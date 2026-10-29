package demo;

import hx.assets.Assets;
import hx.ui.UIAssets;
import hx.ui.UIManager;

/** 使用原 XML 构建界面，同时遵守示例页的异步资源生命周期。 */
class SampleUILoadScene extends SampleScene {
	private var pendingUI:UIAssets;

	override private function onBuildUI():Void {
		var path:String = cast Reflect.getProperty(this, "__ui_id__");
		if (path == null) return;
		var assets:Assets = createAssets();
		assets.loadUIAssets(path);
		assets.onComplete((data) -> {
			UIManager.bindAssets(assets);
			pendingUI = assets.uiAssetses.get(Assets.formatName(path));
			buildPendingUI();
		}).onError((error) -> trace("XML 示例加载失败：", error));
		assets.start();
	}

	override public function onAddToStage():Void {
		super.onAddToStage();
		buildPendingUI();
	}

	private function buildPendingUI():Void {
		if (stage == null || pendingUI == null || isDisposed) return;
		var ui:UIAssets = pendingUI;
		pendingUI = null;
		ui.build(this);
		onLoaded();
	}

	public function onLoaded():Void {}
}
