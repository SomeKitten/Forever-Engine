package gameFolder.meta.state.charting;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.FlxStrip;
import flixel.util.FlxColor;
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
class WaveformRenderTest extends MusicBeatState
{
	var fuck:FlxSprite;

	var audioBuffer:AudioBuffer;
	var bytes:Bytes;

	override public function create()
	{
		super.create();

		fuck = new FlxSprite().makeGraphic(1280, 720, FlxColor.BLACK);
		fuck.angle = 90;
		add(fuck);

		audioBuffer = AudioBuffer.fromFile("./assets/songs/milf/inst.ogg");
		bytes = audioBuffer.data.toBytes();

		FlxG.sound.playMusic(Sound.fromAudioBuffer(audioBuffer));

		#if !html5
		Thread.create(function()
		{
			var currentTime:Float = Sys.time();
			var finishedTime:Float;

			var index:Int = 0;
			var drawIndex:Int = 0;
			var samplesPerCollumn:Int = 600;

			var min:Float = 0;
			var max:Float = 0;

			Sys.println("Interating");

			while ((index * 4) < (bytes.length - 1))
			{
				var byte:Int = bytes.getUInt16(index * 4);

				if (byte > 65535 / 2)
					byte -= 65535;

				var sample:Float = (byte / 65535);

				if (sample > 0)
				{
					if (sample > max)
						max = sample;
				}
				else if (sample < 0)
				{
					if (sample < min)
						min = sample;
				}

				if ((index % samplesPerCollumn) == 0)
				{
					// trace("min: " + min + ", max: " + max);

					if (drawIndex > 1280)
					{
						drawIndex = 0;
					}

					var pixelsMin:Float = Math.abs(min * 300);
					var pixelsMax:Float = max * 300;

					fuck.pixels.fillRect(new Rectangle(drawIndex, 0, 1, 720), 0xFF000000);
					fuck.pixels.fillRect(new Rectangle(drawIndex, (FlxG.height / 2) - pixelsMin, 1, pixelsMin + pixelsMax), FlxColor.WHITE);
					drawIndex += 1;

					min = 0;
					max = 0;
				}

				index += 1;
			}

			finishedTime = Sys.time();

			Sys.println("Took " + (finishedTime - currentTime) + " seconds.");
		});
		#end
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);
	}
}
