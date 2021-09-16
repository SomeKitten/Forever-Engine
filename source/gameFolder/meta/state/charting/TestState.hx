package gameFolder.meta.state.charting;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.FlxStrip;
import flixel.addons.display.FlxTiledSprite;
import flixel.util.FlxColor;
import gameFolder.gameObjects.Note;
import gameFolder.meta.MusicBeat.MusicBeatState;
import haxe.io.Bytes;
import lime.media.AudioBuffer;
import lime.media.vorbis.VorbisFile;
import openfl.geom.Rectangle;
import openfl.media.Sound;
#if !html5
import sys.thread.Thread;
#end

/**
	This is just code I stole from gedehari, he's a really cool guy. Here's a link to the source.
	https://github.com/gedehari/HaxeFlixel-Waveform-Rendering
	This is only used to test waveforms, I'm going to write my own code based on this later
**/
class TestState extends MusicBeatState
{
	var note:Note;
	var newNote:FlxTiledSprite;

	override public function create()
	{
		super.create();

		var note = ForeverAssets.generateArrow(PlayState.assetModifier, 0, 0, 0, 0);
		note.noteQuant = 0;

		note.screenCenter();

		newNote = new FlxTiledSprite(null, 109, 0, false, true);
		newNote.frames = Paths.getSparrowAtlas(ForeverTools.returnSkinAsset('NOTE_assets', "base", Init.trueSettings.get("Note Skin"), 'noteskins/notes'));

		newNote.animation.addByPrefix('purpleholdend', 'pruple end hold');
		newNote.animation.addByPrefix('greenholdend', 'green hold end');
		newNote.animation.addByPrefix('redholdend', 'red hold end');
		newNote.animation.addByPrefix('blueholdend', 'blue hold end');

		newNote.animation.addByPrefix('purplehold', 'purple hold piece');
		newNote.animation.addByPrefix('greenhold', 'green hold piece');
		newNote.animation.addByPrefix('redhold', 'red hold piece');
		newNote.animation.addByPrefix('bluehold', 'blue hold piece');

		// newNote.setGraphicSize(Std.int(newNote.width * 0.7));
		// newNote.updateHitbox();
		newNote.antialiasing = (!Init.trueSettings.get('Disable Antialiasing'));

		newNote.animation.play('redhold');

		add(newNote);
		newNote.screenCenter();
		newNote.y = note.y + note.height / 2;

		add(note);
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);

		if (controls.RIGHT)
		{
			newNote.height++;
			// newNote.scrollY++;
		}

		if (controls.LEFT)
		{
			newNote.height--;
			// newNote.scrollY++;
		}
	}
}
