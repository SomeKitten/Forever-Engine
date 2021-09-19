package gameFolder.meta.state.charting;

import flixel.FlxBasic;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.addons.display.FlxBackdrop;
import flixel.addons.display.FlxGridOverlay;
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
	private var curSection:Int = 0;
	private var chartType:String;

	var strumLine:FlxSpriteGroup;
	var typingShit:FlxInputText;

	var camHUD:FlxCamera;
	var camGame:FlxCamera;
	var strumLineCam:FlxObject;

	var songMusic:FlxSound;
	var vocals:FlxSound;
	private var keysTotal = 8;

	private var dummyArrow:FlxSprite;
	private var curRenderedNotes:FlxTypedGroup<Note>;
	private var curRenderedSustains:FlxTypedGroup<Note>;
	private var curRenderedSections:FlxTypedGroup<FlxBasic>;

	private var arrowGroup:FlxTypedSpriteGroup<UIStaticArrow>;

	private var iconL:HealthIcon;
	private var iconR:HealthIcon;

	var curSelectedNotes:Array<Array<Dynamic>>;

	public static var songPosition:Float = 0;
	public static var curSong:SwagSong;

	private var sectionsMap:Map<Int, Dynamic>;

	var _song:SwagSong;

	var newWaveform:FlxSprite;

	override public function create():Void
	{
		super.create();

		//
		chartType = 'FNF';

		if (PlayState.SONG != null)
			_song = PlayState.SONG;
		else
			_song = Song.loadFromJson('fresh-hard', 'fresh');

		PlayState.resetMusic();
		if (FlxG.sound.music != null)
		{
			FlxG.sound.music.stop();
			// vocals.stop();
		}

		#if !html5
		Discord.changePresence('CHARTING STATE', 'Freeplay');
		#end

		FlxG.mouse.useSystemCursor = false; // Use system cursor because it's prettier
		FlxG.mouse.visible = true; // Hide mouse on start

		strumLineCam = new FlxObject(0, 0);
		strumLineCam.screenCenter(X);

		// generate the chart itself
		addSection();
		loadSong(_song.song);
		generateBackground();

		// set up these dumb shits loll
		sectionsAll = new FlxTypedGroup<FlxSprite>();
		curRenderedNotes = new FlxTypedGroup<Note>();
		curRenderedSustains = new FlxTypedGroup<Note>();
		curRenderedSections = new FlxTypedGroup<FlxBasic>();

		sectionsMap = new Map<Int, Dynamic>();

		generateChart();

		// render the waveforms here instead
		/*
			newWaveform = generateWaveform(Paths.inst(_song.song), 0, 0);
			add(newWaveform);
		 */

		// uh heres the epic setup for these
		add(sectionsAll);
		add(curRenderedSections);
		add(curRenderedSustains);
		add(curRenderedNotes);

		/* Create Cool UI elements here */

		// epic strum line
		strumLine = new FlxSpriteGroup(0, 0);

		var strumLineBase:FlxSprite = new FlxSprite(0, 0).makeGraphic(Std.int(FlxG.width / 2), 2);
		strumLine.add(strumLineBase);

		// dont ask me why this is a sprite I just didnt wanna bother with flxshape tbh
		var strumLineMarkerL:FlxSprite = new FlxSprite(-8, -12).loadGraphic(Paths.image('UI/forever/base/chart editor/marker'));
		strumLine.add(strumLineMarkerL);
		var strumLineMarkerR:FlxSprite = new FlxSprite((FlxG.width / 2) - 8, -12).loadGraphic(Paths.image('UI/forever/base/chart editor/marker'));
		strumLine.add(strumLineMarkerR);

		// center the strumline
		strumLine.screenCenter(X);

		// add the cool icons
		iconL = new HealthIcon(_song.player2, false);
		iconR = new HealthIcon(_song.player1, true);
		iconL.setGraphicSize(Std.int(iconL.width / 2));
		iconR.setGraphicSize(Std.int(iconR.width / 2));

		iconL.setPosition(-64, -128);
		iconR.setPosition(strumLineBase.width - 80, -128);

		strumLine.add(iconL);
		strumLine.add(iconR);

		add(strumLine);

		// cursor
		dummyArrow = new FlxSprite().makeGraphic(gridSize, gridSize);
		add(dummyArrow);

		// and now the epic note thingies
		arrowGroup = new FlxTypedSpriteGroup<UIStaticArrow>(0, 0);
		for (i in 0...horizontalSize)
		{
			var typeReal:Int = i;
			if (typeReal > 3)
				typeReal -= 4;

			var newArrow:UIStaticArrow = ForeverAssets.generateUIArrows(((FlxG.width / 2) - ((horizontalSize / 2) * gridSize)) + ((i - 1) * gridSize) + 1,
				-76, typeReal, 'chart editor');

			newArrow.ID = i;
			newArrow.setGraphicSize(gridSize, gridSize);
			newArrow.updateHitbox();
			newArrow.alpha = 0.9;
			newArrow.antialiasing = (!Init.trueSettings.get('Disable Antialiasing'));

			// lol silly idiot
			newArrow.playAnim('static');

			arrowGroup.add(newArrow);
		}
		add(arrowGroup);

		// code from the playstate so I can separate the camera and hud
		camGame = new FlxCamera();
		camHUD = new FlxCamera();
		camHUD.bgColor.alpha = 0;

		FlxG.cameras.reset(camGame);
		FlxG.cameras.add(camHUD);
		FlxCamera.defaultCameras = [camGame];

		generateHUD();

		//
		Conductor.changeBPM(_song.bpm);
		Conductor.mapBPMChanges(_song);

		FlxG.camera.follow(strumLineCam);

		debugText = new FlxText(0, 0, 0, '', 24);
		// add(debugText);
	}

	private var debugText:FlxText;
	private var informationBar:FlxText;

	private function generateHUD()
	{
		// interactible hud
		var sidebar = new FlxShapeBox(916, 160, 326, 480, {thickness: 24, color: FlxColor.WHITE}, FlxColor.WHITE);
		sidebar.alpha = (26 / 255);

		addSectionUI();
		addSongUI();
		addNoteUI();

		//
		var constTextSize:Int = 24;
		informationBar = new FlxText(5, FlxG.height - (constTextSize * 4) - 5, 0, 'BEAT:', constTextSize);
		informationBar.setFormat(Paths.font("vcr.ttf"), constTextSize);
		informationBar.cameras = [camHUD];

		add(informationBar);
	}

	var UI_box:FlxUITabMenu;
	var _file:FileReference;

	var stepperLength:FlxUINumericStepper;
	var check_mustHitSection:FlxUICheckBox;
	var check_changeBPM:FlxUICheckBox;
	var stepperSectionBPM:FlxUINumericStepper;
	var check_altAnim:FlxUICheckBox;

	function addSectionUI():Void
	{
		var tabs = [
			{name: "Song", label: 'Song'},
			{name: "Section", label: 'Section'},
			{name: "Note", label: 'Note'}
		];

		UI_box = new FlxUITabMenu(null, tabs, true);

		UI_box.resize(300, 400);
		UI_box.x = 916;
		UI_box.y = 160;
		add(UI_box);

		var tab_group_section = new FlxUI(null, UI_box);
		tab_group_section.name = 'Section';

		stepperLength = new FlxUINumericStepper(10, 10, 4, 0, 0, 999, 0);
		stepperLength.value = _song.notes[curSection].lengthInSteps;
		stepperLength.name = "section_length";

		stepperSectionBPM = new FlxUINumericStepper(10, 80, 1, Conductor.bpm, 0, 999, 0);
		stepperSectionBPM.value = Conductor.bpm;
		stepperSectionBPM.name = 'section_bpm';

		var stepperCopy:FlxUINumericStepper = new FlxUINumericStepper(110, 130, 1, 1, -999, 999, 0);

		var copyButton:FlxButton = new FlxButton(10, 130, "Copy last section", function()
		{
			// copySection(Std.int(stepperCopy.value));
		});

		var clearSectionButton:FlxButton = new FlxButton(10, 150, "Clear", function() {});

		var swapSection:FlxButton = new FlxButton(10, 170, "Swap section", function()
		{
			for (i in 0..._song.notes[curSection].sectionNotes.length)
			{
				var note = _song.notes[curSection].sectionNotes[i];
				note[1] = (note[1] + 4) % 8;
				_song.notes[curSection].sectionNotes[i] = note;
				// updateGrid();
			}
		});

		check_mustHitSection = new FlxUICheckBox(10, 30, null, null, "Must hit section", 100);
		check_mustHitSection.name = 'check_mustHit';
		check_mustHitSection.checked = true;
		// _song.needsVoices = check_mustHit.checked;

		check_altAnim = new FlxUICheckBox(10, 400, null, null, "Alt Animation", 100);
		check_altAnim.name = 'check_altAnim';

		check_changeBPM = new FlxUICheckBox(10, 60, null, null, 'Change BPM', 100);
		check_changeBPM.name = 'check_changeBPM';

		tab_group_section.add(stepperLength);
		tab_group_section.add(stepperSectionBPM);
		tab_group_section.add(stepperCopy);
		tab_group_section.add(check_mustHitSection);
		tab_group_section.add(check_altAnim);
		tab_group_section.add(check_changeBPM);
		tab_group_section.add(copyButton);
		tab_group_section.add(clearSectionButton);
		tab_group_section.add(swapSection);

		UI_box.addGroup(tab_group_section);
		UI_box.cameras = [camHUD];
	}

	function addSongUI():Void
	{
		var UI_songTitle = new FlxUIInputText(10, 10, 70, _song.song, 8);
		typingShit = UI_songTitle;

		var check_voices = new FlxUICheckBox(10, 25, null, null, "Has voice track", 100);
		check_voices.checked = _song.needsVoices;
		// _song.needsVoices = check_voices.checked;
		check_voices.callback = function()
		{
			_song.needsVoices = check_voices.checked;
			trace('CHECKED!');
		};

		var check_mute_inst = new FlxUICheckBox(10, 200, null, null, "Mute Instrumental (in editor)", 100);
		check_mute_inst.checked = false;
		check_mute_inst.callback = function()
		{
			var vol:Float = 1;

			if (check_mute_inst.checked)
				vol = 0;

			FlxG.sound.music.volume = vol;
		};

		var saveButton:FlxButton = new FlxButton(110, 8, "Save", function()
		{
			saveLevel();
		});

		var reloadSong:FlxButton = new FlxButton(saveButton.x + saveButton.width + 10, saveButton.y, "Reload Audio", function()
		{
			loadSong(_song.song);
		});

		var reloadSongJson:FlxButton = new FlxButton(reloadSong.x, saveButton.y + 30, "Reload JSON", function()
		{
			loadJson(_song.song.toLowerCase());
		});

		var loadAutosaveBtn:FlxButton = new FlxButton(reloadSongJson.x, reloadSongJson.y + 30, 'load autosave', loadAutosave);

		var stepperSpeed:FlxUINumericStepper = new FlxUINumericStepper(10, 80, 0.1, 1, 0.1, 10, 1);
		stepperSpeed.value = _song.speed;
		stepperSpeed.name = 'song_speed';

		var stepperBPM:FlxUINumericStepper = new FlxUINumericStepper(10, 65, 1, 1, 1, 339, 0);
		stepperBPM.value = Conductor.bpm;
		stepperBPM.name = 'song_bpm';

		var characters:Array<String> = CoolUtil.coolTextFile(Paths.txt('characterList'));

		var player1DropDown = new FlxUIDropDownMenu(10, 100, FlxUIDropDownMenu.makeStrIdLabelArray(characters, true), function(character:String)
		{
			_song.player1 = characters[Std.parseInt(character)];
			updateHeads();
		});
		player1DropDown.selectedLabel = _song.player1;

		var player2DropDown = new FlxUIDropDownMenu(140, 100, FlxUIDropDownMenu.makeStrIdLabelArray(characters, true), function(character:String)
		{
			_song.player2 = characters[Std.parseInt(character)];
			updateHeads();
		});

		player2DropDown.selectedLabel = _song.player2;

		var tab_group_song = new FlxUI(null, UI_box);
		tab_group_song.name = "Song";
		tab_group_song.add(UI_songTitle);

		tab_group_song.add(check_voices);
		tab_group_song.add(check_mute_inst);
		tab_group_song.add(saveButton);
		tab_group_song.add(reloadSong);
		tab_group_song.add(reloadSongJson);
		tab_group_song.add(loadAutosaveBtn);
		tab_group_song.add(stepperBPM);
		tab_group_song.add(stepperSpeed);
		tab_group_song.add(player1DropDown);
		tab_group_song.add(player2DropDown);

		UI_box.addGroup(tab_group_song);
		UI_box.scrollFactor.set();

		FlxG.camera.follow(strumLine);
	}

	private function updateHUD()
	{
		//
		var fakeStep = Std.string(FlxMath.roundDecimal((Conductor.songPosition / Conductor.stepCrochet), 2));
		var fakeBeat = Std.string(FlxMath.roundDecimal((Conductor.songPosition / Conductor.stepCrochet) / 4, 2));
		var songTime = Std.string(FlxMath.roundDecimal(Conductor.songPosition / 1000, 2));
		informationBar.text = 'STEP: $fakeStep\nBEAT: $fakeBeat\nTIME: $songTime' + '\nBPM: ' + Conductor.bpm + '\n';

		// putting this code here cus fuck you

		if (FlxG.keys.pressed.BACKSPACE)
		{
			pauseMusic();
			openSubState(new PreferenceSubstate(camHUD));
		}
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

	var stepperSusLength:FlxUINumericStepper;
	var stepperType:FlxUINumericStepper;

	function addNoteUI():Void
	{
		var tab_group_note = new FlxUI(null, UI_box);
		tab_group_note.name = 'Note';

		stepperSusLength = new FlxUINumericStepper(10, 10, Conductor.stepCrochet / 2, 0, 0, Conductor.stepCrochet * 16);
		stepperSusLength.value = 0;
		stepperSusLength.name = 'note_susLength';

		var applyLength:FlxButton = new FlxButton(100, 10, 'Apply');

		tab_group_note.add(stepperSusLength);
		tab_group_note.add(applyLength);

		// note types
		stepperType = new FlxUINumericStepper(10, 30, Conductor.stepCrochet / 125, 0, 0, (Conductor.stepCrochet / 125) + 10); // 10 is placeholder
		// I have no idea what i'm doing lmfao
		stepperType.value = 0;
		stepperType.name = 'note_type';

		tab_group_note.add(stepperType);

		UI_box.addGroup(tab_group_note);
		// I'm genuinely tempted to go around and remove every instance of the word "sus" it is genuinely killing me inside
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

	private var scrollSpeed:Float = 0.75;
	private var canPlay:Bool = true;

	private var isPlacing:Bool = false;
	private var isPlacingStrums:Bool = false;
	private var notesExtending:Array<Note> = [];

	override public function update(elapsed:Float)
	{
		var beatTime:Float = ((Conductor.songPosition / 1000) * (Conductor.bpm / 60));

		// coolGrid.y = (750 * (Math.cos((beatTime / 5) * Math.PI)));
		// coolGrid.x = Conductor.songPosition;

		if (FlxG.keys.justPressed.SPACE)
		{
			if (songMusic.playing)
				pauseMusic();
			else
			{
				vocals.play();
				songMusic.play();

				// reset note tick sounds
				hitSoundsPlayed = [];

				// playButtonAnimation('play');
			}
		}

		// originally only for note ticks but
		// repurposed for arrow presses
		if (songMusic.playing) {}

		arrowGroup.forEach(function(arrow:UIStaticArrow)
		{
			if (arrow.animation.curAnim.finished)
				arrow.playAnim('static');
		});

		if (FlxG.mouse.wheel != 0)
		{
			pauseMusic();

			songMusic.time = Math.max(songMusic.time - (FlxG.mouse.wheel * Conductor.stepCrochet * scrollSpeed), 0);
			songMusic.time = Math.min(songMusic.time, songMusic.length);
			vocals.time = songMusic.time;
		}

		// I don't know if this is optimised I'm sorry if it isn't
		checkExists(curRenderedNotes);
		checkExists(curRenderedSustains);
		checkExists(curRenderedSections);

		// strumline camera stuffs!
		Conductor.songPosition = songMusic.time;

		strumLine.y = getYfromStrum(Conductor.songPosition);
		curSection = getSectionfromY(strumLine.y);

		strumLineCam.y = strumLine.y + (FlxG.height / 3);
		arrowGroup.y = strumLine.y;

		coolGradient.y = strumLineCam.y - (FlxG.height / 2);
		coolGrid.y = strumLineCam.y - (FlxG.height / 2);

		super.update(elapsed);

		var shiftThing:Int = 1;
		if (FlxG.keys.pressed.SHIFT)
			shiftThing = 4;

		if (FlxG.keys.justPressed.RIGHT || FlxG.keys.justPressed.D)
		{
			songMusic.time = getStrumTime(sectionsMap.get(Std.int(Math.min(curSection + shiftThing, sectionsMax)))[2]);
			pauseMusic();
		}
		else if (FlxG.keys.justPressed.LEFT || FlxG.keys.justPressed.A)
		{
			songMusic.time = getStrumTime(sectionsMap.get(Std.int(Math.max(curSection - shiftThing, 0)))[2]);
			pauseMusic();
		}

		// mouse stuffs!

		debugText.setPosition(FlxG.mouse.x + 48, FlxG.mouse.y);
		debugText.text = Std.string(Math.floor(dummyArrow.x / gridSize));

		///*
		if (FlxG.mouse.x > ((FlxG.width / 2) - (gridSize * (horizontalSize / 2)))
			&& FlxG.mouse.x < ((FlxG.width / 2) + (gridSize * (horizontalSize / 2)))
			&& FlxG.mouse.y > 0
			&& FlxG.mouse.y < (gridSize * sectionsMax * verticalSize))
		{
			var testInterval = 16;
			dummyArrow.x = (Math.floor((FlxG.mouse.x - testInterval) / gridSize) * gridSize) + testInterval;
			if (FlxG.keys.pressed.SHIFT)
				dummyArrow.y = FlxG.mouse.y - testInterval;
			else
				dummyArrow.y = Math.floor(FlxG.mouse.y / gridSize) * gridSize;

			// moved this in here for the sake of not dying
			if (FlxG.mouse.justPressed)
			{
				if (!FlxG.mouse.overlaps(curRenderedNotes))
				{
					// add note funny
					var noteStrum = getStrumTime(dummyArrow.y);

					var notesSection = getSectionfromY(dummyArrow.y);
					var noteData = adjustSide(Math.floor(dummyArrow.x / gridSize) - 8, notesSection);
					var noteSus = 0; // ninja you will NOT get away with this

					noteCleanup(notesSection, noteStrum, noteData);

					_song.notes[notesSection].sectionNotes.push([noteStrum, noteData, noteSus]);
					generateChartNote(noteData, noteStrum, noteSus, 0, notesSection, sectionsMap.get(notesSection)[3]);

					updateSelection(_song.notes[notesSection].sectionNotes[_song.notes[notesSection].sectionNotes.length - 1], notesSection, true);

					isPlacing = true;
				}
				else
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
								// delete the epic note
								var notesSection = getSectionfromY(note.y);
								// persona 3 mass destruction
								destroySustain(note, notesSection);

								noteCleanup(notesSection, note.strumTime, note.rawNoteData);

								note.kill();
								curRenderedNotes.remove(note);
								note.destroy();
								//
							}
						}
						// lol
					});
				}
			}
		}
		// */

		if (FlxG.mouse.pressed)
		{
			if (isPlacing)
			{
				// adjust the note length lol
				for (i in 0...curSelectedNotes.length)
				{
					// distance stuffs
					var lastNotePlacement = getYfromStrum(curSelectedNotes[curSelectedNotes.length - 1][0]);
					// idk how to math so weird ass equation here
					if (curRenderedNotes.members.contains(notesExtending[i]))
						adjustNoteSustain(notesExtending[i], (((FlxG.mouse.y - (lastNotePlacement + gridSize)) / gridSize) * Conductor.stepCrochet));
					// someone please fix this for me I'm so burnt out
				}
			}
		}
		else
			isPlacing = false;

		if (FlxG.keys.justPressed.ENTER)
		{
			songPosition = songMusic.time;
			FlxG.mouse.useSystemCursor = true;
			FlxG.mouse.visible = false; // Hide mouse

			PlayState.SONG = _song;
			ForeverTools.killMusic([songMusic, vocals]);
			Main.switchState(this, new PlayState());
		}

		updateHUD();
	}

	private function updateSelection(noteToAdd, section, ?reset = false)
	{
		// lol reset funny selection list if script calls for it
		if (reset)
		{
			curSelectedNotes = [];
			notesExtending = [];
		}

		curSelectedNotes.push(noteToAdd);
		// find the notes for the actual display
		var chosenNoteMap:Map<Note, Array<Dynamic>> = sectionsMap.get(section)[3];
		// remove all connected notes in the note's map
		for (i in chosenNoteMap.keys())
		{
			//
			if ((i.strumTime == noteToAdd[0] && i.rawNoteData == noteToAdd[1]) && (i.exists))
				notesExtending.push(i);
		}
		#if debug
		trace(curSelectedNotes + ', fakenotes ' + notesExtending);
		#end
	}

	private function noteCleanup(notesSection, strumTime, noteData)
	{
		// go through all notes in the section and remove any dupes
		for (removeNote in _song.notes[notesSection].sectionNotes)
		{
			// hopefully this works
			if ((removeNote[0] == strumTime) && (removeNote[1] == noteData))
				_song.notes[notesSection].sectionNotes.remove(removeNote);
		}
	}

	/**
		This is the last thing I'm trying if it doesnt work I'm just moving on with my life and fixing it after skater is done
	**/
	private function destroySustain(note, notesSection)
	{
		var chosenNoteMap:Map<Note, Array<Dynamic>> = sectionsMap.get(notesSection)[3];
		// remove all connected notes in the note's map
		#if debug
		trace(chosenNoteMap.get(note));
		#end

		if (chosenNoteMap.get(note) != null)
		{
			for (i in 0...chosenNoteMap.get(note).length)
			{
				chosenNoteMap.get(note)[i].kill();
				curRenderedSustains.remove(chosenNoteMap.get(note)[i]);
				chosenNoteMap.get(note)[i].destroy();
			}
		}
	}

	function updateHeads():Void
	{
		if (check_mustHitSection.checked)
		{
			iconL.animation.play(_song.player1);
			iconR.animation.play(_song.player2);
		}
		else
		{
			iconL.animation.play(_song.player2);
			iconR.animation.play(_song.player1);
		}
	}

	private function adjustNoteSustain(note:Note, newSus:Float)
	{
		//
		var notesSection = getSectionfromY(note.y);
		var noteSustains:Map<Note, Array<Dynamic>> = sectionsMap.get(notesSection)[3];

		if (newSus > 0)
		{
			if ((noteSustains.get(note) != null) && (noteSustains.get(note)[0].exists))
			{
				// if a note map does already exist (the note was a sustain note before)
				var constSize = Std.int(gridSize / 3);
				noteSustains.get(note)[0].setGraphicSize(constSize, getNoteVerticalSize(newSus));
				noteSustains.get(note)[0].updateHitbox();
				//
				noteSustains.get(note)[1].y = note.y + (noteSustains.get(note)[0].height) + (gridSize / 2);
			}
			else
				generateSustain(note.strumTime, note.rawNoteData, newSus, 0, note, noteSustains);
		}
		else if ((noteSustains.get(note) != null) && (noteSustains.get(note)[0].exists)) // remove the sustain note instead
			destroySustain(note, notesSection);

		// set the note sustain in the actual chart info
		for (i in 0...curSelectedNotes.length)
			curSelectedNotes[i][2] = Math.max(newSus, 0);
	}

	private function getNoteVerticalSize(newSus:Float)
	{
		var constSize = Std.int(gridSize / 3);
		return Math.floor(FlxMath.remapToRange(newSus, 0, Conductor.stepCrochet * getChartSizeMax(), 0, gridSize * getChartSizeMax()) - constSize);
	}

	private function returnFromNote(note:Note)
	{
		// just the note selector from the og chart editor
		var counter:Int = 0;
		var returnNote = null;
		var notesSection = getSectionfromY(note.y);

		for (i in _song.notes[notesSection].sectionNotes)
		{
			if (i.strumTime == note.strumTime && i.noteData == note.rawNoteData)
				returnNote = _song.notes[notesSection].sectionNotes[counter];
			counter += 1;
		}

		return returnNote;
	}

	var coolGrid:FlxBackdrop;
	var coolGradient:FlxSprite;

	private function checkExists(group:FlxTypedGroup<Dynamic>)
	{
		group.forEach(function(object:Dynamic)
		{
			if ((object.y < (strumLineCam.y - (FlxG.height / 2) - object.height)) || (object.y > (strumLineCam.y + (FlxG.height / 2))))
				object.alive = false;
			else
				object.alive = true;
		});
	}

	private function generateBackground()
	{
		coolGrid = new FlxBackdrop(null, 1, 1, true, true, 1, 1);
		coolGrid.loadGraphic(Paths.image('UI/forever/base/chart editor/grid'));
		coolGrid.alpha = (32 / 255);
		add(coolGrid);

		// gradient
		coolGradient = FlxGradient.createGradientFlxSprite(FlxG.width, FlxG.height,
			FlxColor.gradient(FlxColor.fromRGB(188, 158, 255, 200), FlxColor.fromRGB(80, 12, 108, 255), 16));
		coolGradient.alpha = (32 / 255);
		add(coolGradient);
	}

	var gridSize:Int = 52;
	var horizontalSize:Int = 8;
	var verticalSize:Int = 16;

	private var sectionsMax:Int = 0;
	private var sectionsAll:FlxTypedGroup<FlxSprite>;

	private var prevNote:Note;
	private var hitSoundsPlayed:Array<Bool> = [];
	private var fullSectionSize:Float = 0;

	private function generateChart()
	{
		// generate all sections

		// YOU DUMMY PUT IT OVER HERE NOT AFTER LMAAOOOOO
		removeAllNotes();

		sectionsMax = 1;
		for (section in _song.notes)
		{
			// set up cool section stuffs here!
			// section map will be used to control sections easily so I can just do stuffs without it breaking
			var curGridSprite:FlxSprite = FlxGridOverlay.create(gridSize, gridSize, gridSize * horizontalSize, gridSize * section.lengthInSteps, true,
				FlxColor.WHITE, FlxColor.BLACK);
			curGridSprite.alpha = (26 / 255);
			curGridSprite.screenCenter(X);
			curGridSprite.y = fullSectionSize;

			sectionsAll.add(curGridSprite);
			regenerateSection(sectionsMax - 1, fullSectionSize);

			// generate notes
			var curNoteMap:Map<Note, Dynamic> = new Map<Note, Array<Dynamic>>();

			for (i in section.sectionNotes)
			{
				// note stuffs
				var daNoteAlt = 0;
				if (i.length > 2)
					daNoteAlt = i[3];

				generateChartNote(i[1], i[0], i[2], daNoteAlt, sectionsMax - 1, curNoteMap);
			}

			//
			sectionsMap.set(sectionsMax - 1, [curGridSprite, section.lengthInSteps, fullSectionSize, curNoteMap]);
			fullSectionSize += (gridSize * section.lengthInSteps);
			sectionsMax++;
		}
		// lolll
		sectionsMax--;
	}

	private function generateChartNote(daNoteInfo, daStrumTime, daSus, daNoteAlt, noteSection, curNoteMap:Map<Note, Dynamic>)
	{
		//
		var note:Note = ForeverAssets.generateArrow(PlayState.assetModifier, daStrumTime, daNoteInfo % 4, 0, daNoteAlt);
		// I love how there's 3 different engines that use this exact same variable name lmao
		note.rawNoteData = daNoteInfo;
		note.sustainLength = daSus;
		note.setGraphicSize(gridSize, gridSize);
		note.updateHitbox();

		note.screenCenter(X);
		note.x -= ((gridSize * (horizontalSize / 2)) - (gridSize / 2));
		note.x += Math.floor(adjustSide(daNoteInfo, noteSection) * gridSize);

		note.y = Math.floor(getYfromStrum(daStrumTime));

		curRenderedNotes.add(note);

		curNoteMap.set(note, null);
		generateSustain(daStrumTime, daNoteInfo, daSus, daNoteAlt, note, curNoteMap);
	}

	private function generateSustain(daStrumTime:Float = 0, daNoteInfo:Int = 0, daSus:Float = 0, daNoteAlt:Float = 0, note:Note, curNoteMap:Map<Note, Dynamic>)
	{
		if (daSus > 0)
		{
			prevNote = note;
			var constSize = Std.int(gridSize / 3);

			var sustainVis:Note = ForeverAssets.generateArrow(PlayState.assetModifier, daStrumTime + (Conductor.stepCrochet * daSus) + Conductor.stepCrochet,
				daNoteInfo % 4, 0, daNoteAlt, true, prevNote);

			sustainVis.setGraphicSize(constSize, getNoteVerticalSize(daSus / 2));
			sustainVis.updateHitbox();
			sustainVis.x = note.x + constSize;
			sustainVis.y = note.y + (gridSize / 2);

			var sustainEnd:Note = ForeverAssets.generateArrow(PlayState.assetModifier, daStrumTime + (Conductor.stepCrochet * daSus) + Conductor.stepCrochet,
				daNoteInfo % 4, 0, daNoteAlt, true, sustainVis);
			sustainEnd.setGraphicSize(constSize, constSize);
			sustainEnd.updateHitbox();
			sustainEnd.x = sustainVis.x;
			sustainEnd.y = note.y + (sustainVis.height) + (gridSize / 2);

			// loll for later
			sustainVis.rawNoteData = daNoteInfo;
			sustainEnd.rawNoteData = daNoteInfo;

			curRenderedSustains.add(sustainVis);
			curRenderedSustains.add(sustainEnd);
			//

			// set the note at the current note map
			curNoteMap.set(note, [sustainVis, sustainEnd]);
		}
	}

	private function regenerateSection(section:Int, placement:Float)
	{
		// this will be used to regenerate a box that shows what section the camera is focused on

		// oh and section information lol
		var extraSize = 6;
		var sectionLine:FlxSprite = new FlxSprite(FlxG.width / 2 - (gridSize * (horizontalSize / 2)) - (extraSize / 2),
			placement).makeGraphic(gridSize * horizontalSize + extraSize, 2);
		sectionLine.alpha = (88 / 255);

		// section camera
		var sectionExtend:Float = 0;
		if (_song.notes[section].mustHitSection)
			sectionExtend = (gridSize * (horizontalSize / 2));

		var sectionCamera:FlxSprite = new FlxSprite(FlxG.width / 2 - (gridSize * (horizontalSize / 2)) + (sectionExtend),
			placement).makeGraphic(Std.int(gridSize * (horizontalSize / 2)), _song.notes[section].lengthInSteps * gridSize, FlxColor.fromRGB(43, 116, 219));
		sectionCamera.alpha = (88 / 255);
		curRenderedSections.add(sectionCamera);

		// set up section numbers
		for (i in 0...2)
		{
			var sectionNumber:FlxText = new FlxText(0, sectionLine.y - 12, 0, Std.string(section), 20);
			// set the x of the section number
			sectionNumber.x = sectionLine.x - sectionNumber.width - 5;
			if (i == 1)
				sectionNumber.x = sectionLine.x + sectionLine.width + 5;

			sectionNumber.setFormat(Paths.font("vcr.ttf"), 24, FlxColor.WHITE);
			sectionNumber.antialiasing = false;
			sectionNumber.alpha = sectionLine.alpha;
			curRenderedSections.add(sectionNumber);
		}

		for (i in 1...Std.int(_song.notes[section].lengthInSteps / 4))
		{
			// create a smaller section stepper
			var sectionStep:FlxSprite = new FlxSprite(FlxG.width / 2 - (gridSize * (horizontalSize / 2)) - (extraSize / 2),
				placement + (i * (gridSize * 4))).makeGraphic(gridSize * horizontalSize + extraSize, 1);
			sectionStep.alpha = sectionLine.alpha;
			curRenderedSections.add(sectionStep);
		}

		curRenderedSections.add(sectionLine);
	}

	private function removeAllNotes()
	{
		curRenderedNotes.clear();
		curRenderedSustains.clear();
	}

	private function addSection(lengthInSteps:Int = 16):Void
	{
		var sec:SwagSection = {
			lengthInSteps: lengthInSteps,
			bpm: _song.bpm,
			changeBPM: false,
			mustHitSection: true,
			sectionNotes: [],
			typeOfSection: 0,
			altAnim: false
		};

		_song.notes.push(sec);
	}

	function getStrumTime(yPos:Float):Float
	{
		return FlxMath.remapToRange(yPos, 0, getChartSizeMax() * gridSize, 0, getChartSizeMax() * Conductor.stepCrochet);
	}

	function getYfromStrum(strumTime:Float):Float
	{
		return FlxMath.remapToRange(strumTime, 0, (getChartSizeMax() * Conductor.stepCrochet), 0, (getChartSizeMax() * gridSize));
	}

	function getChartSizeMax()
	{
		// return the chart's length (in steps)
		var totalReturn = 0;
		for (sections in _song.notes)
			totalReturn += sections.lengthInSteps;
		return totalReturn;
	}

	function getSectionfromY(location:Float)
	{
		// simple script for stuff to work properly
		var newSection:Int = 0;
		for (sections in sectionsMap.keys())
		{
			// find new section loll
			if ((Math.floor(location / gridSize) * gridSize) >= sectionsMap.get(sections)[2])
				newSection = sections;
		}
		return newSection;
	}

	function adjustSide(noteData:Int, sectionTemp:Int)
	{
		return (_song.notes[sectionTemp].mustHitSection ? ((noteData + 4) % 8) : noteData);
	}

	private var daSpacing:Float = 0.3;

	function loadLevel():Void
	{
		trace(_song.notes);
	}

	function getNotes():Array<Dynamic>
	{
		var noteData:Array<Dynamic> = [];

		for (i in _song.notes)
		{
			noteData.push(i.sectionNotes);
		}

		return noteData;
	}

	function loadJson(song:String):Void
	{
		PlayState.SONG = Song.loadFromJson(song.toLowerCase(), song.toLowerCase());
		FlxG.resetState();
	}

	function loadAutosave():Void
	{
		PlayState.SONG = Song.parseJSONshit(FlxG.save.data.autosave);
		FlxG.resetState();
	}

	private function saveLevel()
	{
		var json = {
			"song": _song
		};

		var data:String = Json.stringify(json);

		if ((data != null) && (data.length > 0))
		{
			_file = new FileReference();
			_file.addEventListener(Event.COMPLETE, onSaveComplete);
			_file.addEventListener(Event.CANCEL, onSaveCancel);
			_file.addEventListener(IOErrorEvent.IO_ERROR, onSaveError);
			_file.save(data.trim(), _song.song.toLowerCase() + ".json");
		}
	}

	function autosaveSong():Void
	{
		FlxG.save.data.autosave = Json.stringify({
			"song": _song
		});
		FlxG.save.flush();
	}

	function onSaveComplete(_):Void
	{
		_file.removeEventListener(Event.COMPLETE, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
		FlxG.log.notice("Successfully saved LEVEL DATA.");
	}

	/**
	 * Called when the save file dialog is cancelled.
	 */
	function onSaveCancel(_):Void
	{
		_file.removeEventListener(Event.COMPLETE, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
	}

	/**
	 * Called if there is an error while saving the gameplay recording.
	 */
	function onSaveError(_):Void
	{
		_file.removeEventListener(Event.COMPLETE, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
		FlxG.log.error("Problem saving Level data");
	}

	function generateWaveform(loadedSong:String, x:Float = 0, y:Float = 0):FlxSprite
	{
		// generate the waveform based on gedehari's code
		// https://github.com/gedehari/HaxeFlixel-Waveform-Rendering
		// (yes he let me use this lol)

		var audioBuffer:AudioBuffer = AudioBuffer.fromFile('./$loadedSong');
		var tempSong = new FlxSound().loadEmbedded(Sound.fromAudioBuffer(audioBuffer), false, true);
		// FlxG.sound.list.add(tempSong);

		var generatedWaveform = new FlxSprite(x, y).makeGraphic(3000, 720, FlxColor.fromRGB(0, 0, 0, 1));
		generatedWaveform.x = x - (generatedWaveform.width / 2);
		generatedWaveform.y = y - (generatedWaveform.height / 2);

		generatedWaveform.angle = 360 - 90;

		var bytes:Bytes = audioBuffer.data.toBytes();

		#if !html5
		Thread.create(function()
		{
			var currentTime:Float = Sys.time();
			var finishedTime:Float;

			var index:Int = 0;
			var drawIndex:Int = 0;
			var samplesPerCollumn:Int = Std.int(tempSong.length / 600);

			var min:Float = 0;
			var max:Float = 0;

			Sys.println("Iterating");

			while ((index * 4) < (bytes.length - 1))
			{
				var byte:Int = bytes.getUInt16(index * 4);

				if (byte > 65535 / 2)
					byte -= 65535;

				var sample:Float = (byte / 65535);

				if (sample > 0)
				{
					if (sample > max)
						max = sample;
				}
				else if (sample < 0)
				{
					if (sample < min)
						min = sample;
				}

				if ((index % samplesPerCollumn) == 0)
				{
					// trace("min: " + min + ", max: " + max);

					if (drawIndex > 1280)
					{
						drawIndex = 0;
					}

					var pixelsMin:Float = Math.abs(min * 300);
					var pixelsMax:Float = max * 300;

					generatedWaveform.pixels.fillRect(new Rectangle(drawIndex, 0, 1, 720), 0xFF000000);
					generatedWaveform.pixels.fillRect(new Rectangle(drawIndex, (FlxG.height / 2) - pixelsMin, 1, pixelsMin + pixelsMax), FlxColor.WHITE);
					drawIndex += 1;

					min = 0;
					max = 0;
				}

				index += 1;
			}

			finishedTime = Sys.time();

			Sys.println("Took " + (finishedTime - currentTime) + " seconds.");
		});
		#end

		// tempSong.stop();

		return generatedWaveform;
	}
}
