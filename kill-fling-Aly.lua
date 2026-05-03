local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local lp = Players.LocalPlayer

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

local hitTracker = {}
local lastTouchPerPlayer = {}
local voidCooldown = {}

local raycastParams = RaycastParams.new()
raycastParams.FilterType = Enum.RaycastFilterType.Blacklist

-- =========================
-- 💀 VOID CONTROLADO
-- =========================
local function VoidPlayer(attackerHRP, attackerPlr)
	if not attackerHRP or not attackerHRP.Parent then return end
	if not attackerPlr then return end
	
	if tick() - (voidCooldown[attackerPlr] or 0) < 1 then return end
	voidCooldown[attackerPlr] = tick()

	attackerHRP.AssemblyLinearVelocity = Vector3.new(0, -500, 0)
	attackerHRP.CFrame = attackerHRP.CFrame - Vector3.new(0, 150, 0)
end

-- =========================
-- 🎯 CHECK FOCUS
-- =========================
local function CheckFocus(attackerHRP, attackerPlr)
	if not attackerPlr then return end
	
	hitTracker[attackerPlr] = hitTracker[attackerPlr] or {}
	table.insert(hitTracker[attackerPlr], tick())

	for i = #hitTracker[attackerPlr], 1, -1 do
		if tick() - hitTracker[attackerPlr][i] > 8 then
			table.remove(hitTracker[attackerPlr], i)
		end
	end

	if #hitTracker[attackerPlr] >= 5 then
		hitTracker[attackerPlr] = {}
		VoidPlayer(attackerHRP, attackerPlr)
	end
end

-- =========================
-- ⚡ DODGE
-- =========================
local function DodgeTouch(attackerChar)
	if tick() - lastTP < 0.05 then return end
	lastTP = tick()
	
	local char = lp.Character
	local HRP = char and char:FindFirstChild("HumanoidRootPart")
	local attackerHRP = attackerChar and attackerChar:FindFirstChild("HumanoidRootPart")
	local attackerPlr = attackerChar and Players:GetPlayerFromCharacter(attackerChar)
	if not HRP or not attackerHRP then return end
	
	-- 📈 Escalado
	local now = tick()
	if now - lastTouchTime < 3 then
		touchCount += 1
	else
		touchCount = 1
	end
	lastTouchTime = now
	
	local currentSeparation = math.min(BASE_SEPARATION * (2 ^ (touchCount - 1)), MAX_DODGE)

	-- 🧠 Predicción coherente
	local predictedPos = attackerHRP.Position + attackerHRP.AssemblyLinearVelocity * 0.1
	local dir = HRP.Position - predictedPos
	dir = dir.Magnitude > 0 and dir.Unit or Vector3.new(1,0,0)

	local exactPos = predictedPos + dir * currentSeparation

	-- 📡 Raycast largo
	local ray = Workspace:Raycast(
		exactPos + Vector3.new(0,20,0),
		Vector3.new(0,-100,0),
		raycastParams
	)

	if ray then
		HRP.CFrame = CFrame.new(ray.Position + Vector3.new(0, SAFE_HEIGHT, 0))
	else
		-- fallback cercano
		local fallback = HRP.Position + dir * 10
		HRP.CFrame = CFrame.new(fallback)
	end

	CheckFocus(attackerHRP, attackerPlr)
end

-- =========================
-- 🛡️ SETUP
-- =========================
local function SetupDodge(char)
	local HRP = char:WaitForChild("HumanoidRootPart")
	raycastParams.FilterDescendantsInstances = {char}

	-- 🔵 TOUCH DETECTION
	for _, part in pairs(char:GetDescendants()) do
		if part:IsA("BasePart") then
			part.Touched:Connect(function(hit)
				local attackerChar = hit:FindFirstAncestorOfClass("Model")
				local attackerPlr = attackerChar and Players:GetPlayerFromCharacter(attackerChar)

				if attackerPlr and attackerPlr ~= lp then
					if tick() - (lastTouchPerPlayer[attackerPlr] or 0) < 0.2 then return end
					lastTouchPerPlayer[attackerPlr] = tick()

					DodgeTouch(attackerChar)
				end
			end)
		end
	end

	-- 🧠 ÚNICO HEARTBEAT (optimizado)
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
			Vector3.new(60,30,60)
		)) do
			if not part.Anchored then
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
