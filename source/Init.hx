import flixel.FlxG;
import flixel.FlxState;
import gameFolder.meta.data.Highscore;
import gameFolder.meta.state.*;
import openfl.filters.BitmapFilter;
import openfl.filters.ColorMatrixFilter;

/**
	This is the initialisation class. if you ever want to set anything before the game starts or call anything then this is probably your best bet.
	A lot of this code is just going to be similar to the flixel templates' colorblind filters because I wanted to add support for those as I'll
	most likely need them for skater, and I think it'd be neat if more mods were more accessible.
**/
class Init extends FlxState
{
	public static var settingsMap:Map<String, Dynamic> = new Map<String, Dynamic>();
	public static var filters:Array<BitmapFilter> = []; // the filters the game has active
	/// initalise filters here
	public static var gameFilters:Map<String, {filter:BitmapFilter, ?onUpdate:Void->Void}> = [
		"Deuteranopia" => {
			var matrix:Array<Float> = [
				0.43, 0.72, -.15, 0, 0,
				0.34, 0.57, 0.09, 0, 0,
				-.02, 0.03,    1, 0, 0,
				   0,    0,    0, 1, 0,
			];
			{filter: new ColorMatrixFilter(matrix)}
		},
		"Protanopia" => {
			var matrix:Array<Float> = [
				0.20, 0.99, -.19, 0, 0,
				0.16, 0.79, 0.04, 0, 0,
				0.01, -.01,    1, 0, 0,
				   0,    0,    0, 1, 0,
			];
			{filter: new ColorMatrixFilter(matrix)}
		},
		"Tritanopia" => {
			var matrix:Array<Float> = [
				0.97, 0.11, -.08, 0, 0,
				0.02, 0.82, 0.16, 0, 0,
				0.06, 0.88, 0.18, 0, 0,
				   0,    0,    0, 1, 0,
			];
			{filter: new ColorMatrixFilter(matrix)}
		}
	];

	///

	override public function create():Void
	{
		FlxG.save.bind('funkin', 'forever');
		Highscore.load();

		// apply saved filters
		FlxG.game.setFilters(filters);

		Main.switchState(new TitleState());
	}

	public static function loadSettings():Void
	{
		if (FlxG.save.data.settingsMap != null)
			settingsMap = FlxG.save.data.settingsMap;
	}

	static function saveSettings(setting:String, settingSettings:Dynamic):Void
	{
		// amazing naming conventions right here
		settingsMap.set(setting, settingSettings);
		// anyways tho
		FlxG.save.data.settingsMap = settingsMap;
		FlxG.save.flush();
	}
}
