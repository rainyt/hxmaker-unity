package hx.render;

import hx.core.Render;
import hx.display.Label;
import hx.display.DisplayObject;
import hx.display.DisplayObjectContainer;
import hx.geom.ColorTransform;
import hx.unity.NativeBridge;
import hx.text.UnityTextLayout;

/** 先统一请求字形，再布局和提交，避免字库重排导致同帧 UV 失效。 */
@:access(hx.display.Label)
@:access(hx.display.DisplayObject)
class TextFieldRender {
	public static function requestTree(object:DisplayObject):Void {
		if (object.isDisposed || object.hide || !object.visible) return;
		if (object is Label) requestLabel(cast object);
		if (object is DisplayObjectContainer) {
			var container:DisplayObjectContainer = cast object;
			if (container.background != null) requestTree(container.background);
			for (child in container.children) requestTree(child);
		}
	}
	public static function prepareTree(object:DisplayObject):Void {
		if (object.isDisposed || object.hide || !object.visible) return;
		if (object is Label) prepareLabel(cast object, false);
		if (object is DisplayObjectContainer) {
			var container:DisplayObjectContainer = cast object;
			if (container.background != null) prepareTree(container.background);
			for (child in container.children) prepareTree(child);
		}
	}
	public static function requestLabel(label:Label):Void {
		var format:hx.display.TextFormat = label.__textFormat;
		var text:String = filtered(label);
		NativeBridge.requestFont(format.font, text + " ", Std.int(Math.max(1, format.size)));
		for (range in label.__rangeTextFormats) NativeBridge.requestFont(range.font, text + " ", Std.int(Math.max(1, range.size)));
	}
	public static function filtered(label:Label):String {
		return label.charFilterEnabled && Label.onGlobalCharFilter != null ? Label.onGlobalCharFilter(label.data) : label.data;
	}
	public static function prepareLabel(label:Label, request:Bool = true):Void {
		var layout:UnityTextLayout = Std.isOfType(label.root, UnityTextLayout) ? cast label.root : null;
		if (layout == null) { layout = new UnityTextLayout(); label.root = layout; }
		if (!label.__textFormatDirty && layout.valid()) return;
		if (request) requestLabel(label);
		layout.build(label, filtered(label));
		label.__textFormatDirty = false;
	}
	public static function render(label:Label, renderer:Render):Void {
		var layout:UnityTextLayout = cast label.root;
		for (glyph in layout.glyphs) {
			if (glyph.outline > 0) for (offset in [[-1., -1.], [0., -1.], [1., -1.], [-1., 0.], [1., 0.], [-1., 1.], [0., 1.], [1., 1.]])
				drawGlyph(label, renderer, glyph, offset[0] * glyph.outline, offset[1] * glyph.outline, glyph.outlineColor);
			drawGlyph(label, renderer, glyph, 0, 0, glyph.color);
		}
	}
	private static function drawGlyph(label:Label, renderer:Render, glyph:hx.text.UnityTextLayout.TextGlyph, dx:Float, dy:Float, color:Int):Void {
		var red:Float = (color >> 16) & 255;
		var green:Float = (color >> 8) & 255;
		var blue:Float = color & 255;
		// 动态字库只提供字形透明度，RGB 由文本颜色决定。
		// 乘数归零、偏移写入颜色，使 Metal 等后端的字库 RGB 不影响结果。
		var transform:ColorTransform = new ColorTransform(0, 0, 0, 1, red, green, blue, 0);
		if (label.__colorTransform != null) {
			var source:ColorTransform = label.__colorTransform;
			transform.redOffset = red * source.redMultiplier + source.redOffset;
			transform.greenOffset = green * source.greenMultiplier + source.greenOffset;
			transform.blueOffset = blue * source.blueMultiplier + source.blueOffset;
			transform.alphaMultiplier = source.alphaMultiplier;
			transform.alphaOffset = source.alphaOffset;
		}
		var x:Float = glyph.x + dx; var y:Float = glyph.y + dy;
		renderer.emit([x, y, x + glyph.width, y, x, y + glyph.height, x + glyph.width, y + glyph.height], [0, 1, 2, 1, 3, 2], glyph.uvs,
			glyph.texture, label.__worldTransform, label.__worldAlpha, transform, label.smoothing, false);
	}
	public static function disposeTextFieldContextBitmapData():Void {
		// 字库由 Unity 字体对象持有；递增版本即可让布局在下一帧重建。
		UnityTextLayout.invalidateAll();
	}
}
