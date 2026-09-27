-- Fictional game balancing, not a model of real-world mood or sleep duration.
local Mood = {}
Mood.effects = {
	Curtains = {{4,8,"A darker room can help you settle down for sleep."},{-2,-6,"Outside light can make it harder to settle down."}},
	Lighting = {{4,8,"Softer lighting can help you wind down."},{0,-8,"Bright light can make it harder to feel sleepy."}},
	Food = {{3,5,"Avoiding a heavy meal near bedtime can help you rest comfortably."},{2,-8,"A heavy meal near bedtime can make rest less comfortable."}},
	Phone = {{6,12,"Putting your phone away can help make space to wind down."},{2,-16,"Keeping your phone nearby can make it tempting to keep scrolling."}},
	Notifications = {{6,8,"Quieting alerts can help keep bedtime peaceful."},{-6,-10,"Alerts can interrupt a quiet moment before sleep."}},
	Temperature = {{4,6,"A comfortably cool room can help you settle in."},{-3,-5,"A room that feels too warm can make rest less comfortable."}},
	Shower = {{5,3,"A comfortable shower can be part of a relaxing bedtime routine."},{0,0,"A shower is optional; choose a routine that feels comfortable."}},
	BrushTeeth = {{3,0,"Brushing supports dental health and can be a familiar bedtime cue."},{-2,0,"Brushing later can still be part of your bedtime routine."}},
	WindDown = {{10,12,"A quiet breathing break can help you relax before bed."},{-2,-4,"A little quiet time later can still help you unwind."}},
	Reading = {{8,8,"A quiet chapter can help you unwind before bed."},{0,0,"You can choose another calming activity before bed."}},
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
