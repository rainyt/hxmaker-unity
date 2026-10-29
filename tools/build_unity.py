#!/usr/bin/env python3
"""编译 Haxe、导入 C#，并按需用 Unity 创建示例场景或检查工程。"""
from __future__ import annotations
import argparse
import os
import shutil
import subprocess
from pathlib import Path
from export_unity import export


def main() -> None:
    parser: argparse.ArgumentParser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--project', type=Path, required=True, help='Unity 工程根目录')
    parser.add_argument('--source', type=Path, help='含 build.hxml 的 Haxe 工程目录，默认与 Unity 工程相同')
    parser.add_argument('--haxe', default='haxe', help='Haxe 可执行程序')
    parser.add_argument('--main', default='Main', help='Haxe 入口类')
    parser.add_argument('--unity-editor', type=Path, help='Unity 编辑器可执行程序')
    parser.add_argument('--create-scene', action='store_true', help='通过 Unity 创建默认场景，需要 --unity-editor')
    parser.add_argument('--check', action='store_true', help='通过 Unity 批处理检查 C# 导入，需要 --unity-editor')
    args: argparse.Namespace = parser.parse_args()
    project: Path = args.project.resolve()
    source: Path = (args.source or args.project).resolve()
    if not (source / 'build.hxml').is_file() or not (project / 'Assets').is_dir():
        raise SystemExit('需要包含 build.hxml 的 Haxe 目录和包含 Assets 的 Unity 工程')
    if (args.check or args.create_scene) and args.unity_editor is None:
        raise SystemExit('--check／--create-scene 需要指定 --unity-editor')
    executable: str | None = shutil.which(args.haxe)
    if executable is None:
        raise SystemExit('找不到 Haxe，请先安装并加入 PATH')
    environment: dict[str, str] = dict(os.environ)
    # 解析版本管理器的符号链接，避免经包装目录启动时丢失标准库。
    standard: Path = Path(executable).resolve().parent / 'std'
    if 'HAXE_STD_PATH' not in environment and standard.is_dir():
        environment['HAXE_STD_PATH'] = str(standard)
    subprocess.run([executable, 'build.hxml'], cwd=source, env=environment, check=True)
    export(source / 'build', project, args.main)
    if args.unity_editor is not None and (args.check or args.create_scene):
        log: Path = project / 'Logs' / 'hxmaker-import.log'
        log.parent.mkdir(parents=True, exist_ok=True)
        command: list[str] = [str(args.unity_editor.resolve()), '-batchmode', '-quit', '-projectPath', str(project), '-logFile', str(log)]
        if args.create_scene:
            command.extend(['-executeMethod', 'Hxmaker.Unity.Editor.HxmakerProjectSetup.CreateScene'])
        subprocess.run(command, check=True)
        print('Unity 导入编译通过，日志：' + str(log))


if __name__ == '__main__':
    main()
