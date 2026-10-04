local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local HttpService = game:GetService("HttpService")
local Stats = game:GetService("Stats")
local Lighting = game:GetService("Lighting")
local SoundService = game:GetService("SoundService")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

local S = {
    fly = false, flySpeed = 60, flyUp = false, flyDown = false,
    speedOn = false, walk = 16,
    jumpOn = false, jp = 50,
    noclip = false,

    aim = false, aimPart = "Head", aimFov = 90, aimDist = 500,
    aimSmooth = 60, aimTeam = true, aimCircle = true,
    aimTargetMode = "all", aimPriority = "crosshair",
    aimWall = false, aimStick = 30, aimHL = false, aimLaser = false,

    esp = false, espHL = false, espBox = false, espSkel = false,
    espTracer = false, espName = false, espDist = false,
    espHPNum = false, espTool = false,
    espMax = 300, espTarget = "all", espYOff = 0, espTeamColor = true,

    radar = false, radarRange = 200, radarSize = 140,
    entList = false,
    hurtFlash = false,
    showFps = true,
    lowHPWarn = false, lowHPThreshold = 30,
    fullbright = false,

    itemESP = false, itemRange = 150,
    monShake = false, shakeDist = 60, shakePower = 5,
    heartbeat = false,
}

local flyGyro = nil
local flyVel = nil
local flyConn = nil

local espObjects = {}
local humanoids = {}
local aimTarget = nil

local origGravity = Workspace.Gravity

local origJumpPower = nil
local origJumpHeight = nil
local origUseJumpPower = nil

local lastHealth = nil
local hurtTween = nil

local radarDots = {}
local entFrame = nil

local origLighting = {
    Lighting.Brightness,
    Lighting.ClockTime,
    Lighting.Ambient,
    Lighting.OutdoorAmbient,
    Lighting.FogEnd,
    Lighting.FogStart,
    Lighting.GlobalShadows,
    Lighting.ShadowSoftness,
}

local toggleRefs = {}
local sliderRefs = {}
local segRefs = {}

local function isSelf(model)
    if not model then
        return false
    end
    if model == LocalPlayer.Character then
        return true
    end
    return Players:GetPlayerFromCharacter(model) == LocalPlayer
end

local function getPlayer(model)
    local ok, player = pcall(function()
        return Players:GetPlayerFromCharacter(model)
    end)
    if ok and player then
        return player
    end
    return nil
end

local function isTeammate(model)
    if not S.espTeamColor then
        return false
    end
    local player = getPlayer(model)
    if not player then
        return false
    end
    if not LocalPlayer.Team or not player.Team then
        return false
    end
    return player.Team == LocalPlayer.Team
end

local SKEL_15 = {
    {"Head", "UpperTorso"}, {"UpperTorso", "LowerTorso"},
    {"UpperTorso", "LeftUpperArm"}, {"LeftUpperArm", "LeftLowerArm"},
    {"LeftLowerArm", "LeftHand"},
    {"UpperTorso", "RightUpperArm"}, {"RightUpperArm", "RightLowerArm"},
    {"RightLowerArm", "RightHand"},
    {"LowerTorso", "LeftUpperLeg"}, {"LeftUpperLeg", "LeftLowerLeg"},
    {"LeftLowerLeg", "LeftFoot"},
    {"LowerTorso", "RightUpperLeg"}, {"RightUpperLeg", "RightLowerLeg"},
    {"RightLowerLeg", "RightFoot"},
}

local SKEL_6 = {
    {"Head", "Torso"},
    {"Torso", "Left Arm"}, {"Torso", "Right Arm"},
    {"Torso", "Left Leg"}, {"Torso", "Right Leg"},
}

local C = {
    bg = Color3.fromRGB(12, 16, 30),
    card = Color3.fromRGB(20, 27, 50),
    dark = Color3.fromRGB(11, 15, 30),
    deep = Color3.fromRGB(6, 8, 16),
    cy = Color3.fromRGB(0, 229, 255),
    pu = Color3.fromRGB(124, 77, 255),
    pi = Color3.fromRGB(255, 64, 129),
    gr = Color3.fromRGB(0, 230, 118),
    ye = Color3.fromRGB(255, 180, 50),
    rd = Color3.fromRGB(255, 60, 60),
    dg = Color3.fromRGB(255, 82, 82),
    tx = Color3.fromRGB(235, 242, 255),
    dm = Color3.fromRGB(115, 130, 170),
    st = Color3.fromRGB(38, 52, 88),
    gold = Color3.fromRGB(255, 215, 0),
}

local function corner(parent, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius)
    c.Parent = parent
    return c
end

local function stroke(parent, color, thickness, transparency)
    local s = Instance.new("UIStroke")
    s.Color = color
    s.Thickness = thickness or 1
    s.Transparency = transparency or 0
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Parent = parent
    return s
end

local function gradient(parent, colorSequence, rotation)
    local g = Instance.new("UIGradient")
    g.Color = colorSequence
    if rotation then
        g.Rotation = rotation
    end
    g.Parent = parent
    return g
end

local screenGui = Instance.new("ScreenGui")
screenGui.ResetOnSpawn = false
screenGui.DisplayOrder = 999999
screenGui.IgnoreGuiInset = true
screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local introOverlay = Instance.new("Frame")
introOverlay.Size = UDim2.new(1, 0, 1, 0)
introOverlay.BackgroundColor3 = Color3.fromRGB(10, 18, 35)
introOverlay.BackgroundTransparency = 0.75
introOverlay.BorderSizePixel = 0
introOverlay.ZIndex = 9999990
introOverlay.Active = false
introOverlay.Parent = screenGui

local introGradient = Instance.new("UIGradient")
introGradient.Rotation = 90
introGradient.Transparency = NumberSequence.new({
    NumberSequenceKeypoint.new(0, 0.4),
    NumberSequenceKeypoint.new(0.5, 0.85),
    NumberSequenceKeypoint.new(1, 0.4),
})
introGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 20, 40)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 10, 25)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 20, 40)),
})
introGradient.Parent = introOverlay

local bigGlow = Instance.new("Frame")
bigGlow.Size = UDim2.new(0, 10, 0, 10)
bigGlow.AnchorPoint = Vector2.new(0.5, 0.5)
bigGlow.Position = UDim2.new(0.5, 0, 0.5, -20)
bigGlow.BackgroundColor3 = Color3.fromRGB(80, 200, 255)
bigGlow.BackgroundTransparency = 0.5
bigGlow.BorderSizePixel = 0
bigGlow.ZIndex = 0
bigGlow.Parent = introOverlay
corner(bigGlow, 9999)

local bigGlowGradient = Instance.new("UIGradient")
bigGlowGradient.Transparency = NumberSequence.new({
    NumberSequenceKeypoint.new(0, 0),
    NumberSequenceKeypoint.new(0.5, 0.6),
    NumberSequenceKeypoint.new(1, 1),
})
bigGlowGradient.Rotation = 90
bigGlowGradient.Parent = bigGlow

local centerGlow = Instance.new("Frame")
centerGlow.Size = UDim2.new(0, 10, 0, 10)
centerGlow.AnchorPoint = Vector2.new(0.5, 0.5)
centerGlow.Position = UDim2.new(0.5, 0, 0.5, -20)
centerGlow.BackgroundColor3 = Color3.fromRGB(120, 230, 255)
centerGlow.BackgroundTransparency = 0.4
centerGlow.BorderSizePixel = 0
centerGlow.ZIndex = 1
centerGlow.Parent = introOverlay
corner(centerGlow, 9999)

local ringOuter = Instance.new("Frame")
ringOuter.Size = UDim2.new(0, 60, 0, 60)
ringOuter.AnchorPoint = Vector2.new(0.5, 0.5)
ringOuter.Position = UDim2.new(0.5, 0, 0.5, -20)
ringOuter.BackgroundTransparency = 1
ringOuter.ZIndex = 2
ringOuter.Parent = introOverlay
corner(ringOuter, 9999)

local ringOuterStroke = Instance.new("UIStroke")
ringOuterStroke.Color = Color3.fromRGB(0, 240, 255)
ringOuterStroke.Thickness = 4
ringOuterStroke.Transparency = 0
ringOuterStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
ringOuterStroke.Parent = ringOuter

local ringInner = Instance.new("Frame")
ringInner.Size = UDim2.new(0, 40, 0, 40)
ringInner.AnchorPoint = Vector2.new(0.5, 0.5)
ringInner.Position = UDim2.new(0.5, 0, 0.5, -20)
ringInner.BackgroundTransparency = 1
ringInner.ZIndex = 2
ringInner.Parent = introOverlay
corner(ringInner, 9999)

local ringInnerStroke = Instance.new("UIStroke")
ringInnerStroke.Color = Color3.fromRGB(180, 130, 255)
ringInnerStroke.Thickness = 3
ringInnerStroke.Transparency = 0
ringInnerStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
ringInnerStroke.Parent = ringInner

local centerIcon = Instance.new("TextLabel")
centerIcon.Size = UDim2.new(0, 140, 0, 140)
centerIcon.AnchorPoint = Vector2.new(0.5, 0.5)
centerIcon.Position = UDim2.new(0.5, 0, 0.5, -20)
centerIcon.BackgroundTransparency = 1
centerIcon.Text = "GT"
centerIcon.TextColor3 = Color3.fromRGB(255, 255, 255)
centerIcon.TextSize = 80
centerIcon.Font = Enum.Font.GothamBold
centerIcon.TextTransparency = 1
centerIcon.TextStrokeTransparency = 1
centerIcon.TextStrokeColor3 = Color3.fromRGB(0, 240, 255)
centerIcon.ZIndex = 3
centerIcon.Parent = introOverlay

local satelliteDots = {}
for i = 1, 4 do
    local dot = Instance.new("Frame")
    dot.Size = UDim2.new(0, 12, 0, 12)
    dot.AnchorPoint = Vector2.new(0.5, 0.5)
    dot.Position = UDim2.new(0.5, 0, 0.5, -20)
    dot.BackgroundColor3 = Color3.fromHSV((i - 1) / 4, 0.75, 1)
    dot.BorderSizePixel = 0
    dot.ZIndex = 4
    dot.BackgroundTransparency = 1
    dot.Parent = introOverlay
    corner(dot, 6)

    local dotStroke = Instance.new("UIStroke")
    dotStroke.Color = Color3.new(1, 1, 1)
    dotStroke.Thickness = 1.5
    dotStroke.Transparency = 0.3
    dotStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    dotStroke.Parent = dot

    table.insert(satelliteDots, dot)
end

local titleText = "GENERAL TOOLS"
local charWidth = 32
local totalWidth = #titleText * charWidth
local startX = -totalWidth / 2
local titleLabels = {}

for i = 1, #titleText do
    local ch = titleText:sub(i, i)
    local fromSide = (i % 2 == 0) and 1 or -1
    local baseX = startX + (i - 1) * charWidth
    local basePos = UDim2.new(0.5, baseX, 0.5, 60)

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(0, charWidth, 0, 70)
    lbl.AnchorPoint = Vector2.new(0, 0)
    lbl.Position = UDim2.new(0.5, baseX + fromSide * 700, 0.5, 60)
    lbl.Rotation = fromSide * 120
    lbl.BackgroundTransparency = 1
    lbl.Text = ch == " " and " " or ch
    lbl.TextColor3 = Color3.fromRGB(255, 255, 255)
    lbl.TextSize = 38
    lbl.Font = Enum.Font.GothamBold
    lbl.TextTransparency = 1
    lbl.TextStrokeTransparency = 0
    lbl.TextStrokeColor3 = Color3.fromRGB(0, 240, 255)
    lbl.ZIndex = 3
    lbl.Parent = introOverlay

    table.insert(titleLabels, {label = lbl, basePos = basePos})
end

local introDone = false

local fbGuard = false

local function applyFullbright()
    if fbGuard then
        return
    end
    fbGuard = true

    pcall(function()
        Lighting.Brightness = 3
        Lighting.ClockTime = 14
        Lighting.Ambient = Color3.fromRGB(200, 200, 200)
        Lighting.OutdoorAmbient = Color3.fromRGB(200, 200, 200)
        Lighting.FogEnd = 100000
        Lighting.FogStart = 100000
        Lighting.GlobalShadows = false
        Lighting.ShadowSoftness = 0
    end)

    fbGuard = false
end

RunService.RenderStepped:Connect(function()
    if S.fullbright then
        applyFullbright()
    end
end)

pcall(function()
    Lighting:GetPropertyChangedSignal("Brightness"):Connect(function()
        if S.fullbright and not fbGuard then
            applyFullbright()
        end
    end)
    Lighting:GetPropertyChangedSignal("ClockTime"):Connect(function()
        if S.fullbright and not fbGuard then
            applyFullbright()
        end
    end)
end)

local function setFullbright(on)
    if on then
        pcall(function()
            if not Lighting:FindFirstChild("GT_CC") then
                local cc = Instance.new("ColorCorrectionEffect")
                cc.Name = "GT_CC"
                cc.Brightness = 0.35
                cc.Parent = Lighting
            end
        end)
        applyFullbright()
    else
        pcall(function()
            local cc = Lighting:FindFirstChild("GT_CC")
            if cc then
                cc:Destroy()
            end
        end)
        pcall(function()
            Lighting.Brightness = origLighting[1]
            Lighting.ClockTime = origLighting[2]
            Lighting.Ambient = origLighting[3]
            Lighting.OutdoorAmbient = origLighting[4]
            Lighting.FogEnd = origLighting[5]
            Lighting.FogStart = origLighting[6]
            Lighting.GlobalShadows = origLighting[7]
            Lighting.ShadowSoftness = origLighting[8]
        end)
    end
end

local ITEM_KEYWORDS = {
    "key", "battery", "item", "pickup", "flashlight", "fuel",
    "gas", "weapon", "medkit", "tool", "crate", "radio",
    "camera", "generator", "keycard", "supply", "ammo",
    "health", "wire", "fuse", "door", "exit", "escape",
    "ladder", "lever", "valve", "switch",
}

local function isItemObject(inst)
    if not inst.Name or inst.Name == "" then
        return false
    end
    local nameLower = inst.Name:lower()
    for _, keyword in ipairs(ITEM_KEYWORDS) do
        if nameLower:find(keyword, 1, true) then
            return true
        end
    end
    return false
end

local itemObjects = {}

local function clearItems()
    for _, data in pairs(itemObjects) do
        if data and data.billboard then
            pcall(function()
                data.billboard:Destroy()
            end)
        end
    end
    itemObjects = {}
end

local function scanItems()
    clearItems()
    if not S.itemESP then
        return
    end

    local character = LocalPlayer.Character
    local hrp = character and character:FindFirstChild("HumanoidRootPart")
    if not hrp then
        return
    end

    local myPos = hrp.Position
    local count = 0

    pcall(function()
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if count >= 30 then
                break
            end

            if obj:IsA("BasePart") and obj.Name ~= "HumanoidRootPart" then
                local notMine = not character:IsAncestorOf(obj) and not obj:IsDescendantOf(character)
                if notMine and isItemObject(obj) then
                    local dist = (obj.Position - myPos).Magnitude
                    if dist <= S.itemRange then
                        local billboard = Instance.new("BillboardGui")
                        billboard.Adornee = obj
                        billboard.Size = UDim2.new(0, 150, 0, 22)
                        billboard.StudsOffset = Vector3.new(0, 1.5, 0)
                        billboard.AlwaysOnTop = true
                        billboard.MaxDistance = S.itemRange * 2.5
                        billboard.Parent = screenGui

                        local label = Instance.new("TextLabel")
                        label.Size = UDim2.new(1, 0, 1, 0)
                        label.BackgroundTransparency = 0.3
                        label.BackgroundColor3 = C.deep
                        label.Text = " " .. obj.Name .. " " .. math.floor(dist) .. "m "
                        label.TextColor3 = C.gold
                        label.TextStrokeTransparency = 0.5
                        label.TextSize = 12
                        label.Font = Enum.Font.GothamBold
                        label.Parent = billboard
                        corner(label, 6)

                        itemObjects[obj] = {billboard = billboard}
                        count = count + 1
                    end
                end
            end
        end
    end)
end

spawn(function()
    while screenGui.Parent do
        if S.itemESP then
            scanItems()
        else
            clearItems()
        end
        wait(1.2)
    end
end)

RunService:BindToRenderStep("GT_Shake", 202, function()
    if not S.monShake then
        return
    end

    local character = LocalPlayer.Character
    local hrp = character and character:FindFirstChild("HumanoidRootPart")
    if not hrp then
        return
    end

    local nearestDist = math.huge
    for humanoid in pairs(humanoids) do
        if humanoid and humanoid.Parent and humanoid.Health > 0 then
            local model = humanoid.Parent
            if not isSelf(model) and not getPlayer(model) then
                local target = model:FindFirstChild("HumanoidRootPart")
                if target then
                    local d = (target.Position - hrp.Position).Magnitude
                    if d < nearestDist then
                        nearestDist = d
                    end
                end
            end
        end
    end

    if nearestDist < S.shakeDist then
        local factor = 1 - nearestDist / S.shakeDist
        local power = S.shakePower * factor
        local cam = Workspace.CurrentCamera
        if cam then
            cam.CFrame = cam.CFrame
                * CFrame.new(
                    (math.random() - 0.5) * power * 0.08,
                    (math.random() - 0.5) * power * 0.08,
                    0
                )
                * CFrame.Angles(
                    math.rad((math.random() - 0.5) * power * 0.5),
                    math.rad((math.random() - 0.5) * power * 0.5),
                    math.rad((math.random() - 0.5) * power * 0.5)
                )
        end
    end
end)

local heartbeatSound = Instance.new("Sound")
heartbeatSound.SoundId = "rbxassetid://6745508758"
heartbeatSound.Volume = 0.65
heartbeatSound.Parent = SoundService

spawn(function()
    while screenGui.Parent do
        local character = LocalPlayer.Character
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")

        if humanoid and S.heartbeat and humanoid.Health > 0 and humanoid.MaxHealth > 0 then
            local pct = humanoid.Health / humanoid.MaxHealth
            if pct <= 0.6 then
                pcall(function()
                    heartbeatSound.Volume = 0.4 + (1 - pct) * 0.5
                    heartbeatSound:Play()
                end)
                if pct < 0.3 then
                    wait(0.55)
                else
                    wait(1.0)
                end
            else
                wait(0.5)
            end
        else
            wait(0.5)
        end
    end
end)

local toastScreenGui = Instance.new("ScreenGui")
toastScreenGui.ResetOnSpawn = false
toastScreenGui.DisplayOrder = 1000000
toastScreenGui.IgnoreGuiInset = true
toastScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local toastFrame = Instance.new("Frame")
toastFrame.Size = UDim2.new(0, 280, 0, 48)
toastFrame.Position = UDim2.new(0.5, -140, 0, 20)
toastFrame.BackgroundColor3 = C.deep
toastFrame.BorderSizePixel = 0
toastFrame.Active = false
toastFrame.Visible = false
toastFrame.Parent = toastScreenGui
corner(toastFrame, 14)

local toastStroke = stroke(toastFrame, C.gr, 2, 0)

local toastIcon = Instance.new("TextLabel")
toastIcon.Size = UDim2.new(0, 36, 1, 0)
toastIcon.Position = UDim2.new(0, 10, 0, 0)
toastIcon.BackgroundTransparency = 1
toastIcon.Text = "✓"
toastIcon.TextColor3 = C.gr
toastIcon.TextSize = 24
toastIcon.Font = Enum.Font.GothamBold
toastIcon.Parent = toastFrame

local toastText = Instance.new("TextLabel")
toastText.Size = UDim2.new(1, -56, 1, 0)
toastText.Position = UDim2.new(0, 52, 0, 0)
toastText.BackgroundTransparency = 1
toastText.Text = ""
toastText.TextColor3 = C.tx
toastText.TextSize = 14
toastText.Font = Enum.Font.GothamBold
toastText.TextXAlignment = Enum.TextXAlignment.Left
toastText.Parent = toastFrame

local toastGen = 0

local function showToast(msg, ok)
    toastGen = toastGen + 1
    local myGen = toastGen

    toastText.Text = msg
    toastIcon.Text = ok and "✓" or "✕"
    toastIcon.TextColor3 = ok and C.gr or C.rd
    toastStroke.Color = ok and C.gr or C.rd

    toastFrame.BackgroundTransparency = 0
    toastText.TextTransparency = 0
    toastIcon.TextTransparency = 0
    toastStroke.Transparency = 0
    toastFrame.Visible = true

    spawn(function()
        wait(2)
        if myGen ~= toastGen then
            return
        end

        TweenService:Create(toastFrame, TweenInfo.new(0.4), {BackgroundTransparency = 1}):Play()
        TweenService:Create(toastText, TweenInfo.new(0.4), {TextTransparency = 1}):Play()
        TweenService:Create(toastIcon, TweenInfo.new(0.4), {TextTransparency = 1}):Play()
        TweenService:Create(toastStroke, TweenInfo.new(0.4), {Transparency = 1}):Play()

        wait(0.5)
        if myGen ~= toastGen then
            return
        end
        toastFrame.Visible = false
    end)
end

local panelWidth = math.min(340, Camera.ViewportSize.X - 24)
local panelHeight = math.min(500, Camera.ViewportSize.Y - 60)

local fpsLabel = Instance.new("TextLabel")
fpsLabel.Size = UDim2.new(0, 180, 0, 22)
fpsLabel.Position = UDim2.new(0.5, -90, 0, 20)
fpsLabel.BackgroundColor3 = C.deep
fpsLabel.BackgroundTransparency = 0.35
fpsLabel.TextColor3 = C.cy
fpsLabel.TextSize = 12
fpsLabel.Font = Enum.Font.GothamBold
fpsLabel.ZIndex = 999970
fpsLabel.Active = false
fpsLabel.Parent = screenGui
corner(fpsLabel, 8)
stroke(fpsLabel, C.cy, 1, 0.4)

local frameCounter = 0
RunService.RenderStepped:Connect(function()
    frameCounter = frameCounter + 1
end)

spawn(function()
    local lastTick = tick()
    while screenGui.Parent do
        wait(1)
        local now = tick()
        local fps = math.floor(frameCounter / math.max(now - lastTick, 0.001))
        frameCounter = 0
        lastTick = now

        local ping = 0
        pcall(function()
            ping = math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue())
        end)

        fpsLabel.Text = "FPS " .. fps .. " | PING " .. ping .. "ms"
    end
end)

local lowHealthFrames = {}
for i = 1, 4 do
    local fr = Instance.new("Frame")
    fr.BackgroundColor3 = C.rd
    fr.BackgroundTransparency = 1
    fr.BorderSizePixel = 0
    fr.ZIndex = 999975
    fr.Active = false
    fr.Parent = screenGui
    table.insert(lowHealthFrames, fr)
end

lowHealthFrames[1].Size = UDim2.new(1, 0, 0, 8)
lowHealthFrames[1].Position = UDim2.new(0, 0, 0, 0)
lowHealthFrames[2].Size = UDim2.new(1, 0, 0, 8)
lowHealthFrames[2].Position = UDim2.new(0, 0, 1, -8)
lowHealthFrames[3].Size = UDim2.new(0, 8, 1, 0)
lowHealthFrames[3].Position = UDim2.new(0, 0, 0, 0)
lowHealthFrames[4].Size = UDim2.new(0, 8, 1, 0)
lowHealthFrames[4].Position = UDim2.new(1, -8, 0, 0)

spawn(function()
    while screenGui.Parent do
        local character = LocalPlayer.Character
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")

        if humanoid and S.lowHPWarn and humanoid.Health > 0 and humanoid.Health < S.lowHPThreshold then
            local t = (math.sin(tick() * 6) + 1) / 2
            local alpha = 0.55 - t * 0.35
            for _, fr in ipairs(lowHealthFrames) do
                fr.BackgroundTransparency = alpha
            end
        else
            for _, fr in ipairs(lowHealthFrames) do
                fr.BackgroundTransparency = 1
            end
        end
        wait(0.05)
    end
end)

local laserLine = Instance.new("Frame")
laserLine.AnchorPoint = Vector2.new(0.5, 0.5)
laserLine.BackgroundColor3 = C.cy
laserLine.BackgroundTransparency = 0.25
laserLine.BorderSizePixel = 0
laserLine.ZIndex = 999950
laserLine.Active = false
laserLine.Visible = false
laserLine.Parent = screenGui

local laserTip = Instance.new("Frame")
laserTip.AnchorPoint = Vector2.new(0.5, 0.5)
laserTip.Size = UDim2.new(0, 8, 0, 8)
laserTip.BackgroundColor3 = C.cy
laserTip.BackgroundTransparency = 0.2
laserTip.BorderSizePixel = 0
laserTip.ZIndex = 999951
laserTip.Active = false
laserTip.Visible = false
laserTip.Parent = screenGui
corner(laserTip, 4)

RunService.RenderStepped:Connect(function()
    if not S.aim or not S.aimLaser or not aimTarget or not aimTarget.Parent then
        laserLine.Visible = false
        laserTip.Visible = false
        return
    end

    local cam = Workspace.CurrentCamera
    if not cam then
        laserLine.Visible = false
        laserTip.Visible = false
        return
    end

    local targetHRP = aimTarget:FindFirstChild("HumanoidRootPart")
    if not targetHRP then
        laserLine.Visible = false
        laserTip.Visible = false
        return
    end

    local viewportSize = cam.ViewportSize
    local origin = Vector2.new(viewportSize.X / 2, viewportSize.Y / 2)
    local screenPos, onScreen = cam:WorldToViewportPoint(targetHRP.Position)

    if not onScreen or screenPos.Z <= 0 then
        laserLine.Visible = false
        laserTip.Visible = false
        return
    end

    local targetPos = Vector2.new(screenPos.X, screenPos.Y)
    local delta = targetPos - origin
    local length = delta.Magnitude

    if length < 2 then
        laserLine.Visible = false
        laserTip.Visible = false
        return
    end

    local angle = math.deg(math.atan2(delta.Y, delta.X))
    local mid = (origin + targetPos) / 2

    laserLine.Visible = true
    laserLine.Position = UDim2.fromOffset(mid.X, mid.Y)
    laserLine.Size = UDim2.fromOffset(length, 2)
    laserLine.Rotation = angle

    laserTip.Visible = true
    laserTip.Position = UDim2.fromOffset(targetPos.X, targetPos.Y)
end)

local panel = Instance.new("Frame")
panel.Size = UDim2.new(0, panelWidth, 0, panelHeight)
panel.Position = UDim2.new(0.5, -panelWidth / 2, 0.5, -panelHeight / 2)
panel.BackgroundColor3 = C.bg
panel.BorderSizePixel = 0
panel.Active = true
panel.ClipsDescendants = true
panel.Visible = false
panel.Parent = screenGui
corner(panel, 18)
stroke(panel, Color3.fromRGB(70, 100, 160), 1.5)
gradient(panel, ColorSequence.new({
    ColorSequenceKeypoint.new(0, C.bg),
    ColorSequenceKeypoint.new(1, C.deep),
}), 90)

local topBar = Instance.new("Frame")
topBar.Size = UDim2.new(1, 0, 0, 60)
topBar.BackgroundColor3 = C.dark
topBar.BorderSizePixel = 0
topBar.Parent = panel
corner(topBar, 18)

local topFix = Instance.new("Frame")
topFix.Size = UDim2.new(1, 0, 0.5, 0)
topFix.Position = UDim2.new(0, 0, 0.5, 0)
topFix.BackgroundColor3 = C.dark
topFix.BorderSizePixel = 0
topFix.Parent = topBar

local gradientStrip = Instance.new("Frame")
gradientStrip.Size = UDim2.new(1, 0, 0, 3)
gradientStrip.BackgroundColor3 = Color3.new(1, 1, 1)
gradientStrip.BorderSizePixel = 0
gradientStrip.ZIndex = 5
gradientStrip.Parent = topBar
corner(gradientStrip, 2)

local gradientStripInner = gradient(gradientStrip, ColorSequence.new({
    ColorSequenceKeypoint.new(0, C.cy),
    ColorSequenceKeypoint.new(0.5, C.pu),
    ColorSequenceKeypoint.new(1, C.pi),
}), 0)

spawn(function()
    local offset = 0
    while gradientStrip.Parent and gradientStripInner.Parent do
        offset = (offset + 0.006) % 1
        pcall(function()
            gradientStripInner.Offset = Vector2.new(offset, 0)
        end)
        wait(0.03)
    end
end)

local statusDot = Instance.new("Frame")
statusDot.Size = UDim2.new(0, 8, 0, 8)
statusDot.Position = UDim2.new(0, 16, 0, 22)
statusDot.BackgroundColor3 = C.gr
statusDot.BorderSizePixel = 0
statusDot.ZIndex = 6
statusDot.Parent = topBar
corner(statusDot, 4)

local statusHalo = Instance.new("Frame")
statusHalo.Size = UDim2.new(0, 8, 0, 8)
statusHalo.Position = UDim2.new(0, 16, 0, 22)
statusHalo.BackgroundColor3 = C.gr
statusHalo.BackgroundTransparency = 0.6
statusHalo.BorderSizePixel = 0
statusHalo.ZIndex = 5
statusHalo.Parent = topBar
corner(statusHalo, 4)

spawn(function()
    while statusHalo.Parent do
        statusHalo.Size = UDim2.new(0, 8, 0, 8)
        statusHalo.Position = UDim2.new(0, 16, 0, 22)
        statusHalo.BackgroundTransparency = 0.5

        TweenService:Create(statusHalo, TweenInfo.new(1.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Size = UDim2.new(0, 20, 0, 20),
            Position = UDim2.new(0, 10, 0, 16),
            BackgroundTransparency = 1,
        }):Play()

        wait(1.4)
    end
end)

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, -110, 0, 22)
titleLabel.Position = UDim2.new(0, 32, 0, 10)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "GENERAL TOOLS"
titleLabel.TextColor3 = Color3.new(1, 1, 1)
titleLabel.TextSize = 16
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.ZIndex = 4
titleLabel.Parent = topBar
gradient(titleLabel, ColorSequence.new({
    ColorSequenceKeypoint.new(0, C.cy),
    ColorSequenceKeypoint.new(0.6, C.tx),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 210, 255)),
}), 0)

local subtitleLabel = Instance.new("TextLabel")
subtitleLabel.Size = UDim2.new(1, -110, 0, 12)
subtitleLabel.Position = UDim2.new(0, 32, 1, -22)
subtitleLabel.BackgroundTransparency = 1
subtitleLabel.Text = "V50"
subtitleLabel.TextColor3 = C.dm
subtitleLabel.TextSize = 8
subtitleLabel.Font = Enum.Font.GothamBold
subtitleLabel.TextXAlignment = Enum.TextXAlignment.Left
subtitleLabel.ZIndex = 4
subtitleLabel.Parent = topBar

local minBtn = Instance.new("TextButton")
minBtn.Size = UDim2.new(0, 30, 0, 30)
minBtn.Position = UDim2.new(1, -76, 0.5, -15)
minBtn.BackgroundColor3 = C.card
minBtn.BackgroundTransparency = 0.3
minBtn.Text = "−"
minBtn.TextColor3 = C.cy
minBtn.TextSize = 20
minBtn.Font = Enum.Font.GothamBold
minBtn.BorderSizePixel = 0
minBtn.ZIndex = 4
minBtn.Parent = topBar
corner(minBtn, 9)
stroke(minBtn, C.cy, 1, 0.6)

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 30, 0, 30)
closeBtn.Position = UDim2.new(1, -42, 0.5, -15)
closeBtn.BackgroundColor3 = C.card
closeBtn.BackgroundTransparency = 0.3
closeBtn.Text = "X"
closeBtn.TextColor3 = C.dg
closeBtn.TextSize = 15
closeBtn.Font = Enum.Font.GothamBold
closeBtn.BorderSizePixel = 0
closeBtn.ZIndex = 4
closeBtn.Parent = topBar
corner(closeBtn, 9)
stroke(closeBtn, C.dg, 1, 0.6)

local tabBar = Instance.new("Frame")
tabBar.Size = UDim2.new(1, -24, 0, 38)
tabBar.Position = UDim2.new(0, 12, 0, 66)
tabBar.BackgroundColor3 = C.deep
tabBar.BackgroundTransparency = 0.3
tabBar.BorderSizePixel = 0
tabBar.Parent = panel
corner(tabBar, 10)
stroke(tabBar, C.st, 1, 0.4)

local tabCount = 6
local tabWidthRatio = 1 / tabCount

local tabIndicator = Instance.new("Frame")
tabIndicator.Size = UDim2.new(tabWidthRatio, -4, 1, -8)
tabIndicator.Position = UDim2.new(0, 2, 0, 4)
tabIndicator.BackgroundColor3 = C.cy
tabIndicator.BorderSizePixel = 0
tabIndicator.ZIndex = 1
tabIndicator.Parent = tabBar
corner(tabIndicator, 8)
stroke(tabIndicator, Color3.new(1, 1, 1), 1.5, 0.4)

local contentArea = Instance.new("Frame")
contentArea.Size = UDim2.new(1, -16, 1, -122)
contentArea.Position = UDim2.new(0, 8, 0, 110)
contentArea.BackgroundTransparency = 1
contentArea.Parent = panel

local function makeScrollFrame()
    local sf = Instance.new("ScrollingFrame")
    sf.Size = UDim2.new(1, 0, 1, 0)
    sf.BackgroundTransparency = 1
    sf.BorderSizePixel = 0
    sf.AutomaticCanvasSize = Enum.AutomaticSize.Y
    sf.ScrollBarThickness = 3
    sf.ScrollBarImageColor3 = C.pu
    sf.ScrollBarImageTransparency = 0.3
    sf.Visible = false
    sf.Parent = contentArea

    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 10)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = sf

    local padding = Instance.new("UIPadding")
    padding.PaddingTop = UDim.new(0, 4)
    padding.PaddingBottom = UDim.new(0, 4)
    padding.PaddingLeft = UDim.new(0, 2)
    padding.PaddingRight = UDim.new(0, 2)
    padding.Parent = sf

    return sf
end

local tabMove = makeScrollFrame()
local tabAttr = makeScrollFrame()
local tabEsp = makeScrollFrame()
local tabAim = makeScrollFrame()
local tabHorror = makeScrollFrame()
local tabSettings = makeScrollFrame()

local Tabs = {
    {name = "移动", color = C.cy, frame = tabMove},
    {name = "属性", color = C.pu, frame = tabAttr},
    {name = "透视", color = C.gr, frame = tabEsp},
    {name = "自瞄", color = C.rd, frame = tabAim},
    {name = "恐怖", color = C.pi, frame = tabHorror},
    {name = "设置", color = C.gold, frame = tabSettings},
}

local tabButtons = {}
local currentTab = 1

local function switchTab(index)
    if index == currentTab then
        return
    end
    currentTab = index

    TweenService:Create(tabIndicator, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Position = UDim2.new((index - 1) * tabWidthRatio, 2, 0, 4),
        BackgroundColor3 = Tabs[index].color,
    }):Play()

    for k, tab in ipairs(Tabs) do
        TweenService:Create(tabButtons[k], TweenInfo.new(0.2), {
            TextColor3 = (k == index) and C.bg or C.dm,
        }):Play()
        tab.frame.Visible = (k == index)
    end
end

for i, tab in ipairs(Tabs) do
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(tabWidthRatio, -4, 1, -8)
    btn.Position = UDim2.new((i - 1) * tabWidthRatio, 2, 0, 4)
    btn.BackgroundTransparency = 1
    btn.Text = tab.name
    btn.TextColor3 = C.dm
    btn.TextSize = 10
    btn.Font = Enum.Font.GothamBold
    btn.BorderSizePixel = 0
    btn.ZIndex = 5
    btn.Parent = tabBar
    btn.MouseButton1Click:Connect(function()
        switchTab(i)
    end)
    table.insert(tabButtons, btn)
end

tabMove.Visible = true
tabButtons[1].TextColor3 = C.bg

local layoutOrder = 0

local function newCard(parent)
    layoutOrder = layoutOrder + 1
    local card = Instance.new("Frame")
    card.Size = UDim2.new(1, -8, 0, 0)
    card.BackgroundColor3 = C.card
    card.BackgroundTransparency = 0.05
    card.AutomaticSize = Enum.AutomaticSize.Y
    card.LayoutOrder = layoutOrder
    card.Parent = parent
    corner(card, 14)
    stroke(card, C.st, 1, 0.3)

    local padding = Instance.new("UIPadding")
    padding.PaddingTop = UDim.new(0, 14)
    padding.PaddingBottom = UDim.new(0, 14)
    padding.PaddingLeft = UDim.new(0, 16)
    padding.PaddingRight = UDim.new(0, 14)
    padding.Parent = card

    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 9)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = card

    return card
end

local function newSection(parent, text, color)
    layoutOrder = layoutOrder + 1
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 22)
    row.BackgroundTransparency = 1
    row.LayoutOrder = layoutOrder
    row.Parent = parent

    local mark = Instance.new("Frame")
    mark.Size = UDim2.new(0, 3, 0, 14)
    mark.Position = UDim2.new(0, 0, 0.5, -7)
    mark.BackgroundColor3 = color
    mark.BorderSizePixel = 0
    mark.ZIndex = 1
    mark.Parent = row
    corner(mark, 2)

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -18, 1, 0)
    label.Position = UDim2.new(0, 14, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = C.tx
    label.TextSize = 11
    label.Font = Enum.Font.GothamBold
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = row
end

local function newToggle(parent, name, getFn, setFn, accent)
    accent = accent or C.cy
    layoutOrder = layoutOrder + 1

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 42)
    btn.BackgroundColor3 = C.deep
    btn.BackgroundTransparency = 0.3
    btn.Text = ""
    btn.LayoutOrder = layoutOrder
    btn.Parent = parent
    corner(btn, 10)

    local btnStroke = stroke(btn, C.st, 1, 0.4)

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.75, 0, 1, 0)
    label.Position = UDim2.new(0, 14, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = name
    label.TextColor3 = C.tx
    label.TextSize = 12
    label.Font = Enum.Font.GothamBold
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = btn

    local dotOuter = Instance.new("Frame")
    dotOuter.Size = UDim2.new(0, 20, 0, 20)
    dotOuter.Position = UDim2.new(1, -34, 0.5, -10)
    dotOuter.BackgroundColor3 = C.bg
    dotOuter.BorderSizePixel = 0
    dotOuter.Parent = btn
    corner(dotOuter, 10)

    local dotOuterStroke = stroke(dotOuter, C.st, 1.5, 0.2)

    local dot = Instance.new("Frame")
    dot.Size = UDim2.new(0, 10, 0, 10)
    dot.Position = UDim2.new(0.5, -5, 0.5, -5)
    dot.BackgroundColor3 = C.dg
    dot.BackgroundTransparency = 0.4
    dot.BorderSizePixel = 0
    dot.Parent = dotOuter
    corner(dot, 5)

    local function apply()
        if getFn() then
            dotOuter.BackgroundColor3 = C.deep
            dotOuterStroke.Color = accent
            dotOuterStroke.Transparency = 0
            dotOuterStroke.Thickness = 2
            dot.BackgroundColor3 = accent
            dot.BackgroundTransparency = 0
            dot.Size = UDim2.new(0, 12, 0, 12)
            dot.Position = UDim2.new(0.5, -6, 0.5, -6)
            btnStroke.Color = accent
        else
            dotOuter.BackgroundColor3 = C.bg
            dotOuterStroke.Color = C.st
            dotOuterStroke.Transparency = 0.2
            dotOuterStroke.Thickness = 1.5
            dot.BackgroundColor3 = C.dg
            dot.BackgroundTransparency = 0.4
            dot.Size = UDim2.new(0, 10, 0, 10)
            dot.Position = UDim2.new(0.5, -5, 0.5, -5)
            btnStroke.Color = C.st
        end
    end

    apply()
    table.insert(toggleRefs, apply)

    btn.MouseButton1Click:Connect(function()
        local newVal = not getFn()
        setFn(newVal)
        apply()

        TweenService:Create(btn, TweenInfo.new(0.1), {Size = UDim2.new(0.96, 0, 0, 42)}):Play()
        wait(0.1)
        TweenService:Create(btn, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Size = UDim2.new(1, 0, 0, 42),
        }):Play()
    end)
end

local function newSlider(parent, name, getFn, setFn, minVal, maxVal, step, accent)
    accent = accent or C.cy
    layoutOrder = layoutOrder + 1

    local wrapper = Instance.new("Frame")
    wrapper.Size = UDim2.new(1, 0, 0, 52)
    wrapper.BackgroundTransparency = 1
    wrapper.LayoutOrder = layoutOrder
    wrapper.Parent = parent

    local nameRow = Instance.new("Frame")
    nameRow.Size = UDim2.new(1, 0, 0, 20)
    nameRow.BackgroundTransparency = 1
    nameRow.Parent = wrapper

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.65, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = name
    label.TextColor3 = C.dm
    label.TextSize = 11
    label.Font = Enum.Font.GothamBold
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = nameRow

    local valueBox = Instance.new("Frame")
    valueBox.Size = UDim2.new(0, 52, 0, 18)
    valueBox.Position = UDim2.new(1, -52, 0.5, -9)
    valueBox.BackgroundColor3 = C.deep
    valueBox.BorderSizePixel = 0
    valueBox.Parent = nameRow
    corner(valueBox, 6)
    stroke(valueBox, accent, 1, 0.5)

    local valueLabel = Instance.new("TextLabel")
    valueLabel.Size = UDim2.new(1, 0, 1, 0)
    valueLabel.BackgroundTransparency = 1
    valueLabel.Text = tostring(getFn())
    valueLabel.TextColor3 = accent
    valueLabel.TextSize = 11
    valueLabel.Font = Enum.Font.GothamBold
    valueLabel.Parent = valueBox

    local track = Instance.new("Frame")
    track.Size = UDim2.new(1, 0, 0, 6)
    track.Position = UDim2.new(0, 0, 0, 30)
    track.BackgroundColor3 = C.deep
    track.BorderSizePixel = 0
    track.Parent = wrapper
    corner(track, 3)
    stroke(track, C.st, 1, 0.4)

    local initialRatio = (getFn() - minVal) / (maxVal - minVal)

    local fill = Instance.new("Frame")
    fill.Size = UDim2.new(initialRatio, 0, 1, 0)
    fill.BackgroundColor3 = Color3.new(1, 1, 1)
    fill.BorderSizePixel = 0
    fill.Parent = track
    corner(fill, 3)
    gradient(fill, ColorSequence.new({
        ColorSequenceKeypoint.new(0, accent),
        ColorSequenceKeypoint.new(1, C.pu),
    }), 0)

    local handle = Instance.new("Frame")
    handle.Size = UDim2.new(0, 14, 0, 14)
    handle.Position = UDim2.new(initialRatio, 0, 0.5, -7)
    handle.BackgroundColor3 = Color3.new(1, 1, 1)
    handle.BorderSizePixel = 0
    handle.ZIndex = 3
    handle.Parent = track
    corner(handle, 7)

    local dragging = false

    local function updateFromX(x)
        local trackPos = track.AbsolutePosition.X
        local trackSize = track.AbsoluteSize.X
        local ratio = math.clamp((x - trackPos) / trackSize, 0, 1)
        local val = minVal + (maxVal - minVal) * ratio
        val = math.floor(val / step + 0.5) * step
        if val < minVal then val = minVal end
        if val > maxVal then val = maxVal end

        fill.Size = UDim2.new((val - minVal) / (maxVal - minVal), 0, 1, 0)
        handle.Position = UDim2.new((val - minVal) / (maxVal - minVal), 0, 0.5, -7)
        valueLabel.Text = tostring(val)
        setFn(val)
    end

    local function refresh()
        local val = getFn()
        local ratio = (val - minVal) / (maxVal - minVal)
        fill.Size = UDim2.new(ratio, 0, 1, 0)
        handle.Position = UDim2.new(ratio, 0, 0.5, -7)
        valueLabel.Text = tostring(val)
    end

    table.insert(sliderRefs, refresh)

    track.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch
            or input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            updateFromX(input.Position.X)
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.Touch
            or input.UserInputType == Enum.UserInputType.MouseMovement) then
            updateFromX(input.Position.X)
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch
            or input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
end

local function newSegment(parent, options, default, callback, accent, getter)
    accent = accent or C.cy
    layoutOrder = layoutOrder + 1

    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 36)
    row.BackgroundColor3 = C.deep
    row.BackgroundTransparency = 0.3
    row.BorderSizePixel = 0
    row.LayoutOrder = layoutOrder
    row.Parent = parent
    corner(row, 9)
    stroke(row, C.st, 1, 0.4)

    local buttons = {}
    local count = #options

    local function updateHighlight(selectedIndex)
        for i, btn in ipairs(buttons) do
            TweenService:Create(btn, TweenInfo.new(0.2), {
                BackgroundTransparency = (i == selectedIndex) and 0 or 1,
                TextColor3 = (i == selectedIndex) and C.bg or C.dm,
            }):Play()
        end
    end

    for i = 1, count do
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1 / count, -6, 1, -8)
        btn.Position = UDim2.new((i - 1) / count, 3, 0, 4)
        btn.BackgroundColor3 = accent
        btn.BackgroundTransparency = 1
        btn.Text = options[i]
        btn.TextColor3 = C.dm
        btn.TextSize = 10
        btn.Font = Enum.Font.GothamBold
        btn.BorderSizePixel = 0
        btn.Parent = row
        corner(btn, 6)

        btn.MouseButton1Click:Connect(function()
            updateHighlight(i)
            callback(i)
        end)

        table.insert(buttons, btn)
    end

    local function sync()
        local current = default
        if getter then
            current = getter()
        end
        if type(current) == "number" and current >= 1 and current <= count then
            updateHighlight(current)
        end
    end

    sync()
    table.insert(segRefs, sync)
end

local function newAction(parent, text, callback, accent)
    accent = accent or C.pi
    layoutOrder = layoutOrder + 1

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 38)
    btn.BackgroundColor3 = Color3.new(1, 1, 1)
    btn.Text = text
    btn.TextColor3 = Color3.new(1, 1, 1)
    btn.TextStrokeTransparency = 0
    btn.TextStrokeColor3 = Color3.new(0, 0, 0)
    btn.TextSize = 12
    btn.Font = Enum.Font.GothamBold
    btn.LayoutOrder = layoutOrder
    btn.Parent = parent
    corner(btn, 10)
    stroke(btn, accent, 1, 0.4)
    gradient(btn, ColorSequence.new({
        ColorSequenceKeypoint.new(0, accent),
        ColorSequenceKeypoint.new(1, C.pu),
    }), 0)

    btn.MouseButton1Click:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.1), {Size = UDim2.new(0.95, 0, 0, 38)}):Play()
        wait(0.1)
        TweenService:Create(btn, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Size = UDim2.new(1, 0, 0, 38),
        }):Play()

        if callback then
            callback()
        end
    end)
end

local panelDragging = false
local dragOffset = nil

topBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch
        or input.UserInputType == Enum.UserInputType.MouseButton1 then
        panelDragging = true
        dragOffset = input.Position - Vector3.new(panel.AbsolutePosition.X, panel.AbsolutePosition.Y, 0)
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if panelDragging and (input.UserInputType == Enum.UserInputType.Touch
        or input.UserInputType == Enum.UserInputType.MouseMovement) then
        panel.Position = UDim2.fromOffset(input.Position.X - dragOffset.X, input.Position.Y - dragOffset.Y)
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch
        or input.UserInputType == Enum.UserInputType.MouseButton1 then
        panelDragging = false
    end
end)

local collapsed = false

minBtn.MouseButton1Click:Connect(function()
    collapsed = not collapsed

    if collapsed then
        tabBar.Visible = false
        contentArea.Visible = false
        TweenService:Create(panel, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Size = UDim2.new(0, panelWidth, 0, 60),
        }):Play()
        minBtn.Text = "+"
    else
        tabBar.Visible = true
        contentArea.Visible = true
        TweenService:Create(panel, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Size = UDim2.new(0, panelWidth, 0, panelHeight),
        }):Play()
        minBtn.Text = "−"
    end
end)

for _, player in ipairs(Players:GetPlayers()) do
    if player.Character then
        local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoids[humanoid] = true
        end
    end
end

Workspace.DescendantAdded:Connect(function(desc)
    if desc:IsA("Humanoid") then
        humanoids[desc] = true
    end
end)

Workspace.DescendantRemoving:Connect(function(desc)
    if desc:IsA("Humanoid") then
        humanoids[desc] = nil
    end
end)

spawn(function()
    while screenGui.Parent do
        wait(1.5)
        for humanoid in pairs(humanoids) do
            if not humanoid.Parent or humanoid.Health <= 0 then
                humanoids[humanoid] = nil
            end
        end
    end
end)

local hurtFrame = Instance.new("Frame")
hurtFrame.Size = UDim2.new(1, 0, 1, 0)
hurtFrame.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
hurtFrame.BackgroundTransparency = 1
hurtFrame.BorderSizePixel = 0
hurtFrame.ZIndex = 999980
hurtFrame.Active = false
hurtFrame.Parent = screenGui

spawn(function()
    while screenGui.Parent do
        local character = LocalPlayer.Character
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")

        if humanoid then
            if lastHealth == nil then
                lastHealth = humanoid.Health
            end

            if humanoid.Health < lastHealth - 0.5 and S.hurtFlash then
                hurtFrame.BackgroundTransparency = 0.55

                if hurtTween then
                    hurtTween:Cancel()
                end

                hurtTween = TweenService:Create(
                    hurtFrame,
                    TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                    {BackgroundTransparency = 1}
                )
                hurtTween:Play()
            end

            lastHealth = humanoid.Health
        end

        wait(0.05)
    end
end)

local radarFrame = Instance.new("Frame")
radarFrame.Size = UDim2.fromOffset(S.radarSize, S.radarSize)
radarFrame.Position = UDim2.new(1, -S.radarSize - 16, 0, 100)
radarFrame.BackgroundColor3 = Color3.fromRGB(8, 12, 24)
radarFrame.BackgroundTransparency = 0.35
radarFrame.BorderSizePixel = 0
radarFrame.ZIndex = 100
radarFrame.Visible = false
radarFrame.Parent = screenGui
corner(radarFrame, 9999)
stroke(radarFrame, C.cy, 1.5, 0.4)

local radarSelf = Instance.new("Frame")
radarSelf.Size = UDim2.new(0, 6, 0, 6)
radarSelf.Position = UDim2.new(0.5, -3, 0.5, -3)
radarSelf.BackgroundColor3 = C.cy
radarSelf.BorderSizePixel = 0
radarSelf.ZIndex = 102
radarSelf.Parent = radarFrame
corner(radarSelf, 3)

local radarCone = Instance.new("Frame")
radarCone.Size = UDim2.new(0, 3, 0, S.radarSize / 2 - 4)
radarCone.Position = UDim2.new(0.5, -1.5, 0.5, -S.radarSize / 2 + 4)
radarCone.BackgroundColor3 = C.cy
radarCone.BackgroundTransparency = 0.6
radarCone.BorderSizePixel = 0
radarCone.ZIndex = 101
radarCone.Parent = radarFrame
corner(radarCone, 1)

RunService.Heartbeat:Connect(function()
    if not S.radar then
        radarFrame.Visible = false
        for _, d in pairs(radarDots) do
            d:Destroy()
        end
        radarDots = {}
        return
    end

    radarFrame.Visible = true
    radarFrame.Size = UDim2.fromOffset(S.radarSize, S.radarSize)
    radarCone.Size = UDim2.new(0, 3, 0, S.radarSize / 2 - 4)
    radarCone.Position = UDim2.new(0.5, -1.5, 0.5, -S.radarSize / 2 + 4)

    local cam = Workspace.CurrentCamera
    local character = LocalPlayer.Character
    local hrp = character and character:FindFirstChild("HumanoidRootPart")
    if not cam or not hrp then
        return
    end

    local myPos = hrp.Position
    local camLook = cam.CFrame.LookVector
    local flatLook = Vector3.new(camLook.X, 0, camLook.Z)
    if flatLook.Magnitude < 0.01 then
        flatLook = Vector3.new(0, 0, -1)
    end
    flatLook = flatLook.Unit

    local flatRight = Vector3.new(flatLook.Z, 0, -flatLook.X)
    local cx = S.radarSize / 2
    local cy = S.radarSize / 2
    local scale = (S.radarSize / 2) / S.radarRange
    local active = {}

    for humanoid in pairs(humanoids) do
        if humanoid and humanoid.Parent and humanoid.Health > 0 then
            local model = humanoid.Parent
            if model and model:IsA("Model") and not isSelf(model) then
                local target = model:FindFirstChild("HumanoidRootPart")
                if target then
                    local rel = target.Position - myPos
                    local dist = Vector3.new(rel.X, 0, rel.Z).Magnitude
                    if dist <= S.radarRange then
                        local lx = rel:Dot(flatRight)
                        local ly = rel:Dot(flatLook)
                        local dotColor
                        if isTeammate(model) then
                            dotColor = C.gr
                        elseif getPlayer(model) then
                            dotColor = C.rd
                        else
                            dotColor = C.pi
                        end
                        active[model] = {x = cx + lx * scale, y = cy - ly * scale, color = dotColor}
                    end
                end
            end
        end
    end

    for model, dot in pairs(radarDots) do
        if not active[model] then
            dot:Destroy()
            radarDots[model] = nil
        end
    end

    for model, pos in pairs(active) do
        local dot = radarDots[model]
        if not dot then
            dot = Instance.new("Frame")
            dot.Size = UDim2.new(0, 6, 0, 6)
            dot.BorderSizePixel = 0
            dot.ZIndex = 103
            dot.Parent = radarFrame
            corner(dot, 3)
            radarDots[model] = dot
        end
        dot.Position = UDim2.fromOffset(pos.x - 3, pos.y - 3)
        dot.BackgroundColor3 = pos.color
    end
end)

local function refreshEntityList()
    if not entFrame or not entFrame.Parent then
        return
    end

    for _, child in ipairs(entFrame:GetChildren()) do
        if child:IsA("Frame") and child.Name == "Row" then
            child:Destroy()
        end
    end

    if not S.entList then
        return
    end

    local character = LocalPlayer.Character
    local hrp = character and character:FindFirstChild("HumanoidRootPart")
    if not hrp then
        return
    end

    local myPos = hrp.Position
    local list = {}

    for humanoid in pairs(humanoids) do
        if humanoid and humanoid.Parent and humanoid.Health > 0 then
            local model = humanoid.Parent
            if model and model:IsA("Model") and not isSelf(model) then
                local target = model:FindFirstChild("HumanoidRootPart")
                if target then
                    local dist = (target.Position - myPos).Magnitude
                    if dist <= S.espMax then
                        table.insert(list, {
                            model = model,
                            dist = dist,
                            team = isTeammate(model),
                            isPlayer = getPlayer(model) ~= nil,
                        })
                    end
                end
            end
        end
    end

    table.sort(list, function(a, b)
        return a.dist < b.dist
    end)

    for i, entry in ipairs(list) do
        if i > 8 then
            break
        end

        local row = Instance.new("Frame")
        row.Name = "Row"
        row.Size = UDim2.new(1, 0, 0, 28)
        row.Position = UDim2.new(0, 0, 0, (i - 1) * 30)
        row.BackgroundColor3 = C.deep
        row.BackgroundTransparency = 0.4
        row.Parent = entFrame
        corner(row, 6)

        local nameLabel = Instance.new("TextLabel")
        nameLabel.Size = UDim2.new(0.6, 0, 1, 0)
        nameLabel.Position = UDim2.new(0, 8, 0, 0)
        nameLabel.BackgroundTransparency = 1
        nameLabel.Text = entry.model.Name
        if entry.team then
            nameLabel.TextColor3 = C.gr
        elseif entry.isPlayer then
            nameLabel.TextColor3 = C.cy
        else
            nameLabel.TextColor3 = C.pi
        end
        nameLabel.TextSize = 11
        nameLabel.Font = Enum.Font.GothamBold
        nameLabel.TextXAlignment = Enum.TextXAlignment.Left
        nameLabel.Parent = row

        local distLabel = Instance.new("TextLabel")
        distLabel.Size = UDim2.new(0.2, 0, 1, 0)
        distLabel.Position = UDim2.new(0.6, 0, 0, 0)
        distLabel.BackgroundTransparency = 1
        distLabel.Text = math.floor(entry.dist) .. "m"
        distLabel.TextColor3 = C.dm
        distLabel.TextSize = 10
        distLabel.Font = Enum.Font.Gotham
        distLabel.Parent = row

        local teleportBtn = Instance.new("TextButton")
        teleportBtn.Size = UDim2.new(0.18, 0, 1, -6)
        teleportBtn.Position = UDim2.new(0.81, 0, 0, 3)
        teleportBtn.BackgroundColor3 = C.gr
        teleportBtn.Text = "T"
        teleportBtn.TextColor3 = Color3.new(1, 1, 1)
        teleportBtn.TextSize = 10
        teleportBtn.Font = Enum.Font.GothamBold
        teleportBtn.Parent = row
        corner(teleportBtn, 5)

        teleportBtn.MouseButton1Click:Connect(function()
            local char = LocalPlayer.Character
            local myHRP = char and char:FindFirstChild("HumanoidRootPart")
            local targetHRP = entry.model:FindFirstChild("HumanoidRootPart")

            if myHRP and targetHRP then
                local dir = Vector3.new(
                    myHRP.Position.X - targetHRP.Position.X,
                    0,
                    myHRP.Position.Z - targetHRP.Position.Z
                )
                if dir.Magnitude < 0.1 then
                    dir = Vector3.new(1, 0, 0)
                end
                dir = dir.Unit * 3
                myHRP.CFrame = CFrame.new(targetHRP.Position + dir + Vector3.new(0, 2, 0))
            end
        end)
    end
end

spawn(function()
    while screenGui.Parent do
        wait(0.6)
        if S.entList then
            refreshEntityList()
        end
    end
end)

local fovCircle = Instance.new("Frame")
fovCircle.AnchorPoint = Vector2.new(0.5, 0.5)
fovCircle.Position = UDim2.new(0.5, 0, 0.5, 0)
fovCircle.BackgroundTransparency = 1
fovCircle.ZIndex = 5
fovCircle.Visible = false
fovCircle.Parent = screenGui
corner(fovCircle, 9999)
stroke(fovCircle, C.rd, 1.5, 0.35)

RunService.RenderStepped:Connect(function()
    if not (S.aim and S.aimCircle) then
        fovCircle.Visible = false
        return
    end

    local cam = Workspace.CurrentCamera
    if not cam then
        return
    end

    local vp = cam.ViewportSize
    local radius = (vp.Y / 2) * math.tan(math.rad(S.aimFov / 2)) / math.tan(math.rad(cam.FieldOfView / 2))
    local maxRadius = math.min(vp.X, vp.Y) / 2 - 5
    if radius > maxRadius then
        radius = maxRadius
    end
    if radius < 4 then
        radius = 4
    end

    fovCircle.Visible = true
    fovCircle.Size = UDim2.fromOffset(radius * 2, radius * 2)
end)

local function getAimPart(model)
    if S.aimPart == "Head" then
        return model:FindFirstChild("Head")
            or model:FindFirstChild("UpperTorso")
            or model:FindFirstChild("Torso")
            or model:FindFirstChild("HumanoidRootPart")
    elseif S.aimPart == "Torso" then
        return model:FindFirstChild("UpperTorso")
            or model:FindFirstChild("Torso")
            or model:FindFirstChild("HumanoidRootPart")
    else
        return model:FindFirstChild("HumanoidRootPart")
    end
end

local function hasLineOfSight(targetPart)
    local cam = Workspace.CurrentCamera
    if not cam then
        return true
    end

    local origin = cam.CFrame.Position
    local dir = targetPart.Position - origin
    if dir.Magnitude < 0.1 then
        return true
    end

    local rayParams = RaycastParams.new()
    pcall(function()
        rayParams.FilterType = Enum.RaycastFilterType.Exclude
    end)

    local filterList = {}
    if LocalPlayer.Character then
        table.insert(filterList, LocalPlayer.Character)
    end
    if targetPart.Parent then
        table.insert(filterList, targetPart.Parent)
    end
    rayParams.FilterDescendantsInstances = filterList

    return Workspace:Raycast(origin, dir, rayParams) == nil
end

local function passTargetFilter(model)
    local player = getPlayer(model)
    if S.aimTargetMode == "player" then
        return player ~= nil
    end
    if S.aimTargetMode == "npc" then
        return player == nil
    end
    return true
end

local function findBestTarget()
    local cam = Workspace.CurrentCamera
    local character = LocalPlayer.Character
    local hrp = character and character:FindFirstChild("HumanoidRootPart")
    if not cam or not hrp then
        return nil
    end

    local myTeam = LocalPlayer.Team
    local camPos = cam.CFrame.Position
    local lookVec = cam.CFrame.LookVector
    local best = nil
    local bestScore = nil
    local stickyBonus = 1 - math.clamp(S.aimStick / 100, 0, 0.9)

    if S.aimPriority == "crosshair" then
        bestScore = S.aimFov / 2
    elseif S.aimPriority == "distance" then
        bestScore = S.aimDist
    elseif S.aimPriority == "health" then
        bestScore = math.huge
    else
        bestScore = S.aimDist
    end

    for humanoid in pairs(humanoids) do
        if humanoid and humanoid.Parent and humanoid.Health > 0 then
            local model = humanoid.Parent
            if model and model:IsA("Model") and not isSelf(model) and passTargetFilter(model) then
                local target = model:FindFirstChild("HumanoidRootPart")
                if target then
                    local dist = (target.Position - hrp.Position).Magnitude
                    if dist <= S.aimDist then
                        local skip = false

                        if S.aimTeam and myTeam then
                            local player = getPlayer(model)
                            if player and player.Team and player.Team == myTeam then
                                skip = true
                            end
                        end

                        if not skip then
                            local visible = true
                            if S.aimWall then
                                visible = hasLineOfSight(getAimPart(model) or target)
                            end

                            if visible then
                                local picked = false
                                local effectiveDist = dist
                                if model == aimTarget then
                                    effectiveDist = dist * stickyBonus
                                end

                                if S.aimPriority == "crosshair" then
                                    local toTarget = target.Position - camPos
                                    if toTarget.Magnitude > 0.1 then
                                        toTarget = toTarget.Unit
                                        local angle = math.deg(math.acos(math.clamp(lookVec:Dot(toTarget), -1, 1)))
                                        if angle <= S.aimFov / 2 and angle < bestScore then
                                            bestScore = angle
                                            picked = true
                                        end
                                    end
                                elseif S.aimPriority == "health" then
                                    if humanoid.Health < bestScore then
                                        bestScore = humanoid.Health
                                        picked = true
                                    end
                                else
                                    if effectiveDist < bestScore then
                                        bestScore = effectiveDist
                                        picked = true
                                    end
                                end

                                if picked then
                                    best = model
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    return best
end

local function startFly()
    local character = LocalPlayer.Character
    local hrp = character and character:FindFirstChild("HumanoidRootPart")
    if not hrp then
        return
    end

    for _, v in pairs(character:GetDescendants()) do
        if v:IsA("BasePart") then
            v.CanCollide = false
        end
    end

    flyGyro = Instance.new("BodyGyro")
    flyGyro.P = 9e4
    flyGyro.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
    flyGyro.CFrame = hrp.CFrame
    flyGyro.Parent = hrp

    flyVel = Instance.new("BodyVelocity")
    flyVel.MaxForce = Vector3.new(9e9, 9e9, 9e9)
    flyVel.Velocity = Vector3.zero
    flyVel.Parent = hrp

    flyConn = RunService.RenderStepped:Connect(function()
        if not S.fly then
            return
        end

        local char = LocalPlayer.Character
        local myHRP = char and char:FindFirstChild("HumanoidRootPart")
        local humanoid = char and char:FindFirstChildOfClass("Humanoid")
        if not myHRP or not flyGyro or not flyVel then
            return
        end

        local cam = Workspace.CurrentCamera
        flyGyro.CFrame = cam.CFrame

        local moveVec = Vector3.zero

        if humanoid and humanoid.MoveDirection.Magnitude > 0.05 then
            local moveDir = humanoid.MoveDirection
            local camLook = cam.CFrame.LookVector
            local flatLook = Vector3.new(camLook.X, 0, camLook.Z)

            if flatLook.Magnitude > 0.01 then
                flatLook = flatLook.Unit
                local flatRight = Vector3.new(flatLook.Z, 0, -flatLook.X)
                local forward = moveDir:Dot(flatLook)
                local right = moveDir:Dot(flatRight)
                moveVec = cam.CFrame.LookVector * forward + cam.CFrame.RightVector * right
            end
        end

        if S.flyUp then
            moveVec = moveVec + cam.CFrame.UpVector
        end
        if S.flyDown then
            moveVec = moveVec - cam.CFrame.UpVector
        end

        if moveVec.Magnitude > 0.05 then
            flyVel.Velocity = moveVec.Unit * S.flySpeed
        else
            flyVel.Velocity = Vector3.zero
        end
    end)
end

local function stopFly()
    if flyConn then
        flyConn:Disconnect()
        flyConn = nil
    end
    if flyGyro then
        flyGyro:Destroy()
        flyGyro = nil
    end
    if flyVel then
        flyVel:Destroy()
        flyVel = nil
    end

    local character = LocalPlayer.Character
    if character then
        for _, v in pairs(character:GetDescendants()) do
            if v:IsA("BasePart") then
                v.CanCollide = true
            end
        end
    end
end

RunService:BindToRenderStep("GT_Aim", 201, function()
    if not S.aim then
        aimTarget = nil
        return
    end

    local cam = Workspace.CurrentCamera
    if not cam then
        return
    end

    if aimTarget then
        local humanoid = aimTarget:FindFirstChildOfClass("Humanoid")
        if not humanoid or humanoid.Health <= 0 or not aimTarget.Parent or isSelf(aimTarget) then
            aimTarget = nil
        end
    end

    if not (S.aimPriority == "lock" and aimTarget) then
        aimTarget = findBestTarget()
    end

    if not aimTarget then
        return
    end

    local targetPart = getAimPart(aimTarget)
    if not targetPart then
        return
    end

    local targetCF = CFrame.new(cam.CFrame.Position, targetPart.Position)

    if S.aimSmooth >= 100 then
        cam.CFrame = targetCF
    else
        cam.CFrame = cam.CFrame:Lerp(targetCF, math.clamp(S.aimSmooth / 100, 0.05, 1))
    end
end)

local function captureJumpPower(humanoid)
    if not origJumpPower then
        origJumpPower = humanoid.JumpPower
        origJumpHeight = humanoid.JumpHeight
        origUseJumpPower = humanoid.UseJumpPower
    end
end

RunService.Heartbeat:Connect(function()
    local character = LocalPlayer.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if not humanoid then
        return
    end

    captureJumpPower(humanoid)

    if S.speedOn and humanoid.WalkSpeed ~= S.walk then
        humanoid.WalkSpeed = S.walk
    end

    if S.jumpOn then
        local targetHeight = S.jp / 7.85
        if humanoid.JumpPower ~= S.jp then
            humanoid.JumpPower = S.jp
        end
        if humanoid.JumpHeight ~= targetHeight then
            humanoid.JumpHeight = targetHeight
        end
        if humanoid.UseJumpPower ~= true then
            humanoid.UseJumpPower = true
        end
    end
end)

local function hookHumanoid(humanoid)
    captureJumpPower(humanoid)

    humanoid:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
        if S.speedOn and humanoid.WalkSpeed ~= S.walk then
            humanoid.WalkSpeed = S.walk
        end
    end)

    humanoid:GetPropertyChangedSignal("JumpPower"):Connect(function()
        if S.jumpOn and humanoid.JumpPower ~= S.jp then
            humanoid.JumpPower = S.jp
        end
    end)

    humanoid:GetPropertyChangedSignal("JumpHeight"):Connect(function()
        if S.jumpOn then
            local t = S.jp / 7.85
            if humanoid.JumpHeight ~= t then
                humanoid.JumpHeight = t
            end
        end
    end)

    humanoid:GetPropertyChangedSignal("UseJumpPower"):Connect(function()
        if S.jumpOn and humanoid.UseJumpPower ~= true then
            humanoid.UseJumpPower = true
        end
    end)
end

spawn(function()
    while screenGui.Parent do
        local character = LocalPlayer.Character
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        if humanoid and not humanoid:GetAttribute("GT_H") then
            humanoid:SetAttribute("GT_H", true)
            pcall(function()
                hookHumanoid(humanoid)
            end)
        end
        wait(1)
    end
end)

RunService.Stepped:Connect(function()
    if not S.noclip then
        return
    end

    local character = LocalPlayer.Character
    if not character then
        return
    end

    for _, v in pairs(character:GetDescendants()) do
        if v:IsA("BasePart") and v.CanCollide then
            v.CanCollide = false
        end
    end
end)

local function shouldESP(model)
    if not S.esp or isSelf(model) or not model.Parent then
        return false
    end

    local character = LocalPlayer.Character
    if character and model ~= character and model:IsDescendantOf(character) then
        return false
    end

    local humanoid = model:FindFirstChildOfClass("Humanoid")
    if not humanoid then
        return false
    end

    local player = getPlayer(model)
    if S.espTarget == "player" then
        return player ~= nil
    end
    if S.espTarget == "npc" then
        return player == nil
    end
    return true
end

local function getModelColor(model)
    if isTeammate(model) then
        return C.gr
    end
    local player = getPlayer(model)
    if player then
        return C.rd
    end
    return C.pi
end

local function addESP(model)
    if espObjects[model] or isSelf(model) then
        return
    end

    local hrp = model:FindFirstChild("HumanoidRootPart")
    local humanoid = model:FindFirstChildOfClass("Humanoid")
    if not hrp or not humanoid then
        return
    end

    local color = getModelColor(model)
    local data = {color = color, defaultColor = color}

    if S.espHL then
        local highlight = Instance.new("Highlight")
        highlight.Adornee = model
        highlight.FillColor = color
        highlight.OutlineColor = Color3.new(1, 1, 1)
        highlight.FillTransparency = 0.6
        highlight.OutlineTransparency = 0
        pcall(function()
            highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        end)
        highlight.Parent = screenGui
        data.highlight = highlight
    end

    if S.espBox then
        local box = Instance.new("Frame")
        box.BackgroundTransparency = 1
        box.Visible = false
        box.ZIndex = 3
        box.Parent = screenGui
        local s = stroke(box, color, 2, 0)
        data.box = box
        data.boxStroke = s
    end

    if S.espSkel then
        local skeleton = model:FindFirstChild("UpperTorso") and SKEL_15
            or (model:FindFirstChild("Torso") and SKEL_6 or nil)
        if skeleton then
            data.skeleton = {}
            for _, pair in ipairs(skeleton) do
                local line = Instance.new("Frame")
                line.AnchorPoint = Vector2.new(0.5, 0.5)
                line.BackgroundColor3 = color
                line.BorderSizePixel = 0
                line.ZIndex = 2
                line.Visible = false
                line.Parent = screenGui
                table.insert(data.skeleton, {frame = line, from = pair[1], to = pair[2]})
            end
        end
    end

    if S.espTracer then
        local tracer = Instance.new("Frame")
        tracer.AnchorPoint = Vector2.new(0.5, 0.5)
        tracer.BackgroundColor3 = color
        tracer.BackgroundTransparency = 0.15
        tracer.BorderSizePixel = 0
        tracer.ZIndex = 1
        tracer.Visible = false
        tracer.Parent = screenGui
        data.tracer = tracer
    end

    if S.espName or S.espDist or S.espHPNum or S.espTool then
        local billboard = Instance.new("BillboardGui")
        billboard.Adornee = hrp
        billboard.Size = UDim2.new(0, 180, 0, 20)
        billboard.StudsOffset = Vector3.new(0, 3.2, 0)
        billboard.AlwaysOnTop = true
        billboard.MaxDistance = 3000
        billboard.Parent = screenGui
        data.billboard = billboard

        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, 0, 1, 0)
        label.BackgroundTransparency = 1
        label.TextColor3 = color
        label.TextStrokeTransparency = 0
        label.TextStrokeColor3 = Color3.new(0, 0, 0)
        label.TextSize = 13
        label.Font = Enum.Font.GothamBold
        label.Text = ""
        label.Parent = billboard
        data.label = label
    end

    espObjects[model] = data
end

local function removeESP(model)
    local data = espObjects[model]
    if not data then
        return
    end

    if data.highlight then
        data.highlight:Destroy()
    end
    if data.box then
        data.box:Destroy()
    end
    if data.billboard then
        data.billboard:Destroy()
    end
    if data.tracer then
        data.tracer:Destroy()
    end
    if data.skeleton then
        for _, bone in ipairs(data.skeleton) do
            bone.frame:Destroy()
        end
    end

    espObjects[model] = nil
end

local function refreshESP()
    for model, _ in pairs(espObjects) do
        removeESP(model)
    end
    espObjects = {}

    if not S.esp then
        return
    end

    pcall(function()
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj:IsA("Model") and not isSelf(obj) and shouldESP(obj) then
                addESP(obj)
            end
        end
    end)
end

RunService.RenderStepped:Connect(function()
    if not S.esp then
        return
    end

    local cam = Workspace.CurrentCamera
    if not cam then
        return
    end

    local vp = cam.ViewportSize
    local screenBottom = Vector2.new(vp.X / 2, vp.Y)

    local character = LocalPlayer.Character
    local hrp = character and character:FindFirstChild("HumanoidRootPart")
    local myPos = hrp and hrp.Position

    for model, data in pairs(espObjects) do
        local target = model:FindFirstChild("HumanoidRootPart")
        local humanoid = model:FindFirstChildOfClass("Humanoid")

        if not target or not humanoid or humanoid.Health <= 0 or not model.Parent or isSelf(model) then
            removeESP(model)
        else
            local isAimTarget = (model == aimTarget and S.aim and S.aimHL)
            local color = isAimTarget and C.gold or data.defaultColor

            if data.highlight then
                data.highlight.FillColor = color
            end
            if data.boxStroke then
                data.boxStroke.Color = color
            end
            if data.label then
                data.label.TextColor3 = color
            end
            if data.tracer then
                data.tracer.BackgroundColor3 = color
            end

            local dist = nil
            if myPos then
                dist = (target.Position - myPos).Magnitude
            end

            local inRange = true
            if dist and S.espMax > 0 then
                inRange = dist <= S.espMax
            end

            if data.highlight then
                data.highlight.FillTransparency = inRange and 0.6 or 1
                data.highlight.OutlineTransparency = inRange and 0 or 1
            end

            if data.billboard then
                data.billboard.Enabled = inRange
                if inRange and data.label then
                    local parts = {}
                    if S.espName then
                        table.insert(parts, model.Name)
                    end
                    if S.espHPNum then
                        table.insert(parts, "HP " .. math.floor(humanoid.Health))
                    end
                    if S.espDist and dist then
                        table.insert(parts, math.floor(dist) .. "m")
                    end
                    if S.espTool then
                        local tool = model:FindFirstChildOfClass("Tool")
                        table.insert(parts, "[" .. (tool and tool.Name or "无") .. "]")
                    end
                    data.label.Text = table.concat(parts, "  ")
                end
            end

            local topPos, bottomPos, centerX = nil, nil, nil

            if inRange and (data.box or data.tracer) then
                local topWorld = target.Position + Vector3.new(0, 2.8, 0)
                local bottomWorld = target.Position - Vector3.new(0, 3, 0)

                local topScreen, topOn = cam:WorldToViewportPoint(topWorld)
                local bottomScreen, bottomOn = cam:WorldToViewportPoint(bottomWorld)

                if topOn and bottomOn and topScreen.Z > 0 and bottomScreen.Z > 0 then
                    topPos = Vector2.new(topScreen.X, topScreen.Y)
                    bottomPos = Vector2.new(bottomScreen.X, bottomScreen.Y)
                    centerX = (topPos.X + bottomPos.X) / 2

                    if data.box then
                        local height = math.abs(bottomPos.Y - topPos.Y)
                        local width = height * 0.55
                        local yPos = math.min(topPos.Y, bottomPos.Y)
                        data.box.Visible = true
                        data.box.Size = UDim2.fromOffset(width, height)
                        data.box.Position = UDim2.fromOffset(centerX - width / 2, yPos + S.espYOff)
                    end
                else
                    if data.box then
                        data.box.Visible = false
                    end
                end
            end

            if data.tracer then
                if inRange and topPos and bottomPos then
                    local cX = centerX
                    local cY = (topPos.Y + bottomPos.Y) / 2 + S.espYOff
                    local targetScreen = Vector2.new(cX, cY)
                    local delta = targetScreen - screenBottom
                    local length = delta.Magnitude

                    if length > 2 then
                        local angle = math.deg(math.atan2(delta.Y, delta.X))
                        local mid = (screenBottom + targetScreen) / 2
                        data.tracer.Visible = true
                        data.tracer.Position = UDim2.fromOffset(mid.X, mid.Y)
                        data.tracer.Size = UDim2.fromOffset(length, 1.5)
                        data.tracer.Rotation = angle
                    else
                        data.tracer.Visible = false
                    end
                else
                    data.tracer.Visible = false
                end
            end

            if data.skeleton then
                if inRange then
                    for _, bone in ipairs(data.skeleton) do
                        local partA = model:FindFirstChild(bone.from)
                        local partB = model:FindFirstChild(bone.to)

                        if partA and partB then
                            local screenA, onA = cam:WorldToViewportPoint(partA.Position)
                            local screenB, onB = cam:WorldToViewportPoint(partB.Position)

                            if onA and onB and screenA.Z > 0 and screenB.Z > 0 then
                                local a = Vector2.new(screenA.X, screenA.Y)
                                local b = Vector2.new(screenB.X, screenB.Y)
                                local delta = b - a
                                local length = delta.Magnitude

                                if length > 1 then
                                    local angle = math.deg(math.atan2(delta.Y, delta.X))
                                    local mid = (a + b) / 2
                                    bone.frame.Visible = true
                                    bone.frame.BackgroundColor3 = color
                                    bone.frame.Position = UDim2.fromOffset(mid.X, mid.Y + S.espYOff)
                                    bone.frame.Size = UDim2.fromOffset(length, 2)
                                    bone.frame.Rotation = angle
                                else
                                    bone.frame.Visible = false
                                end
                            else
                                bone.frame.Visible = false
                            end
                        else
                            bone.frame.Visible = false
                        end
                    end
                else
                    for _, bone in ipairs(data.skeleton) do
                        bone.frame.Visible = false
                    end
                end
            end
        end
    end
end)

Workspace.DescendantAdded:Connect(function(desc)
    if not S.esp or not desc:IsA("Humanoid") then
        return
    end
    local model = desc.Parent
    if not model or not model:IsA("Model") then
        return
    end
    wait(0.3)
    if S.esp and model.Parent and not isSelf(model) and shouldESP(model) then
        addESP(model)
    end
end)

Workspace.DescendantRemoving:Connect(function(desc)
    if espObjects[desc] then
        removeESP(desc)
    end
end)

LocalPlayer.CharacterAdded:Connect(function()
    for model, _ in pairs(espObjects) do
        if isSelf(model) then
            removeESP(model)
        end
    end
end)

local CONFIG_FILE = "gt_config.json"

local function saveConfig()
    local ok, err = pcall(function()
        local data = HttpService:JSONEncode(S)
        if writefile then
            writefile(CONFIG_FILE, data)
        else
            error("no writefile")
        end
    end)
    return ok, err
end

local function loadConfig()
    local ok, err = pcall(function()
        if not readfile then
            error("no readfile")
        end
        if not isfile or not isfile(CONFIG_FILE) then
            error("no config")
        end

        local data = readfile(CONFIG_FILE)
        local parsed = HttpService:JSONDecode(data)

        for k, v in pairs(parsed) do
            if S[k] ~= nil then
                S[k] = v
            end
        end

        for _, fn in ipairs(toggleRefs) do
            pcall(fn)
        end
        for _, fn in ipairs(sliderRefs) do
            pcall(fn)
        end
        for _, fn in ipairs(segRefs) do
            pcall(fn)
        end

        if S.fullbright then
            pcall(setFullbright, true)
        end
        if S.fly then
            pcall(startFly)
        end
        if S.esp then
            pcall(refreshESP)
        end
        if S.itemESP then
            pcall(scanItems)
        end

        if S.entList then
            if not entFrame then
                entFrame = Instance.new("Frame")
                entFrame.Size = UDim2.new(1, 0, 0, 250)
                entFrame.BackgroundColor3 = C.deep
                entFrame.BackgroundTransparency = 0.4
                entFrame.BorderSizePixel = 0
                entFrame.Parent = entityListCard
                corner(entFrame, 8)
            end
            entFrame.Visible = true
            pcall(refreshEntityList)
        end
    end)

    return ok, err
end

local moveCard = newCard(tabMove)
newSection(moveCard, "飞行控制", C.cy)
newToggle(moveCard, "飞天模式", function()
    return S.fly
end, function(v)
    S.fly = v
    if v then
        startFly()
    else
        stopFly()
    end
end, C.cy)
newSlider(moveCard, "飞行速度", function()
    return S.flySpeed
end, function(v)
    S.flySpeed = v
end, 10, 300, 5, C.cy)
newToggle(moveCard, "上升", function()
    return S.flyUp
end, function(v)
    S.flyUp = v
end, C.cy)
newToggle(moveCard, "下降", function()
    return S.flyDown
end, function(v)
    S.flyDown = v
end, C.cy)

local teleportCard = newCard(tabMove)
newSection(teleportCard, "传送系统", C.cy)
newAction(teleportCard, "传送到天空", function()
    local character = LocalPlayer.Character
    local hrp = character and character:FindFirstChild("HumanoidRootPart")
    if hrp then
        hrp.CFrame = CFrame.new(hrp.Position.X, 500, hrp.Position.Z)
    end
end, C.cy)
newAction(teleportCard, "回原点", function()
    local character = LocalPlayer.Character
    local hrp = character and character:FindFirstChild("HumanoidRootPart")
    if hrp then
        hrp.CFrame = CFrame.new(0, 50, 0)
    end
end, C.cy)
newAction(teleportCard, "随机传送", function()
    local character = LocalPlayer.Character
    local hrp = character and character:FindFirstChild("HumanoidRootPart")
    if hrp then
        local angle = math.random() * math.pi * 2
        local dist = math.random(100, 400)
        hrp.CFrame = CFrame.new(math.cos(angle) * dist, 150, math.sin(angle) * dist)
    end
end, C.cy)

local attrCard = newCard(tabAttr)
newSection(attrCard, "移动属性", C.pu)
newSlider(attrCard, "移动速度", function()
    return S.walk
end, function(v)
    S.walk = v
end, 16, 500, 4, C.pu)
newSlider(attrCard, "跳跃高度", function()
    return S.jp
end, function(v)
    S.jp = v
end, 50, 500, 5, C.pu)
newToggle(attrCard, "启用移速", function()
    return S.speedOn
end, function(v)
    S.speedOn = v
end, C.pu)
newToggle(attrCard, "启用跳跃", function()
    return S.jumpOn
end, function(v)
    S.jumpOn = v
end, C.pu)
newToggle(attrCard, "穿墙", function()
    return S.noclip
end, function(v)
    S.noclip = v
end, C.pu)

newSection(attrCard, "视觉增强", C.pu)
newToggle(attrCard, "全图高亮度", function()
    return S.fullbright
end, function(v)
    S.fullbright = v
    setFullbright(v)
end, C.pu)

local espCard = newCard(tabEsp)
newSection(espCard, "透视总控", C.gr)
newToggle(espCard, "启用透视", function()
    return S.esp
end, function(v)
    S.esp = v
    refreshESP()
end, C.gr)

newSection(espCard, "目标筛选", C.gr)
newSegment(espCard, {"玩家", "NPC", "全部"}, 3, function(i)
    if i == 1 then
        S.espTarget = "player"
    elseif i == 2 then
        S.espTarget = "npc"
    else
        S.espTarget = "all"
    end
    if S.esp then
        refreshESP()
    end
end, C.gr, function()
    if S.espTarget == "player" then
        return 1
    elseif S.espTarget == "npc" then
        return 2
    else
        return 3
    end
end)

newSection(espCard, "显示元素", C.gr)
newToggle(espCard, "高亮描边", function()
    return S.espHL
end, function(v)
    S.espHL = v
    if S.esp then
        refreshESP()
    end
end, C.gr)
newToggle(espCard, "方框绘制", function()
    return S.espBox
end, function(v)
    S.espBox = v
    if S.esp then
        refreshESP()
    end
end, C.gr)
newToggle(espCard, "骨骼绘制", function()
    return S.espSkel
end, function(v)
    S.espSkel = v
    if S.esp then
        refreshESP()
    end
end, C.gr)
newToggle(espCard, "天线追踪", function()
    return S.espTracer
end, function(v)
    S.espTracer = v
    if S.esp then
        refreshESP()
    end
end, C.gr)
newToggle(espCard, "名字标签", function()
    return S.espName
end, function(v)
    S.espName = v
    if S.esp then
        refreshESP()
    end
end, C.gr)
newToggle(espCard, "距离显示", function()
    return S.espDist
end, function(v)
    S.espDist = v
    if S.esp then
        refreshESP()
    end
end, C.gr)
newToggle(espCard, "血量数字", function()
    return S.espHPNum
end, function(v)
    S.espHPNum = v
    if S.esp then
        refreshESP()
    end
end, C.gr)
newToggle(espCard, "手持物品", function()
    return S.espTool
end, function(v)
    S.espTool = v
    if S.esp then
        refreshESP()
    end
end, C.gr)

newSection(espCard, "特殊功能", C.gr)
newToggle(espCard, "队友变绿", function()
    return S.espTeamColor
end, function(v)
    S.espTeamColor = v
    if S.esp then
        refreshESP()
    end
end, C.gr)
newSlider(espCard, "绘制距离", function()
    return S.espMax
end, function(v)
    S.espMax = v
end, 30, 1500, 10, C.gr)
newSlider(espCard, "Y偏移", function()
    return S.espYOff
end, function(v)
    S.espYOff = v
end, -60, 60, 1, C.gr)

local radarCard = newCard(tabEsp)
newSection(radarCard, "雷达", C.gr)
newToggle(radarCard, "启用雷达", function()
    return S.radar
end, function(v)
    S.radar = v
end, C.gr)
newSlider(radarCard, "雷达范围", function()
    return S.radarRange
end, function(v)
    S.radarRange = v
end, 50, 500, 10, C.gr)
newSlider(radarCard, "雷达大小", function()
    return S.radarSize
end, function(v)
    S.radarSize = v
end, 100, 200, 5, C.gr)

local entityListCard = newCard(tabEsp)
newSection(entityListCard, "实体列表", C.gr)
newToggle(entityListCard, "启用列表", function()
    return S.entList
end, function(v)
    S.entList = v
    if v then
        if not entFrame then
            entFrame = Instance.new("Frame")
            entFrame.Size = UDim2.new(1, 0, 0, 250)
            entFrame.BackgroundColor3 = C.deep
            entFrame.BackgroundTransparency = 0.4
            entFrame.BorderSizePixel = 0
            entFrame.LayoutOrder = layoutOrder + 1
            entFrame.Parent = entityListCard
            corner(entFrame, 8)
            layoutOrder = layoutOrder + 1
        end
        entFrame.Visible = true
        refreshEntityList()
    elseif entFrame then
        entFrame.Visible = false
    end
end, C.gr)

local hurtCard = newCard(tabEsp)
newSection(hurtCard, "受击反馈", C.gr)
newToggle(hurtCard, "受击红闪", function()
    return S.hurtFlash
end, function(v)
    S.hurtFlash = v
end, C.gr)
newSection(hurtCard, "血量警告", C.gr)
newToggle(hurtCard, "低血量屏幕红闪", function()
    return S.lowHPWarn
end, function(v)
    S.lowHPWarn = v
end, C.gr)
newSlider(hurtCard, "警告阈值", function()
    return S.lowHPThreshold
end, function(v)
    S.lowHPThreshold = v
end, 5, 100, 5, C.gr)

local aimCard = newCard(tabAim)
newSection(aimCard, "自瞄目标筛选", C.rd)
newSegment(aimCard, {"玩家", "NPC", "全部"}, 3, function(i)
    if i == 1 then
        S.aimTargetMode = "player"
    elseif i == 2 then
        S.aimTargetMode = "npc"
    else
        S.aimTargetMode = "all"
    end
end, C.rd, function()
    if S.aimTargetMode == "player" then
        return 1
    elseif S.aimTargetMode == "npc" then
        return 2
    else
        return 3
    end
end)

newSection(aimCard, "优先级", C.rd)
newSegment(aimCard, {"准心近", "距离近", "血最少", "锁定"}, 1, function(i)
    if i == 1 then
        S.aimPriority = "crosshair"
    elseif i == 2 then
        S.aimPriority = "distance"
    elseif i == 3 then
        S.aimPriority = "health"
    else
        S.aimPriority = "lock"
    end
end, C.rd, function()
    if S.aimPriority == "crosshair" then
        return 1
    elseif S.aimPriority == "distance" then
        return 2
    elseif S.aimPriority == "health" then
        return 3
    else
        return 4
    end
end)

newSlider(aimCard, "防抖粘滞", function()
    return S.aimStick
end, function(v)
    S.aimStick = v
end, 0, 80, 5, C.rd)

newSection(aimCard, "自瞄系统", C.rd)
newToggle(aimCard, "启用自瞄", function()
    return S.aim
end, function(v)
    S.aim = v
end, C.rd)
newToggle(aimCard, "目标金色高亮", function()
    return S.aimHL
end, function(v)
    S.aimHL = v
end, C.rd)
newToggle(aimCard, "瞄准激光", function()
    return S.aimLaser
end, function(v)
    S.aimLaser = v
end, C.rd)
newToggle(aimCard, "掩体检测", function()
    return S.aimWall
end, function(v)
    S.aimWall = v
end, C.rd)
newToggle(aimCard, "显示FOV圈", function()
    return S.aimCircle
end, function(v)
    S.aimCircle = v
end, C.rd)
newSlider(aimCard, "FOV视野", function()
    return S.aimFov
end, function(v)
    S.aimFov = v
end, 10, 360, 5, C.rd)
newSlider(aimCard, "自瞄距离", function()
    return S.aimDist
end, function(v)
    S.aimDist = v
end, 50, 2000, 25, C.rd)
newSlider(aimCard, "平滑度", function()
    return S.aimSmooth
end, function(v)
    S.aimSmooth = v
end, 5, 100, 5, C.rd)
newToggle(aimCard, "队伍检测", function()
    return S.aimTeam
end, function(v)
    S.aimTeam = v
end, C.rd)

newSection(aimCard, "瞄准部位", C.rd)
newToggle(aimCard, "锁定头部", function()
    return S.aimPart == "Head"
end, function(v)
    if v then
        S.aimPart = "Head"
    end
end, C.rd)
newToggle(aimCard, "锁定躯干", function()
    return S.aimPart == "Torso"
end, function(v)
    if v then
        S.aimPart = "Torso"
    end
end, C.rd)
newToggle(aimCard, "锁定根部件", function()
    return S.aimPart == "HumanoidRootPart"
end, function(v)
    if v then
        S.aimPart = "HumanoidRootPart"
    end
end, C.rd)

local itemCard = newCard(tabHorror)
newSection(itemCard, "附近物品标记", C.pi)
newToggle(itemCard, "启用物品标记", function()
    return S.itemESP
end, function(v)
    S.itemESP = v
    if v then
        scanItems()
    else
        clearItems()
    end
end, C.pi)
newSlider(itemCard, "物品追踪范围", function()
    return S.itemRange
end, function(v)
    S.itemRange = v
end, 30, 500, 10, C.pi)

newSection(itemCard, "怪物接近警告", C.pi)
newToggle(itemCard, "屏幕震动", function()
    return S.monShake
end, function(v)
    S.monShake = v
end, C.pi)
newSlider(itemCard, "触发距离", function()
    return S.shakeDist
end, function(v)
    S.shakeDist = v
end, 20, 200, 5, C.pi)
newSlider(itemCard, "震动强度", function()
    return S.shakePower
end, function(v)
    S.shakePower = v
end, 1, 15, 1, C.pi)

newSection(itemCard, "心跳音效", C.pi)
newToggle(itemCard, "低血量心跳声", function()
    return S.heartbeat
end, function(v)
    S.heartbeat = v
end, C.pi)

local hudCard = newCard(tabSettings)
newSection(hudCard, "界面HUD", C.gold)
newToggle(hudCard, "FPS/Ping监控", function()
    return S.showFps
end, function(v)
    S.showFps = v
end, C.gold)

newSection(hudCard, "配置存档", C.gold)
newAction(hudCard, "保存当前配置", function()
    local ok, err = saveConfig()
    if ok then
        showToast("配置已保存", true)
    else
        showToast("保存失败", false)
    end
end, C.gold)
newAction(hudCard, "加载上次配置", function()
    local ok, err = loadConfig()
    if ok then
        showToast("配置已加载", true)
    else
        showToast("加载失败", false)
    end
end, C.gold)

closeBtn.MouseButton1Click:Connect(function()
    S.fly = false
    S.speedOn = false
    S.jumpOn = false
    S.noclip = false
    S.aim = false
    S.esp = false
    S.radar = false
    S.entList = false
    S.hurtFlash = false
    S.aimLaser = false
    S.lowHPWarn = false
    S.fullbright = false
    S.itemESP = false
    S.monShake = false
    S.heartbeat = false

    pcall(stopFly)
    pcall(setFullbright, false)
    pcall(clearItems)
    pcall(function()
        heartbeatSound:Stop()
    end)

    laserLine.Visible = false
    laserTip.Visible = false
    Workspace.Gravity = origGravity

    for model, _ in pairs(espObjects) do
        pcall(removeESP, model)
    end

    pcall(function()
        RunService:UnbindFromRenderStep("GT_Aim")
    end)
    pcall(function()
        RunService:UnbindFromRenderStep("GT_Shake")
    end)

    local character = LocalPlayer.Character
    if character then
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            if origJumpPower then
                humanoid.JumpPower = origJumpPower
            end
            if origJumpHeight then
                humanoid.JumpHeight = origJumpHeight
            end
            if origUseJumpPower ~= nil then
                humanoid.UseJumpPower = origUseJumpPower
            end
            humanoid.WalkSpeed = 16
        end

        for _, v in pairs(character:GetDescendants()) do
            if v:IsA("BasePart") then
                v.CanCollide = true
            end
        end
    end

    screenGui:Destroy()
    toastScreenGui:Destroy()
end)

LocalPlayer.CharacterAdded:Connect(function()
    wait(0.5)
    if S.esp then
        refreshESP()
    end
    if S.itemESP then
        scanItems()
    end
end)

spawn(function()
    wait(0.1)

    TweenService:Create(centerGlow, TweenInfo.new(0.7, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, 520, 0, 520),
    }):Play()
    TweenService:Create(centerGlow, TweenInfo.new(0.7), {BackgroundTransparency = 0.85}):Play()

    TweenService:Create(bigGlow, TweenInfo.new(1.0, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, 900, 0, 900),
    }):Play()
    TweenService:Create(bigGlow, TweenInfo.new(1.0), {BackgroundTransparency = 0.9}):Play()

    TweenService:Create(centerIcon, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        TextTransparency = 0,
        TextStrokeTransparency = 0,
    }):Play()

    TweenService:Create(ringOuter, TweenInfo.new(0.6, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, 200, 0, 200),
    }):Play()

    TweenService:Create(ringInner, TweenInfo.new(0.8, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, 140, 0, 140),
    }):Play()

    for _, dot in ipairs(satelliteDots) do
        TweenService:Create(dot, TweenInfo.new(0.4), {BackgroundTransparency = 0}):Play()
    end

    local spinAngle = 0
    local satelliteAngle = 0
    local pulseStart = tick()

    spawn(function()
        while introOverlay.Parent and ringOuter.Parent and not introDone do
            spinAngle = spinAngle + 3
            satelliteAngle = satelliteAngle + 5

            ringOuter.Rotation = spinAngle
            ringInner.Rotation = -spinAngle * 1.4

            for i, dot in ipairs(satelliteDots) do
                local angle = math.rad(satelliteAngle + (i - 1) * 90)
                local radius = 95
                dot.Position = UDim2.new(0.5, math.cos(angle) * radius, 0.5, -20 + math.sin(angle) * radius)
            end

            local elapsed = tick() - pulseStart
            centerIcon.TextSize = 80 * (1 + math.sin(elapsed * 4) * 0.08)

            wait(0.016)
        end
    end)

    wait(0.5)

    for i, entry in ipairs(titleLabels) do
        TweenService:Create(entry.label, TweenInfo.new(0.75, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Position = entry.basePos,
            Rotation = 0,
            TextTransparency = 0,
            TextStrokeTransparency = 0,
        }):Play()
        wait(0.09)
    end

    wait(1.0)

    local sweep = Instance.new("Frame")
    sweep.Size = UDim2.new(0, 100, 0, 140)
    sweep.AnchorPoint = Vector2.new(0.5, 0.5)
    sweep.Position = UDim2.new(0, -150, 0.5, 60)
    sweep.BackgroundColor3 = Color3.new(1, 1, 1)
    sweep.BackgroundTransparency = 0.15
    sweep.BorderSizePixel = 0
    sweep.ZIndex = 10
    sweep.Parent = introOverlay
    corner(sweep, 40)

    local sweepGradient = Instance.new("UIGradient")
    sweepGradient.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 1),
        NumberSequenceKeypoint.new(0.5, 0),
        NumberSequenceKeypoint.new(1, 1),
    })
    sweepGradient.Parent = sweep

    TweenService:Create(sweep, TweenInfo.new(0.9, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), {
        Position = UDim2.new(1, 150, 0.5, 60),
    }):Play()

    wait(0.45)

    for i, entry in ipairs(titleLabels) do
        TweenService:Create(entry.label, TweenInfo.new(0.15), {
            TextSize = entry.label.TextSize + 14,
            TextColor3 = Color3.new(1, 1, 1),
        }):Play()
        wait(0.05)
    end

    wait(0.35)

    for _, entry in ipairs(titleLabels) do
        local originalSize = entry.label.TextSize
        TweenService:Create(entry.label, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            TextSize = originalSize,
            TextColor3 = Color3.fromRGB(230, 250, 255),
        }):Play()
    end

    wait(0.6)

    sweep:Destroy()
    introDone = true

    for _, entry in ipairs(titleLabels) do
        TweenService:Create(entry.label, TweenInfo.new(0.4), {
            TextTransparency = 1,
            TextStrokeTransparency = 1,
        }):Play()
    end

    TweenService:Create(centerIcon, TweenInfo.new(0.4), {TextTransparency = 1}):Play()
    TweenService:Create(ringOuterStroke, TweenInfo.new(0.4), {Transparency = 1}):Play()
    TweenService:Create(ringInnerStroke, TweenInfo.new(0.4), {Transparency = 1}):Play()
    TweenService:Create(centerGlow, TweenInfo.new(0.4), {BackgroundTransparency = 1}):Play()
    TweenService:Create(bigGlow, TweenInfo.new(0.4), {BackgroundTransparency = 1}):Play()

    for _, dot in ipairs(satelliteDots) do
        TweenService:Create(dot, TweenInfo.new(0.4), {BackgroundTransparency = 1}):Play()
    end

    TweenService:Create(introOverlay, TweenInfo.new(0.4), {BackgroundTransparency = 1}):Play()

    wait(0.5)

    panel.Visible = true
    panel.Size = UDim2.new(0, 0, 0, 0)
    panel.Position = UDim2.new(0.5, 0, 0.5, 0)

    TweenService:Create(panel, TweenInfo.new(0.55, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, panelWidth, 0, panelHeight),
        Position = UDim2.new(0.5, -panelWidth / 2, 0.5, -panelHeight / 2),
    }):Play()

    wait(0.6)
    introOverlay:Destroy()
end)
