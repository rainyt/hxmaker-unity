package hx.unity;

#if macro
import haxe.macro.Context;
import haxe.macro.Compiler;

/** 检查后端组合，禁止把尚未实现的能力宏当作有效功能。 */
class Build {
	public static function configure():Void {
		if (!Context.defined("cs")) Context.fatalError("hxmaker-unity 仅支持 Haxe C# 目标", Context.currentPos());
		if (Context.defined("openfl") || Context.defined("hxmaker_openfl"))
			Context.fatalError("Unity 和 OpenFL 后端不能同时启用", Context.currentPos());
		for (feature in ["hxmaker_scene3d", "hxmaker_text_input", "hxmaker_filters", "hxmaker_advanced_blend", "hxmaker_custom_shader", "hxmaker_native_display", "hxmaker_bitmap_draw"])
			if (Context.defined(feature)) Context.fatalError("Unity 首版尚未实现能力：" + feature, Context.currentPos());
		Compiler.define("hxmaker_unity");
		Compiler.define("no-compilation");
		Compiler.define("actuate_manual_update");
		Compiler.define("actuate_manual_time");
	}
}
#end
