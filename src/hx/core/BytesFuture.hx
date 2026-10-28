package hx.core;

import hx.assets.Future;
import hx.net.RequestQueue;
import haxe.io.Bytes;

class BytesFuture extends Future<Bytes, String> {
	private var pending:Bool = false;
	override public function post():Void {
		if (pending || isComplete) return;
		pending = true;
		isError = false;
		RequestQueue.load(0, getLoadData(), (data:Dynamic, failure:hx.events.FutureErrorEvent) -> {
			pending = false;
			if (failure != null) errorValue(failure);
			else { progressValue(1); completeValue(cast data, RequestQueue.key(0, path)); }
		});
	}
}
