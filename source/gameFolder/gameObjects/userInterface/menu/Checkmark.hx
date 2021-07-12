package gameFolder.gameObjects.userInterface.menu;

import flixel.FlxSprite;

class Checkmark extends FlxSprite
{
	public var animOffsets:Map<String, Array<Dynamic>>;

	public function new(x:Float, y:Float)
	{
		super();
		animOffsets = new Map<String, Array<Dynamic>>();

		frames = Paths.getSparrowAtlas('UI/checkboxThingie');
		animation.addByPrefix('false', 'Check Box unselected', 24, true);
		animation.addByPrefix('true finished', 'Check Box Selected Static', 24, true);
		animation.addByPrefix('true', 'Check Box selecting animation', 24, false);
		setGraphicSize(Std.int(width * 0.7));
		updateHitbox();

		addOffset('true finished', 17, 37);
		addOffset('true', 25, 57);
		addOffset('false', 2, -30);

		antialiasing = true;
	}

	override public function update(elapsed:Float)
	{
		if ((animation.finished) && (animation.curAnim.name == 'true'))
			playAnim('true finished');

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
