local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")

local lp = Players.LocalPlayer
local PlayerGui = lp:WaitForChild("PlayerGui")

-- CONFIG
local BASE_SEPARATION = 5 -- 5 studs de separación del que te toca
local MAX_DODGE = 100 -- máximo 100 studs si te spamean
local VOID_TIME = 3
local SAFE_HEIGHT = 10
local FAST_PART_VELOCITY = 80
local DISASTER_KEYWORDS = {"Lava", "Meteor", "Lightning", "Acid", "Spike", "Fire"}

local isDodging = false
local lastTouchTime = 0
local currentSeparation = BASE_SEPARATION -- distancia actual
local tpTimestamps = {}
local raycastParams = RaycastParams.new()
raycastParams.FilterType = Enum.RaycastFilterType.Blacklist

-- Notificación
task.spawn(function()
	local ScreenGui = Instance.new("ScreenGui")
	ScreenGui.ResetOnSpawn = false
	ScreenGui.Parent = PlayerGui
	local Frame = Instance.new("Frame", ScreenGui)
	Frame.Size = UDim2.new(0, 360, 0, 50)
	Frame.Position = UDim2.new(1, 370, 1, -60)
	Frame.AnchorPoint = Vector2.new(0, 1)
	Frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
	Instance.new("UICorner", Frame).CornerRadius = UDim.new(0, 8)
	local Text = Instance.new("TextLabel", Frame)
	Text.Size = UDim2.new(1, -10, 1, 0)
	Text.Position = UDim2.new(0, 5, 0, 0)
	Text.BackgroundTransparency = 1
	Text.Text = "🛡️ AUTO-DODGE V4 | 5-100 STUDS | FOCUS x5 TP"
	Text.TextColor3 = Color3.fromRGB(0, 200, 255)
	Text.Font = Enum.Font.GothamBold
	Text.TextSize = 13
	TweenService:Create(Frame, TweenInfo.new(0.3, Enum.EasingStyle.Back), {Position = UDim2.new(1, -370, 1, -10)}):Play()
	task.wait(3)
	TweenService:Create(Frame, TweenInfo.new(0.3), {Position = UDim2.new(1, 370, 1, -60)}):Play()
	task.wait(0.3)
	ScreenGui:Destroy()
end)

local function FindSafeSpot(origin)
	for i = 1, 36 do
		local angle = math.rad(i * 10)
		local offset = Vector3.new(math.cos(angle) * 50, 0, math.sin(angle) * 50)
		local rayOrigin = origin + offset + Vector3.new(0, 100, 0)
		local rayResult = Workspace:Raycast(rayOrigin, Vector3.new(0, -300, 0), raycastParams)
		
		if rayResult and rayResult.Instance.CanCollide then
			local safePos = rayResult.Position + Vector3.new(0, SAFE_HEIGHT, 0)
			local safe = true
			for _, keyword in pairs(DISASTER_KEYWORDS) do
				if rayResult.Instance.Name:lower():find(keyword:lower()) then
					safe = false
					break
				end
			end
			if safe then
				return safePos
			end
		end
	end
	return origin + Vector3.new(0, 20, 0)
end

local function IsInLobby(pos)
	return pos.Y > 500 or pos.Y < -1000
end

local function CheckFocus(attackerHRP)
	table.insert(tpTimestamps, tick())
	
	for i = #tpTimestamps, 1, -1 do
		if tick() - tpTimestamps[i] > 8 then
			table.remove(tpTimestamps, i)
		end
	end
	
	if #tpTimestamps >= 5 then
		tpTimestamps = {}
		
		if attackerHRP and attackerHRP.Parent then
			local originalCF = attackerHRP.CFrame
			attackerHRP.CFrame = attackerHRP.CFrame - Vector3.new(0, 50, 0)
			attackerHRP.Anchored = true
			task.delay(VOID_TIME, function()
				if attackerHRP and attackerHRP.Parent then
					attackerHRP.Anchored = false
					attackerHRP.CFrame = originalCF + Vector3.new(0, 5, 0)
				end
			end)
		end
	end
end

local function DodgeTouch(attackerChar)
	if isDodging then return end
	isDodging = true
	
	local char = lp.Character
	local HRP = char and char:FindFirstChild("HumanoidRootPart")
	local attackerHRP = attackerChar and attackerChar:FindFirstChild("HumanoidRootPart")
	if not HRP or not attackerHRP then isDodging = false return end
	
	-- Sistema progresivo: si te tocan en <3s desde el último TP, duplica distancia
	local now = tick()
	if now - lastTouchTime < 3 then
		currentSeparation = math.min(currentSeparation * 2, MAX_DODGE) -- 5 -> 10 -> 20 -> 40 -> 80 -> 100
	else
		currentSeparation = BASE_SEPARATION -- reset a 5 studs
	end
	lastTouchTime = now
	
	-- Calcula posición a exactamente currentSeparation studs del atacante
	local dir = (HRP.Position - attackerHRP.Position).Unit
	if dir.Magnitude == 0 then dir = Vector3.new(1, 0, 0) end
	
	-- Posición objetivo: 5 studs desde el atacante en dirección opuesta
	local targetPos = attackerHRP.Position + dir * currentSeparation
	local safePos = FindSafeSpot(targetPos)
	
	HRP.CFrame = CFrame.new(safePos)
	
	CheckFocus(attackerHRP)
	
	task.wait(0.05)
	isDodging = false
end

local function SetupDodge(char)
	local Humanoid = char:WaitForChild("Humanoid")
	local HRP = char:WaitForChild("HumanoidRootPart")
	
	raycastParams.FilterDescendantsInstances = {char}
	
	-- ANTI-TOQUE: 5 studs de separación, escala hasta 100
	for _, part in pairs(char:GetDescendants()) do
		if part:IsA("BasePart") then
			part.Touched:Connect(function(hit)
				local attackerChar = hit:FindFirstAncestorOfClass("Model")
				local attackerHum = attackerChar and attackerChar:FindFirstChildOfClass("Humanoid")
				local attackerPlr = attackerChar and Players:GetPlayerFromCharacter(attackerChar)
				
				if attackerPlr and attackerPlr ~= lp and attackerHum and attackerHum.Health > 0 then
					DodgeTouch(attackerChar)
				end
			end)
		end
	end
	
	-- ANTI-DESASTRE + ANTI PIEZAS VOLADORAS
	RunService.Heartbeat:Connect(function()
		if isDodging or not HRP.Parent then return end
		
		for _, part in pairs(Workspace:GetPartBoundsInBox(HRP.CFrame + Vector3.new(0, 15, 0), Vector3.new(60, 30, 60))) do
			for _, keyword in pairs(DISASTER_KEYWORDS) do
				if part.Name:lower():find(keyword:lower()) or part.Parent.Name:lower():find(keyword:lower()) then
					if part.AssemblyLinearVelocity.Y < -20 then
						local safePos = FindSafeSpot(HRP.Position)
						HRP.CFrame = CFrame.new(safePos)
						CheckFocus(nil)
						return
					end
				end
			end
			
			if not part.Anchored and not Players:GetPlayerFromCharacter(part.Parent) then
				if part.AssemblyLinearVelocity.Magnitude > FAST_PART_VELOCITY then
					local dist = (part.Position - HRP.Position).Magnitude
					if dist < 25 then
						if IsInLobby(HRP.Position) then
							HRP.CFrame = CFrame.new(FindSafeSpot(Vector3.new(0, 10, 0)))
						else
							HRP.CFrame = CFrame.new(0, 1000, 0)
						end
						CheckFocus(nil)
						return
					end
				end
			end
		end
	end)
end

lp.CharacterAdded:Connect(SetupDodge)
if lp.Character then
	SetupDodge(lp.Character)
end
