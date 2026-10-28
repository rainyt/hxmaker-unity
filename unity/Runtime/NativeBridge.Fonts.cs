using System;
using System.Collections.Generic;
using UnityEngine;

namespace Hxmaker.Unity
{
    public static partial class NativeBridge
    {
        private static readonly Dictionary<string, Font> fonts = new Dictionary<string, Font>();
        private static readonly HashSet<Font> ownedFonts = new HashSet<Font>();
        private static int fontVersion;
        public static int fontRevision() { return fontVersion; }
        private static void OnFontRebuilt(Font font) { fontVersion++; }
        public static void RegisterFont(string name, Font font)
        {
            if (font == null || !font.dynamic) throw new ArgumentException("Hxmaker 字体必须是动态字体");
            fonts[name ?? ""] = font; fontVersion++;
        }
        private static Font ResolveFont(string name)
        {
            string key = name ?? "";
            if (fonts.TryGetValue(key, out Font font)) return font;
            if (string.IsNullOrEmpty(key))
            {
                font = Host.DefaultFont != null ? Host.DefaultFont : Resources.GetBuiltinResource<Font>("LegacyRuntime.ttf");
            }
            else
            {
                font = Font.CreateDynamicFontFromOSFont(key, 16);
                if (font != null) ownedFonts.Add(font);
            }
            if (font == null) throw new InvalidOperationException("找不到动态字体，请在 Hxmaker 宿主上配置字体：" + key);
            fonts.Add(key, font); return font;
        }
        public static void requestFont(string name, string text, int size) { ResolveFont(name).RequestCharactersInTexture(text, Math.Max(1, size), FontStyle.Normal); }
        public static double[] fontMetrics(string name, int size)
        {
            Font font = ResolveFont(name);
            double scale = (double)size / Math.Max(1, font.fontSize);
            return new double[] { Math.Max(size, font.lineHeight * scale), font.ascent * scale };
        }
        public static double[] glyph(string name, int size, int code)
        {
            Font font = ResolveFont(name);
            if (code == 10 || code == 13) return new double[14];
            if (!font.GetCharacterInfo((char)code, out CharacterInfo info, size, FontStyle.Normal))
                return new double[] { size * 0.5, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 };
            Texture atlas = font.material.mainTexture;
            int texture = textureIds.TryGetValue(atlas, out int existing) ? existing : RegisterTexture(atlas, false);
            // 对外统一为左上角 UV，普通图片与字形走同一个批处理程序。
            return new double[] { info.advance, info.minX, info.maxX, info.minY, info.maxY,
                info.uvTopLeft.x, 1 - info.uvTopLeft.y, info.uvTopRight.x, 1 - info.uvTopRight.y,
                info.uvBottomLeft.x, 1 - info.uvBottomLeft.y, info.uvBottomRight.x, 1 - info.uvBottomRight.y, texture };
        }
        private static void DisposeFonts()
        {
            foreach (Font font in ownedFonts) if (font != null) UnityEngine.Object.Destroy(font);
            fonts.Clear(); ownedFonts.Clear(); fontVersion++;
        }
    }
}
