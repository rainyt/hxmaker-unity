using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

namespace Hxmaker.Unity
{
    // 一台摄像机可有多个视口；分屏与 RenderTexture 摄像机共享同一份业务更新。
    [RequireComponent(typeof(Camera))]
    public sealed class HxmakerView : MonoBehaviour
    {
        public int Surface;
        public int Order;
        public bool AcceptInput = true;
        public bool PreserveAspect = true;
        private Camera cameraComponent;
        private CommandBuffer commands;
        private static readonly List<HxmakerView> views = new List<HxmakerView>();
        public Camera Camera { get { if (cameraComponent == null) cameraComponent = GetComponent<Camera>(); return cameraComponent; } }
        public Rect PixelViewport
        {
            get
            {
                Rect rect = Camera.pixelRect;
                if (!PreserveAspect || !NativeBridge.TryGetSurface(Surface, out NativeBridge.Surface surface)) return rect;
                float scale = Mathf.Min(rect.width / surface.Width, rect.height / surface.Height);
                float width = surface.Width * scale; float height = surface.Height * scale;
                return new Rect(rect.x + (rect.width - width) * 0.5f, rect.y + (rect.height - height) * 0.5f, width, height);
            }
        }
        private void OnEnable() { views.Add(this); }
        private void OnDisable()
        {
            views.Remove(this);
            if (commands != null) { Camera.RemoveCommandBuffer(CameraEvent.AfterEverything, commands); commands.Release(); commands = null; }
        }
        private void OnPreRender()
        {
            if (GraphicsSettings.currentRenderPipeline != null) return;
            if (commands == null)
            {
                commands = new CommandBuffer { name = "Hxmaker 二维合成" }; Camera.AddCommandBuffer(CameraEvent.AfterEverything, commands);
            }
            commands.Clear();
            // 同一摄像机只由排序最前的组件录制一次，避免重复绘制。
            List<HxmakerView> selected = ForCamera(Camera);
            if (selected.Count > 0 && selected[0] == this) NativeBridge.Record(commands, Camera);
        }
        public bool Map(Vector2 screen, out Vector2 logical, bool allowOutside = false)
        {
            logical = Vector2.zero;
            if (!isActiveAndEnabled || !NativeBridge.TryGetSurface(Surface, out NativeBridge.Surface surface)) return false;
            Rect rect = PixelViewport;
            if (rect.width <= 0 || rect.height <= 0 || (!allowOutside && !rect.Contains(screen))) return false;
            logical = new Vector2((screen.x - rect.x) * surface.Width / rect.width, (rect.yMax - screen.y) * surface.Height / rect.height);
            return true;
        }
        public static List<HxmakerView> ForCamera(Camera camera)
        {
            List<HxmakerView> selected = new List<HxmakerView>();
            foreach (HxmakerView view in views) if (view != null && view.isActiveAndEnabled && view.Camera == camera) selected.Add(view);
            selected.Sort((a, b) => a.Order.CompareTo(b.Order)); return selected;
        }
        internal static HxmakerView Pick(Vector2 screen)
        {
            HxmakerView selected = null;
            foreach (HxmakerView view in views)
            {
                if (view == null || !view.isActiveAndEnabled || !view.Camera.isActiveAndEnabled || !view.AcceptInput || view.Camera.targetTexture != null || !view.PixelViewport.Contains(screen)) continue;
                if (selected == null || view.Camera.depth > selected.Camera.depth || (view.Camera.depth == selected.Camera.depth && view.Order > selected.Order)) selected = view;
            }
            return selected;
        }
    }
}
