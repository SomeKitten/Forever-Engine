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

	public var downscroll:Bool = true;

	public static var startTimer:FlxTimer;

	private var vocals:FlxSound;

	public static var dadOpponent:Character;
	public static var gf:Character;
	public static var boyfriend:Boyfriend;

	public var boyfriendAutoplay:Bool = false;

	private var dadAutoplay:Bool = true; // this is for testing purposes

	private var notes:FlxTypedGroup<Note>;
	private var unspawnNotes:Array<Note> = [];
	private var ratingArray:Array<String> = [];
	private var allSicks:Bool = true;

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
	private var splashNotes:FlxTypedGroup<NoteSplash>;

	private var gfSpeed:Int = 1;

	public static var health:Float = 1; // mario
	public static var combo:Int = 0;
	public static var misses:Int = 0;

	private var generatedMusic:Bool = false;
	private var startingSong:Bool = false;
	private var paused:Bool = false;
	var startedCountdown:Bool = false;
	var canPause:Bool = true;

	var previousFrameTime:Int = 0;
	var lastReportedPlayheadPosition:Int = 0;
	var songTime:Float = 0;

	private var camHUD:FlxCamera;

	public static var camGame:FlxCamera;

	private var camDisplaceX:Float = 0;
	private var camDisplaceY:Float = 0; // might not use depending on result

	public static var defaultCamZoom:Float = 1.05;

	private var camZooming:Bool = true;

	public static var songScore:Int = 0;

	var storyDifficultyText:String = "";
	var iconRPC:String = "";
	var songLength:Float = 0;

	public var stageBuild:Stage;

	public var uiHUD:ClassHUD;

	public static var daPixelZoom:Float = 6;
	public static var isPixel:Bool = false;
	public static var determinedChartType:String = "";

	// at the beginning of the playstate
	override public function create()
	{
		// reset any values and variables that are static
		songScore = 0;
		combo = 0;
		health = 1;
		misses = 0;

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
			SONG = Song.loadFromJson('fresh-hard', 'fresh');

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

		/// here we determine the chart type!
		// determine the chart type here
		determinedChartType = "";

		//

		// set the dadOpponent's position (check the stage class to edit that!)
		// reminder that this probably isn't the best way to do this but hey it works I guess and is cleaner
		stageBuild.dadPosition(curStage, dadOpponent, gf, camPos, SONG.player2);

		// I don't like the way I'm doing this, but basically hardcode stages to charts if the chart type is the base fnf one
		// (forever engine charts will have non hardcoded stages)
		if ((curStage.startsWith("school")) && ((determinedChartType == "") || (determinedChartType == "FNF")))
			isPixel = true;

		// isPixel = true;

		// reposition characters
		stageBuild.repositionPlayers(curStage, boyfriend, dadOpponent, gf);

		// add characters
		add(gf);

		// add limo cus dumb layering
		if (curStage == 'highway')
			add(stageBuild.limo);

		add(dadOpponent);
		add(boyfriend);

		// force them to dance
		dadOpponent.dance();
		gf.dance();
		boyfriend.dance();

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

		// set up the elements for the notes
		strumLineNotes = new FlxTypedGroup<UIBabyArrow>();
		add(strumLineNotes);

		// now splash notes
		splashNotes = new FlxTypedGroup<NoteSplash>();
		add(splashNotes);

		// and now the note strums
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
		splashNotes.cameras = [camHUD];
		notes.cameras = [camHUD];

		// actually set the camera up
		FlxG.camera.follow(camFollow, LOCKON, 0.02);
		FlxG.camera.zoom = defaultCamZoom;
		FlxG.camera.focusOn(camFollow.getPosition());

		FlxG.worldBounds.set(0, 0, FlxG.width, FlxG.height);

		// initialize ui elements
		startingSong = true;
		startedCountdown = true;

		for (i in 0...2)
			generateStaticArrows(i);

		var uiHUD:ClassHUD = new ClassHUD();
		add(uiHUD);
		uiHUD.cameras = [camHUD];

		//

		super.create();
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);

		if (health > 2)
			health = 2;

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

		// charting state (more on that later)
		if (FlxG.keys.justPressed.SEVEN)
		{
			Main.mainClassState = ChartingState;
			FlxG.switchState(new ChartingState());
		}

		if (FlxG.keys.justPressed.SIX)
			boyfriendAutoplay = !boyfriendAutoplay;

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

			// song shit for testing lols

			/*

				var shitBeat = (Conductor.songPosition / 1000) * (Conductor.bpm / 60);
				var swirlInterval:Float = curBeat;
				for (i in 0...strumLineNotes.length)
				{
					strumLineNotes.members[i].y = strumLineNotes.members[i].initialY + swirlInterval * Math.cos((shitBeat + i * 0.25) * Math.PI);
					strumLineNotes.members[i].x = strumLineNotes.members[i].initialX + swirlInterval * Math.sin((shitBeat + i * 0.25) * Math.PI);
				}

				// */
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
			if (unspawnNotes[0].strumTime - Conductor.songPosition < 3500)
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
			if (daNote.strumTime < Conductor.songPosition)
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
				var altString:String = '';
				if (daNote.noteAlt > 0)
					altString = '-alt';

				stringArrow = 'sing' + UIBabyArrow.getArrowFromNumber(daNote.noteData).toUpperCase() + altString;
				if (daNote.noteString != "")
					stringArrow = daNote.noteString;

				char.playAnim(stringArrow, true);

				char.holdTimer = 0;
				//

				// make sure voices are called properly
				if (SONG.needsVoices)
					vocals.volume = 1;

				// kill the note, then remove it from the array
				if (charCallType == 1)
				{
					var canDisplayRating = true;
					for (noteDouble in notesPressedAutoplay)
					{
						if (noteDouble.noteData == daNote.noteData)
						{
							// if (Math.abs(noteDouble.strumTime - daNote.strumTime) < 10)
							canDisplayRating = false;
							//
						}
						//
					}
					notesPressedAutoplay.push(daNote);

					if ((!daNote.isSustainNote) && (canDisplayRating))
					{
						increaseCombo();
						popUpScore(daNote.strumTime, daNote);
						health += 0.023;
					}
					else if ((daNote.isSustainNote) && (canDisplayRating))
						health += 0.004;
				}
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
	// call a note array
	public var notesPressedAutoplay:Array<Note> = [];

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

		for (i in 0...splashNotes.length)
		{
			// splash note positions
			splashNotes.members[i].x = strumLineNotes.members[i + 4].x - 48;
			splashNotes.members[i].y = strumLineNotes.members[i + 4].y - 56;
		}

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

			notesPressedAutoplay = [];
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
					{
						health -= 0.0475;
						vocals.volume = 0;

						// I'll ask pixl if this is wrong and if he says yes I'll remove it
						decreaseCombo();
					}

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
				var possibleNoteList:Array<Note> = [];
				var pressedNotes:Array<Note> = [];

				notes.forEachAlive(function(daNote:Note)
				{
					if (daNote.canBeHit && daNote.mustPress && !daNote.tooLate && !daNote.wasGoodHit)
					{
						possibleNoteList.push(daNote);
						possibleNoteList.sort((a, b) -> Std.int(a.strumTime - b.strumTime));
					}
				});

				// check all of the controls
				for (i in 0...pressControls.length)
				{
					// if there is a list of notes that exists for that control
					if (possibleNoteList.length > 0)
					{
						var eligable = true;
						// this may be impractical, but I want overlayed notes to be played, just not count towards score or combo
						// this is so that they run code and stuff
						var firstNote = true;
						// loop through the possible notes
						for (coolNote in possibleNoteList)
						{
							// and if a note is being pressed
							if (pressControls[coolNote.noteData])
							{
								for (noteDouble in pressedNotes)
									if (noteDouble.noteData == coolNote.noteData)
									{
										if (Math.abs(noteDouble.strumTime - coolNote.strumTime) < 10)
											firstNote = false;
										else
											eligable = false;
									}

								if (eligable)
								{
									goodNoteHit(coolNote, character, characterStrums, firstNote); // then hit the note
									pressedNotes.push(coolNote);
								}
							}
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
		if (character.holdTimer > Conductor.stepCrochet * (4 / 1000) && (!holdControls.contains(true) || autoplay))
		{
			if (character.animation.curAnim.name.startsWith('sing') && !character.animation.curAnim.name.endsWith('miss'))
				character.dance();
		}
	}

	public var ratingTiming:String = "";

	function popUpScore(strumTime:Float, coolNote:Note)
	{
		// just base game but a lil cleaner
		var noteDiff:Float = Math.abs(strumTime - Conductor.songPosition);
		vocals.volume = 1;

		// set up the rating
		var score:Int = 50;

		// call the rating
		// also thanks sammu :mariocool:

		// first one is the reach/chance of that rating, second is the score it gives,
		var daRatings:Map<String, Array<Dynamic>> = [
			"sick" => [null, 350],
			"good" => [0.15, 200],
			"bad" => [0.5, 100],
			"shit" => [0.7, 50],
		];

		var foundRating = false;
		// loop through all avaliable ratings
		var baseRating:String = "sick";
		for (myRating in daRatings.keys())
		{
			if ((daRatings.get(myRating)[0] != null)
				&& (((noteDiff > Conductor.safeZoneOffset * daRatings.get(myRating)[0])) && (!foundRating)))
			{
				// get the timing
				if (strumTime < Conductor.songPosition)
					ratingTiming = "late";
				else
					ratingTiming = "early";

				// call the rating itself
				baseRating = myRating;
				foundRating = true;
			}
		}

		// notesplashes
		if (baseRating == "sick")
		{
			// create the note splash if you hit a sick
			createSplash(coolNote);
		}
		else
		{
			// if it isn't a sick, and you had a sick combo, then it becomes not sick :(
			if (allSicks)
				allSicks = false;
		}

		displayRating(baseRating);
		score = Std.int(daRatings.get(baseRating)[1]);

		songScore += score;

		popUpCombo();
	}

	private var createdColor = FlxColor.fromRGB(255, 145, 150);

	function popUpCombo()
	{
		var pixelModifier:String = "";
		if (isPixel)
			pixelModifier = "pixelUI/";

		var comboString:String = Std.string(combo);
		var negative = false;
		if ((comboString.startsWith('-')) || (combo == 0))
			negative = true;
		var stringArray:Array<String> = comboString.split("");
		for (scoreInt in 0...stringArray.length)
		{
			var numScore:FlxSprite = new FlxSprite().loadGraphic(Paths.image('UI/' + pixelModifier + 'num' + stringArray[scoreInt]));
			numScore.screenCenter();
			numScore.x += (43 * scoreInt) + 20;
			numScore.y += 60;

			if (negative)
				numScore.color = createdColor;

			if (!isPixel)
			{
				numScore.antialiasing = true;
				numScore.setGraphicSize(Std.int(numScore.width * 0.5));
			}
			else
				numScore.setGraphicSize(Std.int(numScore.width * daPixelZoom));

			numScore.updateHitbox();

			numScore.acceleration.y = FlxG.random.int(200, 300);
			numScore.velocity.y -= FlxG.random.int(140, 160);
			numScore.velocity.x = FlxG.random.float(-5, 5);
			add(numScore);

			FlxTween.tween(numScore, {alpha: 0}, 0.2, {
				onComplete: function(tween:FlxTween)
				{
					numScore.destroy();
				},
				startDelay: Conductor.crochet * 0.002
			});
		}
	}

	//
	//
	//

	function decreaseCombo()
	{
		if (combo > 0)
		{
			combo = 0; // bitch lmao
		}
		else
			combo--;

		// misses
		songScore -= 10;
		misses++;

		// display negative combo
		popUpCombo();
	}

	function increaseCombo()
	{
		if (combo < 0)
			combo = 0;
		combo += 1;
	}

	//
	//
	//

	public function createSplash(coolNote:Note)
	{
		// play animation in existing notesplashes
		var noteSplashRandom:String = (Std.string((FlxG.random.int(0, 1) + 1)));
		splashNotes.members[coolNote.noteData].playAnimation('anim' + noteSplashRandom);
	}

	public function displayRating(daRating:String)
	{
		var rating:FlxSprite = new FlxSprite();
		// set a custom color if you have a perfect sick combo
		var perfectSickString:String = "";
		if (allSicks)
			perfectSickString = "-perfect";

		var noTiming:Bool = false;
		if (daRating == "sick")
			noTiming = true;

		var pixelModifier:String = "";
		if (isPixel)
			pixelModifier = "pixelUI/";

		rating.loadGraphic(Paths.image('UI/' + pixelModifier + 'ratings/' + daRating + perfectSickString));
		rating.screenCenter();
		rating.x = (FlxG.width * 0.55) - 40;
		rating.y -= 60;
		rating.acceleration.y = 550;
		rating.velocity.y -= FlxG.random.int(140, 175);
		rating.velocity.x -= FlxG.random.int(0, 10);

		// this has to be loaded after unfortunately as much as I like to condense all of my code down
		if (isPixel)
			rating.setGraphicSize(Std.int(rating.width * daPixelZoom));

		add(rating);

		// ooof this is very bad
		if (!noTiming)
		{
			var timing:FlxSprite = new FlxSprite();

			// rating timing
			// setting the width, it's half of the sprite's width, I don't like doing this but that code scares me in terms of optimisations
			var newWidth = 166;
			if (isPixel)
				newWidth = 26;
			timing.loadGraphic(Paths.image('UI/' + pixelModifier + 'ratings/' + daRating + '-timings'), true, newWidth);
			// this code is quickly becoming painful lmao
			timing.animation.add('early', [0]);
			timing.animation.add('late', [1]);
			timing.animation.play(ratingTiming);

			timing.screenCenter();
			timing.x = rating.x;
			timing.y = rating.y;
			timing.acceleration.y = rating.acceleration.y;
			timing.velocity.y = rating.velocity.y;
			timing.velocity.x = rating.velocity.x;

			// messy messy pixel stuffs
			// but thank you pixl your timings are awesome
			if (isPixel)
			{
				// positions are stupid
				timing.x += (newWidth / 2) * daPixelZoom;
				timing.setGraphicSize(Std.int(timing.width * daPixelZoom));
				if (ratingTiming != 'late')
					timing.x -= newWidth * daPixelZoom;
			}
			else if (ratingTiming == 'late')
				timing.x += newWidth;

			add(timing);

			FlxTween.tween(timing, {alpha: 0}, 0.2, {
				onComplete: function(tween:FlxTween)
				{
					timing.destroy();
				},
				startDelay: Conductor.crochet * 0.002
			});
		}

		///*
		FlxTween.tween(rating, {alpha: 0}, 0.2, {
			onComplete: function(tween:FlxTween)
			{
				rating.destroy();
			},
			startDelay: Conductor.crochet * 0.002
		});
		// */
	}

	function goodNoteHit(coolNote:Note, character:Character, characterStrums:FlxTypedGroup<UIBabyArrow>, ?canDisplayRating:Bool = true)
	{
		if (!coolNote.wasGoodHit)
		{
			coolNote.wasGoodHit = true;
			vocals.volume = 1;

			if ((!coolNote.isSustainNote) && (canDisplayRating))
			{
				increaseCombo();
				popUpScore(coolNote.strumTime, coolNote);
				health += 0.023;
			}
			else if ((coolNote.isSustainNote) && (canDisplayRating))
				health += 0.004;

			var stringArrow:String = '';
			var altString:String = '';
			if (coolNote.noteAlt > 0)
				altString = '-alt';

			stringArrow = 'sing' + UIBabyArrow.getArrowFromNumber(coolNote.noteData).toUpperCase() + altString;
			if (coolNote.noteString != "")
				stringArrow = coolNote.noteString;

			character.playAnim(stringArrow);

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
			health -= 0.0475;
			var stringDirection:String = UIBabyArrow.getArrowFromNumber(direction);

			FlxG.sound.play(Paths.soundRandom('missnote', 1, 3), FlxG.random.float(0.1, 0.2));
			character.playAnim('sing' + stringDirection.toUpperCase() + 'miss');

			decreaseCombo();
			//
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

		// here's where the chart loading takes place
		notes = new FlxTypedGroup<Note>();
		add(notes);

		// generate the chart
		// much simpler looking than in the original game lol
		ChartLoader.generateChartType(determinedChartType);

		// return the unspawned notes that were generated in said chart
		unspawnNotes = ChartLoader.returnUnspawnNotes();

		// sort through them
		unspawnNotes.sort(sortByShit);
		// give the game the heads up to be able to start
		generatedMusic = true;
	}

	function sortByShit(Obj1:Note, Obj2:Note):Int
	{
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1.strumTime, Obj2.strumTime);
	}

	public function generateStaticArrows(player:Int):Void
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

			babyArrow.x += 75;
			babyArrow.x += Note.swagWidth * i;
			babyArrow.x += ((FlxG.width / 2) * player);

			babyArrow.initialX = Math.floor(babyArrow.x);
			babyArrow.initialY = Math.floor(babyArrow.y);

			babyArrow.y -= 10;
			babyArrow.alpha = 0;
			FlxTween.tween(babyArrow, {y: babyArrow.initialY, alpha: 1}, 1, {ease: FlxEase.circOut, startDelay: 0.5 + (0.2 * i)});

			babyArrow.playAnim('static');
			strumLineNotes.add(babyArrow);

			// generate note splashes
			if (player == 1)
			{
				var noteSplash:NoteSplash = new NoteSplash(i);
				noteSplash.x += Note.swagWidth * i;
				noteSplash.x += ((FlxG.width / 2) * player);
				splashNotes.add(noteSplash);
			}
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

	public static function everyoneDance()
	{
		// this is sorta useful I guess for cutscenes and such
		dadOpponent.dance();
		gf.dance();
		boyfriend.dance();
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
		// uiHUD.hudUpdate();
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
