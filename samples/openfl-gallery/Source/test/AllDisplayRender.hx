package test;

import hx.display.Box;
import hx.layout.AnchorLayoutData;
import hx.layout.AnchorLayout;
import hx.display.Graphics;
import hx.display.Image;
import hx.display.TextFormat;
import hx.display.Label;
import hx.display.Spine;
import hx.assets.SpineTextureAtlas;
import hx.display.Quad;
import hx.assets.Assets;
import hx.display.Scene;
import demo.SampleScene;

class AllDisplayRender extends SampleScene {
	public var assets:Assets;

	override function onStageInit():Void {
		super.onStageInit();
		assets = createAssets();
		assets.loadBitmapData("assets/logo.jpg");
		assets.loadSpineAtlas("assets/spine/snowglobe-pro.png", "assets/spine/snowglobe-pro.atlas");
		assets.loadString("assets/spine/snowglobe-pro.json");
		assets.onComplete(a -> {
			// 加载完成
			trace("加载完成");
			this.onLoaded();
		}).onError(err -> {
			trace("加载失败");
		});
		assets.start();
	}

	private function onLoaded():Void {
		// Quad
		var quad:Quad = new Quad(200, 200, 0xfff000);
		this.addChild(quad);
		quad.layoutData = AnchorLayoutData.topLeft(0, 250);

		this.layout = new AnchorLayout();

		// Spine
		var spineAtlas:SpineTextureAtlas = cast assets.atlases.get("snowglobe-pro");
		var data:spine.SkeletonData = spineAtlas.createSkeletonData(assets.strings.get("snowglobe-pro"));
		var spine:Spine = new Spine(data);
		var box:Box = new Box();
		box.width = box.height = 1;
		this.addChild(box);
		box.addChild(spine);
		spine.scaleX = spine.scaleY = 0.15;
		spine.play("idle", 0, true);
		// 让spine居中
		box.layoutData = AnchorLayoutData.center();

		// 文本
		var label:Label = new Label("Hello World");
		this.addChild(label);
		label.textFormat = new TextFormat(null, 32, 0xfff000);
		label.width = label.getTextWidth();
		spine.layoutData = AnchorLayoutData.center(0, -300);

		// 图片
		var image:Image = new Image(assets.bitmapDatas.get("logo"));
		this.addChild(image);
		image.layoutData = AnchorLayoutData.bottomRight();

		// 图形
		var graphic:Graphics = new Graphics();
		graphic.beginFill(0xff0000);
		graphic.drawTriangles([50, 0, 100, 100, 0, 100], [0, 1, 2], [0, 0, 0, 0, 0, 0]);
		this.addChild(graphic);
		trace("graphic", graphic.getBounds());
		graphic.layoutData = AnchorLayoutData.center(0, 300);
	}
}
