-- [[ Made by Knightingale | ScriptBlox.com ]] --
-- Official script V1.5

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

local SCREEN_GUI_NAME = "PremiumAvatarCopier"
local ParentTarget = LocalPlayer:WaitForChild("PlayerGui")

if gethui then
	ParentTarget = gethui()
elseif syn and syn.protect_gui then
	local coreGui = game:GetService("CoreGui")
	syn.protect_gui(coreGui)
	ParentTarget = coreGui
end

local existingGui = ParentTarget:FindFirstChild(SCREEN_GUI_NAME)
if existingGui then
	existingGui:Destroy()
end

-- DONT CHANGE THIS FILE ROUTE TO "AVATAR SAVER V2" or else you want to corrupt you saver v2 Saved avatars.

local FOLDER_NAME = "Catalog Avatar Premium Clipboard"
local FILE_PATH = FOLDER_NAME .. "/SavedOutfits.json"

if makefolder and isfolder then
	if not isfolder(FOLDER_NAME) then
		makefolder(FOLDER_NAME)
	end
end

local copiedAvatars = {}
local dragging = false
local dragStart, startPosition
local minimized = false
local copying = false
local selectedPlayer = nil
local holdingCopy = false
local holdStart = 0
local HOLD_TIME = 0.7
local connections = {}

local function rgb(c)
	return {
		r = math.floor(c.R * 255),
		g = math.floor(c.G * 255),
		b = math.floor(c.B * 255),
		IsRGBTable = true
	}
end

local function vector(v)
	return {
		X = v.X,
		Y = v.Y,
		Z = v.Z,
		Vector3 = true
	}
end

local function getLayeredAccessories(desc)
	local result = {}
	for _, accessory in desc:GetAccessories(true) do
		if accessory.IsLayered then
			table.insert(result, {
				Rotation = vector(accessory.Rotation),
				AssetId = accessory.AssetId,
				AccessoryType = accessory.AccessoryType.Name,
				Position = vector(accessory.Position),
				Order = accessory.Order,
				IsLayered = true,
				Puffiness = accessory.Puffiness,
				Scale = vector(accessory.Scale)
			})
		end
	end
	return result
end

local function createCopiedProperties(desc)
	local props = {
		["WalkAnimation"] = desc.WalkAnimation,
		["MoodAnimation"] = desc.MoodAnimation,
		["ClimbAnimation"] = desc.ClimbAnimation,
		["FallAnimation"] = desc.FallAnimation,
		["RunAnimation"] = desc.RunAnimation,
		["SwimAnimation"] = desc.SwimAnimation,
		["IdleAnimation"] = desc.IdleAnimation,
		["JumpAnimation"] = desc.JumpAnimation,

		["Face"] = desc.Face,
		["Shirt"] = desc.Shirt,
		["Pants"] = desc.Pants,
		["GraphicTShirt"] = desc.GraphicTShirt,

		["RightArmColor"] = rgb(desc.RightArmColor),
		["TorsoColor"] = rgb(desc.TorsoColor),
		["RightLegColor"] = rgb(desc.RightLegColor),
		["LeftLegColor"] = rgb(desc.LeftLegColor),
		["LeftArmColor"] = rgb(desc.LeftArmColor),
		["HeadColor"] = rgb(desc.HeadColor),

		["Head"] = desc.Head,
		["Torso"] = desc.Torso,
		["LeftArm"] = desc.LeftArm,
		["RightArm"] = desc.RightArm,
		["LeftLeg"] = desc.LeftLeg,
		["RightLeg"] = desc.RightLeg,

		["ProportionScale"] = desc.ProportionScale,
		["DepthScale"] = desc.DepthScale,
		["HeightScale"] = desc.HeightScale,
		["WidthScale"] = desc.WidthScale,
		["BodyTypeScale"] = desc.BodyTypeScale,
		["HeadScale"] = desc.HeadScale,

		["FaceAccessory"] = desc.FaceAccessory,
		["HairAccessory"] = desc.HairAccessory,
		["WaistAccessory"] = desc.WaistAccessory,
		["ShouldersAccessory"] = desc.ShouldersAccessory,
		["NeckAccessory"] = desc.NeckAccessory,
		["HatAccessory"] = desc.HatAccessory,
		["FrontAccessory"] = desc.FrontAccessory,
		["BackAccessory"] = desc.BackAccessory,

		["LayeredAccessories"] = getLayeredAccessories(desc),
		["AccessoryRefinements"] = {}
	}

	pcall(function() props["EyelashAccessory"] = desc.EyelashAccessory end)
	pcall(function() props["EyebrowAccessory"] = desc.EyebrowAccessory end)
	pcall(function() props["MoodAccessory"] = desc.MoodAccessory end)

	return props
end

local function getAvatarSignature(properties, rigType)
	local success, result = pcall(function()
		return HttpService:JSONEncode({
			Properties = properties,
			RigType = tostring(rigType)
		})
	end)
	return success and result or tostring(properties)
end

local function applyTween(instance, properties, duration)
	local tweenInfo = TweenInfo.new(duration or 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local tween = TweenService:Create(instance, tweenInfo, properties)
	tween:Play()
	return tween
end

local function saveToWorkspace()
	if not writefile then return end

	local exportData = {}
	for index, data in ipairs(copiedAvatars) do
		table.insert(exportData, {
			FileName = "@" .. data.Name,
			Name = data.Name,
			DisplayName = data.DisplayName,
			Properties = data.Properties,
			RigType = tostring(data.RigType),
			Signature = data.Signature,
			Order = index
		})
	end

	pcall(function()
		writefile(FILE_PATH, HttpService:JSONEncode(exportData))
	end)
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = SCREEN_GUI_NAME
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.Parent = ParentTarget

local Main = Instance.new("Frame")
Main.Name = "Main"
Main.Size = UDim2.new(0, 310, 0, 320)
Main.Position = UDim2.new(0.5, -155, 0.5, -160)
Main.BackgroundColor3 = Color3.fromRGB(20, 20, 26)
Main.BorderSizePixel = 0
Main.ClipsDescendants = true
Main.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 10)
MainCorner.Parent = Main

local MainStroke = Instance.new("UIStroke")
MainStroke.Color = Color3.fromRGB(45, 45, 55)
MainStroke.Thickness = 1
MainStroke.Parent = Main

local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1, 0, 0, 42)
TitleBar.BackgroundColor3 = Color3.fromRGB(28, 28, 36)
TitleBar.BorderSizePixel = 0
TitleBar.ClipsDescendants = true
TitleBar.Parent = Main

local TitleBarCorner = Instance.new("UICorner")
TitleBarCorner.CornerRadius = UDim.new(0, 10)
TitleBarCorner.Parent = TitleBar

local TitleBarBottomFill = Instance.new("Frame")
TitleBarBottomFill.Size = UDim2.new(1, 0, 0, 10)
TitleBarBottomFill.Position = UDim2.new(0, 0, 1, -10)
TitleBarBottomFill.BackgroundColor3 = Color3.fromRGB(28, 28, 36)
TitleBarBottomFill.BorderSizePixel = 0
TitleBarBottomFill.ZIndex = 0
TitleBarBottomFill.Parent = TitleBar

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -50, 1, 0)
Title.Position = UDim2.new(0, 14, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "AVATAR CLIPBOARD \xF0\x9F\x93\x8B\xE2\x9C\xA8"
Title.TextColor3 = Color3.fromRGB(235, 235, 245)
Title.TextSize = 14
Title.Font = Enum.Font.GothamBold
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.ZIndex = 2
Title.Parent = TitleBar

local Minimize = Instance.new("TextButton")
Minimize.Size = UDim2.new(0, 28, 0, 28)
Minimize.Position = UDim2.new(1, -35, 0, 7)
Minimize.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
Minimize.Text = "-"
Minimize.TextColor3 = Color3.fromRGB(200, 200, 210)
Minimize.TextSize = 16
Minimize.Font = Enum.Font.GothamBold
Minimize.ZIndex = 2
Minimize.Parent = TitleBar

local MinCorner = Instance.new("UICorner")
MinCorner.CornerRadius = UDim.new(0, 6)
MinCorner.Parent = Minimize

local SaveButton = Instance.new("TextButton")
SaveButton.Size = UDim2.new(0.33, -8, 0, 32)
SaveButton.Position = UDim2.new(0, 10, 0, 50)
SaveButton.BackgroundColor3 = Color3.fromRGB(46, 125, 85)
SaveButton.Text = "SAVE CURRENT"
SaveButton.TextColor3 = Color3.fromRGB(255, 255, 255)
SaveButton.TextSize = 10
SaveButton.Font = Enum.Font.GothamBold
SaveButton.Parent = Main

local SaveCorner = Instance.new("UICorner")
SaveCorner.CornerRadius = UDim.new(0, 6)
SaveCorner.Parent = SaveButton

local ClearButton = Instance.new("TextButton")
ClearButton.Size = UDim2.new(0.33, -8, 0, 32)
ClearButton.Position = UDim2.new(0.33, 4, 0, 50)
ClearButton.BackgroundColor3 = Color3.fromRGB(135, 80, 50)
ClearButton.Text = "CLEAR ALL"
ClearButton.TextColor3 = Color3.fromRGB(255, 255, 255)
ClearButton.TextSize = 10
ClearButton.Font = Enum.Font.GothamBold
ClearButton.Parent = Main

local ClearCorner = Instance.new("UICorner")
ClearCorner.CornerRadius = UDim.new(0, 6)
ClearCorner.Parent = ClearButton

local UnloadButton = Instance.new("TextButton")
UnloadButton.Size = UDim2.new(0.33, -8, 0, 32)
UnloadButton.Position = UDim2.new(0.66, -2, 0, 50)
UnloadButton.BackgroundColor3 = Color3.fromRGB(135, 50, 50)
UnloadButton.Text = "DESTROY UI"
UnloadButton.TextColor3 = Color3.fromRGB(255, 255, 255)
UnloadButton.TextSize = 10
UnloadButton.Font = Enum.Font.GothamBold
UnloadButton.Parent = Main

local UnloadCorner = Instance.new("UICorner")
UnloadCorner.CornerRadius = UDim.new(0, 6)
UnloadCorner.Parent = UnloadButton

local Status = Instance.new("TextLabel")
Status.Size = UDim2.new(1, -20, 0, 20)
Status.Position = UDim2.new(0, 10, 0, 88)
Status.BackgroundTransparency = 1
Status.Text = "Copied avatars: 0"
Status.TextColor3 = Color3.fromRGB(150, 150, 165)
Status.TextSize = 11
Status.Font = Enum.Font.Gotham
Status.TextXAlignment = Enum.TextXAlignment.Left
Status.Parent = Main

local Watermark = Instance.new("TextLabel")
Watermark.Size = UDim2.new(1, -20, 0, 16)
Watermark.Position = UDim2.new(0, 10, 1, -18)
Watermark.BackgroundTransparency = 1
Watermark.Text = "Made by Knightingale | ScriptBlox.com"
Watermark.TextColor3 = Color3.fromRGB(85, 85, 105)
Watermark.TextSize = 9
Watermark.Font = Enum.Font.GothamBold
Watermark.TextXAlignment = Enum.TextXAlignment.Right
Watermark.Parent = Main

local ListContainer = Instance.new("Frame")
ListContainer.Size = UDim2.new(1, -20, 1, -138)
ListContainer.Position = UDim2.new(0, 10, 0, 110)
ListContainer.BackgroundTransparency = 1
ListContainer.ClipsDescendants = true
ListContainer.Parent = Main

local ListContainerCorner = Instance.new("UICorner")
ListContainerCorner.CornerRadius = UDim.new(0, 8)
ListContainerCorner.Parent = ListContainer

local List = Instance.new("ScrollingFrame")
List.Size = UDim2.new(1, 0, 1, 0)
List.BackgroundTransparency = 1
List.BorderSizePixel = 0
List.ScrollBarThickness = 3
List.ScrollBarImageColor3 = Color3.fromRGB(60, 60, 75)
List.CanvasSize = UDim2.new(0, 0, 0, 0)
List.AutomaticCanvasSize = Enum.AutomaticSize.Y
List.Parent = ListContainer

local Layout = Instance.new("UIListLayout")
Layout.Padding = UDim.new(0, 6)
Layout.SortOrder = Enum.SortOrder.LayoutOrder
Layout.Parent = List

local EmptyMessage = Instance.new("TextLabel")
EmptyMessage.Size = UDim2.new(1, 0, 0, 60)
EmptyMessage.Position = UDim2.new(0, 0, 0, 20)
EmptyMessage.BackgroundTransparency = 1
EmptyMessage.Text = "Click on any player to copy their outfit."
EmptyMessage.TextColor3 = Color3.fromRGB(110, 110, 125)
EmptyMessage.TextSize = 12
EmptyMessage.Font = Enum.Font.Gotham
EmptyMessage.Parent = ListContainer

local ConfirmFrame = Instance.new("Frame")
ConfirmFrame.Size = UDim2.new(1, -20, 0, 75)
ConfirmFrame.Position = UDim2.new(0, 10, 0, 110)
ConfirmFrame.BackgroundColor3 = Color3.fromRGB(32, 32, 40)
ConfirmFrame.BorderSizePixel = 0
ConfirmFrame.Visible = false
ConfirmFrame.ZIndex = 10
ConfirmFrame.Parent = Main

local ConfirmCorner = Instance.new("UICorner")
ConfirmCorner.CornerRadius = UDim.new(0, 8)
ConfirmCorner.Parent = ConfirmFrame

local ConfirmText = Instance.new("TextLabel")
ConfirmText.Size = UDim2.new(1, -10, 0, 26)
ConfirmText.Position = UDim2.new(0, 5, 0, 6)
ConfirmText.BackgroundTransparency = 1
ConfirmText.Text = "Clear all saved fits?"
ConfirmText.TextColor3 = Color3.fromRGB(240, 240, 245)
ConfirmText.TextSize = 12
ConfirmText.Font = Enum.Font.GothamBold
ConfirmText.ZIndex = 11
ConfirmText.Parent = ConfirmFrame

local CancelButton = Instance.new("TextButton")
CancelButton.Size = UDim2.new(0.5, -8, 0, 28)
CancelButton.Position = UDim2.new(0, 5, 0, 38)
CancelButton.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
CancelButton.Text = "CANCEL"
CancelButton.TextColor3 = Color3.fromRGB(255, 255, 255)
CancelButton.TextSize = 10
CancelButton.Font = Enum.Font.GothamBold
CancelButton.ZIndex = 11
CancelButton.Parent = ConfirmFrame

local CancelCorner = Instance.new("UICorner")
CancelCorner.CornerRadius = UDim.new(0, 5)
CancelCorner.Parent = CancelButton

local ConfirmAction = Instance.new("TextButton")
ConfirmAction.Size = UDim2.new(0.5, -8, 0, 28)
ConfirmAction.Position = UDim2.new(0.5, 3, 0, 38)
ConfirmAction.BackgroundColor3 = Color3.fromRGB(150, 50, 50)
ConfirmAction.Text = "CONFIRM"
ConfirmAction.TextColor3 = Color3.fromRGB(255, 255, 255)
ConfirmAction.TextSize = 10
ConfirmAction.Font = Enum.Font.GothamBold
ConfirmAction.ZIndex = 11
ConfirmAction.Parent = ConfirmFrame

local ConfirmActionCorner = Instance.new("UICorner")
ConfirmActionCorner.CornerRadius = UDim.new(0, 5)
ConfirmActionCorner.Parent = ConfirmAction

local SelectFrame = Instance.new("Frame")
SelectFrame.Size = UDim2.new(0, 220, 0, 80)
SelectFrame.Position = UDim2.new(0.5, -110, 0.8, 0)
SelectFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 38)
SelectFrame.BorderSizePixel = 0
SelectFrame.Visible = false
SelectFrame.ZIndex = 20
SelectFrame.Parent = ScreenGui

local SelectCorner = Instance.new("UICorner")
SelectCorner.CornerRadius = UDim.new(0, 8)
SelectCorner.Parent = SelectFrame

local SelectStroke = Instance.new("UIStroke")
SelectStroke.Color = Color3.fromRGB(50, 50, 65)
SelectStroke.Thickness = 1
SelectStroke.Parent = SelectFrame

local SelectedName = Instance.new("TextLabel")
SelectedName.Size = UDim2.new(1, -20, 0, 24)
SelectedName.Position = UDim2.new(0, 10, 0, 6)
SelectedName.BackgroundTransparency = 1
SelectedName.Text = "@Player"
SelectedName.TextColor3 = Color3.fromRGB(255, 255, 255)
SelectedName.TextSize = 12
SelectedName.Font = Enum.Font.GothamBold
SelectedName.TextXAlignment = Enum.TextXAlignment.Left
SelectedName.TextTruncate = Enum.TextTruncate.AtEnd
SelectedName.ZIndex = 21
SelectedName.Parent = SelectFrame

local HoldButton = Instance.new("TextButton")
HoldButton.Size = UDim2.new(1, -90, 0, 34)
HoldButton.Position = UDim2.new(0, 10, 0, 36)
HoldButton.BackgroundColor3 = Color3.fromRGB(55, 95, 175)
HoldButton.Text = "HOLD TO COPY"
HoldButton.TextColor3 = Color3.fromRGB(255, 255, 255)
HoldButton.TextSize = 11
HoldButton.Font = Enum.Font.GothamBold
HoldButton.ZIndex = 21
HoldButton.Parent = SelectFrame

local HoldCorner = Instance.new("UICorner")
HoldCorner.CornerRadius = UDim.new(0, 6)
HoldCorner.Parent = HoldButton

local SelectCancel = Instance.new("TextButton")
SelectCancel.Size = UDim2.new(0, 65, 0, 34)
SelectCancel.Position = UDim2.new(1, -75, 0, 36)
SelectCancel.BackgroundColor3 = Color3.fromRGB(85, 45, 45)
SelectCancel.Text = "CANCEL"
SelectCancel.TextColor3 = Color3.fromRGB(255, 255, 255)
SelectCancel.TextSize = 10
SelectCancel.Font = Enum.Font.GothamBold
SelectCancel.ZIndex = 21
SelectCancel.Parent = SelectFrame

local SelectCancelCorner = Instance.new("UICorner")
SelectCancelCorner.CornerRadius = UDim.new(0, 6)
SelectCancelCorner.Parent = SelectCancel

TitleBar.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = true
		dragStart = input.Position
		startPosition = Main.Position

		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				dragging = false
			end
		end)
	end
end)

table.insert(connections, UserInputService.InputChanged:Connect(function(input)
	if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
		local delta = input.Position - dragStart
		Main.Position = UDim2.new(
			startPosition.X.Scale,
			startPosition.X.Offset + delta.X,
			startPosition.Y.Scale,
			startPosition.Y.Offset + delta.Y
		)
	end
end))

local function updateStatus()
	Status.Text = "Copied avatars: " .. tostring(#copiedAvatars)
	EmptyMessage.Visible = (#copiedAvatars == 0) and not minimized
end

local function hideSelectFrame()
	selectedPlayer = nil
	holdingCopy = false
	SelectFrame.Visible = false
	HoldButton.Text = "HOLD TO COPY"
	HoldButton.BackgroundColor3 = Color3.fromRGB(55, 95, 175)
end

local function wearCopiedAvatar(data)
	if not data then return end
	local wearPayload = {{
		["Properties"] = data.Properties,
		["Action"] = "CreateAndWearHumanoidDescription",
		["RigType"] = data.RigType
	}}

	local success, err = pcall(function()
		ReplicatedStorage.Events.CatalogGuiRemote:InvokeServer(unpack(wearPayload))
	end)

	if not success then
		warn("[Avatar Copier] Wear action failed:", err)
	end
end

local function saveCurrentOutfit()
	local success, err = pcall(function()
		ReplicatedStorage.Events.SavedOutfitsRemote:InvokeServer({
			OutfitName = "Unnamed Outfit",
			Configs = {},
			Action = "CreateNewOutfit"
		})
	end)

	if success then
		Status.Text = "Current outfit saved!"
		task.delay(2, updateStatus)
	else
		warn("[Avatar Copier] Save action failed:", err)
	end
end

local function destroyScriptAndUI()
	for _, conn in ipairs(connections) do
		if conn and conn.Connected then
			conn:Disconnect()
		end
	end
	table.clear(connections)
	ScreenGui:Destroy()
end

local function createAvatarEntry(data, index)
	local Entry = Instance.new("Frame")
	Entry.Size = UDim2.new(1, -6, 0, 36)
	Entry.BackgroundColor3 = Color3.fromRGB(28, 28, 36)
	Entry.BorderSizePixel = 0
	Entry.LayoutOrder = index
	Entry.ClipsDescendants = true
	Entry.Parent = List

	local Corner = Instance.new("UICorner")
	Corner.CornerRadius = UDim.new(0, 6)
	Corner.Parent = Entry

	local NameLabel = Instance.new("TextLabel")
	NameLabel.Size = UDim2.new(1, -70, 1, 0)
	NameLabel.Position = UDim2.new(0, 10, 0, 0)
	NameLabel.BackgroundTransparency = 1
	NameLabel.Text = "@" .. data.Name
	NameLabel.TextColor3 = Color3.fromRGB(230, 230, 240)
	NameLabel.TextSize = 11
	NameLabel.Font = Enum.Font.Gotham
	NameLabel.TextXAlignment = Enum.TextXAlignment.Left
	NameLabel.TextTruncate = Enum.TextTruncate.AtEnd
	NameLabel.Parent = Entry

	local WearButton = Instance.new("TextButton")
	WearButton.Size = UDim2.new(0, 54, 0, 24)
	WearButton.Position = UDim2.new(1, -60, 0, 6)
	WearButton.BackgroundColor3 = Color3.fromRGB(55, 95, 175)
	WearButton.Text = "WEAR"
	WearButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	WearButton.TextSize = 10
	WearButton.Font = Enum.Font.GothamBold
	WearButton.Parent = Entry

	local WearCorner = Instance.new("UICorner")
	WearCorner.CornerRadius = UDim.new(0, 5)
	WearCorner.Parent = WearButton

	data.UI = Entry
	data.NameLabel = NameLabel

	WearButton.MouseEnter:Connect(function()
		applyTween(WearButton, {BackgroundColor3 = Color3.fromRGB(75, 115, 195)})
	end)
	WearButton.MouseLeave:Connect(function()
		applyTween(WearButton, {BackgroundColor3 = Color3.fromRGB(55, 95, 175)})
	end)

	WearButton.Activated:Connect(function()
		wearCopiedAvatar(data)
	end)
end

local function updateOrders()
	for index, data in ipairs(copiedAvatars) do
		data.Order = index
		if data.UI and data.UI.Parent then
			data.UI.LayoutOrder = index
			if data.NameLabel then
				data.NameLabel.Text = "@" .. data.Name
			end
		end
	end
	saveToWorkspace()
end

local function loadFromWorkspace()
	if not readfile or not isfile or not isfile(FILE_PATH) then return end

	local success, result = pcall(function()
		return HttpService:JSONDecode(readfile(FILE_PATH))
	end)

	if success and type(result) == "table" then
		table.clear(copiedAvatars)
		for index, data in ipairs(result) do
			if typeof(data.RigType) == "string" then
				data.RigType = (data.RigType == "Enum.HumanoidRigType.R15" or data.RigType == "R15") and Enum.HumanoidRigType.R15 or Enum.HumanoidRigType.R6
			end
			table.insert(copiedAvatars, data)
			createAvatarEntry(data, index)
		end
		updateStatus()
	end
end

local function clearCopiedFits()
	for _, data in ipairs(copiedAvatars) do
		if data.UI then
			data.UI:Destroy()
		end
	end

	table.clear(copiedAvatars)
	if delfile and isfile and isfile(FILE_PATH) then
		pcall(function()
			delfile(FILE_PATH)
		end)
	end

	updateStatus()
	Status.Text = "Copied fits cleared!"
	task.delay(2, updateStatus)
end

local function copyForStorage(targetPlayer)
	if copying or not targetPlayer or not targetPlayer.Character then return end

	local humanoid = targetPlayer.Character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end

	copying = true

	local success, data = pcall(function()
		local desc = humanoid:GetAppliedDescription()
		local properties = createCopiedProperties(desc)

		return {
			Name = targetPlayer.Name,
			DisplayName = targetPlayer.DisplayName,
			Properties = properties,
			RigType = humanoid.RigType,
			Signature = getAvatarSignature(properties, humanoid.RigType),
			Order = 1
		}
	end)

	if not success then
		warn("[Avatar Copier] Capture failed:", data)
		copying = false
		return
	end

	for _, existing in ipairs(copiedAvatars) do
		if existing.Signature == data.Signature then
			Status.Text = "Already copied!"
			task.delay(2, updateStatus)
			copying = false
			return
		end
	end

	table.insert(copiedAvatars, 1, data)

	createAvatarEntry(data, 1)
	updateOrders()
	updateStatus()

	Status.Text = "Copied @" .. data.Name .. "!"
	task.delay(2, updateStatus)

	task.delay(0.3, function()
		copying = false
	end)
end

local function getPlayerFromTarget(target)
	if not target then return nil end
	local model = target:FindFirstAncestorOfClass("Model")
	if not model then return nil end

	local humanoid = model:FindFirstChildOfClass("Humanoid")
	if not humanoid then return nil end

	local player = Players:GetPlayerFromCharacter(model)
	return (player and player ~= LocalPlayer) and player or nil
end

local function selectPlayer(player)
	if not player or player == LocalPlayer or not player.Character then return end

	selectedPlayer = player
	SelectedName.Text = "@" .. player.Name
	HoldButton.Text = "HOLD TO COPY"
	HoldButton.BackgroundColor3 = Color3.fromRGB(55, 95, 175)
	SelectFrame.Visible = true
end

local function handlePlayerClick()
	local player = getPlayerFromTarget(Mouse.Target)
	if player then
		selectPlayer(player)
	end
end

table.insert(connections, UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		handlePlayerClick()
	end
end))

table.insert(connections, UserInputService.TouchTap:Connect(function(_, gameProcessed)
	if gameProcessed then return end
	handlePlayerClick()
end))

local function beginHold()
	if not selectedPlayer or copying then return end

	holdingCopy = true
	holdStart = os.clock()
	HoldButton.Text = "COPYING..."

	task.spawn(function()
		while holdingCopy do
			if os.clock() - holdStart >= HOLD_TIME then
				holdingCopy = false
				local player = selectedPlayer

				HoldButton.Text = "COPIED!"
				HoldButton.BackgroundColor3 = Color3.fromRGB(46, 125, 85)

				copyForStorage(player)

				task.delay(0.6, function()
					hideSelectFrame()
				end)
				break
			end
			task.wait()
		end
	end)
end

local function endHold()
	if holdingCopy then
		holdingCopy = false
		if selectedPlayer then
			HoldButton.Text = "HOLD TO COPY"
		end
	end
end

HoldButton.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		beginHold()
	end
end)

HoldButton.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		endHold()
	end
end)

SelectCancel.Activated:Connect(hideSelectFrame)
SaveButton.Activated:Connect(saveCurrentOutfit)

local currentConfirmAction = nil

ClearButton.Activated:Connect(function()
	if #copiedAvatars == 0 then
		Status.Text = "Nothing to clear!"
		task.delay(2, updateStatus)
		return
	end

	ConfirmText.Text = "Clear all saved fits?"
	currentConfirmAction = clearCopiedFits

	ConfirmFrame.Visible = true
	ClearButton.Visible = false
	SaveButton.Visible = false
	UnloadButton.Visible = false
	Status.Visible = false
	ListContainer.Visible = false
	Watermark.Visible = false
end)

UnloadButton.Activated:Connect(function()
	ConfirmText.Text = "Destroy UI & unload script?"
	currentConfirmAction = destroyScriptAndUI

	ConfirmFrame.Visible = true
	ClearButton.Visible = false
	SaveButton.Visible = false
	UnloadButton.Visible = false
	Status.Visible = false
	ListContainer.Visible = false
	Watermark.Visible = false
end)

CancelButton.Activated:Connect(function()
	ConfirmFrame.Visible = false
	ClearButton.Visible = true
	SaveButton.Visible = true
	UnloadButton.Visible = true
	Status.Visible = true
	ListContainer.Visible = true
	Watermark.Visible = true
	currentConfirmAction = nil
	updateStatus()
end)

ConfirmAction.Activated:Connect(function()
	ConfirmFrame.Visible = false
	ClearButton.Visible = true
	SaveButton.Visible = true
	UnloadButton.Visible = true
	Status.Visible = true
	ListContainer.Visible = true
	Watermark.Visible = true

	if currentConfirmAction then
		currentConfirmAction()
		currentConfirmAction = nil
	end
end)

Minimize.Activated:Connect(function()
	minimized = not minimized

	if minimized then
		hideSelectFrame()
		TitleBarBottomFill.Visible = false
		applyTween(Main, {Size = UDim2.new(0, 220, 0, 42)})

		SaveButton.Visible = false
		ClearButton.Visible = false
		UnloadButton.Visible = false
		Status.Visible = false
		ListContainer.Visible = false
		ConfirmFrame.Visible = false
		Watermark.Visible = false

		Minimize.Text = "+"
	else
		applyTween(Main, {Size = UDim2.new(0, 310, 0, 320)})
		TitleBarBottomFill.Visible = true

		SaveButton.Visible = true
		ClearButton.Visible = true
		UnloadButton.Visible = true
		Status.Visible = true
		ListContainer.Visible = true
		Watermark.Visible = true

		Minimize.Text = "-"
		updateStatus()
	end
end)

loadFromWorkspace()
updateStatus()
