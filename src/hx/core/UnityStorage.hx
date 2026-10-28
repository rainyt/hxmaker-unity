package hx.core;

import hx.unity.NativeBridge;
import hx.utils.IStorage;

/** JSON 值与保存 ID 均保留，Unity 使用 PlayerPrefs 持久化。 */
class UnityStorage implements IStorage {
	private var saveId:String = "default";
	public function new() {}
	public function setSaveId(value:String):Void { saveId = value; }
	private function key(value:String):String { return "hxmaker:" + saveId.length + ":" + saveId + ":" + value; }
	public function setKeyValue(name:String, value:Dynamic):Void { NativeBridge.storageSet(key(name), haxe.Json.stringify(value)); }
	public function getKeyValue(name:String, defaultValue:Dynamic):Dynamic {
		var value:String = NativeBridge.storageGet(key(name));
		if (value == null) return defaultValue;
		try { return haxe.Json.parse(value); } catch (error:Dynamic) { return defaultValue; }
	}
	public function removeKey(name:String):Void { NativeBridge.storageRemove(key(name)); }
}
