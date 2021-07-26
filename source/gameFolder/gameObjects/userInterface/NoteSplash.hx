package gameFolder.gameObjects.userInterface;

import flixel.FlxG;
import flixel.FlxSprite;
import gameFolder.gameObjects.Note;
import gameFolder.meta.state.PlayState;

/**
	Create the note splashes in week 7 whenever you get a sick!
**/
class NoteSplash extends FlxSprite
{
	public var animOffsets:Map<String, Array<Dynamic>>;

	//
	public function new(noteData:Int)
	{
		super();
		animOffsets = new Map<String, Array<Dynamic>>();

		visible = false;
		alpha = 0.6;
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		// kill the note splash if it's done
		if (animation.finished)
		{
			// set the splash to invisible
			if (visible)
				visible = false;
		}
		//
	}

	public function addOffset(name:String, x:Float = 0, y:Float = 0)
	{
		animOffsets[name] = [x, y];
	}

	public function playAnim(AnimName:String, Force:Bool = false, Reversed:Bool = false, Frame:Int = 0)
	{
		// make sure the animation is visible
		visible = true;
		// play the animation
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
}
