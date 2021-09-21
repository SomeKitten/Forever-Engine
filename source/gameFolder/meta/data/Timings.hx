package gameFolder.meta.data;

import gameFolder.gameObjects.userInterface.notes.*;
import gameFolder.meta.state.PlayState;

/**
	Here's a class that calculates timings and judgements for the songs and such
**/
class Timings
{
	//
	public static var accuracy:Float;
	public static var trueAccuracy:Float;
	public static var judgementRates:Array<Float>;

	// from left to right
	// max milliseconds, score from it and percentage
	public static var judgementsMap:Map<String, Array<Dynamic>> = [
		"sick" => [0, 45, 350, 100],
		"good" => [1, 100, 150, 40],
		"bad" => [2, 120, 0, 5],
		"shit" => [3, 140, -50, -100],
		"miss" => [4, 180, -100, -150],
	];

	public static var msThreshold:Float = 0;

	// set the score judgements for later use
	public static var scoreRating:Map<String, Int> = ["s" => 90, "a" => 80, "b" => 70, "c" => 50, "d" => 40, "e" => 20, "f" => 0,];

	public static var ratingFinal:String = "f";
	public static var notesHit:Int = 0;

	public static var comboDisplay:String = '';
	public static var notesHitNoSus:Int = 0;

	public static function callAccuracy()
	{
		// reset the accuracy to 0%
		accuracy = 0.001;
		trueAccuracy = 0;
		judgementRates = new Array<Float>();

		// reset ms threshold
		var biggestThreshold:Float = 0;
		for (i in judgementsMap.keys())
			if (judgementsMap.get(i)[1] > biggestThreshold)
				biggestThreshold = judgementsMap.get(i)[1];
		msThreshold = biggestThreshold;

		notesHit = 0;
		notesHitNoSus = 0;

		ratingFinal = "f";

		comboDisplay = '';
	}

	/*
		You can create custom judgements here! just assign values to it as explained below.
		Null means that it is the highest judgement, meaning it doesn't get a check and is set automatically
	 */
	public static function accuracyMaxCalculation(realNotes:Array<Note>)
	{
		// first we split the notes and get a total note number
		var totalNotes:Int = 0;
		for (i in 0...realNotes.length)
		{
			if (realNotes[i].mustPress)
				totalNotes++;
		}
	}

	public static function updateAccuracy(judgement:Int, isSustain:Bool = false)
	{
		notesHit++;
		if (!isSustain)
			notesHitNoSus++;
		accuracy += Math.max(0, judgement);
		trueAccuracy = (accuracy / notesHit);

		updateFCDisplay();
		updateScoreRating();
	}

	public static function updateFCDisplay()
	{
		// update combo display
		// if you dont understand this look up ternary operators, they're REALLY useful for condensing code and
		// I would totally encourage you check them out and learn a little more
		comboDisplay = ((PlayState.combo >= notesHitNoSus) ? ((trueAccuracy >= 100) ? ' [PERFECT]' : ' [FC]') : '');

		// to break it down further
		/*
			if (PlayState.combo >= notesHitNoSus) {
				if (trueAccuracy >= 100)
					comboDisplay = ' [PERFECT]';
				else
					comboDisplay = ' [FC]';
			} else
				comboDisplay = '';
		 */

		// this updates the most so uh
		PlayState.uiHUD.updateScoreText();
	}

	public static function getAccuracy()
	{
		return trueAccuracy;
	}

	public static function updateScoreRating()
	{
		var biggest:Int = 0;
		for (score in scoreRating.keys())
		{
			if ((scoreRating.get(score) <= trueAccuracy) && (scoreRating.get(score) >= biggest))
			{
				biggest = scoreRating.get(score);
				ratingFinal = score;
			}
		}
	}

	public static function returnScoreRating()
	{
		return ratingFinal;
	}
}
