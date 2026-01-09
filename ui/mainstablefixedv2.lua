--// Hydroxide UI - STABLE FIXED v2 (FINAL)
--// File: ui/mainstablefixedv2.lua
--// Purpose: FINAL stability patch (thumbnails, memory, FD safe)

----------------------------------------------------------------
-- SERVICES
----------------------------------------------------------------
local CoreGui = game:GetService("CoreGui")
local UserInput = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

----------------------------------------------------------------
-- GLOBAL LOCK (prevent double execution)
----------------------------------------------------------------
if _G.__HYDROXIDE_UI_LOCK__ then
	return
end
_G.__HYDROXIDE_UI_LOCK__ = true

----------------------------------------------------------------
-- EARLY CACHE CHECK
----------------------------------------------------------------
if oh.Cache["ui/main"] then
	return oh.Cache["ui/main"]
end

----------------------------------------------------------------
-- SAFE UI LOAD (deferred)
----------------------------------------------------------------
local Interface
do
	RunService.Heartbeat:Wait()
	RunService.Heartbeat:Wait()

	local ok, result = pcall(function()
		return import("rbxassetid://11389137937")
	end)

	if not ok or not result then
		error("Failed to load UI asset")
	end

	Interface = result
	oh.Cache["ui/main"] = Interface
end

----------------------------------------------------------------
-- ADVANCED THUMBNAIL MANAGER (FINAL)
----------------------------------------------------------------
local MAX_THUMBNAILS = 64
local MAX_RETRIES = 1
local thumbnailCount = 0

local ThumbnailQueue = {}

local function isValidAvatarThumb(url)
	if type(url) ~= "string" then return false end
	if not url:find("rbxthumb://type=AvatarHeadShot") then
		return false
	end
	local id = url:match("id=(%d+)")
	return id and tonumber(id) and tonumber(id) > 0
end

for _, obj in ipairs(Interface:GetDescendants()) do
	if obj:IsA("ImageLabel") or obj:IsA("ImageButton") then
		local img = obj.Image
		if img and img:find("rbxthumb://") then
			if isValidAvatarThumb(img) then
				thumbnailCount += 1
				if thumbnailCount <= MAX_THUMBNAILS then
					obj.Image = ""
					table.insert(ThumbnailQueue, {
						object = obj,
						image = img,
						retries = 0
					})
				else
					obj.Image = ""
				end
			else
				obj.Image = ""
			end
		end
	end
end

-- Sequential thumbnail loader (FD safe)
task.spawn(function()
	for _, item in ipairs(ThumbnailQueue) do
		if not item.object or not item.object.Parent then
			continue
		end

		if item.retries >= MAX_RETRIES then
			continue
		end

		item.retries += 1
		item.object.Image = item.image

		-- give engine time to breathe
		RunService.Heartbeat:Wait()
		RunService.Heartbeat:Wait()
	end
end)

----------------------------------------------------------------
-- CONTROLS / MODULES (ORIGINAL)
----------------------------------------------------------------
import("ui/controls/TabSelector")
local MessageBox, MessageType = import("ui/controls/MessageBox")

xpcall(function()
	import("ui/modules/RemoteSpy")
	import("ui/modules/ClosureSpy")
	import("ui/modules/ScriptScanner")
	import("ui/modules/ModuleScanner")
	import("ui/modules/UpvalueScanner")
	import("ui/modules/ConstantScanner")
end, function(err)
	MessageBox.Show(
		"Hydroxide UI Error",
		tostring(err),
		MessageType.OK,
		function()
			if Interface then
				Interface:Destroy()
			end
		end
	)
end)

----------------------------------------------------------------
-- UI CONSTANTS / DRAG / BUTTONS (UNCHANGED)
----------------------------------------------------------------
local constants = {
	opened  = UDim2.new(0.5, -325, 0.5, -175),
	closed  = UDim2.new(0.5, -325, 0, -400),
	reveal  = UDim2.new(0.5, -15, 0, 20),
	conceal = UDim2.new(0.5, -15, 0, -75)
}

local Open = Interface.Open
local Base = Interface.Base
local Drag = Base.Drag
local Status = Base.Status
local Collapse = Drag.Collapse

function oh.setStatus(text)
	Status.Text = '• Status: ' .. text
end

function oh.getStatus()
	return Status.Text:gsub('• Status: ', '')
end

local dragging, dragStart, startPos

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

UserInput.InputChanged:Connect(function(input)
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

Open.MouseButton1Click:Connect(function()
	Open:TweenPosition(constants.conceal, "Out", "Quad", 0.15)
	Base:TweenPosition(constants.opened, "Out", "Quad", 0.15)
end)

Collapse.MouseButton1Click:Connect(function()
	Base:TweenPosition(constants.closed, "Out", "Quad", 0.15)
	Open:TweenPosition(constants.reveal, "Out", "Quad", 0.15)
end)

----------------------------------------------------------------
-- FINAL PARENTING
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
