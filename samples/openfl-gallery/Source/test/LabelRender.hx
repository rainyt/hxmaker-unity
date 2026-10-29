package test;

import hx.display.DisplayObjectContainer;
import hx.display.DisplayObject;
import hx.events.MouseEvent;
import hx.display.TextFormat;
import hx.display.Label;
import hx.display.Scene;
import demo.SampleScene;

class LabelRender extends SampleScene {
	override function onAddToStage():Void {
		super.onAddToStage();
		// 文本渲染支持
		var box:DisplayObjectContainer = new DisplayObjectContainer();
		this.addChild(box);
		var label:Label = new Label();
		box.addChild(label);
		label.data = "Hello, HxMaker!";
		label.textFormat = new TextFormat(null, 62, 0xff0000);
		label.width = stage.stageWidth;
		label.height = stage.stageHeight;
		label.x = 0;
		label.y = 0;
		label.horizontalAlign = CENTER;
		label.verticalAlign = MIDDLE;
		box.y = 100;

		// 中文渲染
		var label2:Label = new Label();
		this.addChild(label2);
		label2.data = "你好，HxMaker！";
		label2.textFormat = new TextFormat(null, 62, 0x00fff0);
		label2.width = stage.stageWidth;
		label2.height = stage.stageHeight;
		label2.x = 0;
		label2.y = 0;
		label2.horizontalAlign = LEFT;
		label2.verticalAlign = MIDDLE;

		var label2:Label = new Label();
		this.addChild(label2);
		label2.data = "你好，HxMaker！";
		label2.textFormat = new TextFormat(null, 62, 0x00fff0);
		label2.width = stage.stageWidth;
		label2.height = stage.stageHeight;
		label2.x = 0;
		label2.y = 0;
		label2.horizontalAlign = RIGHT;
		label2.verticalAlign = MIDDLE;

		var label2:Label = new Label();
		this.addChild(label2);
		label2.data = "你好，HxMaker！";
		label2.textFormat = new TextFormat(null, 62, 0x00fff0);
		label2.width = stage.stageWidth;
		label2.height = stage.stageHeight;
		label2.x = 0;
		label2.y = 0;
		label2.horizontalAlign = RIGHT;
		label2.verticalAlign = TOP;

		var label2:Label = new Label();
		this.addChild(label2);
		label2.data = "你好，HxMaker！";
		label2.textFormat = new TextFormat(null, 62, 0x00fff0);
		label2.width = stage.stageWidth;
		label2.height = stage.stageHeight;
		label2.x = 0;
		label2.y = 0;
		label2.horizontalAlign = RIGHT;
		label2.verticalAlign = BOTTOM;

		var label2:Label = new Label();
		this.addChild(label2);
		label2.data = "你好，HxMaker！";
		label2.textFormat = new TextFormat(null, 62, 0x00fff0);
		label2.width = stage.stageWidth;
		label2.height = stage.stageHeight;
		label2.x = 0;
		label2.y = 0;
		label2.horizontalAlign = LEFT;
		label2.verticalAlign = TOP;

		var label2:Label = new Label();
		this.addChild(label2);
		label2.data = "你好，HxMaker！";
		label2.textFormat = new TextFormat(null, 62, 0x00fff0);
		label2.width = stage.stageWidth;
		label2.height = stage.stageHeight;
		label2.x = 0;
		label2.y = 0;
		label2.horizontalAlign = LEFT;
		label2.verticalAlign = BOTTOM;

		var label2:Label = new Label();
		this.addChild(label2);
		label2.data = "你好，HxMaker！";
		label2.textFormat = new TextFormat(null, 62, 0x00fff0);
		label2.width = stage.stageWidth;
		label2.height = stage.stageHeight;
		label2.x = 0;
		label2.y = 0;
		label2.horizontalAlign = CENTER;
		label2.verticalAlign = TOP;

		var label2:Label = new Label();
		this.addChild(label2);
		label2.data = "你好，HxMaker！";
		label2.textFormat = new TextFormat(null, 62, 0x00fff0);
		label2.width = stage.stageWidth;
		label2.height = stage.stageHeight;
		label2.x = 0;
		label2.y = 0;
		label2.horizontalAlign = CENTER;
		label2.verticalAlign = BOTTOM;

		this.addEventListener(MouseEvent.CLICK, (e:MouseEvent) -> {
			trace("点击到了", e.target);
		});
	}
}
