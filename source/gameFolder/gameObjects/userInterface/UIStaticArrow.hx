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
class UIStaticArrow extends FlxSprite
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

	public var xTo:Float;
	public var yTo:Float;
	public var angleTo:Float;

	public var setAlpha:Float = 0.8;

	public function new(x:Float, y:Float, ?babyArrowType:Int = 0)
	{
		// this extension is just going to rely a lot on preexisting code as I wanna try to write an extension before I do options and stuff
		super(x, y);
		animOffsets = new Map<String, Array<Dynamic>>();

		this.babyArrowType = babyArrowType;

		updateHitbox();
		scrollFactor.set();
	}

	// literally just character code
	public function playAnim(AnimName:String, Force:Bool = false, Reversed:Bool = false, Frame:Int = 0):Void
	{
		if (AnimName == 'confirm')
			alpha = 1;
		else
			alpha = setAlpha;

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
