package test;

import hx.assets.SpineTextureAtlas;
import hx.display.Spine;
import hx.display.MovieClip;
import hx.display.DisplayObjectContainer;
import hx.events.MouseEvent;
import hx.display.TextFormat;
import hx.display.Label;
import hx.events.Event;
import hx.display.Image;
import hx.assets.Assets;
import hx.display.Scene;
import demo.SampleScene;

class SpineDuckRender extends SampleScene {
	/**
	 * 资源管理器
	 */
	var assets:Assets;

	var label:Label = new Label();

	var bunnys:Array<SpineBunny> = [];

	var gravity:Float = 0.5;

	var box:DisplayObjectContainer;

	override function onStageInit():Void {
		super.onStageInit();
		assets = createAssets();
		box = new DisplayObjectContainer();
		this.addChild(box);
		assets.loadSpineAtlas("assets/spine/onionDuck.png", "assets/spine/onionDuck.atlas");
		assets.loadString("assets/spine/onionDuck.json");
		assets.onComplete((data) -> {
			this.onLoaded();
		}).onError(err -> {
			trace("加载失败");
		});
		assets.start();

		this.addChild(label);
		label.width = stage.stageWidth;
		label.horizontalAlign = CENTER;
		label.height = 50;
		label.textFormat = new TextFormat(null, 46, 0xff0000);
	}

	public function onLoaded():Void {
		this.createBunny();
		this.addEventListener(Event.UPDATE, onUpdateEvent);
	}

	override function onAddToStage():Void {
		super.onAddToStage();
		this.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
	}

	override function onRemoveToStage():Void {
		super.onRemoveToStage();
		this.removeEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
	}

	private function onMouseDown(e:MouseEvent):Void {
		if (assets == null || !assets.isComplete) return;
		createBunny(50);
	}

	private function createBunny(counts:Int = 50):Void {
		for (i in 0...counts) {
			var spineAtlas:SpineTextureAtlas = cast assets.atlases.get("onionDuck");
			var bunny:SpineBunny = new SpineBunny(spineAtlas.createSkeletonData(assets.strings.get("onionDuck")));
			box.addChild(bunny);
			bunny.x = Math.random() * this.stage.stageWidth;
			bunny.y = Math.random() * this.stage.stageHeight;
			bunny.speedX = Math.random() * 5;
			bunny.speedY = (Math.random() * 5) - 2.5;
			bunny.scaleX = bunny.scaleY = 0.5;
			bunnys.push(bunny);
			bunny.play("run", 0, true);
		}
		label.data = "数量：" + bunnys.length;
	}

	private function onUpdateEvent(e:Event):Void {
		for (bunny in bunnys) {
			bunny.x += bunny.speedX;
			bunny.y += bunny.speedY;
			bunny.speedY += gravity;
			if (bunny.x > stage.stageWidth) {
				bunny.speedX *= -1;
				bunny.x = stage.stageWidth;
			} else if (bunny.x < 0) {
				bunny.speedX *= -1;
				bunny.x = 0;
			}

			if (bunny.y > stage.stageHeight) {
				bunny.speedY *= -0.8;
				bunny.y = stage.stageHeight;

				if (Math.random() > 0.5) {
					bunny.speedY -= 3 + Math.random() * 4;
				}
			} else if (bunny.y < 0) {
				bunny.speedY = 0;
				bunny.y = 0;
			}
		}
	}
}

/**
 * Spine
 */
class SpineBunny extends Spine {
	public var speedX:Float = 1;
	public var speedY:Float = 1;
}
