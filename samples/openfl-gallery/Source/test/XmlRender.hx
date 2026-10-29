package test;

import hx.ui.UIManager;
import hx.assets.Assets;
import hx.display.Scene;
import demo.SampleScene;

/**
 * 读取配置构造界面
 */
class XmlRender extends SampleScene {
	override function onStageInit():Void {
		super.onStageInit();
		var uiAssets:Assets = createAssets();
		UIManager.bindAssets(uiAssets);
		uiAssets.loadUIAssets("assets/views/XmlScene.xml");
		uiAssets.onComplete((a) -> {
			trace("加载完成");
			var view:XmlRenderView = new XmlRenderView();
			this.addChild(view);
		}).onError(err -> {
			trace("加载失败");
		});
		uiAssets.start();
	}
}

@:build(hx.macro.UIBuilder.build("assets/views/XmlScene.xml"))
class XmlRenderView extends SampleScene {
	override function onInit():Void {
		super.onInit();
		this.btn_view.clickEvent = () -> {
			trace("触发点击");
		}
	}
}
