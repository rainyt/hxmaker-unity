package hx.core;

import hx.assets.Future;
import hx.net.RequestQueue;
import hx.assets.Sound;

class SoundFuture extends Future<Sound, String> {
	private var pending:Bool = false;
	public var isMusic:Bool = false;
	override public function post():Void {
		if (pending || isComplete) return;
		pending = true;
		isError = false;
		RequestQueue.load(3, getLoadData(), (data:Dynamic, failure:hx.events.FutureErrorEvent) -> {
			pending = false;
			if (failure != null) errorValue(failure);
			else { progressValue(1); completeValue(cast data, RequestQueue.key(3, path)); }
		});
	}
}
