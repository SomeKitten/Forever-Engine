package;

import flixel.FlxG;
import flixel.FlxGame;
import flixel.FlxState;
import gameFolder.meta.*;
import gameFolder.meta.data.PlayerSettings;
import openfl.Assets;
import openfl.Lib;
import openfl.display.FPS;
import openfl.display.Sprite;
import openfl.events.Event;

// Here we actually import the states and metadata, and just the metadata.
// It's nice to have modularity so that we don't have ALL elements loaded at the same time.
// at least that's how I think it works. I could be stupid!
class Main extends Sprite
{
	/*
		This is the main class of the project, it basically connects everything together.
		If you know what you're doing, go ahead and shoot! if you're looking for something more specific, however,
		try accessing some game objects or meta files, meta files control the information (say what's playing on screen)
		and game objects are like the boyfriend, girlfriend and the oppontent. 

		Thanks for using my little modular engine project! I really appreciate it. 
		If you've got any suggestions let me know at Shubs#0404 on discord or create a ticket on the github.

		To run through the basics, I've essentially created a rewrite of Friday Night Funkin that is supposed to be
		more modular for mod devs to use if they want to, as well as to give mod devs a couple legs up in terms of
		things like organisation and such, since I haven't really seen any engines that are organised like this.
		also, playstate was getting real crowded so I did a me and decided to rewrite everything instead of just
		fixing the problems with FNF :P

		yeah this is a problem I have
		it has to be perfect or else it isn't presentable

		I'm sure I'll write this down in the github, but this is an open source Friday Night Funkin' Modding engine
		which is completely open for anyone to modify. I have a couple of requests and prerequisites however, and that is
		that you, number one, in no way claim this engine as your own. If you're going to make an open source modification to the engine
		you should run a pull request or fork and not create a new standalone repo for it. If you're actually going to mod the game however,
		please, by all means, create your own repository for it instead as it would be your project then. I also request the engine is credited
		somewhere in the project. (in the gamebanana page, wherever you'd like/is most convenient for you!)
		if you don't wanna credit me that's fine, I just ask for the project to be in the credits somewhere 
		I do ask that you credit me if you make an actual modification to the engine or something like that, basically what I said above

		I have no idea how licenses work so pretend I'm professional or something AAAA
		thank you for using this engine it means a lot to me :)

		if you have any questions like I said, shoot me a message or something, I'm totally cool with it even if it's just help with programming or something
		>	fair warning I'm not a very good programmer
	 */
	// class action variables
	public static var gameWidth:Int = 1280; // Width of the game in pixels (might be less / more in actual pixels depending on your zoom).
	public static var gameHeight:Int = 720; // Height of the game in pixels (might be less / more in actual pixels depending on your zoom).

	public static var mainClassState:Class<FlxState> = Init; // Determine the main class state of the game

	/*  This is used to switch "rooms," to put it basically. Imagine you are in the main menu, and press the freeplay button.
		That would change the game's main class to freeplay, as it is the active class at the moment.
	 */
	var zoom:Float = -1; // If -1, zoom is automatically calculated to fit the window dimensions.
	var framerate:Int = 120; // How many frames per second the game should run at.
	var skipSplash:Bool = true; // Whether to skip the flixel splash screen that appears in release mode.
	var infoHudDisplay:Bool = true; // Whether to display additional debug information.
	var infoCounter:InfoHud; // initialize the heads up display that shows information before creating it.

	// most of these variables are just from the base game!
	// be sure to mess around with these if you'd like.

	public static function main():Void
	{
		Lib.current.addChild(new Main());
	}

	// calls a function to set the game up
	public function new()
	{
		super();

		setupGame(); // oh right yeah actually run the game lmfao what a fucking dumbass I am
	}

	private function setupGame():Void
	{
		var stageWidth:Int = Lib.current.stage.stageWidth;
		var stageHeight:Int = Lib.current.stage.stageHeight;
		// simply said, a state is like the 'surface' area of the window where everything is drawn.
		// if you've used gamemaker you'll probably understand the term surface better
		// this defines the surface bounds

		if (zoom == -1)
		{
			var ratioX:Float = stageWidth / gameWidth;
			var ratioY:Float = stageHeight / gameHeight;
			zoom = Math.min(ratioX, ratioY);
			gameWidth = Math.ceil(stageWidth / zoom);
			gameHeight = Math.ceil(stageHeight / zoom);
			// this just kind of sets up the camera zoom in accordance to the surface width and camera zoom.
			// if set to negative one, it is done so automatically, which is the default.
		}

		// here we set up the base game
		var gameCreate:FlxGame;
		gameCreate = new FlxGame(gameWidth, gameHeight, mainClassState, zoom, framerate, framerate, skipSplash);
		addChild(gameCreate); // and create it afterwards

		// default game FPS settings, I'll probably comment over them later.
		// addChild(new FPS(10, 3, 0xFFFFFF));

		// test initialising the player settings
		PlayerSettings.init();

		// if you're reading this in the future I've added my own FPS counter below! hopefully...
		// yeah dw I'm getting started on it fffff

		infoCounter = new InfoHud(10, 3, 0xFFFFFF, infoHudDisplay);
		addChild(infoCounter);
	}

	/// function for going to different states and such
	public static function switchState(target:FlxState)
	{
		// this is for a dumb feature that has no use except for cool extra info
		mainClassState = Type.getClass(target);
		// though I suppose this could be of use to people who want to load things between classes and such
		// not that that would be of use to people who aren't already writing their own engines lmfao

		// load the state
		FlxG.switchState(target);
	}
}
