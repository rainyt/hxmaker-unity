import hx.core.Hxmaker;
import hx.core.UnityBitmapData;
import hx.display.Stage;
import hx.display.Sprite;
import hx.display.Image;
import hx.display.Quad;
import hx.display.Label;
import hx.display.Graphics;
import hx.display.TextFormat;
import hx.display.BitmapData;
import hx.events.Event;
import hx.events.MouseEvent;
import motion.Actuate;

/** 无外部图片的人工验收场景；字体需要在 Unity 宿主上配置。 */
class GameStage extends Stage {
	private var textures:Array<BitmapData> = [];
	private var counter:Label;
	private var rotationRoot:Sprite;
	override public function onStageInit():Void {
		super.onStageInit();
		addChild(new Quad(960, 540, 0x17243a));
		var title:Label = new Label("hxmaker Unity · 多纹理与多镜头", new TextFormat(null, 30, 0xffffff));
		title.x = 24; title.y = 20; addChild(title);
		rotationRoot = new Sprite(); rotationRoot.x = 160; rotationRoot.y = 200; addChild(rotationRoot);
		var colors:Array<Int> = [0xffef5350, 0xff66bb6a, 0xff42a5f5, 0xffffca28, 0xffab47bc, 0xff26c6da, 0xffff7043, 0xffeeeeee, 0xff78909c];
		for (i in 0...colors.length) {
			var data:BitmapData = UnityBitmapData.fromSize(32, 32, colors[i]); textures.push(data);
			var image:Image = new Image(data); image.x = i * 44; image.y = i % 2 * 44; rotationRoot.addChild(image);
		}
		var clipped:Sprite = new Sprite(); clipped.x = 560; clipped.y = 130;
		clipped.maskRect = new hx.geom.Rectangle(0, 0, 240, 130); addChild(clipped);
		var inner:Sprite = new Sprite(); inner.x = 70; inner.maskRect = new hx.geom.Rectangle(0, 0, 220, 100); clipped.addChild(inner);
		inner.addChild(new Quad(300, 160, 0x26c6da));
		var path:Graphics = new Graphics(); path.x = 560; path.y = 310; path.beginFill(0xffca28); path.drawCircle(0, 0, 55); addChild(path);
		counter = new Label("", new TextFormat(null, 22, 0xffffff)); counter.x = 24; counter.y = 440; counter.width = 900; addChild(counter);
		var toggle:Label = new Label("点击切换单纹理／多纹理", new TextFormat(null, 24, 0x80deea));
		toggle.x = 24; toggle.y = 490; toggle.mouseEnabled = true; addChild(toggle);
		toggle.addEventListener(MouseEvent.CLICK, (_:MouseEvent) -> Hxmaker.engine.renderer.multiTextureEnabled = !Hxmaker.engine.renderer.multiTextureEnabled);
		Actuate.tween(path, 1.5, {x: 800.}).reflect().repeat();
		updateEnabled = true;
	}
	override public function onUpdate(dt:Float):Void {
		super.onUpdate(dt);
		rotationRoot.rotation += dt * 10;
		var render:hx.core.Render = cast Hxmaker.engine.renderer;
		counter.data = "上一帧批次：" + render.drawCall + "  多纹理：" + render.multiTextureEnabled + "  原生场景与多个镜头可同时显示";
	}
	override public function dispose():Void { super.dispose(); for (texture in textures) texture.dispose(); textures = []; }
}
