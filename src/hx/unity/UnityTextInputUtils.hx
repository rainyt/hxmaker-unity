package hx.unity;

import hx.display.InputLabel;

/** 输入组件仍可作为静态界面构建；尝试编辑时明确报告未实现。 */
class UnityTextInputUtils {
	public static var input:InputLabel;
	public static function openInput(value:InputLabel):Void { throw "Unity 首版未实现 InputLabel 编辑，请用 hxmaker_unity 条件编译区分"; }
	public static function closeInput(value:InputLabel):Void { if (input == value) input = null; }
	public static function syncSelectionToNative(value:InputLabel):Void {}
	public static function syncTextToNative(value:InputLabel):Void {}
}
