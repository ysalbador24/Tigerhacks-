-- Fictional local posts with Roblox-hosted avatar thumbnails; no social account required.
-- Thumbnail formats: https://create.roblox.com/docs/projects/assets#rbxthumb
local PhoneInteraction = {}
local posts = {
	{name = "@CloudBuilder", title = "A cabin above the clouds", caption = "Finished my floating island build. Would you live here?", tag = "BUILD SHOWCASE", color = Color3.fromRGB(84, 126, 172), blocks = 5},
	{name = "@ObbyOwl", title = "One jump from victory", caption = "That final checkpoint took twelve tries. Worth it.", tag = "OBBY MOMENTS", color = Color3.fromRGB(128, 93, 168), blocks = 7},
	{name = "@CozyPixels", title = "The quietest server", caption = "Warm lights, tiny houses, and a sky full of stars.", tag = "COZY CORNER", color = Color3.fromRGB(57, 112, 103), blocks = 4},
	{name = "@BrickExplorer", title = "Found a secret rooftop", caption = "Sometimes the best view is off the main path.", tag = "EXPLORING", color = Color3.fromRGB(167, 105, 76), blocks = 6},
	{name = "@MoonMode", title = "Saving my progress", caption = "The build will still be here tomorrow. Good night, everyone.", tag = "LAST POST TONIGHT", color = Color3.fromRGB(67, 77, 127), blocks = 3},
}
function PhoneInteraction.open(player)
	local gui = Instance.new("ScreenGui")
	gui.Name = "EveningSocialPhone"; gui.DisplayOrder = 15; gui.ResetOnSpawn = false
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling; gui.Parent = player:WaitForChild("PlayerGui")
	local function frame(parent, position, size, color, radius)
		local f = Instance.new("Frame"); f.Position = position; f.Size = size
		f.BackgroundColor3 = color; f.BorderSizePixel = 0; f.Parent = parent
		if radius then Instance.new("UICorner", f).CornerRadius = UDim.new(0, radius) end
		return f
	end
	local function label(parent, value, pos, size, button)
		local l = Instance.new(if button then "TextButton" else "TextLabel")
		l.Text = value; l.Position = pos; l.Size = size; l.BackgroundTransparency = 1
		l.TextColor3 = Color3.fromRGB(245, 245, 250); l.Font = Enum.Font.GothamMedium
		l.TextScaled = true; l.TextWrapped = true; l.Parent = parent
		local constraint = Instance.new("UITextSizeConstraint", l); constraint.MaxTextSize = 22
		return l
	end
	local backdrop = frame(gui, UDim2.new(), UDim2.fromScale(1, 1), Color3.fromRGB(10, 14, 25))
	backdrop.BackgroundTransparency = 0.28; backdrop.Active = true
	local phone = frame(backdrop, UDim2.fromScale(0.5, 0.5), UDim2.fromScale(0.9, 0.94), Color3.fromRGB(21, 23, 30), 34)
	phone.AnchorPoint = Vector2.new(0.5, 0.5)
	local aspect = Instance.new("UIAspectRatioConstraint", phone); aspect.AspectRatio = 0.51
	local edge = Instance.new("UIStroke", phone); edge.Color = Color3.fromRGB(112, 118, 132); edge.Thickness = 3
	local screen = frame(phone, UDim2.fromScale(0.035, 0.02), UDim2.fromScale(0.93, 0.96), Color3.fromRGB(29, 32, 45), 27)
	frame(screen, UDim2.fromScale(0.33, 0.01), UDim2.fromScale(0.34, 0.032), Color3.fromRGB(8, 10, 14), 12)
	label(screen, "10:30", UDim2.fromScale(0.07, 0.01), UDim2.fromScale(0.2, 0.035))
	label(screen, "▰ 87%", UDim2.fromScale(0.73, 0.01), UDim2.fromScale(0.21, 0.035))
	label(screen, "Bloxstagram", UDim2.fromScale(0.07, 0.07), UDim2.fromScale(0.86, 0.05))
	label(screen, "For you  •  Following", UDim2.fromScale(0.07, 0.13), UDim2.fromScale(0.86, 0.035))
	local feed = frame(screen, UDim2.fromScale(0.04, 0.19), UDim2.fromScale(0.92, 0.61), Color3.fromRGB(29, 32, 45))
	feed.ClipsDescendants = true
	local pages = Instance.new("UIPageLayout", feed)
	pages.SortOrder = Enum.SortOrder.LayoutOrder; pages.FillDirection = Enum.FillDirection.Vertical
	pages.TweenTime = 0.32; pages.EasingStyle = Enum.EasingStyle.Quart
	pages.TouchInputEnabled = true; pages.ScrollWheelInputEnabled = true; pages.GamepadInputEnabled = true
	pages.Circular = false
	local function avatarImage(parent, userId, headshot, position, size)
		local picture = Instance.new("ImageLabel")
		picture.Name = if headshot then "ProfilePhoto" else "AvatarPhoto"
		picture.BackgroundTransparency = 1
		picture.Position = position; picture.Size = size
		picture.ScaleType = Enum.ScaleType.Fit
		picture.Image = string.format("rbxthumb://type=%s&id=%d&w=420&h=420", if headshot then "AvatarHeadShot" else "Avatar", userId)
		picture.Parent = parent
		if headshot then
			local aspect = Instance.new("UIAspectRatioConstraint", picture); aspect.AspectRatio = 1
			picture.BackgroundTransparency = 0; picture.BackgroundColor3 = Color3.fromRGB(91, 74, 110)
			Instance.new("UICorner", picture).CornerRadius = UDim.new(1, 0)
		end
		return picture
	end
	-- Use the visitor's real avatar for the featured post, including a Studio fallback.
	local avatarIds = {1, 156, if player.UserId > 0 then player.UserId else 1, 261, 1}
	for index, post in posts do
		local card = frame(feed, UDim2.new(), UDim2.fromScale(1, 1), Color3.fromRGB(35, 39, 54), 12)
		card.Name = "Post" .. index; card.LayoutOrder = index
		avatarImage(card, avatarIds[index], true, UDim2.fromScale(0.04, 0.015), UDim2.fromScale(0.12, 0.09))
		local username = label(card, post.name, UDim2.fromScale(0.2, 0.02), UDim2.fromScale(0.66, 0.06))
		username.TextXAlignment = Enum.TextXAlignment.Left
		label(card, "•••", UDim2.fromScale(0.88, 0.02), UDim2.fromScale(0.08, 0.06))
		local art = frame(card, UDim2.fromScale(0.04, 0.12), UDim2.fromScale(0.92, 0.48), post.color, 9)
		art.ClipsDescendants = true
		local gradient = Instance.new("UIGradient", art)
		gradient.Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.fromRGB(65, 66, 106)); gradient.Rotation = 90
		frame(art, UDim2.fromScale(0.72, 0.08), UDim2.fromScale(0.17, 0.2), Color3.fromRGB(255, 224, 167), 50)
		for block = 1, post.blocks do
			local x = (block - 1) / post.blocks
			local height = 0.16 + ((block * 7 + index) % 4) * 0.1
			local tower = frame(art, UDim2.fromScale(x, 0.9 - height), UDim2.fromScale(0.9 / post.blocks, height), Color3.fromRGB(48 + block * 12, 62 + block * 9, 88 + block * 8), 2)
			frame(tower, UDim2.fromScale(0.2, 0.2), UDim2.fromScale(0.25, 0.2), Color3.fromRGB(255, 220, 144), 2)
		end
		avatarImage(art, avatarIds[index], false, UDim2.fromScale(0.18, 0.1), UDim2.fromScale(0.64, 0.9))
		label(art, post.tag, UDim2.fromScale(0.04, 0.03), UDim2.fromScale(0.62, 0.13))
		label(card, post.title, UDim2.fromScale(0.06, 0.72), UDim2.fromScale(0.88, 0.065))
		label(card, post.caption, UDim2.fromScale(0.06, 0.80), UDim2.fromScale(0.88, 0.12))
		local like = label(card, "♡ Like", UDim2.fromScale(0.06, 0.63), UDim2.fromScale(0.4, 0.065), true)
		local liked = false
		like.Activated:Connect(function() liked = not liked; like.Text = if liked then "♥ Liked" else "♡ Like" end)
		local save = label(card, "Save", UDim2.fromScale(0.69, 0.63), UDim2.fromScale(0.25, 0.065), true)
		local saved = false
		save.Activated:Connect(function() saved = not saved; save.Text = if saved then "Saved ✓" else "Save" end)
		label(card, "Fictional post", UDim2.fromScale(0.06, 0.94), UDim2.fromScale(0.55, 0.035))
		label(card, index .. " / " .. #posts, UDim2.fromScale(0.7, 0.9), UDim2.fromScale(0.23, 0.065))
	end
	local previous = label(screen, "↑ Back", UDim2.fromScale(0.06, 0.82), UDim2.fromScale(0.38, 0.05), true)
	local nextPost = label(screen, "Keep scrolling ↑", UDim2.fromScale(0.56, 0.82), UDim2.fromScale(0.38, 0.05), true)
	previous.Activated:Connect(function() if pages.CurrentPage and pages.CurrentPage.LayoutOrder > 1 then pages:Previous() end end)
	nextPost.Activated:Connect(function() if pages.CurrentPage then
		if pages.CurrentPage.LayoutOrder < #posts then pages:Next() else pages:JumpToIndex(0) end
	end end)
	label(screen, "Swipe up or down • mouse wheel", UDim2.fromScale(0.06, 0.88), UDim2.fromScale(0.88, 0.03))
	local close = label(screen, "Choose again • Put phone away", UDim2.fromScale(0.12, 0.93), UDim2.fromScale(0.76, 0.045), true)
	close.Activated:Connect(function() gui:Destroy() end)
	return gui
end
return PhoneInteraction
