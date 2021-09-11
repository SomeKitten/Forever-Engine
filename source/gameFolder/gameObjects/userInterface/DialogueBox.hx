package gameFolder.gameObjects.userInterface;

import flixel.FlxBasic;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.math.FlxPoint;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import gameFolder.meta.data.dependency.FNFSprite;
import gameFolder.meta.data.font.Alphabet;

typedef PortraitDataDef =
{
	var name:String;
	var expressions:Array<String>;
	var position:Null<Dynamic>;
	var scale:Null<Int>;
	var antialiasing:Null<Bool>;
	var flipX:Null<Bool>;
}

typedef DialogueDataDef =
{
	var events:Array<Array<String>>;
	var portrait:String;
	var expression:String;
	var text:Null<String>;
	var boxState:Null<String>;
}

typedef BoxDataDef =
{
	var position:Null<Array<Int>>;
	var textPos:Null<Array<Int>>;
	var scale:Null<Float>;
	var antialiasing:Null<Bool>;
	var singleFrame:Null<Bool>;
	var doFlip:Null<Bool>;
	var states:Null<Dynamic>;
}

typedef DialogueFileDataDef =
{
	var box:String;
	var boxState:Null<String>;
	var dialogue:Array<DialogueDataDef>;
}

class DialogueBox extends FlxSpriteGroup
{
	///
	/*
		Epic Dialogue Documentation!

		nothing yet :P
	 */
	var box:FNFSprite;
	var bgFade:FlxSprite;
	var portrait:FNFSprite;
	var text:FlxText;
	var alphabetText:Alphabet;

	var dialogueData:DialogueFileDataDef;
	var portraitData:PortraitDataDef;
	var boxData:BoxDataDef;

	var curPage:Int = 0;
	var curCharacter:String;
	var curBoxState:String;

	public var whenDaFinish:Void->Void;

	public static function createDialogue(thisDialogue:String):DialogueBox
	{
		//
		var newDialogue = new DialogueBox(false, thisDialogue);
		return newDialogue;
	}

	public function new(?talkingRight:Bool = false, ?daDialogue:String)
	{
		super();

		trace("start");

		// get dialog data from dialogue.json
		dialogueData = haxe.Json.parse(daDialogue);

		dialogDataCheck();

		// background fade
		bgFade = new FlxSprite(-200, -200).makeGraphic(Std.int(FlxG.width * 1.3), Std.int(FlxG.height * 1.3), FlxColor.BLACK);
		bgFade.scrollFactor.set();
		bgFade.alpha = 0;
		add(bgFade);

		// add the dialog box
		box = new FNFSprite(0, 370);

		// cur portrait
		portrait = new FNFSprite(800, 160);

		alphabetText = new Alphabet(100, 320, "cool", true, true, 0.7);

		// text
		text = new FlxText(100, 480, 1000, "", 35);
		text.color = FlxColor.BLACK;
		text.visible = false;

		updateDialog(true);

		// add stuff
		add(portrait);
		add(box);
		add(text);

		add(alphabetText);
	}

	function updateDialog(force:Bool = false)
	{
		// set current portrait
		updateTextBox(force);
		updatePortrait(force);

		// text update
		var curPageData = dialogueData.dialogue[curPage];

		if (curPageData.text == null)
			curPageData.text = "lol u need text for dialog";

		text.text = curPageData.text;
		alphabetText.restartText(curPageData.text, true);
	}

	function updateTextBox(force:Bool = false)
	{
		var curBox = dialogueData.box;
		var newState = dialogueData.dialogue[curPage].boxState;

		if (force && newState == null)
			newState = dialogueData.boxState;

		if (newState == null)
			return;

		if (curBoxState != newState || force)
		{
			curBoxState = newState;

			// get the path to the json
			var boxJson = Paths.file('images/dialogue/boxes/$curBox/$curBox.json');

			// load the json and sprite
			boxData = haxe.Json.parse(sys.io.File.getContent(boxJson));
			box.frames = Paths.getSparrowAtlas('dialogue/boxes/$curBox/$curBox');

			// get the states sectioon
			var curStateData = Reflect.field(boxData.states, curBoxState);

			if (curStateData == null)
				return;

			// default and open animations
			var defaultAnim:Array<Dynamic> = Reflect.field(curStateData, "default");
			var openAnim:Array<Dynamic> = Reflect.field(curStateData, "open");

			// make sure theres atleast a offset if things are null
			if (defaultAnim[1] == null)
				defaultAnim[1] = [0, 0];

			if (openAnim[1] == null)
				openAnim[1] = [0, 0];

			// check if single frame
			if (boxData.singleFrame == null)
				boxData.singleFrame = false;

			// do flip
			if (boxData.doFlip == null)
				boxData.doFlip = true;

			// add the animations
			box.animation.addByPrefix('normal', defaultAnim[0], 24, true);
			box.addOffset('normal', defaultAnim[1][0], defaultAnim[1][1]);

			box.animation.addByPrefix('normalOpen', openAnim[0], 24, false);
			box.addOffset('normalOpen', openAnim[1][0], openAnim[1][1]);

			// if the box doesnt have a position set it to 0 0
			if (boxData.position == null)
				boxData.position = [0, 0];

			box.x = boxData.position[0];
			box.y = boxData.position[1];

			// other stuff
			if (boxData.scale == null)
				boxData.scale = 1;

			if (boxData.antialiasing == null)
				boxData.antialiasing = true;

			box.scale = new FlxPoint(boxData.scale, boxData.scale);
			box.antialiasing = boxData.antialiasing;

			if (boxData.textPos != null)
			{
				text.x = boxData.textPos[0];
				text.y = boxData.textPos[1];
			}

			box.playAnim('normalOpen');
		}
	}

	function updatePortrait(force:Bool = false)
	{
		var newChar = dialogueData.dialogue[curPage].portrait;

		if (newChar == null)
			return;

		if (curCharacter != newChar || force)
		{
			// made the curCharacter the new character
			curCharacter = newChar;
			var portraitJson = Paths.file('images/dialogue/portraits/$curCharacter/$curCharacter.json');

			// load the json file
			if (sys.FileSystem.exists(portraitJson))
			{
				portraitData = haxe.Json.parse(sys.io.File.getContent(portraitJson));
				portrait.frames = Paths.getSparrowAtlas('dialogue/portraits/$curCharacter/$curCharacter');
			}

			// loop through the expressions and add the to the list of expressions
			for (n in Reflect.fields(portraitData.expressions))
			{
				var curAnim = Reflect.field(portraitData.expressions, n);
				var animName = n;

				portrait.animation.addByPrefix(animName, curAnim, 24, false);
			}

			// check for null values
			if (portraitData.scale == null)
				portraitData.scale = 1;

			if (portraitData.antialiasing == null)
				portraitData.antialiasing = true;

			// change some smaller values
			portrait.scale = new FlxPoint(portraitData.scale, portraitData.scale);
			portrait.antialiasing = portraitData.antialiasing;

			// position and flip stuff
			// honestly
			var newX = 850;
			var newY = 160;
			var enterX = -20;
			var newFlip = false;

			if (Std.is(portraitData.position, String))
			{
				switch (portraitData.position)
				{
					case "left":
						newX = 10;
						enterX = -enterX;
						newFlip = true;
					case "middle":
						newX = 400;
				}
			}
			else if (Std.is(portraitData.position, Array))
			{
				newX = portraitData.position[0];
				newY = portraitData.position[1];
			}

			portrait.x = newX - enterX;
			portrait.y = newY;

			// flip
			if (portraitData.flipX != null)
				newFlip = portraitData.flipX;

			portrait.flipX = newFlip;

			// flip check
			if (boxData.doFlip == true)
				box.flipX = newFlip;

			// this causes problems, and i know exactly what the problem is... i just cant fix it
			// basically i need to get rid of the last tween before doing a new one, or else the portraits slide around all over the place
			// ngl its kinda funny
			FlxTween.tween(portrait, {x: newX + enterX}, 0.2, {ease: FlxEase.quadInOut});
		}

		// change expressions
		var curExpression = dialogueData.dialogue[curPage].expression;
		portrait.animation.play(curExpression);
	}

	function closeDialog()
	{
		whenDaFinish();
		kill();
	}

	function dialogDataCheck()
	{
		var tisOkay = true;

		if (dialogueData.box == null)
			tisOkay = false;
		if (dialogueData.dialogue == null)
			tisOkay = false;

		if (!tisOkay)
			closeDialog();
	}

	override function update(elapsed:Float)
	{
		if (box.animation.finished)
		{
			if (boxData.singleFrame != true)
				box.playAnim('normal');

			text.visible = true;
		}

		bgFade.alpha += 0.02;
		if (bgFade.alpha > 0.6)
			bgFade.alpha = 0.6;

		if (FlxG.keys.justPressed.ENTER)
		{
			FlxG.sound.play(Paths.sound('cancelMenu'));

			curPage += 1;

			if (curPage == dialogueData.dialogue.length)
				closeDialog()
			else
				updateDialog();
		}

		super.update(elapsed);
	}
}
