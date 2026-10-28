package hx.core;

import hx.assets.Future;
import hx.display.BitmapData;
import hx.events.FutureErrorEvent;
import hx.net.RequestQueue;
import haxe.io.Bytes;

class BitmapDataBytesFuture extends Future<BitmapData, {bytes:Bytes, path:String}> {
	override public function post():Void {
		if (isComplete) return;
		isError = false;
		try {
			var bitmap:BitmapData = UnityBitmapData.fromBytes(getLoadData().bytes);
			completeValue(bitmap, RequestQueue.adoptBitmap(bitmap, path));
		} catch (error:Dynamic) { errorValue(FutureErrorEvent.create(FutureErrorEvent.LOAD_ERROR, -1, Std.string(error), path)); }
	}
}
