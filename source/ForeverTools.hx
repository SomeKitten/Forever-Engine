package;

import flixel.FlxG;
import flixel.system.FlxSound;
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

	public static function returnSkinAsset(asset:String, assetModifier:String = 'base', changeableSkin:String = 'default', baseLibrary:String,
			?defaultChangeableSkin:String = 'default', ?defaultBaseAsset:String = 'base'):String
	{
		var realAsset = '$baseLibrary/$changeableSkin/$assetModifier/$asset';
		if (!Assets.exists(Paths.image(realAsset)))
		{
			realAsset = '$baseLibrary/$defaultChangeableSkin/$assetModifier/$asset';
			if (!Assets.exists(Paths.image(realAsset)))
				realAsset = '$baseLibrary/$defaultChangeableSkin/$defaultBaseAsset/$asset';
		}

		return realAsset;
	}

	public static function killMusic(songsArray:Array<FlxSound>)
	{
		// neat function thing for songs
		for (i in 0...songsArray.length)
		{
			// stop
			songsArray[i].stop();
			songsArray[i].destroy();
		}
	}
}
