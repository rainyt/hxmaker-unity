package hx.core;

import hx.display.Stage;

/** Unity 应用入口；业务初始化方式与其他后端保持一致。 */
class HxmakerApplication {
	public function new() {}
	public function init(mainClasses:Class<Stage>, hdwidth:Int = 1920, hdheight:Int = 1080, cacheAsBitmap:Bool = false, lockLandscape:Bool = false):Void {
		if (Hxmaker.engine != null) throw "Unity 宿主只能初始化一个 hxmaker 引擎";
		Hxmaker.init(Engine, hdwidth, hdheight, cacheAsBitmap, lockLandscape);
		Hxmaker.engine.addToStage(Type.createInstance(mainClasses, []));
	}
}
