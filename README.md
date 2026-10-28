# hxmaker-unity

hxmaker 的 Unity Haxelib 后端。Haxe 编译为 C#，Unity 承担窗口、主循环、摄像机、设备与资源 API；hxmaker 保留显示树、布局和业务代码。

当前为首版源码实现，尚未运行 Haxe 编译、Unity 导入、画面或发布验证。不能据此视为已通过验收的发行版本。

## 首版范围

| 能力 | 实现方式 |
| --- | --- |
| 应用与业务舞台 | 启动类继承 `hx.core.HxmakerApplication`，调用 `init(GameStage, width, height)` |
| 二维显示与布局 | 复用 hxmaker 显示树、布局、组件、XML UI、列表及滚动逻辑 |
| 多纹理 | 1／4／8 槽 Shader 变体；按纹理数量、平滑状态、裁剪和顶点上限拆批 |
| 图形与动画 | 图片、图集、九宫格、平铺、路径网格、帧动画和二维粒子 |
| Spine | 使用现有 Haxe 运行时；额外依赖 `spine-haxe` 或 `spine-hx`，版本组合需要单独验收 |
| 文本 | Unity 动态字库、普通排版、字符换行、范围格式、位图字体和八方向描边 |
| 遮罩与混合 | 嵌套矩形裁剪；NORMAL 与 ADD；旋转矩形按世界坐标包围盒裁剪 |
| 输入 | 鼠标、滚轮、键盘、触摸、首指鼠标合成、Tab 焦点；新输入系统可调用路由接口 |
| 资源 | Future、请求合并、引用计数、图片、字节、文本、JSON、XML、ZIP 与资源包 |
| 音频与存储 | AudioSource 播放与完成事件；PlayerPrefs 保存 JSON 值 |
| Unity 共存 | 内置管线命令缓冲；可选 URP 通道；相机分屏与目标 RenderTexture |

这里的能力表描述代码覆盖范围，实际兼容性与性能仍待验证。

## 安装

需要 Haxe 4.3 系列、`hxcs`、Python 3.10+ 和 Unity 2022.3+。本机可用 Unity 为 2022.3；Unity 6 的 URP Render Graph 路径已提供源码，尚未验证。

核心库必须使用本次已适配 `hxmaker_unity` 条件的 `unity` 分支，不能直接搭配未修改的 hxmaker 1.0.0。

```sh
haxelib dev hxmaker /Users/rainy/Documents/haxelib-self/rainyt/hxmaker
haxelib dev hxmaker-unity /Users/rainy/Documents/Github/hxmaker-unity
haxelib install hxcs
```

将本仓库的 `unity/package.json` 作为本地 UPM 包导入。也可在 Unity 项目的 `Packages/manifest.json` 中添加：

```json
"com.rainyt.hxmaker": "file:/Users/rainy/Documents/Github/hxmaker-unity/unity"
```

从 `samples/basic` 目录运行：

```sh
haxe build.hxml
python3 ../../tools/export_unity.py --generated build --project /你的/Unity项目 --main Main
```

导出工具仅写入 `Assets/HxmakerGenerated`，并维护自己的文件清单；不会把 Haxe 构建命令嵌入 Unity 编辑器回调。入口 `main()` 必须公开。生成程序集通过 `link.xml` 保留动态 UI 所需的成员。

在 Unity 执行菜单“GameObject → Hxmaker → 创建宿主与摄像机”。宿主上必须保留 `BatchShader` 的序列化引用，以免发布时 Shader 被裁剪。中文游戏请将包含中文字形的动态字体配置到 `DefaultFont`，或通过 `Fonts` 注册别名；移动端不要依赖操作系统字体恰好存在。

## 多摄像机与渲染管线

一个宿主每帧仅更新一次 Haxe。`HxmakerView` 挂到需要绘制的 Camera 上，摄像机只重放已生成批次，不推进游戏时间。多个 Camera 可以同时显示同一逻辑画面。相机 `rect` 负责分屏，`targetTexture` 负责输出到 Unity RenderTexture，`PreserveAspect` 控制等比适配；输入使用相同的视口变换。

默认主表面编号为 0。首版多个镜头共享同一业务画面，不提供 hxmaker 三维场景的多相机观察。目标纹理上的交互需由业务把坐标转换后传入宿主。

内置管线无需额外包。URP 请另外导入 `integrations/urp/package.json`，在 Universal Renderer 的 Renderer Features 中添加 `HxmakerRendererFeature`。可选包要求工程已经安装 URP 14（Unity 2022.3）或 URP 17（Unity 6），URP 版本由宿主工程固定。包含 Unity 6 Render Graph 和兼容模式两条源码路径。HDRP、XR、多眼实例渲染和动态分辨率不在首版范围内。

`HxmakerHost.PollLegacyInput` 使用旧输入管理器；仅启用新 Input System 的项目需关闭轮询并将输入接入 `RoutePointer`／`RouteKeyboard`，后者使用 hxmaker 键码。屏幕输入原点为左下角，Haxe 舞台原点为左上角。UI Toolkit 或 uGUI 输入遮挡的优先级由宿主业务安排。

## 资源与生命周期

普通相对路径以 Unity `StreamingAssets` 为根目录，HTTP(S)、文件 URL 交给 UnityWebRequest。`resources://路径` 加载 Unity Resources，路径不带扩展名；文本／字节应导入为 TextAsset。网络音频覆盖 WAV、OGG、MP3，具体解码取决于发布平台。内存图片先覆盖 PNG/JPEG，GIF/WebP 等不作兼容承诺。

`AssetObject.retain/release` 接入后端缓存；`System.gc()` 会清理无引用缓存。共享图集子区域复用同一个底层纹理，不能对仍在使用的图集手动 `dispose()`。Unity 外部纹理可由 C# `NativeBridge.RegisterTexture(texture, false)` 注册，再用 `new UnityBitmapData(handle)` 包装；借用纹理不由后端销毁。禁止采样正在绘制的相机目标，避免反馈读写。

Actuate 使用手动时钟和更新宏，由宿主逐帧推进；Future、延迟列表刷新也在主线程执行。关闭宿主时释放后端网格、材质、请求、音频通道和自有纹理。

## 暂不支持与条件编译

后端宏为 `hxmaker_unity`。暂不实现：hxmaker Scene3D、InputLabel 编辑与 IME、通用滤镜、复杂混合模式、OpenFL 原生显示对象、自定义 Shader／运行时 GLSL、`BitmapData.draw`／读回、`cacheAsBitmap` 和运行时横屏锁定。Unity 原生三维、摄像机和 RenderTexture 可与二维后端共存。

对应能力值可查询 `hx.unity.Capabilities`。不要通过添加 `hxmaker_scene3d`、`hxmaker_text_input`、`hxmaker_filters`、`hxmaker_advanced_blend`、`hxmaker_custom_shader`、`hxmaker_native_display`、`hxmaker_bitmap_draw` 假装启用这些功能；构建宏会明确拒绝。业务用后端条件选择替代方案：

```haxe
#if !hxmaker_unity
image.filters = [new hx.filters.BlurFilter()];
#end
```

复杂文字整形、双向文字、emoji 组合序列、精确复刻 OpenFL 排版、容器 ADD 的离屏分组合成语义暂不保证。容器 ADD 在首版将加法状态传给后代，重叠对象不会先组成透明度组。颜色和透明边缘需在所选 Unity 色彩空间下验收。

## 待用户安排的验证

遵守项目约定，本次不自动运行编译或测试。后续应依次确认：

1. Haxe C# 生成、Unity 内置管线导入、URP 14 与 URP 17 两条路径。
2. 超过 8 张纹理自动拆批，关闭多纹理后画面一致；平滑／像素风混用、NORMAL／ADD。
3. 中文字体重排、文本尺寸、范围颜色、换行、描边；列表、九宫格、平铺、嵌套裁剪。
4. 两台摄像机、分屏、目标纹理、指针拖出视口、焦点丢失、触摸和键盘 Tab。
5. Future 并发合并、失败重试、共享图集引用、加载释放循环、音频完成和重新进入播放模式。
6. 桌面与移动端 IL2CPP 发布、反射裁剪、Shader 变体保留、色彩空间和帧耗时。

验收通过前，不将本仓库标记为生产可用。
