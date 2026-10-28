package hx.net;

import hx.unity.NativeBridge;
import hx.core.UnityBitmapData;
import hx.core.UnitySound;
import hx.display.BitmapData;
import hx.assets.Sound;
import hx.events.FutureErrorEvent;
import haxe.io.Bytes;

/** 主线程合并相同请求；资源仅在引用归零后由 sweepCache 释放。 */
class RequestQueue {
	private static var entries:Map<String, CacheEntry> = [];
	public static function key(kind:Int, path:String):String { return "unity:" + kind + ":" + path; }
	public static function load(kind:Int, path:String, callback:Dynamic->FutureErrorEvent->Void):Void {
		var name:String = key(kind, path);
		var entry:CacheEntry = entries.get(name);
		if (entry != null) {
			if (entry.request == 0) callback(entry.value, null); else entry.listeners.push(callback);
			return;
		}
		entry = {kind: kind, path: path, request: 0, refs: 0, value: null, listeners: [callback]};
		entries.set(name, entry);
		try {
			entry.request = NativeBridge.beginRequest(path, kind == 2 ? 1 : kind == 3 ? 2 : 0);
		} catch (error:Dynamic) {
			entries.remove(name);
			callback(null, FutureErrorEvent.create(FutureErrorEvent.LOAD_ERROR, -1, Std.string(error), path));
		}
	}
	public static function update():Void {
		var ready:Array<String> = [];
		for (name => entry in entries) if (entry.request != 0 && NativeBridge.requestStatus(entry.request) != 0) ready.push(name);
		for (name in ready) {
			var entry:CacheEntry = entries.get(name);
			if (entry == null) continue;
			var request:Int = entry.request;
			var error:FutureErrorEvent = null;
			try {
				if (NativeBridge.requestStatus(request) < 0) throw NativeBridge.requestError(request);
				switch entry.kind {
					case 0: entry.value = haxe.crypto.Base64.decode(NativeBridge.requestBytes(request));
					case 1: entry.value = haxe.crypto.Base64.decode(NativeBridge.requestBytes(request)).toString();
					case 2: entry.value = BitmapData.formData(new UnityBitmapData(NativeBridge.requestHandle(request)));
					case 3:
						var sound:Sound = new Sound(); sound.root = new UnitySound(NativeBridge.requestHandle(request)); entry.value = sound;
					default: throw "未知 Unity 资源类型";
				}
			} catch (failure:Dynamic) {
				error = FutureErrorEvent.create(FutureErrorEvent.LOAD_ERROR, -1, Std.string(failure), entry.path);
				entries.remove(name);
			}
			NativeBridge.dropRequest(request);
			entry.request = 0;
			var listeners:Array<Dynamic->FutureErrorEvent->Void> = entry.listeners;
			entry.listeners = [];
			var callbackFailure:Dynamic = null;
			for (listener in listeners) {
				try { listener(entry.value, error); }
				catch (failure:Dynamic) { if (callbackFailure == null) callbackFailure = failure; }
			}
			if (callbackFailure != null) throw callbackFailure;
		}
		hx.core.UnitySoundChannel.update();
	}
	public static function adoptBitmap(bitmap:BitmapData, path:String):String {
		var name:String = key(2, path);
		// 内存解码调用不共享对象，避免同一键覆盖仍被引用的纹理。
		var suffix:Int = 0;
		while (entries.exists(name)) { suffix++; name = key(2, path + ":" + suffix); }
		entries.set(name, {kind: 2, path: path, request: 0, refs: 0, value: bitmap, listeners: []});
		return name;
	}
	public static function retain(path:String):Void { var entry:CacheEntry = entries.get(path); if (entry != null) entry.refs++; }
	public static function release(path:String):Void {
		var entry:CacheEntry = entries.get(path);
		if (entry != null && entry.refs > 0) entry.refs--;
	}
	public static function sweepCache():Void {
		var names:Array<String> = [for (name => entry in entries) if (entry.request == 0 && entry.refs == 0) name];
		for (name in names) {
			var entry:CacheEntry = entries.get(name); entries.remove(name);
			if (entry.kind == 2) cast(entry.value, BitmapData).dispose();
			if (entry.kind == 3) cast(entry.value, Sound).root.dispose();
		}
	}
	public static function dispose():Void {
		for (entry in entries) {
			if (entry.request != 0) NativeBridge.dropRequest(entry.request);
			else if (entry.kind == 2) cast(entry.value, BitmapData).dispose();
			else if (entry.kind == 3) cast(entry.value, Sound).root.dispose();
		}
		entries.clear();
		hx.core.UnitySoundChannel.disposeAll();
	}
}

private typedef CacheEntry = {
	var kind:Int;
	var path:String;
	var request:Int;
	var refs:Int;
	var value:Dynamic;
	var listeners:Array<Dynamic->FutureErrorEvent->Void>;
}
