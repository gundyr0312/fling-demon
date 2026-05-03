local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local lp = Players.LocalPlayer
local PlayerGui = lp:WaitForChild("PlayerGui")
local flingPower = 55000

-- Mensajito
task.spawn(function()
	local ScreenGui = Instance.new("ScreenGui")
	ScreenGui.ResetOnSpawn = false
	ScreenGui.Parent = PlayerGui
	local Frame = Instance.new("Frame", ScreenGui)
	Frame.Size = UDim2.new(0, 320, 0, 50)
	Frame.Position = UDim2.new(1, 340, 1, -60)
	Frame.AnchorPoint = Vector2.new(0, 1)
	Frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
	Instance.new("UICorner", Frame).CornerRadius = UDim.new(0, 8)
	local Text = Instance.new("TextLabel", Frame)
	Text.Size = UDim2.new(1, -10, 1, 0)
	Text.Position = UDim2.new(0, 5, 0, 0)
	Text.BackgroundTransparency = 1
	Text.Text = "FLING V2 ACTIVO | POWER: 55000 | COLLISION BYPASS"
	Text.TextColor3 = Color3.fromRGB(255, 50, 50)
	Text.Font = Enum.Font.GothamBold
	Text.TextSize = 13
	TweenService:Create(Frame, TweenInfo.new(0.3, Enum.EasingStyle.Back), {Position = UDim2.new(1, -330, 1, -10)}):Play()
	task.wait(3)
	TweenService:Create(Frame, TweenInfo.new(0.3), {Position = UDim2.new(1, 340, 1, -60)}):Play()
	task.wait(0.3)
	ScreenGui:Destroy()
end)

local function SetupFlingV2(char)
	local HRP = char:WaitForChild("HumanoidRootPart")
	local Humanoid = char:WaitForChild("Humanoid")
	
	-- 1. MATA LOS LOOPS DEL ANTI-FLING DESPUÉS DE 11s
	task.delay(11, function()
		for _, v in pairs(getconnections(RunService.Heartbeat)) do
			local s = tostring(v.Function)
			if s:find("RotVelocity") or s:find("Velocity = Vector3.new(0,0,0)") or s:find("CanCollide = false") then
				pcall(function() v:Disable() end)
			end
		end
	end)
	
	-- 2. HITBOX INVISIBLE MASIVA SOLDADA A TI
	local FlingPart = Instance.new("Part")
	FlingPart.Name = "FlingHitbox"
	FlingPart.Size = Vector3.new(10, 10, 10)
	FlingPart.Transparency = 1
	FlingPart.CanCollide = true
	FlingPart.Massless = false
	FlingPart.CustomPhysicalProperties = PhysicalProperties.new(9e9, 0, 0) -- masa absurda
	FlingPart.CFrame = HRP.CFrame
	FlingPart.Parent = char
	
	local Weld = Instance.new("WeldConstraint")
	Weld.Part0 = HRP
	Weld.Part1 = FlingPart
	Weld.Parent = FlingPart
	
	-- 3. BODYVELOCITY HACIA ABAJO EN LA HITBOX, NO EN TU HRP
	local BV = Instance.new("BodyVelocity")
	BV.MaxForce = Vector3.new(0, 9e9, 0)
	BV.Velocity = Vector3.new(0, -flingPower, 0)
	BV.P = 1250
	BV.Parent = FlingPart
	
	local BAV = Instance.new("BodyAngularVelocity")
	BAV.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
	BAV.AngularVelocity = Vector3.new(0, 0, 0)
	BAV.Parent = FlingPart
	
	-- 4. ANULA EL ANCLADO Y COLLISION GROUPS CADA FRAME
	RunService.Heartbeat:Connect(function()
		if HRP and HRP.Parent then
			if HRP.Anchored then
				HRP.Anchored = false
			end
			
			-- Fuerza a todos los otros a chocar con tu hitbox
			for _, plr in pairs(Players:GetPlayers()) do
				if plr ~= lp and plr.Character then
					local theirHRP = plr.Character:FindFirstChild("HumanoidRootPart")
					if theirHRP then
						theirHRP.CanCollide = true
						pcall(function()
							theirHRP.CollisionGroup = "Default"
						end)
					end
				end
			end
		end
	end)
end

lp.CharacterAdded:Connect(SetupFlingV2)
if lp.Character then
	SetupFlingV2(lp.Character)
end
