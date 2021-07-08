package gameFolder.meta.state;

import flixel.FlxSprite;
import gameFolder.meta.MusicBeat.MusicBeatState;

class OptionsMenuState extends MusicBeatState
{

	var optionShit:Array<String> = ['story mode', 'freeplay', 'options'];
	
	override public function create():Void
	{
		// call the options menu
		var bg = new FlxSprite(-85);
		bg.loadGraphic(Paths.image('menuBG'));
		bg.scrollFactor.x = 0;
		bg.scrollFactor.y = 0.18;
		bg.setGraphicSize(Std.int(bg.width * 1.1));
		bg.updateHitbox();
		bg.screenCenter();
		bg.antialiasing = true;
		add(bg);
	}
}
