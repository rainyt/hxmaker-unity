#!/usr/bin/env python3
"""重新编译 Haxe 并将 C# 导入本目录下的 Unity 示例。"""
from pathlib import Path
import subprocess
import sys

sample: Path = Path(__file__).resolve().parent
backend: Path = sample.parent.parent
subprocess.run([sys.executable, str(backend / "tools/build_unity.py"),
                "--source", str(sample), "--project", str(sample / "UnityProject"),
                *sys.argv[1:]], check=True)
