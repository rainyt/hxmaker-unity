package hx.core;

import hx.display.EventDispatcher;
import hx.display.DisplayObjectContainer;
import hx.display.DisplayObject;
import hx.display.Stage;
import hx.display.IRender;
import hx.events.Event;
import hx.events.MouseEvent;
import hx.events.TouchEvent;
import hx.events.KeyboardEvent;
import hx.geom.Matrix;
import hx.unity.NativeBridge;
import hx.unity.UnityRuntime;

/** 更新由 Unity 宿主驱动；摄像机只重放已生成的绘制数据。 */
@:access(hx.display.DisplayObject)
@:access(hx.display.Stage)
class Engine extends EventDispatcher implements IEngine {
	public var renderer:IRender;
	public var scaleFactor:Float = 1;
	public var stages:Array<Stage> = [];
	public var touchX:Float = 0;
	public var touchY:Float = 0;
	public var dt:Float = 0;
	public var stageWidth(get, never):Float;
	public var stageHeight(get, never):Float;
	public var devicePixelRatio(get, never):Float;
	public var frameRate(get, set):Int;
	private var width:Float = 1920;
	private var height:Float = 1080;
	private var fps:Int = -1;
	private var disposed:Bool = false;
	private var elapsed:Float = 0;
	public function new() {}
	public function init(stageWidth:Int, stageHeight:Int, lockLandscape:Bool = false):Void {
		if (UnityRuntime.engine != null) throw "Unity 宿主已有活动引擎";
		if (lockLandscape) throw "Unity 屏幕方向请在 Player Settings 中配置，首版不支持 lockLandscape";
		width = stageWidth > 0 ? stageWidth : 1920;
		height = stageHeight > 0 ? stageHeight : 1080;
		renderer = new Render();
		UnityRuntime.engine = this;
		motion.actuators.SimpleActuator.getTime = () -> elapsed;
	}
	private function get_stageWidth():Float { return width; }
	private function get_stageHeight():Float { return height; }
	private function get_devicePixelRatio():Float { return NativeBridge.pixelRatio(); }
	private function get_frameRate():Int { return fps; }
	private function set_frameRate(value:Int):Int { fps = value; NativeBridge.targetFrameRate(value); return value; }
	public function addToStage(stage:Stage):Void {
		if (stage == null || stages.indexOf(stage) >= 0) return;
		var index:Int = stages.indexOf(Hxmaker.topView);
		if (index < 0) stages.push(stage); else stages.insert(index, stage);
		stage.__stageWidth = width; stage.__stageHeight = height;
		stage.onStageInit();
	}
	public function removeToStage(stage:Stage):Void {
		if (stage.openedContextMenu != null) stage.openedContextMenu.close();
		stages.remove(stage);
	}
	/** 逻辑尺寸由应用确定，摄像机分屏和目标纹理尺寸不改变业务舞台。 */
	public function resize(pixelWidth:Float, pixelHeight:Float):Void {
		if (disposed || pixelWidth <= 0 || pixelHeight <= 0) return;
		scaleFactor = Math.min(pixelWidth / width, pixelHeight / height);
		for (stage in stages) {
			stage.__stageWidth = width; stage.__stageHeight = height;
			stage.setDirty(); stage.dispatchEvent(new Event(Event.RESIZE));
		}
	}
	public function update(delta:Float):Void {
		if (disposed || !Math.isFinite(delta) || delta < 0) return;
		dt = delta; elapsed += dt;
		@:privateAccess motion.actuators.SimpleActuator.stage_onEnterFrame();
		hx.net.RequestQueue.update();
		hx.utils.Timer.run(dt);
		hx.procedure.ProcedureManager.instance.update(dt);
		for (stage in stages.copy()) if (!stage.customRender) stage.onUpdate(dt);
		// 先完成虚拟列表及布局，保证本帧新创建的文本也进入字形预请求。
		for (stage in stages) stage.__updateTransform(stage);
		// 先请求全部字形，再构建布局，防止动态字库重排破坏先前记录的 UV。
		for (stage in stages) hx.render.TextFieldRender.requestTree(stage);
		for (stage in stages) hx.render.TextFieldRender.prepareTree(stage);
		var render:Render = cast renderer;
		render.clear();
		try {
			for (stage in stages) if (!stage.customRender) this.render(stage);
			render.endFill();
		} catch (error:Dynamic) {
			render.abort();
			throw error;
		}
	}
	public function render(display:DisplayObjectContainer, ?parentMatrix:Matrix):Void {
		if (parentMatrix != null) throw "Unity 首版暂不支持 render 的额外父矩阵";
		display.__updateTransform(display);
		renderer.renderDisplayObject(display);
	}
	public function pointer(type:String, x:Float, y:Float, id:Int = -1, delta:Float = 0):Void {
		if (disposed) return;
		touchX = x; touchY = y;
		var event:MouseEvent;
		if (id >= 0) {
			var touch:TouchEvent = new TouchEvent(type, false, true);
			touch.touchPointID = id; touch.touchX = x; touch.touchY = y;
			event = touch;
		} else event = new MouseEvent(type, false, true);
		event.stageX = x; event.stageY = y; event.delta = delta;
		var hit:Bool = true;
		var index:Int = stages.length;
		while (index-- > 0) if (stages[index].handleMouseEvent(event, hit)) hit = false;
	}
	public function keyboard(type:String, code:Int, modifiers:Int):Void {
		var event:KeyboardEvent = new KeyboardEvent(type, false, true);
		event.keyCode = code; event.shiftKey = (modifiers & 1) != 0; event.ctrlKey = (modifiers & 2) != 0;
		event.altKey = (modifiers & 4) != 0; event.metaKey = (modifiers & 8) != 0;
		if (type == KeyboardEvent.KEY_DOWN) { @:privateAccess hx.utils.KeyboardTools.onKeyDown(code); }
		else { @:privateAccess hx.utils.KeyboardTools.onKeyUp(code); }
		var index:Int = stages.length;
		while (index-- > 0) if (!event.isDefaultPrevented) stages[index].handleKeyboardEvent(event);
	}
	public function activate(active:Bool):Void {
		for (stage in stages) stage.dispatchEvent(new Event(active ? Event.ACTIVATE : Event.DEACTIVATE));
	}
	public function dispose():Void {
		if (disposed) return;
		disposed = true;
		for (stage in stages.copy()) {
			if (stage.openedContextMenu != null) stage.openedContextMenu.close();
			stage.dispose();
		}
		stages.resize(0);
		cast(renderer, Render).dispose();
		hx.net.RequestQueue.dispose();
		motion.Actuate.reset();
		hx.utils.Timer.resetAll();
		hx.utils.KeyboardTools.reset();
		removeEventListeners();
		UnityRuntime.engine = null;
		@:privateAccess Hxmaker.__engine = null;
		Hxmaker.topView = new Stage();
	}
}
