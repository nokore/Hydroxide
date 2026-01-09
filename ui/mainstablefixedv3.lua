--// Hydroxide Stable UI - FIXED V3 (ULTRA++ PRO MAX FINAL)
--// File: ui/mainstablefixedv3.lua
--// Author: You + ChatGPT
--// Goal: ZERO crash, ZERO thumbnail abuse, ZERO websocket leaks

----------------------------------------------------------------
-- HARD KILL SWITCHES (ABSOLUTE)
----------------------------------------------------------------
_G.HYDROXIDE_DISABLE_WS = true
_G.HYDROXIDE_NO_DEBUG_SERVER = true
_G.HYDROXIDE_STANDALONE = true
_G.HYDROXIDE_DISABLE_THUMBNAILS = true

----------------------------------------------------------------
-- SERVICES (SAFE ACQUIRE)
----------------------------------------------------------------
local Services = {}
local function S(name)
	local ok, svc = pcall(game.GetService, game, name)
	if ok then
		Services[name] = svc
		return svc
	end
	return nil
end

local Players        = S("Players")
local CoreGui        = S("CoreGui")
local UserInput      = S("UserInputService")
local HttpService    = S("HttpService")
local RunService     = S("RunService")

----------------------------------------------------------------
-- STRICT ENV VALIDATION
----------------------------------------------------------------
if not Players or not CoreGui or not UserInput then
	warn("[Hydroxide UI V3] Critical services missing. UI aborted.")
	return
end

----------------------------------------------------------------
-- PLAYER GATE (NO UI BEFORE READY)
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
-- SAFE THUMBNAIL (NEVER USE rbxthumb DIRECTLY)
----------------------------------------------------------------
local PLACEHOLDER = "rbxasset://textures/ui/GuiImagePlaceholder.png"

local function SafeAvatar(userId)
	if _G.HYDROXIDE_DISABLE_THUMBNAILS then
		return PLACEHOLDER
	end
	if type(userId) ~= "number" or userId <= 0 then
		return PLACEHOLDER
	end
	return PLACEHOLDER -- forced sandbox
end

----------------------------------------------------------------
-- UI IMPORT (ASSET ONLY, NO NETWORK)
----------------------------------------------------------------
local Interface
do
	local ok, result = pcall(function()
		return import("rbxassetid://11389137937")
	end)
	if not ok or not result then
		warn("[Hydroxide UI V3] Failed to load UI asset.")
		return
	end
	Interface = result
end

----------------------------------------------------------------
-- CACHE GUARD (PREVENT DOUBLE LOAD)
----------------------------------------------------------------
if _G.__HYDROXIDE_UI_V3_LOADED then
	warn("[Hydroxide UI V3] UI already loaded. Skipping.")
	return
end
_G.__HYDROXIDE_UI_V3_LOADED = true

----------------------------------------------------------------
-- BASIC UI WIRES (NO MODULE SCANNERS)
----------------------------------------------------------------
local Base     = Interface:FindFirstChild("Base", true)
local OpenBtn  = Interface:FindFirstChild("Open", true)

if not Base or not OpenBtn then
	warn("[Hydroxide UI V3] UI structure invalid. Abort.")
	Interface:Destroy()
	return
end

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
-- OPEN / CLOSE (SAFE TWEEN)
----------------------------------------------------------------
local OPEN_POS   = UDim2.new(0.5, -325, 0.5, -175)
local CLOSED_POS = UDim2.new(0.5, -325, 0, -400)

Base.Position = CLOSED_POS

OpenBtn.MouseButton1Click:Connect(function()
	Base:TweenPosition(OPEN_POS, "Out", "Quad", 0.15, true)
end)

----------------------------------------------------------------
-- PARENTING (SECURE)
----------------------------------------------------------------
Interface.Name = "Hydroxide_UI_V3_" .. HttpService:GenerateGUID(false)

if getHui then
	Interface.Parent = getHui()
elseif syn and syn.protect_gui then
	syn.protect_gui(Interface)
	Interface.Parent = CoreGui
else
	Interface.Parent = CoreGui
end

----------------------------------------------------------------
-- FINAL STATUS
----------------------------------------------------------------
warn("[Hydroxide UI V3] UI loaded safely. No thumbnails. No WS. No crash.")
return Interface
