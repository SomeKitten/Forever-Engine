package gameFolder.meta.data.dependency;

import flixel.addons.transition.FlxTransitionableState;
import flixel.addons.ui.FlxUIState;

/**
	Credit to HelloSammu for this
**/
class FNFUIState extends FlxUIState
{
	override public function transitionIn():Void
	{
		if (transIn != null && transIn.type != NONE)
		{
			if (FlxTransitionableState.skipNextTransIn)
			{
				FlxTransitionableState.skipNextTransIn = false;

				if (finishTransIn != null)
				{
					finishTransIn();
				}

				return;
			}

			// Make the transition effect
			var _trans = new FNFTransition(transIn);

			_trans.setStatus(FULL);
			openSubState(_trans);

			_trans.finishCallback = finishTransIn;
			_trans.start(OUT);
		}
	}

	public override function transitionOut(?OnExit:Void->Void):Void
	{
		_onExit = OnExit;

		if (hasTransOut)
		{
			var _trans = new FNFTransition(transOut);

			_trans.setStatus(EMPTY);
			openSubState(_trans);

			_trans.finishCallback = finishTransOut;
			_trans.start(IN);
		}
		else
		{
			_onExit();
		}
	}
}
