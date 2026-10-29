import hx.core.HxmakerApplication;

/** 应用入口；场景与交互由业务舞台负责。 */
class Main extends HxmakerApplication {
	public static function main():Void {
		new Main();
	}

	public function new() {
		super();
		init(Game, 1920, 1080);
	}
}
