# Unity 基础示例

## 打开并测试

1. 在 Unity Hub 中选择“添加本地项目”，目录选择本 README 同级的 `UnityProject`。
2. 使用 Unity **2022.3.62f3c1** 打开，等待本地包和 C# 导入完成。
3. 打开 `Assets/Scenes/Main.unity`，点击播放。

当前目录：`/Users/rainy/Documents/Github/hxmaker-unity/samples/basic/UnityProject`。

工程已经包含生成的 C# 源码和序列化场景，本机第一次打开无需重新运行构建脚本。生成源码不纳入 Git；在新机器检出后请先构建。

## 画面内容

- Unity 原生方块、灯光和主摄像机。
- 半透明 hxmaker 界面、中文文字、九张独立纹理、旋转动画、图形和嵌套裁剪。
- 右上角的预览摄像机重放同一份 hxmaker 画面，不重复推进业务时间。
- 点击底部“点击切换单纹理／多纹理”，观察画面和批次数变化。

建议检查中文显示、动画、裁剪、点击切换和两个镜头；把 Console 中的错误或异常画面反馈给我即可。运行和视觉测试由你进行，本次没有自动进入播放模式。

## 修改 Haxe 后重建

在当前目录执行：

```sh
python3 build.py
```

脚本调用本仓库的 `tools/build_unity.py`，编译 `Source` 并更新 `UnityProject/Assets/HxmakerGenerated`。请修改 Haxe 源码，而不是生成的 C#。

## 当前验证状态

- Haxe 4.3.7 已成功生成 C#。
- Unity 2022.3.62f3c1 的临时示例导入编译通过，并成功生成当前 Main 场景。
- 仍有 Haxe 生成器／Actuate 的非阻断警告。
- 目标工程移动后的首次导入、运行画面、多摄像机交互和发布平台尚待手动验证。

本地包使用相对路径引用仓库内的 `unity`，无需依赖临时目录。发布中文游戏时应配置可分发的动态字体资源。
