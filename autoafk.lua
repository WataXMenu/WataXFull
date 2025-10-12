local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer

local AUTO_START = true
local AUTO_RESPAWN = true
local STOP_DELAY = 15
local RESPAWN_DELAY = 10
local POST_RESPAWN_DELAY = 5
local MOVE_THRESHOLD = 0.05
local RETRY_INTERVAL = 10
local COOLDOWN_AFTER_RESPAWN = 10 

local hrp, toggleBtn
local lastPos, stillTime, totalDist = nil, 0, 0
local lastAutoStart = 0
local justRestarted = false
local afterRespawn = false


local function clickButton(button)
	if not button then return end
	for _, c in ipairs(getconnections(button.MouseButton1Click)) do
		pcall(function() c.Function() end)
	end
end

local function getButtonText()
	if not toggleBtn then return "" end
	return toggleBtn.Text:lower()
end


local function getHRP()
	local char = player.Character or player.CharacterAdded:Wait()
	return char:WaitForChild("HumanoidRootPart", 10)
end

local function setStatus(text, color)
	if _G.WataXStatus then
		_G.WataXStatus(text, color)
	end
end

local function respawnChar()
	local char = player.Character
	if char and char:FindFirstChild("Humanoid") then
		print("[WataX AutoAFK] Respawning...")
		setStatus("🔴 Respawning...", Color3.fromRGB(255,100,100))
		char.Humanoid.Health = 0
	end
	player.CharacterAdded:Wait():WaitForChild("HumanoidRootPart")
	task.wait(POST_RESPAWN_DELAY)
	hrp = getHRP()
	print("[WataX AutoAFK] Respawn selesai, siap auto-start.")
	
	
	afterRespawn = true
	local text = getButtonText()
	if text:find("stop") then
		clickButton(toggleBtn)
		task.wait(1)
	end
	if getButtonText():find("start") then
		clickButton(toggleBtn)
		setStatus("🟢 Auto Start after Respawn", Color3.fromRGB(100,255,100))
	end

	
	task.spawn(function()
		task.wait(COOLDOWN_AFTER_RESPAWN)
		afterRespawn = false
	end)
end


local function waitForToggleButton()
	local ui
	repeat
		task.wait(1)
		for _, g in pairs(game:GetDescendants()) do
			if g:IsA("TextButton") and (g.Text:find("Start") or g.Text:find("Stop")) then
				if g.Parent and (g.Parent.Name == "WataXReplayUI" or (g.Parent.Parent and g.Parent.Parent.Name == "WataXReplayUI")) then
					ui = g
					break
				end
			end
		end
	until ui
	print("[WataX AutoAFK] Tombol replay ditemukan:", ui.Text)
	return ui
end


local screenGui = Instance.new("ScreenGui")
screenGui.Name = "WataX_AutoUI"
screenGui.Parent = game.CoreGui

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 240, 0, 65)
frame.Position = UDim2.new(1, -260, 1, -110)
frame.BackgroundColor3 = Color3.fromRGB(30, 20, 50)
frame.BackgroundTransparency = 0.25
frame.BorderSizePixel = 0
frame.Active = true
frame.Draggable = true
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 14)
frame.Parent = screenGui

local glow = Instance.new("UIStroke", frame)
glow.Color = Color3.fromRGB(180, 120, 255)
glow.Thickness = 2
glow.Transparency = 0.4

local title = Instance.new("TextLabel", frame)
title.Size = UDim2.new(1, 0, 0.45, 0)
title.BackgroundTransparency = 1
title.Text = "⚙️ AutoAFK Status"
title.Font = Enum.Font.GothamBold
title.TextColor3 = Color3.fromRGB(180, 180, 255)
title.TextScaled = true

local statusLabel = Instance.new("TextLabel", frame)
statusLabel.Size = UDim2.new(1, 0, 0.55, 0)
statusLabel.Position = UDim2.new(0, 0, 0.45, 0)
statusLabel.BackgroundTransparency = 1
statusLabel.Font = Enum.Font.GothamBold
statusLabel.TextScaled = true
statusLabel.Text = "🟡 Idle..."
statusLabel.TextColor3 = Color3.fromRGB(255, 255, 100)

local hue = 0
RunService.RenderStepped:Connect(function()
	hue = (hue + 0.4) % 360
	glow.Color = Color3.fromHSV(hue / 360, 0.8, 1)
end)

_G.WataXStatus = function(text, color)
	statusLabel.Text = text
	statusLabel.TextColor3 = color
end


hrp = getHRP()
toggleBtn = waitForToggleButton()
lastPos = hrp.Position

task.spawn(function()
	while task.wait(1) do
		if not hrp or not hrp.Parent then
			hrp = getHRP()
			lastPos = hrp.Position
			stillTime, totalDist = 0, 0
			continue
		end

		local dist = (hrp.Position - lastPos).Magnitude
		totalDist += dist
		lastPos = hrp.Position

		if dist < MOVE_THRESHOLD then
			stillTime += 1
		else
			stillTime, totalDist = 0, 0
			justRestarted = false
		end

		if afterRespawn then
			stillTime = 0
			continue
		end

		if stillTime == 0 then
			setStatus("🟢 Running", Color3.fromRGB(100,255,100))
		elseif stillTime < RESPAWN_DELAY then
			setStatus("🟡 Idle "..stillTime.."s", Color3.fromRGB(255,255,150))
		end

		if AUTO_RESPAWN and stillTime >= RESPAWN_DELAY then
			print("[WataX AutoAFK] Auto respawn triggered.")
			respawnChar()
			stillTime, totalDist = 0, 0
			justRestarted = false
			continue
		end

		local now = tick()
		if AUTO_START and stillTime >= STOP_DELAY and totalDist < 0.5 and (now - lastAutoStart > RETRY_INTERVAL) then
			if not justRestarted then
				local text = getButtonText()
				setStatus("🔵 Restarting Route...", Color3.fromRGB(100,150,255))

				if text:find("stop") then
					clickButton(toggleBtn)
					task.wait(1)
				end
				if getButtonText():find("start") then
					clickButton(toggleBtn)
					lastAutoStart = now
					justRestarted = true
					setStatus("🟢 Running", Color3.fromRGB(100,255,100))
				end
			end
			stillTime, totalDist = 0, 0
		end
	end
end)
