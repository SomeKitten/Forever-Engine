package gameFolder.meta.data;

import gameFolder.gameObjects.Note;

/**
	Here's a class that calculates timings and ratings for the songs and such
**/
class Timings
{
	//
	public static var accuracy:Float;
	public static var trueAccuracy:Float;
	public static var judgementRates:Array<Float>;

	public static var daRatings:Map<String, Array<Dynamic>>;
	public static var scoreRating:Map<String, Int>;

	public static var ratingFinal:String = "f";
	public static var notesHit:Int = 0;

	public static function callAccuracy()
	{
		// reset the accuracy to 0%
		accuracy = 0.001;
		trueAccuracy = 0;
		judgementRates = new Array<Float>();
		notesHit = 0;
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
			"good" => [0.2, 200, 1, 60],
			"bad" => [0.5, 100, 2, 15],
			"shit" => [0.7, 50, 3, 0],
		];

		// set the score ratings for later use
		scoreRating = ["s" => 90, "a" => 80, "b" => 70, "c" => 50, "d" => 40, "e" => 20, "f" => 0,];
	}

	public static function updateAccuracy(judgement:Int)
	{
		notesHit++;
		accuracy += judgement;
		trueAccuracy = (accuracy / notesHit);
		updateScoreRating();
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
