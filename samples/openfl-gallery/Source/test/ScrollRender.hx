package test;

import hx.display.Quad;
import hx.events.MouseEvent;
import hx.display.Scroll;
import hx.display.Scene;
import demo.SampleScene;

/**
 * 滚动列表
 */
class ScrollRender extends SampleScene {
	var scroll:Scroll = new Scroll();

	override function onInit():Void {
		super.onInit();
		this.addChild(scroll);
		scroll.width = 500;
		scroll.height = 500;
		scroll.backgroundColor = 0xffffff;
		scroll.backgroundAlpha = 0.5;
		scroll.x = 300;
		scroll.y = 300;

		var quad:Quad = new Quad(100, 100, 0xff0000);
		scroll.addChild(quad);

		// scroll.quad.x = 500;
		// scroll.quad.y = 500;
		// scroll.quad.width = 500;
		// scroll.quad.height = 500;
	}

	override function onAddToStage():Void {
		super.onAddToStage();
		this.addEventListener(MouseEvent.CLICK, (e) -> {
			// trace(scroll, scroll.width, scroll.height, scroll.quad.parent);
			trace("点击", e.target);
		});
	}
}
