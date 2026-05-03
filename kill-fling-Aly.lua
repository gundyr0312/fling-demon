local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")

local lp = Players.LocalPlayer
local PlayerGui = lp:WaitForChild("PlayerGui")

-- CONFIG
local BASE_SEPARATION = 5
local MAX_DODGE = 100
local SAFE_HEIGHT = 3
local FAST_PART_VELOCITY = 80
local VOID_TIME = 3
local DISASTER_KEYWORDS = {"Lava", "Meteor", "Lightning", "Acid", "Spike", "Fire", "Rock", "Boulder"}

-- ESTADO
local lastTP = 0
local lastDangerCheck = 0
local lastPredictionCheck = 0
local lastDisasterDodge = 0 -- NUEVO: cooldown anti-spam desastres
local lastTouchTime = 0
local touchCount = 0
local currentAttacker = nil

local hitTracker = {}
local lastTouchPerPlayer = {}
local voidCooldown = {}

local raycastParams = RaycastParams.new()
raycastParams.FilterType = Enum.RaycastFilterType.Blacklist

-- NOTIFICACIÓN AZUL
local function NotifyActivation()
	task.spawn(function()
		local ScreenGui = Instance.new("ScreenGui")
		ScreenGui.Name = "DodgeNotifier"
		ScreenGui.ResetOnSpawn = false
		ScreenGui.Parent = PlayerGui
		
		local Frame = Instance.new("Frame", ScreenGui)
		Frame.Size = UDim2.new(0, 450, 0, 55)
		Frame.Position = UDim2.new(1, 460, 1, -65)
		Frame.AnchorPoint = Vector2.new(0, 1)
		Frame.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
		Instance.new("UICorner", Frame).CornerRadius = UDim.new(0, 10)
		
		local Stroke = Instance.new("UIStroke", Frame)
		Stroke.Color = Color3.fromRGB(0, 150, 255)
		Stroke.Thickness = 2
		
		local Text = Instance.new("TextLabel", Frame)
		Text.Size = UDim2.new(1, -20, 1, 0)
		Text.Position = UDim2.new(0, 10, 0, 0)
		Text.BackgroundTransparency = 1
		Text.Text = "🛡️ AUTO-DODGE V11 | FIX INFINITE TP"
		Text.TextColor3 = Color3.fromRGB(0, 200, 255)
		Text.Font = Enum.Font.GothamBold
		Text.TextSize = 14
		Text.TextXAlignment = Enum.TextXAlignment.Left
		
		TweenService:Create(Frame, TweenInfo.new(0.4, Enum.EasingStyle.Back), {Position = UDim2.new(1, -460, 1, -10)}):Play()
		task.wait(3.5)
		TweenService:Create(Frame, TweenInfo.new(0.3), {Position = UDim2.new(1, 460, 1, -65)}):Play()
		task.wait(0.3)
		ScreenGui:Destroy()
	end)
end

-- VERIFICA SI YA ESTÁS SEGURO
local function IsSafeSpot(pos, disasterPos)
	if (pos - disasterPos).Magnitude > 25 then return true end -- ya estás lejos
	return false
end

-- FUNCIÓN SEGURA PARA MOVER
local function SafeTeleport(HRP, targetPos)
	-- FIX: No teletransportar si ya estás en el aire sin suelo
	local groundCheck = Workspace:Raycast(HRP.Position, Vector3.new(0,-10,0), raycastParams)
	if not groundCheck then return false end -- no te muevas si ya estás flotando
	
	local ray = Workspace:Raycast(
		targetPos + Vector3.new(0,50,0),
		Vector3.new(0,-200,0),
		raycastParams
	)
	if ray and ray.Instance and ray.Instance.CanCollide then
		HRP.CFrame = CFrame.new(ray.Position + Vector3.new(0, SAFE_HEIGHT, 0))
		return true
	end
	return false
end

-- VOID CON REGRESO
local function VoidPlayer(attackerHRP, attackerPlr)
	if not attackerHRP or not attackerHRP.Parent then return end
	if not attackerPlr then return end
	
	if tick() - (voidCooldown[attackerPlr] or 0) < 2 then return end
	voidCooldown[attackerPlr] = tick()

	local originalCF = attackerHRP.CFrame
	attackerHRP.AssemblyLinearVelocity = Vector3.new(0, -500, 0)
	attackerHRP.CFrame = attackerHRP.CFrame - Vector3.new(0, 150, 0)
	
	task.delay(VOID_TIME, function()
		if attackerHRP and attackerHRP.Parent then
			attackerHRP.CFrame = originalCF + Vector3.new(0, 5, 0)
			attackerHRP.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
		end
	end)
end

-- CHECK FOCUS: 5 TOQUES EN 10S
local function CheckFocus(attackerHRP, attackerPlr)
	if not attackerPlr then return end
	
	hitTracker[attackerPlr] = hitTracker[attackerPlr] or {}
	table.insert(hitTracker[attackerPlr], tick())

	for i = #hitTracker[attackerPlr], 1, -1 do
		if tick() - hitTracker[attackerPlr][i] > 10 then
			table.remove(hitTracker[attackerPlr], i)
		end
	end

	if #hitTracker[attackerPlr] >= 5 then
		hitTracker[attackerPlr] = {}
		VoidPlayer(attackerHRP, attackerPlr)
	end
end

-- DODGE SOLO POR CONTACTO
local function DodgeTouch(attackerChar)
	if tick() - lastTP < 0.05 then return end
	lastTP = tick()
	
	local char = lp.Character
	local HRP = char and char:FindFirstChild("HumanoidRootPart")
	local attackerHRP = attackerChar and attackerChar:FindFirstChild("HumanoidRootPart")
	local attackerPlr = attackerChar and Players:GetPlayerFromCharacter(attackerChar)
	if not HRP or not attackerHRP then return end
	
	local now = tick()
	
	if now - lastTouchTime < 3 and attackerPlr == currentAttacker then
		touchCount += 1
	else
		touchCount = 1
		currentAttacker = attackerPlr
	end
	lastTouchTime = now
	
	local currentSeparation = math.min(BASE_SEPARATION * (2 ^ (touchCount - 1)), MAX_DODGE)

	local predictedPos = attackerHRP.Position + attackerHRP.AssemblyLinearVelocity * 0.1
	local dir = HRP.Position - predictedPos
	dir = dir.Magnitude > 0 and dir.Unit or Vector3.new(1,0,0)

	local exactPos = predictedPos + dir * currentSeparation

	if not SafeTeleport(HRP, exactPos) then
		local fallback = HRP.Position + dir * 15
		if not SafeTeleport(HRP, fallback) then
			-- FIX: Solo sube 20 si hay suelo abajo, sino no hagas nada
			local groundCheck = Workspace:Raycast(HRP.Position, Vector3.new(0,-10,0), raycastParams)
			if groundCheck then
				HRP.CFrame = CFrame.new(HRP.Position + Vector3.new(0, 20, 0))
			end
		end
	end

	CheckFocus(attackerHRP, attackerPlr)
end

-- SETUP
local function SetupDodge(char)
	local HRP = char:WaitForChild("HumanoidRootPart")
	raycastParams.FilterDescendantsInstances = {char}
	
	NotifyActivation()

	for _, part in pairs(char:GetDescendants()) do
		if part:IsA("BasePart") then
			part.Touched:Connect(function(hit)
				local attackerChar = hit:FindFirstAncestorOfClass("Model")
				local attackerPlr = attackerChar and Players:GetPlayerFromCharacter(attackerChar)

				if attackerPlr and attackerPlr ~= lp then
					if tick() - (lastTouchPerPlayer[attackerPlr] or 0) < 0.15 then return end
					lastTouchPerPlayer[attackerPlr] = tick()
					DodgeTouch(attackerChar)
				end
			end)
		end
	end

	-- ÚNICO HEARTBEAT
	RunService.Heartbeat:Connect(function()
		if not HRP.Parent then return end

		-- PREDICCIÓN DE DESASTRES CON COOLDOWN ANTI-SPAM
		if tick() - lastPredictionCheck >= 0.3 then -- 0.3s en vez de 0.2
			lastPredictionCheck = tick()
			
			for _, part in pairs(Workspace:GetChildren()) do
				if part:IsA("BasePart") and not part.Anchored then
					local isDisaster = false
					for _, keyword in pairs(DISASTER_KEYWORDS) do
						if part.Name:lower():find(keyword:lower()) then
							isDisaster = true
							break
						end
					end
					
					if isDisaster and part.AssemblyLinearVelocity.Y < -30 then
						local gravity = 196.2
						local timeToImpact = 1.2 -- reduje a 1.2s para menos falsos positivos
						local futurePos = part.Position + part.AssemblyLinearVelocity * timeToImpact + Vector3.new(0, -0.5 * gravity * timeToImpact^2, 0)
						
						-- FIX: Solo esquiva si va a caer cerca Y no has esquivado en 0.8s
						if (futurePos - HRP.Position).Magnitude < 20 and tick() - lastDisasterDodge > 0.8 then
							-- FIX: Verifica que no estés ya seguro
							if not IsSafeSpot(HRP.Position, futurePos) then
								lastDisasterDodge = tick() -- marca cooldown
								
								local escapeDir = (HRP.Position - futurePos).Unit
								if escapeDir.Magnitude == 0 then escapeDir = Vector3.new(1,0,0) end
								local escapePos = HRP.Position + escapeDir * 35 -- 35 en vez de 40
								
								if SafeTeleport(HRP, escapePos) then
									return
								end
							end
						end
					end
				end
			end
		end

		-- ANTI-PARTES RÁPIDAS
		if tick() - lastDangerCheck < 0.1 then return end
		lastDangerCheck = tick()

		for _, part in pairs(Workspace:GetPartBoundsInBox(HRP.CFrame, Vector3.new(50,25,50))) do
			if not part.Anchored and not Players:GetPlayerFromCharacter(part.Parent) then
				if part.AssemblyLinearVelocity.Magnitude > FAST_PART_VELOCITY then
					local dist = (part.Position - HRP.Position).Magnitude
					if dist < 25 and tick() - lastDisasterDodge > 0.8 then -- mismo cooldown
						lastDisasterDodge = tick()
						-- FIX: Solo sube si hay suelo
						local groundCheck = Workspace:Raycast(HRP.Position, Vector3.new(0,-10,0), raycastParams)
						if groundCheck then
							HRP.CFrame = HRP.CFrame + Vector3.new(0, 40, 0) -- 40 en vez de 50
						end
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

NotifyActivation()
