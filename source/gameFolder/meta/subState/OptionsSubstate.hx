package gameFolder.meta.subState;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import gameFolder.meta.MusicBeat.MusicBeatSubState;
import gameFolder.meta.data.font.Alphabet;

class OptionsSubstate extends MusicBeatSubState
{
	private var curSelection = 0;
	var totalSize = Lambda.count(Init.gameControls);

	// the controls class thingy
	override public function create():Void
	{
		// call the options menu
		var bg = new FlxSprite(-85);
		bg.loadGraphic(Paths.image('menuDesat'));
		bg.scrollFactor.x = 0;
		bg.scrollFactor.y = 0.18;
		bg.setGraphicSize(Std.int(bg.width * 1.1));
		bg.updateHitbox();
		bg.screenCenter();
		bg.color = 0xCE64DF;
		bg.antialiasing = true;
		add(bg);

		super.create();

		keyOptions = generateOptions();
		updateSelection();
	}

	private var keyOptions:FlxTypedGroup<Alphabet>;
	private var otherKeys:FlxTypedGroup<Alphabet>;

	private function generateOptions()
	{
		keyOptions = new FlxTypedGroup<Alphabet>();

		var arrayTemp:Array<String> = [];
		// re-sort everything according to the list numbers
		for (controlString in Init.gameControls.keys())
			arrayTemp[Init.gameControls.get(controlString)[1]] = controlString;

		for (i in 0...arrayTemp.length)
		{
			// generate key options lol
			var optionsText:Alphabet = new Alphabet(0, 0, arrayTemp[i], true, false);
			optionsText.screenCenter();
			optionsText.y += (90 * (i - (arrayTemp.length / 2)));
			optionsText.targetY = i;
			optionsText.disableX = true;
			optionsText.isMenuItem = true;
			optionsText.alpha = 0.6;
			keyOptions.add(optionsText);
		}

		// stupid shubs you always forget this
		add(keyOptions);

		generateExtra(arrayTemp);

		return keyOptions;
	}

	private function generateExtra(arrayTemp:Array<String>)
	{
		otherKeys = new FlxTypedGroup<Alphabet>();
		for (i in 0...arrayTemp.length)
		{
			for (j in 0...1)
			{
				var secondaryText:Alphabet = new Alphabet(0, 0, Std.string('deez'), false, false);
				secondaryText.screenCenter();
				secondaryText.y += (90 * (i - (arrayTemp.length / 2)));
				secondaryText.targetY = i;
				secondaryText.disableX = true;
				secondaryText.xTo += ((j + 1) * 30);
				secondaryText.isMenuItem = true;
				secondaryText.alpha = 0.6;
				otherKeys.add(secondaryText);
			}
		}
		add(otherKeys);
	}

	private function updateSelection(equal:Int = 0)
	{
		if (equal != curSelection)
			FlxG.sound.play(Paths.sound('scrollMenu'));

		curSelection = equal;
		// wrap the current selection
		if (curSelection < 0)
			curSelection = keyOptions.length - 1;
		else if (curSelection >= keyOptions.length)
			curSelection = 0;

		//
		for (i in 0...keyOptions.length)
		{
			keyOptions.members[i].alpha = 0.6;
			keyOptions.members[i].targetY = (i - curSelection) / 2;
		}
		keyOptions.members[curSelection].alpha = 1;

		///*
		for (i in 0...otherKeys.length)
		{
			otherKeys.members[i].alpha = 0.6;
			otherKeys.members[i].targetY = ((i - curSelection) / 2);
		}
		otherKeys.members[curSelection + curHorizontalSelection].alpha = 1;
		// */
	}

	private var curHorizontalSelection = 0;

	private function updateHorizontalSelection()
	{
		var left = controls.LEFT_P;
		var right = controls.RIGHT_P;
		var horizontalControl:Array<Bool> = [left, right];

		if (horizontalControl.contains(true))
		{
			for (i in 0...horizontalControl.length)
			{
				if (horizontalControl[i] == true)
				{
					curHorizontalSelection += (i - 1);

					if (curHorizontalSelection < 0)
						curHorizontalSelection = 1;
					else if (curHorizontalSelection > 1)
						curHorizontalSelection = 0;

					// update stuffs
					FlxG.sound.play(Paths.sound('scrollMenu'));
				}
			}
			//
		}
	}

	private var submenuOpen:Bool = false;

	override public function update(elapsed:Float)
	{
		super.update(elapsed);

		if (!submenuOpen)
		{
			if (controls.BACK)
			{
				close();
			}

			var up = controls.UP;
			var down = controls.DOWN;
			var up_p = controls.UP_P;
			var down_p = controls.DOWN_P;
			var controlArray:Array<Bool> = [up, down, up_p, down_p];

			if (controlArray.contains(true))
			{
				for (i in 0...controlArray.length)
				{
					// here we check which keys are pressed
					if (controlArray[i] == true)
					{
						// if single press
						if (i > 1)
						{
							// up is 2 and down is 3
							// paaaaaiiiiiiinnnnn
							if (i == 2)
								updateSelection(curSelection - 1);
							else if (i == 3)
								updateSelection(curSelection + 1);
						}
					}
					//
				}
			}

			//
			updateHorizontalSelection();
		}
	}
}
