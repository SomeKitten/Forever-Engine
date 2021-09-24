package gameFolder.meta.state.charting;

import flixel.FlxBasic;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.addons.display.FlxBackdrop;
import flixel.addons.display.FlxGridOverlay;
import flixel.addons.display.FlxTiledSprite;
import flixel.addons.display.shapes.FlxShapeBox;
import flixel.addons.ui.FlxInputText;
import flixel.addons.ui.FlxUI;
import flixel.addons.ui.FlxUICheckBox;
import flixel.addons.ui.FlxUIDropDownMenu;
import flixel.addons.ui.FlxUIInputText;
import flixel.addons.ui.FlxUINumericStepper;
import flixel.addons.ui.FlxUITabMenu;
import flixel.group.FlxGroup;
import flixel.group.FlxSpriteGroup;
import flixel.math.FlxMath;
import flixel.system.FlxSound;
import flixel.text.FlxText;
import flixel.ui.FlxButton;
import flixel.util.FlxColor;
import flixel.util.FlxGradient;
import gameFolder.gameObjects.*;
import gameFolder.gameObjects.userInterface.*;
import gameFolder.gameObjects.userInterface.notes.*;
import gameFolder.gameObjects.userInterface.notes.Strumline.UIStaticArrow;
import gameFolder.meta.MusicBeat.MusicBeatState;
import gameFolder.meta.data.*;
import gameFolder.meta.data.Section.SwagSection;
import gameFolder.meta.data.Song.SwagSong;
import gameFolder.meta.data.dependency.Discord;
import gameFolder.meta.subState.charting.*;
import haxe.Json;
import haxe.io.Bytes;
import lime.media.AudioBuffer;
import openfl.events.Event;
import openfl.events.IOErrorEvent;
import openfl.geom.ColorTransform;
import openfl.geom.Rectangle;
import openfl.media.Sound;
import openfl.net.FileReference;
import openfl.utils.ByteArray;

using StringTools;

#if !html5
import sys.thread.Thread;
#end

/**
	As the name implies, this is the class where all of the charting state stuff happens, so when you press 7 the game
	state switches to this one, where you get to chart songs and such. I'm planning on overhauling this entirely in the future
	and making it both more practical and more user friendly.
**/
class ChartingState extends MusicBeatState
{
	var _song:SwagSong;

	var songMusic:FlxSound;
	var vocals:FlxSound;
	private var keysTotal = 8;

	public static var songPosition:Float = 0;
	public static var curSong:SwagSong;

	public static var gridSize:Int = 50;

	override public function create()
	{
		//
		super.create();

		generateBackground();

		if (PlayState.SONG != null)
			_song = PlayState.SONG;
		else
			_song = Song.loadFromJson('test', 'test');

		loadSong(_song.song);
		Conductor.changeBPM(_song.bpm);
		Conductor.mapBPMChanges(_song);

		generateGrid();
	}

	var fullGrid:FlxTiledSprite;

	function generateGrid()
	{
		// create new sprite
		var base:FlxSprite = FlxGridOverlay.create(gridSize, gridSize, gridSize * 2, gridSize * 2, true, FlxColor.WHITE, FlxColor.BLACK);
		fullGrid = new FlxTiledSprite(null, gridSize * 8, gridSize * 32);
		// base graphic change data
		var newAlpha = (26 / 255);
		base.graphic.bitmap.colorTransform(base.graphic.bitmap.rect, new ColorTransform(1, 1, 1, newAlpha));
		fullGrid.loadGraphic(base.graphic);
		fullGrid.screenCenter(X);
		add(fullGrid);
	}

	function loadSong(daSong:String):Void
	{
		if (songMusic != null)
			songMusic.stop();

		if (vocals != null)
			vocals.stop();

		songMusic = new FlxSound().loadEmbedded(Sound.fromFile('./' + Paths.inst(daSong)), false, true);
		if (_song.needsVoices)
			vocals = new FlxSound().loadEmbedded(Sound.fromFile('./' + Paths.voices(daSong)), false, true);
		else
			vocals = new FlxSound();
		FlxG.sound.list.add(songMusic);
		FlxG.sound.list.add(vocals);

		songMusic.play();
		vocals.play();

		if (curSong == _song)
			songMusic.time = songPosition;
		curSong = _song;

		pauseMusic();

		songMusic.onComplete = function()
		{
			vocals.pause();
			songMusic.pause();
		};
		//
	}

	///*
	private function generateBackground()
	{
		var coolGrid = new FlxBackdrop(null, 1, 1, true, true, 1, 1);
		coolGrid.loadGraphic(Paths.image('UI/forever/base/chart editor/grid'));
		coolGrid.alpha = (32 / 255);
		add(coolGrid);

		// gradient
		var coolGradient = FlxGradient.createGradientFlxSprite(FlxG.width, FlxG.height,
			FlxColor.gradient(FlxColor.fromRGB(188, 158, 255, 200), FlxColor.fromRGB(80, 12, 108, 255), 16));
		coolGradient.alpha = (32 / 255);
		add(coolGradient);
	}

	function adjustSide(noteData:Int, sectionTemp:Int)
	{
		// return (_song.notes[sectionTemp].mustHitSection ? ((noteData + 4) % 8) : noteData);
	}

	function pauseMusic()
	{
		songMusic.time = Math.max(songMusic.time, 0);
		songMusic.time = Math.min(songMusic.time, songMusic.length);

		resyncVocals();
		songMusic.pause();
		vocals.pause();
	}

	function resyncVocals():Void
	{
		vocals.pause();

		songMusic.play();
		Conductor.songPosition = songMusic.time;
		vocals.time = Conductor.songPosition;
		vocals.play();
	}

	// */
}
