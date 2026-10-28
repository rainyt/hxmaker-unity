package hx.core;

import hx.assets.Future;
import hx.net.RequestQueue;
import hx.display.BitmapData;

class BitmapDataFuture extends Future<BitmapData, String> {
	private var pending:Bool = false;
	override public function post():Void {
		if (pending || isComplete) return;
		pending = true;
		isError = false;
		RequestQueue.load(2, getLoadData(), (data:Dynamic, failure:hx.events.FutureErrorEvent) -> {
			pending = false;
			if (failure != null) errorValue(failure);
			else { progressValue(1); completeValue(cast data, RequestQueue.key(2, path)); }
		});
	}
}
