package gameFolder.gameObjects.userInterface.menu;

import flixel.FlxSprite;

using StringTools;

class Checkmark extends FlxSprite
{
	public var animOffsets:Map<String, Array<Dynamic>>;

	public function new(x:Float, y:Float)
	{
		super(x, y);
		animOffsets = new Map<String, Array<Dynamic>>();
	}

	override public function update(elapsed:Float)
	{
		if ((animation.finished) && (animation.curAnim.name == 'true'))
			playAnim('true finished');
		if ((animation.finished) && (animation.curAnim.name == 'false'))
			playAnim('false finished');

		super.update(elapsed);
	}

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
}
