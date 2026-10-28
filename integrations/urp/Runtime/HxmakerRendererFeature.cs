using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;
#if UNITY_6000_0_OR_NEWER
using UnityEngine.Rendering.RenderGraphModule;
#endif

namespace Hxmaker.Unity.URP
{
    public sealed class HxmakerRendererFeature : ScriptableRendererFeature
    {
        private HxmakerPass pass;
        public RenderPassEvent InjectionPoint = RenderPassEvent.AfterRenderingPostProcessing;
        public override void Create() { pass = new HxmakerPass { renderPassEvent = InjectionPoint }; }
        public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
        {
            Camera camera = renderingData.cameraData.camera;
            if (HxmakerHost.Active == null || HxmakerView.ForCamera(camera).Count == 0) return;
            pass.Renderer = renderer; pass.renderPassEvent = InjectionPoint; renderer.EnqueuePass(pass);
        }
        protected override void Dispose(bool disposing) { if (pass != null) pass.Dispose(); }
        private sealed class HxmakerPass : ScriptableRenderPass
        {
            internal ScriptableRenderer Renderer;
#if UNITY_6000_0_OR_NEWER
            private readonly Dictionary<RenderTexture, RTHandle> imported = new Dictionary<RenderTexture, RTHandle>();
            private sealed class PassData { internal Camera Camera; internal TextureHandle Target; }
            public override void RecordRenderGraph(RenderGraph graph, ContextContainer frame)
            {
                UniversalResourceData resources = frame.Get<UniversalResourceData>();
                UniversalCameraData camera = frame.Get<UniversalCameraData>();
                using (IUnsafeRenderGraphBuilder builder = graph.AddUnsafePass<PassData>("Hxmaker 二维合成", out PassData data))
                {
                    data.Camera = camera.camera; data.Target = resources.activeColorTexture;
                    builder.UseTexture(data.Target, AccessFlags.ReadWrite);
                    foreach (RenderTexture texture in NativeBridge.RenderTextures(data.Camera))
                    {
                        if (!imported.TryGetValue(texture, out RTHandle handle)) { handle = RTHandles.Alloc(texture); imported.Add(texture, handle); }
                        builder.UseTexture(graph.ImportTexture(handle), AccessFlags.Read);
                    }
                    builder.AllowPassCulling(false); builder.AllowGlobalStateModification(true);
                    builder.SetRenderFunc((PassData value, UnsafeGraphContext context) =>
                    {
                        CommandBuffer command = CommandBufferHelpers.GetNativeCommandBuffer(context.cmd);
                        command.SetRenderTarget(value.Target);
                        NativeBridge.Record(command, value.Camera);
                    });
                }
            }
#endif
            public override void OnCameraSetup(CommandBuffer command, ref RenderingData renderingData)
            {
                ConfigureTarget(Renderer.cameraColorTargetHandle);
            }
            public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
            {
                CommandBuffer command = CommandBufferPool.Get("Hxmaker 二维合成");
                try
                {
                    NativeBridge.Record(command, renderingData.cameraData.camera); context.ExecuteCommandBuffer(command);
                }
                finally { CommandBufferPool.Release(command); }
            }
            internal void Dispose()
            {
#if UNITY_6000_0_OR_NEWER
                foreach (RTHandle handle in imported.Values) handle.Release(); imported.Clear();
#endif
            }
        }
    }
}
