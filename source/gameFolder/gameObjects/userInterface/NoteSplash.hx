package gameFolder.gameObjects.userInterface;

import flixel.FlxG;
import flixel.FlxSprite;
import gameFolder.gameObjects.Note;

/**
	Create the note splashes in week 7 whenever you get a sick!
**/
class NoteSplash extends FlxSprite
{
	//
	public function new(noteData:Int)
	{
		super();
		// call the note's animations
		frames = Paths.getSparrowAtlas('notes/noteSplashes');
		// get a random value for the note splash type
		animation.addByPrefix('anim1', 'note impact 1 ' + UIBabyArrow.getColorFromNumber(noteData), 24, false);
		animation.addByPrefix('anim2', 'note impact 2 ' + UIBabyArrow.getColorFromNumber(noteData), 24, false);
		animation.play('anim1');
		visible = false;

		alpha = 0.6;
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		// kill the note splash if it's done
		if (animation.finished)
		{
			if (visible)
				visible = false;
		}
		//
	}

	public function playAnimation(animPlay:String)
	{
		visible = true;
		animation.play(animPlay);
	}
}
