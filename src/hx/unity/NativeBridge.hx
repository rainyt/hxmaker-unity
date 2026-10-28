package hx.unity;

import cs.NativeArray;

/** Unity 原生运行时的强类型边界，不依赖整个 Unity API 的 extern 包。 */
@:native("Hxmaker.Unity.NativeBridge")
extern class NativeBridge {
	public static function beginFrame(surface:Int, width:Float, height:Float):Void;
	public static function submit(surface:Int, vertices:NativeArray<Float>, indices:NativeArray<Int>, textures:NativeArray<Int>, smoothing:Bool,
		clipX:Float, clipY:Float, clipWidth:Float, clipHeight:Float):Void;
	public static function endFrame(surface:Int):Void;
	public static function disposeSurface(surface:Int):Void;
	public static function textureSlots():Int;
	public static function pixelRatio():Float;
	public static function targetFrameRate(value:Int):Void;
	public static function createTexture(base64:String):Int;
	public static function createSolidTexture(width:Int, height:Int, color:Int):Int;
	public static function clearTexture(handle:Int, x:Int, y:Int, width:Int, height:Int):Void;
	public static function textureWidth(handle:Int):Int;
	public static function textureHeight(handle:Int):Int;
	public static function releaseTexture(handle:Int):Void;
	public static function beginRequest(path:String, kind:Int):Int;
	public static function requestStatus(id:Int):Int;
	public static function requestError(id:Int):String;
	public static function requestBytes(id:Int):String;
	public static function requestHandle(id:Int):Int;
	public static function dropRequest(id:Int):Void;
	public static function releaseSound(handle:Int):Void;
	public static function playSound(handle:Int, loop:Bool):Int;
	public static function stopSound(channel:Int):Void;
	public static function soundPlaying(channel:Int):Bool;
	public static function soundVolume(channel:Int, volume:Float, pan:Float):Void;
	public static function storageSet(key:String, value:String):Void;
	public static function storageGet(key:String):String;
	public static function storageRemove(key:String):Void;
	public static function platform():String;
	public static function isDesktop():Bool;
	public static function writeClipboard(text:String):Void;
	public static function readClipboard():String;
	public static function log(message:String):Void;
	public static function fontRevision():Int;
	public static function requestFont(name:String, text:String, size:Int):Void;
	public static function fontMetrics(name:String, size:Int):NativeArray<Float>;
	public static function glyph(name:String, size:Int, code:Int):NativeArray<Float>;
}
