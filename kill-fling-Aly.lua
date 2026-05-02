local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local PhysicsService = game:GetService("PhysicsService")

local Player = Players.LocalPlayer
local Config = {g=false,wf=false,nc=false,ab=false,av=false}

-- 🔥 Anti-vacío básico
workspace.FallenPartsDestroyHeight = -50000

-- 🔥 CollisionGroups: tú no chocas con otros players para que el fling pegue mejor
pcall(function()
	PhysicsService:RegisterCollisionGroup("WalkFlingMe")
	PhysicsService:RegisterCollisionGroup("WalkFlingOthers")
	PhysicsService:CollisionGroupSetCollidable("WalkFlingMe", "WalkFlingOthers", false)
	PhysicsService:CollisionGroupSetCollidable("WalkFlingMe", "Default", true)
end)

if Player.PlayerGui:FindFirstChild("OmniFling") then
	Player.PlayerGui.OmniFling:Destroy()
end

local Gui = Instance.new("ScreenGui", Player.PlayerGui)
Gui.Name = "OmniFling"
Gui.ResetOnSpawn = false

local ToggleBtn = Instance.new("TextButton", Gui)
ToggleBtn.Size = UDim2.new(0,50,0,50)
ToggleBtn.Position = UDim2.new(0.02,0,0.15,0)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(200,0,0)
ToggleBtn.Text = "FLING"
ToggleBtn.TextColor3 = Color3.new(1,1,1)
ToggleBtn.Font = Enum.Font.GothamBold
Instance.new("UICorner", ToggleBtn).CornerRadius = UDim.new(1,0)

local Frame = Instance.new("Frame", Gui)
Frame.Size = UDim2.new(0,200,0,270)
Frame.Position = UDim2.new(0.5,-100,0.4,-135)
Frame.BackgroundColor3 = Color3.fromRGB(15,15,15)
Frame.Visible = true
Instance.new("UICorner", Frame)

ToggleBtn.MouseButton1Click:Connect(function()
	Frame.Visible = not Frame.Visible
end)

local function CreateToggle(Name, PosY, Key)
	local Btn = Instance.new("TextButton", Frame)
	Btn.Size = UDim2.new(0.9,0,0,35)
	Btn.Position = UDim2.new(0.05,0,0,PosY)
	Btn.BackgroundColor3 = Color3.fromRGB(30,30,30)
	Btn.TextColor3 = Color3.new(1,0,0)
	Btn.Text = Name..": OFF"
	Btn.Font = Enum.Font.Gotham
	Btn.TextSize = 14
	Instance.new("UICorner", Btn)
	
	Btn.MouseButton1Click:Connect(function()
		Config[Key] = not Config[Key]
		Btn.Text = Name..": "..(Config[Key] and "ON" or "OFF")
		Btn.TextColor3 = Config[Key] and Color3.new(0,1,0.5) or Color3.new(1,0,0)
	end)
end

CreateToggle("IMMORTAL",15,"g")
CreateToggle("WALK FLING",55,"wf")
CreateToggle("NO-COLLIDE",95,"nc")
CreateToggle("ANTI-BANG",135,"ab")
CreateToggle("ANTI-VOID",175,"av")

local WalkFlingConn = nil
local OldCollision = {}

local function EnableWalkFling(HRP)
	if WalkFlingConn then WalkFlingConn:Disconnect() end
	WalkFlingConn = RunService.Heartbeat:Connect(function()
		if not Config.wf or not HRP or not HRP.Parent then return end
		-- El truco del walkfling: rotación loca + velocidad angular
		local Vel = HRP.AssemblyLinearVelocity
		HRP.AssemblyAngularVelocity = Vector3.new(0, 10000, 0)
		HRP.AssemblyLinearVelocity = Vel + Vector3.new(0, 2, 0) -- pequeño boost vertical
	end)
end

local function SetCollisionGroup(char)
	for _, part in pairs(char:GetDescendants()) do
		if part:IsA("BasePart") then
			pcall(function()
				part.CollisionGroup = "WalkFlingMe"
				if Config.nc then
					OldCollision[part] = part.CanCollide
					part.CanCollide = false
				end
			end)
		end
	end
end

Player.CharacterAdded:Connect(function(char)
	task.wait(0.5)
	local Humanoid = char:WaitForChild("Humanoid")
	local HRP = char:WaitForChild("HumanoidRootPart")
	
	SetCollisionGroup(char)
	
	-- Anti-vacío: te baja y sube al respawnear para resetear física
	if Config.av then
		task.spawn(function()
			repeat task.wait() until Humanoid.Health > 0
			task.wait(0.5)
			local original = HRP.CFrame
			for i = 1, 15 do
				if not HRP.Parent then return end
				HRP.CFrame = original - Vector3.new(0, 400, 0)
				task.wait()
			end
			HRP.CFrame = original + Vector3.new(0, 5, 0)
		end)
	end
	
	if Config.wf then
		EnableWalkFling(HRP)
	end
end)

if Player.Character then
	SetCollisionGroup(Player.Character)
	local HRP = Player.Character:FindFirstChild("HumanoidRootPart")
	if HRP and Config.wf then
		EnableWalkFling(HRP)
	end
end

-- Loop principal: inmortalidad + efectos que NO joden el fling
RunService.Heartbeat:Connect(function()
	if not Player.Character then return end
	local Humanoid = Player.Character:FindFirstChildOfClass("Humanoid")
	local HRP = Player.Character:FindFirstChild("HumanoidRootPart")
	
	if Humanoid then
		if Config.g then
			-- Inmortalidad compatible con fling
			Humanoid.Health = Humanoid.MaxHealth
			Humanoid:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
			Humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
			Humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
		end
		
		-- Anti-sit/bang básico sin resetear velocidad
		Humanoid.Sit = false
		Humanoid.PlatformStand = false
		if Humanoid:GetState() == Enum.HumanoidStateType.PlatformStanding then
			Humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
		end
	end
	
	-- No-Collide toggle
	if HRP then
		for _, part in pairs(Player.Character:GetDescendants()) do
			if part:IsA("BasePart") then
				if Config.nc then
					part.CanCollide = false
				elseif OldCollision[part] ~= nil then
					part.CanCollide = OldCollision[part]
				end
			end
		end
	end
	
	-- Anti-Bang: destruye welds de otros players
	if Config.ab then
		for _,v in pairs(Player.Character:GetDescendants()) do
			if v:IsA("JointInstance") or v:IsA("WeldConstraint") then
				local p0, p1 = v.Part0, v.Part1
				if (p0 and not p0:IsDescendantOf(Player.Character)) or (p1 and not p1:IsDescendantOf(Player.Character)) then
					v:Destroy()
				end
			end
		end
	end
end)

Frame.Active = true
Frame.Draggable = true
