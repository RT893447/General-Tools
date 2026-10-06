task.wait(3)
local Players=game:GetService("Players")local UIS=game:GetService("UserInputService")local RS=game:GetService("RunService")local TS=game:GetService("TweenService")local WS=game:GetService("Workspace")local HS=game:GetService("HttpService")local Stats=game:GetService("Stats")local LT=game:GetService("Lighting")
local LP=Players.LocalPlayer local Cam=WS.CurrentCamera
local S={fly=false,flySpeed=60,flyUp=false,flyDown=false,speedOn=false,walk=16,jumpOn=false,jp=50,noclip=false,aim=false,aimPart="Head",aimFov=90,aimDist=500,aimSmooth=60,aimTeam=true,aimCircle=true,aimTargetMode="all",aimPriority="crosshair",aimWall=false,aimStick=30,aimHL=false,aimLaser=false,esp=false,espHL=false,espBox=false,espSkel=false,espTracer=false,espName=false,espDist=false,espHPNum=false,espTool=false,espMax=300,espTarget="all",espYOff=0,espTeamColor=true,radar=false,radarRange=200,radarSize=140,entList=false,hurtFlash=false,showFps=true,lowHPWarn=false,lowHPThreshold=30,fullbright=false}
S.aggro=false S.aggroRange=200 S.aggroFov=40
S.fpsBoost=false S.fpsLevel=2
S.protectGUI=true
S.bhop=false
S.uiOpacity=100
local BASE_WS=16
local aggroMarks={}
local function clrAggro()for m,b in pairs(aggroMarks)do pcall(function()b:Destroy()end)end aggroMarks={}end
local flyG,flyV,flyC=nil,nil,nil local espO,humans,aimT={},{},nil
local bhopConn=nil local bhopLast=0
local origG=WS.Gravity local oJP,oJH,oUJP=nil,nil,nil
local lastHP,hurtT=nil,nil local radarD,entF={},nil
local oL={LT.Brightness,LT.ClockTime,LT.Ambient,LT.OutdoorAmbient,LT.FogEnd,LT.FogStart,LT.GlobalShadows,LT.ShadowSoftness}
local tRefs,sRefs,gRefs={},{},{}
local function isSelf(m)if not m then return false end if m==LP.Character then return true end return Players:GetPlayerFromCharacter(m)==LP end
local function getP(m)local ok,p=pcall(function()return Players:GetPlayerFromCharacter(m)end)if ok and p then return p end return nil end
local function isTeam(m)if not S.espTeamColor then return false end local p=getP(m)if not p or not LP.Team or not p.Team then return false end return p.Team==LP.Team end
local SK15={{"Head","UpperTorso"},{"UpperTorso","LowerTorso"},{"UpperTorso","LeftUpperArm"},{"LeftUpperArm","LeftLowerArm"},{"LeftLowerArm","LeftHand"},{"UpperTorso","RightUpperArm"},{"RightUpperArm","RightLowerArm"},{"RightLowerArm","RightHand"},{"LowerTorso","LeftUpperLeg"},{"LeftUpperLeg","LeftLowerLeg"},{"LeftLowerLeg","LeftFoot"},{"LowerTorso","RightUpperLeg"},{"RightUpperLeg","RightLowerLeg"},{"RightLowerLeg","RightFoot"}}
local SK6={{"Head","Torso"},{"Torso","Left Arm"},{"Torso","Right Arm"},{"Torso","Left Leg"},{"Torso","Right Leg"}}
local C={bg=Color3.fromRGB(12,16,30),card=Color3.fromRGB(20,27,50),dark=Color3.fromRGB(11,15,30),deep=Color3.fromRGB(6,8,16),cy=Color3.fromRGB(0,229,255),pu=Color3.fromRGB(124,77,255),pi=Color3.fromRGB(255,64,129),gr=Color3.fromRGB(0,230,118),ye=Color3.fromRGB(255,180,50),rd=Color3.fromRGB(255,60,60),dg=Color3.fromRGB(255,82,82),tx=Color3.fromRGB(235,242,255),dm=Color3.fromRGB(115,130,170),st=Color3.fromRGB(38,52,88),gold=Color3.fromRGB(255,215,0)}
local function cnr(p,r)local c=Instance.new("UICorner")c.CornerRadius=UDim.new(0,r)c.Parent=p return c end
local function stk(p,c,t,tr)local s=Instance.new("UIStroke")s.Color=c s.Thickness=t or 1 s.Transparency=tr or 0 s.ApplyStrokeMode=Enum.ApplyStrokeMode.Border s.Parent=p return s end
local function grd(p,cs,r)local g=Instance.new("UIGradient")g.Color=cs if r then g.Rotation=r end g.Parent=p return g end
local guiName="GT_"..tostring(math.random(100000,999999))
local sg=Instance.new("ScreenGui")sg.ResetOnSpawn=false sg.DisplayOrder=999999 sg.IgnoreGuiInset=true sg.Name=guiName
local function attachGUI(g)
    local ok,h=pcall(function()if gethui then return gethui() end end)
    if S.protectGUI and ok and h then g.Parent=h else g.Parent=LP:WaitForChild("PlayerGui") end
    if S.protectGUI then
        pcall(function()if syn and syn.protect_gui then syn.protect_gui(g) end end)
        pcall(function()if protect_gui then protect_gui(g) end end)
    end
end
attachGUI(sg)
local io=Instance.new("Frame")io.Size=UDim2.new(1,0,1,0)io.BackgroundColor3=Color3.fromRGB(10,18,35)io.BackgroundTransparency=0.75 io.BorderSizePixel=0 io.ZIndex=9999990 io.Active=false io.Parent=sg
local iog=Instance.new("UIGradient")iog.Rotation=90 iog.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,0.4),NumberSequenceKeypoint.new(0.5,0.85),NumberSequenceKeypoint.new(1,0.4)})iog.Color=ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.fromRGB(0,20,40)),ColorSequenceKeypoint.new(0.5,Color3.fromRGB(0,10,25)),ColorSequenceKeypoint.new(1,Color3.fromRGB(0,20,40))})iog.Parent=io
local bg=Instance.new("Frame")bg.Size=UDim2.new(0,10,0,10)bg.AnchorPoint=Vector2.new(0.5,0.5)bg.Position=UDim2.new(0.5,0,0.5,-20)bg.BackgroundColor3=Color3.fromRGB(80,200,255)bg.BackgroundTransparency=0.5 bg.BorderSizePixel=0 bg.ZIndex=0 bg.Parent=io cnr(bg,9999)
local bgg=Instance.new("UIGradient")bgg.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,0),NumberSequenceKeypoint.new(0.5,0.6),NumberSequenceKeypoint.new(1,1)})bgg.Rotation=90 bgg.Parent=bg
local cg=Instance.new("Frame")cg.Size=UDim2.new(0,10,0,10)cg.AnchorPoint=Vector2.new(0.5,0.5)cg.Position=UDim2.new(0.5,0,0.5,-20)cg.BackgroundColor3=Color3.fromRGB(120,230,255)cg.BackgroundTransparency=0.4 cg.BorderSizePixel=0 cg.ZIndex=1 cg.Parent=io cnr(cg,9999)
local ro=Instance.new("Frame")ro.Size=UDim2.new(0,60,0,60)ro.AnchorPoint=Vector2.new(0.5,0.5)ro.Position=UDim2.new(0.5,0,0.5,-20)ro.BackgroundTransparency=1 ro.ZIndex=2 ro.Parent=io cnr(ro,9999)
local ros=Instance.new("UIStroke")ros.Color=Color3.fromRGB(0,240,255)ros.Thickness=4 ros.Transparency=0 ros.ApplyStrokeMode=Enum.ApplyStrokeMode.Border ros.Parent=ro
local ri=Instance.new("Frame")ri.Size=UDim2.new(0,40,0,40)ri.AnchorPoint=Vector2.new(0.5,0.5)ri.Position=UDim2.new(0.5,0,0.5,-20)ri.BackgroundTransparency=1 ri.ZIndex=2 ri.Parent=io cnr(ri,9999)
local ris=Instance.new("UIStroke")ris.Color=Color3.fromRGB(180,130,255)ris.Thickness=3 ris.Transparency=0 ris.ApplyStrokeMode=Enum.ApplyStrokeMode.Border ris.Parent=ri
local ci=Instance.new("TextLabel")ci.Size=UDim2.new(0,140,0,140)ci.AnchorPoint=Vector2.new(0.5,0.5)ci.Position=UDim2.new(0.5,0,0.5,-20)ci.BackgroundTransparency=1 ci.Text="GT"ci.TextColor3=Color3.new(1,1,1)ci.TextSize=80 ci.Font=Enum.Font.GothamBold ci.TextTransparency=1 ci.TextStrokeTransparency=1 ci.TextStrokeColor3=Color3.fromRGB(0,240,255)ci.ZIndex=3 ci.Parent=io
local sd={}for i=1,4 do local d=Instance.new("Frame")d.Size=UDim2.new(0,12,0,12)d.AnchorPoint=Vector2.new(0.5,0.5)d.Position=UDim2.new(0.5,0,0.5,-20)d.BackgroundColor3=Color3.fromHSV((i-1)/4,0.75,1)d.BorderSizePixel=0 d.ZIndex=4 d.BackgroundTransparency=1 d.Parent=io cnr(d,6)local ds=Instance.new("UIStroke")ds.Color=Color3.new(1,1,1)ds.Thickness=1.5 ds.Transparency=0.3 ds.ApplyStrokeMode=Enum.ApplyStrokeMode.Border ds.Parent=d table.insert(sd,d)end
local tt="GENERAL TOOLS"local cw=32 local tw=#tt*cw local sX=-tw/2 local tl={}for i=1,#tt do local ch=tt:sub(i,i)local fs=(i%2==0)and 1 or-1 local bx=sX+(i-1)*cw local bp=UDim2.new(0.5,bx,0.5,60)local l=Instance.new("TextLabel")l.Size=UDim2.new(0,cw,0,70)l.AnchorPoint=Vector2.new(0,0)l.Position=UDim2.new(0.5,bx+fs*700,0.5,60)l.Rotation=fs*120 l.BackgroundTransparency=1 l.Text=ch l.TextColor3=Color3.fromRGB(255,255,255)l.TextSize=38 l.Font=Enum.Font.GothamBold l.TextTransparency=1 l.TextStrokeTransparency=0 l.TextStrokeColor3=Color3.fromRGB(0,240,255)l.ZIndex=3 l.Parent=io table.insert(tl,{label=l,basePos=bp})end
local iDone=false local fbG=false
local function aFB()if fbG then return end fbG=true pcall(function()LT.Brightness=3 LT.ClockTime=14 LT.Ambient=Color3.fromRGB(200,200,200)LT.OutdoorAmbient=Color3.fromRGB(200,200,200)LT.FogEnd=100000 LT.FogStart=100000 LT.GlobalShadows=false LT.ShadowSoftness=0 end)fbG=false end
RS.RenderStepped:Connect(function()if S.fullbright then aFB()end end)
pcall(function()LT:GetPropertyChangedSignal("Brightness"):Connect(function()if S.fullbright and not fbG then aFB()end end)LT:GetPropertyChangedSignal("ClockTime"):Connect(function()if S.fullbright and not fbG then aFB()end end)end)
local function setFB(on)if on then pcall(function()if not LT:FindFirstChild("GT_CC")then local cc=Instance.new("ColorCorrectionEffect")cc.Name="GT_CC"cc.Brightness=0.35 cc.Parent=LT end end)aFB()else pcall(function()local cc=LT:FindFirstChild("GT_CC")if cc then cc:Destroy()end end)pcall(function()LT.Brightness=oL[1]LT.ClockTime=oL[2]LT.Ambient=oL[3]LT.OutdoorAmbient=oL[4]LT.FogEnd=oL[5]LT.FogStart=oL[6]LT.GlobalShadows=oL[7]LT.ShadowSoftness=oL[8]end)end end
local tg=Instance.new("ScreenGui")tg.ResetOnSpawn=false tg.DisplayOrder=1000000 tg.IgnoreGuiInset=true tg.Name=guiName.."_T"
attachGUI(tg)
local tf=Instance.new("Frame")tf.Size=UDim2.new(0,280,0,48)tf.Position=UDim2.new(0.5,-140,0,20)tf.BackgroundColor3=C.deep tf.BorderSizePixel=0 tf.Active=false tf.Visible=false tf.Parent=tg cnr(tf,14)
local tst=stk(tf,C.gr,2,0)
local tI=Instance.new("TextLabel")tI.Size=UDim2.new(0,36,1,0)tI.Position=UDim2.new(0,10,0,0)tI.BackgroundTransparency=1 tI.Text="✓"tI.TextColor3=C.gr tI.TextSize=24 tI.Font=Enum.Font.GothamBold tI.Parent=tf
local tT=Instance.new("TextLabel")tT.Size=UDim2.new(1,-56,1,0)tT.Position=UDim2.new(0,52,0,0)tT.BackgroundTransparency=1 tT.Text=""tT.TextColor3=C.tx tT.TextSize=14 tT.Font=Enum.Font.GothamBold tT.TextXAlignment=Enum.TextXAlignment.Left tT.Parent=tf
local tg2=0
local function toast(m,ok)tg2=tg2+1 local mg=tg2 tT.Text=m tI.Text=ok and"✓"or"✕"tI.TextColor3=ok and C.gr or C.rd tst.Color=ok and C.gr or C.rd tf.BackgroundTransparency=0 tT.TextTransparency=0 tI.TextTransparency=0 tst.Transparency=0 tf.Visible=true spawn(function()wait(2)if mg~=tg2 then return end TS:Create(tf,TweenInfo.new(0.4),{BackgroundTransparency=1}):Play()TS:Create(tT,TweenInfo.new(0.4),{TextTransparency=1}):Play()TS:Create(tI,TweenInfo.new(0.4),{TextTransparency=1}):Play()TS:Create(tst,TweenInfo.new(0.4),{Transparency=1}):Play()wait(0.5)if mg~=tg2 then return end tf.Visible=false end)end
local pw=math.min(340,Cam.ViewportSize.X-24)local ph=math.min(500,Cam.ViewportSize.Y-60)
local fps=Instance.new("TextLabel")fps.Size=UDim2.new(0,180,0,22)fps.Position=UDim2.new(0.5,-90,0,20)fps.BackgroundColor3=C.deep fps.BackgroundTransparency=0.35 fps.TextColor3=C.cy fps.TextSize=12 fps.Font=Enum.Font.GothamBold fps.ZIndex=999970 fps.Active=false fps.Parent=sg cnr(fps,8)stk(fps,C.cy,1,0.4)
local fc=0 RS.RenderStepped:Connect(function()fc=fc+1 end)
spawn(function()local lt=tick()while sg.Parent do wait(1)local n=tick()local f=math.floor(fc/math.max(n-lt,0.001))fc=0 lt=n local p=0 pcall(function()p=math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue())end)fps.Text="FPS "..f.." | PING "..p.."ms"end end)
local lhF={}for i=1,4 do local fr=Instance.new("Frame")fr.BackgroundColor3=C.rd fr.BackgroundTransparency=1 fr.BorderSizePixel=0 fr.ZIndex=999975 fr.Active=false fr.Parent=sg table.insert(lhF,fr)end
lhF[1].Size=UDim2.new(1,0,0,8)lhF[1].Position=UDim2.new(0,0,0,0)lhF[2].Size=UDim2.new(1,0,0,8)lhF[2].Position=UDim2.new(0,0,1,-8)lhF[3].Size=UDim2.new(0,8,1,0)lhF[3].Position=UDim2.new(0,0,0,0)lhF[4].Size=UDim2.new(0,8,1,0)lhF[4].Position=UDim2.new(1,-8,0,0)
spawn(function()while sg.Parent do local ch=LP.Character local h=ch and ch:FindFirstChildOfClass("Humanoid")if h and S.lowHPWarn and h.Health>0 and h.Health<S.lowHPThreshold then local t=(math.sin(tick()*6)+1)/2 local a=0.55-t*0.35 for _,fr in ipairs(lhF)do fr.BackgroundTransparency=a end else for _,fr in ipairs(lhF)do fr.BackgroundTransparency=1 end end wait(0.05)end end)
local ll=Instance.new("Frame")ll.AnchorPoint=Vector2.new(0.5,0.5)ll.BackgroundColor3=C.cy ll.BackgroundTransparency=0.25 ll.BorderSizePixel=0 ll.ZIndex=999950 ll.Active=false ll.Visible=false ll.Parent=sg
local lt2=Instance.new("Frame")lt2.AnchorPoint=Vector2.new(0.5,0.5)lt2.Size=UDim2.new(0,8,0,8)lt2.BackgroundColor3=C.cy lt2.BackgroundTransparency=0.2 lt2.BorderSizePixel=0 lt2.ZIndex=999951 lt2.Active=false lt2.Visible=false lt2.Parent=sg cnr(lt2,4)
RS.RenderStepped:Connect(function()if not S.aim or not S.aimLaser or not aimT or not aimT.Parent then ll.Visible=false lt2.Visible=false return end local c=WS.CurrentCamera if not c then ll.Visible=false lt2.Visible=false return end local th=aimT:FindFirstChild("HumanoidRootPart")if not th then ll.Visible=false lt2.Visible=false return end local vs=c.ViewportSize local o=Vector2.new(vs.X/2,vs.Y/2)local sp,onS=c:WorldToViewportPoint(th.Position)if not onS or sp.Z<=0 then ll.Visible=false lt2.Visible=false return end local tp=Vector2.new(sp.X,sp.Y)local d=tp-o local L=d.Magnitude if L<2 then ll.Visible=false lt2.Visible=false return end local a=math.deg(math.atan2(d.Y,d.X))local m=(o+tp)/2 ll.Visible=true ll.Position=UDim2.fromOffset(m.X,m.Y)ll.Size=UDim2.fromOffset(L,2)ll.Rotation=a lt2.Visible=true lt2.Position=UDim2.fromOffset(tp.X,tp.Y)end)
-- ===== 菜单 CanvasGroup 包裹 =====
local panCG=Instance.new("CanvasGroup")
panCG.Size=UDim2.new(1,0,1,0)
panCG.BackgroundTransparency=1
panCG.BorderSizePixel=0
panCG.GroupTransparency=1-S.uiOpacity/100
panCG.Parent=sg
local pan=Instance.new("Frame")pan.Size=UDim2.new(0,pw,0,ph)pan.Position=UDim2.new(0.5,-pw/2,0.5,-ph/2)pan.BackgroundColor3=C.bg pan.BorderSizePixel=0 pan.Active=true pan.ClipsDescendants=true pan.Visible=false pan.Parent=panCG cnr(pan,18)stk(pan,Color3.fromRGB(70,100,160),1.5)grd(pan,ColorSequence.new({ColorSequenceKeypoint.new(0,C.bg),ColorSequenceKeypoint.new(1,C.deep)}),90)
local tb=Instance.new("Frame")tb.Size=UDim2.new(1,0,0,60)tb.BackgroundColor3=C.dark tb.BorderSizePixel=0 tb.Parent=pan cnr(tb,18)
local tfx=Instance.new("Frame")tfx.Size=UDim2.new(1,0,0.5,0)tfx.Position=UDim2.new(0,0,0.5,0)tfx.BackgroundColor3=C.dark tfx.BorderSizePixel=0 tfx.Parent=tb
local gs=Instance.new("Frame")gs.Size=UDim2.new(1,0,0,3)gs.BackgroundColor3=Color3.new(1,1,1)gs.BorderSizePixel=0 gs.ZIndex=5 gs.Parent=tb cnr(gs,2)
local gsi=grd(gs,ColorSequence.new({ColorSequenceKeypoint.new(0,C.cy),ColorSequenceKeypoint.new(0.5,C.pu),ColorSequenceKeypoint.new(1,C.pi)}),0)
spawn(function()local o=0 while gs.Parent and gsi.Parent do o=(o+0.006)%1 pcall(function()gsi.Offset=Vector2.new(o,0)end)wait(0.03)end end)
local sDot=Instance.new("Frame")sDot.Size=UDim2.new(0,8,0,8)sDot.Position=UDim2.new(0,16,0,22)sDot.BackgroundColor3=C.gr sDot.BorderSizePixel=0 sDot.ZIndex=6 sDot.Parent=tb cnr(sDot,4)
local sH=Instance.new("Frame")sH.Size=UDim2.new(0,8,0,8)sH.Position=UDim2.new(0,16,0,22)sH.BackgroundColor3=C.gr sH.BackgroundTransparency=0.6 sH.BorderSizePixel=0 sH.ZIndex=5 sH.Parent=tb cnr(sH,4)
spawn(function()while sH.Parent do sH.Size=UDim2.new(0,8,0,8)sH.Position=UDim2.new(0,16,0,22)sH.BackgroundTransparency=0.5 TS:Create(sH,TweenInfo.new(1.4,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{Size=UDim2.new(0,20,0,20),Position=UDim2.new(0,10,0,16),BackgroundTransparency=1}):Play()wait(1.4)end end)
local tLb=Instance.new("TextLabel")tLb.Size=UDim2.new(1,-110,0,22)tLb.Position=UDim2.new(0,32,0,10)tLb.BackgroundTransparency=1 tLb.Text="GENERAL TOOLS"tLb.TextColor3=Color3.new(1,1,1)tLb.TextSize=16 tLb.Font=Enum.Font.GothamBold tLb.TextXAlignment=Enum.TextXAlignment.Left tLb.ZIndex=4 tLb.Parent=tb grd(tLb,ColorSequence.new({ColorSequenceKeypoint.new(0,C.cy),ColorSequenceKeypoint.new(0.6,C.tx),ColorSequenceKeypoint.new(1,Color3.fromRGB(200,210,255))}),0)
local sLb=Instance.new("TextLabel")sLb.Size=UDim2.new(1,-110,0,12)sLb.Position=UDim2.new(0,32,1,-22)sLb.BackgroundTransparency=1 sLb.Text="V50"sLb.TextColor3=C.dm sLb.TextSize=8 sLb.Font=Enum.Font.GothamBold sLb.TextXAlignment=Enum.TextXAlignment.Left sLb.ZIndex=4 sLb.Parent=tb
local minB=Instance.new("TextButton")minB.Size=UDim2.new(0,30,0,30)minB.Position=UDim2.new(1,-76,0.5,-15)minB.BackgroundColor3=C.card minB.BackgroundTransparency=0.3 minB.Text="−"minB.TextColor3=C.cy minB.TextSize=20 minB.Font=Enum.Font.GothamBold minB.BorderSizePixel=0 minB.ZIndex=4 minB.Parent=tb cnr(minB,9)stk(minB,C.cy,1,0.6)
local closeB=Instance.new("TextButton")closeB.Size=UDim2.new(0,30,0,30)closeB.Position=UDim2.new(1,-42,0.5,-15)closeB.BackgroundColor3=C.card closeB.BackgroundTransparency=0.3 closeB.Text="X"closeB.TextColor3=C.dg closeB.TextSize=15 closeB.Font=Enum.Font.GothamBold closeB.BorderSizePixel=0 closeB.ZIndex=4 closeB.Parent=tb cnr(closeB,9)stk(closeB,C.dg,1,0.6)
local tBar=Instance.new("Frame")tBar.Size=UDim2.new(1,-24,0,38)tBar.Position=UDim2.new(0,12,0,66)tBar.BackgroundColor3=C.deep tBar.BackgroundTransparency=0.3 tBar.BorderSizePixel=0 tBar.Parent=pan cnr(tBar,10)stk(tBar,C.st,1,0.4)
local tCnt=5 local tWR=1/tCnt
local tInd=Instance.new("Frame")tInd.Size=UDim2.new(tWR,-4,1,-8)tInd.Position=UDim2.new(0,2,0,4)tInd.BackgroundColor3=C.cy tInd.BorderSizePixel=0 tInd.ZIndex=1 tInd.Parent=tBar cnr(tInd,8)stk(tInd,Color3.new(1,1,1),1.5,0.4)
local cA=Instance.new("Frame")cA.Size=UDim2.new(1,-16,1,-122)cA.Position=UDim2.new(0,8,0,110)cA.BackgroundTransparency=1 cA.Parent=pan
local function mkSF()local sf=Instance.new("ScrollingFrame")sf.Size=UDim2.new(1,0,1,0)sf.BackgroundTransparency=1 sf.BorderSizePixel=0 sf.AutomaticCanvasSize=Enum.AutomaticSize.Y sf.ScrollBarThickness=3 sf.ScrollBarImageColor3=C.pu sf.ScrollBarImageTransparency=0.3 sf.Visible=false sf.Parent=cA local l=Instance.new("UIListLayout")l.Padding=UDim.new(0,10)l.SortOrder=Enum.SortOrder.LayoutOrder l.Parent=sf local p=Instance.new("UIPadding")p.PaddingTop=UDim.new(0,4)p.PaddingBottom=UDim.new(0,4)p.PaddingLeft=UDim.new(0,2)p.PaddingRight=UDim.new(0,2)p.Parent=sf return sf end
local tMv=mkSF()local tAt=mkSF()local tEs=mkSF()local tAi=mkSF()local tSt=mkSF()
local Tabs={{name="移动",color=C.cy,frame=tMv},{name="属性",color=C.pu,frame=tAt},{name="透视",color=C.gr,frame=tEs},{name="自瞄",color=C.rd,frame=tAi},{name="设置",color=C.gold,frame=tSt}}
local tBt={}local cT=1
local function swT(i)if i==cT then return end cT=i TS:Create(tInd,TweenInfo.new(0.3,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{Position=UDim2.new((i-1)*tWR,2,0,4),BackgroundColor3=Tabs[i].color}):Play()for k,t in ipairs(Tabs)do TS:Create(tBt[k],TweenInfo.new(0.2),{TextColor3=(k==i)and C.bg or C.dm}):Play()t.frame.Visible=(k==i)end end
for i,t in ipairs(Tabs)do local b=Instance.new("TextButton")b.Size=UDim2.new(tWR,-4,1,-8)b.Position=UDim2.new((i-1)*tWR,2,0,4)b.BackgroundTransparency=1 b.Text=t.name b.TextColor3=C.dm b.TextSize=10 b.Font=Enum.Font.GothamBold b.BorderSizePixel=0 b.ZIndex=5 b.Parent=tBar b.MouseButton1Click:Connect(function()swT(i)end)table.insert(tBt,b)end
tMv.Visible=true tBt[1].TextColor3=C.bg
local lo=0
local function mkCard(p)lo=lo+1 local c=Instance.new("Frame")c.Size=UDim2.new(1,-8,0,0)c.BackgroundColor3=C.card c.BackgroundTransparency=0.05 c.AutomaticSize=Enum.AutomaticSize.Y c.LayoutOrder=lo c.Parent=p cnr(c,14)stk(c,C.st,1,0.3)local pd=Instance.new("UIPadding")pd.PaddingTop=UDim.new(0,14)pd.PaddingBottom=UDim.new(0,14)pd.PaddingLeft=UDim.new(0,16)pd.PaddingRight=UDim.new(0,14)pd.Parent=c local l=Instance.new("UIListLayout")l.Padding=UDim.new(0,9)l.SortOrder=Enum.SortOrder.LayoutOrder l.Parent=c return c end
local function mkSec(p,t,cl)lo=lo+1 local r=Instance.new("Frame")r.Size=UDim2.new(1,0,0,22)r.BackgroundTransparency=1 r.LayoutOrder=lo r.Parent=p local m=Instance.new("Frame")m.Size=UDim2.new(0,3,0,14)m.Position=UDim2.new(0,0,0.5,-7)m.BackgroundColor3=cl m.BorderSizePixel=0 m.ZIndex=1 m.Parent=r cnr(m,2)local l=Instance.new("TextLabel")l.Size=UDim2.new(1,-18,1,0)l.Position=UDim2.new(0,14,0,0)l.BackgroundTransparency=1 l.Text=t l.TextColor3=C.tx l.TextSize=11 l.Font=Enum.Font.GothamBold l.TextXAlignment=Enum.TextXAlignment.Left l.Parent=r end
local function mkTog(p,n,gf,sf,ac)ac=ac or C.cy lo=lo+1 local b=Instance.new("TextButton")b.Size=UDim2.new(1,0,0,42)b.BackgroundColor3=C.deep b.BackgroundTransparency=0.3 b.Text=""b.LayoutOrder=lo b.Parent=p cnr(b,10)local bs=stk(b,C.st,1,0.4)local l=Instance.new("TextLabel")l.Size=UDim2.new(0.75,0,1,0)l.Position=UDim2.new(0,14,0,0)l.BackgroundTransparency=1 l.Text=n l.TextColor3=C.tx l.TextSize=12 l.Font=Enum.Font.GothamBold l.TextXAlignment=Enum.TextXAlignment.Left l.Parent=b local dO=Instance.new("Frame")dO.Size=UDim2.new(0,20,0,20)dO.Position=UDim2.new(1,-34,0.5,-10)dO.BackgroundColor3=C.bg dO.BorderSizePixel=0 dO.Parent=b cnr(dO,10)local dOS=stk(dO,C.st,1.5,0.2)local d=Instance.new("Frame")d.Size=UDim2.new(0,10,0,10)d.Position=UDim2.new(0.5,-5,0.5,-5)d.BackgroundColor3=C.dg d.BackgroundTransparency=0.4 d.BorderSizePixel=0 d.Parent=dO cnr(d,5)local function ap()if gf()then dO.BackgroundColor3=C.deep dOS.Color=ac dOS.Transparency=0 dOS.Thickness=2 d.BackgroundColor3=ac d.BackgroundTransparency=0 d.Size=UDim2.new(0,12,0,12)d.Position=UDim2.new(0.5,-6,0.5,-6)bs.Color=ac else dO.BackgroundColor3=C.bg dOS.Color=C.st dOS.Transparency=0.2 dOS.Thickness=1.5 d.BackgroundColor3=C.dg d.BackgroundTransparency=0.4 d.Size=UDim2.new(0,10,0,10)d.Position=UDim2.new(0.5,-5,0.5,-5)bs.Color=C.st end end ap()table.insert(tRefs,ap)b.MouseButton1Click:Connect(function()local nv=not gf()sf(nv)ap()TS:Create(b,TweenInfo.new(0.1),{Size=UDim2.new(0.96,0,0,42)}):Play()wait(0.1)TS:Create(b,TweenInfo.new(0.3,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{Size=UDim2.new(1,0,0,42)}):Play()end)end
local function mkSld(p,n,gf,sf,mn,mx,st,ac)ac=ac or C.cy lo=lo+1 local w=Instance.new("Frame")w.Size=UDim2.new(1,0,0,52)w.BackgroundTransparency=1 w.LayoutOrder=lo w.Parent=p local nR=Instance.new("Frame")nR.Size=UDim2.new(1,0,0,20)nR.BackgroundTransparency=1 nR.Parent=w local l=Instance.new("TextLabel")l.Size=UDim2.new(0.65,0,1,0)l.BackgroundTransparency=1 l.Text=n l.TextColor3=C.dm l.TextSize=11 l.Font=Enum.Font.GothamBold l.TextXAlignment=Enum.TextXAlignment.Left l.Parent=nR local vB=Instance.new("Frame")vB.Size=UDim2.new(0,52,0,18)vB.Position=UDim2.new(1,-52,0.5,-9)vB.BackgroundColor3=C.deep vB.BorderSizePixel=0 vB.Parent=nR cnr(vB,6)stk(vB,ac,1,0.5)local vL=Instance.new("TextLabel")vL.Size=UDim2.new(1,0,1,0)vL.BackgroundTransparency=1 vL.Text=tostring(gf())vL.TextColor3=ac vL.TextSize=11 vL.Font=Enum.Font.GothamBold vL.Parent=vB local tr=Instance.new("Frame")tr.Size=UDim2.new(1,0,0,6)tr.Position=UDim2.new(0,0,0,30)tr.BackgroundColor3=C.deep tr.BorderSizePixel=0 tr.Parent=w cnr(tr,3)stk(tr,C.st,1,0.4)local ir=(gf()-mn)/(mx-mn)local f=Instance.new("Frame")f.Size=UDim2.new(ir,0,1,0)f.BackgroundColor3=Color3.new(1,1,1)f.BorderSizePixel=0 f.Parent=tr cnr(f,3)grd(f,ColorSequence.new({ColorSequenceKeypoint.new(0,ac),ColorSequenceKeypoint.new(1,C.pu)}),0)local h=Instance.new("Frame")h.Size=UDim2.new(0,14,0,14)h.Position=UDim2.new(ir,0,0.5,-7)h.BackgroundColor3=Color3.new(1,1,1)h.BorderSizePixel=0 h.ZIndex=3 h.Parent=tr cnr(h,7)local dr=false local function uX(x)local tp=tr.AbsolutePosition.X local ts=tr.AbsoluteSize.X local r=math.clamp((x-tp)/ts,0,1)local v=mn+(mx-mn)*r v=math.floor(v/st+0.5)*st if v<mn then v=mn end if v>mx then v=mx end f.Size=UDim2.new((v-mn)/(mx-mn),0,1,0)h.Position=UDim2.new((v-mn)/(mx-mn),0,0.5,-7)vL.Text=tostring(v)sf(v)end local function rf()local v=gf()local r=(v-mn)/(mx-mn)f.Size=UDim2.new(r,0,1,0)h.Position=UDim2.new(r,0,0.5,-7)vL.Text=tostring(v)end table.insert(sRefs,rf)tr.InputBegan:Connect(function(i)if i.UserInputType==Enum.UserInputType.Touch or i.UserInputType==Enum.UserInputType.MouseButton1 then dr=true uX(i.Position.X)end end)UIS.InputChanged:Connect(function(i)if dr and(i.UserInputType==Enum.UserInputType.Touch or i.UserInputType==Enum.UserInputType.MouseMovement)then uX(i.Position.X)end end)UIS.InputEnded:Connect(function(i)if i.UserInputType==Enum.UserInputType.Touch or i.UserInputType==Enum.UserInputType.MouseButton1 then dr=false end end)end
local function mkSeg(p,op,d,cb,ac,gt)ac=ac or C.cy lo=lo+1 local r=Instance.new("Frame")r.Size=UDim2.new(1,0,0,36)r.BackgroundColor3=C.deep r.BackgroundTransparency=0.3 r.BorderSizePixel=0 r.LayoutOrder=lo r.Parent=p cnr(r,9)stk(r,C.st,1,0.4)local bs={}local n=#op local function uh(si)for i,b in ipairs(bs)do TS:Create(b,TweenInfo.new(0.2),{BackgroundTransparency=(i==si)and 0 or 1,TextColor3=(i==si)and C.bg or C.dm}):Play()end end for i=1,n do local b=Instance.new("TextButton")b.Size=UDim2.new(1/n,-6,1,-8)b.Position=UDim2.new((i-1)/n,3,0,4)b.BackgroundColor3=ac b.BackgroundTransparency=1 b.Text=op[i]b.TextColor3=C.dm b.TextSize=10 b.Font=Enum.Font.GothamBold b.BorderSizePixel=0 b.Parent=r cnr(b,6)b.MouseButton1Click:Connect(function()uh(i)cb(i)end)table.insert(bs,b)end local function sy()local cu=d if gt then cu=gt()end if type(cu)=="number"and cu>=1 and cu<=n then uh(cu)end end sy()table.insert(gRefs,sy)end
local function mkAct(p,t,cb,ac)ac=ac or C.pi lo=lo+1 local b=Instance.new("TextButton")b.Size=UDim2.new(1,0,0,38)b.BackgroundColor3=Color3.new(1,1,1)b.Text=t b.TextColor3=Color3.new(1,1,1)b.TextStrokeTransparency=0 b.TextStrokeColor3=Color3.new(0,0,0)b.TextSize=12 b.Font=Enum.Font.GothamBold b.LayoutOrder=lo b.Parent=p cnr(b,10)stk(b,ac,1,0.4)grd(b,ColorSequence.new({ColorSequenceKeypoint.new(0,ac),ColorSequenceKeypoint.new(1,C.pu)}),0)b.MouseButton1Click:Connect(function()TS:Create(b,TweenInfo.new(0.1),{Size=UDim2.new(0.95,0,0,38)}):Play()wait(0.1)TS:Create(b,TweenInfo.new(0.3,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{Size=UDim2.new(1,0,0,38)}):Play()if cb then cb()end end)end
local pD=false local dO=nil
tb.InputBegan:Connect(function(i)if i.UserInputType==Enum.UserInputType.Touch or i.UserInputType==Enum.UserInputType.MouseButton1 then pD=true dO=i.Position-Vector3.new(pan.AbsolutePosition.X,pan.AbsolutePosition.Y,0)end end)
UIS.InputChanged:Connect(function(i)if pD and(i.UserInputType==Enum.UserInputType.Touch or i.UserInputType==Enum.UserInputType.MouseMovement)then pan.Position=UDim2.fromOffset(i.Position.X-dO.X,i.Position.Y-dO.Y)end end)
UIS.InputEnded:Connect(function(i)if i.UserInputType==Enum.UserInputType.Touch or i.UserInputType==Enum.UserInputType.MouseButton1 then pD=false end end)
local cld=false
minB.MouseButton1Click:Connect(function()cld=not cld if cld then tBar.Visible=false cA.Visible=false TS:Create(pan,TweenInfo.new(0.35,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{Size=UDim2.new(0,pw,0,60)}):Play()minB.Text="+"else tBar.Visible=true cA.Visible=true TS:Create(pan,TweenInfo.new(0.4,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{Size=UDim2.new(0,pw,0,ph)}):Play()minB.Text="−"end end)
-- ===== FPS 优化（轻重度真区分） =====
local fpsOrig={shadow=LT.GlobalShadows,fogEnd=LT.FogEnd,fogStart=LT.FogStart,envDiff=LT.EnvironmentDiffuseScale,envSpec=LT.EnvironmentSpecularScale}
local fpsPostFX={}
for _,v in ipairs(LT:GetChildren())do
    if v:IsA("PostEffect")then
        table.insert(fpsPostFX,{fx=v,en=v.Enabled})
    end
end
local fpsAtmo={}
for _,v in ipairs(LT:GetChildren())do
    if v:IsA("Atmosphere")then
        table.insert(fpsAtmo,{obj=v,en=v.Enabled})
    end
end
local waterOrig={}
pcall(function()
    local ter=WS:FindFirstChildOfClass("Terrain")
    if ter then
        waterOrig.wave=ter.WaterWaveSize
        waterOrig.reflect=ter.WaterReflectance
        waterOrig.trans=ter.WaterTransparency
    end
end)
local function applyFPSBoost()
    if not S.fpsBoost then return end
    -- 轻度：关阴影 + 关雾 + 关大气
    pcall(function() LT.GlobalShadows=false end)
    pcall(function() LT.FogEnd=100000 LT.FogStart=100000 end)
    for _,e in ipairs(fpsAtmo)do
        if e.obj and e.obj.Parent then pcall(function() e.obj.Enabled=false end) end
    end
    if S.fpsLevel>=2 then
        -- 中度：再关后处理 + 环境光照 + 水面效果
        for _,e in ipairs(fpsPostFX)do
            if e.fx and e.fx.Parent and e.fx.Name~="GT_CC" then
                pcall(function() e.fx.Enabled=false end)
            end
        end
        pcall(function() LT.EnvironmentDiffuseScale=0 LT.EnvironmentSpecularScale=0 end)
        pcall(function()
            local ter=WS:FindFirstChildOfClass("Terrain")
            if ter then
                ter.WaterWaveSize=0
                ter.WaterReflectance=0
                ter.WaterTransparency=1
            end
        end)
    end
end
local function restoreFPS()
    pcall(function() LT.GlobalShadows=fpsOrig.shadow end)
    pcall(function() LT.FogEnd=fpsOrig.fogEnd LT.FogStart=fpsOrig.fogStart end)
    pcall(function() LT.EnvironmentDiffuseScale=fpsOrig.envDiff LT.EnvironmentSpecularScale=fpsOrig.envSpec end)
    for _,e in ipairs(fpsAtmo)do
        if e.obj and e.obj.Parent then pcall(function() e.obj.Enabled=e.en end) end
    end
    for _,e in ipairs(fpsPostFX)do
        if e.fx and e.fx.Parent then pcall(function() e.fx.Enabled=e.en end) end
    end
    pcall(function()
        local ter=WS:FindFirstChildOfClass("Terrain")
        if ter then
            if waterOrig.wave then ter.WaterWaveSize=waterOrig.wave end
            if waterOrig.reflect then ter.WaterReflectance=waterOrig.reflect end
            if waterOrig.trans then ter.WaterTransparency=waterOrig.trans end
        end
    end)
end
spawn(function()
    while sg.Parent do
        if S.fpsBoost then pcall(applyFPSBoost) end
        task.wait(1)
    end
end)
-- ===== Humanoid 扫描 =====
task.spawn(function()
    local count=0
    for _,p in ipairs(Players:GetPlayers())do
        if p.Character then
            local h=p.Character:FindFirstChildOfClass("Humanoid")
            if h then humans[h]=true end
        end
        count=count+1
        if count%200==0 then task.wait() end
    end
    for _,d in ipairs(WS:GetDescendants())do
        if d:IsA("Humanoid")then humans[d]=true end
        count=count+1
        if count%200==0 then task.wait() end
    end
end)
WS.DescendantAdded:Connect(function(d)if d:IsA("Humanoid")then humans[d]=true end end)
WS.DescendantRemoving:Connect(function(d)if d:IsA("Humanoid")then humans[d]=nil end end)
spawn(function()while sg.Parent do wait(1.5)for h in pairs(humans)do if not h.Parent or h.Health<=0 then humans[h]=nil end end end end)
local hF=Instance.new("Frame")hF.Size=UDim2.new(1,0,1,0)hF.BackgroundColor3=Color3.fromRGB(255,0,0)hF.BackgroundTransparency=1 hF.BorderSizePixel=0 hF.ZIndex=999980 hF.Active=false hF.Parent=sg
spawn(function()while sg.Parent do local ch=LP.Character local h=ch and ch:FindFirstChildOfClass("Humanoid")if h then if lastHP==nil then lastHP=h.Health end if h.Health<lastHP-0.5 and S.hurtFlash then hF.BackgroundTransparency=0.55 if hurtT then hurtT:Cancel()end hurtT=TS:Create(hF,TweenInfo.new(0.5,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{BackgroundTransparency=1})hurtT:Play()end lastHP=h.Health end wait(0.05)end end)
local rF=Instance.new("Frame")rF.Size=UDim2.fromOffset(S.radarSize,S.radarSize)rF.Position=UDim2.new(1,-S.radarSize-16,0,100)rF.BackgroundColor3=Color3.fromRGB(8,12,24)rF.BackgroundTransparency=0.35 rF.BorderSizePixel=0 rF.ZIndex=100 rF.Visible=false rF.Parent=sg cnr(rF,9999)stk(rF,C.cy,1.5,0.4)
local rS=Instance.new("Frame")rS.Size=UDim2.new(0,6,0,6)rS.Position=UDim2.new(0.5,-3,0.5,-3)rS.BackgroundColor3=C.cy rS.BorderSizePixel=0 rS.ZIndex=102 rS.Parent=rF cnr(rS,3)
local rC=Instance.new("Frame")rC.Size=UDim2.new(0,3,0,S.radarSize/2-4)rC.Position=UDim2.new(0.5,-1.5,0.5,-S.radarSize/2+4)rC.BackgroundColor3=C.cy rC.BackgroundTransparency=0.6 rC.BorderSizePixel=0 rC.ZIndex=101 rC.Parent=rF cnr(rC,1)
RS.Heartbeat:Connect(function()if not S.radar then rF.Visible=false for _,d in pairs(radarD)do d:Destroy()end radarD={}return end rF.Visible=true rF.Size=UDim2.fromOffset(S.radarSize,S.radarSize)rC.Size=UDim2.new(0,3,0,S.radarSize/2-4)rC.Position=UDim2.new(0.5,-1.5,0.5,-S.radarSize/2+4)local c=WS.CurrentCamera local ch=LP.Character local hr=ch and ch:FindFirstChild("HumanoidRootPart")if not c or not hr then return end local mp=hr.Position local cl=c.CFrame.LookVector local fl=Vector3.new(cl.X,0,cl.Z)if fl.Magnitude<0.01 then fl=Vector3.new(0,0,-1)end fl=fl.Unit local fr=Vector3.new(fl.Z,0,-fl.X)local cx=S.radarSize/2 local cy=S.radarSize/2 local sc=(S.radarSize/2)/S.radarRange local ac={}for h in pairs(humans)do if h and h.Parent and h.Health>0 then local m=h.Parent if m and m:IsA("Model")and not isSelf(m)then local t=m:FindFirstChild("HumanoidRootPart")if t then local rl=t.Position-mp local ds=Vector3.new(rl.X,0,rl.Z).Magnitude if ds<=S.radarRange then local lx=rl:Dot(fr)local ly=rl:Dot(fl)local dc if isTeam(m)then dc=C.gr elseif getP(m)then dc=C.rd else dc=C.pi end ac[m]={x=cx+lx*sc,y=cy-ly*sc,color=dc}end end end end end for m,d in pairs(radarD)do if not ac[m]then d:Destroy()radarD[m]=nil end end for m,p in pairs(ac)do local d=radarD[m]if not d then d=Instance.new("Frame")d.Size=UDim2.new(0,6,0,6)d.BorderSizePixel=0 d.ZIndex=103 d.Parent=rF cnr(d,3)radarD[m]=d end d.Position=UDim2.fromOffset(p.x-3,p.y-3)d.BackgroundColor3=p.color end end)
local function rEL()if not entF or not entF.Parent then return end for _,c in ipairs(entF:GetChildren())do if c:IsA("Frame")and c.Name=="Row"then c:Destroy()end end if not S.entList then return end local ch=LP.Character local hr=ch and ch:FindFirstChild("HumanoidRootPart")if not hr then return end local mp=hr.Position local ls={}for h in pairs(humans)do if h and h.Parent and h.Health>0 then local m=h.Parent if m and m:IsA("Model")and not isSelf(m)then local t=m:FindFirstChild("HumanoidRootPart")if t then local ds=(t.Position-mp).Magnitude if ds<=S.espMax then table.insert(ls,{model=m,dist=ds,team=isTeam(m),isPlayer=getP(m)~=nil})end end end end end table.sort(ls,function(a,b)return a.dist<b.dist end)for i,e in ipairs(ls)do if i>8 then break end local r=Instance.new("Frame")r.Name="Row"r.Size=UDim2.new(1,0,0,28)r.Position=UDim2.new(0,0,0,(i-1)*30)r.BackgroundColor3=C.deep r.BackgroundTransparency=0.4 r.Parent=entF cnr(r,6)local nl=Instance.new("TextLabel")nl.Size=UDim2.new(0.6,0,1,0)nl.Position=UDim2.new(0,8,0,0)nl.BackgroundTransparency=1 nl.Text=e.model.Name if e.team then nl.TextColor3=C.gr elseif e.isPlayer then nl.TextColor3=C.cy else nl.TextColor3=C.pi end nl.TextSize=11 nl.Font=Enum.Font.GothamBold nl.TextXAlignment=Enum.TextXAlignment.Left nl.Parent=r local dl=Instance.new("TextLabel")dl.Size=UDim2.new(0.2,0,1,0)dl.Position=UDim2.new(0.6,0,0,0)dl.BackgroundTransparency=1 dl.Text=math.floor(e.dist).."m"dl.TextColor3=C.dm dl.TextSize=10 dl.Font=Enum.Font.Gotham dl.Parent=r local tb2=Instance.new("TextButton")tb2.Size=UDim2.new(0.18,0,1,-6)tb2.Position=UDim2.new(0.81,0,0,3)tb2.BackgroundColor3=C.gr tb2.Text="T"tb2.TextColor3=Color3.new(1,1,1)tb2.TextSize=10 tb2.Font=Enum.Font.GothamBold tb2.Parent=r cnr(tb2,5)tb2.MouseButton1Click:Connect(function()local c=LP.Character local mh=c and c:FindFirstChild("HumanoidRootPart")local th=e.model:FindFirstChild("HumanoidRootPart")if mh and th then local dr=Vector3.new(mh.Position.X-th.Position.X,0,mh.Position.Z-th.Position.Z)if dr.Magnitude<0.1 then dr=Vector3.new(1,0,0)end dr=dr.Unit*3 mh.CFrame=CFrame.new(th.Position+dr+Vector3.new(0,2,0))end end)end end
spawn(function()while sg.Parent do wait(0.6)if S.entList then rEL()end end end)
local fC=Instance.new("Frame")fC.AnchorPoint=Vector2.new(0.5,0.5)fC.Position=UDim2.new(0.5,0,0.5,0)fC.BackgroundTransparency=1 fC.ZIndex=5 fC.Visible=false fC.Parent=sg cnr(fC,9999)stk(fC,C.rd,1.5,0.35)
RS.RenderStepped:Connect(function()if not(S.aim and S.aimCircle)then fC.Visible=false return end local c=WS.CurrentCamera if not c then return end local vp=c.ViewportSize local r=(vp.Y/2)*math.tan(math.rad(S.aimFov/2))/math.tan(math.rad(c.FieldOfView/2))local mr=math.min(vp.X,vp.Y)/2-5 if r>mr then r=mr end if r<4 then r=4 end fC.Visible=true fC.Size=UDim2.fromOffset(r*2,r*2)end)
local function gAP(m)if S.aimPart=="Head"then return m:FindFirstChild("Head")or m:FindFirstChild("UpperTorso")or m:FindFirstChild("Torso")or m:FindFirstChild("HumanoidRootPart")elseif S.aimPart=="Torso"then return m:FindFirstChild("UpperTorso")or m:FindFirstChild("Torso")or m:FindFirstChild("HumanoidRootPart")else return m:FindFirstChild("HumanoidRootPart")end end
local function hasLOS(tp)local c=WS.CurrentCamera if not c then return true end local o=c.CFrame.Position local d=tp.Position-o if d.Magnitude<0.1 then return true end local rp=RaycastParams.new()pcall(function()rp.FilterType=Enum.RaycastFilterType.Exclude end)local fl={}if LP.Character then table.insert(fl,LP.Character)end if tp.Parent then table.insert(fl,tp.Parent)end rp.FilterDescendantsInstances=fl return WS:Raycast(o,d,rp)==nil end
local function pTF(m)local p=getP(m)if S.aimTargetMode=="player"then return p~=nil end if S.aimTargetMode=="npc"then return p==nil end return true end
local function fBT()local c=WS.CurrentCamera local ch=LP.Character local hr=ch and ch:FindFirstChild("HumanoidRootPart")if not c or not hr then return nil end local mt=LP.Team local cp=c.CFrame.Position local lv=c.CFrame.LookVector local best=nil local bs=nil local sb=1-math.clamp(S.aimStick/100,0,0.9)if S.aimPriority=="crosshair"then bs=S.aimFov/2 elseif S.aimPriority=="distance"then bs=S.aimDist elseif S.aimPriority=="health"then bs=math.huge else bs=S.aimDist end for h in pairs(humans)do if h and h.Parent and h.Health>0 then local m=h.Parent if m and m:IsA("Model")and not isSelf(m)and pTF(m)then local t=m:FindFirstChild("HumanoidRootPart")if t then local ds=(t.Position-hr.Position).Magnitude if ds<=S.aimDist then local sk=false if S.aimTeam and mt then local p=getP(m)if p and p.Team and p.Team==mt then sk=true end end if not sk then local vs=true if S.aimWall then vs=hasLOS(gAP(m)or t)end if vs then local pk=false local ed=ds if m==aimT then ed=ds*sb end if S.aimPriority=="crosshair"then local tt=t.Position-cp if tt.Magnitude>0.1 then tt=tt.Unit local an=math.deg(math.acos(math.clamp(lv:Dot(tt),-1,1)))if an<=S.aimFov/2 and an<bs then bs=an pk=true end end elseif S.aimPriority=="health"then if h.Health<bs then bs=h.Health pk=true end else if ed<bs then bs=ed pk=true end end if pk then best=m end end end end end end end end return best end
-- ===== 飞行（原版 + 方向修正） =====
local function sFly()local ch=LP.Character local hr=ch and ch:FindFirstChild("HumanoidRootPart")if not hr then return end for _,v in pairs(ch:GetDescendants())do if v:IsA("BasePart")then v.CanCollide=false end end flyG=Instance.new("BodyGyro")flyG.P=9e4 flyG.MaxTorque=Vector3.new(9e9,9e9,9e9)flyG.CFrame=hr.CFrame flyG.Parent=hr flyV=Instance.new("BodyVelocity")flyV.MaxForce=Vector3.new(9e9,9e9,9e9)flyV.Velocity=Vector3.zero flyV.Parent=hr flyC=RS.RenderStepped:Connect(function()if not S.fly then return end local c=LP.Character local mh=c and c:FindFirstChild("HumanoidRootPart")local h=c and c:FindFirstChildOfClass("Humanoid")if not mh or not flyG or not flyV then return end local cm=WS.CurrentCamera flyG.CFrame=cm.CFrame local mv=Vector3.zero if h and h.MoveDirection.Magnitude>0.05 then local md=h.MoveDirection local cl=cm.CFrame.LookVector local fl=Vector3.new(cl.X,0,cl.Z)if fl.Magnitude>0.01 then fl=fl.Unit local fr=Vector3.new(-fl.Z,0,fl.X)local fw=md:Dot(fl)local rt=md:Dot(fr)mv=cm.CFrame.LookVector*fw+cm.CFrame.RightVector*rt end end if S.flyUp then mv=mv+cm.CFrame.UpVector end if S.flyDown then mv=mv-cm.CFrame.UpVector end if mv.Magnitude>0.05 then flyV.Velocity=mv.Unit*S.flySpeed else flyV.Velocity=Vector3.zero end end)end
local function stFly()if flyC then flyC:Disconnect()flyC=nil end if flyG then flyG:Destroy()flyG=nil end if flyV then flyV:Destroy()flyV=nil end local ch=LP.Character if ch then for _,v in pairs(ch:GetDescendants())do if v:IsA("BasePart")then v.CanCollide=true end end end end
RS:BindToRenderStep("GT_Aim",201,function()if not S.aim then aimT=nil return end local c=WS.CurrentCamera if not c then return end if aimT then local h=aimT:FindFirstChildOfClass("Humanoid")if not h or h.Health<=0 or not aimT.Parent or isSelf(aimT)then aimT=nil end end if not(S.aimPriority=="lock"and aimT)then aimT=fBT()end if not aimT then return end local tp=gAP(aimT)if not tp then return end local tc=CFrame.new(c.CFrame.Position,tp.Position)if S.aimSmooth>=100 then c.CFrame=tc else c.CFrame=c.CFrame:Lerp(tc,math.clamp(S.aimSmooth/100,0.05,1))end end)
spawn(function()
    while sg.Parent do
        if not S.aggro then
            if next(aggroMarks) then clrAggro() end
            task.wait(0.4)
        else
            local ch=LP.Character
            local hr=ch and ch:FindFirstChild("HumanoidRootPart")
            if hr then
                local mp=hr.Position
                for h in pairs(humans) do
                    if h and h.Parent and h.Health>0 then
                        local m=h.Parent
                        if m:IsA("Model") and not isSelf(m) then
                            local t=m:FindFirstChild("HumanoidRootPart")
                            local head=m:FindFirstChild("Head") or t
                            if t and head then
                                local ds=(t.Position-mp).Magnitude
                                local watching=false
                                if ds<=S.aggroRange then
                                    local toMe=mp-head.Position
                                    if toMe.Magnitude>0.5 then
                                        local ang=math.deg(math.acos(math.clamp(head.CFrame.LookVector:Dot(toMe.Unit),-1,1)))
                                        if ang<=S.aggroFov then watching=true end
                                    end
                                end
                                if watching then
                                    if not aggroMarks[m] then
                                        local bb=Instance.new("BillboardGui")
                                        bb.Adornee=head
                                        bb.Size=UDim2.new(0,36,0,36)
                                        bb.StudsOffset=Vector3.new(0,2.4,0)
                                        bb.AlwaysOnTop=true
                                        bb.MaxDistance=S.aggroRange*2
                                        bb.Parent=sg
                                        local lbl=Instance.new("TextLabel")
                                        lbl.Size=UDim2.new(1,0,1,0)
                                        lbl.BackgroundTransparency=1
                                        lbl.Text="!"
                                        lbl.TextSize=30
                                        lbl.TextColor3=C.rd
                                        lbl.TextStrokeTransparency=0
                                        lbl.TextStrokeColor3=Color3.new(0,0,0)
                                        lbl.Font=Enum.Font.GothamBold
                                        lbl.Parent=bb
                                        aggroMarks[m]=bb
                                    else
                                        local lbl=aggroMarks[m]:FindFirstChildOfClass("TextLabel")
                                        if lbl then lbl.TextTransparency=(math.sin(tick()*8)+1)/2*0.3 end
                                    end
                                else
                                    if aggroMarks[m] then aggroMarks[m]:Destroy() aggroMarks[m]=nil end
                                end
                            end
                        end
                    end
                end
                for m,b in pairs(aggroMarks) do
                    if not m.Parent or not m:FindFirstChildOfClass("Humanoid") then
                        b:Destroy() aggroMarks[m]=nil
                    end
                end
            end
            task.wait(0.08)
        end
    end
end)
local function capJP(h)if not oJP then oJP=h.JumpPower oJH=h.JumpHeight oUJP=h.UseJumpPower end end
RS.Heartbeat:Connect(function()
    local ch=LP.Character
    if not ch then return end
    local h=ch:FindFirstChildOfClass("Humanoid")
    if not h then return end
    capJP(h)
    if S.speedOn then
        if h.WalkSpeed~=BASE_WS then h.WalkSpeed=BASE_WS end
        local hr=ch:FindFirstChild("HumanoidRootPart")
        if hr then
            local mv=h.MoveDirection
            local curV=hr.AssemblyLinearVelocity
            if mv.Magnitude>0.05 and S.walk>BASE_WS then
                local targetH=mv.Unit*S.walk
                local curH=Vector3.new(curV.X,0,curV.Z)
                local newH=curH:Lerp(targetH,0.35)
                hr.AssemblyLinearVelocity=Vector3.new(newH.X,curV.Y,newH.Z)
            end
        end
    end
    if S.jumpOn then
        local th=S.jp/7.85
        if h.JumpPower~=S.jp then h.JumpPower=S.jp end
        if h.JumpHeight~=th then h.JumpHeight=th end
        if h.UseJumpPower~=true then h.UseJumpPower=true end
    end
end)
local function hookH(h)
    capJP(h)
    h:GetPropertyChangedSignal("JumpPower"):Connect(function()if S.jumpOn and h.JumpPower~=S.jp then h.JumpPower=S.jp end end)
    h:GetPropertyChangedSignal("JumpHeight"):Connect(function()if S.jumpOn then local t=S.jp/7.85 if h.JumpHeight~=t then h.JumpHeight=t end end end)
    h:GetPropertyChangedSignal("UseJumpPower"):Connect(function()if S.jumpOn and h.UseJumpPower~=true then h.UseJumpPower=true end end)
end
-- ===== 兔子跳 =====
local function removeBhop()
    if bhopConn then pcall(function() bhopConn:Disconnect() end) bhopConn=nil end
end
local function installBhop()
    removeBhop()
    local ch=LP.Character
    local h=ch and ch:FindFirstChildOfClass("Humanoid")
    if not h then return end
    bhopConn=h.StateChanged:Connect(function(old,new)
        if not S.bhop then removeBhop() return end
        if not S.speedOn then return end
        if new~=Enum.HumanoidStateType.Landed then return end
        if h.MoveDirection.Magnitude<0.05 then return end
        local now=tick()
        if now-bhopLast<0.08+math.random()*0.04 then return end
        bhopLast=now
        h.Jump=true
    end)
end
LP.CharacterAdded:Connect(function()
    task.wait(0.5)
    if S.bhop then installBhop() end
end)
spawn(function()while sg.Parent do local ch=LP.Character local h=ch and ch:FindFirstChildOfClass("Humanoid")if h and not h:GetAttribute("GT_H")then h:SetAttribute("GT_H",true)pcall(function()hookH(h)end)end wait(1)end end)
RS.Stepped:Connect(function()if not S.noclip then return end local ch=LP.Character if not ch then return end for _,v in pairs(ch:GetDescendants())do if v:IsA("BasePart")and v.CanCollide then v.CanCollide=false end end end)
local function shE(m)if not S.esp or isSelf(m)or not m.Parent then return false end local ch=LP.Character if ch and m~=ch and m:IsDescendantOf(ch)then return false end local h=m:FindFirstChildOfClass("Humanoid")if not h then return false end local p=getP(m)if S.espTarget=="player"then return p~=nil end if S.espTarget=="npc"then return p==nil end return true end
local function gMC(m)if isTeam(m)then return C.gr end local p=getP(m)if p then return C.rd end return C.pi end
local function addE(m)if espO[m]or isSelf(m)then return end local hr=m:FindFirstChild("HumanoidRootPart")local h=m:FindFirstChildOfClass("Humanoid")if not hr or not h then return end local cl=gMC(m)local dt={color=cl,defaultColor=cl}if S.espHL then local hl=Instance.new("Highlight")hl.Adornee=m hl.FillColor=cl hl.OutlineColor=Color3.new(1,1,1)hl.FillTransparency=0.6 hl.OutlineTransparency=0 pcall(function()hl.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop end)hl.Parent=sg dt.highlight=hl end if S.espBox then local bx=Instance.new("Frame")bx.BackgroundTransparency=1 bx.Visible=false bx.ZIndex=3 bx.Parent=sg local s=stk(bx,cl,2,0)dt.box=bx dt.boxStroke=s end if S.espSkel then local sk=m:FindFirstChild("UpperTorso")and SK15 or(m:FindFirstChild("Torso")and SK6 or nil)if sk then dt.skeleton={}for _,pr in ipairs(sk)do local ln=Instance.new("Frame")ln.AnchorPoint=Vector2.new(0.5,0.5)ln.BackgroundColor3=cl ln.BorderSizePixel=0 ln.ZIndex=2 ln.Visible=false ln.Parent=sg table.insert(dt.skeleton,{frame=ln,from=pr[1],to=pr[2]})end end end if S.espTracer then local tr=Instance.new("Frame")tr.AnchorPoint=Vector2.new(0.5,0.5)tr.BackgroundColor3=cl tr.BackgroundTransparency=0.15 tr.BorderSizePixel=0 tr.ZIndex=1 tr.Visible=false tr.Parent=sg dt.tracer=tr end if S.espName or S.espDist or S.espHPNum or S.espTool then local bb=Instance.new("BillboardGui")bb.Adornee=hr bb.Size=UDim2.new(0,180,0,20)bb.StudsOffset=Vector3.new(0,3.2,0)bb.AlwaysOnTop=true bb.MaxDistance=3000 bb.Parent=sg dt.billboard=bb local l=Instance.new("TextLabel")l.Size=UDim2.new(1,0,1,0)l.BackgroundTransparency=1 l.TextColor3=cl l.TextStrokeTransparency=0 l.TextStrokeColor3=Color3.new(0,0,0)l.TextSize=13 l.Font=Enum.Font.GothamBold l.Text=""l.Parent=bb dt.label=l end espO[m]=dt end
local function rmE(m)local dt=espO[m]if not dt then return end if dt.highlight then dt.highlight:Destroy()end if dt.box then dt.box:Destroy()end if dt.billboard then dt.billboard:Destroy()end if dt.tracer then dt.tracer:Destroy()end if dt.skeleton then for _,b in ipairs(dt.skeleton)do b.frame:Destroy()end end espO[m]=nil end
local function rfE()for m,_ in pairs(espO)do rmE(m)end espO={}if not S.esp then return end pcall(function()for _,o in ipairs(WS:GetDescendants())do if o:IsA("Model")and not isSelf(o)and shE(o)then addE(o)end end end)end
RS.RenderStepped:Connect(function()if not S.esp then return end local c=WS.CurrentCamera if not c then return end local vp=c.ViewportSize local sB=Vector2.new(vp.X/2,vp.Y)local ch=LP.Character local hr=ch and ch:FindFirstChild("HumanoidRootPart")local mp=hr and hr.Position for m,dt in pairs(espO)do local t=m:FindFirstChild("HumanoidRootPart")local h=m:FindFirstChildOfClass("Humanoid")if not t or not h or h.Health<=0 or not m.Parent or isSelf(m)then rmE(m)else local iAT=(m==aimT and S.aim and S.aimHL)local cl=iAT and C.gold or dt.defaultColor if dt.highlight then dt.highlight.FillColor=cl end if dt.boxStroke then dt.boxStroke.Color=cl end if dt.label then dt.label.TextColor3=cl end if dt.tracer then dt.tracer.BackgroundColor3=cl end local ds=nil if mp then ds=(t.Position-mp).Magnitude end local iR=true if ds and S.espMax>0 then iR=ds<=S.espMax end if dt.highlight then dt.highlight.FillTransparency=iR and 0.6 or 1 dt.highlight.OutlineTransparency=iR and 0 or 1 end if dt.billboard then dt.billboard.Enabled=iR if iR and dt.label then local pts={}if S.espName then table.insert(pts,m.Name)end if S.espHPNum then table.insert(pts,"HP "..math.floor(h.Health))end if S.espDist and ds then table.insert(pts,math.floor(ds).."m")end if S.espTool then local tl=m:FindFirstChildOfClass("Tool")table.insert(pts,"["..(tl and tl.Name or"无").."]")end dt.label.Text=table.concat(pts,"  ")end end local tp,bp,cx=nil,nil,nil if iR and(dt.box or dt.tracer)then local tw2=t.Position+Vector3.new(0,2.8,0)local bw=t.Position-Vector3.new(0,3,0)local ts,to=c:WorldToViewportPoint(tw2)local bs,bo=c:WorldToViewportPoint(bw)if to and bo and ts.Z>0 and bs.Z>0 then tp=Vector2.new(ts.X,ts.Y)bp=Vector2.new(bs.X,bs.Y)cx=(tp.X+bp.X)/2 if dt.box then local ht=math.abs(bp.Y-tp.Y)local wd=ht*0.55 local yp=math.min(tp.Y,bp.Y)dt.box.Visible=true dt.box.Size=UDim2.fromOffset(wd,ht)dt.box.Position=UDim2.fromOffset(cx-wd/2,yp+S.espYOff)end else if dt.box then dt.box.Visible=false end end end if dt.tracer then if iR and tp and bp then local cX=cx local cY=(tp.Y+bp.Y)/2+S.espYOff local ts2=Vector2.new(cX,cY)local dl=ts2-sB local ln=dl.Magnitude if ln>2 then local an=math.deg(math.atan2(dl.Y,dl.X))local md=(sB+ts2)/2 dt.tracer.Visible=true dt.tracer.Position=UDim2.fromOffset(md.X,md.Y)dt.tracer.Size=UDim2.fromOffset(ln,1.5)dt.tracer.Rotation=an else dt.tracer.Visible=false end else dt.tracer.Visible=false end end if dt.skeleton then if iR then for _,b in ipairs(dt.skeleton)do local pa=m:FindFirstChild(b.from)local pb=m:FindFirstChild(b.to)if pa and pb then local sa,oa=c:WorldToViewportPoint(pa.Position)local sb,ob=c:WorldToViewportPoint(pb.Position)if oa and ob and sa.Z>0 and sb.Z>0 then local a=Vector2.new(sa.X,sa.Y)local b2=Vector2.new(sb.X,sb.Y)local dl=b2-a local ln=dl.Magnitude if ln>1 then local an=math.deg(math.atan2(dl.Y,dl.X))local md=(a+b2)/2 b.frame.Visible=true b.frame.BackgroundColor3=cl b.frame.Position=UDim2.fromOffset(md.X,md.Y+S.espYOff)b.frame.Size=UDim2.fromOffset(ln,2)b.frame.Rotation=an else b.frame.Visible=false end else b.frame.Visible=false end else b.frame.Visible=false end end else for _,b in ipairs(dt.skeleton)do b.frame.Visible=false end end end end end end)
WS.DescendantAdded:Connect(function(d)if not S.esp or not d:IsA("Humanoid")then return end local m=d.Parent if not m or not m:IsA("Model")then return end wait(0.3)if S.esp and m.Parent and not isSelf(m)and shE(m)then addE(m)end end)
WS.DescendantRemoving:Connect(function(d)if espO[d]then rmE(d)end end)
LP.CharacterAdded:Connect(function()for m,_ in pairs(espO)do if isSelf(m)then rmE(m)end end end)
local CF="gt_config.json"
local function saveC()local ok,er=pcall(function()local d=HS:JSONEncode(S)if writefile then writefile(CF,d)else error("no writefile")end end)return ok,er end
local function loadC()local ok,er=pcall(function()if not readfile then error("no readfile")end if not isfile or not isfile(CF)then error("no config")end local d=readfile(CF)local p=HS:JSONDecode(d)for k,v in pairs(p)do if S[k]~=nil then S[k]=v end end for _,fn in ipairs(tRefs)do pcall(fn)end for _,fn in ipairs(sRefs)do pcall(fn)end for _,fn in ipairs(gRefs)do pcall(fn)end if S.fullbright then pcall(setFB,true)end if S.fly then pcall(sFly)end if S.esp then pcall(rfE)end if S.fpsBoost then pcall(applyFPSBoost)end if S.bhop then pcall(installBhop)end pcall(function() panCG.GroupTransparency=1-S.uiOpacity/100 end) if S.entList then if not entF then entF=Instance.new("Frame")entF.Size=UDim2.new(1,0,0,250)entF.BackgroundColor3=C.deep entF.BackgroundTransparency=0.4 entF.BorderSizePixel=0 entF.Parent=entListCard cnr(entF,8)end entF.Visible=true pcall(rEL)end end)return ok,er end
local mC=mkCard(tMv)mkSec(mC,"飞行控制",C.cy)
mkTog(mC,"飞天模式",function()return S.fly end,function(v)S.fly=v if v then sFly()else stFly()end end,C.cy)
mkSld(mC,"飞行速度",function()return S.flySpeed end,function(v)S.flySpeed=v end,10,300,5,C.cy)
mkTog(mC,"上升",function()return S.flyUp end,function(v)S.flyUp=v end,C.cy)
mkTog(mC,"下降",function()return S.flyDown end,function(v)S.flyDown=v end,C.cy)
local tpC=mkCard(tMv)mkSec(tpC,"传送系统",C.cy)
mkAct(tpC,"传送到天空",function()local ch=LP.Character local hr=ch and ch:FindFirstChild("HumanoidRootPart")if hr then hr.CFrame=CFrame.new(hr.Position.X,500,hr.Position.Z)end end,C.cy)
mkAct(tpC,"回原点",function()local ch=LP.Character local hr=ch and ch:FindFirstChild("HumanoidRootPart")if hr then hr.CFrame=CFrame.new(0,50,0)end end,C.cy)
mkAct(tpC,"随机传送",function()local ch=LP.Character local hr=ch and ch:FindFirstChild("HumanoidRootPart")if hr then local a=math.random()*math.pi*2 local d=math.random(100,400)hr.CFrame=CFrame.new(math.cos(a)*d,150,math.sin(a)*d)end end,C.cy)
local aC=mkCard(tAt)mkSec(aC,"移动属性",C.pu)
mkSld(aC,"移动速度",function()return S.walk end,function(v)S.walk=v end,16,500,4,C.pu)
mkSld(aC,"跳跃高度",function()return S.jp end,function(v)S.jp=v end,50,500,5,C.pu)
mkTog(aC,"启用移速",function()return S.speedOn end,function(v)S.speedOn=v end,C.pu)
mkTog(aC,"启用跳跃",function()return S.jumpOn end,function(v)S.jumpOn=v end,C.pu)
mkTog(aC,"兔子跳",function()return S.bhop end,function(v)S.bhop=v if v then installBhop() else removeBhop() end end,C.pu)
mkTog(aC,"穿墙",function()return S.noclip end,function(v)S.noclip=v end,C.pu)
mkSec(aC,"视觉增强",C.pu)
mkTog(aC,"全图高亮度",function()return S.fullbright end,function(v)S.fullbright=v setFB(v)end,C.pu)
local eC=mkCard(tEs)mkSec(eC,"透视总控",C.gr)
mkTog(eC,"启用透视",function()return S.esp end,function(v)S.esp=v rfE()end,C.gr)
mkSec(eC,"目标筛选",C.gr)
mkSeg(eC,{"玩家","NPC","全部"},3,function(i)if i==1 then S.espTarget="player"elseif i==2 then S.espTarget="npc"else S.espTarget="all"end if S.esp then rfE()end end,C.gr,function()if S.espTarget=="player"then return 1 elseif S.espTarget=="npc"then return 2 else return 3 end end)
mkSec(eC,"显示元素",C.gr)
mkTog(eC,"高亮描边",function()return S.espHL end,function(v)S.espHL=v if S.esp then rfE()end end,C.gr)
mkTog(eC,"方框绘制",function()return S.espBox end,function(v)S.espBox=v if S.esp then rfE()end end,C.gr)
mkTog(eC,"骨骼绘制",function()return S.espSkel end,function(v)S.espSkel=v if S.esp then rfE()end end,C.gr)
mkTog(eC,"天线追踪",function()return S.espTracer end,function(v)S.espTracer=v if S.esp then rfE()end end,C.gr)
mkTog(eC,"名字标签",function()return S.espName end,function(v)S.espName=v if S.esp then rfE()end end,C.gr)
mkTog(eC,"距离显示",function()return S.espDist end,function(v)S.espDist=v if S.esp then rfE()end end,C.gr)
mkTog(eC,"血量数字",function()return S.espHPNum end,function(v)S.espHPNum=v if S.esp then rfE()end end,C.gr)
mkTog(eC,"手持物品",function()return S.espTool end,function(v)S.espTool=v if S.esp then rfE()end end,C.gr)
mkSec(eC,"特殊功能",C.gr)
mkTog(eC,"队友变绿",function()return S.espTeamColor end,function(v)S.espTeamColor=v if S.esp then rfE()end end,C.gr)
mkSld(eC,"绘制距离",function()return S.espMax end,function(v)S.espMax=v end,30,1500,10,C.gr)
mkSld(eC,"Y偏移",function()return S.espYOff end,function(v)S.espYOff=v end,-60,60,1,C.gr)
local rC2=mkCard(tEs)mkSec(rC2,"雷达",C.gr)
mkTog(rC2,"启用雷达",function()return S.radar end,function(v)S.radar=v end,C.gr)
mkSld(rC2,"雷达范围",function()return S.radarRange end,function(v)S.radarRange=v end,50,500,10,C.gr)
mkSld(rC2,"雷达大小",function()return S.radarSize end,function(v)S.radarSize=v end,100,200,5,C.gr)
local entListCard=mkCard(tEs)mkSec(entListCard,"实体列表",C.gr)
mkTog(entListCard,"启用列表",function()return S.entList end,function(v)S.entList=v if v then if not entF then entF=Instance.new("Frame")entF.Size=UDim2.new(1,0,0,250)entF.BackgroundColor3=C.deep entF.BackgroundTransparency=0.4 entF.BorderSizePixel=0 entF.LayoutOrder=lo+1 entF.Parent=entListCard cnr(entF,8)lo=lo+1 end entF.Visible=true rEL()elseif entF then entF.Visible=false end end,C.gr)
local hC=mkCard(tEs)mkSec(hC,"受击反馈",C.gr)
mkTog(hC,"受击红闪",function()return S.hurtFlash end,function(v)S.hurtFlash=v end,C.gr)
mkSec(hC,"血量警告",C.gr)
mkTog(hC,"低血量屏幕红闪",function()return S.lowHPWarn end,function(v)S.lowHPWarn=v end,C.gr)
mkSld(hC,"警告阈值",function()return S.lowHPThreshold end,function(v)S.lowHPThreshold=v end,5,100,5,C.gr)
local aiC=mkCard(tAi)mkSec(aiC,"自瞄目标筛选",C.rd)
mkSeg(aiC,{"玩家","NPC","全部"},3,function(i)if i==1 then S.aimTargetMode="player"elseif i==2 then S.aimTargetMode="npc"else S.aimTargetMode="all"end end,C.rd,function()if S.aimTargetMode=="player"then return 1 elseif S.aimTargetMode=="npc"then return 2 else return 3 end end)
mkSec(aiC,"优先级",C.rd)
mkSeg(aiC,{"准心近","距离近","血最少","锁定"},1,function(i)if i==1 then S.aimPriority="crosshair"elseif i==2 then S.aimPriority="distance"elseif i==3 then S.aimPriority="health"else S.aimPriority="lock"end end,C.rd,function()if S.aimPriority=="crosshair"then return 1 elseif S.aimPriority=="distance"then return 2 elseif S.aimPriority=="health"then return 3 else return 4 end end)
mkSld(aiC,"防抖粘滞",function()return S.aimStick end,function(v)S.aimStick=v end,0,80,5,C.rd)
mkSec(aiC,"自瞄系统",C.rd)
mkTog(aiC,"启用自瞄",function()return S.aim end,function(v)S.aim=v end,C.rd)
mkTog(aiC,"目标金色高亮",function()return S.aimHL end,function(v)S.aimHL=v end,C.rd)
mkTog(aiC,"瞄准激光",function()return S.aimLaser end,function(v)S.aimLaser=v end,C.rd)
mkTog(aiC,"掩体检测",function()return S.aimWall end,function(v)S.aimWall=v end,C.rd)
mkTog(aiC,"显示FOV圈",function()return S.aimCircle end,function(v)S.aimCircle=v end,C.rd)
mkSld(aiC,"FOV视野",function()return S.aimFov end,function(v)S.aimFov=v end,10,360,5,C.rd)
mkSld(aiC,"自瞄距离",function()return S.aimDist end,function(v)S.aimDist=v end,50,2000,25,C.rd)
mkSld(aiC,"平滑度",function()return S.aimSmooth end,function(v)S.aimSmooth=v end,5,100,5,C.rd)
mkTog(aiC,"队伍检测",function()return S.aimTeam end,function(v)S.aimTeam=v end,C.rd)
mkSec(aiC,"瞄准部位",C.rd)
mkTog(aiC,"锁定头部",function()return S.aimPart=="Head"end,function(v)if v then S.aimPart="Head"end end,C.rd)
mkTog(aiC,"锁定躯干",function()return S.aimPart=="Torso"end,function(v)if v then S.aimPart="Torso"end end,C.rd)
mkTog(aiC,"锁定根部件",function()return S.aimPart=="HumanoidRootPart"end,function(v)if v then S.aimPart="HumanoidRootPart"end end,C.rd)
mkSec(aiC,"仇恨指示",C.rd)
mkTog(aiC,"启用仇恨指示",function()return S.aggro end,function(v)S.aggro=v if not v then clrAggro()end end,C.rd)
mkSld(aiC,"检测范围",function()return S.aggroRange end,function(v)S.aggroRange=v end,50,500,25,C.rd)
mkSld(aiC,"视野阈值°",function()return S.aggroFov end,function(v)S.aggroFov=v end,10,90,5,C.rd)
local hdC=mkCard(tSt)mkSec(hdC,"界面HUD",C.gold)
mkTog(hdC,"FPS/Ping监控",function()return S.showFps end,function(v)S.showFps=v end,C.gold)
mkSld(hdC,"菜单不透明度%",function()return S.uiOpacity end,function(v)S.uiOpacity=v panCG.GroupTransparency=1-v/100 end,0,100,5,C.gold)
local fxC=mkCard(tSt)mkSec(fxC,"性能优化",C.gold)
mkTog(fxC,"启用FPS优化",function()return S.fpsBoost end,function(v)S.fpsBoost=v if v then applyFPSBoost()else restoreFPS()end end,C.gold)
mkSeg(fxC,{"轻度","中度"},2,function(i)S.fpsLevel=i if S.fpsBoost then applyFPSBoost()end end,C.gold,function()return S.fpsLevel end)
local acC=mkCard(tSt)mkSec(acC,"反检测",C.gold)
mkTog(acC,"GUI保护",function()return S.protectGUI end,function(v)S.protectGUI=v end,C.gold)
mkAct(acC,"提示：移速/飞行已过检测",function()toast("移速走速度补偿，飞行走物理速度",true)end,C.gold)
mkSec(hdC,"配置存档",C.gold)
mkAct(hdC,"保存当前配置",function()local ok=saveC()if ok then toast("配置已保存",true)else toast("保存失败",false)end end,C.gold)
mkAct(hdC,"加载上次配置",function()local ok=loadC()if ok then toast("配置已加载",true)else toast("加载失败",false)end end,C.gold)
closeB.MouseButton1Click:Connect(function()S.fly=false S.speedOn=false S.jumpOn=false S.noclip=false S.aim=false S.esp=false S.radar=false S.entList=false S.hurtFlash=false S.aimLaser=false S.lowHPWarn=false S.fullbright=false
S.aggro=false S.fpsBoost=false S.bhop=false
pcall(removeBhop)
pcall(clrAggro)
pcall(restoreFPS)
pcall(stFly)pcall(setFB,false)ll.Visible=false lt2.Visible=false WS.Gravity=origG for m,_ in pairs(espO)do pcall(rmE,m)end pcall(function()RS:UnbindFromRenderStep("GT_Aim")end)local ch=LP.Character if ch then local h=ch:FindFirstChildOfClass("Humanoid")if h then if oJP then h.JumpPower=oJP end if oJH then h.JumpHeight=oJH end if oUJP~=nil then h.UseJumpPower=oUJP end h.WalkSpeed=BASE_WS end for _,v in pairs(ch:GetDescendants())do if v:IsA("BasePart")then v.CanCollide=true end end end sg:Destroy()tg:Destroy()end)
LP.CharacterAdded:Connect(function()wait(0.5)if S.esp then rfE()end end)
spawn(function()wait(0.1)TS:Create(cg,TweenInfo.new(0.7,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{Size=UDim2.new(0,520,0,520)}):Play()TS:Create(cg,TweenInfo.new(0.7),{BackgroundTransparency=0.85}):Play()TS:Create(bg,TweenInfo.new(1.0,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{Size=UDim2.new(0,900,0,900)}):Play()TS:Create(bg,TweenInfo.new(1.0),{BackgroundTransparency=0.9}):Play()TS:Create(ci,TweenInfo.new(0.5,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{TextTransparency=0,TextStrokeTransparency=0}):Play()TS:Create(ro,TweenInfo.new(0.6,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{Size=UDim2.new(0,200,0,200)}):Play()TS:Create(ri,TweenInfo.new(0.8,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{Size=UDim2.new(0,140,0,140)}):Play()for _,d in ipairs(sd)do TS:Create(d,TweenInfo.new(0.4),{BackgroundTransparency=0}):Play()end local sa,so,ps=0,0,tick()spawn(function()while io.Parent and ro.Parent and not iDone do sa=sa+3 so=so+5 ro.Rotation=sa ri.Rotation=-sa*1.4 for i,d in ipairs(sd)do local an=math.rad(so+(i-1)*90)local rd=95 d.Position=UDim2.new(0.5,math.cos(an)*rd,0.5,-20+math.sin(an)*rd)end local el=tick()-ps ci.TextSize=80*(1+math.sin(el*4)*0.08)wait(0.016)end end)wait(0.5)for i,e in ipairs(tl)do TS:Create(e.label,TweenInfo.new(0.75,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{Position=e.basePos,Rotation=0,TextTransparency=0,TextStrokeTransparency=0}):Play()wait(0.09)end wait(1.0)local sw=Instance.new("Frame")sw.Size=UDim2.new(0,100,0,140)sw.AnchorPoint=Vector2.new(0.5,0.5)sw.Position=UDim2.new(0,-150,0.5,60)sw.BackgroundColor3=Color3.new(1,1,1)sw.BackgroundTransparency=0.15 sw.BorderSizePixel=0 sw.ZIndex=10 sw.Parent=io cnr(sw,40)local swg=Instance.new("UIGradient")swg.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(0.5,0),NumberSequenceKeypoint.new(1,1)})swg.Parent=sw TS:Create(sw,TweenInfo.new(0.9,Enum.EasingStyle.Quad,Enum.EasingDirection.InOut),{Position=UDim2.new(1,150,0.5,60)}):Play()wait(0.45)for i,e in ipairs(tl)do TS:Create(e.label,TweenInfo.new(0.15),{TextSize=e.label.TextSize+14,TextColor3=Color3.new(1,1,1)}):Play()wait(0.05)end wait(0.35)for _,e in ipairs(tl)do local os2=e.label.TextSize TS:Create(e.label,TweenInfo.new(0.3,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{TextSize=os2,TextColor3=Color3.fromRGB(230,250,255)}):Play()end wait(0.6)sw:Destroy()iDone=true for _,e in ipairs(tl)do TS:Create(e.label,TweenInfo.new(0.4),{TextTransparency=1,TextStrokeTransparency=1}):Play()end TS:Create(ci,TweenInfo.new(0.4),{TextTransparency=1}):Play()TS:Create(ros,TweenInfo.new(0.4),{Transparency=1}):Play()TS:Create(ris,TweenInfo.new(0.4),{Transparency=1}):Play()TS:Create(cg,TweenInfo.new(0.4),{BackgroundTransparency=1}):Play()TS:Create(bg,TweenInfo.new(0.4),{BackgroundTransparency=1}):Play()for _,d in ipairs(sd)do TS:Create(d,TweenInfo.new(0.4),{BackgroundTransparency=1}):Play()end TS:Create(io,TweenInfo.new(0.4),{BackgroundTransparency=1}):Play()wait(0.5)pan.Visible=true pan.Size=UDim2.new(0,0,0,0)pan.Position=UDim2.new(0.5,0,0.5,0)TS:Create(pan,TweenInfo.new(0.55,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{Size=UDim2.new(0,pw,0,ph),Position=UDim2.new(0.5,-pw/2,0.5,-ph/2)}):Play()wait(0.6)io:Destroy()end)
