-- Fictional game balancing, not a model of real-world mood or sleep duration.
local Mood = {}
Mood.effects = {
	Curtains = {{4,8,"A darker room can help you settle down for sleep."},{-2,-6,"Outside light can make it harder to settle down."}},
	Lighting = {{4,8,"Softer lighting can help you wind down."},{0,-8,"Bright light can make it harder to feel sleepy."}},
	Food = {{3,5,"A lighter snack may feel more comfortable close to bedtime."},{2,-8,"Pizza can be satisfying; a heavier meal may take longer to settle near bedtime."}},
	Notifications = {{6,8,"Quieting alerts can help keep bedtime peaceful."},{-6,-10,"Alerts can interrupt a quiet moment before sleep."}},
	Temperature = {{2,3,"Perfect!"},{0,0,"Choose what feels comfortable."}},
	Shower = {{5,3,"A shower can be a relaxing part of your bedtime routine and help you fall asleep faster."},{0,0,"A shower is optional; choose a routine that feels comfortable."}},
	BrushTeeth = {{3,0,"Brushing supports dental health and can be a familiar bedtime cue."},{-2,0,"Brushing later can still be part of your bedtime routine."}},
	WindDown = {{8,12,"A quiet chapter can help you unwind before bed."},{2,-16,"Scrolling can make it harder to put your phone down and settle in."}},
	TV = {{3,8,"Turning off the TV can help make the room quieter for sleep."},{1,-8,"Another episode can make it harder to wind down before bed."}},
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
