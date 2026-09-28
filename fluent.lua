local function safeLoad(url)
    local success, response = pcall(function()
        return game:HttpGet(url)
    end)

    if not success or not response or response == "" then
        warn("[Fluent X Hub] Failed to fetch: " .. tostring(url))
        return nil
    end

    local chunk, err = loadstring(response)
    if not chunk then
        warn("[Fluent X Hub] Loadstring failed: " .. tostring(err))
        return nil
    end

    local ok, result = pcall(chunk)
    if not ok then
        warn("[Fluent X Hub] Runtime error: " .. tostring(result))
        return nil
    end

    return result
end

local Fluent = safeLoad("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua")

if not Fluent then
    warn("[Fluent X Hub] Fluent UI failed to load. Aborting.")
    return
end

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Lighting         = game:GetService("Lighting")
local Teams            = game:GetService("Teams")
local VirtualUser      = game:GetService("VirtualUser")
local LocalPlayer      = Players.LocalPlayer
local Camera           = workspace.CurrentCamera

local State = {
    AimbotEnabled    = false,
    AimbotHeld       = false,
    AimbotSmooth     = 8,
    AimbotFOV        = 90,
    ShowFOV          = true,
    AimbotTargetPart = "Head",
    LockTeammates    = true,
    WallCheck        = true,
    TriggerEnabled   = false,
    TriggerKey       = nil,
    TriggerAlwaysOn  = false,
    TriggerDelay     = 0,
    TriggerHeld      = false,
    ESP = {
        BoxESP       = false,
        OutlineESP   = false,
        NameESP      = false,
        DistanceESP  = false,
        ESPTeammates = false,
    },
    WalkSpeed        = 16,
    JumpPower        = 50,
    Fullbright       = false,
    NoFog            = false,
    UIKey            = Enum.KeyCode.RightShift,
    InfJump          = false,
    Noclip           = false,
    Fly              = false,
    FlySpeed         = 80,
    AutoRespawn      = false,
    TouchKill        = false,
    AntiAFK          = false,
    FPSBoost         = false,
}

local FOVCircle
pcall(function()
    FOVCircle = Drawing.new("Circle")
    FOVCircle.Color = Color3.fromRGB(0, 178, 255)
    FOVCircle.Thickness = 1.5
    FOVCircle.NumSides = 64
    FOVCircle.Filled = false
    FOVCircle.Visible = true
end)

local function isTeammate(p)
    return LocalPlayer.Team and p.Team == LocalPlayer.Team
end

local function getESPColor(p)
    if #Teams:GetChildren() > 0 and p.TeamColor then return p.TeamColor.Color end
    return Color3.fromRGB(0, 178, 255)
end

local Window = Fluent:CreateWindow({
    Title = "Fluent X Hub",
    SubTitle = "by Fluent X",
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 460),
    Acrylic = true,
    Theme = "Aqua",
    MinimizeKey = Enum.KeyCode.RightShift
})

local Tabs = {
    Aimbot   = Window:AddTab({ Title = "Aimbot", Icon = "crosshair" }),
    Trigger  = Window:AddTab({ Title = "Trigger", Icon = "mouse-pointer-click" }),
    ESP      = Window:AddTab({ Title = "ESP", Icon = "eye" }),
    Misc     = Window:AddTab({ Title = "Misc", Icon = "wrench" }),
    Settings = Window:AddTab({ Title = "Settings", Icon = "settings" }),
    Credits  = Window:AddTab({ Title = "Credits", Icon = "star" })
}

Tabs.Aimbot:AddSection("Aim Lock")

Tabs.Aimbot:AddToggle("AimbotEnabled", {
    Title = "Aimbot Enabled",
    Default = false
}):OnChanged(function(v) State.AimbotEnabled = v end)

Tabs.Aimbot:AddToggle("LockTeammates", {
    Title = "Team Check",
    Default = true
}):OnChanged(function(v) State.LockTeammates = v end)

Tabs.Aimbot:AddToggle("WallCheck", {
    Title = "Wall Check",
    Default = true
}):OnChanged(function(v) State.WallCheck = v end)

Tabs.Aimbot:AddToggle("ShowFOV", {
    Title = "Show FOV Circle",
    Default = true
}):OnChanged(function(v)
    State.ShowFOV = v
    if FOVCircle then pcall(function() FOVCircle.Visible = v end) end
end)

Tabs.Aimbot:AddSection("Target")

Tabs.Aimbot:AddDropdown("AimbotTargetPart", {
    Title = "Target Part",
    Values = {"Head", "HumanoidRootPart", "Torso", "UpperTorso", "LowerTorso"},
    Multi = false,
    Default = 1
}):OnChanged(function(v) State.AimbotTargetPart = v end)

Tabs.Aimbot:AddKeybind("AimKey", {
    Title = "Aim Key (Hold)",
    Mode = "Hold",
    Default = "Q"
}):OnChanged(function(v) State.AimbotHeld = v end)

Tabs.Aimbot:AddSection("Values")

Tabs.Aimbot:AddSlider("AimbotFOV", {
    Title = "FOV Radius",
    Default = 90,
    Min = 10,
    Max = 600,
    Rounding = 0,
    Suffix = " px"
}):OnChanged(function(v) State.AimbotFOV = v end)

Tabs.Aimbot:AddSlider("AimbotSmooth", {
    Title = "Smooth",
    Default = 8,
    Min = 1,
    Max = 100,
    Rounding = 0
}):OnChanged(function(v) State.AimbotSmooth = v end)

Tabs.Trigger:AddSection("Trigger")

Tabs.Trigger:AddToggle("TriggerEnabled", {
    Title = "Triggerbot Enabled",
    Default = false
}):OnChanged(function(v) State.TriggerEnabled = v end)

Tabs.Trigger:AddToggle("TriggerAlwaysOn", {
    Title = "Always On",
    Default = false
}):OnChanged(function(v) State.TriggerAlwaysOn = v end)

Tabs.Trigger:AddKeybind("TriggerKey", {
    Title = "Trigger Key (Hold)",
    Mode = "Hold",
    Default = "E"
}):OnChanged(function(v) State.TriggerHeld = v end)

Tabs.Trigger:AddSlider("TriggerDelay", {
    Title = "Fire Delay",
    Default = 0,
    Min = 0,
    Max = 2000,
    Rounding = 0,
    Suffix = " ms"
}):OnChanged(function(v) State.TriggerDelay = v end)

Tabs.ESP:AddSection("ESP Options")

Tabs.ESP:AddToggle("BoxESP", {
    Title = "Box ESP",
    Default = false
}):OnChanged(function(v) State.ESP.BoxESP = v end)

Tabs.ESP:AddToggle("OutlineESP", {
    Title = "Outline ESP",
    Default = false
}):OnChanged(function(v) State.ESP.OutlineESP = v end)

Tabs.ESP:AddToggle("NameESP", {
    Title = "Name ESP",
    Default = false
}):OnChanged(function(v) State.ESP.NameESP = v end)

Tabs.ESP:AddToggle("DistanceESP", {
    Title = "Distance ESP",
    Default = false
}):OnChanged(function(v) State.ESP.DistanceESP = v end)

Tabs.ESP:AddToggle("ESPTeammates", {
    Title = "Show Teammates",
    Default = false
}):OnChanged(function(v) State.ESP.ESPTeammates = v end)

Tabs.Misc:AddSection("Movement")

Tabs.Misc:AddToggle("InfJump", {
    Title = "Infinite Jump",
    Default = false
}):OnChanged(function(v) State.InfJump = v end)

Tabs.Misc:AddToggle("Noclip", {
    Title = "Noclip",
    Default = false
}):OnChanged(function(v)
    State.Noclip = v
    if not v then
        local c = LocalPlayer.Character
        if c then
            for _, p in ipairs(c:GetDescendants()) do
                if p:IsA("BasePart") then p.CanCollide = true end
            end
        end
    end
end)

Tabs.Misc:AddToggle("Fly", {
    Title = "Fly",
    Default = false
}):OnChanged(function(v) State.Fly = v end)

Tabs.Misc:AddSlider("FlySpeed", {
    Title = "Fly Speed",
    Default = 80,
    Min = 1,
    Max = 500,
    Rounding = 0
}):OnChanged(function(v) State.FlySpeed = v end)

Tabs.Misc:AddSection("Utility")

Tabs.Misc:AddToggle("AutoRespawn", {
    Title = "Auto Respawn",
    Default = false
}):OnChanged(function(v) State.AutoRespawn = v end)

Tabs.Misc:AddToggle("AntiAFK", {
    Title = "Anti-AFK",
    Default = false
}):OnChanged(function(v)
    State.AntiAFK = v
    if v then pcall(function() VirtualUser:ActivateVirtualCursor(Vector2.new(0,0)) end) end
end)

Tabs.Misc:AddToggle("FPSBoost", {
    Title = "FPS Boost",
    Default = false
}):OnChanged(function(v)
    State.FPSBoost = v
    if v then
        for _, obj in ipairs(workspace:GetDescendants()) do
            pcall(function()
                if obj:IsA("ParticleEmitter") or obj:IsA("Trail")
                or obj:IsA("Smoke") or obj:IsA("Fire") or obj:IsA("Sparkles") then
                    obj.Enabled = false
                elseif obj:IsA("BasePart") then
                    obj.CastShadow = false
                end
            end)
        end
        pcall(function() setfpscap(999) end)
    end
end)

Tabs.Misc:AddSection("Danger")

Tabs.Misc:AddButton({
    Title = "Kill Aura Toggle",
    Callback = function()
        State.TouchKill = not State.TouchKill
        Fluent:Notify({
            Title = "Fluent X Hub",
            Content = "Touch Kill: " .. (State.TouchKill and "ON" or "OFF"),
            Duration = 3
        })
    end
})

Tabs.Settings:AddSection("Player")

Tabs.Settings:AddSlider("WalkSpeed", {
    Title = "Walk Speed",
    Default = 16,
    Min = 0,
    Max = 500,
    Rounding = 0
}):OnChanged(function(v)
    State.WalkSpeed = v
    local c = LocalPlayer.Character
    local h = c and c:FindFirstChildOfClass("Humanoid")
    if h then h.WalkSpeed = v end
end)

Tabs.Settings:AddSlider("JumpPower", {
    Title = "Jump Power",
    Default = 50,
    Min = 0,
    Max = 500,
    Rounding = 0
}):OnChanged(function(v)
    State.JumpPower = v
    local c = LocalPlayer.Character
    local h = c and c:FindFirstChildOfClass("Humanoid")
    if h then
        h.UseJumpPower = true
        h.JumpPower = v
    end
end)

Tabs.Settings:AddSection("Visual")

Tabs.Settings:AddToggle("Fullbright", {
    Title = "Fullbright",
    Default = false
}):OnChanged(function(v)
    State.Fullbright = v
    Lighting.Brightness = v and 2 or 1
    Lighting.ClockTime = v and 14 or Lighting.ClockTime
    Lighting.FogEnd = v and 9e9 or 100000
    Lighting.GlobalShadows = not v
end)

Tabs.Settings:AddToggle("NoFog", {
    Title = "No Fog",
    Default = false
}):OnChanged(function(v)
    State.NoFog = v
    Lighting.FogEnd = v and 9e9 or 100000
end)

Tabs.Settings:AddSection("UI")

Tabs.Settings:AddKeybind("UIKey", {
    Title = "Toggle UI Key",
    Mode = "Toggle",
    Default = "RightShift"
})

Tabs.Credits:AddSection("Fluent X Hub")

Tabs.Credits:AddParagraph({
    Title = "Fluent X Hub",
    Content = "Fluent UI build. Universal compatibility. Maintained by Fluent X."
})

local function getChar()
    return LocalPlayer.Character
end
local function getHRP()
    local c = getChar(); return c and c:FindFirstChild("HumanoidRootPart")
end
local function getHum()
    local c = getChar(); return c and c:FindFirstChildOfClass("Humanoid")
end

local function getNearestTarget()
    local cam = workspace.CurrentCamera
    local vp = cam.ViewportSize
    local center = Vector2.new(vp.X/2, vp.Y/2)
    local best, bestDist = nil, State.AimbotFOV

    for _, p in ipairs(Players:GetPlayers()) do
        if p == LocalPlayer then continue end
        if State.LockTeammates and isTeammate(p) then continue end
        local char = p.Character
        if not char then continue end
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hum or hum.Health <= 0 then continue end
        local part = char:FindFirstChild(State.AimbotTargetPart)
            or char:FindFirstChild("HumanoidRootPart")
        if not part then continue end

        if State.WallCheck then
            local rp = RaycastParams.new()
            rp.FilterDescendantsInstances = {getChar(), char}
            rp.FilterType = Enum.RaycastFilterType.Exclude
            local origin = cam.CFrame.Position
            local result = workspace:Raycast(origin, (part.Position - origin), rp)
            if result then continue end
        end

        local screenPos, onScreen = cam:WorldToViewportPoint(part.Position)
        if not onScreen then continue end
        local dist = Vector2.new(screenPos.X, screenPos.Y) - center
        local mag = dist.Magnitude
        if mag < bestDist then
            bestDist = mag
            best = {player=p, char=char, part=part, screen=dist}
        end
    end
    return best
end

RunService.RenderStepped:Connect(function()
    if FOVCircle then
        pcall(function()
            local vp = workspace.CurrentCamera.ViewportSize
            FOVCircle.Position = Vector2.new(vp.X/2, vp.Y/2)
            FOVCircle.Radius   = State.AimbotFOV
            FOVCircle.Visible  = State.ShowFOV
        end)
    end

    if not State.AimbotEnabled then return end
    if not State.AimbotHeld then return end

    local target = getNearestTarget()
    if not target then return end

    local cam = workspace.CurrentCamera
    local smooth = math.clamp(State.AimbotSmooth, 1, 100)
    local goal = CFrame.new(cam.CFrame.Position, target.part.Position)
    cam.CFrame = cam.CFrame:Lerp(goal, 1 / smooth)
end)

local trigLastFire = 0
RunService.Heartbeat:Connect(function()
    if not State.TriggerEnabled then return end
    local keyOk = State.TriggerAlwaysOn or State.TriggerHeld
    if not keyOk then return end

    local cam = workspace.CurrentCamera
    local vp = cam.ViewportSize
    local ray = cam:ScreenPointToRay(vp.X/2, vp.Y/2)
    local rp = RaycastParams.new()
    rp.FilterDescendantsInstances = {getChar() or {}}
    rp.FilterType = Enum.RaycastFilterType.Exclude
    local res = workspace:Raycast(ray.Origin, ray.Direction * 1000, rp)

    if res and res.Instance then
        local char = res.Instance.Parent
        local hum = char:FindFirstChildOfClass("Humanoid")
            or (char.Parent and char.Parent:FindFirstChildOfClass("Humanoid"))
        if hum and hum.Health > 0 then
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= LocalPlayer and (p.Character == char or p.Character == char.Parent) then
                    if State.LockTeammates and isTeammate(p) then break end
                    if tick() - trigLastFire < (State.TriggerDelay / 1000) then break end
                    trigLastFire = tick()
                    if mouse1press then mouse1press(); task.delay(0.03, function() if mouse1release then mouse1release() end end)
                    elseif mouse1click then mouse1click()
                    elseif VirtualInputManager then
                        pcall(function()
                            VirtualInputManager:SendMouseButtonEvent(0,0,0,true,game,1)
                            task.delay(0.03,function() VirtualInputManager:SendMouseButtonEvent(0,0,0,false,game,1) end)
                        end)
                    end
                    break
                end
            end
        end
    end
end)

local espObjects = {}
local function cleanESP(p)
    if espObjects[p] then
        for _, d in ipairs(espObjects[p]) do pcall(function() d:Remove() end) end
        espObjects[p] = nil
    end
end

RunService.Heartbeat:Connect(function()
    local cam = workspace.CurrentCamera
    for _, p in ipairs(Players:GetPlayers()) do
        if p == LocalPlayer then continue end
        if not State.ESP.ESPTeammates and isTeammate(p) then
            cleanESP(p); continue
        end
        local char = p.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if not hrp or not hum or hum.Health <= 0 then cleanESP(p); continue end

        local screenPos, onScreen = cam:WorldToViewportPoint(hrp.Position)
        if not onScreen then cleanESP(p); continue end

        pcall(function()
            if not espObjects[p] then espObjects[p] = {} end
            local col = getESPColor(p)

            if State.ESP.NameESP then
                local n = espObjects[p].nameLbl
                if not n then
                    n = Drawing.new("Text")
                    n.Center = true; n.Outline = true; n.Size = 13
                    n.Font = Drawing.Fonts.Plex
                    espObjects[p].nameLbl = n
                end
                n.Position = Vector2.new(screenPos.X, screenPos.Y - 40)
                n.Text = p.DisplayName
                n.Color = col
                n.Visible = true
            elseif espObjects[p].nameLbl then
                espObjects[p].nameLbl.Visible = false
            end

            if State.ESP.DistanceESP then
                local dist = math.floor((hrp.Position - cam.CFrame.Position).Magnitude)
                local d = espObjects[p].distLbl
                if not d then
                    d = Drawing.new("Text")
                    d.Center = true; d.Outline = true; d.Size = 11
                    d.Font = Drawing.Fonts.Plex
                    espObjects[p].distLbl = d
                end
                d.Position = Vector2.new(screenPos.X, screenPos.Y + 30)
                d.Text = dist .. " studs"
                d.Color = col
                d.Visible = true
            elseif espObjects[p].distLbl then
                espObjects[p].distLbl.Visible = false
            end

            if State.ESP.BoxESP then
                local top = cam:WorldToViewportPoint((hrp.Position + Vector3.new(0,3,0)))
                local bot = cam:WorldToViewportPoint((hrp.Position - Vector3.new(0,2.5,0)))
                local h2 = math.abs(top.Y - bot.Y)
                local w2 = h2 * 0.6
                local bx = espObjects[p].box
                if not bx then
                    bx = Drawing.new("Square")
                    bx.Filled = false; bx.Thickness = 1.5
                    espObjects[p].box = bx
                end
                bx.Position = Vector2.new(screenPos.X - w2/2, math.min(top.Y, bot.Y))
                bx.Size = Vector2.new(w2, h2)
                bx.Color = col
                bx.Visible = true
            elseif espObjects[p].box then
                espObjects[p].box.Visible = false
            end
        end)
    end
end)

Players.PlayerRemoving:Connect(function(p) cleanESP(p) end)

UserInputService.JumpRequest:Connect(function()
    if not State.InfJump then return end
    local hrp = getHRP()
    if hrp then hrp.AssemblyLinearVelocity = Vector3.new(hrp.AssemblyLinearVelocity.X, 55, hrp.AssemblyLinearVelocity.Z) end
end)

RunService.Stepped:Connect(function()
    if State.Noclip then
        local c = getChar()
        if c then
            for _, p in ipairs(c:GetDescendants()) do
                if p:IsA("BasePart") then p.CanCollide = false end
            end
        end
    end
end)

local flyBF
RunService.Heartbeat:Connect(function()
    if not State.Fly then
        if flyBF then flyBF:Destroy(); flyBF = nil end
        return
    end
    local hrp = getHRP()
    if not hrp then return end
    if not flyBF then
        flyBF = Instance.new("BodyVelocity", hrp)
        flyBF.MaxForce = Vector3.new(1e6,1e6,1e6)
        flyBF.Velocity = Vector3.zero
    end
    local cam = workspace.CurrentCamera
    local mv = Vector3.zero
    if UserInputService:IsKeyDown(Enum.KeyCode.W) then mv = mv + cam.CFrame.LookVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.S) then mv = mv - cam.CFrame.LookVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.A) then mv = mv - cam.CFrame.RightVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.D) then mv = mv + cam.CFrame.RightVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.Space) then mv = mv + Vector3.new(0,1,0) end
    if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then mv = mv - Vector3.new(0,1,0) end
    flyBF.Velocity = mv.Magnitude > 0 and mv.Unit * State.FlySpeed or Vector3.zero
end)

RunService.Heartbeat:Connect(function()
    if State.AntiAFK then
        pcall(function() VirtualUser:ActivateVirtualCursor(Vector2.new(math.random(-5,5), math.random(-5,5))) end)
    end
end)

RunService.Heartbeat:Connect(function()
    if not State.TouchKill then return end
    local hrp = getHRP()
    if not hrp then return end
    for _, p in ipairs(Players:GetPlayers()) do
        if p == LocalPlayer then continue end
        local c = p.Character
        local h = c and c:FindFirstChildOfClass("Humanoid")
        local r = c and c:FindFirstChild("HumanoidRootPart")
        if h and r and (hrp.Position - r.Position).Magnitude < 5 then
            h.Health = 0
        end
    end
end)

LocalPlayer.CharacterAdded:Connect(function(char)
    local hum = char:WaitForChild("Humanoid")
    hum.Died:Connect(function()
        if State.AutoRespawn then task.wait(1); LocalPlayer:LoadCharacter() end
    end)
    task.wait(0.1)
    local h2 = char:FindFirstChildOfClass("Humanoid")
    if h2 then
        h2.WalkSpeed = State.WalkSpeed
        h2.UseJumpPower = true
        h2.JumpPower = State.JumpPower
    end
end)

Fluent:Notify({
    Title = "Fluent X Hub",
    Content = "Loaded. Press RightShift to toggle UI.",
    Duration = 4
})
