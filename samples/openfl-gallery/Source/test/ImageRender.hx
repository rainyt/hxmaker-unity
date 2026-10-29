package test;

import hx.geom.ColorTransform;
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
 * 测试图片渲染
 */
class ImageRender extends SampleScene {
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
		// 容器加图片显示对象
		var box:DisplayObjectContainer = new DisplayObjectContainer();
		this.addChild(box);
		var image2:Image = new Image(assets.bitmapDatas.get("logo"));
		box.addChild(image2);
		this.addChild(box);
		box.x = 300;
		box.y = 300;

		for (ix in 0...30) {
			for (iy in 0...100) {
				var image3:Image = new Image(assets.getBitmapData("logo"));
				box.addChild(image3);
				image3.x = ix * 200;
				image3.y = iy * 200;
			}
		}

		this.addEventListener(Event.UPDATE, (e) -> {
			box.rotation++;
		});

		box.mouseEnabled = false;

		for (i in 0...256) {
			var tuzi:Image = new Image(assets.bitmapDatas.get("wabbit_alpha_" + (Std.random(6) + 1)));
			this.addChild(tuzi);
			tuzi.x = Math.random() * stage.stageWidth;
			tuzi.y = Math.random() * stage.stageHeight;
		}

		var images:Array<Image> = [];
		for (i in 0...100) {
			var image3:Image = new Image(assets.bitmapDatas.get("logo"));
			this.addChild(image3);
			image3.x = Math.random() * 500;
			image3.y = Math.random() * 500;
			images.push(image3);
		}

		this.addEventListener(Event.UPDATE, (e:Event) -> {
			for (image in images) {
				image.x += 5;
				image.y += 3;
				image.rotation += Math.random() * 10;
				if (image.x > 500) {
					image.x = 0;
				}
				if (image.y > 500) {
					image.y = 0;
				}
			}
		});

		var emojs:Array<Image> = [];

		for (_ => value in assets.atlases.get("EmojAtlas").bitmapDatas) {
			var atlasImage:Image = new Image(value);
			this.addChild(atlasImage);
			atlasImage.x = Math.random() * stage.stageWidth;
			atlasImage.y = Math.random() * stage.stageHeight;
			emojs.push(atlasImage);
		}

		var img:Image = new Image(assets.atlases.get("EmojAtlas").bitmapDatas.get("zw_5"));
		this.addChild(img);
		img.x = img.y = 100;
		emojs.push(img);

		// for (image in emojs) {
		// 	trace("矩阵", rect);
		// 	// 矩形渲染

		// 矩形渲染

		// 显示一张图片
		var image:Image = new Image(assets.bitmapDatas.get("logo"));
		this.addChild(image);
		image.x = 500;
		image.y = 500;
		image.scaleX = 1;
		image.rotation = 75;
		image.colorTransform = new ColorTransform(0, 0, 0, 1, 255, 255, 255, 0);

		trace("图片矩阵", image.width, image.height, image.getBounds());

		this.addEventListener(MouseEvent.CLICK, (e:MouseEvent) -> {
			trace("点击到了", e.target);
			var display:DisplayObject = e.target;
			display.alpha = 0.5;
			display.visible = false;
		});
	}
}
