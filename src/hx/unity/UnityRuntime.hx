package hx.unity;

import hx.core.Engine;

/** 由生成的 Unity 宿主直接调用，避免运行时反射查找入口。 */
@:keep
@:native("Hxmaker.Unity.HaxeRuntime")
class UnityRuntime {
	public static var engine:Engine;
	public static function Tick(dt:Float):Void { if (engine != null) engine.update(dt); }
	public static function Resize(width:Float, height:Float):Void { if (engine != null) engine.resize(width, height); }
	public static function Pointer(type:String, x:Float, y:Float, id:Int, delta:Float):Void {
		if (engine != null) engine.pointer(type, x, y, id, delta);
	}
	public static function Keyboard(type:String, code:Int, modifiers:Int):Void {
		if (engine != null) engine.keyboard(type, code, modifiers);
	}
	public static function Focus(active:Bool):Void { if (engine != null) engine.activate(active); }
	public static function Shutdown():Void { if (engine != null) engine.dispose(); }
}
