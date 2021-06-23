package gameFolder.meta.state;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.text.FlxText;
import gameFolder.meta.MusicBeat.MusicBeatState;

using StringTools;

class TitleState extends MusicBeatState
{ // remember to change later
	/*
		// holy shit this is like hello world but slightly worse?
		// this is just test code don't mind it.
		var stringText:String = "woah its a string \n no way anyways i \n gotta see if it loads";
		var menuText:FlxText;

		override public function create()
		{
			super.create();

			menuText = new FlxText(0, 0, 0, stringText, 64);
			// menuText.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, RIGHT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
			menuText.screenCenter();
			add(menuText);
		}

		override public function update(elapsed:Float)
		{
			super.update(elapsed);
			menuText.x += 1;
		}
		// */
}
