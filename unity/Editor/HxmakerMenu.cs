using System;
using UnityEditor;
using UnityEngine;

namespace Hxmaker.Unity.Editor
{
    internal static class HxmakerMenu
    {
        [MenuItem("GameObject/Hxmaker/创建宿主与摄像机", false, 10)]
        private static void CreateHost()
        {
            Type type = Type.GetType("Hxmaker.Unity.Generated.HxmakerGame, Hxmaker.Unity.Generated");
            if (type == null) { EditorUtility.DisplayDialog("Hxmaker", "请先编译 Haxe 并运行 export_unity.py 导入生成源码。", "确定"); return; }
            if (UnityEngine.Object.FindObjectOfType<HxmakerHost>() != null)
            { EditorUtility.DisplayDialog("Hxmaker", "当前场景已经存在宿主。", "确定"); return; }
            GameObject owner = new GameObject("Hxmaker"); Undo.RegisterCreatedObjectUndo(owner, "创建 Hxmaker 宿主");
            HxmakerHost host = (HxmakerHost)Undo.AddComponent(owner, type);
            host.BatchShader = Shader.Find("Hxmaker/MultiTexture");
            Camera camera = Camera.main;
            if (camera == null)
            {
                GameObject cameraObject = new GameObject("Hxmaker Camera"); Undo.RegisterCreatedObjectUndo(cameraObject, "创建摄像机");
                camera = Undo.AddComponent<Camera>(cameraObject); camera.tag = "MainCamera";
            }
            if (camera.GetComponent<HxmakerView>() == null) Undo.AddComponent<HxmakerView>(camera.gameObject);
            EditorUtility.SetDirty(host); Selection.activeGameObject = owner;
        }
    }
}
