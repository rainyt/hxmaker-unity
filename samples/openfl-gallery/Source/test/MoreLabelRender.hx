package test;

import hx.events.Event;
import hx.display.TextFormat;
import hx.display.Label;
import hx.assets.Assets;
import hx.display.Scene;
import demo.SampleScene;

/**
 * 文本渲染支持
 */
class MoreLabelRender extends SampleScene {
	override function onStageInit():Void {
		super.onStageInit();
		var labels:Array<Label> = [];
		for (i in 0...1000) {
			var label:Label = new Label();
			this.addChild(label);
			label.data = "随机内容：" + Std.random(9999);
			label.textFormat = new TextFormat(null, 26, 0xffffff);
			label.x = Math.random() * stage.stageWidth;
			label.y = Math.random() * stage.stageHeight;
			labels.push(label);
		}
		this.addEventListener(Event.UPDATE, (e) -> {
			for (label in labels) {
				label.data = "随机内容：" + Std.random(9999);
			}
		});
	}
}
