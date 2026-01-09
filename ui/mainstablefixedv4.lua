--// Hydroxide Stable UI - FIXED V4 (FINAL)
--// File: ui/mainstablefixedv4.lua
--// Goal: UI يظهر فعليًا + ZERO crash + ZERO WS + ZERO thumbnails

----------------------------------------------------------------
-- GLOBAL HARD KILLS
----------------------------------------------------------------
_G.HYDROXIDE_DISABLE_WS = true
_G.HYDROXIDE_NO_DEBUG_SERVER = true
_G.HYDROXIDE_DISABLE_THUMBNAILS = true
_G.HYDROXIDE_STANDALONE = true

----------------------------------------------------------------
-- SERVICES (SAFE)
----------------------------------------------------------------
local function S(name)
	local ok, svc = pcall(game.GetService, game, name)
	if ok then return svc end
end

local Players     = S("Players")
local CoreGui     = S("CoreGui")
local UserInput   = S("UserInputService")
local HttpService = S("HttpService")

if not Players or not CoreGui or not UserInput then
	warn("[Hydroxide UI V4] Critical services missing. Abort.")
	return
end

----------------------------------------------------------------
-- PLAYER READY GATE
----------------------------------------------------------------
local LocalPlayer = Players.LocalPlayer
if not LocalPlayer then
	Players:GetPropertyChangedSignal("LocalPlayer"):Wait()
	LocalPlayer = Players.LocalPlayer
end

if not LocalPlayer.Character then
	LocalPlayer.CharacterAdded:Wait()
end

----------------------------------------------------------------
-- LOAD UI ASSET (NO NETWORK)
----------------------------------------------------------------
local Interface
do
	local ok, result = pcall(function()
		return import("rbxassetid://11389137937")
	end)
	if not ok or not result then
		warn("[Hydroxide UI V4] Failed to load UI asset.")
		return
	end
	Interface = result
end

----------------------------------------------------------------
-- SCREEN GUI SAFETY FIX (CRITICAL)
----------------------------------------------------------------
if Interface:IsA("ScreenGui") then
	Interface.Enabled = true
	Interface.ResetOnSpawn = false
	Interface.IgnoreGuiInset = true
end

----------------------------------------------------------------
-- PREVENT DOUBLE LOAD
----------------------------------------------------------------
if _G.__HYDROXIDE_UI_V4_LOADED then
	warn("[Hydroxide UI V4] UI already loaded.")
	return
end
_G.__HYDROXIDE_UI_V4_LOADED = true

----------------------------------------------------------------
-- FIND CORE ELEMENTS
----------------------------------------------------------------
local Base    = Interface:FindFirstChild("Base", true)
local OpenBtn = Interface:FindFirstChild("Open", true)

if not Base or not OpenBtn then
	warn("[Hydroxide UI V4] UI structure invalid.")
	Interface:Destroy()
	return
end

----------------------------------------------------------------
-- FORCE OPEN BUTTON VISIBILITY (THE FIX)
----------------------------------------------------------------
OpenBtn.Visible = true
OpenBtn.ZIndex = 1000
OpenBtn.Parent = Interface -- تأكيد أنه خارج Base

----------------------------------------------------------------
-- POSITIONS
----------------------------------------------------------------
local OPEN_POS   = UDim2.new(0.5, -325, 0.5, -175)
local CLOSED_POS = UDim2.new(0.5, -325, 0, -400)

Base.Position = CLOSED_POS

----------------------------------------------------------------
-- DRAG SYSTEM (SAFE)
----------------------------------------------------------------
local dragging = false
local dragStart, startPos

local Drag = Base:FindFirstChild("Drag", true)
if Drag then
	Drag.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = true
			dragStart = input.Position
			startPos = Base.Position
		end
	end)

	UserInput.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = false
		end
	end)

	UserInput.InputChanged:Connect(function(input)
		if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
			local delta = input.Position - dragStart
			Base.Position = UDim2.new(
				startPos.X.Scale,
				startPos.X.Offset + delta.X,
				startPos.Y.Scale,
				startPos.Y.Offset + delta.Y
			)
		end
	end)
end

----------------------------------------------------------------
-- OPEN / CLOSE
----------------------------------------------------------------
OpenBtn.MouseButton1Click:Connect(function()
	Base:TweenPosition(OPEN_POS, "Out", "Quad", 0.15, true)
end)

----------------------------------------------------------------
-- AUTO OPEN FIRST TIME (VISUAL CONFIRM)
----------------------------------------------------------------
task.delay(0.2, function()
	Base.Position = OPEN_POS
end)

----------------------------------------------------------------
-- PARENTING (SECURE)
----------------------------------------------------------------
Interface.Name = "Hydroxide_UI_V4_" .. HttpService:GenerateGUID(false)

if getHui then
	Interface.Parent = getHui()
elseif syn and syn.protect_gui then
	syn.protect_gui(Interface)
	Interface.Parent = CoreGui
else
	Interface.Parent = CoreGui
end

----------------------------------------------------------------
-- FINAL LOG
----------------------------------------------------------------
warn("[Hydroxide UI V4] UI LOADED AND VISIBLE ✓")
return Interface
