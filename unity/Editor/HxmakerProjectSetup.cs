using System;
using System.IO;
using UnityEditor;
using UnityEditor.SceneManagement;
using UnityEngine;
using UnityEngine.SceneManagement;

namespace Hxmaker.Unity.Editor
{
    // 由 CLI 或编辑器菜单创建可直接进入播放模式的默认场景。
    public static class HxmakerProjectSetup
    {
        [MenuItem("Tools/Hxmaker/创建默认场景")]
        public static void CreateScene()
        {
            string scenePath = "Assets/Scenes/Main.unity";
            if (File.Exists(scenePath))
            {
                Debug.Log("Hxmaker 默认场景已存在，保留现有场景：" + scenePath);
                return;
            }
            Type gameType = Type.GetType("Hxmaker.Unity.Generated.HxmakerGame, Hxmaker.Unity.Generated");
            if (gameType == null) throw new InvalidOperationException("请先编译 Haxe 并导入 C# 源码");
            Scene scene = EditorSceneManager.NewScene(NewSceneSetup.EmptyScene, NewSceneMode.Single);
            GameObject application = new GameObject("Hxmaker");
            HxmakerHost host = (HxmakerHost)application.AddComponent(gameType);
            host.BatchShader = Shader.Find("Hxmaker/MultiTexture");
            if (host.BatchShader == null) throw new InvalidOperationException("未找到 Hxmaker 多纹理 Shader");
            GameObject cameraObject = new GameObject("Main Camera"); cameraObject.tag = "MainCamera";
            Camera camera = cameraObject.AddComponent<Camera>(); camera.transform.position = new Vector3(0, 0, -10);
            camera.backgroundColor = new Color(0.06f, 0.09f, 0.15f); camera.clearFlags = CameraClearFlags.SolidColor;
            cameraObject.AddComponent<AudioListener>(); cameraObject.AddComponent<HxmakerView>();
            GameObject previewObject = new GameObject("Preview Camera");
            Camera preview = previewObject.AddComponent<Camera>(); preview.transform.position = new Vector3(0, 0, -10);
            preview.rect = new Rect(0.72f, 0.68f, 0.26f, 0.29f); preview.depth = 1;
            preview.backgroundColor = camera.backgroundColor; preview.clearFlags = CameraClearFlags.SolidColor;
            HxmakerView previewView = previewObject.AddComponent<HxmakerView>(); previewView.AcceptInput = false;
            GameObject cube = GameObject.CreatePrimitive(PrimitiveType.Cube); cube.name = "Unity 原生方块";
            cube.transform.position = new Vector3(2, 0, 0); cube.transform.rotation = Quaternion.Euler(20, 35, 0);
            GameObject lightObject = new GameObject("Directional Light"); Light light = lightObject.AddComponent<Light>();
            light.type = LightType.Directional; lightObject.transform.rotation = Quaternion.Euler(50, -30, 0);
            Directory.CreateDirectory("Assets/Scenes"); EditorSceneManager.SaveScene(scene, scenePath);
            EditorBuildSettings.scenes = new EditorBuildSettingsScene[] { new EditorBuildSettingsScene(scenePath, true) };
            PlayerSettings.defaultScreenWidth = 960; PlayerSettings.defaultScreenHeight = 540;
            PlayerSettings.runInBackground = true;
            AssetDatabase.SaveAssets(); Debug.Log("已创建 Hxmaker Unity 示例场景：" + scenePath);
        }
    }
}
