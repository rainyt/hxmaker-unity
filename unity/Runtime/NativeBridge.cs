using System;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

namespace Hxmaker.Unity
{
    // Haxe 仅通过强类型静态方法调用，避免为整个 UnityEngine 生成 extern。
    public static partial class NativeBridge
    {
        private static readonly Dictionary<int, Surface> surfaces = new Dictionary<int, Surface>();
        private static readonly Dictionary<int, TextureEntry> textures = new Dictionary<int, TextureEntry>();
        private static readonly Dictionary<Texture, int> textureIds = new Dictionary<Texture, int>();
        private static int nextTexture = 1;
        private static int slots = 8;
        internal static HxmakerHost Host;
        public static int textureSlots() { return slots; }
        public static double pixelRatio() { return 1.0; }
        public static void targetFrameRate(int value) { Application.targetFrameRate = value; }
        public static string platform() { return Application.platform.ToString().ToLowerInvariant(); }
        public static bool isDesktop() { return !Application.isMobilePlatform; }
        public static void writeClipboard(string text) { GUIUtility.systemCopyBuffer = text; }
        public static string readClipboard() { return GUIUtility.systemCopyBuffer; }
        public static void log(string message) { Debug.Log(message); }

        internal static void Initialize(HxmakerHost host, int requestedSlots)
        {
            Host = host;
            // 首版只包含 1、4、8 槽变体；保守设备或排障可由宿主限制为单纹理。
            slots = SystemInfo.graphicsShaderLevel < 35 ? 1 : requestedSlots >= 8 ? 8 : requestedSlots >= 4 ? 4 : 1;
            if (SystemInfo.graphicsShaderLevel < 35)
                throw new NotSupportedException("Hxmaker 首版要求 Shader Model 3.5 或对应的移动图形能力");
            Font.textureRebuilt += OnFontRebuilt;
        }

        public static void beginFrame(int surface, double width, double height)
        {
            if (!surfaces.TryGetValue(surface, out Surface value))
            {
                value = new Surface(); surfaces.Add(surface, value);
            }
            if (width <= 0 || height <= 0) throw new ArgumentOutOfRangeException("逻辑舞台尺寸必须大于零");
            value.Width = (float)width; value.Height = (float)height; value.Used = 0;
        }

        public static void submit(int surface, double[] data, int[] indices, int[] handles, bool smoothing,
            double clipX, double clipY, double clipWidth, double clipHeight)
        {
            Surface value = surfaces[surface];
            if (handles.Length < 1 || handles.Length > slots || data.Length % 16 != 0)
                throw new ArgumentException("Hxmaker 批次顶点或纹理槽位数据无效");
            if (value.Used == value.Batches.Count) value.Batches.Add(new Batch(Host.BatchShader));
            Batch batch = value.Batches[value.Used++];
            batch.Update(data, indices, handles, smoothing, new Vector4((float)clipX, (float)clipY, (float)(clipX + clipWidth), (float)(clipY + clipHeight)));
        }

        public static void endFrame(int surface)
        {
            if (!surfaces.TryGetValue(surface, out Surface value)) return;
            while (value.Batches.Count > value.Used)
            {
                int last = value.Batches.Count - 1;
                value.Batches[last].Dispose(); value.Batches.RemoveAt(last);
            }
        }

        public static void disposeSurface(int surface)
        {
            if (!surfaces.TryGetValue(surface, out Surface value)) return;
            foreach (Batch batch in value.Batches) batch.Dispose();
            surfaces.Remove(surface);
        }

        internal static bool TryGetSurface(int id, out Surface value) { return surfaces.TryGetValue(id, out value); }

        // 不切换渲染目标，由内置管线或 URP 通道提供当前摄像机目标。
        public static void Record(CommandBuffer command, Camera camera)
        {
            foreach (HxmakerView view in HxmakerView.ForCamera(camera))
            {
                if (!surfaces.TryGetValue(view.Surface, out Surface surface)) continue;
                Rect viewport = view.PixelViewport;
                command.SetViewport(viewport);
                foreach (Batch batch in surface.Batches)
                {
                    foreach (Texture texture in batch.Textures)
                        if (texture != null && texture == camera.targetTexture)
                            throw new InvalidOperationException("不能同时采样并绘制到同一摄像机目标纹理");
                    batch.Properties.SetVector("_HxResolution", new Vector4(surface.Width, surface.Height, 0, 0));
                    command.DrawMesh(batch.Mesh, Matrix4x4.identity, batch.Material, 0, 0, batch.Properties);
                }
            }
            command.SetViewport(camera.pixelRect);
        }

        public static IEnumerable<RenderTexture> RenderTextures(Camera camera)
        {
            HashSet<RenderTexture> found = new HashSet<RenderTexture>();
            foreach (HxmakerView view in HxmakerView.ForCamera(camera))
                if (surfaces.TryGetValue(view.Surface, out Surface surface))
                    foreach (Batch batch in surface.Batches)
                        foreach (Texture texture in batch.Textures)
                            if (texture is RenderTexture target && found.Add(target)) yield return target;
        }

        public static int RegisterTexture(Texture texture, bool owned = false)
        {
            if (texture == null) throw new ArgumentNullException(nameof(texture));
            if (textureIds.TryGetValue(texture, out int existing))
            {
                textures[existing].References++; return existing;
            }
            int id = nextTexture++;
            textures.Add(id, new TextureEntry(texture, owned)); textureIds.Add(texture, id); return id;
        }
        internal static Texture GetTexture(int id)
        {
            if (id == 0) return Texture2D.whiteTexture;
            if (!textures.TryGetValue(id, out TextureEntry entry) || entry.Texture == null)
                throw new InvalidOperationException("纹理句柄已失效：" + id);
            return entry.Texture;
        }
        public static int textureWidth(int id) { return GetTexture(id).width; }
        public static int textureHeight(int id) { return GetTexture(id).height; }
        public static int createTexture(string base64)
        {
            Texture2D texture = new Texture2D(2, 2, TextureFormat.RGBA32, false);
            try
            {
                if (!ImageConversion.LoadImage(texture, Convert.FromBase64String(base64), false))
                    throw new InvalidOperationException("Unity 无法解码图片；首版内存图片支持 PNG/JPEG");
                return RegisterTexture(texture, true);
            }
            catch { UnityEngine.Object.Destroy(texture); throw; }
        }
        public static int createSolidTexture(int width, int height, int color)
        {
            if (width <= 0 || height <= 0) throw new ArgumentOutOfRangeException("纹理尺寸必须大于零");
            Texture2D texture = new Texture2D(width, height, TextureFormat.RGBA32, false);
            Color32 value = new Color32((byte)(color >> 16), (byte)(color >> 8), (byte)color, (byte)((uint)color >> 24));
            Color32[] pixels = new Color32[width * height];
            for (int i = 0; i < pixels.Length; i++) pixels[i] = value;
            texture.SetPixels32(pixels); texture.Apply(); return RegisterTexture(texture, true);
        }
        public static void clearTexture(int id, int x, int y, int width, int height)
        {
            Texture2D texture = GetTexture(id) as Texture2D;
            if (texture == null || !texture.isReadable) throw new InvalidOperationException("当前纹理不支持 CPU 清除");
            if (x < 0 || y < 0 || width < 0 || height < 0 || x + width > texture.width || y + height > texture.height)
                throw new ArgumentOutOfRangeException("清除区域超出纹理边界");
            texture.SetPixels(x, texture.height - y - height, width, height, new Color[width * height]); texture.Apply();
        }
        public static void releaseTexture(int id)
        {
            if (!textures.TryGetValue(id, out TextureEntry entry)) return;
            if (--entry.References > 0) return;
            textures.Remove(id); textureIds.Remove(entry.Texture);
            if (entry.Owned && entry.Texture != null) UnityEngine.Object.Destroy(entry.Texture);
        }
        public static void storageSet(string key, string value) { PlayerPrefs.SetString(key, value); PlayerPrefs.Save(); }
        public static string storageGet(string key) { return PlayerPrefs.HasKey(key) ? PlayerPrefs.GetString(key) : null; }
        public static void storageRemove(string key) { PlayerPrefs.DeleteKey(key); PlayerPrefs.Save(); }

        internal static void Shutdown()
        {
            Font.textureRebuilt -= OnFontRebuilt;
            foreach (Surface surface in surfaces.Values) foreach (Batch batch in surface.Batches) batch.Dispose();
            surfaces.Clear();
            foreach (TextureEntry entry in textures.Values) if (entry.Owned && entry.Texture != null) UnityEngine.Object.Destroy(entry.Texture);
            textures.Clear(); textureIds.Clear();
            DisposeRequests(); DisposeAudio(); DisposeFonts(); Host = null;
        }
        private sealed class TextureEntry
        {
            internal readonly Texture Texture;
            internal readonly bool Owned;
            internal int References = 1;
            internal TextureEntry(Texture texture, bool owned) { Texture = texture; Owned = owned; }
        }
        internal sealed class Surface
        {
            internal float Width;
            internal float Height;
            internal int Used;
            internal readonly List<Batch> Batches = new List<Batch>();
        }
        internal sealed class Batch : IDisposable
        {
            internal readonly Mesh Mesh;
            internal readonly Material Material;
            internal readonly MaterialPropertyBlock Properties = new MaterialPropertyBlock();
            internal Texture[] Textures = Array.Empty<Texture>();
            private Vector3[] positions = Array.Empty<Vector3>();
            private Vector2[] uvs = Array.Empty<Vector2>();
            private Color[] colors = Array.Empty<Color>();
            private readonly List<Vector4> offsets = new List<Vector4>();
            private readonly List<Vector4> properties = new List<Vector4>();
            internal Batch(Shader shader)
            {
                if (shader == null || !shader.isSupported) throw new InvalidOperationException("请在宿主上配置可用的 Hxmaker/MultiTexture Shader");
                Mesh = new Mesh { name = "Hxmaker 批次", hideFlags = HideFlags.DontSave }; Mesh.MarkDynamic();
                Material = new Material(shader) { hideFlags = HideFlags.DontSave };
            }
            internal void Update(double[] data, int[] indices, int[] handles, bool smoothing, Vector4 clip)
            {
                int count = data.Length / 16;
                if (count > 65535) throw new ArgumentOutOfRangeException("批次顶点超过 16 位索引范围");
                if (positions.Length != count) { positions = new Vector3[count]; uvs = new Vector2[count]; colors = new Color[count]; }
                offsets.Clear(); properties.Clear();
                for (int i = 0; i < count; i++)
                {
                    int p = i * 16;
                    positions[i] = new Vector3((float)data[p], (float)data[p + 1], 0);
                    uvs[i] = new Vector2((float)data[p + 2], (float)data[p + 3]);
                    colors[i] = new Color((float)data[p + 4], (float)data[p + 5], (float)data[p + 6], (float)data[p + 7]);
                    offsets.Add(new Vector4((float)data[p + 8], (float)data[p + 9], (float)data[p + 10], (float)data[p + 11]));
                    properties.Add(new Vector4((float)data[p + 12], (float)data[p + 13], (float)data[p + 14], (float)data[p + 15]));
                }
                Mesh.Clear(); Mesh.vertices = positions; Mesh.uv = uvs; Mesh.colors = colors; Mesh.SetUVs(1, offsets); Mesh.SetUVs(2, properties);
                Mesh.SetIndices(indices, MeshTopology.Triangles, 0, false);
                Mesh.bounds = new Bounds(Vector3.zero, new Vector3(1e8f, 1e8f, 1));
                Properties.Clear(); if (Textures.Length != handles.Length) Textures = new Texture[handles.Length];
                for (int i = 0; i < handles.Length; i++) { Textures[i] = GetTexture(handles[i]); Properties.SetTexture("_HxTex" + i, Textures[i]); }
                Properties.SetVector("_HxClip", clip); Properties.SetFloat("_HxSmooth", smoothing ? 1 : 0);
                Material.DisableKeyword("HX_TEXTURES_4"); Material.DisableKeyword("HX_TEXTURES_8");
                if (handles.Length > 4) Material.EnableKeyword("HX_TEXTURES_8"); else if (handles.Length > 1) Material.EnableKeyword("HX_TEXTURES_4");
            }
            public void Dispose() { UnityEngine.Object.Destroy(Mesh); UnityEngine.Object.Destroy(Material); }
        }
    }
}
