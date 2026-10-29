package demo;

import hx.core.Hxmaker;
import hx.core.Render;
import hx.display.DisplayObjectContainer;
import hx.display.Label;
import hx.display.Quad;
import hx.display.TextFormat;

/** Unity 示例统计；不依赖 OpenFL 的舞台位图池。 */
class SampleFPS extends DisplayObjectContainer {
	public var label:Label;
	private var statsBackground:Quad;
	private var elapsed:Float = 0;
	private var frames:Int = 0;

	override public function onInit():Void {
		super.onInit();
		mouseEnabled = false;
		mouseChildren = false;
		updateEnabled = true;
		statsBackground = new Quad(300, 90, 0);
		statsBackground.alpha = 0.8;
		addChild(statsBackground);
		label = new Label("帧率：采样中");
		label.textFormat = new TextFormat(null, 26, 0xffffff);
		label.x = label.y = 5;
		addChild(label);
	}

	override public function onUpdate(dt:Float):Void {
		super.onUpdate(dt);
		elapsed += dt;
		frames++;
		if (elapsed < 0.5) return;
		var renderer:Render = cast Hxmaker.engine.renderer;
		label.data = "帧率：" + Math.round(frames / elapsed) + " FPS\n上一帧批次：" + renderer.drawCall;
		statsBackground.width = label.width + 10;
		statsBackground.height = label.height + 10;
		frames = 0;
		elapsed = 0;
	}
}
