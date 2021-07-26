package;

/*
	Aw hell yeah! something I can actually work on!
 */
import flixel.FlxG;
import flixel.graphics.frames.FlxAtlasFrames;
import openfl.utils.AssetType;
import openfl.utils.Assets as OpenFlAssets;

class Paths
{
	// Here we set up the paths class. This will be used to
	// Return the paths of assets and call on those assets as well.
	// set the current song extension to either OGG or MP3 depending on the client
	inline public static var SOUND_EXT = "ogg";

	// level we're loading
	static var currentLevel:String;

	// set the current level top the condition of this function if called
	static public function setCurrentLevel(name:String)
	{
		currentLevel = name.toLowerCase();
	}

	//
	static function getPath(file:String, type:AssetType, library:Null<String>)
	{
		/*
				Okay so, from what I understand, this loads in the current path based on the level
				we're in (if a library is not specified), say like week 1 or something, 
				then checks if the assets you're looking for are there.
				if not, it checks the shared assets folder.
			// */

		// well I'm rewriting it so that the library is the path and it looks for the file type
		// later lmao I don't really wanna rn

		if (library != null)
			return getLibraryPath(file, library);

		/*
			if (currentLevel != null)
			{
				levelPath = getLibraryPathForce(file, currentLevel);
				if (OpenFlAssets.exists(levelPath, type))
					return levelPath;

				levelPath = getLibraryPathForce(file, "shared");
				if (OpenFlAssets.exists(levelPath, type))
					return levelPath;
		}*/

		var levelPath = getLibraryPathForce(file, "mods");
		if (OpenFlAssets.exists(levelPath, type))
			return levelPath;

		return getPreloadPath(file);
	}

	// files!
	// this is how I'm gonna do it, considering it's much cleaner in my opinion

	/*
		inline static public function returnFileType(fileName:String, ?library:String, fileExtension:String)
		{
			// I don't really use haxe so bare with me
			var returnFile:String = "$" + fileName + "." + fileExtension;
			return getPath()
	}//*/
	/*  
		actually I could just combine all of these main functions into one and really call it a day
		it's similar and would use one function with a switch case
		for now I'm more focused on getting this to run than anything and I'll clean out the code later as I do want to organise
		everything later 
	 */
	static public function getLibraryPath(file:String, library = "preload")
	{
		return if (library == "preload" || library == "default") getPreloadPath(file); else getLibraryPathForce(file, library);
	}

	inline static function getLibraryPathForce(file:String, library:String)
	{
		return '$library/$file';
	}

	inline static function getPreloadPath(file:String)
	{
		return 'assets/$file';
	}

	inline static public function file(file:String, type:AssetType = TEXT, ?library:String)
	{
		return getPath(file, type, library);
	}

	inline static public function txt(key:String, ?library:String)
	{
		return getPath('data/$key.txt', TEXT, library);
	}

	inline static public function xml(key:String, ?library:String)
	{
		return getPath('data/$key.xml', TEXT, library);
	}

	inline static public function offsetTxt(key:String, ?library:String)
	{
		return getPath('images/characters/$key.txt', TEXT, library);
	}

	inline static public function json(key:String, ?library:String)
	{
		return getPath('data/$key.json', TEXT, library);
	}

	static public function sound(key:String, ?library:String)
	{
		return getPath('sounds/$key.$SOUND_EXT', SOUND, library);
	}

	inline static public function soundRandom(key:String, min:Int, max:Int, ?library:String)
	{
		return sound(key + FlxG.random.int(min, max), library);
	}

	inline static public function music(key:String, ?library:String)
	{
		return getPath('music/$key.$SOUND_EXT', MUSIC, library);
	}

	inline static public function voices(song:String)
	{
		return getPath('songs/${song.toLowerCase()}/Voices.$SOUND_EXT', MUSIC, null);
	}

	inline static public function inst(song:String)
	{
		return getPath('songs/${song.toLowerCase()}/Inst.$SOUND_EXT', MUSIC, null);
	}

	inline static public function image(key:String, ?library:String)
	{
		return getPath('images/$key.png', IMAGE, library);
	}

	inline static public function font(key:String)
	{
		return 'assets/fonts/$key';
	}

	inline static public function getSparrowAtlas(key:String, ?library:String)
	{
		return FlxAtlasFrames.fromSparrow(image(key, library), file('images/$key.xml', library));
	}

	inline static public function getPackerAtlas(key:String, ?library:String)
	{
		return FlxAtlasFrames.fromSpriteSheetPacker(image(key, library), file('images/$key.txt', library));
	}
	/*	Dedicating this section to asset separation and such!
		way this will work is, frames can be stored and such (from xml files themselves not actual sprites)

		Shoutouts to tricky v2, I'm not a fan of how they do it, but it definitely gave me the idea to implement a system like this
		I just dont want to preload everything because that would be REALLY bad honestly

		WIP PLEASE STAND BY I WILL CORRECT THE ISSUES LATER
	 */
	/*
		public static var cachedStuffs:Map<String, FlxAtlasFrames> = new Map<String, FlxAtlasFrames>();

		public static function cacheSparrow(key:String)
		{
			// alright so here we'd want to cache the atlas for later usage
			cachedStuffs.set(key, getSparrowAtlas(key));
			// thats it lmfao
		}

		inline public static function loadCachedSparrow(key:String)
		{
			// return the cached sprite I think
			if (cachedStuffs.get(key) == null)
				Paths.cacheSparrow(key);

			var cachedReturn:FlxAtlasFrames = cachedStuffs.get(key);
			return cachedReturn;
		}

		public static function dumpCache()
		{
			// clear the map of cached stuffs
			cachedStuffs.clear();
			
		}
	 */
}
