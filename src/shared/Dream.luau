-- Shared layout and rules for the dream course. Bedtime choices decide which
-- effects appear; the server owns progress, checkpoints, and the ending.
local Dream = {}

-- High above the campus so the course never overlaps the neighborhood.
Dream.origin = Vector3.new(0, 600, 0)
-- Falling this far below the course returns the player to their checkpoint.
Dream.fallDepth = 25
-- Reaching this close to the sunrise ends the dream.
Dream.goalRadius = 14
-- Seconds before the "wake up now" safety button becomes available.
Dream.earlyWakeSeconds = 45

-- Legacy effect keys used by the dream course (not required activities).
Dream.essentials = {"Phone", "Lighting", "Food"}

-- Platforms are offsets from Dream.origin: {size, position, kind}.
-- Gaps are 5-6 studs with rises of at most 2, so default jumping clears them.
Dream.platforms = {
	{Vector3.new(24, 2, 24), Vector3.new(0, 0, 0), "Start"},
	{Vector3.new(12, 2, 16), Vector3.new(0, 1, -25), "Tile"},
	{Vector3.new(12, 2, 16), Vector3.new(3, 2, -46), "Tile"},
	{Vector3.new(12, 2, 16), Vector3.new(0, 2, -67), "Tile"},
	{Vector3.new(20, 2, 20), Vector3.new(0, 3, -91), "Checkpoint"},
	{Vector3.new(12, 2, 16), Vector3.new(-3, 3, -115), "Tile"},
	{Vector3.new(12, 2, 16), Vector3.new(0, 4, -136), "Tile"},
	{Vector3.new(12, 2, 16), Vector3.new(3, 4, -157), "Tile"},
	{Vector3.new(20, 2, 20), Vector3.new(0, 5, -181), "Checkpoint"},
	{Vector3.new(12, 2, 16), Vector3.new(0, 5, -205), "Tile"},
	{Vector3.new(12, 2, 16), Vector3.new(-3, 6, -226), "Tile"},
	{Vector3.new(12, 2, 16), Vector3.new(0, 6, -247), "Tile"},
	{Vector3.new(30, 2, 30), Vector3.new(0, 7, -276), "Goal"},
}
Dream.goal = Vector3.new(0, 15, -282)

-- Standing positions (offsets) for the start and each checkpoint, in order.
function Dream.checkpoints()
	local list = {}
	for _, platform in Dream.platforms do
		if platform[3] == "Start" or platform[3] == "Checkpoint" then
			table.insert(list, platform[2] + Vector3.new(0, platform[1].Y / 2 + 3, 0))
		end
	end
	return list
end

function Dream.world(offset)
	return Dream.origin + offset
end

-- Standing CFrame at a checkpoint offset, facing down the course (-Z).
function Dream.spawnCFrame(offset)
	local position = Dream.world(offset)
	return CFrame.lookAt(position, position + Vector3.new(0, 0, -1))
end

-- Each essential choice maps to one visible dream effect.
local effects = {
	Phone = {
		{flag = nil, line = "Phone away: the dream path stays quiet."},
		{flag = "Notifications", line = "Kept scrolling: The Algorithm chases you, notifications block the path, and 4 sheep are doomscrolling."},
	},
	Lighting = {
		{flag = nil, line = "Dim lights: a calm, steady night sky."},
		{flag = "Flicker", line = "Bright light: the dream glares, platforms blink out, and 3 sheep need sunglasses."},
	},
	Food = {
		{flag = nil, line = "Lighter food choice: the path holds still."},
		{flag = "Heavy", line = "Late heavy meal: you're sluggish, the path won't sit still, and 3 sheep are in a food coma."},
	},
}

-- Short hint shown in the room right after an essential choice.
local hints = {
	Phone = {"Tonight's dream: a quiet path.", "Tonight's dream: the Algorithm will follow you in."},
	Lighting = {"Tonight's dream: a calm night sky.", "Tonight's dream: glaring light and flickering platforms."},
	Food = {"Tonight's dream: steady footing.", "Tonight's dream: sluggish steps on a drifting path."},
}

function Dream.hint(key, option)
	local options = hints[key]
	return options and options[option]
end

-- Counting sheep: one sheep stands on each tile (platforms 2-11). Each
-- unhealthy key choice distracts a fixed set of them so they can't be counted.
Dream.sheepNames = {
	"Gary", "Baaarbara", "Wooliam", "Lamb-da", "Fleece Witherspoon",
	"Baaaxter", "Ewe-nice", "Shaun Again", "Count Woolula", "Sheepy McSheepface",
}
local distractions = {
	Phone = {sheep = {1, 4, 7, 10}, kind = "Scrolling", label = "brb, one more reel"},
	Lighting = {sheep = {2, 5, 8}, kind = "Squinting", label = "too bright. can't count."},
	Food = {sheep = {3, 6, 9}, kind = "Snacking", label = "digesting... do not disturb"},
}

-- Adapt the single WindDown outcome for the existing phone dream effects.
-- This copy is never stored as additional scored answers.
function Dream.effectAnswers(answers)
	local effects = table.clone(answers)
	effects.Phone = answers.WindDown
	effects.Reading = nil
	return effects
end

-- Deterministic dream setup from the player's answers.
function Dream.configure(answers, readiness)
	answers = Dream.effectAnswers(answers)
	local config = {flags = {}, lines = {}, sheep = {}, readiness = readiness or 50}
	for index, name in Dream.sheepNames do
		config.sheep[index] = {name = name, platform = index + 1}
	end
	for _, key in Dream.essentials do
		local distraction = distractions[key]
		if answers[key] == 2 then
			for _, index in distraction.sheep do
				config.sheep[index].kind = distraction.kind
				config.sheep[index].label = distraction.label
			end
		end
	end
	config.sheepCountable = 0
	for _, sheep in config.sheep do
		if not sheep.kind then config.sheepCountable += 1 end
	end
	for _, key in Dream.essentials do
		local effect = effects[key][answers[key] or 1]
		if effect.flag then config.flags[effect.flag] = true end
		if key == "Phone" and effect.flag then config.flags.Algorithm = true end
		table.insert(config.lines, effect.line)
	end
	-- Sleep debt: each unhealthy key choice makes the dream blurrier and stranger
	-- (microsleeps, tunnel vision, shadow figures). See DreamEffects.client.luau.
	config.severity = 0
	for _, key in Dream.essentials do
		if answers[key] == 2 then config.severity += 1 end
	end
	-- Readiness can add difficulty without erasing consequences from specific
	-- phone, lighting, or food choices. Watching TV alone drops readiness below
	-- 50, so that choice reaches the existing severity-driven dream effects.
	local readinessSeverity = if config.readiness < 35 then 2 elseif config.readiness < 50 then 1 else 0
	config.severity = math.max(config.severity, readinessSeverity)
	if answers.TV == 1 then
		table.insert(config.lines, "TV off: the room grew quieter before sleep.")
	elseif answers.TV == 2 then
		config.flags.TVGlow = true
		table.insert(config.lines, "One more episode: colorful scenes linger in the dream.")
	end
	if config.severity == 0 then
		table.insert(config.lines, "Well rested: cloud bridges fill the gaps and your legs feel fast.")
	end
	if config.severity >= 2 then
		table.insert(config.lines, "Sleep debt: blurry vision, microsleeps, and something in the corner of your eye.")
	end
	-- Leaving notifications on adds more interruptions to the swarm.
	if answers.Notifications == 2 then
		config.flags.Notifications = true
		config.flags.ExtraNotifications = true
		table.insert(config.lines, "Notifications on: even more pings interrupt the dream.")
	end
	-- Describe only explicitly recorded choices, never the fallback effect values.
	local details={}
	for _,entry in {
		{"WindDown", "read a book", "scrolled on your phone"},
		{"Lighting", "dimmed the lights", "kept the main light on"},
		{"Food", "chose cherries", "chose a slice of pizza"},
		{"TV", "turned off the TV", "watched another episode"},
	} do
		local choice=answers[entry[1]]
		if choice==1 or choice==2 then table.insert(details,entry[choice+1]) end
		if #details==2 then break end
	end
	local mood=if config.severity>0 then "the path might feel a little trickier tonight" else "things feel a little calmer tonight"
	config.introduction=if #details>0 then "You "..table.concat(details," and ").."; "..mood.."."
		elseif config.severity>0 then "It's been a busy night; the path might feel a little trickier."
		else "Your evening is over; a new dream is beginning."
	return config
end

return Dream
