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

		// call the note's animations
		if (!PlayState.isPixel)
		{
			frames = Paths.getSparrowAtlas('notes/noteSplashes');
			// get a random value for the note splash type
			animation.addByPrefix('anim1', 'note impact 1 ' + UIBabyArrow.getColorFromNumber(noteData), 24, false);
			animation.addByPrefix('anim2', 'note impact 2 ' + UIBabyArrow.getColorFromNumber(noteData), 24, false);
			animation.play('anim1');

			addOffset('anim1', 16, 16);
			addOffset('anim2', 16, 16);
		}
		else
		{
			loadGraphic(Paths.image('notes/splash-pixel'), true, 34, 34);

			animation.add('anim1', [noteData, 4 + noteData, 8 + noteData, 12 + noteData], 24, false);
			animation.add('anim2', [16 + noteData, 20 + noteData, 24 + noteData, 28 + noteData], 24, false);
			animation.play('anim1');

			addOffset('anim1', -120, -120);
			addOffset('anim2', -120, -120);

			setGraphicSize(Std.int(width * PlayState.daPixelZoom));
		}

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
