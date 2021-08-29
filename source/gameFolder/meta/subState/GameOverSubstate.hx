package gameFolder.meta.subState;

import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSubState;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import gameFolder.gameObjects.Boyfriend;
import gameFolder.meta.MusicBeat.MusicBeatSubState;
import gameFolder.meta.data.Conductor.BPMChangeEvent;
import gameFolder.meta.data.Conductor;
import gameFolder.meta.state.*;
import gameFolder.meta.state.menus.*;

class GameOverSubstate extends MusicBeatSubState
{
	//
	var bf:Boyfriend;
	var camFollow:FlxObject;
	var stageSuffix:String = "";

	public function new(x:Float, y:Float)
	{
		var daBoyfriendType = PlayState.boyfriend.curCharacter;
		var daBf:String = '';
		switch (daBoyfriendType)
		{
			case 'bf-og':
				daBf = daBoyfriendType;
			case 'bf-pixel':
				daBf = 'bf-pixel-dead';
				stageSuffix = '-pixel';
			default:
				daBf = 'bf-dead';
		}

		PlayState.boyfriend.destroy();

		super();

		Conductor.songPosition = 0;

		bf = new Boyfriend(x, y, daBf);
		add(bf);

		camFollow = new FlxObject(bf.getGraphicMidpoint().x + 20, bf.getGraphicMidpoint().y - 40, 1, 1);
		add(camFollow);

		FlxG.sound.play(Paths.sound('fnf_loss_sfx' + stageSuffix));
		Conductor.changeBPM(100);

		// FlxG.camera.followLerp = 1;
		// FlxG.camera.focusOn(FlxPoint.get(FlxG.width / 2, FlxG.height / 2));
		FlxG.camera.scroll.set();
		FlxG.camera.target = null;

		bf.playAnim('firstDeath');
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (controls.ACCEPT)
			endBullshit();

		if (controls.BACK)
		{
			FlxG.sound.music.stop();

			if (PlayState.isStoryMode)
			{
				Main.switchState(this, new StoryMenuState());
			}
			else
				Main.switchState(this, new FreeplayState());
		}

		if (bf.animation.curAnim.name == 'firstDeath' && bf.animation.curAnim.curFrame == 12)
			FlxG.camera.follow(camFollow, LOCKON, 0.01);

		if (bf.animation.curAnim.name == 'firstDeath' && bf.animation.curAnim.finished)
			FlxG.sound.playMusic(Paths.music('gameOver' + stageSuffix));

		// if (FlxG.sound.music.playing)
		//	Conductor.songPosition = FlxG.sound.music.time;
	}

	override function beatHit()
	{
		super.beatHit();

		FlxG.log.add('beat');
	}

	var isEnding:Bool = false;

	function endBullshit():Void
	{
		if (!isEnding)
		{
			isEnding = true;
			bf.playAnim('deathConfirm', true);
			FlxG.sound.music.stop();
			FlxG.sound.play(Paths.music('gameOverEnd' + stageSuffix));
			new FlxTimer().start(0.7, function(tmr:FlxTimer)
			{
				FlxG.camera.fade(FlxColor.BLACK, 1, false, function()
				{
					Main.switchState(this, new PlayState());
				});
			});
			//
		}
	}
}
