package test;

import hx.display.Sprite;
import hx.display.DisplayObject;
import hx.events.MouseEvent;
import hx.display.Quad;
import hx.display.TextFormat;
import hx.display.Label;
import hx.events.Event;
import hx.display.Image;
import hx.assets.Assets;
import hx.display.Scene;
import demo.SampleScene;
import hx.display.DisplayObjectContainer;

/**
 * BlendMode渲染测试
 */
class BlendModeRender extends SampleScene {
	/**
	 * 资源管理器
	 */
	var assets:Assets;

	override function onStageInit():Void {
		super.onStageInit();
		assets = createAssets();
		// 开始加载资源
		assets.loadBitmapData("assets/logo.jpg");
		for (i in 0...6) {
			assets.loadBitmapData("assets/wabbit_alpha_" + (i + 1) + ".png");
		}
		assets.loadAtlas("assets/EmojAtlas.png", "assets/EmojAtlas.xml");
		assets.onComplete((data) -> {
			this.onLoaded();
		}).onError(err -> {
			trace("加载失败");
		});
		assets.start();
	}

	/**
	 * 当资源加载完成时
	 */
	public function onLoaded():Void {
		trace("加载完成");
		// 显示一张图片

		var sprite:Sprite = new Sprite();
		this.addChild(sprite);

		var root:Image = new Image(assets.bitmapDatas.get("logo"));
		sprite.addChild(root);
		root.x = 0;
		root.y = 0;

		var image:Image = new Image(assets.bitmapDatas.get("logo"));
		sprite.addChild(image);
		image.x = root.x + root.width + 10;
		image.y = root.y;
		image.blendMode = ADD;

		// Unity 当前仅渲染 NORMAL 与 ADD，跳过 MULTIPLY、SCREEN。

		sprite.x = stage.stageWidth / 2 - sprite.width / 2;
		sprite.y = stage.stageHeight / 2 - sprite.height / 2;
	}
}
