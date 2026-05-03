local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")

local lp = Players.LocalPlayer
local PlayerGui = lp:WaitForChild("PlayerGui")

-- CONFIG
local DODGE_DISTANCE = 5
local VOID_TIME = 2
local SAFE_HEIGHT = 10
local FAST_PART_VELOCITY = 50 -- velocidad mínima para considerar pieza peligrosa
local DISASTER_KEYWORDS = {"Lava", "Meteor", "Lightning", "Acid", "Spike", "Fire"}

local isDodging = false
local lastFocusAttacker = nil
local raycastParams = RaycastParams.new()
raycastParams.FilterType = Enum.RaycastFilterType.Blacklist

-- Notificación
task.spawn(function()
	local ScreenGui = Instance.new("ScreenGui")
	ScreenGui.ResetOnSpawn = false
	ScreenGui.Parent = PlayerGui
	local Frame = Instance.new("Frame", ScreenGui)
	Frame.Size = UDim2.new(0, 320, 0, 50)
	Frame.Position = UDim2.new(1, 330, 1, -60)
	Frame.AnchorPoint = Vector2.new(0, 1)
	Frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
	Instance.new("UICorner", Frame).CornerRadius = UDim.new(0, 8)
	local Text = Instance.new("TextLabel", Frame)
	Text.Size = UDim2.new(1, -10, 1, 0)
	Text.Position = UDim2.new(0, 5, 0, 0)
	Text.BackgroundTransparency = 1
	Text.Text = "🛡️ AUTO-DODGE V2 | 5 STUDS + ANTI FLYING PARTS"
	Text.TextColor3 = Color3.fromRGB(0, 200, 255)
	Text.Font = Enum.Font.GothamBold
	Text.TextSize = 13
	TweenService:Create(Frame, TweenInfo.new(0.3, Enum.EasingStyle.Back), {Position = UDim2.new(1, -330, 1, -10)}):Play()
	task.wait(3)
	TweenService:Create(Frame, TweenInfo.new(0.3), {Position = UDim2.new(1, 330, 1, -60)}):Play()
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
	-- Si estás muy alto o muy bajo = lobby. Ajusta estos valores a tu juego
	return pos.Y > 500 or pos.Y < -1000
end

local function TeleportToVoidAndCounter(attackerHRP)
	if isDodging then return end
	isDodging = true
	
	local char = lp.Character
	local HRP = char and char:FindFirstChild("HumanoidRootPart")
	if not HRP then isDodging = false return end
	
	local originalPos = HRP.CFrame
	lastFocusAttacker = attackerHRP
	HRP.CFrame = CFrame.new(0, -50000, 0)
	
	task.delay(VOID_TIME, function()
		if not lp.Character or not lp.Character:FindFirstChild("HumanoidRootPart") then 
			isDodging = false 
			return 
		end
		
		local newHRP = lp.Character.HumanoidRootPart
		if attackerHRP and attackerHRP.Parent then
			newHRP.CFrame = attackerHRP.CFrame + Vector3.new(0, 5, 0)
			newHRP.AssemblyLinearVelocity = Vector3.new(0, -5000, 0)
		else
			newHRP.CFrame = CFrame.new(FindSafeSpot(originalPos.Position))
		end
		isDodging = false
	end)
end

local function DodgeTouch(attackerChar)
	if isDodging then return end
	isDodging = true
	
	local char = lp.Character
	local HRP = char and char:FindFirstChild("HumanoidRootPart")
	local attackerHRP = attackerChar and attackerChar:FindFirstChild("HumanoidRootPart")
	if not HRP or not attackerHRP then isDodging = false return end
	
	local dir = (HRP.Position - attackerHRP.Position).Unit
	if dir.Magnitude == 0 then dir = Vector3.new(1, 0, 0) end
	
	local targetPos = HRP.Position + dir * DODGE_DISTANCE
	local safePos = FindSafeSpot(targetPos)
	
	HRP.CFrame = CFrame.new(safePos)
	task.wait(0.2)
	isDodging = false
end

local function SetupDodge(char)
	local Humanoid = char:WaitForChild("Humanoid")
	local HRP = char:WaitForChild("HumanoidRootPart")
	
	raycastParams.FilterDescendantsInstances = {char}
	
	-- 1. ANTI-TOQUE: 5 studs
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
	
	-- 2. ANTI-DESASTRE + ANTI PIEZAS VOLADORAS RÁPIDAS
	RunService.Heartbeat:Connect(function()
		if isDodging or not HRP or not HRP.Parent then return end
		
		-- Desastres cayendo
		for _, part in pairs(Workspace:GetPartBoundsInBox(HRP.CFrame + Vector3.new(0, 15, 0), Vector3.new(60, 30, 60))) do
			for _, keyword in pairs(DISASTER_KEYWORDS) do
				if part.Name:lower():find(keyword:lower()) or part.Parent.Name:lower():find(keyword:lower()) then
					if part.AssemblyLinearVelocity.Y < -20 then
						local safePos = FindSafeSpot(HRP.Position)
						HRP.CFrame = CFrame.new(safePos)
						return
					end
				end
			end
			
			-- NUEVO: Piezas voladoras del mapa a alta velocidad
			if not part.Anchored and not Players:GetPlayerFromCharacter(part.Parent) then
				if part.AssemblyLinearVelocity.Magnitude > FAST_PART_VELOCITY then
					local dist = (part.Position - HRP.Position).Magnitude
					if dist < 25 then -- si está a menos de 25 studs y viene rápido
						if IsInLobby(HRP.Position) then
							-- Estás en lobby -> ve al mapa
							HRP.CFrame = CFrame.new(FindSafeSpot(Vector3.new(0, 10, 0)))
						else
							-- Estás en mapa -> ve al lobby
							HRP.CFrame = CFrame.new(0, 1000, 0) -- ajusta esta altura a tu lobby
						end
						return
					end
				end
			end
		end
	end)
	
	-- 3. ANTI-FOCUS
	local lastHealth = Humanoid.Health
	local damageTime = 0
	local damageAmount = 0
	
	Humanoid.HealthChanged:Connect(function(newHealth)
		if newHealth < lastHealth then
			local dmg = lastHealth - newHealth
			if tick() - damageTime < 1 then
				damageAmount = damageAmount + dmg
				if damageAmount > 30 then
					local closest, closestDist = nil, 50
					for _, plr in pairs(Players:GetPlayers()) do
						if plr ~= lp and plr.Character:FindFirstChild("HumanoidRootPart") then
							local dist = (HRP.Position - plr.Character.HumanoidRootPart.Position).Magnitude
							if dist < closestDist then
								closest = plr.Character.HumanoidRootPart
								closestDist = dist
							end
						end
					end
					if closest then
						TeleportToVoidAndCounter(closest)
					end
					damageAmount = 0
				end
			else
				damageAmount = dmg
			end
			damageTime = tick()
		end
		lastHealth = newHealth
	end)
end

lp.CharacterAdded:Connect(SetupDodge)
if lp.Character then
	SetupDodge(lp.Character)
end
