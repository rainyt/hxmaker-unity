package hx.text;

import hx.display.Label;
import hx.display.TextFormat;
import hx.geom.Rectangle;
import hx.providers.ITextFieldLayoutProvider;
import hx.unity.NativeBridge;
import cs.NativeArray;

/** 使用 Unity 动态字库度量；保存空白字符与插入位置的逻辑边界。 */
@:access(hx.display.Label)
@:access(hx.display.DisplayObject)
class UnityTextLayout implements ITextFieldLayoutProvider {
	private static var generation:Int = 0;
	private var builtGeneration:Int = -1;
	public var layoutVersion(default, null):Int = 0;
	public var revision(default, null):Int = -1;
	public var glyphs:Array<TextGlyph> = [];
	private var bounds:Rectangle = new Rectangle();
	private var characters:Array<Rectangle> = [];
	private var carets:Array<Rectangle> = [];
	public function new() {}
	public static function invalidateAll():Void { generation++; }
	public function valid():Bool { return builtGeneration == generation && revision == NativeBridge.fontRevision(); }
	public function build(label:Label, text:String):Void {
		glyphs = []; characters = []; carets = [];
		var format:TextFormat = label.__textFormat;
		var metrics:NativeArray<Float> = NativeBridge.fontMetrics(format.font, Std.int(Math.max(1, format.size)));
		var lineHeight:Float = metrics[0]; var ascent:Float = metrics[1];
		for (range in label.__rangeTextFormats) {
			var rangeMetrics:NativeArray<Float> = NativeBridge.fontMetrics(range.font, Std.int(Math.max(1, range.size)));
			lineHeight = Math.max(lineHeight, rangeMetrics[0]); ascent = Math.max(ascent, rangeMetrics[1]);
		}
		var x:Float = 0; var y:Float = 0; var maxWidth:Float = 0;
		var limit:Float = label.wordWrap && label.__width != null && label.__width > 0 ? label.__width : Math.POSITIVE_INFINITY;
		var lineWidths:Array<Float> = []; var line:Int = 0;
		for (i in 0...text.length) {
			var style:TextFormat = format;
			for (range in label.__rangeTextFormats) if (i >= range.startIndex && (range.endIndex < 0 || i < range.endIndex)) style = range;
			var code:Int = text.charCodeAt(i);
			var size:Int = Std.int(Math.max(1, style.size));
			var info:NativeArray<Float> = NativeBridge.glyph(style.font, size, code == 9 ? 32 : code);
			var advance:Float = code == 9 ? info[0] * 4 : info[0];
			if (code != 10 && code != 13 && x > 0 && x + advance > limit) {
				lineWidths.push(x); maxWidth = Math.max(maxWidth, x); x = 0; y += lineHeight; line++;
			}
			carets.push(new Rectangle(x, y, 1, lineHeight));
			if (code == 10) {
				characters.push(new Rectangle(x, y, 0, lineHeight)); lineWidths.push(x); maxWidth = Math.max(maxWidth, x);
				x = 0; y += lineHeight; line++; continue;
			}
			if (code == 13) { characters.push(new Rectangle(x, y, 0, lineHeight)); continue; }
			characters.push(new Rectangle(x, y, advance, lineHeight));
			if (code != 9 && info[2] > info[1] && info[4] > info[3]) glyphs.push({
				x: x + info[1], y: y + ascent - info[4], width: info[2] - info[1], height: info[4] - info[3], line: line,
				uvs: [info[5], info[6], info[7], info[8], info[9], info[10], info[11], info[12]], texture: Std.int(info[13]),
				color: style.color, outline: style.outline, outlineColor: style.outlineColor
			});
			x += advance;
		}
		lineWidths.push(x); maxWidth = Math.max(maxWidth, x);
		carets.push(new Rectangle(x, y, 1, lineHeight));
		bounds.setTo(0, 0, maxWidth, text.length == 0 ? 0 : y + lineHeight);
		for (glyph in glyphs) {
			var offset:Float = label.horizontalAlign == CENTER ? (maxWidth - lineWidths[glyph.line]) / 2 : label.horizontalAlign == RIGHT ? maxWidth - lineWidths[glyph.line] : 0;
			glyph.x += offset;
		}
		builtGeneration = generation; revision = NativeBridge.fontRevision(); layoutVersion++;
	}
	public function getTextWidth():Float { return bounds.width; }
	public function getTextHeight():Float { return bounds.height; }
	public function getTextBounds():Rectangle { return bounds; }
	public function getChatBounds(index:Int):Rectangle { return index < 0 || index >= characters.length ? new Rectangle() : characters[index].clone(); }
	public function getCaretBounds(index:Int):Rectangle { return index < 0 || index >= carets.length ? new Rectangle() : carets[index].clone(); }
	public function release():Void { glyphs = []; characters = []; carets = []; revision = -1; }
}

typedef TextGlyph = {
	var x:Float; var y:Float; var width:Float; var height:Float; var line:Int;
	var uvs:Array<Float>; var texture:Int; var color:Int; var outline:Int; var outlineColor:Int;
}
