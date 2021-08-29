package gameFolder.gameObjects.userInterface;

import flixel.group.FlxSpriteGroup;

class DialogueBox extends FlxSpriteGroup
{
	///
	/*
		Epic Dialogue Documentation!

		nothing yet :P
	 */
	public static function createDialogue(thisDialogue:Array<String>):DialogueBox
	{
		//
		var newDialogue = new DialogueBox(false, thisDialogue);
		return newDialogue;
	}

	public function new(?talkingRight:Bool = false, ?dialogueList:Array<String>)
	{
		super();
	}
}
