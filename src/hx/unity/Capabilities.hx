package hx.unity;

/** 首版实际能力；纹理槽位是设备与宿主配置的运行时结果。 */
class Capabilities {
	public static inline var scene3D:Bool = false;
	public static inline var textInput:Bool = false;
	public static inline var filters:Bool = false;
	public static inline var advancedBlend:Bool = false;
	public static inline var customShader:Bool = false;
	public static inline var nativeDisplay:Bool = false;
	public static inline var bitmapDraw:Bool = false;
	public static var multiTextureSlots(get, never):Int;
	private static function get_multiTextureSlots():Int { return NativeBridge.textureSlots(); }
}
