package gameFolder.gameObjects;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.math.FlxMath;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import gameFolder.gameObjects.userInterface.UIStaticArrow;
import gameFolder.meta.*;
import gameFolder.meta.data.*;
import gameFolder.meta.data.dependency.FNFSprite;
import gameFolder.meta.state.PlayState;

using StringTools;

#if polymod
import polymod.format.ParseRules.TargetSignatureElement;
#end

class Note extends FNFSprite
{
	public var strumTime:Float = 0;

	public var mustPress:Bool = false;
	public var noteData:Int = 0;
	public var noteAlt:Float = 0;
	public var noteType:Float = 0;
	public var noteString:String = "";

	public var canBeHit:Bool = false;
	public var tooLate:Bool = false;
	public var wasGoodHit:Bool = false;
	public var prevNote:Note;

	public var sustainLength:Float = 0;
	public var isSustainNote:Bool = false;

	// only useful for charting stuffs
	public var chartSustain:FlxSprite = null;
	public var rawNoteData:Int;

	public static var swagWidth:Float = 160 * 0.7;

	// people really gon go 'oh she uses a lot of maps' of course I do lmao I like loading info like this so I only have to set it up once
	public var foreverMods:Map<String, Array<Dynamic>> = [
		/*  here we'll be setting some strings and stuff yknow cus I like that a lot honestly???
			the idea behind this is you'll be able to easily add stuff here and the chart editor will work with it
			and then you can set what the stuff here does when the notes are actually hit
			which will be a function
		 */
		'type' => [0],
		'zoom' => [false, 0],
		'camZoom' => [false, 0],
		'angle' => [false, 0],
		'camAngle' => [false, 0],
		// which one (of 8, 0...7), to what x, to what y, angle of the arrow
		'moveStrumarrow' => [false, 0, 0, 0, 0],
		'string' => ['']
	];

	public function new(strumTime:Float, noteData:Int, noteAlt:Float, ?prevNote:Note, ?sustainNote:Bool = false)
	{
		super(x, y);

		if (prevNote == null)
			prevNote = this;

		this.prevNote = prevNote;
		isSustainNote = sustainNote;

		x += 50;
		y -= 2000;
		this.strumTime = strumTime;
		this.noteData = noteData;
		this.noteAlt = noteAlt;

		decideNote();
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (mustPress)
		{
			if (strumTime > Conductor.songPosition - (Conductor.safeZoneOffset)
				&& strumTime < Conductor.songPosition + (Conductor.safeZoneOffset))
				canBeHit = true;
			else
				canBeHit = false;

			if (strumTime < Conductor.songPosition - (Conductor.safeZoneOffset * 1.5) && !wasGoodHit)
				tooLate = true;
		}
		else // make sure the note can't be hit if it's the dad's I guess
			canBeHit = false;

		if (tooLate)
		{
			if (alpha > 0.3)
				alpha -= 0.05;
		}

		if (foreverMods.get('type')[0] != noteType)
		{
			noteType = foreverMods.get('type')[0];
			decideNote();
		}
	}

	private function decideNote()
	{
		// frames originally go here
		switch (noteType)
		{
			case 1: // pixel arrows
				loadGraphic(Paths.image('UI/pixel/notes/arrows-pixels'), true, 17, 17);

				animation.add('greenScroll', [6]);
				animation.add('redScroll', [7]);
				animation.add('blueScroll', [5]);
				animation.add('purpleScroll', [4]);

				if (isSustainNote)
				{
					loadGraphic(Paths.image('UI/pixel/notes/arrowEnds'), true, 7, 6);

					animation.add('purpleholdend', [4]);
					animation.add('greenholdend', [6]);
					animation.add('redholdend', [7]);
					animation.add('blueholdend', [5]);

					animation.add('purplehold', [0]);
					animation.add('greenhold', [2]);
					animation.add('redhold', [3]);
					animation.add('bluehold', [1]);
				}

				antialiasing = false;
				setGraphicSize(Std.int(width * PlayState.daPixelZoom));
				updateHitbox();

			default: // base game arrows for no reason whatsoever
				frames = Paths.getSparrowAtlas('UI/base/notes/NOTE_assets');

				animation.addByPrefix('greenScroll', 'green0');
				animation.addByPrefix('redScroll', 'red0');
				animation.addByPrefix('blueScroll', 'blue0');
				animation.addByPrefix('purpleScroll', 'purple0');

				animation.addByPrefix('purpleholdend', 'pruple end hold');
				animation.addByPrefix('greenholdend', 'green hold end');
				animation.addByPrefix('redholdend', 'red hold end');
				animation.addByPrefix('blueholdend', 'blue hold end');

				animation.addByPrefix('purplehold', 'purple hold piece');
				animation.addByPrefix('greenhold', 'green hold piece');
				animation.addByPrefix('redhold', 'red hold piece');
				animation.addByPrefix('bluehold', 'blue hold piece');

				setGraphicSize(Std.int(width * 0.7));
				updateHitbox();
				antialiasing = true;
		}

		//
		animation.play(UIStaticArrow.getColorFromNumber(noteData) + 'Scroll');

		// trace(prevNote);

		if (isSustainNote && prevNote != null)
		{
			alpha = 0.6;

			animation.play(UIStaticArrow.getColorFromNumber(noteData) + 'holdend');

			updateHitbox();

			if (prevNote.isSustainNote)
			{
				prevNote.animation.play(UIStaticArrow.getColorFromNumber(prevNote.noteData) + 'hold');

				prevNote.scale.y *= Conductor.stepCrochet / 100 * 1.5 * PlayState.SONG.speed;
				prevNote.updateHitbox();
				// prevNote.setGraphicSize();
			}
		}
	}

	public function callMods()
	{
		// call upon the note end functions
		trace('call upon mods');
		for (mods in foreverMods.keys())
		{
			if (foreverMods.get(mods)[0])
			{
				switch (mods)
				{
					case 'zoom':
						var amount = foreverMods.get(mods)[1];
						if (amount != 0)
							PlayState.forceZoom[0] += amount;
					case 'camZoom':
						var amount = foreverMods.get(mods)[1];
						if (amount != 0)
							PlayState.forceZoom[1] += amount;
					case 'angle':
						var amount = foreverMods.get(mods)[1];
						if (amount != 0)
							PlayState.forceZoom[2] += amount;
					case 'camAngle':
						var amount = foreverMods.get(mods)[1];
						if (amount != 0)
							PlayState.forceZoom[3] += amount;

					// these get real repetitive so heres a divider
					case 'moveStrumarrow':
						PlayState.strumLineNotes.members[foreverMods.get(mods)[1]].xTo += foreverMods.get(mods)[2];
						PlayState.strumLineNotes.members[foreverMods.get(mods)[1]].yTo += foreverMods.get(mods)[3];
						PlayState.strumLineNotes.members[foreverMods.get(mods)[1]].angleTo += foreverMods.get(mods)[4];
				}
				//

				// trace('$mods $amount');
			}
		}

		// finish actions!
	}
}
