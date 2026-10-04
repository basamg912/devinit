"""Build Zed and iTerm2 artifacts from the Vim-inspired palette."""

import json
import plistlib
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
PALETTES = json.loads((ROOT / "colorblind-palette.json").read_text())
ANSI_NAMES = ["black", "red", "green", "yellow", "blue", "magenta", "cyan", "white"]


def syntax_style(token, p):
    color, weight, style = p["foreground"], None, None
    if token.startswith(("comment", "hint", "predictive")):
        color = p["muted"]
        if token.startswith("predictive"):
            style = "italic"
    elif token.startswith(("type", "enum", "variant", "concept", "attribute")):
        color = p["purple"]
    elif token.startswith(("preproc", "predoc", "keyword.directive", "constant.macro", "function.macro")):
        color, weight = p["purple"], 700
    elif token.startswith(("keyword", "function", "constructor", "operator", "tag")):
        color, weight = p["blue"], 700
    elif token.startswith(("number", "float", "boolean", "constant", "character")):
        color = p["amber"]
    elif token.startswith(("string.escape", "string.special", "string.regex", "string.regexp", "punctuation.special")):
        color, weight = p["amber"], 700
    elif token.startswith(("string", "link_", "text.literal", "selector")):
        color = p["blue"]
    elif token == "diff.plus":
        color, weight = p["blue"], 700
    elif token == "diff.minus":
        color, weight = p["purple"], 700
    elif token in ("emphasis.strong", "title"):
        weight = 700
    elif token == "emphasis":
        style = "italic"
    return {"color": color, "font_weight": weight, "font_style": style}


def zed_style(p, tokens, scrollbar):
    bg, fg, muted = p["background"], p["foreground"], p["muted"]
    surface, hover, blue = p["surface"], p["hover"], p["blue"]
    s = {
        "background.appearance": "opaque",
        "background": surface,
        "surface.background": surface,
        "elevated_surface.background": bg,
        "border": p["border"],
        "border.variant": p["border"],
        "border.focused": blue,
        "border.selected": blue,
        "border.transparent": "#00000000",
        "border.disabled": p["border"],
        "element.background": surface,
        "element.hover": hover,
        "element.active": p["selection"],
        "element.selected": p["selection"],
        "element.disabled": surface,
        "drop_target.background": p["selection"],
        "ghost_element.background": "#00000000",
        "ghost_element.hover": hover,
        "ghost_element.active": p["selection"],
        "ghost_element.selected": p["selection"],
        "ghost_element.disabled": "#00000000",
        "text": fg,
        "text.muted": muted,
        "text.placeholder": muted,
        "text.disabled": muted,
        "text.accent": blue,
        "icon": fg,
        "icon.muted": muted,
        "icon.disabled": muted,
        "icon.placeholder": muted,
        "icon.accent": blue,
        "status_bar.background": bg,
        "title_bar.background": bg,
        "title_bar.inactive_background": surface,
        "toolbar.background": bg,
        "tab_bar.background": surface,
        "tab.inactive_background": surface,
        "tab.active_background": bg,
        "panel.background": surface,
        "panel.overlay_background": bg,
        "panel.focused_border": blue,
        "pane.focused_border": blue,
        "pane_group.border": p["border"],
        "panel.indent_guide": p["border"],
        "panel.indent_guide_active": blue,
        "panel.indent_guide_hover": muted,
        "minimap.thumb.background": p["border"] + "50",
        "minimap.thumb.hover_background": p["border"] + "70",
        "minimap.thumb.active_background": blue + "50",
        "minimap.thumb.border": p["border"],
        "editor.foreground": fg,
        "editor.background": bg,
        "editor.gutter.background": bg,
        "editor.subheader.background": surface,
        "editor.active_line.background": surface,
        "editor.highlighted_line.background": p["selection"],
        "editor.line_number": muted,
        "editor.active_line_number": fg,
        "editor.hover_line_number": fg,
        "editor.invisible": muted,
        "editor.wrap_guide": p["border"],
        "editor.active_wrap_guide": muted,
        "editor.indent_guide": p["border"],
        "editor.indent_guide_active": muted,
        "editor.document_highlight.read_background": p["selection"],
        "editor.document_highlight.write_background": p["search"],
        "editor.document_highlight.bracket_background": p["selection"],
        "editor.debugger_active_line.background": p["search"],
        "search.match_background": p["search"],
        "search.active_match_background": p["search_active"],
        "link_text.hover": blue,
        "debugger.accent": p["amber"],
        "terminal.background": bg,
        "terminal.foreground": fg,
        "terminal.bright_foreground": fg,
        "terminal.dim_foreground": muted,
        "terminal.ansi.background": bg,
        "syntax": {token: syntax_style(token, p) for token in sorted(tokens)},
        "accents": [blue, p["amber"], p["purple"]],
        "players": [
            {"cursor": color, "background": color, "selection": p["selection"]}
            for color in [p["cursor"], p["purple"], blue, muted, p["amber"]]
        ],
    }
    statuses = {
        "created": (blue, p["added_background"]),
        "modified": (p["amber"], p["search"]),
        "deleted": (p["purple"], p["deleted_background"]),
        "renamed": (blue, p["added_background"]),
        "conflict": (p["purple"], p["deleted_background"]),
        "error": (blue, p["added_background"]),
        "warning": (p["amber"], p["search"]),
        "info": (blue, p["added_background"]),
        "success": (blue, p["added_background"]),
        "hint": (muted, surface),
        "predictive": (muted, surface),
        "hidden": (muted, surface),
        "ignored": (muted, surface),
        "unreachable": (muted, surface),
    }
    for name, (color, background) in statuses.items():
        s.update({name: color, name + ".background": background, name + ".border": color})
    for name, role in {"added": "created", "modified": "modified", "deleted": "deleted",
                       "renamed": "renamed", "conflict": "conflict", "ignored": "ignored"}.items():
        s["version_control." + name] = s[role]
    s.update({
        "version_control.word_added": p["added_background"],
        "version_control.word_deleted": p["deleted_background"],
        "version_control.conflict_marker.ours": p["added_background"],
        "version_control.conflict_marker.theirs": p["deleted_background"],
        "vim.mode.text": bg,
    })
    for mode in ["normal", "helix_normal", "visual", "helix_select", "insert",
                 "visual_line", "visual_block", "replace"]:
        s["vim." + mode + ".foreground"] = bg
        s["vim." + mode + ".background"] = fg
    for i, name in enumerate(ANSI_NAMES):
        s["terminal.ansi." + name] = p["ansi"][i]
        s["terminal.ansi.bright_" + name] = p["ansi"][i + 8]
        # Faint text retains the same minimum contrast as normal ANSI text.
        s["terminal.ansi.dim_" + name] = p["ansi"][i]
    s.update(scrollbar)
    s["scrollbar.thumb.active_background"] = scrollbar["scrollbar.thumb.hover_background"]
    return s


def iterm_color(hex_color):
    rgb = [int(hex_color[i:i + 2], 16) / 255 for i in (1, 3, 5)]
    return dict(zip(["Red Component", "Green Component", "Blue Component"], rgb),
                **{"Color Space": "sRGB", "Alpha Component": 1.0})


def iterm_colors(p):
    colors = {
        "Background Color": p["background"],
        "Foreground Color": p["foreground"],
        "Bold Color": p["foreground"],
        "Cursor Color": p["cursor"],
        "Cursor Text Color": p["background"],
        "Selection Color": p["foreground"],
        "Selected Text Color": p["background"],
        "Link Color": p["blue"],
        "Match Background Color": p["search"],
        "Cursor Guide Color": p["selection"],
        "Badge Color": p["muted"],
    }
    colors.update({f"Ansi {i} Color": color for i, color in enumerate(p["ansi"])})
    return {key: iterm_color(color) for key, color in colors.items()}


def build():
    tokens = set()
    scrollbars = {}
    for filename in ["github-colorblind-split.json", "catppuccin-colorblind-split.json"]:
        for theme in json.loads((ROOT / filename).read_text())["themes"]:
            tokens.update(theme["style"]["syntax"])
            if filename == "github-colorblind-split.json":
                scrollbars[theme["appearance"]] = {
                    key: value for key, value in theme["style"].items()
                    if key.startswith("scrollbar.")
                }
    family = {"$schema": "https://zed.dev/schema/themes/v0.2.0.json",
              "name": "Vim Colorblind", "author": "basamg",
              "themes": [{"name": "Vim Colorblind " + mode.title(), "appearance": mode,
                          "style": zed_style(p, tokens, scrollbars[mode])}
                         for mode, p in PALETTES.items()]}
    (ROOT / "vim-colorblind.json").write_text(json.dumps(family, indent=2) + "\n")
    profile = {
        "Name": "Vim Colorblind", "Guid": "D60AF721-3900-4DA1-AE5F-2AE390C6757C",
        "Dynamic Profile Parent Name": "Default", "Tags": ["Colorblind"],
        "Use Separate Colors for Light and Dark Mode": True,
        "Transparency": 0.0,
    }
    for mode, p in PALETTES.items():
        colors = iterm_colors(p)
        (ROOT / f"Vim-Colorblind-{mode.title()}.itermcolors").write_bytes(plistlib.dumps(colors))
        if mode == "light":
            profile.update(colors)
        suffix = " (" + mode.title() + ")"
        profile.update({key + suffix: value for key, value in colors.items()})
        for key, value in {"Use Selected Text Color": True, "Smart Cursor Color": False,
                           "Minimum Contrast": 0.0, "Use Bright Bold": False}.items():
            profile[key + suffix] = value
            profile[key] = value
    (ROOT / "Vim-Colorblind.iterm-profile.json").write_text(
        json.dumps({"Profiles": [profile]}, indent=2) + "\n")
    print("Built Zed light/dark themes, iTerm2 presets and adaptive profile")


if __name__ == "__main__":
    build()
