package hx.core;

import hx.display.BitmapData;
import hx.display.IBitmapData;
import hx.display.DisplayObject;
import hx.display.BlendMode;
import hx.geom.Matrix;
import hx.geom.Rectangle;
import hx.unity.NativeBridge;
import haxe.io.Bytes;

/** 纹理句柄由 Unity 运行时管理，借用外部纹理时不销毁外部对象。 */
class UnityBitmapData implements IBitmapData {
	public var handle(default, null):Int;
	public function new(handle:Int) { this.handle = handle; }
	public static function fromBytes(bytes:Bytes):BitmapData {
		return BitmapData.formData(new UnityBitmapData(NativeBridge.createTexture(haxe.crypto.Base64.encode(bytes))));
	}
	public static function fromSize(width:Int, height:Int, color:Int = 0):BitmapData {
		return BitmapData.formData(new UnityBitmapData(NativeBridge.createSolidTexture(width, height, color)));
	}
	public function getTexture():Dynamic { return handle; }
	public function getWidth():Int { return handle == 0 ? 0 : NativeBridge.textureWidth(handle); }
	public function getHeight():Int { return handle == 0 ? 0 : NativeBridge.textureHeight(handle); }
	public function clear(?rect:Rectangle):Void {
		if (handle == 0) return;
		NativeBridge.clearTexture(handle, rect == null ? 0 : Std.int(rect.x), rect == null ? 0 : Std.int(rect.y),
			rect == null ? getWidth() : Std.int(rect.width), rect == null ? getHeight() : Std.int(rect.height));
	}
	public function draw(source:DisplayObject, matrix:Matrix, ?blendMode:BlendMode, updateTransform:Bool = true):Void {
		throw "Unity 首版不支持 BitmapData.draw；摄像机输出请使用 Unity RenderTexture";
	}
	public function dispose():Void { if (handle != 0) { NativeBridge.releaseTexture(handle); handle = 0; } }
}
