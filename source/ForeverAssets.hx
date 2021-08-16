package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.util.FlxColor;
import gameFolder.gameObjects.userInterface.*;
import gameFolder.gameObjects.userInterface.menu.*;
import gameFolder.meta.state.PlayState;

/**
	Forever Assets is a class that manages the different asset types, basically a compilation of switch statements that are
	easy to edit for your own needs. Most of these are just static functions that return information
**/
class ForeverAssets
{
	//
	public static function generateCombo(asset:String, assetModifier:String = 'base', baseLibrary:String, negative:Bool, createdColor:FlxColor, scoreInt:Int,
			recycleGroup:FlxTypedGroup<FlxSprite>):FlxSprite
	{
		var newSprite:FlxSprite = recycleGroup.recycle(FlxSprite).loadGraphic(Paths.image(ForeverTools.returnSkinAsset(asset, assetModifier, baseLibrary)));
		switch (assetModifier)
		{
			case 'basepixel' | 'foreverpixel':
				newSprite.alpha = 1;
				newSprite.screenCenter();
				newSprite.x += (43 * scoreInt) + 20;
				newSprite.y += 60;

				newSprite.color = FlxColor.WHITE;
				if (negative)
					newSprite.color = createdColor;

				newSprite.setGraphicSize(Std.int(newSprite.width * PlayState.daPixelZoom));
				newSprite.updateHitbox();

				newSprite.acceleration.y = FlxG.random.int(200, 300);
				newSprite.velocity.y = -FlxG.random.int(140, 160);
				newSprite.velocity.x = FlxG.random.float(-5, 5);

			default:
				newSprite.alpha = 1;
				newSprite.screenCenter();
				newSprite.x += (43 * scoreInt) + 20;
				newSprite.y += 60;

				newSprite.color = FlxColor.WHITE;
				if (negative)
					newSprite.color = createdColor;

				newSprite.antialiasing = true;
				newSprite.setGraphicSize(Std.int(newSprite.width * 0.5));
				newSprite.updateHitbox();

				newSprite.acceleration.y = FlxG.random.int(200, 300);
				newSprite.velocity.y = -FlxG.random.int(140, 160);
				newSprite.velocity.x = FlxG.random.float(-5, 5);
		}

		return newSprite;
	}

	public static function generateRating(asset:String, assetModifier:String = 'base', baseLibrary:String, recycleGroup:FlxTypedGroup<FlxSprite>):FlxSprite
	{
		var rating:FlxSprite = recycleGroup.recycle(FlxSprite).loadGraphic(Paths.image(ForeverTools.returnSkinAsset(asset, assetModifier, baseLibrary)));
		switch (assetModifier)
		{
			default:
				rating.alpha = 1;
				rating.screenCenter();
				rating.x = (FlxG.width * 0.55) - 40;
				rating.y -= 60;
				rating.acceleration.y = 550;
				rating.velocity.y = -FlxG.random.int(140, 175);
				rating.velocity.x = -FlxG.random.int(0, 10);
		}

		return rating;
	}

	public static function generateNoteSplashes(asset:String, assetModifier:String = 'base', baseLibrary:String, noteData:Int):NoteSplash
	{
		//
		var tempSplash:NoteSplash = new NoteSplash(noteData);
		switch (assetModifier)
		{
			case 'basepixel' | 'foreverpixel':
				tempSplash.loadGraphic(Paths.image(ForeverTools.returnSkinAsset('notes/splash-pixel', assetModifier, 'UI')), true, 34, 34);
				tempSplash.animation.add('anim1', [noteData, 4 + noteData, 8 + noteData, 12 + noteData], 24, false);
				tempSplash.animation.add('anim2', [16 + noteData, 20 + noteData, 24 + noteData, 28 + noteData], 24, false);
				tempSplash.animation.play('anim1');
				tempSplash.addOffset('anim1', -120, -120);
				tempSplash.addOffset('anim2', -120, -120);
				tempSplash.setGraphicSize(Std.int(tempSplash.width * PlayState.daPixelZoom));

			default:
				// 'UI/$assetModifier/notes/noteSplashes'
				tempSplash.loadGraphic(Paths.image(ForeverTools.returnSkinAsset('notes/noteSplashes', assetModifier, 'UI')), true, 210, 210);
				tempSplash.animation.add('anim1', [
					(noteData * 2 + 1),
					8 + (noteData * 2 + 1),
					16 + (noteData * 2 + 1),
					24 + (noteData * 2 + 1),
					32 + (noteData * 2 + 1)
				], 24, false);
				tempSplash.animation.add('anim2', [
					(noteData * 2),
					8 + (noteData * 2),
					16 + (noteData * 2),
					24 + (noteData * 2),
					32 + (noteData * 2)
				], 24, false);
				tempSplash.animation.play('anim1');
				tempSplash.addOffset('anim1', -20, -10);
				tempSplash.addOffset('anim2', -20, -10);

				/*
					tempSplash.frames = Paths.getSparrowAtlas('UI/$assetModifier/notes/noteSplashes');
					// get a random value for the note splash type
					tempSplash.animation.addByPrefix('anim1', 'note impact 1 ' + UIStaticArrow.getColorFromNumber(noteData), 24, false);
					tempSplash.animation.addByPrefix('anim2', 'note impact 2 ' + UIStaticArrow.getColorFromNumber(noteData), 24, false);
					tempSplash.animation.play('anim1');

					tempSplash.addOffset('anim1', 16, 16);
					tempSplash.addOffset('anim2', 16, 16);
				 */
		}

		return tempSplash;
	}

	public static function generateUIArrows(x:Float, y:Float, ?babyArrowType:Int = 0, assetModifier:String):UIStaticArrow
	{
		var newBabyArrow:UIStaticArrow = new UIStaticArrow(x, y, babyArrowType);
		switch (assetModifier)
		{
			case 'basepixel' | 'foreverpixel':
				// look man you know me I fucking hate repeating code
				// not even just a cleanliness thing it's just so annoying to tweak if something goes wrong like
				// genuinely more programmers should make their code more modular
				newBabyArrow.loadGraphic(Paths.image('UI/$assetModifier/notes/arrows-pixels'), true, 17, 17);
				newBabyArrow.animation.add('static', [babyArrowType]);
				newBabyArrow.animation.add('pressed', [4 + babyArrowType, 8 + babyArrowType], 12, false);
				newBabyArrow.animation.add('confirm', [12 + babyArrowType, 16 + babyArrowType], 24, false);

				newBabyArrow.setGraphicSize(Std.int(newBabyArrow.width * PlayState.daPixelZoom));
				newBabyArrow.updateHitbox();
				newBabyArrow.antialiasing = false;

				newBabyArrow.addOffset('static', -67, -75);
				newBabyArrow.addOffset('pressed', -67, -75);
				newBabyArrow.addOffset('confirm', -67, -75);

			case 'chart editor':
				// look man you know me I fucking hate repeating code
				// not even just a cleanliness thing it's just so annoying to tweak if something goes wrong like
				// genuinely more programmers should make their code more modular
				newBabyArrow.loadGraphic(Paths.image('UI/forever/chart editor/note_array'), true, 157, 156);
				newBabyArrow.animation.add('static', [babyArrowType]);
				newBabyArrow.animation.add('pressed', [16 + babyArrowType], 12, false);
				newBabyArrow.animation.add('confirm', [4 + babyArrowType, 8 + babyArrowType, 16 + babyArrowType], 24, false);

				newBabyArrow.addOffset('static');
				newBabyArrow.addOffset('pressed');
				newBabyArrow.addOffset('confirm');

			default:
				// probably gonna revise this and make it possible to add other arrow types but for now it's just pixel and normal
				var stringSect:String = '';
				// call arrow type I think
				stringSect = UIStaticArrow.getArrowFromNumber(babyArrowType);

				var framesArgument:String = "NOTE_assets";

				newBabyArrow.frames = Paths.getSparrowAtlas(ForeverTools.returnSkinAsset('notes/$framesArgument', assetModifier, 'UI'));

				newBabyArrow.animation.addByPrefix('static', 'arrow' + stringSect.toUpperCase());
				newBabyArrow.animation.addByPrefix('pressed', stringSect + ' press', 24, false);
				newBabyArrow.animation.addByPrefix('confirm', stringSect + ' confirm', 24, false);

				newBabyArrow.antialiasing = true;
				newBabyArrow.setGraphicSize(Std.int(newBabyArrow.width * 0.7));

				// set little offsets per note!
				// so these had a little problem honestly and they make me wanna off(set) myself so the middle notes basically
				// have slightly different offsets than the side notes (which have the same offset)

				var offsetMiddleX = 0;
				var offsetMiddleY = 0;
				if (babyArrowType > 0 && babyArrowType < 3)
				{
					offsetMiddleX = 2;
					offsetMiddleY = 2;
					if (babyArrowType == 1)
					{
						offsetMiddleX -= 1;
						offsetMiddleY += 2;
					}
				}

				newBabyArrow.addOffset('static');
				newBabyArrow.addOffset('pressed', -2, -2);
				newBabyArrow.addOffset('confirm', 36 + offsetMiddleX, 36 + offsetMiddleY);
		}

		return newBabyArrow;
	}

	public static function generateCheckmark(x:Float, y:Float, asset:String, assetModifier:String = 'base', baseLibrary:String)
	{
		var newCheckmark:Checkmark = new Checkmark(x, y);
		switch (assetModifier)
		{
			default:
				newCheckmark.frames = Paths.getSparrowAtlas(ForeverTools.returnSkinAsset(asset, assetModifier, baseLibrary));
				newCheckmark.antialiasing = true;

				newCheckmark.animation.addByPrefix('false finished', 'uncheckFinished');
				newCheckmark.animation.addByPrefix('false', 'uncheck', 12, false);
				newCheckmark.animation.addByPrefix('true finished', 'checkFinished');
				newCheckmark.animation.addByPrefix('true', 'check', 12, false);

				// for week 7 assets when they decide to exist
				// animation.addByPrefix('false', 'Check Box unselected', 24, true);
				// animation.addByPrefix('false finished', 'Check Box unselected', 24, true);
				// animation.addByPrefix('true finished', 'Check Box Selected Static', 24, true);
				// animation.addByPrefix('true', 'Check Box selecting animation', 24, false);
				newCheckmark.setGraphicSize(Std.int(newCheckmark.width * 0.7));
				newCheckmark.updateHitbox();

				///*
				var offsetByX = 45;
				var offsetByY = 5;
				newCheckmark.addOffset('false', offsetByX, offsetByY);
				newCheckmark.addOffset('true', offsetByX, offsetByY);
				newCheckmark.addOffset('true finished', offsetByX, offsetByY);
				newCheckmark.addOffset('false finished', offsetByX, offsetByY);
				// */

				// addOffset('true finished', 17, 37);
				// addOffset('true', 25, 57);
				// addOffset('false', 2, -30);
		}
		return newCheckmark;
	}
}
