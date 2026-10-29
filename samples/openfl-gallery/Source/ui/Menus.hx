package ui;

import hx.display.Scroll;
import hx.layout.AnchorLayoutData;
import hx.layout.AnchorLayout;
import hx.events.Event;
import hx.events.MouseEvent;
import hx.display.TextFormat;
import hx.display.Label;
import hx.display.Scene;
import hx.display.Quad;
import hx.display.DisplayObjectContainer;
import hx.layout.VerticalLayout;
import hx.display.Box;
import hx.display.DisplayObject;

/**
 * 左侧栏功能模块
 */
class Menus extends Box {
	override function onInit():Void {
		super.onInit();
		this.layout = new AnchorLayout();
		this.width = 250;
		var bg:Quad = new Quad(this.width, this.height, 0x282828);
		bg.layoutData = AnchorLayoutData.fill();
		this.addChild(bg);

		var scroll:Scroll = new Scroll();
		this.addChild(scroll);
		scroll.scrollXEnable = false;
		scroll.layoutData = AnchorLayoutData.fill();

		var box:Box = new Box();
		scroll.addChild(box);
		box.width = this.width;
		box.layout = new VerticalLayout().setGap(5);
		for (c in Game.tests) {
			var button:MenuButton = new MenuButton(c);
			box.addChild(button);
		}
	}
}

/**
 * 菜单按钮
 */
class MenuButton extends DisplayObjectContainer {
	private var __c:Class<Scene>;

	public function new(c:Class<Scene>) {
		super();
		__c = c;
		this.mouseChildren = false;
		this.addEventListener(MouseEvent.CLICK, (e) -> {
			var event:Event = new Event("changeScene");
			event.data = __c;
			this.stage.dispatchEvent(event);
		});
	}

	override function onStageInit():Void {
		super.onStageInit();
		var quad:Quad = new Quad(250, 36);
		quad.alpha = 0.8;
		this.addChild(quad);
		var className:String = Type.getClassName(__c);
		var label:Label = new Label(className);
		label.textFormat = new TextFormat(null, 20, 0xff0000);
		label.height = this.height;
		label.x = 10;
		label.verticalAlign = MIDDLE;
		this.addChild(label);
	}
}
