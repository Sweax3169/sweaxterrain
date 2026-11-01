"""Build SweaxTerrain.rbxmx from src/.

    python tools/build.py            -> dist/SweaxTerrain.rbxmx
    python tools/build.py --install  -> also copies it into your Roblox Studio Plugins folder

The plugin is one Script (Ana.server.lua) with its modules as child ModuleScripts.
Studio loads local plugins when it starts, so restart Studio after installing.
"""
import os
import shutil
import sys
from pathlib import Path
from xml.sax.saxutils import escape

ROOT = Path(__file__).resolve().parent.parent
SRC = ROOT / "src"
DIST = ROOT / "dist"
OUT = DIST / "SweaxTerrain.rbxmx"

MAIN = "Ana.server.lua"
MODULES = ["Dil", "Uretici", "Arayuz", "Yapilar", "YapiTemel", "YapiMaden", "YapiSus", "YapiAlan"]


def read(name):
    text = (SRC / name).read_text(encoding="utf-8")
    return text.replace("\r\n", "\n")


def item(cls, name, source, ref, children=""):
    return (
        f'<Item class="{cls}" referent="RBX{ref}">\n'
        "<Properties>\n"
        f'<string name="Name">{escape(name)}</string>\n'
        f'<ProtectedString name="Source">{escape(source)}</ProtectedString>\n'
        "</Properties>\n"
        f"{children}"
        "</Item>\n"
    )


def build():
    children = "".join(item("ModuleScript", m, read(m + ".lua"), i + 2) for i, m in enumerate(MODULES))
    body = item("Script", "SweaxTerrain", read(MAIN), 1, children)
    xml = '<roblox version="4">\n' + body + "</roblox>\n"
    DIST.mkdir(exist_ok=True)
    OUT.write_text(xml, encoding="utf-8", newline="\n")
    print(f"built {OUT.relative_to(ROOT)} ({len(xml.encode('utf-8')) // 1024} KB, {len(MODULES)} modules)")
    return OUT


def plugins_folder():
    if sys.platform == "win32":
        return Path(os.environ["LOCALAPPDATA"]) / "Roblox" / "Plugins"
    if sys.platform == "darwin":
        return Path.home() / "Documents" / "Roblox" / "Plugins"
    return None


if __name__ == "__main__":
    out = build()
    if "--install" in sys.argv:
        target = plugins_folder()
        if target is None:
            sys.exit("Roblox Studio runs on Windows and macOS only; copy dist/SweaxTerrain.rbxmx by hand.")
        target.mkdir(parents=True, exist_ok=True)
        shutil.copy2(out, target / out.name)
        print(f"installed to {target / out.name} (restart Studio to load it)")
