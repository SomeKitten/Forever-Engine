package gameFolder.meta.data;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import gameFolder.gameObjects.Note;
import gameFolder.meta.data.Section.SwagSection;
import gameFolder.meta.data.Song.SwagSong;
import gameFolder.meta.state.ChartingState;
import gameFolder.meta.state.PlayState;

/**
	This is the chartloader class. it loads in charts, but also exports charts, the chart parameters are based on the type of chart, 
	say the base game type loads the base game's charts, the forever chart type loads a custom forever structure chart with custom features,
	and so on. This class will handle both saving and loading of charts with useful features and scripts that will make things much easier
	to handle and load, as well as much more modular!
**/
class ChartLoader
{
	// set up some variables maybe and then public static functions that can be used anywhere
	public static var unspawnNotes:Array<Note> = [];

	// hopefully this makes it easier for people to load and save chart features and such, y'know the deal lol
	public static function generateChartType(?typeOfChart:String = "FNF")
	{
		//
		var songData = PlayState.SONG;
		var noteData:Array<SwagSection>;

		noteData = songData.notes;
		switch (typeOfChart)
		{
			default:
				// load fnf style charts (PRE 2.8)
				var daBeats:Int = 0; // Not exactly representative of 'daBeats' lol, just how much it has looped

				for (section in noteData)
				{
					var coolSection:Int = Std.int(section.lengthInSteps / 4);

					for (songNotes in section.sectionNotes)
					{
						var daStrumTime:Float = songNotes[0];
						var daNoteData:Int = Std.int(songNotes[1] % 4);
						// define the note's animation (in accordance to the original game)!
						var daNoteAlt:Float = 0;

						// very stupid but I'm lazy
						if (songNotes.length > 2)
							daNoteAlt = songNotes[3];
						/*
							rest of this code will be mostly unmodified, I don't want to interfere with how FNF chart loading works
							I'll keep all of the extra features in forever charts, which you'll be able to convert and export to very easily using
							the in engine editor 

							I'll be doing my best to comment the work below but keep in mind I didn't originally write it
						 */

						// check the base section
						var gottaHitNote:Bool = section.mustHitSection;

						// if the note is on the other side, flip the base section of the note
						if (songNotes[1] > 3)
							gottaHitNote = !section.mustHitSection;

						// define the note that comes before (previous note)
						var oldNote:Note;
						if (unspawnNotes.length > 0)
							oldNote = unspawnNotes[Std.int(unspawnNotes.length - 1)];
						else // if it exists, that is
							oldNote = null;

						// create the new note
						var swagNote:Note = new Note(daStrumTime, daNoteData, daNoteAlt, 0, "", oldNote);

						// set the note's length (sustain note)
						swagNote.sustainLength = songNotes[2];
						swagNote.scrollFactor.set(0, 0);
						var susLength:Float = swagNote.sustainLength; // sus amogus

						// adjust sustain length
						susLength = susLength / Conductor.stepCrochet;
						// push the note to the array we'll push later to the playstate
						unspawnNotes.push(swagNote);
						// STOP POSTING ABOUT AMONG US
						// basically said push the sustain notes to the array respectively
						for (susNote in 0...Math.floor(susLength))
						{
							oldNote = unspawnNotes[Std.int(unspawnNotes.length - 1)];
							var sustainNote:Note = new Note(daStrumTime + (Conductor.stepCrochet * susNote) + Conductor.stepCrochet, daNoteData, daNoteAlt, 0,
								"", oldNote, true);
							sustainNote.scrollFactor.set();
							unspawnNotes.push(sustainNote);
							sustainNote.mustPress = gottaHitNote;
							/*
								This is handled in engine anyways, not necessary!
								if (sustainNote.mustPress)
									sustainNote.x += FlxG.width / 2;
							 */
						}
						// oh and set the note's must hit section
						swagNote.mustPress = gottaHitNote;
					}
					daBeats += 1;
				}
			/*
				This is basically the end of this section, of course, it loops through all of the notes it has to,
				But any optimisations and such like the ones sammu is working on won't be handled here, I want to keep this code as
				close to the original as possible with a few tweaks and optimisations because I want to go for the abilities to 
				load charts from the base game, export charts to the base game, and generally handle everything with an accuracy similar to that
				of the main game so it feels like loading things in works well.
			 */
			case 'forever':
				/*
					That being said, however, we also have forever charts, which are complete restructures with new custom features and such.
					Will be useful for projects later on, and it will give you more control over things you can do with the chart and with the game.
					I'll also make it really easy to convert charts, you'll just have to load them in and pick an export option! If you want to play
					songs made in forever engine with the base game then you can do that too.
				 */
		}
	}

	public static function returnUnspawnNotes()
	{
		return unspawnNotes;
	}

	public static function flushUnspawnNotes()
	{
		unspawnNotes = [];
	}

	public static function generateChartingArrows(i:Array<Int>, curSection:Int, _song:SwagSong)
	{
		var GRID_SIZE = ChartingState.GRID_SIZE;
		// note modifiers based on shit like idk the funny chart types
		var daNoteInfo = i[1];
		var daStrumTime = i[0];
		var daSus = i[2];
		var daNoteType = 0;
		var daNoteAlt = 0;

		if (i.length > 2)
			daNoteAlt = i[3];

		// for now I'mma just use the fnf style for a test
		var note:Note = new Note(daStrumTime, daNoteInfo % 4, daNoteAlt, 0, "");

		// if the note is on the other side, flip the base section of the note
		var gottaHitNote:Bool = _song.notes[curSection].mustHitSection;
		if (daNoteInfo > 3)
			gottaHitNote = !gottaHitNote;

		note.rawNoteData = daNoteInfo; // raw data

		note.sustainLength = daSus;
		note.noteType = daNoteType;
		note.setGraphicSize(GRID_SIZE, GRID_SIZE);
		note.updateHitbox();
		note.x = ((FlxG.width / 2) - (GRID_SIZE * 4));

		note.x += Math.floor((daNoteInfo % 4) * GRID_SIZE);
		if (gottaHitNote)
			note.x += (4 * GRID_SIZE);

		// when the equation is painful
		note.y = Math.floor(ChartingState.getYfromStrum((daStrumTime - ChartingState.sectionStartTime(curSection,
			_song)) % (Conductor.stepCrochet * _song.notes[curSection].lengthInSteps), curSection));

		ChartingState.curRenderedNotes.add(note);

		if (daSus > 0)
		{
			var sustainVis:FlxSprite = new FlxSprite(note.x + (GRID_SIZE / 2),
				note.y + GRID_SIZE).makeGraphic(8, Math.floor(FlxMath.remapToRange(daSus, 0, Conductor.stepCrochet * 16, 0, GRID_SIZE * 16)));
			note.chartSustain = sustainVis;
			ChartingState.curRenderedSustains.add(sustainVis);
		}

		// pain

		// hell in a shell even

		// play mario rabbids

		// unoptimised asf but for testing purposes
		if (ChartingState.renderTestActive)
		{
			var newText:FlxText = new FlxText(note.x, note.y, 0, Std.string(daNoteInfo) + ', ' + Std.string(daNoteInfo % 4));
			newText.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, RIGHT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
			ChartingState.renderTextTest.add(newText);
		}
		//
	}
}
