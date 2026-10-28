#!/usr/bin/env python3
"""将 Haxe 生成的 C# 源码导入 Unity 项目，并生成无需反射的入口。"""
from __future__ import annotations
import argparse
import json
import re
import shutil
from pathlib import Path


def export(generated: Path, project: Path, main: str) -> None:
    source: Path = generated.resolve() / "src"
    assets: Path = project.resolve() / "Assets"
    if not source.is_dir() or not assets.is_dir():
        raise SystemExit("需要有效的 Haxe 输出目录和已存在的 Unity 项目 Assets 目录")
    if not re.fullmatch(r"[A-Za-z_][A-Za-z0-9_]*(\.[A-Za-z_][A-Za-z0-9_]*)*", main):
        raise SystemExit("Haxe 入口类名格式无效")
    destination: Path = assets / "HxmakerGenerated"
    destination.mkdir(parents=True, exist_ok=True)
    manifest: Path = destination / ".hxmaker-export.json"
    owned: list[str] = json.loads(manifest.read_text()).get("files", []) if manifest.exists() else []
    files: dict[str, bytes] = {}
    for path in source.rglob("*.cs"):
        files["Haxe/" + path.relative_to(source).as_posix()] = path.read_bytes()
    if not files:
        raise SystemExit("Haxe 输出目录中没有 C# 源码，请先执行 Haxe 构建")
    native_main: str = main if "." in main else "haxe.root." + main
    files["HxmakerGame.cs"] = ("""using Hxmaker.Unity;
using UnityEngine.Scripting;

namespace Hxmaker.Unity.Generated
{
    // 自动生成；修改入口应重新运行导出工具。
    [Preserve]
    public sealed class HxmakerGame : HxmakerHost
    {
        protected override void Boot()
        {
            global::cs.Boot.init();
            TickHandler = global::Hxmaker.Unity.HaxeRuntime.Tick;
            ResizeHandler = global::Hxmaker.Unity.HaxeRuntime.Resize;
            PointerHandler = global::Hxmaker.Unity.HaxeRuntime.Pointer;
            KeyboardHandler = global::Hxmaker.Unity.HaxeRuntime.Keyboard;
            FocusHandler = global::Hxmaker.Unity.HaxeRuntime.Focus;
            ShutdownHandler = global::Hxmaker.Unity.HaxeRuntime.Shutdown;
            global::""" + native_main + """.main();
        }
    }
}
""").encode()
    files["Hxmaker.Unity.Generated.asmdef"] = json.dumps({
        "name": "Hxmaker.Unity.Generated", "references": ["Hxmaker.Unity"],
        "allowUnsafeCode": True, "autoReferenced": True,
    }, indent=2).encode()
    # Haxe 宏与 XML UI 会动态引用成员，Unity 的裁剪必须保留生成程序集。
    files["link.xml"] = b'<linker><assembly fullname="Hxmaker.Unity.Generated" preserve="all" /></linker>\n'
    for name in files:
        path: Path = destination / name
        if path.exists() and name not in owned:
            raise SystemExit("目标文件未登记为自动生成，拒绝覆盖：" + str(path))
    for name, data in files.items():
        path: Path = destination / name
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_bytes(data)
    for name in owned:
        path: Path = (destination / name).resolve()
        if not path.is_relative_to(destination.resolve()):
            raise SystemExit("导出清单包含越界路径")
        if name not in files and path.is_file():
            path.unlink()
            meta: Path = Path(str(path) + ".meta")
            if meta.exists():
                meta.unlink()
    manifest.write_text(json.dumps({"files": sorted(files)}, indent=2))
    print("已导出至 " + str(destination))


if __name__ == "__main__":
    parser: argparse.ArgumentParser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--generated", type=Path, required=True, help="Haxe --cs 的输出目录")
    parser.add_argument("--project", type=Path, required=True, help="Unity 项目根目录")
    parser.add_argument("--main", default="Main", help="公开 static main() 所在的 Haxe 类")
    arguments: argparse.Namespace = parser.parse_args()
    export(arguments.generated, arguments.project, arguments.main)
