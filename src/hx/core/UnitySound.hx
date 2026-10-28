package hx.core;

import hx.assets.ISound;
import hx.assets.ISoundChannel;
import hx.unity.NativeBridge;

class UnitySound implements ISound {
	private var handle:Int;
	public function new(handle:Int) { this.handle = handle; }
	public function play(isLoop:Bool = false):ISoundChannel {
		if (handle == 0) throw "音频已经释放";
		return new UnitySoundChannel(NativeBridge.playSound(handle, isLoop));
	}
	public function dispose():Void { if (handle != 0) { NativeBridge.releaseSound(handle); handle = 0; } }
}
