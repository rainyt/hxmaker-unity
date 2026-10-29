package demo;

import hx.assets.Assets;
import hx.display.Scene;
import hx.ui.UIManager;

/** 切换示例时释放资源，并阻止已离开的页面执行异步完成回调。 */
class SampleScene extends Scene {
	private var ownedAssets:Array<Assets>;

	public function createAssets():Assets {
		if (ownedAssets == null) ownedAssets = [];
		var assets:Assets = new Assets();
		ownedAssets.push(assets);
		assets.customCompleteValue((future, value) -> {
			if (isDisposed) {
				UIManager.unbindAssets(assets);
				assets.clean();
			} else {
				future.completeValue(value);
			}
		});
		assets.onError((error) -> {
			if (isDisposed) {
				UIManager.unbindAssets(assets);
				assets.stop();
				assets.clean();
			}
		});
		return assets;
	}

	override public function dispose():Void {
		super.dispose();
		if (ownedAssets == null) return;
		for (assets in ownedAssets) {
			UIManager.unbindAssets(assets);
			// 加载中的请求完成后由上面的回调释放，避免晚到资源再次访问舞台。
			if (assets.isComplete || assets.isError) {
				assets.stop();
				assets.clean();
			}
		}
		ownedAssets = [];
	}
}
