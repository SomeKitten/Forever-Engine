package;

import flixel.FlxG;
import gameFolder.meta.data.*;
import openfl.utils.Assets;

/**
	This class is used as an extension to many other forever engine stuffs, please don't delete it as it is not only exclusively used in forever engine
	custom stuffs, and is instead used globally.
**/
class ForeverTools
{
	// set up maps and stuffs
	public static function resetMenuMusic()
	{
		// make sure the music is playing
		if (((FlxG.sound.music != null) && (!FlxG.sound.music.playing)) || (FlxG.sound.music == null))
		{
			FlxG.sound.playMusic(Paths.music('freakyMenu'));
			// placeholder bpm
			Conductor.changeBPM(102);
		}
		//
	}

	public static function returnSkinAsset(asset:String, assetModifier:String = 'base', baseLibrary:String):String
	{
		var realAsset = '$baseLibrary/$assetModifier/$asset';
		if (!Assets.exists(realAsset))
			realAsset = '$baseLibrary/base/$asset';

		return realAsset;
	}
}
