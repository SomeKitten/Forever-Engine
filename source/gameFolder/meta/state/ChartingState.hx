package gameFolder.meta.state;

import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.addons.display.FlxGridOverlay;
import flixel.addons.ui.FlxInputText;
import flixel.addons.ui.FlxUI9SliceSprite;
import flixel.addons.ui.FlxUI;
import flixel.addons.ui.FlxUICheckBox;
import flixel.addons.ui.FlxUIDropDownMenu;
import flixel.addons.ui.FlxUIInputText;
import flixel.addons.ui.FlxUINumericStepper;
import flixel.addons.ui.FlxUITabMenu;
import flixel.addons.ui.FlxUITooltip.FlxUITooltipStyle;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.group.FlxGroup;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.system.FlxSound;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.ui.FlxButton;
import flixel.ui.FlxSpriteButton;
import flixel.util.FlxColor;
import gameFolder.gameObjects.*;
import gameFolder.gameObjects.userInterface.*;
import gameFolder.meta.Conductor.BPMChangeEvent;
import gameFolder.meta.MusicBeat.MusicBeatState;
import gameFolder.meta.data.*;
import gameFolder.meta.data.Section.SwagSection;
import gameFolder.meta.data.Song.SwagSong;
import haxe.Json;
import lime.utils.Assets;
import openfl.events.Event;
import openfl.events.IOErrorEvent;
import openfl.media.Sound;
import openfl.net.FileReference;
import openfl.utils.ByteArray;

using StringTools;

/**
	As the name implies, this is the class where all of the charting state stuff happens, so when you press 7 the game
	state switches to this one, where you get to chart songs and such. I'm planning on overhauling this entirely in the future
	and making it both more practical and more user friendly.
**/
class ChartingState extends MusicBeatState
{
	private var curSection:Int = 0;
	private var chartType:String;

	private var psuedoCameraY:Float = 0;

	private var leftIcon:HealthIcon;
	private var rightIcon:HealthIcon;

	private var gridSize = 40;
	private var keysTotal = 8;

	private var dummyArrow:FlxSprite;

	var _song:SwagSong;

	override public function create():Void
	{
		//
		chartType = 'FNF';

		if (PlayState.SONG != null)
			_song = PlayState.SONG;
		else
			_song = Song.loadFromJson('test', 'test');

		PlayState.resetMusic();
		if (FlxG.sound.music != null)
		{
			FlxG.sound.music.stop();
			// vocals.stop();
		}

		// generate the chart itself
		generateChart();

		// generate ui elements and stuffs
		leftIcon = new HealthIcon(_song.player2);
		rightIcon = new HealthIcon(_song.player1);
		leftIcon.setGraphicSize(Std.int(leftIcon.width / 2));
		rightIcon.setGraphicSize(Std.int(rightIcon.width / 2));
		leftIcon.screenCenter(X);
		rightIcon.screenCenter(X);

		leftIcon.x -= gridSize * 2;
		rightIcon.x += gridSize * 2;

		add(leftIcon);
		add(rightIcon);

		// cursor
		dummyArrow = new FlxSprite().makeGraphic(gridSize, gridSize);
		add(dummyArrow);

		//
		Conductor.changeBPM(_song.bpm);
		Conductor.mapBPMChanges(_song);
	}

	private var sectionsMax:Int = 0;
	private var sectionsAll:FlxTypedGroup<FlxSprite>;

	private function generateChart()
	{
		// generate all sections
		sectionsAll = new FlxTypedGroup<FlxSprite>();
		for (section in _song.notes)
		{
			trace('generating section $section');
			var curGridSprite:FlxSprite = FlxGridOverlay.create(gridSize, gridSize, gridSize * keysTotal, gridSize * 16, true);
			curGridSprite.screenCenter(X);
			curGridSprite.y += ((gridSize * 16) * sectionsMax);

			sectionsAll.add(curGridSprite);
			sectionsMax++;
		}
		add(sectionsAll);
	}

	override public function update(elapsed:Float)
	{
		/* 
			if (FlxG.mouse.x > gridBG.x
				&& FlxG.mouse.x < gridBG.x + gridBG.width
				&& FlxG.mouse.y > gridBG.y
				&& FlxG.mouse.y < gridBG.y + (GRID_SIZE * _song.notes[curSection].lengthInSteps))
			{
				dummyArrow.x = Math.floor(FlxG.mouse.x / GRID_SIZE) * GRID_SIZE;
				if (FlxG.keys.pressed.SHIFT)
					dummyArrow.y = FlxG.mouse.y;
				else
					dummyArrow.y = Math.floor(FlxG.mouse.y / GRID_SIZE) * GRID_SIZE;
			}
		 */
		super.update(elapsed);
	}
}
