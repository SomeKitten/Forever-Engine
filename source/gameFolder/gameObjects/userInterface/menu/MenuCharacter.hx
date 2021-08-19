package gameFolder.gameObjects.userInterface.menu;

import flixel.FlxSprite;
import flixel.graphics.frames.FlxAtlasFrames;

class MenuCharacter extends FlxSprite
{
	public var character:String;

	public function new(x:Float, character:String = 'bf')
	{
		super(x);

		this.character = character;

		var tex = Paths.getSparrowAtlas('menus/base/storymenu/campaign_menu_UI_characters');
		frames = tex;

		animation.addByPrefix('bf', "BF idle dance white", 24);
		animation.addByPrefix('bfConfirm', 'BF HEY!!', 24, false);
		animation.addByPrefix('gf', "GF Dancing Beat WHITE", 24);
		animation.addByPrefix('alien', "MM xigidle", 24);
		animation.addByPrefix('bones', "MM bonesidle", 24);
		animation.addByPrefix('fbi', "MM goon idle", 24);
		animation.addByPrefix('harold', "MM harold idle", 24);
		// Parent Christmas Idle

		animation.play(character);
		updateHitbox();
	}
}
