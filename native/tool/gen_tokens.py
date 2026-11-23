#!/usr/bin/env python3
"""Sinh TeachHubTokens.kt (Android) và TeachHubTokens.swift (iOS) từ app/assets/tokens/teachhub.tokens.json.

Chạy:   python3 native/tool/gen_tokens.py          # ghi file
        python3 native/tool/gen_tokens.py --check  # CI: báo lỗi nếu file sinh lệch nguồn
"""
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SRC = ROOT / "app/assets/tokens/teachhub.tokens.json"
KT = ROOT / "native/android/app/src/main/java/vn/dayhoc/app/core/designsystem/TeachHubTokens.kt"
SWIFT = ROOT / "native/ios/DayHoc/Core/DesignSystem/TeachHubTokens.swift"
HEADER = "// File sinh bởi native/tool/gen_tokens.py từ app/assets/tokens/teachhub.tokens.json. Không sửa tay."


def load():
    data = json.loads(SRC.read_text())
    core = {k: v["$value"] for k, v in data["core"]["color"].items() if not k.startswith("$")}

    def resolve(value):
        m = re.fullmatch(r"\{core\.color\.(\w+)\}", value)
        return core[m.group(1)] if m else value

    def flat_colors(mode):
        out = {}
        groups = [g for k, g in data[mode].items() if not k.startswith("$")]  # colorScheme, theme, tasco
        for group in groups:
            for name, tok in group.items():
                if name.startswith("$"):
                    continue
                if name in out:
                    raise SystemExit(f"Trùng tên token màu '{name}' trong mode {mode}")
                out[name] = resolve(tok["$value"])
        return out

    dimens = {k: v["$value"] for k, v in data["shared"]["tasco"].items() if not k.startswith("$")}
    return flat_colors("light"), flat_colors("dark"), dimens


def hex6(h):
    h = h.lstrip("#")
    assert re.fullmatch(r"[0-9A-Fa-f]{6}", h), f"Màu không hợp lệ: {h}"
    return h.upper()


def kotlin(light, dark, dimens):
    lines = [HEADER, "package vn.dayhoc.app.core.designsystem", "",
             "import androidx.compose.ui.graphics.Color", "import androidx.compose.ui.unit.dp", "",
             "object TeachHubTokens {"]
    for title, colors in (("Light", light), ("Dark", dark)):
        lines.append(f"    object {title} {{")
        lines += [f"        val {n} = Color(0xFF{hex6(v)})" for n, v in colors.items()]
        lines.append("    }")
    lines.append("    object Dimens {")
    lines += [f"        val {n} = {v}.dp" for n, v in dimens.items()]
    lines += ["    }", "}", ""]
    return "\n".join(lines)


def swift(light, dark, dimens):
    def color(h):
        h = hex6(h)
        r, g, b = (int(h[i:i + 2], 16) for i in (0, 2, 4))
        return f"Color(red: {r} / 255, green: {g} / 255, blue: {b} / 255)"

    lines = [HEADER, "import SwiftUI", "", "enum TeachHubTokens {"]
    for title, colors in (("Light", light), ("Dark", dark)):
        lines.append(f"    enum {title} {{")
        lines += [f"        static let {n} = {color(v)}" for n, v in colors.items()]
        lines.append("    }")
    lines.append("    enum Dimens {")
    lines += [f"        static let {n}: CGFloat = {v}" for n, v in dimens.items()]
    lines += ["    }", "}", ""]
    return "\n".join(lines)


def main():
    light, dark, dimens = load()
    assert light.keys() == dark.keys(), "Light và Dark phải có cùng bộ tên màu"
    outputs = {KT: kotlin(light, dark, dimens), SWIFT: swift(light, dark, dimens)}
    if "--check" in sys.argv:
        stale = [str(p.relative_to(ROOT)) for p, text in outputs.items() if not p.exists() or p.read_text() != text]
        if stale:
            raise SystemExit("Token sinh lệch nguồn, chạy lại native/tool/gen_tokens.py: " + ", ".join(stale))
        print("Token khớp nguồn")
        return
    for path, text in outputs.items():
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(text)
        print("Đã ghi", path.relative_to(ROOT))


if __name__ == "__main__":
    main()
