import flixel.FlxG;
import flixel.FlxState;
import flixel.graphics.FlxGraphic;
import flixel.input.keyboard.FlxKey;
import gameFolder.meta.CoolUtil;
import gameFolder.meta.InfoHud;
import gameFolder.meta.data.Highscore;
import gameFolder.meta.data.dependency.Discord;
import gameFolder.meta.state.*;
import gameFolder.meta.state.charting.*;
import openfl.filters.BitmapFilter;
import openfl.filters.ColorMatrixFilter;

using StringTools;

/**
	This is the initialisation class. if you ever want to set anything before the game starts or call anything then this is probably your best bet.
	A lot of this code is just going to be similar to the flixel templates' colorblind filters because I wanted to add support for those as I'll
	most likely need them for skater, and I think it'd be neat if more mods were more accessible.
**/
class Init extends FlxState
{
	/*
		Okay so here we'll set custom settings. As opposed to the previous options menu, everything will be handled in here with no hassle.
		This will read what the second value of the key's array is, and then it will categorise it, telling the game which option to set it to.

		0 - boolean, true or false checkmark
		1 - choose string
		2 - choose number (for fps so its low capped at 30)
		3 - offsets, this is unused but it'd bug me if it were set to 0
		might redo offset code since I didnt make it and it bugs me that it's hardcoded the the last part of the controls menu
	 */
	public static var FORCED = 'forced';
	public static var NOT_FORCED = 'not forced';

	public static var gameSettings:Map<String, Dynamic> = [
		'Downscroll' => [
			false,
			0,
			'Whether to have the strumline vertically flipped in gameplay.',
			NOT_FORCED
		],
		'Auto Pause' => [true, 0, '', NOT_FORCED],
		'FPS Counter' => [true, 0, 'Whether to display the FPS counter.', NOT_FORCED],
		'Memory Counter' => [
			true,
			0,
			'Whether to display approximately how much memory is being used.',
			NOT_FORCED
		],
		'Debug Info' => [false, 0, 'Whether to display information like your game state.', NOT_FORCED],
		'Reduced Movements' => [
			false,
			0,
			'Whether to reduce movements, like icons bouncing or beat zooms in gameplay.',
			NOT_FORCED
		],
		'Display Accuracy' => [true, 0, 'Whether to display your accuracy on screen.', NOT_FORCED],
		'Disable Antialiasing' => [
			false,
			0,
			'Whether to disable Anti-aliasing. Helps improve performance in FPS.',
			NOT_FORCED
		],
		'No Camera Note Movement' => [
			false,
			0,
			'When enabled, left and right notes no longer move the camera.',
			NOT_FORCED
		],
		'Use Forever Chart Editor' => [
			true,
			0,
			'When enabled, uses the custom Forever Engine chart editor!',
			NOT_FORCED
		],
		'Disable Note Splashes' => [
			false,
			0,
			'Whether to disable note splashes in gameplay. Useful if you find them distracting.',
			NOT_FORCED
		],
		// custom ones lol
		'Offset' => [0, 3],
		'Filter' => [
			'none',
			1,
			'Choose a filter for colorblindness.',
			NOT_FORCED,
			['none', 'Deuteranopia', 'Protanopia', 'Tritanopia']
		],
		"UI Skin" => ['default', 1, 'Choose a UI Skin for judgements, combo, etc.', NOT_FORCED, ''],
		"Note Skin" => ['default', 1, 'Choose a note skin.', NOT_FORCED, ''],
		"Framerate Cap" => [120, 1, 'Define your maximum FPS.', NOT_FORCED, ['']],
		"Opaque Arrows" => [false, 0, "Makes the arrows at the top of the screen opaque again.", NOT_FORCED],
		"Opaque Holds" => [false, 0, "Huh, why isnt the trail cut off?", NOT_FORCED],
		'Ghost Tapping' => [
			false,
			0,
			"Enables Ghost Tapping, allowing you to press inputs without missing.",
			NOT_FORCED
		],
		'Centered Notefield' => [false, 0, "Center the notes, disables the enemy's notes."],
		"Custom Titlescreen" => [
			false,
			0,
			"Enables the custom Forever Engine titlescreen! (only effective with a restart)",
			FORCED
		],
		'SM-like Judgements' => [
			false,
			0,
			"Fixes the judgements to the camera instead of to the world itself, making them easier to read."
		],
		'Display Miss Count' => [
			false,
			0,
			"When enabled, displays the amount of combo breaks you have in a song."
		],
	];

	public static var trueSettings:Map<String, Dynamic> = [];
	public static var settingsDescriptions:Map<String, String> = [];

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

	override public function create():Void
	{
		FlxG.save.bind('foreverengine-options');
		Highscore.load();

		loadSettings();
		loadControls();

		#if !html5
		Main.updateFramerate(trueSettings.get("Framerate Cap"));
		#end

		// apply saved filters
		FlxG.game.setFilters(filters);

		// Some additional changes to default HaxeFlixel settings, both for ease of debugging
		// and usability.
		FlxG.fixedTimestep = false; // This ensures that the game is not tied to the FPS
		FlxG.mouse.useSystemCursor = true; // Use system cursor because it's prettier
		FlxG.mouse.visible = false; // Hide mouse on start

		// Main.switchState(this, new ChartingState());
		gotoTitleScreen();
	}

	private function gotoTitleScreen()
	{
		if (trueSettings.get("Custom Titlescreen"))
			Main.switchState(this, new CustomTitlescreen());
		else
			Main.switchState(this, new TitleState());
	}

	public static function loadSettings():Void
	{
		// set the true settings array
		// only the first variable will be saved! the rest are for the menu stuffs

		// IF YOU WANT TO SAVE MORE THAN ONE VALUE MAKE YOUR VALUE AN ARRAY INSTEAD
		for (setting in gameSettings.keys())
			trueSettings.set(setting, gameSettings.get(setting)[0]);

		// NEW SYSTEM, INSTEAD OF REPLACING THE WHOLE THING I REPLACE EXISTING KEYS
		// THAT WAY IT DOESNT HAVE TO BE DELETED IF THERE ARE SETTINGS CHANGES
		if (FlxG.save.data.settings != null)
		{
			var settingsMap:Map<String, Dynamic> = FlxG.save.data.settings;
			for (singularSetting in settingsMap.keys())
				if (gameSettings.get(singularSetting) != null && gameSettings.get(singularSetting)[3] != FORCED)
					trueSettings.set(singularSetting, FlxG.save.data.settings.get(singularSetting));
		}

		// lemme fix that for you
		if (!Std.isOfType(trueSettings.get("Framerate Cap"), Int)
			|| trueSettings.get("Framerate Cap") < 30
			|| trueSettings.get("Framerate Cap") > 360)
			trueSettings.set("Framerate Cap", 30);

		// 'hardcoded' ui skins
		gameSettings.get("UI Skin")[4] = CoolUtil.returnAssetsLibrary('UI');
		if (!gameSettings.get("UI Skin")[4].contains(trueSettings.get("UI Skin")))
			trueSettings.set("UI Skin", 'default');
		gameSettings.get("Note Skin")[4] = CoolUtil.returnAssetsLibrary('noteskins/notes');
		if (!gameSettings.get("Note Skin")[4].contains(trueSettings.get("Note Skin")))
			trueSettings.set("Note Skin", 'default');

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
		FlxG.save.data.settings = trueSettings;
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
		InfoHud.updateDisplayInfo(trueSettings.get('FPS Counter'), trueSettings.get('Debug Info'), trueSettings.get('Memory Counter'));

		#if !html5
		Main.updateFramerate(trueSettings.get("Framerate Cap"));
		#end

		///*
		filters = [];
		FlxG.game.setFilters(filters);

		var theFilter:String = trueSettings.get('Filter');
		if (gameFilters.get(theFilter) != null)
		{
			var realFilter = gameFilters.get(theFilter).filter;

			if (realFilter != null)
				filters.push(realFilter);
		}

		FlxG.game.setFilters(filters);
		// */
	}
}
