using System;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

namespace Hxmaker.Unity
{
    [Serializable]
    public sealed class FontAlias
    {
        public string Name;
        public Font Font;
    }

    // 导出工具生成的入口继承此类；全部 Haxe 回调均在 Unity 主线程执行。
    [DefaultExecutionOrder(-1000)]
    public abstract class HxmakerHost : MonoBehaviour
    {
        public static HxmakerHost Active { get; private set; }
        public Shader BatchShader;
        public Font DefaultFont;
        public FontAlias[] Fonts = Array.Empty<FontAlias>();
        [Range(1, 8)] public int TextureSlots = 8;
        [Min(1)] public int RequestTimeout = 30;
        public bool UseUnscaledTime;
        public bool PollLegacyInput = true;
        public Action<double> TickHandler;
        public Action<double, double> ResizeHandler;
        public Action<string, double, double, int, double> PointerHandler;
        public Action<string, int, int> KeyboardHandler;
        public Action<bool> FocusHandler;
        public Action ShutdownHandler;
        private readonly Dictionary<int, PointerState> pointers = new Dictionary<int, PointerState>();
        private readonly HashSet<int> pressedKeys = new HashSet<int>();
        private Vector2Int lastSize;
        private bool running;
        private bool previousMouseSimulation;
        private int primaryTouch = -1;
        private Vector2 lastMouse;
        private bool mouseKnown;
        private static readonly KeyCode[] keys = (KeyCode[])Enum.GetValues(typeof(KeyCode));
        protected abstract void Boot();

        protected virtual void Awake()
        {
            if (Active != null) { Debug.LogError("当前进程只能启动一个 HxmakerHost", this); enabled = false; return; }
            Active = this;
            try
            {
                if (BatchShader == null) BatchShader = Shader.Find("Hxmaker/MultiTexture");
                NativeBridge.Initialize(this, TextureSlots);
                foreach (FontAlias alias in Fonts) NativeBridge.RegisterFont(alias.Name, alias.Font);
                Boot(); running = true;
                #if ENABLE_LEGACY_INPUT_MANAGER || !ENABLE_INPUT_SYSTEM
                previousMouseSimulation = Input.simulateMouseWithTouches;
                Input.simulateMouseWithTouches = false;
#endif
            }
            catch (Exception error) { Debug.LogException(error, this); enabled = false; Cleanup(); }
        }
        protected virtual void Update()
        {
            if (!running) return;
            if (lastSize.x != Screen.width || lastSize.y != Screen.height)
            {
                lastSize = new Vector2Int(Screen.width, Screen.height); ResizeHandler?.Invoke(lastSize.x, lastSize.y);
            }
#if ENABLE_LEGACY_INPUT_MANAGER || !ENABLE_INPUT_SYSTEM
            if (PollLegacyInput) PollInput();
#endif
        }
        protected virtual void LateUpdate()
        {
            if (running) TickHandler?.Invoke(UseUnscaledTime ? Time.unscaledDeltaTime : Time.deltaTime);
        }
        protected virtual void OnApplicationFocus(bool active)
        {
            if (!running) return;
            if (!active) CancelInput();
            FocusHandler?.Invoke(active);
        }
        protected virtual void OnDisable() { if (running) CancelInput(); }
        protected virtual void OnDestroy() { if (Active == this) Cleanup(); }
        private void Cleanup()
        {
            if (Active != this) return;
            try { if (running) CancelInput(); ShutdownHandler?.Invoke(); }
            finally
            {
                #if ENABLE_LEGACY_INPUT_MANAGER || !ENABLE_INPUT_SYSTEM
                if (running) Input.simulateMouseWithTouches = previousMouseSimulation;
#endif
                running = false; NativeBridge.Shutdown(); Active = null;
                TickHandler = null; ResizeHandler = null; PointerHandler = null; KeyboardHandler = null; FocusHandler = null; ShutdownHandler = null;
            }
        }
        // 新输入系统或业务输入桥也使用此入口；屏幕坐标原点为左下角。
        public bool RoutePointer(string type, Vector2 screen, int id = -1, double delta = 0)
        {
            int key = id < 0 ? -1 : id;
            bool begin = type == "mouseDown" || type == "rightMouseDown" || type == "touchBegin";
            bool end = type == "mouseUp" || type == "rightMouseUp" || type == "touchEnd" || type == "touchCancel";
            pointers.TryGetValue(key, out PointerState state);
            HxmakerView view = state != null ? state.View : HxmakerView.Pick(screen);
            if (view == null || !view.Map(screen, out Vector2 point, state != null)) return false;
            if (begin) { state = new PointerState { View = view, Start = screen, Last = screen }; pointers[key] = state; }
            if (state != null) { state.Last = screen; state.MaxDistance = Mathf.Max(state.MaxDistance, (screen - state.Start).sqrMagnitude); }
            PointerHandler?.Invoke(type, point.x, point.y, id, delta);
            if (end) pointers.Remove(key);
            return true;
        }
        public void RouteKeyboard(string type, int code, int modifiers)
        {
            if (type == "keyDown") pressedKeys.Add(code); else pressedKeys.Remove(code);
            KeyboardHandler?.Invoke(type, code, modifiers);
        }
        private void CancelInput()
        {
            foreach (KeyValuePair<int, PointerState> pair in new Dictionary<int, PointerState>(pointers))
                RoutePointer(pair.Key < 0 ? "mouseUp" : "touchCancel", pair.Value.Last, pair.Key);
            pointers.Clear(); primaryTouch = -1;
            foreach (int code in new List<int>(pressedKeys)) RouteKeyboard("keyUp", code, 0);
        }
#if ENABLE_LEGACY_INPUT_MANAGER || !ENABLE_INPUT_SYSTEM
        private void PollInput()
        {
            Vector2 mouse = Input.mousePosition;
            if (!mouseKnown || mouse != lastMouse)
            {
                mouseKnown = true; lastMouse = mouse;
                if (primaryTouch < 0) RoutePointer("mouseMove", mouse);
            }
            for (int button = 0; button < 2; button++)
            {
                string down = button == 0 ? "mouseDown" : "rightMouseDown";
                string up = button == 0 ? "mouseUp" : "rightMouseUp";
                string click = button == 0 ? "click" : "rightClick";
                if (Input.GetMouseButtonDown(button)) RoutePointer(down, mouse);
                if (Input.GetMouseButtonUp(button))
                {
                    bool clicked = pointers.TryGetValue(-1, out PointerState state) && Mathf.Max(state.MaxDistance, (mouse - state.Start).sqrMagnitude) <= 25 && state.View.PixelViewport.Contains(mouse);
                    RoutePointer(up, mouse);
                    if (clicked) RoutePointer(click, mouse);
                }
            }
            if (Input.mouseScrollDelta.y != 0) RoutePointer("mouseWheel", mouse, -1, Input.mouseScrollDelta.y);
            for (int i = 0; i < Input.touchCount; i++)
            {
                Touch touch = Input.GetTouch(i);
                string type = touch.phase == TouchPhase.Began ? "touchBegin" : touch.phase == TouchPhase.Ended ? "touchEnd" : touch.phase == TouchPhase.Canceled ? "touchCancel" : "touchMove";
                bool clicked = pointers.TryGetValue(touch.fingerId, out PointerState state) && Mathf.Max(state.MaxDistance, (touch.position - state.Start).sqrMagnitude) <= 25;
                RoutePointer(type, touch.position, touch.fingerId);
                // 首指合成鼠标交互，让 Button、Scroll 和长按使用已有组件逻辑。
                if (primaryTouch < 0 && touch.phase == TouchPhase.Began) primaryTouch = touch.fingerId;
                if (touch.fingerId == primaryTouch)
                {
                    if (touch.phase == TouchPhase.Began) RoutePointer("mouseDown", touch.position);
                    else if (touch.phase == TouchPhase.Ended || touch.phase == TouchPhase.Canceled)
                    {
                        RoutePointer("mouseUp", touch.position);
                        if (clicked && touch.phase == TouchPhase.Ended) RoutePointer("click", touch.position);
                        primaryTouch = -1;
                    }
                    else if (touch.phase == TouchPhase.Moved) RoutePointer("mouseMove", touch.position);
                }
            }
            int modifiers = (Input.GetKey(KeyCode.LeftShift) || Input.GetKey(KeyCode.RightShift) ? 1 : 0)
                | (Input.GetKey(KeyCode.LeftControl) || Input.GetKey(KeyCode.RightControl) ? 2 : 0)
                | (Input.GetKey(KeyCode.LeftAlt) || Input.GetKey(KeyCode.RightAlt) ? 4 : 0)
                | (Input.GetKey(KeyCode.LeftCommand) || Input.GetKey(KeyCode.RightCommand) ? 8 : 0);
            foreach (KeyCode key in keys)
            {
                int code = KeyCodeFor(key); if (code == 0) continue;
                if (Input.GetKeyDown(key)) RouteKeyboard("keyDown", code, modifiers);
                if (Input.GetKeyUp(key)) RouteKeyboard("keyUp", code, modifiers);
            }
        }
        private static int KeyCodeFor(KeyCode key)
        {
            if ((int)key >= (int)KeyCode.A && (int)key <= (int)KeyCode.Z) return (int)key - (int)KeyCode.A + 65;
            if ((int)key >= (int)KeyCode.F1 && (int)key <= (int)KeyCode.F15) return (int)key - (int)KeyCode.F1 + 112;
            switch (key)
            {
                case KeyCode.LeftArrow: return 37; case KeyCode.UpArrow: return 38; case KeyCode.RightArrow: return 39; case KeyCode.DownArrow: return 40;
                case KeyCode.LeftShift: case KeyCode.RightShift: return 16;
                case KeyCode.LeftControl: case KeyCode.RightControl: return 17;
                case KeyCode.LeftAlt: case KeyCode.RightAlt: return 18;
                case KeyCode.LeftCommand: case KeyCode.RightCommand: return 15;
                case KeyCode.Home: return 36; case KeyCode.End: return 35; case KeyCode.PageUp: return 33; case KeyCode.PageDown: return 34;
                case KeyCode.Insert: return 45; case KeyCode.Delete: return 46;
                default: return (int)key > 0 && (int)key <= 127 ? (int)key : 0;
            }
        }
#endif
        private sealed class PointerState
        {
            internal HxmakerView View; internal Vector2 Start; internal Vector2 Last; internal float MaxDistance;
        }
    }
}
