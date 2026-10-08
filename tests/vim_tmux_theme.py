"""Exercise OSC 11 detection in real Vim panes on an isolated tmux server."""
import json
import os
from pathlib import Path
import shlex
import subprocess
import tempfile
import time


ROOT = Path(__file__).resolve().parents[1]
CONFIG = Path(os.environ.get("VIM_PERSONAL_CONFIG", ROOT / "vimrc" / "my_configs.vim"))
with tempfile.TemporaryDirectory(prefix="vim-tmux-theme-") as directory:
    base = Path(directory).resolve()
    socket = base / "socket"
    report = base / "theme.json"
    output = base / "terminal-output"
    runtime = ROOT / "vimrc"
    vimrc = base / "vimrc"
    vimrc.write_text("set runtimepath+=" + str(runtime) + "\n" + "\n".join(
        "source " + str(runtime / "vimrcs" / (name + ".vim"))
        for name in ("basic", "filetypes", "plugins_config", "extended")
    ) + "\nsource " + str(CONFIG) + "\n")
    audit = base / "audit.vim"
    audit.write_text("""let g:ale_enabled = 0
let g:gitgutter_enabled = 0
let g:theme_reload_count = 0
augroup ThemeAudit
  autocmd!
  autocmd ColorScheme * let g:theme_reload_count += 1 | call ScheduleAudit()
  autocmd VimEnter * call ScheduleAudit()
  autocmd TermResponseAll background call ScheduleAudit()
augroup END
function! AuditTheme(timer) abort
  call writefile([json_encode({'term': &term, 'background': &background,
        \\ 'query': &t_RB, 'response': v:termrbgresp,
        \\ 'string_fg': synIDattr(hlID('String'), 'fg', 'cterm'),
        \\ 'comment_fg': synIDattr(hlID('Comment'), 'fg', 'cterm'),
        \\ 'reloads': g:theme_reload_count, 'errors': v:errors,
        \\ 'background_timers': len(filter(timer_info(),
        \\ 'string(v:val.callback) =~ "RequestTerminalBackground"'))})], $VIM_THEME_AUDIT)
endfunction
function! ScheduleAudit() abort
  call timer_start(100, function('AuditTheme'))
endfunction
""")
    tmuxrc = base / "tmux.conf"
    tmuxrc.write_text("set -s default-terminal tmux-256color\n"
                      "set -g window-style bg=#0d1117\n"
                      "set -s set-clipboard off\n")
    environment = os.environ.copy()
    environment.pop("TMUX", None)
    environment["VIM_THEME_AUDIT"] = str(report)

    def tmux(*args):
        result = subprocess.run(["tmux", "-S", str(socket), *args],
                                env=environment, capture_output=True,
                                text=True, check=True)
        return result.stdout.strip()

    def wait_theme(theme):
        deadline = time.monotonic() + 6
        last = None
        while time.monotonic() < deadline:
            try:
                last = json.loads(report.read_text())
            except (OSError, json.JSONDecodeError):
                pass
            if last and last["background"] == theme and last["response"]:
                assert last["term"] == "tmux-256color", last
                assert last["query"] == "\x1b]11;?\x07", last
                assert last["string_fg"] == ("117" if theme == "dark" else "25"), last
                assert last["comment_fg"] == ("250" if theme == "dark" else "241"), last
                assert not last["errors"], last
                return last
            time.sleep(0.1)
        raise AssertionError(f"Vim did not detect {theme}: {last}")

    try:
        command = shlex.join(["vim", "-Nu", str(vimrc), "-i", "NONE", "-n",
                              "-S", str(audit)])
        tmux("-f", str(tmuxrc), "new-session", "-d", "-s", "theme-audit", command)
        wait_theme("dark")
        for theme, color in (("light", "#ffffff"), ("dark", "#0d1117"),
                             ("light", "#ffffff")):
            tmux("set-option", "-w", "-t", "theme-audit", "window-style", "bg=" + color)
            # Simulate terminal focus events in this test-owned pane only.
            tmux("send-keys", "-t", "theme-audit", "-l", "\x1b[O\x1b[I")
            wait_theme(theme)
            print(f"tmux -> focus return -> OSC 11 -> Vim: {theme} palette verified")
        count = wait_theme("light")["reloads"]
        time.sleep(0.3)
        tmux("pipe-pane", "-t", "theme-audit", "cat > " + shlex.quote(str(output)))
        time.sleep(2.2)
        assert wait_theme("light")["reloads"] == count, "Unchanged theme reloaded repeatedly"
        emitted = output.read_bytes()
        queries = emitted.count(b"\x1b]11;?\x07")
        clears = emitted.count(b"\x1b[2J") + emitted.count(b"\x1b[H\x1b[J")
        print(f"Idle terminal output: {len(emitted)} bytes, "
              f"{queries} background queries, {clears} full-screen clears")
        assert not emitted, f"Idle Vim keeps updating the terminal: {emitted[:100]!r}"
        assert wait_theme("light")["background_timers"] == 0, "Background polling is still active"
        tmux("send-keys", "-t", "theme-audit", "-l", ":source " + str(CONFIG))
        tmux("send-keys", "-t", "theme-audit", "Enter")
        time.sleep(0.5)
        assert wait_theme("light")["background_timers"] == 0, "Config reload revived background polling"
        # Re-sourcing must not revive polling or duplicate focus callbacks.
        time.sleep(0.3)
        before = output.read_bytes()
        tmux("send-keys", "-t", "theme-audit", "-l", "\x1b[O\x1b[I")
        time.sleep(0.3)
        after = output.read_bytes()[len(before):]
        assert after.count(b"\x1b]11;?\x07") == 1, "Focus query hooks were duplicated"
        time.sleep(0.3)
        settled = output.stat().st_size
        time.sleep(2.2)
        assert output.stat().st_size == settled, "Config reload restarted idle terminal updates"
        print("Startup, focus theme changes and config reload passed; idle Vim emits no terminal updates")
    finally:
        subprocess.run(["tmux", "-S", str(socket), "kill-server"], env=environment,
                       capture_output=True, check=False)
