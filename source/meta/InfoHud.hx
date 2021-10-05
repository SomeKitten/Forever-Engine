package meta;

// import Main;
import flixel.FlxG;
import haxe.Timer;
import openfl.events.Event;
import openfl.system.System;
import openfl.text.TextField;
import openfl.text.TextFormat;

/**
	This is the infoHud class that is derrived from the default FPS class from haxeflixel.
	It displays debug information, like frames per second, and active states.
	Hopefully I can also add memory usage in here (reminder to remove later if I don't know how to)
**/
class InfoHud extends TextField
{
	// set up variables
	public static var currentFPS(default, null):Int;
	public static var memoryUsage:Float;

	// display info
	public static var displayFps = true;
	public static var displayMemory = true;
	public static var displayExtra = true;

	// I also like to set them up so that you can call on them later since they're static
	// anyways heres some other stuff I didn't write most of this so its just standard fps stuff
	private var cacheCount:Int;
	private var currentTime:Float;
	private var times:Array<Float>;
	private var display:Bool;

	public function new(x:Float = 10, y:Float = 10, color:Int = 0x000000, hudDisplay:Bool = false)
	{
		super();

		display = hudDisplay;

		this.x = x;
		this.y = y;

		currentFPS = 0;
		selectable = false;
		mouseEnabled = false;
		// might as well have made it comic sans
		defaultTextFormat = new TextFormat(Paths.font("vcr.ttf"), 16, color);
		// set text area for the time being
		width = Main.gameWidth;
		height = Main.gameHeight;

		text = "FPS: \nState: \nMemory:";

		cacheCount = 0;
		currentTime = 0;
		times = [];

		#if flash
		addEventListener(Event.ENTER_FRAME, function(e)
		{
			var time = Lib.getTimer();
			__enterFrame(time - currentTime);
		});
		#end
	}

	// Event Handlers
	private #if !flash override #end function __enterFrame(deltaTime:Float):Void
	{
		currentTime += deltaTime;
		times.push(currentTime);

		while (times[0] < currentTime - 1000)
		{
			times.shift();
		}

		// u h
		text = "";
		if (displayFps)
		{
			if (Math.isNaN(FlxG.updateFramerate))
				currentFPS = Math.round((times.length + cacheCount) / 2);
			else
				currentFPS = FlxG.updateFramerate;
			text += "FPS: " + currentFPS + "\n";
			cacheCount = times.length;
		}
		if (displayExtra)
			text += "State: " + Main.mainClassState + "\n";
		if (displayMemory)
		{
			memoryUsage = Math.round(System.totalMemory / (1e+6)); // division to convey the memory usage in megabytes
			text += "Memory: " + memoryUsage + " mb";
			// mb stands for my bad
		}
	}

	// be able to call framerates later on
	public static function getFrames():Float
	{
		return currentFPS;
	}

	// and also the amount of memory being used (so you dont destroy someones computer)
	public static function getMemoryUsage():Float
	{
		return memoryUsage;
	}

	public static function updateDisplayInfo(shouldDisplayFps:Bool, shouldDisplayExtra:Bool, shouldDisplayMemory:Bool)
	{
		displayFps = shouldDisplayFps;
		displayExtra = shouldDisplayExtra;
		displayMemory = shouldDisplayMemory;
	}
}
