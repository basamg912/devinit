"""Check actual theme artifacts, including highlighted syntax and ANSI text."""

import json
import plistlib
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
palettes = json.loads((ROOT / "colorblind-palette.json").read_text())
themes = json.loads((ROOT / "vim-colorblind.json").read_text())["themes"]
profile = json.loads((ROOT / "Vim-Colorblind.iterm-profile.json").read_text())["Profiles"][0]


def luminance(hex_color):
    rgb = [int(hex_color[i:i + 2], 16) / 255 for i in (1, 3, 5)]
    linear = [c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4 for c in rgb]
    return sum(c * weight for c, weight in zip(linear, [0.2126, 0.7152, 0.0722]))


def contrast(fg, bg):
    a, b = luminance(fg), luminance(bg)
    return (max(a, b) + 0.05) / (min(a, b) + 0.05)


def check(fg, bg, label, minimum=4.5):
    ratio = contrast(fg, bg)
    assert ratio >= minimum, f"{label}: {fg} on {bg} is {ratio:.2f}:1"
    return ratio


def plist_hex(color):
    assert color["Color Space"] == "sRGB"
    return "#" + "".join(f"{round(color[key] * 255):02x}" for key in
                        ["Red Component", "Green Component", "Blue Component"])


vim = (ROOT / "vimrc/colors/colorblind_terminal.vim").read_text()
for key, vim_key in {"foreground": "fg", "muted": "muted", "blue": "blue",
                     "amber": "amber", "purple": "purple"}.items():
    match = re.search(r"let s:" + vim_key + r" = s:dark \? \['(#[0-9a-f]+)', \d+\] : \['(#[0-9a-f]+)', \d+\]", vim)
    assert match, f"Cannot find Vim palette entry {vim_key}"
    assert palettes["dark"][key] == match[1]
    assert palettes["light"][key] == match[2]

for theme in themes:
    mode, s = theme["appearance"], theme["style"]
    p = palettes[mode]
    assert theme["name"] == "Vim Colorblind " + mode.title()
    assert s["editor.background"] == s["terminal.background"] == p["background"]
    assert s["syntax"]["function"]["font_weight"] == 700
    assert s["syntax"]["keyword"]["font_weight"] == 700
    assert s["syntax"]["string"]["color"] == p["blue"]
    ratios = []
    text_backgrounds = [s[key] for key in [
        "editor.background", "editor.active_line.background", "editor.highlighted_line.background",
        "search.match_background", "search.active_match_background",
        "editor.document_highlight.read_background", "editor.document_highlight.write_background",
        "editor.document_highlight.bracket_background", "editor.debugger_active_line.background",
        "version_control.word_added", "version_control.word_deleted",
    ]] + [player["selection"] for player in s["players"]]
    for token, highlight in s["syntax"].items():
        for background in text_backgrounds:
            ratios.append(check(highlight["color"], background, mode + " syntax " + token))
    for bg_key in ["background", "surface.background", "elevated_surface.background",
                   "element.hover", "element.selected", "tab.active_background", "panel.background"]:
        for fg_key in ["text", "text.muted", "text.accent", "text.placeholder", "text.disabled"]:
            ratios.append(check(s[fg_key], s[bg_key], mode + " " + fg_key + " / " + bg_key))
    for status in ["created", "modified", "deleted", "renamed", "conflict", "error", "warning",
                   "info", "success", "hint", "predictive", "ignored", "hidden", "unreachable"]:
        ratios.append(check(s[status], s[status + ".background"], mode + " " + status))
        check(s[status], p["surface"], mode + " " + status + " panel")
    for key, color in s.items():
        if key.startswith("terminal.ansi.") and key != "terminal.ansi.background":
            ratios.append(check(color, s["terminal.background"], mode + " " + key))
    for player in s["players"]:
        check(player["cursor"], p["background"], mode + " cursor", minimum=3)

    preset = plistlib.loads((ROOT / f"Vim-Colorblind-{mode.title()}.itermcolors").read_bytes())
    for key, color in preset.items():
        assert profile[key + " (" + mode.title() + ")"] == color
    for i, color in enumerate(p["ansi"]):
        assert plist_hex(preset[f"Ansi {i} Color"]) == color
        ratios.append(check(color, p["background"], mode + f" iTerm ANSI {i}"))
    check(plist_hex(preset["Selected Text Color"]), plist_hex(preset["Selection Color"]), mode + " selected text")
    check(plist_hex(preset["Cursor Text Color"]), plist_hex(preset["Cursor Color"]), mode + " cursor text")
    assert profile["Use Selected Text Color (" + mode.title() + ")"] is True
    assert profile["Smart Cursor Color (" + mode.title() + ")"] is False
    print(f"{theme['name']}: minimum tested text contrast {min(ratios):.2f}:1; syntax, selections, diagnostics, UI and ANSI verified")
