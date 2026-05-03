local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local PhysicsService = game:GetService("PhysicsService")

local lp = Players.LocalPlayer
local PlayerGui = lp:WaitForChild("PlayerGui")

local hiddenfling = true
local flingPower = 55000 -- máximo del slider original

-- ESPERA A QUE EL OTRO SCRIPT MONTE SUS BLOQUEOS Y LUEGO LOS ROMPE
task.delay(11, function()
	-- 1. Mata los HeartbeatLoops que ponen Velocity = 0 a otros
	for _, v in pairs(getconnections(RunService.Heartbeat)) do
		local s = tostring(v.Function)
		if s:find("RotVelocity") or s:find("Velocity = Vector3.new(0,0,0)") or s:find("CanCollide = false") then
			pcall(function() v:Disable() end)
		end
	end
end)

if not ReplicatedStorage:FindFirstChild("juisdfj0i32i0eidsuf0iok") then
	local detection = Instance.new("Decal")
	detection.Name = "juisdfj0i32i0eidsuf0iok"
	detection.Parent = ReplicatedStorage
end

-- Mensajito de 3 segundos
task.spawn(function()
	local ScreenGui = Instance.new("ScreenGui")
	ScreenGui.Name = "FlingNotif"
	ScreenGui.ResetOnSpawn = false
	ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	ScreenGui.Parent = PlayerGui

	local Frame = Instance.new("Frame", ScreenGui)
	Frame.Size = UDim2.new(0, 280, 0, 50)
	Frame.Position = UDim2.new(1, 300, 1, -60)
	Frame.AnchorPoint = Vector2.new(0, 1)
	Frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
	Frame.BackgroundTransparency = 0.1
	Frame.BorderSizePixel = 0
	Instance.new("UICorner", Frame).CornerRadius = UDim.new(0, 8)

	local UIStroke = Instance.new("UIStroke", Frame)
	UIStroke.Color = Color3.fromRGB(255, 0, 0)
	UIStroke.Thickness = 2

	local Text = Instance.new("TextLabel", Frame)
	Text.Size = UDim2.new(1, -10, 1, 0)
	Text.Position = UDim2.new(0, 5, 0, 0)
	Text.BackgroundTransparency = 1
	Text.Text = "FLING ACTIVO | POWER: 55000 | ANTI-FLING BYPASS"
	Text.TextColor3 = Color3.fromRGB(255, 50, 50)
	Text.Font = Enum.Font.GothamBold
	Text.TextSize = 14
	Text.TextXAlignment = Enum.TextXAlignment.Left

	local TweenIn = TweenService:Create(Frame, TweenInfo.new(0.3, Enum.EasingStyle.Back), {
		Position = UDim2.new(1, -290, 1, -10)
	})
	TweenIn:Play()
	task.wait(3)
	local TweenOut = TweenService:Create(Frame, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
		Position = UDim2.new(1, 300, 1, -60)
	})
	TweenOut:Play()
	TweenOut.Completed:Wait()
	ScreenGui:Destroy()
end)

local function SetupFling(char)
	local Humanoid = char:WaitForChild("Humanoid")
	local HRP = char:WaitForChild("HumanoidRootPart")
	
	-- BYPASS DE LOS 4 BLOQUEOS DEL ANTI-FLING
	RunService.Heartbeat:Connect(function()
		if not HRP or not HRP.Parent then return end
		
		-- Bloqueo 1: Te ancla si alguien va rápido cerca
		if HRP.Anchored then
			HRP.Anchored = false
		end
		
		-- Bloqueo 2: CollisionGroupSetCollidable false entre players
		-- Forzamos a que choquen poniéndolos en Default
		for _, plr in pairs(Players:GetPlayers()) do
			if plr ~= lp and plr.Character then
				local theirHRP = plr.Character:FindFirstChild("HumanoidRootPart")
				if theirHRP then
					-- Bloqueo 3: CanCollide = false
					theirHRP.CanCollide = true
					-- Bloqueo 4: CollisionGroup = "AntiflingPlayers"
					pcall(function()
						theirHRP.CollisionGroup = "Default"
					end)
				end
			end
		end
	end)
	
	-- FLING LOOP ORIGINAL
	task.spawn(function()
		local hrp, c, vel, movel = nil, nil, nil, 0.1
		while true do
			RunService.Heartbeat:Wait()
			if hiddenfling then
				while hiddenfling and not (c and c.Parent and hrp and hrp.Parent) do
					RunService.Heartbeat:Wait()
					c = lp.Character
					hrp = c and c:FindFirstChild("HumanoidRootPart")
				end

				if hiddenfling then
					vel = hrp.Velocity
					hrp.Velocity = vel * flingPower + Vector3.new(0, flingPower, 0)
					RunService.RenderStepped:Wait()
					if c and c.Parent and hrp and hrp.Parent then
						hrp.Velocity = vel
					end
					RunService.Stepped:Wait()
					if c and c.Parent and hrp and hrp.Parent then
						hrp.Velocity = vel + Vector3.new(0, movel, 0)
						movel = movel * -1
					end
				end
			end
		end
	end)
end

lp.CharacterAdded:Connect(SetupFling)
if lp.Character then
	SetupFling(lp.Character)
end
