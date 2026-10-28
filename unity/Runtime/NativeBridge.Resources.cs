using System;
using System.Collections;
using System.Collections.Generic;
using System.IO;
using UnityEngine;
using UnityEngine.Networking;

namespace Hxmaker.Unity
{
    public static partial class NativeBridge
    {
        private static readonly Dictionary<int, Request> requests = new Dictionary<int, Request>();
        private static readonly Dictionary<int, AudioClip> sounds = new Dictionary<int, AudioClip>();
        private static readonly Dictionary<int, Channel> channels = new Dictionary<int, Channel>();
        private static int nextRequest = 1;
        private static int nextSound = 1;
        private static int nextChannel = 1;

        public static int beginRequest(string path, int kind)
        {
            if (Host == null) throw new InvalidOperationException("Unity 宿主尚未启动");
            Request request = new Request { Kind = kind };
            int id = nextRequest++; requests.Add(id, request);
            request.Coroutine = Host.StartCoroutine(Load(request, path)); return id;
        }
        public static int requestStatus(int id) { return requests.TryGetValue(id, out Request value) ? value.Status : -1; }
        public static string requestError(int id) { return requests.TryGetValue(id, out Request value) ? value.Error : "资源请求已取消"; }
        public static string requestBytes(int id) { return Convert.ToBase64String(requests[id].Bytes); }
        public static int requestHandle(int id) { Request value = requests[id]; value.Adopted = true; return value.Handle; }
        public static void dropRequest(int id)
        {
            if (!requests.TryGetValue(id, out Request value)) return;
            requests.Remove(id);
            if (value.Status == 0 && value.Coroutine != null && Host != null) Host.StopCoroutine(value.Coroutine);
            if (value.Web != null) { value.Web.Abort(); value.Web.Dispose(); value.Web = null; }
            if (!value.Adopted && value.Handle != 0)
            {
                if (value.Kind == 1) releaseTexture(value.Handle);
                else if (value.Kind == 2) releaseSound(value.Handle);
            }
        }
        private static string ResolveUrl(string path)
        {
            if (path.StartsWith("http://", StringComparison.OrdinalIgnoreCase) || path.StartsWith("https://", StringComparison.OrdinalIgnoreCase)
                || path.StartsWith("file://", StringComparison.OrdinalIgnoreCase) || path.StartsWith("jar:", StringComparison.OrdinalIgnoreCase)) return path;
            string full = Path.IsPathRooted(path) ? path : Path.Combine(Application.streamingAssetsPath, path);
            if (full.Contains("://") || full.StartsWith("jar:", StringComparison.OrdinalIgnoreCase)) return full;
            return new Uri(Path.GetFullPath(full)).AbsoluteUri;
        }
        private static IEnumerator Load(Request request, string path)
        {
            // Resources 路径不含扩展名；普通相对路径基于 StreamingAssets。
            if (path.StartsWith("resources://", StringComparison.Ordinal))
            {
                string assetPath = path.Substring("resources://".Length);
                Type type = request.Kind == 1 ? typeof(Texture2D) : request.Kind == 2 ? typeof(AudioClip) : typeof(TextAsset);
                ResourceRequest operation = null;
                try { operation = Resources.LoadAsync(assetPath, type); }
                catch (Exception error) { request.Error = error.Message; request.Status = -1; }
                if (operation == null) yield break;
                yield return operation;
                try
                {
                    if (operation.asset == null) throw new FileNotFoundException("Resources 资源不存在：" + assetPath);
                    if (request.Kind == 1) request.Handle = RegisterTexture((Texture)operation.asset, false);
                    else if (request.Kind == 2) request.Handle = RegisterSound((AudioClip)operation.asset);
                    else request.Bytes = ((TextAsset)operation.asset).bytes;
                    request.Status = 1;
                }
                catch (Exception error) { request.Error = error.Message; request.Status = -1; }
                yield break;
            }
            UnityWebRequest web = null;
            try
            {
                string url = ResolveUrl(path);
                if (request.Kind == 1) web = UnityWebRequestTexture.GetTexture(url, false);
                else if (request.Kind == 2)
                {
                    string extension = Path.GetExtension(path.Split('?')[0]).ToLowerInvariant();
                    AudioType audio = extension == ".ogg" ? AudioType.OGGVORBIS : extension == ".wav" ? AudioType.WAV : extension == ".mp3" ? AudioType.MPEG : AudioType.UNKNOWN;
                    web = UnityWebRequestMultimedia.GetAudioClip(url, audio);
                }
                else web = UnityWebRequest.Get(url);
                web.timeout = Host.RequestTimeout; request.Web = web;
            }
            catch (Exception error) { request.Error = error.Message; request.Status = -1; }
            if (web == null) yield break;
            UnityWebRequestAsyncOperation pending = null;
            try { pending = web.SendWebRequest(); }
            catch (Exception error) { request.Error = error.Message; request.Status = -1; web.Dispose(); request.Web = null; }
            if (pending == null) yield break;
            yield return pending;
            try
            {
                if (web.result != UnityWebRequest.Result.Success) throw new IOException(web.error);
                if (request.Kind == 1) request.Handle = RegisterTexture(DownloadHandlerTexture.GetContent(web), true);
                else if (request.Kind == 2) request.Handle = RegisterSound(DownloadHandlerAudioClip.GetContent(web), true);
                else request.Bytes = web.downloadHandler.data;
                request.Status = 1;
            }
            catch (Exception error) { request.Error = error.Message; request.Status = -1; }
            finally { web.Dispose(); request.Web = null; }
        }
        private static void DisposeRequests()
        {
            List<int> ids = new List<int>(requests.Keys);
            foreach (int id in ids) dropRequest(id);
        }
        private sealed class Request
        {
            internal int Kind;
            internal int Status;
            internal int Handle;
            internal string Error;
            internal byte[] Bytes;
            internal bool Adopted;
            internal UnityWebRequest Web;
            internal Coroutine Coroutine;
        }
        private static readonly HashSet<int> ownedSounds = new HashSet<int>();
        private static int RegisterSound(AudioClip clip, bool owned = false)
        {
            int id = nextSound++; sounds.Add(id, clip); if (owned) ownedSounds.Add(id); return id;
        }
        public static int playSound(int handle, bool loop)
        {
            AudioClip clip = sounds[handle];
            GameObject owner = new GameObject("Hxmaker 音频"); owner.transform.SetParent(Host.transform, false);
            AudioSource source = owner.AddComponent<AudioSource>(); source.clip = clip; source.loop = loop; source.spatialBlend = 0; source.Play();
            int id = nextChannel++; channels.Add(id, new Channel { Source = source, Sound = handle }); return id;
        }
        public static bool soundPlaying(int id) { return channels.TryGetValue(id, out Channel value) && value.Source != null && value.Source.isPlaying; }
        public static void stopSound(int id)
        {
            if (!channels.TryGetValue(id, out Channel value)) return;
            channels.Remove(id);
            if (value.Source != null) { value.Source.Stop(); UnityEngine.Object.Destroy(value.Source.gameObject); }
        }
        public static void soundVolume(int id, double volume, double pan)
        {
            if (!channels.TryGetValue(id, out Channel value) || value.Source == null) return;
            value.Source.volume = Mathf.Clamp01((float)volume); value.Source.panStereo = Mathf.Clamp((float)pan, -1, 1);
        }
        public static void releaseSound(int handle)
        {
            if (!sounds.TryGetValue(handle, out AudioClip clip)) return;
            List<int> stopped = new List<int>();
            foreach (KeyValuePair<int, Channel> pair in channels) if (pair.Value.Sound == handle) stopped.Add(pair.Key);
            foreach (int id in stopped) stopSound(id);
            sounds.Remove(handle); if (ownedSounds.Remove(handle)) UnityEngine.Object.Destroy(clip);
        }
        private static void DisposeAudio()
        {
            foreach (int id in new List<int>(channels.Keys)) stopSound(id);
            foreach (int id in new List<int>(sounds.Keys)) releaseSound(id);
        }
        private sealed class Channel { internal AudioSource Source; internal int Sound; }
    }
}
