package gameFolder.meta.state.charting;

import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.addons.display.FlxBackdrop;
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
import flixel.util.FlxGradient;
import gameFolder.gameObjects.*;
import gameFolder.gameObjects.userInterface.*;
import gameFolder.meta.MusicBeat.MusicBeatState;
import gameFolder.meta.data.*;
import gameFolder.meta.data.Conductor.BPMChangeEvent;
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

	var strumLine:FlxSprite;

	var camHUD:FlxCamera;
	var camGame:FlxCamera;
	var strumLineCam:FlxObject;

	var songMusic:FlxSound;
	var vocals:FlxSound;

	private var keysTotal = 8;

	private var dummyArrow:FlxSprite;
	private var curRenderedNotes:FlxTypedGroup<Note>;
	private var curRenderedSustains:FlxTypedGroup<FlxSprite>;

	var _song:SwagSong;

	override public function create():Void
	{
		//
		chartType = 'FNF';

		if (PlayState.SONG != null)
			_song = PlayState.SONG;
		else
			_song = Song.loadFromJson('dadbattle-hard', 'dadbattle');

		PlayState.resetMusic();
		if (FlxG.sound.music != null)
		{
			FlxG.sound.music.stop();
			// vocals.stop();
		}

		// generate the chart itself
		loadSong(_song.song);
		generateBackground();
		generateChart();

		// epic strum line
		strumLine = new FlxSprite(0, 0).makeGraphic(Std.int(FlxG.width / 2), 4);
		strumLine.screenCenter(X);
		add(strumLine);

		strumLineCam = new FlxObject(0, 0);
		strumLineCam.screenCenter(X);

		// cursor
		dummyArrow = new FlxSprite().makeGraphic(gridSize, gridSize);
		add(dummyArrow);

		// code from the playstate so I can separate the camera and hud
		camGame = new FlxCamera();
		camHUD = new FlxCamera();
		camHUD.bgColor.alpha = 0;

		FlxG.cameras.reset(camGame);
		FlxG.cameras.add(camHUD);
		FlxCamera.defaultCameras = [camGame];

		//
		Conductor.changeBPM(_song.bpm);
		Conductor.mapBPMChanges(_song);

		FlxG.camera.follow(strumLineCam);
		super.create();
	}

	function loadSong(daSong:String):Void
	{
		if (songMusic != null)
			songMusic.stop();

		if (vocals != null)
			vocals.stop();

		songMusic = new FlxSound().loadEmbedded(Paths.inst(daSong));
		vocals = new FlxSound().loadEmbedded(Paths.voices(daSong));
		FlxG.sound.list.add(songMusic);
		FlxG.sound.list.add(vocals);

		songMusic.pause();
		vocals.pause();

		songMusic.onComplete = function()
		{
			vocals.pause();
			songMusic.pause();
		};
		//
	}

	override public function update(elapsed:Float)
	{
		var beatTime:Float = ((Conductor.songPosition / 1000) * (Conductor.bpm / 60));
		// coolGrid.y = (750 * (Math.cos((beatTime / 5) * Math.PI)));
		// coolGrid.x = Conductor.songPosition;

		super.update(elapsed);
	}

	var coolGrid:FlxBackdrop;
	var coolGradient:FlxSprite;

	private function generateBackground()
	{
		coolGrid = new FlxBackdrop(null, 1, 1, true, true, 1, 1);
		coolGrid.loadGraphic(Paths.image('UI/forever/chart editor/grid'));
		coolGrid.alpha = (32 / 255);
		add(coolGrid);

		// gradient
		coolGradient = FlxGradient.createGradientFlxSprite(FlxG.width, FlxG.height,
			FlxColor.gradient(FlxColor.fromRGB(188, 158, 255, 200), FlxColor.fromRGB(80, 12, 108, 255), 16));
		coolGradient.alpha = (32 / 255);
		add(coolGradient);
	}

	var gridSize:Int = 51;
	var horizontalSize:Int = 8;
	var verticalSize:Int = 16;

	private var sectionsMax:Int = 0;
	private var sectionsAll:FlxTypedGroup<FlxSprite>;

	private function generateChart()
	{
		// generate all sections
		sectionsAll = new FlxTypedGroup<FlxSprite>();
		curRenderedNotes = new FlxTypedGroup<Note>();
		curRenderedSustains = new FlxTypedGroup<FlxSprite>();

		for (section in _song.notes)
		{
			// trace('generating section $section');
			var curGridSprite:FlxSprite = FlxGridOverlay.create(gridSize, gridSize, gridSize * horizontalSize, gridSize * verticalSize, true);
			curGridSprite.screenCenter(X);
			curGridSprite.y += ((gridSize * 16) * sectionsMax);

			sectionsAll.add(curGridSprite);
			regenerateSection(sectionsMax);

			removeAllNotes();

			// generate arrows lol
			// var sectionInfo:Array<Dynamic> = _song.notes[sectionsMax].sectionNotes;
			for (i in _song.notes[sectionsMax].sectionNotes)
			{
				// note stuffs
				var daNoteInfo = i[1];
				var daStrumTime = i[0];
				var daSus = i[2];
				var daNoteAlt = 0;

				if (i.length > 2)
					daNoteAlt = i[3];

				var note:Note = new Note(daStrumTime, daNoteInfo % 4, daNoteAlt);
				note.sustainLength = daSus;
				note.setGraphicSize(gridSize, gridSize);
				note.updateHitbox();
				note.x = Math.floor(daNoteInfo * gridSize);
				note.y = 0;
				// note.y = Math.floor(((daStrumTime - sectionStartTime(sectionsMax)) % (Conductor.stepCrochet * _song.notes[curSection].lengthInSteps)));

				curRenderedNotes.add(note);

				if (daSus > 0)
				{
					var sustainVis:FlxSprite = new FlxSprite(note.x + (gridSize / 2),
						note.y + gridSize).makeGraphic(8, Math.floor(FlxMath.remapToRange(daSus, 0, Conductor.stepCrochet * 16, 0, gridSize * 16)));
					curRenderedSustains.add(sustainVis);
				}
			}
			//

			sectionsMax++;
		}
		add(sectionsAll);
		add(curRenderedNotes);
		add(curRenderedSustains);
	}

	private function regenerateSection(section:Int)
	{
		// this will be used to regenerate a box that shows what section the camera is focused on
	}

	private function removeAllNotes()
	{
		while (curRenderedNotes.members.length > 0)
		{
			curRenderedNotes.remove(curRenderedNotes.members[0], true);
		}

		while (curRenderedSustains.members.length > 0)
		{
			curRenderedSustains.remove(curRenderedSustains.members[0], true);
		}
	}
	/*
		private function generateGrid()
		{


			// temp function for now
			var noteGrid:FlxSprite = FlxGridOverlay.create(gridSize, gridSize, gridSize * horizontalSize, gridSize * verticalSize, true, FlxColor.WHITE,
				FlxColor.BLACK);
			noteGrid.alpha = (26 / 255);
			add(noteGrid);
			noteGrid.screenCenter();
		}
	 */
}
