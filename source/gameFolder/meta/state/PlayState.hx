package gameFolder.meta.state;

import cpp.ConstStar;
import flixel.FlxBasic;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.FlxSubState;
import flixel.addons.effects.FlxTrail;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.system.FlxSound;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.ui.FlxBar;
import flixel.util.FlxColor;
import flixel.util.FlxSort;
import flixel.util.FlxTimer;
import gameFolder.gameObjects.*;
import gameFolder.gameObjects.userInterface.*;
import gameFolder.meta.*;
import gameFolder.meta.MusicBeat.MusicBeatState;
import gameFolder.meta.data.*;
import gameFolder.meta.data.Section.SwagSection;
import gameFolder.meta.data.Song.SwagSong;
import gameFolder.meta.state.ChartingState;
import gameFolder.meta.subState.*;

using StringTools;

// probably import substate too later
class PlayState extends MusicBeatState
{
	public static var curStage:String = '';
	public static var SONG:SwagSong;
	public static var isStoryMode:Bool = false;
	public static var storyWeek:Int = 0;
	public static var storyPlaylist:Array<String> = [];
	public static var storyDifficulty:Int = 2;

	var startTimer:FlxTimer;

	private var vocals:FlxSound;

	private var dadOpponent:Character;
	private var gf:Character;
	private var boyfriend:Boyfriend;

	public var boyfriendAutoplay:Bool = false;

	private var dadAutoplay:Bool = true; // this is for testing purposes

	private var notes:FlxTypedGroup<Note>;
	private var unspawnNotes:Array<Note> = [];

	// control arrays I'll use later
	var holdControls:Array<Bool> = [];
	var pressControls:Array<Bool> = [];
	var releaseControls:Array<Bool> = []; // haha garcello!

	// get it cus release
	// I'm funny just trust me
	private var curSection:Int = 0;
	private var camFollow:FlxObject;

	private static var prevCamFollow:FlxObject;

	// strums
	private var strumLine:FlxTypedGroup<FlxSprite>;
	private var strumLineNotes:FlxTypedGroup<UIBabyArrow>;
	private var boyfriendStrums:FlxTypedGroup<UIBabyArrow>;
	private var dadStrums:FlxTypedGroup<UIBabyArrow>;

	private var curSong:String = "";

	private var gfSpeed:Int = 1;
	private var health:Float = 1;
	private var combo:Int = 0;

	private var healthBarBG:FlxSprite;
	private var healthBar:FlxBar;

	private var generatedMusic:Bool = false;
	private var startingSong:Bool = false;
	private var paused:Bool = false;
	var startedCountdown:Bool = false;
	var canPause:Bool = true;

	var previousFrameTime:Int = 0;
	var lastReportedPlayheadPosition:Int = 0;
	var songTime:Float = 0;

	private var camHUD:FlxCamera;
	private var camGame:FlxCamera;

	private var camDisplaceX:Float = 0;
	private var camDisplaceY:Float = 0; // might not use depending on result

	public static var defaultCamZoom:Float = 1.05;

	private var camZooming:Bool = true;

	public static var songScore:Int = 0;

	var storyDifficultyText:String = "";
	var iconRPC:String = "";
	var songLength:Float = 0;

	public var stageBuild:Stage;

	public var uiHud:ClassHUD;

	public static var daPixelZoom:Float = 6;

	// at the beginning of the playstate
	override public function create()
	{
		// stop any existing music tracks playing
		if (FlxG.sound.music != null)
			FlxG.sound.music.stop();

		// create the game camera
		camGame = new FlxCamera();
		// create the hud camera (separate so the hud stays on screen)
		camHUD = new FlxCamera();
		camHUD.bgColor.alpha = 0;

		FlxG.cameras.reset(camGame);
		FlxG.cameras.add(camHUD);
		FlxCamera.defaultCameras = [camGame];

		// default song
		if (SONG == null)
			SONG = Song.loadFromJson('stress-hard', 'stress');

		Conductor.mapBPMChanges(SONG);
		Conductor.changeBPM(SONG.bpm);

		// call the song's stage if it exists
		if (SONG.stage != null)
			curStage = SONG.stage;
		// set up a class for the stage type in here afterwards
		stageBuild = new Stage(curStage);
		add(stageBuild);

		/*
			Everything related to the stages aside from things done after are set in the stage class!
			this means that the girlfriend's type, boyfriend's position, dad's position, are all there

			It serves to clear clutter and can easily be destroyed later. The problem is,
			I don't actually know if this is optimised, I just kinda roll with things and hope
			they work. I'm not actually really experienced compared to a lot of other developers in the scene, 
			so I don't really know what I'm doing, I'm just hoping I can make a better and more optimised 
			engine for both myself and other modders to use!
		 */

		// set up characters here too
		gf = new Character(400, 130, stageBuild.returnGFtype(curStage));
		gf.scrollFactor.set(0.95, 0.95);

		dadOpponent = new Character(100, 100, SONG.player2);
		boyfriend = new Boyfriend(770, 450, SONG.player1);

		var camPos:FlxPoint = new FlxPoint(dadOpponent.getGraphicMidpoint().x, dadOpponent.getGraphicMidpoint().y);

		// set the dadOpponent's position (check the stage class to edit that!)
		// reminder that this probably isn't the best way to do this but hey it works I guess and is cleaner
		stageBuild.dadPosition(curStage, dadOpponent, gf, camPos, SONG.player2);
		// test
		// stageBuild.dadPosition(curStage, boyfriend, gf, camPos, SONG.player1);

		// reposition characters
		stageBuild.repositionPlayers(curStage, boyfriend, dadOpponent, gf);

		// add characters
		add(gf);

		// add limo cus dumb layering
		if (curStage == 'highway')
			add(stageBuild.limo);

		add(dadOpponent);
		add(boyfriend);

		// set song position before beginning
		Conductor.songPosition = -5000;

		// create strums and ui elements
		strumLine = new FlxTypedGroup<FlxSprite>();
		for (i in 0...8)
		{
			var strumLinePart = new FlxSprite(0, 50).makeGraphic(FlxG.width, 10);
			strumLinePart.scrollFactor.set();

			strumLine.add(strumLinePart);
		}

		strumLineNotes = new FlxTypedGroup<UIBabyArrow>();
		add(strumLineNotes);

		boyfriendStrums = new FlxTypedGroup<UIBabyArrow>();
		dadStrums = new FlxTypedGroup<UIBabyArrow>();

		// generate the song
		generateSong(SONG.song);

		// create the game camera
		camFollow = new FlxObject(0, 0, 1, 1);
		camFollow.setPosition(camPos.x, camPos.y);
		// check if the camera was following someone previouslyw
		if (prevCamFollow != null)
		{
			camFollow = prevCamFollow;
			prevCamFollow = null;
		}

		add(camFollow);

		// set up camera dependencies (so that ui elements correspond to their cameras and such)
		strumLineNotes.cameras = [camHUD];
		notes.cameras = [camHUD];

		// actually set the camera up
		FlxG.camera.follow(camFollow, LOCKON, 0.02);
		// FlxG.camera.setScrollBounds(0, FlxG.width, 0, FlxG.height);
		FlxG.camera.zoom = defaultCamZoom;
		FlxG.camera.focusOn(camFollow.getPosition());

		// initialize ui elements
		var uiHUD:ClassHUD = new ClassHUD();
		add(uiHUD);
		uiHUD.cameras = [camHUD];
		//

		startingSong = true;

		startCountdown();
		super.create();
	}

	var canAscend = false;

	override public function update(elapsed:Float)
	{
		// pause the game if the game is allowed to pause and enter is pressed
		if (FlxG.keys.justPressed.ENTER && startedCountdown && canPause)
		{
			// update drawing stuffs
			persistentUpdate = false;
			persistentDraw = true;
			paused = true;

			// open pause substate
			openSubState(new PauseSubState(boyfriend.getScreenPosition().x, boyfriend.getScreenPosition().y));

			#if desktop
			// DiscordClient.changePresence(detailsPausedText, SONG.song + " (" + storyDifficultyText + ")", iconRPC);
			#end
		}

		super.update(elapsed);

		// charting state (more on that later)
		if (FlxG.keys.justPressed.SEVEN)
			FlxG.switchState(new ChartingState());

		if (FlxG.keys.justPressed.SIX)
			boyfriendAutoplay = !boyfriendAutoplay;

		if (FlxG.keys.justPressed.FIVE)
			canAscend = true;

		if (canAscend)
			boyfriend.y -= 50;

		///*
		if (startingSong)
		{
			if (startedCountdown)
			{
				Conductor.songPosition += FlxG.elapsed * 1000;
				if (Conductor.songPosition >= 0)
					startSong();
			}
		}
		else
		{
			// Conductor.songPosition = FlxG.sound.music.time;
			Conductor.songPosition += FlxG.elapsed * 1000;

			if (!paused)
			{
				songTime += FlxG.game.ticks - previousFrameTime;
				previousFrameTime = FlxG.game.ticks;

				// Interpolation type beat
				if (Conductor.lastSongPos != Conductor.songPosition)
				{
					songTime = (songTime + Conductor.songPosition) / 2;
					Conductor.lastSongPos = Conductor.songPosition;
					// Conductor.songPosition += FlxG.elapsed * 1000;
					// trace('MISSED FRAME');
				}
			}

			// Conductor.lastSongPos = FlxG.sound.music.time;
		}

		// boyfriend.playAnim('singLEFT', true);
		// */

		// camera controls and stuffs
		if (generatedMusic && PlayState.SONG.notes[Std.int(curStep / 16)] != null)
		{
			// if must hit section
			if (!PlayState.SONG.notes[Std.int(curStep / 16)].mustHitSection)
			{
				camFollow.setPosition(dadOpponent.getMidpoint().x + 150 + (camDisplaceX * 8), dadOpponent.getMidpoint().y - 100);
			}
			else
			{
				camFollow.setPosition(boyfriend.getMidpoint().x - 100 + (camDisplaceX * 8), boyfriend.getMidpoint().y - 100);
			}
		}

		if (camZooming)
		{
			FlxG.camera.zoom = FlxMath.lerp(defaultCamZoom, FlxG.camera.zoom, 0.95);
			camHUD.zoom = FlxMath.lerp(1, camHUD.zoom, 0.95);
		}

		// spawn in the notes from the array
		if (unspawnNotes[0] != null)
		{
			if (unspawnNotes[0].strumTime - Conductor.songPosition < 1500)
			{
				var dunceNote:Note = unspawnNotes[0];
				notes.add(dunceNote);

				var index:Int = unspawnNotes.indexOf(dunceNote);
				unspawnNotes.splice(index, 1);
			}
		}

		// handle all of the note calls
		noteCalls();
	}

	//----------------------------------------------------------------
	//
	//
	//
	//	this is just a divider, move long.
	//
	//
	//
	//----------------------------------------------------------------

	private function mainControls(daNote:Note, char:Character, autoplay:Bool, ?otherSide:Int = 0):Void
	{
		// call character type for later I'm so sorry this is painful
		var charCallType:Int = 0;
		if (char == boyfriend)
			charCallType = 1;

		// uh if condition from the original game
		// I have no idea what I have done

		// im very sorry for this if condition I made it worse lmao
		///*
		if (daNote.isSustainNote
			&& daNote.y + daNote.offset.y <= strumLine.members[Math.floor(daNote.noteData + (otherSide * 4))].y + Note.swagWidth / 2
			&& (autoplay || (daNote.wasGoodHit || (daNote.prevNote.wasGoodHit && !daNote.canBeHit))))
		{
			var swagRect = new FlxRect(0, strumLine.members[Math.floor(daNote.noteData + (otherSide * 4))].y + Note.swagWidth / 2 - daNote.y,
				daNote.width * 2, daNote.height * 2);
			swagRect.y /= daNote.scale.y;
			swagRect.height -= swagRect.y;

			daNote.clipRect = swagRect;
		}
		// */

		// here I'll set up the autoplay functions
		if (autoplay)
		{
			// check if the note was a good hit
			if (daNote.strumTime <= Conductor.songPosition)
			{
				// use a switch thing cus it feels right idk lol
				// make sure the strum is played for the autoplay stuffs
				switch (charCallType)
				{
					case 1:
						boyfriendStrums.forEach(function(cStrum:UIBabyArrow)
						{
							strumCallsAuto(cStrum, 0, daNote);
						});
					default:
						dadStrums.forEach(function(cStrum:UIBabyArrow)
						{
							strumCallsAuto(cStrum, 0, daNote);
						});
				}

				// animations stuffs
				// alright so we determine which animation needs to play
				var stringArrow:String = '';
				stringArrow = UIBabyArrow.getArrowFromNumber(daNote.noteData);
				char.playAnim('sing' + stringArrow.toUpperCase(), true);

				char.holdTimer = 0;
				//

				// make sure voices are called properly
				if (SONG.needsVoices)
					vocals.volume = 1;

				// kill the note, then remove it from the array
				daNote.kill();
				notes.remove(daNote, true);
				daNote.destroy();
			}
			//
		}

		// unoptimised asf camera control based on strums
		switch (charCallType)
		{
			case 1:
				strumCameraRoll(boyfriendStrums, true);
			default:
				strumCameraRoll(dadStrums, false);
		}
	}

	//----------------------------------------------------------------
	//
	//
	//
	//	strum calls auto
	//
	//
	//
	//----------------------------------------------------------------

	private function strumCallsAuto(cStrum:UIBabyArrow, ?callType:Int = 1, ?daNote:Note):Void
	{
		switch (callType)
		{
			case 1:
				// end the animation if the calltype is 1 and it is done
				if ((cStrum.animation.finished) && (cStrum.canFinishAnimation))
					cStrum.playAnim('static');
			default:
				// check if it is the correct strum
				if (daNote.noteData == cStrum.ID)
				{
					// if (cStrum.animation.curAnim.name != 'confirm')
					cStrum.playAnim('confirm'); // play the correct strum's confirmation animation (haha rhymes)

					// stuff for sustain notes
					if ((daNote.isSustainNote) && (!daNote.animation.curAnim.name.endsWith('holdend')))
						cStrum.canFinishAnimation = false; // basically, make it so the animation can't be finished if there's a sustain note below
					else
						cStrum.canFinishAnimation = true;
				}
		}
	}

	private function strumCameraRoll(cStrum:FlxTypedGroup<UIBabyArrow>, mustHit:Bool)
	{
		var camDisplaceExtend:Float = 1.5;
		var camDisplaceSpeed = 0.0125;
		if (PlayState.SONG.notes[Std.int(curStep / 16)] != null)
		{
			if ((PlayState.SONG.notes[Std.int(curStep / 16)].mustHitSection && mustHit)
				|| (!PlayState.SONG.notes[Std.int(curStep / 16)].mustHitSection && !mustHit))
			{
				if ((cStrum.members[0].animation.curAnim.name == 'confirm') && (camDisplaceX > -camDisplaceExtend))
					camDisplaceX -= camDisplaceSpeed;
				else if ((cStrum.members[3].animation.curAnim.name == 'confirm') && (camDisplaceX < camDisplaceExtend))
					camDisplaceX += camDisplaceSpeed;
			}
		}
	}

	//----------------------------------------------------------------
	//
	//
	//
	//
	//	idk I just need these cus the code is killing me
	//  I wanna see where the lines are for different functions
	//
	//
	//
	//----------------------------------------------------------------

	private function noteCalls():Void
	{
		// get ready for nested script calls!

		// set up the controls for later usage
		// (control stuffs don't go here they go in noteControls(), I just have them here so I don't call them every. single. time. noteControls() is called)
		var up = controls.UP;
		var right = controls.RIGHT;
		var down = controls.DOWN;
		var left = controls.LEFT;

		var upP = controls.UP_P;
		var rightP = controls.RIGHT_P;
		var downP = controls.DOWN_P;
		var leftP = controls.LEFT_P;

		var upR = controls.UP_R;
		var rightR = controls.RIGHT_R;
		var downR = controls.DOWN_R;
		var leftR = controls.LEFT_R;

		var holdControls = [left, down, up, right];
		var pressControls = [leftP, downP, upP, rightP];
		var releaseControls = [leftR, downR, upR, rightR];

		// handle strumline stuffs
		for (i in 0...strumLine.length)
			strumLine.members[i].y = strumLineNotes.members[i].y + 25;

		// reset strums
		for (i in 0...4)
		{
			boyfriendStrums.forEach(function(cStrum:UIBabyArrow)
			{
				if (boyfriendAutoplay)
					strumCallsAuto(cStrum);
			});
			dadStrums.forEach(function(cStrum:UIBabyArrow)
			{
				if (dadAutoplay)
					strumCallsAuto(cStrum);
			});
		}

		// if the song is generated
		if (generatedMusic)
		{
			// nested script #1
			controlPlayer(boyfriend, boyfriendAutoplay, boyfriendStrums, holdControls, pressControls, releaseControls);
			// controlPlayer(dadOpponent, dadAutoplay, dadStrums, holdControls, pressControls, releaseControls, false);

			// call every single note that exists!
			notes.forEachAlive(function(daNote:Note)
			{
				// ya so this might be a lil unoptimised so I'm gonna keep it to a minimum with the calls honestly I'd rather not do them a lot

				// first we wanna orient the note positions.
				// lord forgive me for what I'm about to do but I can't use booleans as integers

				// don't follow this it's hellaaaa stupid code
				var otherSide = 0;
				var otherSustain:Float = 0;
				if (daNote.mustPress)
					otherSide = 1;
				if (daNote.isSustainNote)
					otherSustain = daNote.width;

				// set the notes x and y
				daNote.y = (strumLine.members[Math.floor(daNote.noteData + (otherSide * 4))].y
					- (Conductor.songPosition - daNote.strumTime) * (0.45 * FlxMath.roundDecimal(SONG.speed, 2)));
				daNote.x = strumLineNotes.members[Math.floor(daNote.noteData + (otherSide * 4))].x + 25 + otherSustain;

				// also set note rotation
				if (daNote.isSustainNote == false)
					daNote.angle = strumLineNotes.members[Math.floor(Math.abs(daNote.noteData))].angle;

				// hell breaks loose here, we're using nested scripts!
				// get the note lane and run the corresponding script
				///*
				if (daNote.mustPress)
					mainControls(daNote, boyfriend, boyfriendAutoplay, otherSide);
				else
					mainControls(daNote, dadOpponent, dadAutoplay); // dadOpponent autoplay is true by default and should be true unless neccessary
				// */

				// check where the note is and make sure it is either active or inactive
				if (daNote.y > FlxG.height)
				{
					daNote.active = false;
					daNote.visible = false;
				}
				else
				{
					daNote.visible = true;
					daNote.active = true;
				}

				// if the note is off screen (above)
				if (daNote.y < -daNote.height)
				{
					if (daNote.tooLate || !daNote.wasGoodHit)
						vocals.volume = 0;

					daNote.active = false;
					daNote.visible = false;

					// note damage here I guess
					daNote.kill();
					notes.remove(daNote, true);
					daNote.destroy();
				}
			});
			//
		}
	}

	// good notes hit

	function controlPlayer(character:Character, autoplay:Bool, characterStrums:FlxTypedGroup<UIBabyArrow>, holdControls:Array<Bool>,
			pressControls:Array<Bool>, releaseControls:Array<Bool>, ?mustPress = true)
	{
		if (!autoplay)
		{
			// check if anything is pressed
			if (pressControls.contains(true))
			{
				// reset holdtimer bitch
				character.holdTimer = 0;

				// array of notes
				var possibleNoteList:Array<Note> = [];
				var noteDirectionList:Array<Int> = [];

				notes.forEachAlive(function(daNote:Note)
				{
					if (daNote.canBeHit && daNote.mustPress && !daNote.tooLate && !daNote.wasGoodHit)
					{
						possibleNoteList.push(daNote);
						possibleNoteList.sort((a, b) -> Std.int(a.strumTime - b.strumTime));

						noteDirectionList.push(daNote.noteData);
					}
				});

				// check all of the controls
				for (i in 0...pressControls.length)
				{
					// if there is a list of notes that exists for that control
					if (possibleNoteList.length > 0)
					{
						// loop through the possible notes
						for (coolNote in possibleNoteList)
						{
							// and if a note is being pressed
							if (pressControls[coolNote.noteData])
								goodNoteHit(coolNote, character, characterStrums); // then hit the note
							// end of this little check
						}
						//
					}
					else
						missNoteCheck(i, pressControls, character); // else just call bad notes
					//
				}
				//
			}

			// check if anything is held
			if (holdControls.contains(true))
			{
				// check notes that are alive
				notes.forEachAlive(function(coolNote:Note)
				{
					if (coolNote.canBeHit && coolNote.mustPress && coolNote.isSustainNote && holdControls[coolNote.noteData])
						goodNoteHit(coolNote, character, characterStrums);
				});
			}

			// control camera movements
			// strumCameraRoll(characterStrums, true);

			characterStrums.forEach(function(strum:UIBabyArrow)
			{
				if ((pressControls[strum.ID]) && (strum.animation.curAnim.name != 'confirm'))
					strum.playAnim('pressed');
				if (releaseControls[strum.ID])
					strum.playAnim('static');
				//
			});
		}

		// reset bf's animation
		if (character.holdTimer > Conductor.stepCrochet * 4 * 0.001 && (!holdControls.contains(true) || autoplay))
		{
			if (character.animation.curAnim.name.startsWith('sing') && !character.animation.curAnim.name.endsWith('miss'))
				character.dance();
		}
	}

	function popUpScore(strumTime:Float)
	{
		vocals.volume = 1;
	}

	function goodNoteHit(coolNote:Note, character:Character, characterStrums:FlxTypedGroup<UIBabyArrow>)
	{
		if (!coolNote.wasGoodHit)
		{
			coolNote.wasGoodHit = true;
			vocals.volume = 1;

			if (!coolNote.isSustainNote)
			{
				popUpScore(coolNote.strumTime);
				combo += 1;
			}

			var stringDirection = UIBabyArrow.getArrowFromNumber(coolNote.noteData);
			character.playAnim('sing' + stringDirection.toUpperCase());

			characterStrums.members[coolNote.noteData].playAnim('confirm', true);

			if (!coolNote.isSustainNote)
			{
				coolNote.kill();
				notes.remove(coolNote, true);
				coolNote.destroy();
			}
			//
		}
	}

	function missNoteCheck(direction:Int = 0, pressControls:Array<Bool>, character:Character)
	{
		if (pressControls[direction])
		{
			var stringDirection:String = UIBabyArrow.getArrowFromNumber(direction);

			FlxG.sound.play(Paths.soundRandom('missnote', 1, 3), FlxG.random.float(0.1, 0.2));
			character.playAnim('sing' + stringDirection.toUpperCase() + 'miss');

			if (combo > 0)
				combo = 0; // bitch
		}
	}

	//
	//
	//
	//	please spare me
	//
	//

	function startSong():Void
	{
		startingSong = false;

		previousFrameTime = FlxG.game.ticks;
		lastReportedPlayheadPosition = 0;

		if (!paused)
			FlxG.sound.playMusic(Paths.inst(SONG.song), 1, false);
		// FlxG.sound.music.onComplete = endSong; // set the script to end the song (I'll rewrite this too)
		vocals.play();

		#if desktop
		// Song duration in a float, useful for the time left feature
		songLength = FlxG.sound.music.length;

		// Updating Discord Rich Presence (with Time Left)
		// DiscordClient.changePresence(detailsText, SONG.song + " (" + storyDifficultyText + ")", iconRPC, true, songLength);
		#end
	}

	private function generateSong(dataPath:String):Void
	{
		// FlxG.log.add(ChartParser.parse());

		var songData = SONG;
		Conductor.changeBPM(songData.bpm);

		curSong = songData.song;

		if (SONG.needsVoices)
			vocals = new FlxSound().loadEmbedded(Paths.voices(PlayState.SONG.song));
		else
			vocals = new FlxSound();

		FlxG.sound.list.add(vocals);

		notes = new FlxTypedGroup<Note>();
		add(notes);

		var noteData:Array<SwagSection>;
		noteData = songData.notes;

		var playerCounter:Int = 0;

		var daBeats:Int = 0; // Not exactly representative of 'daBeats' lol, just how much it has looped
		for (section in noteData)
		{
			var coolSection:Int = Std.int(section.lengthInSteps / 4);

			for (songNotes in section.sectionNotes)
			{
				var daStrumTime:Float = songNotes[0];
				var daNoteData:Int = Std.int(songNotes[1] % 4);
				// define note types!
				var daNoteType:Float = 0;
				// check if the array is longer than 3 (so if song note types are defined)
				if (songNotes.length > 2)
					daNoteType = songNotes[3];

				var gottaHitNote:Bool = section.mustHitSection;

				if (songNotes[1] > 3)
				{
					gottaHitNote = !section.mustHitSection;
				}

				var oldNote:Note;
				if (unspawnNotes.length > 0)
					oldNote = unspawnNotes[Std.int(unspawnNotes.length - 1)];
				else
					oldNote = null;

				var swagNote:Note = new Note(daStrumTime, daNoteData, daNoteType, oldNote);
				swagNote.sustainLength = songNotes[2];
				swagNote.scrollFactor.set(0, 0);

				var susLength:Float = swagNote.sustainLength;

				susLength = susLength / Conductor.stepCrochet;
				unspawnNotes.push(swagNote);

				for (susNote in 0...Math.floor(susLength))
				{
					oldNote = unspawnNotes[Std.int(unspawnNotes.length - 1)];

					var sustainNote:Note = new Note(daStrumTime + (Conductor.stepCrochet * susNote) + Conductor.stepCrochet, daNoteData, daNoteType, oldNote,
						true);
					sustainNote.scrollFactor.set();
					unspawnNotes.push(sustainNote);

					sustainNote.mustPress = gottaHitNote;

					if (sustainNote.mustPress)
					{
						sustainNote.x += FlxG.width / 2; // general offset
					}
				}

				swagNote.mustPress = gottaHitNote;

				if (swagNote.mustPress)
				{
					swagNote.x += FlxG.width / 2; // general offset
				}
				// else {}
			}
			daBeats += 1;
		}

		// trace(unspawnNotes.length);
		// playerCounter += 1;

		unspawnNotes.sort(sortByShit);

		generatedMusic = true;
	}

	function sortByShit(Obj1:Note, Obj2:Note):Int
	{
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1.strumTime, Obj2.strumTime);
	}

	private function startCountdown():Void
	{
		generateStaticArrows(0);
		generateStaticArrows(1);

		startedCountdown = true;
		Conductor.songPosition = 0;
		Conductor.songPosition -= Conductor.crochet * 5;

		var swagCounter:Int = 0;

		startTimer = new FlxTimer().start(Conductor.crochet / 1000, function(tmr:FlxTimer)
		{
			dadOpponent.dance();
			gf.dance();
			boyfriend.dance();

			var introAssets:Map<String, Array<String>> = new Map<String, Array<String>>();
			introAssets.set('default', ['ready', "set", "go"]);
			introAssets.set('school', ['weeb/pixelUI/ready-pixel', 'weeb/pixelUI/set-pixel', 'weeb/pixelUI/date-pixel']);
			introAssets.set('schoolEvil', ['weeb/pixelUI/ready-pixel', 'weeb/pixelUI/set-pixel', 'weeb/pixelUI/date-pixel']);

			var introAlts:Array<String> = introAssets.get('default');
			var altSuffix:String = "";

			for (value in introAssets.keys())
			{
				if (value == curStage)
				{
					introAlts = introAssets.get(value);
					altSuffix = '-pixel';
				}
			}

			switch (swagCounter)
			{
				case 0:
					FlxG.sound.play(Paths.sound('intro3'), 0.6);
				case 1:
					var ready:FlxSprite = new FlxSprite().loadGraphic(Paths.image(introAlts[0]));
					ready.scrollFactor.set();
					ready.updateHitbox();

					if (curStage.startsWith('school'))
						ready.setGraphicSize(Std.int(ready.width * daPixelZoom));

					ready.screenCenter();
					add(ready);
					FlxTween.tween(ready, {y: ready.y += 100, alpha: 0}, Conductor.crochet / 1000, {
						ease: FlxEase.cubeInOut,
						onComplete: function(twn:FlxTween)
						{
							ready.destroy();
						}
					});
					FlxG.sound.play(Paths.sound('intro2'), 0.6);
				case 2:
					var set:FlxSprite = new FlxSprite().loadGraphic(Paths.image(introAlts[1]));
					set.scrollFactor.set();

					if (curStage.startsWith('school'))
						set.setGraphicSize(Std.int(set.width * daPixelZoom));

					set.screenCenter();
					add(set);
					FlxTween.tween(set, {y: set.y += 100, alpha: 0}, Conductor.crochet / 1000, {
						ease: FlxEase.cubeInOut,
						onComplete: function(twn:FlxTween)
						{
							set.destroy();
						}
					});
					FlxG.sound.play(Paths.sound('intro1'), 0.6);
				case 3:
					var go:FlxSprite = new FlxSprite().loadGraphic(Paths.image(introAlts[2]));
					go.scrollFactor.set();

					if (curStage.startsWith('school'))
						go.setGraphicSize(Std.int(go.width * daPixelZoom));

					go.updateHitbox();

					go.screenCenter();
					add(go);
					FlxTween.tween(go, {y: go.y += 100, alpha: 0}, Conductor.crochet / 1000, {
						ease: FlxEase.cubeInOut,
						onComplete: function(twn:FlxTween)
						{
							go.destroy();
						}
					});
					FlxG.sound.play(Paths.sound('introGo'), 0.6);
				case 4:
			}

			swagCounter += 1;
			// generateSong('fresh');
		}, 5);
	}

	private function generateStaticArrows(player:Int):Void
	{
		for (i in 0...4)
		{
			// FlxG.log.add(i);
			// var babyArrow:FlxSprite = new FlxSprite(0, strumLine.y);
			var babyArrow:UIBabyArrow = new UIBabyArrow(0, strumLine.members[Math.floor(i + (player * 4))].y - 25, i);

			babyArrow.ID = i; // + (player * 4);

			switch (player)
			{
				case 1:
					boyfriendStrums.add(babyArrow);
				default:
					dadStrums.add(babyArrow);
			}

			babyArrow.y -= 10;
			babyArrow.alpha = 0;
			FlxTween.tween(babyArrow, {y: babyArrow.y + 10, alpha: 1}, 1, {ease: FlxEase.circOut, startDelay: 0.5 + (0.2 * i)});

			babyArrow.x += 75;
			babyArrow.x += Note.swagWidth * i;
			babyArrow.x += ((FlxG.width / 2) * player);

			babyArrow.x = Math.floor(babyArrow.x);
			babyArrow.y = Math.floor(babyArrow.y);

			babyArrow.playAnim('static');
			strumLineNotes.add(babyArrow);
		}
		//
	}

	//
	// I need some space okay? this code is claustrophobic as hell
	//

	function resyncVocals():Void
	{
		vocals.pause();

		FlxG.sound.music.play();
		Conductor.songPosition = FlxG.sound.music.time;
		vocals.time = Conductor.songPosition;
		vocals.play();
	}

	override function stepHit()
	{
		super.stepHit();
		///*
		if (FlxG.sound.music.time > Conductor.songPosition + 20 || FlxG.sound.music.time < Conductor.songPosition - 20)
		{
			resyncVocals();
		}
		//*/
	}

	override function beatHit()
	{
		super.beatHit();

		if (generatedMusic)
		{
			notes.sort(FlxSort.byY, FlxSort.DESCENDING);
		}

		if (camZooming && FlxG.camera.zoom < 1.35 && curBeat % 4 == 0)
		{
			FlxG.camera.zoom += 0.015;
			camHUD.zoom += 0.05;
		}

		if (curBeat % gfSpeed == 0)
			gf.dance();

		if (!boyfriend.animation.curAnim.name.startsWith("sing"))
		{
			boyfriend.dance();
		}

		// added this for opponent cus it wasn't here before and skater would just freeze
		if (!dadOpponent.animation.curAnim.name.startsWith("sing"))
		{
			dadOpponent.dance();
		}

		// stage stuffs
		stageBuild.stageUpdate();
	}

	//
	/// substate stuffs
	//
	//
	override function openSubState(SubState:FlxSubState)
	{
		if (paused)
		{
			if (FlxG.sound.music != null)
			{
				FlxG.sound.music.pause();
				vocals.pause();
			}

			if (!startTimer.finished)
				startTimer.active = false;
		}

		super.openSubState(SubState);
	}

	override function closeSubState()
	{
		if (paused)
		{
			if (FlxG.sound.music != null && !startingSong)
			{
				resyncVocals();
			}

			if (!startTimer.finished)
				startTimer.active = true;
			paused = false;

			/*
				#if desktop
				if (startTimer.finished)
				{
					DiscordClient.changePresence(detailsText, SONG.song + " (" + storyDifficultyText + ")", iconRPC, true, songLength - Conductor.songPosition);
				}
				else
				{
					DiscordClient.changePresence(detailsText, SONG.song + " (" + storyDifficultyText + ")", iconRPC);
				}
				#end
				// */
		}

		super.closeSubState();
	}
}
