package gameFolder.meta.data.dependency;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.transition.Transition;
import flixel.addons.transition.TransitionData;

/**
 *
 * Transition overrides
 * @author HelloSammu
 *
**/
class FNFTransition extends Transition
{
	var back:FlxSprite;
	var camStarted:Bool = false;

	public override function new(data:TransitionData)
	{
		// Inherit from super
		super(data);

		// Take note of background fade
		back = _effect.members[0];
	}

	public override function update(gameTime:Float)
	{
		// Since the transition can start before other cameras are made, we need to make it after the start!
		if (!camStarted)
		{
			var camList = FlxG.cameras.list;
			camera = camList[camList.length - 1];
			back.camera = camera;
		}

		super.update(gameTime);
	}
}
