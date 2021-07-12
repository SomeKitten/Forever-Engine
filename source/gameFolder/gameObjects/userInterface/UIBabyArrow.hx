package gameFolder.gameObjects.userInterface;

import flixel.FlxG;
import flixel.FlxSprite;
import gameFolder.meta.state.PlayState;

using StringTools;

/*
	import flixel.FlxG;

	import flixel.animation.FlxBaseAnimation;
	import flixel.graphics.frames.FlxAtlasFrames;
	import flixel.tweens.FlxEase;
	import flixel.tweens.FlxTween; 
 */
class UIBabyArrow extends FlxSprite
{
	/*  Oh hey, just gonna port this code from the previous Skater engine 
		(depending on the release of this you might not have it cus I might rewrite skater to use this engine instead)
		It's basically just code from the game itself but
		it's in a separate class and I also added the ability to set offsets for the arrows.

		uh hey you're cute ;)
	 */
	public var animOffsets:Map<String, Array<Dynamic>>;
	public var babyArrowType:Int = 0;
	public var canFinishAnimation:Bool = true;

	public var initialX:Int;
	public var initialY:Int;

	public function new(x:Float, y:Float, ?babyArrowType:Int = 0)
	{
		// this extension is just going to rely a lot on preexisting code as I wanna try to write an extension before I do options and stuff
		super(x, y);
		animOffsets = new Map<String, Array<Dynamic>>();

		this.babyArrowType = babyArrowType;

		if (PlayState.isPixel)
		{
			// look man you know me I fucking hate repeating code
			// not even just a cleanliness thing it's just so annoying to tweak if something goes wrong like
			// genuinely more programmers should make their code more modular
			loadGraphic(Paths.image('notes/arrows-pixels'), true, 17, 17);
			animation.add('static', [babyArrowType]);
			animation.add('pressed', [4 + babyArrowType, 8 + babyArrowType], 12, false);
			animation.add('confirm', [12 + babyArrowType, 16 + babyArrowType], 24, false);

			setGraphicSize(Std.int(width * PlayState.daPixelZoom));
			updateHitbox();
			antialiasing = false;
		}
		else
		{
			// probably gonna revise this and make it possible to add other arrow types but for now it's just pixel and normal
			var stringSect:String = '';
			// call arrow type I think
			stringSect = getArrowFromNumber(babyArrowType);

			var framesArgument:String = "NOTE_assets";
			frames = Paths.getSparrowAtlas('notes/$framesArgument');

			// idk if this works or not lmao
			animation.addByPrefix('static', 'arrow' + stringSect.toUpperCase());
			animation.addByPrefix('pressed', stringSect + ' press', 24, false);
			animation.addByPrefix('confirm', stringSect + ' confirm', 24, false);

			antialiasing = true;
			setGraphicSize(Std.int(width * 0.7));
		}

		// set little offsets per note!
		// so these had a little problem honestly and they make me wanna off(set) myself so the middle notes basically
		// have slightly different offsets than the side notes (which have the same offset)

		var offsetMiddleX = 0;
		var offsetMiddleY = 0;
		if (babyArrowType > 0 && babyArrowType < 3)
		{
			offsetMiddleX = 2;
			offsetMiddleY = 2;
			if (babyArrowType == 1)
			{
				offsetMiddleX -= 1;
				offsetMiddleY += 2;
			}
		}

		// yeah this is terrible code but like
		// this is only gonna run once it's FINE

		// upside of this is it only has to run once even if it's trash, the game itself has to run this code with the arrows like
		// idk every time the confirm arrow is shown which is painful
		if (!PlayState.isPixel)
		{
			addOffset('static');
			addOffset('pressed', -2, -2);
			addOffset('confirm', 36 + offsetMiddleX, 36 + offsetMiddleY);
		}
		else
		{
			addOffset('static', -75, -75);
			addOffset('pressed', -75, -75);
			addOffset('confirm', -75, -75);
		}

		updateHitbox();
		scrollFactor.set();
	}

	// literally just character code
	public function playAnim(AnimName:String, Force:Bool = false, Reversed:Bool = false, Frame:Int = 0):Void
	{
		animation.play(AnimName, Force, Reversed, Frame);
		updateHitbox();

		var daOffset = animOffsets.get(AnimName);
		if (animOffsets.exists(AnimName))
		{
			offset.set(daOffset[0], daOffset[1]);
		}
		else
			offset.set(0, 0);
	}

	public function addOffset(name:String, x:Float = 0, y:Float = 0)
	{
		animOffsets[name] = [x, y];
	}

	public static function getArrowFromNumber(numb:Int)
	{
		// yeah no I'm not writing the same shit 4 times over
		// take it or leave it my guy
		var stringSect:String = '';
		switch (numb)
		{
			case(0):
				stringSect = 'left';
			case(1):
				stringSect = 'down';
			case(2):
				stringSect = 'up';
			case(3):
				stringSect = 'right';
		}
		return stringSect;
		//
	}

	// that last function was so useful I gave it a sequel
	public static function getColorFromNumber(numb:Int)
	{
		var stringSect:String = '';
		switch (numb)
		{
			case(0):
				stringSect = 'purple';
			case(1):
				stringSect = 'blue';
			case(2):
				stringSect = 'green';
			case(3):
				stringSect = 'red';
		}
		return stringSect;
		//
	}
}
