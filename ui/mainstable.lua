--// Hydroxide UI - STABLE EDITION
--// File: ui/mainstable.lua
--// Purpose: identical UI, non-blocking load

local CoreGui = game:GetService("CoreGui")
local UserInput = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")

----------------------------------------------------------------
-- EARLY CACHE CHECK (CRITICAL FIX)
----------------------------------------------------------------
if oh.Cache["ui/main"] then
	return oh.Cache["ui/main"]
end

----------------------------------------------------------------
-- SAFE DEFERRED ASSET LOAD
----------------------------------------------------------------
local Interface
local loadError
local loaded = false

task.spawn(function()
	-- give Roblox breathing room
	RunService.Heartbeat:Wait()
	RunService.Heartbeat:Wait()

	local ok, result = pcall(function()
		return import("rbxassetid://11389137937")
	end)

	if ok and result then
		Interface = result
	else
		loadError = result
	end

	loaded = true
end)

-- wait with timeout (prevents hang)
local t0 = os.clock()
while not loaded do
	if os.clock() - t0 > 3 then
		error("UI load timeout (rbxassetid://11389137937)")
	end
	RunService.Heartbeat:Wait()
end

if loadError then
	error(loadError)
end

----------------------------------------------------------------
-- CACHE AFTER SAFE LOAD
----------------------------------------------------------------
oh.Cache["ui/main"] = Interface

----------------------------------------------------------------
-- CONTROLS / MODULES (UNCHANGED)
----------------------------------------------------------------
import("ui/controls/TabSelector")
local MessageBox, MessageType = import("ui/controls/MessageBox")

local RemoteSpy
local ClosureSpy
local ScriptScanner
local ModuleScanner
local UpvalueScanner
local ConstantScanner

xpcall(function()
	RemoteSpy = import("ui/modules/RemoteSpy")
	ClosureSpy = import("ui/modules/ClosureSpy")
	ScriptScanner = import("ui/modules/ScriptScanner")
	ModuleScanner = import("ui/modules/ModuleScanner")
	UpvalueScanner = import("ui/modules/UpvalueScanner")
	ConstantScanner = import("ui/modules/ConstantScanner")
end, function(err)
	local message
	if tostring(err):find("valid member") then
		message =
			"The UI has updated, please rejoin and restart.\n\n" .. err
	else
		message =
			"Report this error in Hydroxide's server:\n\n" .. err
	end

	MessageBox.Show(
		"An error has occurred",
		message,
		MessageType.OK,
		function()
			if Interface then
				Interface:Destroy()
			end
		end
	)
end)

----------------------------------------------------------------
-- UI CONSTANTS (UNCHANGED)
----------------------------------------------------------------
local constants = {
	opened   = UDim2.new(0.5, -325, 0.5, -175),
	closed   = UDim2.new(0.5, -325, 0, -400),
	reveal   = UDim2.new(0.5, -15, 0, 20),
	conceal  = UDim2.new(0.5, -15, 0, -75)
}

----------------------------------------------------------------
-- UI REFERENCES
----------------------------------------------------------------
local Open = Interface.Open
local Base = Interface.Base
local Drag = Base.Drag
local Status = Base.Status
local Collapse = Drag.Collapse

----------------------------------------------------------------
-- STATUS API (UNCHANGED)
----------------------------------------------------------------
function oh.setStatus(text)
	Status.Text = '• Status: ' .. text
end

function oh.getStatus()
	return Status.Text:gsub('• Status: ', '')
end

----------------------------------------------------------------
-- DRAG SYSTEM (SAFE, EVENT-BASED)
----------------------------------------------------------------
local dragging
local dragStart
local startPos

Drag.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		dragging = true
		dragStart = input.Position
		startPos = Base.Position

		local conn
		conn = input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				dragging = false
				conn:Disconnect()
			end
		end)
	end
end)

oh.Events.Drag = UserInput.InputChanged:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseMovement and dragging then
		local delta = input.Position - dragStart
		Base.Position = UDim2.new(
			startPos.X.Scale,
			startPos.X.Offset + delta.X,
			startPos.Y.Scale,
			startPos.Y.Offset + delta.Y
		)
	end
end)

----------------------------------------------------------------
-- BUTTON ACTIONS
----------------------------------------------------------------
Open.MouseButton1Click:Connect(function()
	Open:TweenPosition(constants.conceal, "Out", "Quad", 0.15)
	Base:TweenPosition(constants.opened, "Out", "Quad", 0.15)
end)

Collapse.MouseButton1Click:Connect(function()
	Base:TweenPosition(constants.closed, "Out", "Quad", 0.15)
	Open:TweenPosition(constants.reveal, "Out", "Quad", 0.15)
end)

----------------------------------------------------------------
-- FINAL PARENTING (UNCHANGED)
----------------------------------------------------------------
Interface.Name = HttpService:GenerateGUID(false)

if getHui then
	Interface.Parent = getHui()
else
	if syn then
		syn.protect_gui(Interface)
	end
	Interface.Parent = CoreGui
end

return Interface
