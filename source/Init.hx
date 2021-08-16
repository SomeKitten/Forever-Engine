import flixel.FlxG;
import flixel.FlxState;
import flixel.input.keyboard.FlxKey;
import gameFolder.meta.InfoHud;
import gameFolder.meta.data.Highscore;
import gameFolder.meta.state.*;
import gameFolder.meta.state.charting.*;
import openfl.filters.BitmapFilter;
import openfl.filters.ColorMatrixFilter;

/**
	This is the initialisation class. if you ever want to set anything before the game starts or call anything then this is probably your best bet.
	A lot of this code is just going to be similar to the flixel templates' colorblind filters because I wanted to add support for those as I'll
	most likely need them for skater, and I think it'd be neat if more mods were more accessible.
**/
class Init extends FlxState
{
	// FOREVER ENGINE VALUES
	/* While we have our own user interface for the main menus and such, I wanted to give an option for mod makers using the engine to be able to
		toggle the menu easily, I want this to be snazzy but cozy if needed, and all of the abstraction should help point things in the right direction:

			simply said, it won't be a hassle to work with the engine, as the extra features will be toggleable entirely!
	 */
	public static var forceDisableForeverMenu:Bool = false;

	// GLOBAL VALUES (FOR SAVING)
	/*
		Couple notes! These are CASE SENSITIVE and if your pause menu crashes when going into preferences, it may be because its trying to load 
		something that doesnt exist/does not have a value assigned to it. I'll get around to fixing this eventually, but it's also very useful depending
		on how you look at it, so I might end up not fixing it.
	 */
	public static var gameSettings:Map<String, Dynamic> = [
		'Downscroll' => [false, 0],
		'Auto Pause' => [true, 1],
		'FPS Counter' => [true, 2],
		'Memory Counter' => [true, 3],
		'Debug Info' => [false, 4],
		'Reduced Movements' => [false, 5],
		'Display Accuracy' => [true, 10],
		"Deuteranopia" => [false, 6],
		"Protanopia" => [false, 7],
		"Tritanopia" => [false, 8],
		'No Camera Note Movement' => [false, 9],
		'Offset' => [false, 0],
		'Use Forever Chart Editor' => [true, 11],
		'Forever Engine Menus' => [!forceDisableForeverMenu, 12],
		'Optimized Boyfriend' => [true, 13],
		'Optimized Girlfriend' => [true, 14],
		"use Forever Engine UI" => [true, 15],
		// introduced a new system that checks for the settings version in case you/i wanna hard reset stuffs
		'version' => '1',
	];

	public static var settingsDescriptions:Map<String, String> = [
		'Downscroll' => 'Whether or not to display the strum line at the bottom of the screen instead of at the top',
		'Auto Pause' => 'Whether or not the game automatically pauses on lost focus',
		'FPS Counter' => 'Displays the framerate counter at the top left corner of the screen',
		'Memory Counter' => 'Displays the native memory counter at the top left corner of the screen',
		'Debug Info' => 'Displays debug information on the top left corner of the screen',
		'Reduced Movements' => 'Disables things like camera zooming and icon bopping',
		'Display Accuracy' => 'Enables the display of the accuracy counter, and by extension, your stage ranking',
		"Deuteranopia" => 'Enables the colorblind filter for Deuteranopia', "Protanopia" => 'Enables the colorblind filter for Protanopia',
		"Tritanopia" => 'Enables the colorblind filter for Tritanopia', 'No Camera Note Movement' => "Disables forever engine's note-based camera movement",
		'Use Forever Chart Editor' => "Enables the usage of forever engine's custom chart editor (not recommended for now)",
		'Forever Engine Menus' => "Enables the Forever Engine custom Menus (Applies when exiting the options menu)",
		'Optimized Boyfriend' => "Whether to use Forever Engine's custom boyfriend sprites (Mostly an option for modding)",
		'Optimized Girlfriend' => "Much like the last option, but for Girlfriend instead",
		"use Forever Engine UI" => "Makes some changes to the UI, like ratings having colored outlines",
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

		if ((forceDisableForeverMenu) && (gameSettings.get('Forever Engine Menus')[0]))
			gameSettings.get('Forever Engine Menus')[0] = false;

		// apply saved filters
		FlxG.game.setFilters(filters);

		Main.switchState(new PlayState());
	}

	public static function loadSettings():Void
	{
		if ((FlxG.save.data.gameSettings != null)
			&& (FlxG.save.data.gameSettings.get('version') == gameSettings.get('version'))
			&& (Lambda.count(gameSettings) == Lambda.count(FlxG.save.data.gameSettings)))
			gameSettings = FlxG.save.data.gameSettings;
		/* okay so the new system kinda just checks if the version number is the same. I hope it doesn't crash, because if it's null it shouldnt be the same
			and then the save fill will be overriden. I should really just do a system that regenerates the settings file if they have any null settings honestly
		 */

		saveSettings();
		updateAll();
	}

	public static function loadControls():Void
	{
		if ((FlxG.save.data.gameControls != null) && (Lambda.count(FlxG.save.data.gameControls) == Lambda.count(gameControls)))
			gameControls = FlxG.save.data.gameControls;

		saveControls();
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
