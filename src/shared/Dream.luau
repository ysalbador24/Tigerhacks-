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

-- The three choices the two-minute demo requires before sleeping.
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
		{flag = "Notifications", line = "Kept scrolling: notifications swarm your path and knock you back."},
	},
	Lighting = {
		{flag = nil, line = "Dim lights: a calm, steady night sky."},
		{flag = "Flicker", line = "Bright light: the dream glares and platforms blink out."},
	},
	Food = {
		{flag = nil, line = "Finished eating: the path holds still."},
		{flag = "Heavy", line = "Late heavy meal: you feel sluggish and the path won't sit still."},
	},
}

-- Short hint shown in the room right after an essential choice.
local hints = {
	Phone = {"Tonight's dream: a quiet path.", "Tonight's dream: notifications will chase you."},
	Lighting = {"Tonight's dream: a calm night sky.", "Tonight's dream: glaring light and flickering platforms."},
	Food = {"Tonight's dream: steady footing.", "Tonight's dream: sluggish steps on a drifting path."},
}

function Dream.hint(key, option)
	local options = hints[key]
	return options and options[option]
end

-- Deterministic dream setup from the player's answers.
function Dream.configure(answers)
	local config = {flags = {}, lines = {}}
	for _, key in Dream.essentials do
		local effect = effects[key][answers[key] or 1]
		if effect.flag then config.flags[effect.flag] = true end
		table.insert(config.lines, effect.line)
	end
	-- Leaving notifications on adds more interruptions to the swarm.
	if answers.Notifications == 2 then
		config.flags.Notifications = true
		config.flags.ExtraNotifications = true
		table.insert(config.lines, "Notifications on: even more pings interrupt the dream.")
	end
	return config
end

return Dream
