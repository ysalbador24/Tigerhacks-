-- Uses the server's existing grade and report unchanged; presentation only.
local TweenService=game:GetService("TweenService")
local Results={}
function Results.show(player,result,onReplay)
 local gui=Instance.new("ScreenGui") gui.Name="RushMorningReport" gui.ResetOnSpawn=false gui.DisplayOrder=8 gui.Parent=player.PlayerGui
 local paper=Instance.new("Frame") paper.AnchorPoint=Vector2.new(.5,.5) paper.Position=UDim2.fromScale(.5,.5) paper.Size=UDim2.fromScale(.82,.88)
 paper.BackgroundColor3=Color3.fromRGB(247,233,212) paper.BorderSizePixel=0 paper.Parent=gui
 local limit=Instance.new("UISizeConstraint") limit.MaxSize=Vector2.new(850,750) limit.Parent=paper
 local corner=Instance.new("UICorner") corner.CornerRadius=UDim.new(0,8) corner.Parent=paper
 local ink=Color3.fromRGB(38,34,52)
 local function text(content,pos,size,max,font)
  local t=Instance.new("TextLabel") t.BackgroundTransparency=1 t.Text=content t.TextColor3=ink t.TextScaled=true t.TextWrapped=true t.Font=font or Enum.Font.GothamBold
  t.Position=pos t.Size=size t.Parent=paper
  local cap=Instance.new("UITextSizeConstraint") cap.MaxTextSize=max cap.MinTextSize=9 cap.Parent=t return t
 end
 text("BARB'S MORNING REPORT",UDim2.fromScale(.06,.03),UDim2.fromScale(.88,.05),17)
 local grade=text(result.grade,UDim2.fromScale(.06,.095),UDim2.fromScale(.2,.19),92,Enum.Font.FredokaOne)
 grade.TextColor3=Color3.fromRGB(125,109,161) grade.Rotation=-7
 -- Stamp reveal: the grade hangs back for a beat, then slams onto the page.
 local gradeScale=Instance.new("UIScale") gradeScale.Scale=3 gradeScale.Parent=grade
 grade.TextTransparency=1
 local title=text(result.gradeTitle,UDim2.fromScale(.3,.1),UDim2.fromScale(.64,.075),29,Enum.Font.FredokaOne)
 title.TextTransparency=1
 task.delay(.6,function()
  if not gui.Parent then return end
  TweenService:Create(grade,TweenInfo.new(.12),{TextTransparency=0}):Play()
  local slam=TweenService:Create(gradeScale,TweenInfo.new(.28,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{Scale=1})
  slam:Play()
  slam.Completed:Wait()
  if not gui.Parent then return end
  local thud=Instance.new("Sound") thud.SoundId="rbxasset://sounds/button.wav" thud.Volume=.8 thud.PlaybackSpeed=.6 thud.Parent=gui thud:Play()
  paper.Rotation=1.5 TweenService:Create(paper,TweenInfo.new(.25,Enum.EasingStyle.Elastic),{Rotation=0}):Play()
  TweenService:Create(title,TweenInfo.new(.35),{TextTransparency=0}):Play()
 end)
 local habits=0 for _,key in {"WindDown","Lighting","Food"} do if result.answers[key]==1 then habits+=1 end end
 local firstLine=if result.rush then string.format("%ds TO SPARE  •  %d/3 HABITS",result.secondsLeft,habits) else string.format("%d/3 HEALTHY HABITS",habits)
 text(string.format("%s\n%d/%d SHEEP  •  STABILITY %d",firstLine,result.sheep,result.sheepTotal,result.stability),UDim2.fromScale(.3,.19),UDim2.fromScale(.64,.08),16)
 -- Long Gemini reports stay readable by scrolling rather than shrinking the whole page.
 local scroll=Instance.new("ScrollingFrame") scroll.Position=UDim2.fromScale(.07,.34) scroll.Size=UDim2.fromScale(.86,.44)
 scroll.BackgroundTransparency=1 scroll.BorderSizePixel=0 scroll.ScrollBarThickness=4 scroll.ScrollBarImageColor3=Color3.fromRGB(125,109,161)
 scroll.AutomaticCanvasSize=Enum.AutomaticSize.Y scroll.CanvasSize=UDim2.new() scroll.Parent=paper
 local report=Instance.new("TextLabel") report.Size=UDim2.new(1,-10,0,0) report.AutomaticSize=Enum.AutomaticSize.Y report.BackgroundTransparency=1
 -- One line of live community data (Tiger Data), only when the backend answered.
 local community=""
 local stats=result.community
 if type(stats)=="table" and stats.nights and stats.scrolledRate then
  community=string.format("\n\n%d nights played so far. %d%% of players doomscrolled.",stats.nights,math.floor(stats.scrolledRate*100+.5))
  if stats.rankToday then community..=string.format(" You're #%d today.",stats.rankToday) end
 end
 report.Text=result.reflectionSource..":\n"..result.reflection.."\n\n"..result.suggestion..community
 report.TextColor3=ink report.TextSize=18 report.Font=Enum.Font.Gotham report.TextWrapped=true report.TextXAlignment=Enum.TextXAlignment.Left report.TextYAlignment=Enum.TextYAlignment.Top report.Parent=scroll
 text("Dream Stability is a game outcome. Habits inspired by CDC sleep tips.",UDim2.fromScale(.07,.79),UDim2.fromScale(.86,.035),11,Enum.Font.Gotham)
 local retry=Instance.new("TextButton") retry.AnchorPoint=Vector2.new(.5,0) retry.Position=UDim2.fromScale(.5,.86) retry.Size=UDim2.fromScale(.65,.09)
 local retryText=({S="DEFEND MY TITLE",A="GO FOR S",B="ONE MORE NIGHT",C="LOG OFF & RETRY",D="I CAN DO BETTER"})[result.grade] or "TRY AGAIN"
 retry.BackgroundColor3=Color3.fromRGB(230,174,137) retry.BorderSizePixel=0 retry.Text=retryText retry.TextColor3=ink retry.TextScaled=true retry.Font=Enum.Font.FredokaOne retry.Parent=paper
 local cap=Instance.new("UITextSizeConstraint") cap.MinTextSize=12 cap.MaxTextSize=25 cap.Parent=retry
 local min=Instance.new("UISizeConstraint") min.MinSize=Vector2.new(0,44) min.Parent=retry
 local c=Instance.new("UICorner") c.CornerRadius=UDim.new(0,8) c.Parent=retry
 local connection=retry.Activated:Connect(function()
  retry.Active=false retry.Text="ONE MORE NIGHT..."
  onReplay()
  if gui.Parent then retry.Active=true retry.Text=retryText end
 end)
 local controller={}
 function controller.stop() connection:Disconnect() gui:Destroy() end
 return controller
end
return Results
