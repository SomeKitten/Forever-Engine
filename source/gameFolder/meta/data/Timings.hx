package gameFolder.meta.data;

import gameFolder.gameObjects.Note;

/**
	Here's a class that calculates timings and ratings for the songs and such
**/
class Timings
{
	//
	public static var accuracy:Float;
	public static var judgementRates:Array<Float>;

	public static var daRatings:Map<String, Array<Dynamic>>;
	public static var scoreRating:Map<String, Int>;

	public static var ratingFinal:String = "f";

	public static function callAccuracy()
	{
		// reset the accuracy to 0%
		accuracy = 0.001;
		judgementRates = new Array<Float>();
		ratingFinal = "f";
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
			//
		}

		// here we calculate how much judgements will be worth

		// from left to right
		// chance, score from it, id and percentage
		daRatings = [
			"sick" => [null, 350, 0, 100],
			"good" => [0.15, 200, 1, 50],
			"bad" => [0.5, 100, 2, 25],
			"shit" => [0.7, 50, 3, 5],
		];

		for (myRating in daRatings.keys())
		{
			// call the judgements for their funny little uh score thingy

			// so basically, a judgement is the accuracy of the rating divided by the amount of notes in the chart
			// mines would give you a sick rating if you miss them, holds give you sicks, etc
			judgementRates[daRatings.get(myRating)[2]] = (daRatings.get(myRating)[3] / totalNotes);
		}

		// set the score ratings for later use
		scoreRating = ["s" => 90, "a" => 80, "b" => 70, "c" => 50, "d" => 40, "e" => 20, "f" => 0,];
	}

	public static function updateAccuracy(judgement:Int)
	{
		accuracy += judgementRates[judgement];
		updateScoreRating();
	}

	public static function getAccuracy()
	{
		return accuracy;
	}

	public static function updateScoreRating()
	{
		var biggest:Int = 0;
		for (score in scoreRating.keys())
		{
			if ((scoreRating.get(score) <= accuracy) && (scoreRating.get(score) >= biggest))
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
