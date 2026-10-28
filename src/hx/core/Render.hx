package hx.core;

import cs.NativeArray;
import hx.display.*;
import hx.geom.Matrix;
import hx.geom.Rectangle;
import hx.geom.ColorTransform;
import hx.unity.NativeBridge;

/** 保持显示顺序的二维多纹理批处理；相机复用 Unity 中的持久网格。 */
@:access(hx.display.DisplayObject)
@:access(hx.display.Image)
@:access(hx.display.Graphics)
@:access(hx.geom.Matrix)
class Render implements IRender {
	public var surface(default, null):Int;
	public var multiTextureEnabled(get, set):Bool;
	public var cacheAsBitmap(get, set):Bool;
	public var highDpi(get, set):Bool;
	public var drawCall(default, null):Int = 0;
	private var multi:Bool = true;
	private var dpi:Bool = true;
	private var vertices:Array<Float> = [];
	private var indices:Array<Int> = [];
	private var textures:Array<Int> = [];
	private var smooth:Bool = true;
	private var clip:Rectangle;
	private var additive:Bool = false;
	private var open:Bool = false;
	public function new(surface:Int = 0) { this.surface = surface; }
	private function get_multiTextureEnabled():Bool { return multi; }
	private function set_multiTextureEnabled(value:Bool):Bool { flush(); multi = value; return value; }
	private function get_cacheAsBitmap():Bool { return false; }
	private function set_cacheAsBitmap(value:Bool):Bool {
		if (value) throw "Unity 首版不支持 cacheAsBitmap，请使用摄像机 RenderTexture";
		return false;
	}
	private function get_highDpi():Bool { return dpi; }
	private function set_highDpi(value:Bool):Bool { dpi = value; return value; }
	public function clear():Void {
		vertices = []; indices = []; textures = []; drawCall = 0;
		clip = new Rectangle(0, 0, Hxmaker.engine.stageWidth, Hxmaker.engine.stageHeight);
		NativeBridge.beginFrame(surface, clip.width, clip.height); open = true;
	}
	public function abort():Void { vertices = []; indices = []; textures = []; NativeBridge.endFrame(surface); open = false; }
	public function dispose():Void { NativeBridge.disposeSurface(surface); vertices = []; indices = []; textures = []; open = false; }
	public function endFill():Void { flush(); if (open) NativeBridge.endFrame(surface); open = false; }
	public function renderDisplayObject(object:DisplayObject):Void {
		if (object == null || object.isDisposed || object.hide || !object.visible) return;
		object.__ensureWorldTransform();
		if (object.__worldAlpha <= 0) return;
		if (object.shader != null || (object.filters != null && object.filters.length > 0)) throw "Unity 首版不支持自定义 Shader 与通用滤镜";
		var previous:Rectangle = clip;
		var previousAdd:Bool = additive;
		additive = additive || object.blendMode == ADD;
		if (object.maskRect != null) {
			flush();
			var transformed:Rectangle = new Rectangle();
			object.maskRect.transform(transformed, object.__worldTransform);
			var left:Float = Math.max(previous.x, transformed.x);
			var top:Float = Math.max(previous.y, transformed.y);
			clip = new Rectangle(left, top, Math.max(0, Math.min(previous.right, transformed.right) - left), Math.max(0, Math.min(previous.bottom, transformed.bottom) - top));
		}
		if (clip.width > 0 && clip.height > 0) {
			if (object is Scene3D) throw "Unity 首版不包含 hxmaker Scene3D 渲染；可使用 Unity 原生场景与摄像机";
			else if (object is Image) renderImage(cast object);
			else if (object is DisplayObjectContainer) renderDisplayObjectContainer(cast object);
			else if (object is Label) renderLabel(cast object);
			else if (object is Graphics) renderGraphics(cast object);
			else if (object is CustomDisplayObject) renderCustomDisplayObject(cast object);
		}
		if (clip != previous) { flush(); clip = previous; }
		additive = previousAdd;
		object.__dirty = false;
	}
	public function renderDisplayObjectContainer(container:DisplayObjectContainer):Void {
		if (container.background != null) renderDisplayObject(container.background);
		for (child in container.children) renderDisplayObject(child);
	}
	public function renderImage(image:Image):Void {
		if (image.data == null || image.data.data == null) return;
		if (image.scale9Grid != null || image.repeat) {
			renderTiledImage(image);
			return;
		}
		var data:BitmapData = image.data;
		var width:Float = data.rect == null ? data.data.getWidth() : data.rect.width;
		var height:Float = data.rect == null ? data.data.getHeight() : data.rect.height;
		var u:Float = data.rect == null ? 0 : data.rect.x / data.data.getWidth();
		var v:Float = data.rect == null ? 0 : data.rect.y / data.data.getHeight();
		var uw:Float = width / data.data.getWidth();
		var vh:Float = height / data.data.getHeight();
		emit([0, 0, width, 0, 0, height, width, height], [0, 1, 2, 1, 3, 2], [u, v, u + uw, v, u, v + vh, u + uw, v + vh],
			cast data.data.getTexture(), image.__worldTransform, image.__worldAlpha, image.__colorTransform, image.smoothing, false);
	}
	/** 九宫格与平铺直接生成小四边形，避免借用 OpenFL 辅助图形的父变换与透明度缓存。 */
	private function renderTiledImage(image:Image):Void {
		var data:BitmapData = image.data;
		var sourceWidth:Float = data.rect == null ? data.data.getWidth() : data.rect.width;
		var sourceHeight:Float = data.rect == null ? data.data.getHeight() : data.rect.height;
		var targetWidth:Float = Math.abs(image.width); var targetHeight:Float = Math.abs(image.height);
		if (sourceWidth <= 0 || sourceHeight <= 0 || targetWidth <= 0 || targetHeight <= 0 || image.scaleX == 0 || image.scaleY == 0) return;
		var matrix:Matrix = image.__worldTransform.clone();
		matrix.a /= Math.abs(image.scaleX); matrix.b /= Math.abs(image.scaleX);
		matrix.c /= Math.abs(image.scaleY); matrix.d /= Math.abs(image.scaleY);
		if (image.scale9Grid != null) {
			var grid:Rectangle = image.scale9Grid;
			var left:Float = Math.max(0, Math.min(grid.x, sourceWidth));
			var right:Float = Math.max(0, Math.min(sourceWidth - grid.right, sourceWidth - left));
			var top:Float = Math.max(0, Math.min(grid.y, sourceHeight));
			var bottom:Float = Math.max(0, Math.min(sourceHeight - grid.bottom, sourceHeight - top));
			var scaleX:Float = left + right > targetWidth ? targetWidth / (left + right) : 1;
			var scaleY:Float = top + bottom > targetHeight ? targetHeight / (top + bottom) : 1;
			var sx:Array<Float> = [0, left, sourceWidth - right, sourceWidth];
			var sy:Array<Float> = [0, top, sourceHeight - bottom, sourceHeight];
			var dx:Array<Float> = [0, left * scaleX, targetWidth - right * scaleX, targetWidth];
			var dy:Array<Float> = [0, top * scaleY, targetHeight - bottom * scaleY, targetHeight];
			for (y in 0...3) for (x in 0...3) imageQuad(image, matrix, dx[x], dy[y], dx[x + 1] - dx[x], dy[y + 1] - dy[y], sx[x], sy[y], sx[x + 1] - sx[x], sy[y + 1] - sy[y]);
		} else {
			var y:Float = 0;
			while (y < targetHeight) {
				var x:Float = 0; var height:Float = Math.min(sourceHeight, targetHeight - y);
				while (x < targetWidth) {
					var width:Float = Math.min(sourceWidth, targetWidth - x);
					imageQuad(image, matrix, x, y, width, height, 0, 0, width, height); x += width;
				}
				y += height;
			}
		}
	}
	private function imageQuad(image:Image, matrix:Matrix, x:Float, y:Float, width:Float, height:Float, sx:Float, sy:Float, sw:Float, sh:Float):Void {
		if (width <= 0 || height <= 0 || sw <= 0 || sh <= 0) return;
		var data:BitmapData = image.data;
		var tw:Float = data.data.getWidth(); var th:Float = data.data.getHeight();
		var u:Float = (data.uvOffsetX + sx) / tw; var v:Float = (data.uvOffsetY + sy) / th;
		emit([x, y, x + width, y, x, y + height, x + width, y + height], [0, 1, 2, 1, 3, 2], [u, v, u + sw / tw, v, u, v + sh / th, u + sw / tw, v + sh / th],
			cast data.data.getTexture(), matrix, image.__worldAlpha, image.__colorTransform, image.smoothing, false);
	}
	private function mergeColor(local:ColorTransform, parent:ColorTransform):ColorTransform {
		if (local == null) return parent;
		if (parent == null) return local;
		return new ColorTransform(local.redMultiplier * parent.redMultiplier, local.greenMultiplier * parent.greenMultiplier,
			local.blueMultiplier * parent.blueMultiplier, local.alphaMultiplier * parent.alphaMultiplier,
			local.redOffset * parent.redMultiplier + parent.redOffset, local.greenOffset * parent.greenMultiplier + parent.greenOffset,
			local.blueOffset * parent.blueMultiplier + parent.blueOffset, local.alphaOffset * parent.alphaMultiplier + parent.alphaOffset);
	}
	public function renderGraphics(graphics:Graphics):Void {
		if (graphics.__graphicsDirty) graphics.updateGraphics();
		var bitmap:BitmapData = null;
		var smoothing:Bool = true;
		for (draw in graphics.__graphicsDrawData.draws) switch draw {
			case BEGIN_FILL(color): bitmap = null;
			case BEGIN_BITMAP_DATA(data, value): bitmap = data; smoothing = value;
			case DRAW_TRIANGLE(points, triangles, uvs, alpha, color, add):
				emit(points, triangles, uvs, bitmap == null ? 0 : cast bitmap.data.getTexture(), graphics.__worldTransform,
					graphics.__worldAlpha * alpha, mergeColor(color, graphics.__colorTransform), smoothing, add);
			case DRAW_PATH(mesh, alpha, color):
				var matrix:Matrix = graphics.__worldTransform;
				var coverageMesh:hx.display.graphics.GraphicsMesh = mesh;
				if (graphics.antialiasing) {
					var scale:Float = Hxmaker.engine.scaleFactor;
					coverageMesh = mesh.getAntialiased(matrix.a * scale, matrix.b * scale, matrix.c * scale, matrix.d * scale, graphics.antialiasWidth);
				}
				emit(coverageMesh.vertices, coverageMesh.indices, coverageMesh.uvs, 0, matrix, graphics.__worldAlpha * alpha,
					mergeColor(color, graphics.__colorTransform), true, false, coverageMesh.coverage);
		}
	}
	public function renderLabel(label:Label, offScreenRender:Bool = false):Void {
		hx.render.TextFieldRender.prepareLabel(label);
		if (!offScreenRender) hx.render.TextFieldRender.render(label, this);
	}
	public function renderCustomDisplayObject(displayObject:CustomDisplayObject):Void { throw "Unity 首版不支持 CustomDisplayObject 原生对象"; }
	public function renderToBitmapData(bitmapData:BitmapData):Void { throw "Unity 首版不支持位图读回，请使用 Unity RenderTexture"; }
	/** 顶点颜色采用直通 RGB，最终在 Shader 内统一转为预乘透明度。 */
	public function emit(points:Array<Float>, triangles:Array<Int>, uvs:Array<Float>, texture:Int, matrix:Matrix, alpha:Float,
		color:ColorTransform, smoothing:Bool, add:Bool, coverage:Array<Float> = null):Void {
		var count:Int = Std.int(points.length / 2);
		if (count == 0 || triangles.length == 0) return;
		if (count > 65535) throw "Unity 单个绘图命令超过 65535 顶点，请拆分网格";
		var slot:Int = textures.indexOf(texture);
		var slots:Int = multi ? NativeBridge.textureSlots() : 1;
		if (vertices.length > 0 && (smooth != smoothing || vertices.length / 16 + count > 65535 || (slot < 0 && textures.length >= slots))) {
			flush(); slot = -1;
		}
		smooth = smoothing;
		if (slot < 0) { slot = textures.length; textures.push(texture); }
		var offset:Int = Std.int(vertices.length / 16);
		for (i in 0...count) {
			var x:Float = points[i * 2]; var y:Float = points[i * 2 + 1];
			vertices.push(matrix.a * x + matrix.c * y + matrix.tx); vertices.push(matrix.b * x + matrix.d * y + matrix.ty);
			vertices.push(uvs[i * 2]); vertices.push(uvs[i * 2 + 1]);
			vertices.push(color == null ? 1 : color.redMultiplier); vertices.push(color == null ? 1 : color.greenMultiplier);
			vertices.push(color == null ? 1 : color.blueMultiplier); vertices.push(color == null ? 1 : color.alphaMultiplier);
			vertices.push(color == null ? 0 : color.redOffset / 255); vertices.push(color == null ? 0 : color.greenOffset / 255);
			vertices.push(color == null ? 0 : color.blueOffset / 255); vertices.push(color == null ? 0 : color.alphaOffset / 255);
			vertices.push(alpha); vertices.push(slot); vertices.push(add || additive ? 1 : 0); vertices.push(coverage == null ? 1 : coverage[i]);
		}
		for (index in triangles) indices.push(offset + index);
	}
	private function flush():Void {
		if (indices.length == 0) return;
		var nativeVertices:NativeArray<Float> = new NativeArray<Float>(vertices.length);
		var nativeIndices:NativeArray<Int> = new NativeArray<Int>(indices.length);
		var nativeTextures:NativeArray<Int> = new NativeArray<Int>(textures.length);
		for (i in 0...vertices.length) nativeVertices[i] = vertices[i];
		for (i in 0...indices.length) nativeIndices[i] = indices[i];
		for (i in 0...textures.length) nativeTextures[i] = textures[i];
		NativeBridge.submit(surface, nativeVertices, nativeIndices, nativeTextures, smooth, clip.x, clip.y, clip.width, clip.height);
		drawCall++;
		vertices = []; indices = []; textures = [];
	}
}
