import flixel.FlxG;
import flixel.FlxState;
import flixel.input.keyboard.FlxKey;
import gameFolder.meta.InfoHud;
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
	// GLOBAL VALUES (FOR SAVING)
	public static var gameSettings:Map<String, Dynamic> = [
		'Downscroll' => [false, 0], 'Auto Pause' => [true, 1], 'FPS Counter' => [true, 2], 'Memory Counter' => [true, 3], 'Debug Info' => [false, 4],
		'Reduced Movements' => [false, 5], 'Display Accuracy' => [true, 10], "Deuteranopia" => [false, 6], "Protanopia" => [false, 7],
		"Tritanopia" => [false, 8], 'No camera note movement' => [false, 9],
	];

	public static var gameControls:Map<String, Dynamic> = [
		'UP' => [[FlxKey.UP, W], 2],
		'DOWN' => [[FlxKey.DOWN, S], 1],
		'LEFT' => [[FlxKey.LEFT, A], 0],
		'RIGHT' => [[FlxKey.RIGHT, D], 3],
		'ACCEPT' => [[FlxKey.SPACE, Z, FlxKey.ENTER], 4],
		'BACK' => [[FlxKey.BACKSPACE, X, FlxKey.ESCAPE], 5],
		'PAUSE' => [[FlxKey.ENTER, P], 6],
		'RESET' => [[R, null], 7]
	];

	// SETTING MAPS
	public static var settingsMap:Array<Dynamic> = new Array<Dynamic>();
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

		loadSettings();
		loadControls();

		// apply saved filters
		FlxG.game.setFilters(filters);

		Main.switchState(new TitleState());
	}

	public static function loadSettings():Void
	{
		if ((FlxG.save.data.gameSettings != null) && (Lambda.count(FlxG.save.data.gameSettings) == Lambda.count(gameSettings)))
			gameSettings = FlxG.save.data.gameSettings;
		/* else // was originally gonna have something to reset the settings or some shit but then
			I realised that was unneccessary and would just break savefiles sometimes so if you launch an older version
			it automatically wipes your save, I only want it to wipe your save if its like updated settings or something
			lol
		}*/

		updateAll();
	}

	public static function loadControls():Void
	{
		if ((FlxG.save.data.gameControls != null) && (Lambda.count(FlxG.save.data.gameControls) == Lambda.count(gameControls)))
			gameControls = FlxG.save.data.gameControls;
	}

	public static function saveSettings():Void
	{
		// ez save lol
		FlxG.save.data.gameSettings = gameSettings;
		FlxG.save.flush();

		updateAll();
	}

	public static function saveControls():Void
	{
		FlxG.save.data.gameControls = gameControls;
		FlxG.save.flush();
	}

	public static function updateAll()
	{
		InfoHud.updateDisplayInfo(gameSettings.get('FPS Counter')[0], gameSettings.get('Debug Info')[0], gameSettings.get('Memory Counter')[0]);

		filters = [];
		FlxG.game.setFilters(filters);

		for (string in gameFilters.keys())
		{
			if (gameSettings.get(string)[0])
				filters.push(gameFilters.get(string).filter);
		}

		FlxG.game.setFilters(filters);
	}
}
