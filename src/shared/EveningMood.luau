-- Fictional game balancing, not a model of real-world mood or sleep duration.
local Mood = {}
Mood.effects = {
	Curtains = {{4,8,"Closing the curtains makes the room feel more settled."},{-2,-6,"The open window keeps the evening feeling a little busier."}},
	Lighting = {{4,8,"Soft light helps your character wind down."},{0,-8,"The bright light keeps your character alert."}},
	Food = {{3,5,"Your character feels ready to settle in."},{2,-8,"A late snack is enjoyable, but your character feels less ready for bed."}},
	Phone = {{6,12,"Putting the phone away makes space for a quieter evening."},{2,-16,"Scrolling is fun for now, but it lowers your character's sleep readiness."}},
	Notifications = {{6,8,"A quiet phone makes the room feel more peaceful."},{-6,-10,"The buzzing phone keeps pulling your character's attention away."}},
	Temperature = {{4,6,"The room feels comfortable and cozy."},{-3,-5,"Your character feels a little too warm to settle down."}},
	Shower = {{5,3,"Your character feels refreshed after showering."},{0,0,"You chose to skip the shower tonight."}},
	BrushTeeth = {{3,0,"One small routine done: your character feels prepared."},{-2,0,"Your character still has one little task on their mind."}},
	Skincare = {{5,2,"A moment of self-care lifts your character's mood."},{0,0,"You chose a simpler routine tonight."}},
	WindDown = {{10,12,"Quiet breathing leaves your character feeling calmer."},{-2,-4,"Your character is still carrying some of the day's energy."}},
	Reading = {{8,8,"A quiet chapter leaves your character content and settled."},{0,0,"You can come back to the reading nook another time."}},
}
function Mood.summarize(answers)
	local mood, rest = 50, 50
	for key, option in answers do
		local options = Mood.effects[key]
		local effect = options and options[option]
		if effect then mood += effect[1]; rest += effect[2] end
	end
	mood = math.clamp(mood,0,100)
	rest = math.clamp(rest,0,100)
	return {
		mood = mood,
		rest = rest,
		moodLabel = if mood >= 80 then "Peaceful" elseif mood >= 60 then "Content" elseif mood >= 40 then "Okay" elseif mood >= 20 then "Unsettled" else "Overwhelmed",
		-- The fictional night awards between five and nine simulated hours.
		sleepMinutes = 300 + math.floor(rest * 2.4 + 0.5),
	}
end
function Mood.feedback(key, option)
	local effect = Mood.effects[key] and Mood.effects[key][option]
	return if effect then effect[3] else "Explore your room and see how your evening changes."
end
return Mood
