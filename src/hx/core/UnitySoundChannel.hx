package hx.core;

import hx.display.EventDispatcher;
import hx.assets.ISoundChannel;
import hx.events.SoundEvent;
import hx.unity.NativeBridge;

class UnitySoundChannel extends EventDispatcher implements ISoundChannel {
	private static var channels:Array<UnitySoundChannel> = [];
	private var handle:Int;
	public function new(handle:Int) { this.handle = handle; channels.push(this); }
	public function stop():Void {
		if (handle == 0) return;
		NativeBridge.stopSound(handle); handle = 0; channels.remove(this);
	}
	public function setVolume(volume:Float, pan:Float = 0):Void { if (handle != 0) NativeBridge.soundVolume(handle, volume, pan); }
	public static function update():Void {
		for (channel in channels.copy()) if (!NativeBridge.soundPlaying(channel.handle)) {
			channel.stop(); channel.dispatchEvent(new SoundEvent(SoundEvent.SOUND_COMPLETE));
		}
	}
	public static function disposeAll():Void { for (channel in channels.copy()) channel.stop(); }
}
