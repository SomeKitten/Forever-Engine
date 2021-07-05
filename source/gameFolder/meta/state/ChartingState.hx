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

	I DONT KNOW IF THIS IS PRACTICAL OR NOT SO IM REALLY SORRY I JUST WANTED TO MAKE THE CHART EDITOR MORE FUNCTIONAL
	IM SORRY IF THIS ENDS UP MAKING IT LAG OR UNUSEABLE FOR SOME PEOPLE
**/
class ChartingState extends MusicBeatState
{
	// oops! I guess I'm redoing the chart system lmao
	// set up variables
	public static var GRID_SIZE:Int = 40;
	public static var GRID_TOTAL_SIZE:Int;

	var dummyArrow:FlxSprite;
	var strumLine:FlxSprite;
	var playButton:FlxSprite;

	var _song:SwagSong;
	var gridBG:FlxSprite;
	var vocals:FlxSound;
	var blackBG:FlxSprite;

	var blackColor:FlxColor;

	var camHUD:FlxCamera;
	var camGame:FlxCamera;
	var strumLineCam:FlxObject;

	var hudTextInfo:FlxText;

	public var curSelectedNote:Array<Dynamic>;

	public static var curRenderedNotes:FlxTypedGroup<Note>;
	public static var curRenderedSustains:FlxTypedGroup<FlxSprite>;
	public static var renderTextTest:FlxTypedGroup<FlxText>; // THIS IS FOR TESTING

	public static var renderTestActive:Bool = false;

	// it is very unoptimised so I am only going to use it to check values
	var sectionGroup:FlxTypedGroup<FlxSprite>;

	var playingSong:Bool = false;
	var dividendY:Int = 8;

	var leftIcon:HealthIcon;
	var rightIcon:HealthIcon;

	var sectionsMax:Int;

	var scrolling:Bool = false;

	var hasPlayedSound:Array<Bool> = [];

	override function create()
	{
		if (PlayState.SONG != null)
			_song = PlayState.SONG;
		else
		{
			_song = {
				song: 'Test',
				notes: [],
				bpm: 150,
				needsVoices: true,
				player1: 'bf',
				player2: 'dad',
				speed: 1,
				validScore: false,
				stage: 'stage',
				noteSkin: 'default'
			};
		}

		GRID_TOTAL_SIZE = GRID_SIZE * 16;

		// make groups of rendered notes and sustain notes
		curRenderedNotes = new FlxTypedGroup<Note>();
		curRenderedSustains = new FlxTypedGroup<FlxSprite>();
		// comment over later
		renderTextTest = new FlxTypedGroup<FlxText>();

		blackColor = FlxColor.fromRGB(18, 18, 18);
		blackBG = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, blackColor);
		add(blackBG);

		displayNotes();

		strumLine = new FlxSprite(0, 0).makeGraphic(Std.int(FlxG.width / 2), 4);
		strumLine.screenCenter(X);
		add(strumLine);

		strumLineCam = new FlxObject(0, 0);
		strumLineCam.screenCenter(X);

		// selection
		dummyArrow = new FlxSprite().makeGraphic(GRID_SIZE, GRID_SIZE);
		add(dummyArrow);

		leftIcon = new HealthIcon(_song.player2);
		rightIcon = new HealthIcon(_song.player1);
		leftIcon.scrollFactor.set(1, 1);
		rightIcon.scrollFactor.set(1, 1);
		leftIcon.setGraphicSize(Std.int(leftIcon.width / 2));
		rightIcon.setGraphicSize(Std.int(rightIcon.width / 2));
		add(leftIcon);
		add(rightIcon);

		hudTextInfo = new FlxText(5, 90, 0, "eep", 20);
		hudTextInfo.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, RIGHT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		hudTextInfo.scrollFactor.set();
		add(hudTextInfo);

		leftIcon.screenCenter(X);
		rightIcon.screenCenter(X);
		leftIcon.x -= GRID_SIZE * 2;
		rightIcon.x += GRID_SIZE * 2;

		// code from the playstate so I can separate the camera and hud
		camGame = new FlxCamera();
		camHUD = new FlxCamera();
		camHUD.bgColor.alpha = 0;

		FlxG.cameras.reset(camGame);
		FlxG.cameras.add(camHUD);
		FlxCamera.defaultCameras = [camGame];
		// ee

		loadSong(_song.song);
		Conductor.changeBPM(_song.bpm);
		Conductor.mapBPMChanges(_song);

		// play button
		playButton = new FlxSprite(20, FlxG.height - 160).loadGraphic(Paths.image('UI/Charter/play'), true, 143, 143);
		playButton.animation.add('play', [0, 1], 6, true);
		playButton.animation.add('pause', [2, 3], 6, true);
		playButton.animation.play('pause');
		playButton.setGraphicSize(Std.int(playButton.width * 0.7));
		// ayo dont forget to add it DUMMY shubs
		add(playButton);

		add(curRenderedNotes);
		add(curRenderedSustains);
		// comment over later
		add(renderTextTest);

		// set the camera of the UI elements
		playButton.cameras = [camHUD];
		hudTextInfo.cameras = [camHUD];
		leftIcon.cameras = [camHUD];
		rightIcon.cameras = [camHUD];

		//
		if (FlxG.sound.music != null)
		{
			FlxG.sound.music.stop();
			// vocals.stop();
		}

		FlxG.camera.follow(strumLineCam);
		super.create();
	}

	function displayNotes()
	{
		//
		sectionGroup = new FlxTypedGroup<FlxSprite>();

		var curSection:Int = 0;
		for (section in _song.notes)
		{
			for (i in section.sectionNotes)
				ChartLoader.generateChartingArrows(i, curSection, _song);

			if (curSection * (GRID_SIZE * 16) < FlxG.sound.music.length)
			{
				gridBG = FlxGridOverlay.create(GRID_SIZE, GRID_SIZE, GRID_SIZE * 8, GRID_SIZE * 16, true, 0xffe7e6e6, 0xffd9d5d5);
				gridBG.screenCenter(X);
				gridBG.y += curSection * (GRID_SIZE * 16);
				add(gridBG);
			}

			curSection++;

			var sectionLine = new FlxSprite(0, curSection * (GRID_SIZE * 16)).makeGraphic(Std.int(FlxG.width / 2), 4, blackColor);
			sectionLine.screenCenter(X);
			sectionGroup.add(sectionLine);
		}

		GRID_TOTAL_SIZE = curSection * GRID_SIZE * 16;

		var gridBlackLine:FlxSprite = new FlxSprite(gridBG.x + gridBG.width / 2).makeGraphic(2, Std.int(GRID_TOTAL_SIZE), FlxColor.BLACK);
		add(gridBlackLine);

		add(sectionGroup);

		// set the max amount of sections
		sectionsMax = curSection;
	}

	public static function sectionStartTime(curSection:Int, _song:SwagSong):Float
	{
		var daBPM:Int = _song.bpm;
		var daPos:Float = 0;
		for (i in 0...curSection)
		{
			if (_song.notes[i].changeBPM)
			{
				daBPM = _song.notes[i].bpm;
			}
			daPos += 4 * (1000 * 60 / daBPM);
		}
		return daPos;
	}

	public static function getYfromStrum(strumTime:Float, curSection:Int):Float
	{
		return FlxMath.remapToRange(strumTime, 0, 17 * Conductor.stepCrochet, (curSection * (GRID_SIZE * 16)),
			(curSection * (GRID_SIZE * 16)) + (GRID_SIZE * 17));
	}

	override function update(elapsed:Float)
	{
		// update the song position
		Conductor.songPosition = FlxG.sound.music.time;

		// hell, okay, so we wanna figure out the section the strumline is on
		var strumSection = Math.floor(Math.min((strumLine.y + 10) / (16 * GRID_SIZE), sectionsMax));

		// update the strum line
		strumLine.y = getYfromStrum((Conductor.songPosition - sectionStartTime(strumSection,
			_song)) % (Conductor.stepCrochet * _song.notes[strumSection].lengthInSteps),
			strumSection);
		//
		strumLineCam.y = strumLine.y + (FlxG.height / 3);
		// strumLineCam.x = strumLine.x;

		// update the selection
		// code from the og charter
		if (FlxG.mouse.x > gridBG.x
			&& FlxG.mouse.x < gridBG.x + gridBG.width
			&& FlxG.mouse.y > 0
			&& FlxG.mouse.y < (GRID_TOTAL_SIZE))
		{
			dummyArrow.x = Math.floor(FlxG.mouse.x / GRID_SIZE) * GRID_SIZE;
			if (FlxG.keys.pressed.SHIFT)
				dummyArrow.y = FlxG.mouse.y;
			else
				dummyArrow.y = Math.floor(FlxG.mouse.y / GRID_SIZE) * GRID_SIZE;
		}
		//
		super.update(elapsed);

		if (FlxG.keys.justPressed.SPACE)
		{
			if (FlxG.sound.music.playing)
			{
				FlxG.sound.music.pause();
				vocals.pause();
				playButton.animation.play('pause');
			}
			else
			{
				vocals.play();
				FlxG.sound.music.play();
				// for note tick sounds
				hasPlayedSound = [];

				playButton.animation.play('play');
			}
		}

		// note tick sounds
		if (FlxG.sound.music.playing)
		{
			curRenderedNotes.forEachAlive(function(note:Note)
			{
				var strumYIndex:Int = (Math.floor(strumLine.y / GRID_SIZE) * GRID_SIZE);
				var hasPlayedIndex:Int = (Math.floor(note.y / GRID_SIZE) * GRID_SIZE);
				if ((strumYIndex == hasPlayedIndex) && (hasPlayedSound[hasPlayedIndex] != true))
				{
					FlxG.sound.play(Paths.sound('soundNoteTick'));
					hasPlayedSound[hasPlayedIndex] = true;
				}
			});
		}

		if (FlxG.mouse.wheel != 0)
		{
			// probably stupid
			scrolling = true;

			FlxG.sound.music.pause();
			vocals.pause();

			FlxG.sound.music.time = Math.max(FlxG.sound.music.time - (FlxG.mouse.wheel * Conductor.stepCrochet * 0.4), 0);
			FlxG.sound.music.time = Math.min(FlxG.sound.music.time, FlxG.sound.music.length);
			vocals.time = FlxG.sound.music.time;
		}
		/*else if (scrolling)
			{
				FlxG.sound.music.time = (Math.floor(FlxG.sound.music.time / 10) * 10);
				scrolling = false;
			}
		 */

		// I don't know if this is optimised I'm sorry if it isn't
		curRenderedNotes.forEach(function(daNote:Note)
		{
			if ((daNote.y < (strumLineCam.y - (FlxG.height / 2) - 16)) || (daNote.y > (strumLineCam.y + (FlxG.height / 2))))
			{
				daNote.active = false;
				daNote.visible = false;
			}
			else
			{
				daNote.visible = true;
				daNote.active = true;
			}
		});

		if (FlxG.mouse.justPressed)
		{
			if (FlxG.mouse.overlaps(curRenderedNotes))
			{
				curRenderedNotes.forEachAlive(function(note:Note)
				{
					if (FlxG.mouse.overlaps(note))
					{
						if (FlxG.keys.pressed.CONTROL)
						{
							// selectNote(note);
						}
						else
						{
							deleteNote(note);
						}
					}
				});
			}
			else
			{
				if (FlxG.mouse.x > gridBG.x
					&& FlxG.mouse.x < gridBG.x + gridBG.width
					&& FlxG.mouse.y > 0
					&& FlxG.mouse.y < (GRID_TOTAL_SIZE))
				{
					// FlxG.log.add('added note');
					addNote();
				}
				//
			}
		}

		if (FlxG.keys.justPressed.ENTER)
		{
			// lastSection = curSection;
			PlayState.SONG = _song;
			FlxG.sound.music.stop();
			vocals.stop();

			Main.mainClassState = PlayState;
			FlxG.switchState(new PlayState());
		}

		blackBG.y = strumLineCam.y - (FlxG.height / 2);

		//

		// hud text info stuffs
		var shitText:String = Std.string(strumSection);
		hudTextInfo.text = 'section lol: $shitText, ';
		// var mouseSection:String = Std.string(_song.notes[getMouseSection()].mustHitSection);
		// hudTextInfo.text += 'Mouse Section Data: $mouseSection';
	}

	function loadSong(daSong:String):Void
	{
		if (FlxG.sound.music != null)
		{
			FlxG.sound.music.stop();
			// vocals.stop();
		}

		FlxG.sound.playMusic(Paths.inst(daSong), 0.6);

		// WONT WORK FOR TUTORIAL OR TEST SONG!!! REDO LATER
		vocals = new FlxSound().loadEmbedded(Paths.voices(daSong));
		FlxG.sound.list.add(vocals);

		FlxG.sound.music.pause();
		vocals.pause();

		FlxG.sound.music.onComplete = function()
		{
			vocals.pause();
			vocals.time = 0;
			FlxG.sound.music.pause();
			FlxG.sound.music.time = 0;
			// changeSection();
		};
		//
	}

	function addNote()
	{
		var noteStrum = getStrumTime(dummyArrow.y, getMouseSection()) + sectionStartTime(getMouseSection(), _song);
		var noteData = (Math.floor(FlxG.mouse.x / GRID_SIZE) - 12); // rek
		var noteAlt = 0; // define notes as the current type
		var noteSus = 0; // ninja you will NOT get away with this

		// dont expect me to document this code lmao I barely know what it does I'm just trail and erroring it until
		// notes load on the right sides and spawn on the right sides

		var note:Note = new Note(noteStrum, noteData % 4, noteAlt, 0, "");
		var gottaHitNote:Bool = false; // _song.notes[getMouseSection()].mustHitSection;
		if (noteData > 3)
			gottaHitNote = !gottaHitNote;

		note.rawNoteData = noteData; // raw data

		// pain
		if (_song.notes[getMouseSection()].mustHitSection)
		{ // reverse the order of the notedata I guess
			if (noteData > 3)
				noteData -= 4;
			else
				noteData += 4;
		}

		note.setGraphicSize(GRID_SIZE, GRID_SIZE);
		note.updateHitbox();
		note.x = ((FlxG.width / 2) - (GRID_SIZE * 4));
		note.x += Math.floor((noteData % 4) * GRID_SIZE);
		if (gottaHitNote)
			note.x += (4 * GRID_SIZE);

		note.y = Math.floor(getYfromStrum((noteStrum - sectionStartTime(getMouseSection(),
			_song)) % (Conductor.stepCrochet * _song.notes[getMouseSection()].lengthInSteps),
			getMouseSection()));

		_song.notes[getMouseSection()].sectionNotes.push([noteStrum, noteData, noteSus, noteAlt, 0, '']);

		curSelectedNote = _song.notes[getMouseSection()].sectionNotes[_song.notes[getMouseSection()].sectionNotes.length - 1];
		curRenderedNotes.add(note);

		// if (FlxG.keys.pressed.CONTROL)
		// {
		//	_song.notes[getMouseSection()].sectionNotes.push([noteStrum, (noteData + 4) % 8, noteSus, noteType]);
		// }
		if (ChartingState.renderTestActive)
		{
			var newText:FlxText = new FlxText(note.x, note.y, 0, Std.string(noteData) + ', ' + Std.string(noteData % 4));
			newText.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, RIGHT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
			ChartingState.renderTextTest.add(newText);
		}
	}

	public static function getStrumTime(yPos:Float, curSection:Int):Float
	{
		return FlxMath.remapToRange(yPos - ((GRID_SIZE * 16) * curSection), 0, (GRID_SIZE * 16), 0, 16 * Conductor.stepCrochet);
	}

	function deleteNote(note:Note)
	{
		for (i in _song.notes[getMouseSection()].sectionNotes)
		{
			var noteDataIntercept = i[1];
			if (_song.notes[getMouseSection()].mustHitSection)
			{ // reverse the order of the notedata I guess
				if (noteDataIntercept > 3)
					noteDataIntercept -= 4;
				else
					noteDataIntercept += 4;
			}

			// raw note data stuffs makes this much easier lol
			if (i[0] == note.strumTime && noteDataIntercept == note.rawNoteData)
			{
				_song.notes[getMouseSection()].sectionNotes.remove(i);

				if (note.chartSustain != null)
					curRenderedSustains.remove(note.chartSustain);

				curRenderedNotes.remove(note);
			}
			//
		}
	}

	function getMouseSection()
	{
		return Math.floor(Math.min((FlxG.mouse.y) / (16 * GRID_SIZE), sectionsMax));
	}
}
