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
 local gradeScale=Instance.new("UIScale") gradeScale.Scale=.5 gradeScale.Parent=grade
 TweenService:Create(gradeScale,TweenInfo.new(.45,Enum.EasingStyle.Back),{Scale=1}):Play()
 text(result.gradeTitle,UDim2.fromScale(.3,.1),UDim2.fromScale(.64,.075),29,Enum.Font.FredokaOne)
 local habits=0 for _,key in {"Phone","Lighting","Food"} do if result.answers[key]==1 then habits+=1 end end
 text(string.format("%ds TO SPARE  •  %d/3 HABITS\n%d/%d SHEEP  •  STABILITY %d",result.secondsLeft,habits,result.sheep,result.sheepTotal,result.stability),UDim2.fromScale(.3,.19),UDim2.fromScale(.64,.08),16)
 -- Long Gemini reports stay readable by scrolling rather than shrinking the whole page.
 local scroll=Instance.new("ScrollingFrame") scroll.Position=UDim2.fromScale(.07,.34) scroll.Size=UDim2.fromScale(.86,.44)
 scroll.BackgroundTransparency=1 scroll.BorderSizePixel=0 scroll.ScrollBarThickness=4 scroll.ScrollBarImageColor3=Color3.fromRGB(125,109,161)
 scroll.AutomaticCanvasSize=Enum.AutomaticSize.Y scroll.CanvasSize=UDim2.new() scroll.Parent=paper
 local report=Instance.new("TextLabel") report.Size=UDim2.new(1,-10,0,0) report.AutomaticSize=Enum.AutomaticSize.Y report.BackgroundTransparency=1
 report.Text=result.reflectionSource..":\n"..result.reflection.."\n\n"..result.suggestion
 report.TextColor3=ink report.TextSize=18 report.Font=Enum.Font.Gotham report.TextWrapped=true report.TextXAlignment=Enum.TextXAlignment.Left report.TextYAlignment=Enum.TextYAlignment.Top report.Parent=scroll
 text("Dream Stability is a game outcome. Habits inspired by CDC sleep tips.",UDim2.fromScale(.07,.79),UDim2.fromScale(.86,.035),11,Enum.Font.Gotham)
 local retry=Instance.new("TextButton") retry.AnchorPoint=Vector2.new(.5,0) retry.Position=UDim2.fromScale(.5,.86) retry.Size=UDim2.fromScale(.65,.09)
 retry.BackgroundColor3=Color3.fromRGB(230,174,137) retry.BorderSizePixel=0 retry.Text="TRY AGAIN" retry.TextColor3=ink retry.TextScaled=true retry.Font=Enum.Font.FredokaOne retry.Parent=paper
 local cap=Instance.new("UITextSizeConstraint") cap.MinTextSize=12 cap.MaxTextSize=25 cap.Parent=retry
 local min=Instance.new("UISizeConstraint") min.MinSize=Vector2.new(0,44) min.Parent=retry
 local c=Instance.new("UICorner") c.CornerRadius=UDim.new(0,8) c.Parent=retry
 local connection=retry.Activated:Connect(function()
  retry.Active=false retry.Text="ONE MORE NIGHT..."
  onReplay()
  if gui.Parent then retry.Active=true retry.Text="TRY AGAIN" end
 end)
 local controller={}
 function controller.stop() connection:Disconnect() gui:Destroy() end
 return controller
end
return Results
