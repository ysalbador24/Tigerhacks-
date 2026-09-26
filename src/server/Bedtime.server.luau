local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Mood = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("EveningMood"))
local remote = Instance.new("RemoteFunction")
remote.Name = "BedtimeChoice"
remote.Parent = ReplicatedStorage
local choices = {
	Curtains = {"Close the curtains", "Leave them open"},
	Lighting = {"Use warm, dim lighting", "Keep the bright light"},
	Food = {"Finish eating for tonight", "Have a late heavy meal"},
	Phone = {"Put the phone on the desk", "Keep scrolling in bed"},
	Notifications = {"Turn on Do Not Disturb", "Keep notifications on"},
	Temperature = {"Make the room comfortably cool", "Keep the room warm"},
	Shower = {"Take a warm shower", "Skip showering"},
	BrushTeeth = {"Brush my teeth", "Skip brushing"},
	Skincare = {"Do my skincare routine", "Skip skincare"},
	Reading = {"Read a quiet chapter", "Skip reading"},
	WindDown = {"Take a quiet breathing break", "Skip winding down"},
}
local totalChoices = 0
for _ in choices do totalChoices += 1 end
local sessions = {}
local function begin(player)
	sessions[player] = {answers = {}, started = os.clock()}
end
local function setup(player)
	player:GetAttributeChangedSignal("StartedGame"):Connect(function()
		if player:GetAttribute("StartedGame") and not sessions[player] then begin(player) end
	end)
	if player:GetAttribute("StartedGame") then begin(player) end
end
Players.PlayerAdded:Connect(setup)
for _, player in Players:GetPlayers() do setup(player) end
Players.PlayerRemoving:Connect(function(player) sessions[player] = nil end)
remote.OnServerInvoke = function(player, key, option)
	if not player:GetAttribute("StartedGame") then return nil end
	local session = sessions[player]
	if not session then begin(player); session = sessions[player] end
	if key == "Replay" then
		if not session.result then return nil end
		begin(player)
		return {replay = true, wellbeing = Mood.summarize({})}
	end
	if key == "Status" then return {wellbeing = Mood.summarize(session.answers)} end
	if key == "Sleep" then
		local count, positive = 0, 0
		for _, answer in session.answers do count += 1; if answer == 1 then positive += 1 end end
		if count < totalChoices then return {message = "Try all " .. totalChoices .. " room and bathroom activities before going to sleep."} end
		local remaining = math.ceil(300 - (os.clock() - session.started))
		if remaining > 0 then return {message = "Enjoy a little quiet time. Bedtime is in " .. remaining .. " seconds. You can revisit your choices."} end
		local score = math.floor(positive / totalChoices * 100 + 0.5)
		session.result = {score = score, feeling = if score >= 80 then "Rested and ready" elseif score >= 50 then "A little sleepy" else "Ready for a gentler night", answers = session.answers, wellbeing = Mood.summarize(session.answers)}
		return session.result
	end
	if session.result or not choices[key] or (option ~= 1 and option ~= 2) then return nil end
	session.answers[key] = option
	return {accepted = true, wellbeing = Mood.summarize(session.answers), feedback = Mood.feedback(key,option)}
end
