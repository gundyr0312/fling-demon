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

-- ESTADO
local lastTP = 0
local lastDangerCheck = 0
local lastTouchTime = 0
local touchCount = 0
local currentAttacker = nil -- NUEVO: trackea quién te está spameando

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
	Frame.Size = UDim2.new(0, 420, 0, 55)
	Frame.Position = UDim2.new(1, 430, 1, -65)
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
		Text.Text = "🛡️ AUTO-DODGE V8 | FIXED"
		Text.TextColor3 = Color3.fromRGB(0, 200, 255)
		Text.Font = Enum.Font.GothamBold
		Text.TextSize = 14
		Text.TextXAlignment = Enum.TextXAlignment.Left
		
		TweenService:Create(Frame, TweenInfo.new(0.4, Enum.EasingStyle.Back), {Position = UDim2.new(1, -430, 1, -10)}):Play()
		task.wait(3.5)
		TweenService:Create(Frame, TweenInfo.new(0.3), {Position = UDim2.new(1, 430, 1, -65)}):Play()
		task.wait(0.3)
	ScreenGui:Destroy()
	end)
end

-- VOID CONTROLADO
local function VoidPlayer(attackerHRP, attackerPlr)
	if not attackerHRP or not attackerHRP.Parent then return end
	if not attackerPlr then return end
	
	if tick() - (voidCooldown[attackerPlr] or 0) < 1 then return end
	voidCooldown[attackerPlr] = tick()

	attackerHRP.AssemblyLinearVelocity = Vector3.new(0, -500, 0)
	attackerHRP.CFrame = attackerHRP.CFrame - Vector3.new(0, 150, 0)
end

-- CHECK FOCUS FIXEADO
local function CheckFocus(attackerHRP, attackerPlr)
	if not attackerPlr then return end
	
	hitTracker[attackerPlr] = hitTracker[attackerPlr] or {}
	table.insert(hitTracker[attackerPlr], tick())

	-- Limpia hits viejos >8s
	for i = #hitTracker[attackerPlr], 1, -1 do
		if tick() - hitTracker[attackerPlr][i] > 8 then
			table.remove(hitTracker[attackerPlr], i)
		end
	end

	-- 5 toques = void
	if #hitTracker[attackerPlr] >= 5 then
	hitTracker[attackerPlr] = {}
		VoidPlayer(attackerHRP, attackerPlr)
	end
end

-- DODGE FIXEADO
local function DodgeTouch(attackerChar)
	if tick() - lastTP < 0.05 then return end
	lastTP = tick()
	
	local char = lp.Character
	local HRP = char and char:FindFirstChild("HumanoidRootPart")
	local attackerHRP = attackerChar and attackerChar:FindFirstChild("HumanoidRootPart")
	local attackerPlr = attackerChar and Players:GetPlayerFromCharacter(attackerChar)
	if not HRP or not attackerHRP then return end
	
	local now = tick()
	
	-- FIX 2: Si es el mismo atacante, escala. Si es otro, resetea
	if now - lastTouchTime < 3 and attackerPlr == currentAttacker then
		touchCount += 1
	else
		touchCount = 1
		currentAttacker = attackerPlr
	end
	lastTouchTime = now
	
	local currentSeparation = math.min(BASE_SEPARATION * (2 ^ (touchCount - 1)), MAX_DODGE)

	-- Predicción coherente
	local predictedPos = attackerHRP.Position + attackerHRP.AssemblyLinearVelocity * 0.1
	local dir = HRP.Position - predictedPos
	dir = dir.Magnitude > 0 and dir.Unit or Vector3.new(1,0,0)

	local exactPos = predictedPos + dir * currentSeparation

	-- FIX 1: Raycast con validación real de suelo
	local ray = Workspace:Raycast(
		exactPos + Vector3.new(0,30,0), -- 30 studs arriba para más margen
		Vector3.new(0,-150,0), -- 150 studs abajo para no perder suelo
	raycastParams
	)

	if ray and ray.Instance and ray.Instance.CanCollide then
	HRP.CFrame = CFrame.new(ray.Position + Vector3.new(0, SAFE_HEIGHT, 0))
	else
	-- FIX 1: Fallback seguro, no al vacío
		local fallback = HRP.Position + dir * 15 -- 15 studs hacia atrás, nunca al vacío
		local fallbackRay = Workspace:Raycast(fallback + Vector3.new(0,30,0), Vector3.new(0,-150,0), raycastParams)
		if fallbackRay and fallbackRay.Instance and fallbackRay.Instance.CanCollide then
			HRP.CFrame = CFrame.new(fallbackRay.Position + Vector3.new(0, SAFE_HEIGHT, 0))
		else
			-- Último recurso: 20 studs arriba
			HRP.CFrame = CFrame.new(HRP.Position + Vector3.new(0, 20, 0))
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
					if tick() - (lastTouchPerPlayer[attackerPlr] or 0) < 0.15 then return end -- 0.15s en vez de 0.2
					lastTouchPerPlayer[attackerPlr] = tick()

					DodgeTouch(attackerChar)
				end
			end)
		end
	end

	RunService.Heartbeat:Connect(function()
		if not HRP.Parent then return end

	-- PRE-DODGE
		for _, plr in pairs(Players:GetPlayers()) do
			if plr ~= lp and plr.Character then
				local oHRP = plr.Character:FindFirstChild("HumanoidRootPart")
				if oHRP then
					if (oHRP.Position - HRP.Position).Magnitude < 6 then
						DodgeTouch(plr.Character)
						return
					end
				end
			end
		end

	-- ANTI-PARTES
		if tick() - lastDangerCheck < 0.1 then return end
		lastDangerCheck = tick()

		for _, part in pairs(Workspace:GetPartBoundsInBox(
			HRP.CFrame,
			Vector3.new(50,25,50)
	)) do
			if not part.Anchored and not Players:GetPlayerFromCharacter(part.Parent) then
				if part.AssemblyLinearVelocity.Magnitude > FAST_PART_VELOCITY then
					local dist = (part.Position - HRP.Position).Magnitude
					if dist < 25 then
						HRP.CFrame = HRP.CFrame + Vector3.new(0, 50, 0)
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
