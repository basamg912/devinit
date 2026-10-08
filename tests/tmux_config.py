"""Verify tmux on a private socket without touching user sessions or plugins."""
import os
from pathlib import Path
import shlex
import subprocess
import tempfile


ROOT = Path(__file__).resolve().parents[1]
CONFIG = ROOT / "tmux/tmux.conf"


def rgb(color):
    if color.startswith("#"):
        return tuple(int(color[i:i + 2], 16) / 255 for i in (1, 3, 5))
    index = int(color.removeprefix("colour"))
    if index >= 232:
        return ((8 + (index - 232) * 10) / 255,) * 3
    index -= 16
    levels = [0, 95, 135, 175, 215, 255]
    return tuple(levels[x] / 255 for x in (index // 36, index // 6 % 6, index % 6))


def contrast(fg, bg):
    def luminance(color):
        values = [x / 12.92 if x <= 0.04045 else ((x + 0.055) / 1.055) ** 2.4
                  for x in rgb(color)]
        return sum(x * weight for x, weight in zip(values, (0.2126, 0.7152, 0.0722)))
    values = sorted((luminance(fg), luminance(bg)))
    return (values[1] + 0.05) / (values[0] + 0.05)


with tempfile.TemporaryDirectory(prefix="tmux-colorblind-") as directory:
    base = Path(directory).resolve()
    socket = base / "socket"
    config = CONFIG.read_text()
    plugin_loader = "run-shell '~/.tmux/plugins/tpm/tpm'"
    assert config.count(plugin_loader) == 1
    # Test the settings without loading plugins that write session snapshots.
    test_config = base / "tmux.conf"
    test_config.write_text(config.replace(plugin_loader, ""))
    environment = os.environ.copy()
    environment.pop("TMUX", None)

    def tmux(*args):
        result = subprocess.run(
            ["tmux", "-S", str(socket), *args], env=environment,
            capture_output=True, text=True, check=True,
        )
        return result.stdout.strip()

    def option(name):
        return tmux("show-options", "-Av", name)

    def binding(key):
        words = shlex.split(tmux("list-keys", "-T", "prefix", key))
        return words[words.index(key) + 1:]

    try:
        tmux("-f", str(test_config), "new-session", "-d", "-s", "audit",
             "-c", str(base), "sleep 600")
        assert option("prefix") == "C-b"
        assert option("mouse") == "on"
        assert option("mode-keys") == "vi"
        assert option("default-terminal") == "tmux-256color"
        assert option("set-clipboard") == "external"
        assert option("@continuum-restore") == "off"
        assert option("@resurrect-capture-pane-contents") == "off"
        assert tmux("display-message", "-p", "#{window_index}:#{pane_index}") == "1:1"
        assert binding("c") == ["new-window", "-c", "#{pane_current_path}"]
        assert binding("|") == ["split-window", "-h", "-c", "#{pane_current_path}"]
        assert binding("-") == ["split-window", "-v", "-c", "#{pane_current_path}"]
        for key, direction in zip("hjkl", ("-L", "-D", "-U", "-R")):
            assert binding(key) == ["select-pane", direction]
        assert "begin-selection" in tmux("list-keys", "-T", "copy-mode-vi", "v")
        tmux(*binding("|"), "sleep 600")
        paths = tmux("list-panes", "-F", "#{pane_current_path}").splitlines()
        assert paths == [str(base), str(base)]

        palette = {name: option(name) for name in (
            "@cb-foreground", "@cb-inverse", "@cb-surface", "@cb-muted",
            "@cb-blue", "@cb-amber", "@cb-purple",
        )}
        text_styles = (
            "status-style", "window-status-style", "window-status-current-style",
            "mode-style", "copy-mode-selection-style", "copy-mode-match-style",
            "copy-mode-current-match-style", "copy-mode-mark-style", "message-style",
            "message-command-style", "menu-style", "menu-selected-style", "popup-style",
        )
        for theme in ("light", "dark"):
            for name, value in palette.items():
                tmux("set-option", "-g", name, value.replace("#{client_theme}", theme))
            surface = tmux("display-message", "-p", "#{E:@cb-surface}")
            ratios = []
            for name in (*text_styles, "status-left-style", "status-right-style",
                         "window-status-activity-style", "window-status-bell-style"):
                value = tmux("display-message", "-p", "#{E:" + name + "}")
                fields = dict(part.split("=", 1) for part in value.split(",") if "=" in part)
                ratio = contrast(fields["fg"], fields.get("bg", surface))
                assert ratio >= 4.5, (theme, name, value, ratio)
                ratios.append(ratio)
            pane_background = "#ffffff" if theme == "light" else "#0d1117"
            blue = tmux("display-message", "-p", "#{E:@cb-blue}")
            assert contrast(blue, pane_background) >= 3
            print(f"{theme}: minimum tested text contrast {min(ratios):.2f}:1")
        print("Private tmux server: configuration, keys, numbering and split directory verified")
    finally:
        subprocess.run(["tmux", "-S", str(socket), "kill-server"], env=environment,
                       capture_output=True, check=False)
