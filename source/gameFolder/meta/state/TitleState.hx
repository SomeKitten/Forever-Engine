package gameFolder.meta.state;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.addons.transition.FlxTransitionSprite.GraphicTransTileDiamond;
import flixel.addons.transition.FlxTransitionableState;
import flixel.addons.transition.TransitionData;
import flixel.graphics.FlxGraphic;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import gameFolder.meta.MusicBeat.MusicBeatState;
import openfl.Assets;

using StringTools;

class TitleState extends MusicBeatState
{
	//
	var curWacky:Array<String> = [];
	var initialised:Bool = false; // initialisation to make sure things work

	override public function create():Void
	{
		super.create();

		// text string that plays at the start of the game much like the original engine lol
		curWacky = FlxG.random.getObject(getIntroTextShit());

		new FlxTimer().start(1, function(tmr:FlxTimer)
		{
			startIntro();
		});
	}

	function startIntro()
	{
		// check if the game isn't initialised, if it isn't start doing shit about it!
		if (!initialised)
		{
			//
			FlxG.sound.playMusic(Paths.music('freakyMenu'), 0);
			FlxG.sound.music.fadeIn(5, 0, 0.7);
		}
		Conductor.changeBPM(102);
		persistentUpdate = true;

		var bg:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		add(bg);
	}

	function getIntroTextShit():Array<Array<String>>
	{
		var fullText:String = Assets.getText(Paths.txt('introText'));

		var firstArray:Array<String> = fullText.split('\n');
		var swagGoodArray:Array<Array<String>> = [];

		for (i in firstArray)
		{
			swagGoodArray.push(i.split('--'));
		}

		return swagGoodArray;
	}

	override function update(elapsed:Float)
	{
		//
	}

	override function beatHit()
	{
		super.beatHit();

		// end it on a different line for the sake of clarity
		if (curBeat == 16)
			skipIntro();
	}

	function skipIntro()
	{
		//
	}
}
