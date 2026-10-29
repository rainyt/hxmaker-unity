# OpenFL 示例的 Unity 迁移版

来自 `hxmaker-openfl/samples`，参考提交 `7b293ef6953cd07b5b5e56e450df9081f1dfc5c8`。保留原资源、1920×1080 舞台、250 像素左侧滚动菜单、底部标题、A/D 切页和红色前后切页按钮。现有 `../basic` 示例继续保留多镜头与 Unity 原生物体演示，本示例使用单镜头复现原示例。

## 打开工程

先确保本机 Haxelib 指向适配 Unity 的核心库和本后端，并安装 Spine 4.2 运行时：

```sh
haxelib dev hxmaker /你的路径/hxmaker
haxelib dev hxmaker-unity /你的路径/hxmaker-unity
haxelib install hxcs
haxelib install spine-haxe 4.2.9
```

在本目录执行 `python3 build.py`，生成并导入 C#。然后用 Unity Hub 打开本目录的 `UnityProject`，打开 `Assets/Scenes/Main.unity`，由你进入播放模式查看。

Unity 工程使用 2022.3，`Packages/manifest.json` 通过相对路径引用仓库中的 `unity` 包。请保持示例位于仓库内。启动类 `Main` 继承 `hx.core.HxmakerApplication`，仅调用 `super()` 和 `init(Game, 1920, 1080)`；业务舞台 `Game` 继承 `Stage`。

## 保留的 25 页

| 页面 | 原示例内容 |
| --- | --- |
| ParticleRender2 | XML 粒子布局、鼠标跟随、动态发射点 |
| ParticleRender | 雨滴和程序配置的粒子 |
| ScrollRender | 滚动、矩形裁剪、点击 |
| ListViewRender | 普通列表 |
| VirtualListViewRender | 一万行虚拟列表 |
| VirtualFlowListViewRender | 一万个元素的虚拟流式布局 |
| BitmapLabelRender | 一千个位图数字文本 |
| GraphicRender | 贴图三角形、线段、圆和色块 |
| XmlRender | 原 XML 界面、九宫格、按钮和中文排版 |
| AnchorLayoutRender | 锚点布局 |
| LayoutRender | 盒子和自动布局 |
| SpineDuckRender | Spine 鸭子动画与增加数量 |
| ButtonRender | 图集按钮及点击事件 |
| MovieClipRender | 图集帧动画与增加数量 |
| BlendModeRender | NORMAL、ADD |
| WabbitRender | 多纹理兔子压力演示 |
| Scale9GridRender | 九宫格背景与图片缩放 |
| AllDisplayRender | 图片、文字、图形与 Spine 混合显示 |
| SpineRender | Spine 动画压力演示 |
| ImageRender | 图片、图集、颜色变换和旋转 |
| LabelRender | 中文、换行、对齐和描边 |
| MoreLabelRender | 一千个动态文本 |
| TreeViewDemoRender | 数千节点的树、展开收起与定位 |
| TreeRender | 树列表及虚拟化 |
| FinderRender | 文件浏览器式列表与导航 |

保留原压力页的对象数量。WabbitRender 初始 500 个，点击场景增加 10000 个；MovieClipRender 初始 500 个，点击增加 100 个；SpineDuckRender 初始 50 个，点击增加 50 个。点击菜单不会额外增加这些对象，资源尚未加载完时忽略增加操作。

## 跳过与适配

- `CustomRender`：依赖 OpenFL 原生显示对象，未加入菜单。
- `TextAtlasOverflowRender`：依赖 OpenFL 私有字体图集诊断与释放接口，未加入菜单。
- `BlendModeRender`：跳过 MULTIPLY、SCREEN 两项，不补充新的后端混合能力。
- 字体：原资源没有 `SourceHanSansSC-Bold.otf`，改用 Unity 宿主默认中文字体。可在 Hxmaker 对象的 DefaultFont/Fonts 中指定项目字体；字体度量可能与 OpenFL 不同。
- FPS：改用本示例的 `SampleFPS`，显示主循环帧率与上一帧 hxmaker 提交批次数；不显示 OpenFL 位图池，不代表 Unity 的完整 GPU 绘制次数。
- XML 资源路径仍为 `assets/...`，原资源唯一副本位于 `UnityProject/Assets/StreamingAssets/assets`。`moudle.xml` 同时用于编译期宏和界面模块映射。
- 页面切换释放旧页；异步加载完成时检查旧页是否已释放，避免在离开后构建界面。
- 修正原示例的旧版 Particle 构造参数及 Spine.play 参数，以适配当前核心 API。

此迁移不扩展 Unity 后端能力。已成功生成 Haxe → C# 并导入示例目录；生成时核心库的 Matrix、Particle、Spine 及 Spine 运行时出现构造重载警告。尚未进行 Unity 导入编译、播放、画面或性能测试，需由你在编辑器中验收。
