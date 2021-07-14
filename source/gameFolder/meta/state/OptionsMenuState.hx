package gameFolder.meta.state;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.effects.FlxFlicker;
import flixel.group.FlxGroup.FlxTypedGroup;
import gameFolder.gameObjects.userInterface.menu.Checkmark;
import gameFolder.meta.MusicBeat.MusicBeatState;
import gameFolder.meta.data.font.Alphabet;
import gameFolder.meta.subState.OptionsSubstate;

/**
	Here I'll set up the options menu, based on the one in week 7. It's just going to be a remake of it though, so you may notice some inconsistencies.
	these are probably just going to be things that I didn't like about the original and such. 
**/
class OptionsMenuState extends MusicBeatState
{
	var groupBase:FlxTypedGroup<Alphabet>;
	var preferenceGroup:FlxTypedGroup<Alphabet>;
	var preferenceCheckmarks:FlxTypedGroup<Checkmark>;
	var accessibilityGroup:FlxTypedGroup<Alphabet>;
	var accessibilityCheckmarks:FlxTypedGroup<Checkmark>;

	var optionsSubgroups:Map<String, Dynamic>;
	var selectedGroup:String = 'base';
	var optionsGroupBase:FlxTypedGroup<Alphabet>;

	var curSelection:Int = 0;
	var optionSelected:Bool = false;

	override public function create():Void
	{
		// create option subgroups and handle options information
		var groupBaseOptions:Array<String> = ['preferences', 'controls', 'accessibility', 'exit'];
		groupBase = generateGroup(groupBaseOptions);

		var preferenceOptions:Array<String> = [
			'Downscroll',
			'Auto Pause',
			'FPS Counter',
			'Memory Counter',
			'Debug Info',
			'No camera note movement',
			'Display Accuracy'
		];
		preferenceGroup = generateGroup(preferenceOptions, true);
		preferenceCheckmarks = generateCheckmarks(preferenceOptions);

		var accessibilityOptions:Array<String> = ['Reduced Movements', "Deuteranopia", "Protanopia", "Tritanopia"];
		accessibilityGroup = generateGroup(accessibilityOptions, true);
		accessibilityCheckmarks = generateCheckmarks(accessibilityOptions);
		//

		optionsSubgroups = [
			'base' => [groupBase],
			'preferences' => [preferenceGroup, preferenceCheckmarks],
			'accessibility' => [accessibilityGroup, accessibilityCheckmarks]
		];

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

		updateGroup(optionsSubgroups.get(selectedGroup)[0], optionsSubgroups.get(selectedGroup)[1]);

		super.create();
	}

	override public function update(elapsed:Float)
	{
		/// copied from the main menu lol
		var up = controls.UP;
		var down = controls.DOWN;
		var up_p = controls.UP_P;
		var down_p = controls.DOWN_P;
		var controlArray:Array<Bool> = [up, down, up_p, down_p];

		if ((controlArray.contains(true)) && (!optionSelected))
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
							updateSelection(optionsSubgroups.get(selectedGroup)[0], curSelection - 1);
						else if (i == 3)
							updateSelection(optionsSubgroups.get(selectedGroup)[0], curSelection + 1);
					}
				}
				//
			}
		}

		if ((!optionSelected) && (controls.ACCEPT))
		{
			optionSelected = true;
			FlxG.sound.play(Paths.sound('confirmMenu'));

			var curSet:FlxTypedGroup<Alphabet> = optionsSubgroups.get(selectedGroup)[0];
			FlxFlicker.flicker(curSet.members[curSelection], 0.5, 0.06 * 2, true, false, function(flick:FlxFlicker)
			{
				updateOption(curSet);
			});
		}

		if (controls.BACK)
		{
			// pretty lazy but I'll rewrite it later
			if (selectedGroup != 'base')
				updateGroup(optionsSubgroups.get('base')[0], optionsSubgroups.get('base')[1], optionsSubgroups.get(selectedGroup)[0],
					optionsSubgroups.get(selectedGroup)[1]);
			else
				Main.switchState(new MainMenuState());
		}

		///*
		if (optionsSubgroups.get(selectedGroup)[1] != null)
		{
			for (i in 0...optionsSubgroups.get(selectedGroup)[1].length)
			{
				optionsSubgroups.get(selectedGroup)[1].members[i].x = optionsSubgroups.get(selectedGroup)[0].members[i].x - 100;
				optionsSubgroups.get(selectedGroup)[1].members[i].y = optionsSubgroups.get(selectedGroup)[0].members[i].y - 48;
			}
		} //*/

		super.update(elapsed);
	}

	private function generateGroup(arrayOptions:Array<String>, isMenuMove:Bool = false)
	{
		var optionsGroup:FlxTypedGroup<Alphabet> = new FlxTypedGroup<Alphabet>();
		for (i in 0...arrayOptions.length)
		{
			var optionsText:Alphabet = new Alphabet(0, 0, arrayOptions[i], true, false);
			optionsText.isMenuItem = isMenuMove;

			// optionsText.targetY = i;
			optionsGroup.add(optionsText);
		}

		return optionsGroup;
	}

	private function generateCheckmarks(arrayOptions:Array<String>)
	{
		var optionsGroup:FlxTypedGroup<Checkmark> = new FlxTypedGroup<Checkmark>();
		for (i in 0...arrayOptions.length)
		{
			var checkmark:Checkmark = new Checkmark(10, i);
			optionsGroup.add(checkmark);
		}

		return optionsGroup;
	}

	// updateGroup(optionsSubgroups.get(selectedGroup));
	private function updateGroup(optionsGroup:FlxTypedGroup<Alphabet>, optionsCheckmarks:FlxTypedGroup<Checkmark>, curGroup:FlxTypedGroup<Alphabet> = null,
			curCheckmarks:FlxTypedGroup<Checkmark> = null)
	{
		trace('begin update group');

		if (curGroup != null)
		{
			remove(curGroup);
			if (curCheckmarks != null)
				remove(curCheckmarks);
		}

		add(optionsGroup);
		// reset position
		trace('reset option group position');
		for (i in 0...optionsGroup.length)
		{
			optionsGroup.members[i].screenCenter();
			optionsGroup.members[i].y += (90 * (i - (optionsGroup.length / 2)));
			optionsGroup.members[i].targetY = i;
			optionsGroup.members[i].disableX = true;

			if (optionsCheckmarks != null)
				updateCheckmarks(i, optionsGroup, optionsCheckmarks);
		}

		trace('add checkmarks I guess');
		if (optionsCheckmarks != null)
			add(optionsCheckmarks);

		curSelection = 0;

		trace('update selection');
		updateSelection(optionsGroup);
		trace('get the group string');
		for (myGroup in optionsSubgroups.keys())
		{
			if (optionsSubgroups.get(myGroup)[0] == optionsGroup)
				selectedGroup = myGroup;
		}
		trace('finish doing that');
	}

	private function updateSelection(optionsGroup:FlxTypedGroup<Alphabet>, equal:Int = 0)
	{
		if (equal != curSelection)
			FlxG.sound.play(Paths.sound('scrollMenu'));

		curSelection = equal;
		// wrap the current selection
		if (curSelection < 0)
			curSelection = optionsGroup.length - 1;
		else if (curSelection >= optionsGroup.length)
			curSelection = 0;

		//
		for (i in 0...optionsGroup.length)
		{
			optionsGroup.members[i].alpha = 0.6;
			if (optionsGroup.members[i].isMenuItem)
				optionsGroup.members[i].targetY = (i - curSelection);
		}
		optionsGroup.members[curSelection].alpha = 1;
	}

	private function updateOption(optionsGroup:FlxTypedGroup<Alphabet>)
	{
		// get the option we're updating
		switch (optionsGroup.members[curSelection].text)
		{
			case 'preferences':
				// go to the preferences menu
				updateGroup(optionsSubgroups.get(optionsGroup.members[curSelection].text)[0],
					optionsSubgroups.get(optionsGroup.members[curSelection].text)[1], optionsSubgroups.get(selectedGroup)[0],
					optionsSubgroups.get(selectedGroup)[1]);
			case 'controls':
				// go to the preferences menu
				// updateGroup(optionsSubgroups.get(optionsGroup.members[curSelection].text), optionsSubgroups.get(selectedGroup));
				openSubState(new OptionsSubstate());
			case 'accessibility':
				// go to the preferences menu
				updateGroup(optionsSubgroups.get(optionsGroup.members[curSelection].text)[0],
					optionsSubgroups.get(optionsGroup.members[curSelection].text)[1], optionsSubgroups.get(selectedGroup)[0],
					optionsSubgroups.get(selectedGroup)[1]);
			case 'exit':
				// transIn = FlxTransitionableState.defaultTransIn;
				// transOut = FlxTransitionableState.defaultTransOut;
				Main.switchState(new MainMenuState());

			default:
				// LMAO THIS IS HUGE
				Init.gameSettings.get(optionsGroup.members[curSelection].text)[0] = !Init.gameSettings.get(optionsGroup.members[curSelection].text)[0];
				// update all that stuff
				Init.saveSettings();
				updateCheckmarks(curSelection, optionsSubgroups.get(selectedGroup)[0], optionsSubgroups.get(selectedGroup)[1]);
		}

		optionSelected = false;
	}

	private function updateCheckmarks(i:Int, optionsGroup:FlxTypedGroup<Alphabet>, optionsCheckmarks:FlxTypedGroup<Checkmark>)
	{
		var selection:Bool = Init.gameSettings.get(optionsGroup.members[i].text)[0];
		// set the selection thingy
		optionsCheckmarks.members[i].playAnim(Std.string(selection));
	}
}
