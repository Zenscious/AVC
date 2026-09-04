-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera
local Mouse = LocalPlayer:GetMouse()

-- Environment Detection (Catalog Avatar Creator Check)
local catalogEvents = ReplicatedStorage:FindFirstChild("Events")
local catalogGuiRemote = catalogEvents and catalogEvents:FindFirstChild("CatalogGuiRemote")
local savedOutfitsRemote = catalogEvents and catalogEvents:FindFirstChild("SavedOutfitsRemote")
local IS_CATALOG_GAME = (catalogGuiRemote ~= nil and savedOutfitsRemote ~= nil)

-- Single Instance Prevention
local SCREEN_GUI_NAME = "AvatarSaverV2_UI"
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

-- Storage Path Configuration (Updated to v2)
local FOLDER_NAME = "Avatar Saver v2"
local FILE_PATH = FOLDER_NAME .. "/SavedAvatars.json"

if makefolder and isfolder then
	if not isfolder(FOLDER_NAME) then
		makefolder(FOLDER_NAME)
	end
end

-- Screen Size & Responsive Layout Detection
local isMobile = (Camera.ViewportSize.X < 700 or Camera.ViewportSize.Y < 500)
local mainWidth = isMobile and 310 or 370
local mainHeight = isMobile and 380 or 440

-- State Management
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
local currentActiveData = nil
local currentConfirmAction = nil

-- Safe Serializers
local function rgb(c)
	if not c then return {r=255, g=255, b=255, IsRGBTable=true} end
	return {
		r = math.floor(c.R * 255),
		g = math.floor(c.G * 255),
		b = math.floor(c.B * 255),
		IsRGBTable = true
	}
end

local function vector(v)
	if not v then return {X=0, Y=0, Z=0, Vector3=true} end
	return {X = v.X, Y = v.Y, Z = v.Z, Vector3 = true}
end

local function getLayeredAccessories(desc)
	local result = {}
	pcall(function()
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
	end)
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
	pcall(function() props["Eyes"] = desc.Eyes end)
	pcall(function() props["Lips"] = desc.Lips end)

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
			UserId = data.UserId,
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

-- ScreenGui Setup
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = SCREEN_GUI_NAME
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.Parent = ParentTarget

-- Main Container
local Main = Instance.new("Frame")
Main.Name = "Main"
Main.Size = UDim2.new(0, mainWidth, 0, mainHeight)
Main.Position = UDim2.new(0.5, -mainWidth/2, 0.5, -mainHeight/2)
Main.BackgroundColor3 = Color3.fromRGB(20, 20, 26)
Main.BorderSizePixel = 0
Main.ClipsDescendants = true
Main.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 8)
MainCorner.Parent = Main

local MainStroke = Instance.new("UIStroke")
MainStroke.Color = Color3.fromRGB(45, 45, 55)
MainStroke.Thickness = 1
MainStroke.Parent = Main

-- TitleBar
local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1, 0, 0, 38)
TitleBar.BackgroundColor3 = Color3.fromRGB(28, 28, 36)
TitleBar.BorderSizePixel = 0
TitleBar.Parent = Main

local TitleBarCorner = Instance.new("UICorner")
TitleBarCorner.CornerRadius = UDim.new(0, 8)
TitleBarCorner.Parent = TitleBar

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -50, 1, 0)
Title.Position = UDim2.new(0, 12, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "Avatar Saver [v2]"
Title.TextColor3 = Color3.fromRGB(235, 235, 245)
Title.TextSize = 13
Title.Font = Enum.Font.GothamBold
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = TitleBar

local Minimize = Instance.new("TextButton")
Minimize.Size = UDim2.new(0, 24, 0, 24)
Minimize.Position = UDim2.new(1, -30, 0, 7)
Minimize.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
Minimize.Text = "-"
Minimize.TextColor3 = Color3.fromRGB(200, 200, 210)
Minimize.TextSize = 14
Minimize.Font = Enum.Font.GothamBold
Minimize.Parent = TitleBar

local MinCorner = Instance.new("UICorner")
MinCorner.CornerRadius = UDim.new(0, 4)
MinCorner.Parent = Minimize

-- Non-CAC Warning Banner
local WarningBanner = Instance.new("Frame")
WarningBanner.Size = UDim2.new(1, -16, 0, 32)
WarningBanner.Position = UDim2.new(0, 8, 0, 44)
WarningBanner.BackgroundColor3 = Color3.fromRGB(45, 35, 20)
WarningBanner.BorderSizePixel = 0
WarningBanner.Visible = not IS_CATALOG_GAME
WarningBanner.Parent = Main

local WarningCorner = Instance.new("UICorner")
WarningCorner.CornerRadius = UDim.new(0, 6)
WarningCorner.Parent = WarningBanner

local WarningText = Instance.new("TextLabel")
WarningText.Size = UDim2.new(1, -10, 1, 0)
WarningText.Position = UDim2.new(0, 5, 0, 0)
WarningText.BackgroundTransparency = 1
WarningText.Text = "Warning: Copying avatars may carry risks. Use alt accounts for testing."
WarningText.TextColor3 = Color3.fromRGB(245, 200, 120)
WarningText.TextSize = 8
WarningText.Font = Enum.Font.Gotham
WarningText.TextWrapped = true
WarningText.TextXAlignment = Enum.TextXAlignment.Left
WarningText.Parent = WarningBanner

-- Action Controls Panel
local ActionOffsetY = IS_CATALOG_GAME and 44 or 80

local SaveButton = Instance.new("TextButton")
SaveButton.Size = UDim2.new(0.24, -4, 0, 26)
SaveButton.Position = UDim2.new(0, 8, 0, ActionOffsetY)
SaveButton.BackgroundColor3 = IS_CATALOG_GAME and Color3.fromRGB(46, 125, 85) or Color3.fromRGB(55, 55, 65)
SaveButton.Text = "SAVE CURRENT"
SaveButton.TextColor3 = IS_CATALOG_GAME and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(130, 130, 140)
SaveButton.TextSize = 8
SaveButton.Font = Enum.Font.GothamBold
SaveButton.Parent = Main

local SaveCorner = Instance.new("UICorner")
SaveCorner.CornerRadius = UDim.new(0, 4)
SaveCorner.Parent = SaveButton

local CopySelfBtn = Instance.new("TextButton")
CopySelfBtn.Size = UDim2.new(0.24, -4, 0, 26)
CopySelfBtn.Position = UDim2.new(0.24, 6, 0, ActionOffsetY)
CopySelfBtn.BackgroundColor3 = Color3.fromRGB(55, 95, 175)
CopySelfBtn.Text = "COPY SELF"
CopySelfBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CopySelfBtn.TextSize = 8
CopySelfBtn.Font = Enum.Font.GothamBold
CopySelfBtn.Parent = Main

local CopySelfCorner = Instance.new("UICorner")
CopySelfCorner.CornerRadius = UDim.new(0, 4)
CopySelfCorner.Parent = CopySelfBtn

local ClearButton = Instance.new("TextButton")
ClearButton.Size = UDim2.new(0.24, -4, 0, 26)
ClearButton.Position = UDim2.new(0.48, 4, 0, ActionOffsetY)
ClearButton.BackgroundColor3 = Color3.fromRGB(135, 80, 50)
ClearButton.Text = "CLEAR ALL"
ClearButton.TextColor3 = Color3.fromRGB(255, 255, 255)
ClearButton.TextSize = 8
ClearButton.Font = Enum.Font.GothamBold
ClearButton.Parent = Main

local ClearCorner = Instance.new("UICorner")
ClearCorner.CornerRadius = UDim.new(0, 4)
ClearCorner.Parent = ClearButton

local UnloadButton = Instance.new("TextButton")
UnloadButton.Size = UDim2.new(0.24, -4, 0, 26)
UnloadButton.Position = UDim2.new(0.72, 2, 0, ActionOffsetY)
UnloadButton.BackgroundColor3 = Color3.fromRGB(135, 50, 50)
UnloadButton.Text = "DESTROY UI"
UnloadButton.TextColor3 = Color3.fromRGB(255, 255, 255)
UnloadButton.TextSize = 8
UnloadButton.Font = Enum.Font.GothamBold
UnloadButton.Parent = Main

local UnloadCorner = Instance.new("UICorner")
UnloadCorner.CornerRadius = UDim.new(0, 4)
UnloadCorner.Parent = UnloadButton

-- Status Counter Label
local Status = Instance.new("TextLabel")
Status.Size = UDim2.new(1, -16, 0, 16)
Status.Position = UDim2.new(0, 8, 0, ActionOffsetY + 30)
Status.BackgroundTransparency = 1
Status.Text = "Saved Avatars: 0"
Status.TextColor3 = Color3.fromRGB(150, 150, 165)
Status.TextSize = 9
Status.Font = Enum.Font.Gotham
Status.TextXAlignment = Enum.TextXAlignment.Left
Status.Parent = Main

-- Grid Container
local ContainerOffsetY = ActionOffsetY + 48

local ListContainer = Instance.new("Frame")
ListContainer.Size = UDim2.new(1, -16, 1, -(ContainerOffsetY + 22))
ListContainer.Position = UDim2.new(0, 8, 0, ContainerOffsetY)
ListContainer.BackgroundTransparency = 1
ListContainer.ClipsDescendants = true
ListContainer.Parent = Main

local List = Instance.new("ScrollingFrame")
List.Size = UDim2.new(1, 0, 1, 0)
List.BackgroundTransparency = 1
List.BorderSizePixel = 0
List.ScrollBarThickness = 2
List.ScrollBarImageColor3 = Color3.fromRGB(60, 60, 75)
List.CanvasSize = UDim2.new(0, 0, 0, 0)
List.AutomaticCanvasSize = Enum.AutomaticSize.Y
List.Parent = ListContainer

local Grid = Instance.new("UIGridLayout")
local cardCellWidth = isMobile and 88 or 104
Grid.CellSize = UDim2.new(0, cardCellWidth, 0, 120)
Grid.CellPadding = UDim2.new(0, 8, 0, 8)
Grid.SortOrder = Enum.SortOrder.LayoutOrder
Grid.Parent = List

local EmptyMessage = Instance.new("TextLabel")
EmptyMessage.Size = UDim2.new(1, 0, 0, 40)
EmptyMessage.Position = UDim2.new(0, 0, 0, 30)
EmptyMessage.BackgroundTransparency = 1
EmptyMessage.Text = "Click any player or use COPY SELF to save an avatar."
EmptyMessage.TextColor3 = Color3.fromRGB(110, 110, 125)
EmptyMessage.TextSize = 10
EmptyMessage.Font = Enum.Font.Gotham
EmptyMessage.Parent = ListContainer

-- Card Action Modal
local ActionModal = Instance.new("Frame")
ActionModal.Size = UDim2.new(1, 0, 1, 0)
ActionModal.BackgroundColor3 = Color3.fromRGB(12, 12, 16)
ActionModal.BackgroundTransparency = 0.2
ActionModal.BorderSizePixel = 0
ActionModal.Visible = false
ActionModal.ZIndex = 30
ActionModal.Parent = Main

local ModalBox = Instance.new("Frame")
ModalBox.Size = UDim2.new(0, 220, 0, 160)
ModalBox.Position = UDim2.new(0.5, -110, 0.5, -80)
ModalBox.BackgroundColor3 = Color3.fromRGB(28, 28, 36)
ModalBox.BorderSizePixel = 0
ModalBox.ZIndex = 31
ModalBox.Parent = ActionModal

local ModalCorner = Instance.new("UICorner")
ModalCorner.CornerRadius = UDim.new(0, 8)
ModalCorner.Parent = ModalBox

local ModalTitle = Instance.new("TextLabel")
ModalTitle.Size = UDim2.new(1, -30, 0, 26)
ModalTitle.Position = UDim2.new(0, 10, 0, 6)
ModalTitle.BackgroundTransparency = 1
ModalTitle.Text = "@Player"
ModalTitle.TextColor3 = Color3.fromRGB(240, 240, 245)
ModalTitle.TextSize = 11
ModalTitle.Font = Enum.Font.GothamBold
ModalTitle.TextTruncate = Enum.TextTruncate.AtEnd
ModalTitle.ZIndex = 32
ModalTitle.Parent = ModalBox

local ModalWear = Instance.new("TextButton")
ModalWear.Size = UDim2.new(1, -20, 0, 28)
ModalWear.Position = UDim2.new(0, 10, 0, 38)
ModalWear.BackgroundColor3 = IS_CATALOG_GAME and Color3.fromRGB(55, 95, 175) or Color3.fromRGB(55, 55, 65)
ModalWear.Text = IS_CATALOG_GAME and "WEAR OUTFIT" or "WEAR [CAC ONLY]"
ModalWear.TextColor3 = IS_CATALOG_GAME and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(130, 130, 140)
ModalWear.TextSize = 9
ModalWear.Font = Enum.Font.GothamBold
ModalWear.ZIndex = 32
ModalWear.Parent = ModalBox

local ModalWearCorner = Instance.new("UICorner")
ModalWearCorner.CornerRadius = UDim.new(0, 4)
ModalWearCorner.Parent = ModalWear

local ModalInspect = Instance.new("TextButton")
ModalInspect.Size = UDim2.new(1, -20, 0, 28)
ModalInspect.Position = UDim2.new(0, 10, 0, 72)
ModalInspect.BackgroundColor3 = Color3.fromRGB(60, 110, 100)
ModalInspect.Text = "INSPECT AVATAR"
ModalInspect.TextColor3 = Color3.fromRGB(255, 255, 255)
ModalInspect.TextSize = 9
ModalInspect.Font = Enum.Font.GothamBold
ModalInspect.ZIndex = 32
ModalInspect.Parent = ModalBox

local ModalInspectCorner = Instance.new("UICorner")
ModalInspectCorner.CornerRadius = UDim.new(0, 4)
ModalInspectCorner.Parent = ModalInspect

local ModalDelete = Instance.new("TextButton")
ModalDelete.Size = UDim2.new(1, -20, 0, 28)
ModalDelete.Position = UDim2.new(0, 10, 0, 106)
ModalDelete.BackgroundColor3 = Color3.fromRGB(150, 50, 50)
ModalDelete.Text = "DELETE"
ModalDelete.TextColor3 = Color3.fromRGB(255, 255, 255)
ModalDelete.TextSize = 9
ModalDelete.Font = Enum.Font.GothamBold
ModalDelete.ZIndex = 32
ModalDelete.Parent = ModalBox

local ModalDeleteCorner = Instance.new("UICorner")
ModalDeleteCorner.CornerRadius = UDim.new(0, 4)
ModalDeleteCorner.Parent = ModalDelete

local ModalClose = Instance.new("TextButton")
ModalClose.Size = UDim2.new(0, 20, 0, 20)
ModalClose.Position = UDim2.new(1, -24, 0, 6)
ModalClose.BackgroundTransparency = 1
ModalClose.Text = "[X]"
ModalClose.TextColor3 = Color3.fromRGB(160, 160, 175)
ModalClose.TextSize = 10
ModalClose.Font = Enum.Font.GothamBold
ModalClose.ZIndex = 32
ModalClose.Parent = ModalBox

-- Detailed Inspect Modal (Dual-Pane)
local InspectorModal = Instance.new("Frame")
InspectorModal.Size = UDim2.new(1, 0, 1, 0)
InspectorModal.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
InspectorModal.BorderSizePixel = 0
InspectorModal.Visible = false
InspectorModal.ZIndex = 40
InspectorModal.Parent = Main

local InspectHeader = Instance.new("Frame")
InspectHeader.Size = UDim2.new(1, 0, 0, 32)
InspectHeader.BackgroundColor3 = Color3.fromRGB(25, 25, 32)
InspectHeader.BorderSizePixel = 0
InspectHeader.ZIndex = 41
InspectHeader.Parent = InspectorModal

local InspectTitle = Instance.new("TextLabel")
InspectTitle.Size = UDim2.new(1, -40, 1, 0)
InspectTitle.Position = UDim2.new(0, 10, 0, 0)
InspectTitle.BackgroundTransparency = 1
InspectTitle.Text = "Avatar Inspector"
InspectTitle.TextColor3 = Color3.fromRGB(235, 235, 245)
InspectTitle.TextSize = 11
InspectTitle.Font = Enum.Font.GothamBold
InspectTitle.TextXAlignment = Enum.TextXAlignment.Left
InspectTitle.ZIndex = 42
InspectTitle.Parent = InspectHeader

local InspectClose = Instance.new("TextButton")
InspectClose.Size = UDim2.new(0, 22, 0, 22)
InspectClose.Position = UDim2.new(1, -26, 0, 5)
InspectClose.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
InspectClose.Text = "[X]"
InspectClose.TextColor3 = Color3.fromRGB(200, 200, 210)
InspectClose.TextSize = 9
InspectClose.Font = Enum.Font.GothamBold
InspectClose.ZIndex = 42
InspectClose.Parent = InspectHeader

local InspectCloseCorner = Instance.new("UICorner")
InspectCloseCorner.CornerRadius = UDim.new(0, 4)
InspectCloseCorner.Parent = InspectClose

-- Left Pane: Full-Body Preview Card
local LeftPane = Instance.new("Frame")
LeftPane.Size = UDim2.new(0.38, -6, 1, -40)
LeftPane.Position = UDim2.new(0, 6, 0, 36)
LeftPane.BackgroundColor3 = Color3.fromRGB(25, 25, 32)
LeftPane.BorderSizePixel = 0
LeftPane.ZIndex = 41
LeftPane.Parent = InspectorModal

local LeftCorner = Instance.new("UICorner")
LeftCorner.CornerRadius = UDim.new(0, 6)
LeftCorner.Parent = LeftPane

local FullAvatarRender = Instance.new("ImageLabel")
FullAvatarRender.Size = UDim2.new(1, -8, 1, -8)
FullAvatarRender.Position = UDim2.new(0, 4, 0, 4)
FullAvatarRender.BackgroundTransparency = 1
FullAvatarRender.ScaleType = Enum.ScaleType.Fit
FullAvatarRender.ZIndex = 42
FullAvatarRender.Parent = LeftPane

-- Right Pane: Profile & Asset Grid
local RightPane = Instance.new("Frame")
RightPane.Size = UDim2.new(0.62, -10, 1, -40)
RightPane.Position = UDim2.new(0.38, 4, 0, 36)
RightPane.BackgroundTransparency = 1
RightPane.ZIndex = 41
RightPane.Parent = InspectorModal

-- Profile Banner (Top Right)
local ProfileCard = Instance.new("Frame")
ProfileCard.Size = UDim2.new(1, 0, 0, 44)
ProfileCard.BackgroundColor3 = Color3.fromRGB(25, 25, 32)
ProfileCard.BorderSizePixel = 0
ProfileCard.ZIndex = 42
ProfileCard.Parent = RightPane

local ProfileCorner = Instance.new("UICorner")
ProfileCorner.CornerRadius = UDim.new(0, 6)
ProfileCorner.Parent = ProfileCard

local ProfileIcon = Instance.new("ImageLabel")
ProfileIcon.Size = UDim2.new(0, 34, 0, 34)
ProfileIcon.Position = UDim2.new(0, 5, 0, 5)
ProfileIcon.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
ProfileIcon.ScaleType = Enum.ScaleType.Fit
ProfileIcon.ZIndex = 43
ProfileIcon.Parent = ProfileCard

local IconCorner = Instance.new("UICorner")
IconCorner.CornerRadius = UDim.new(1, 0)
IconCorner.Parent = ProfileIcon

local ProfileName = Instance.new("TextLabel")
ProfileName.Size = UDim2.new(1, -48, 0, 18)
ProfileName.Position = UDim2.new(0, 44, 0, 4)
ProfileName.BackgroundTransparency = 1
ProfileName.Text = "DisplayName"
ProfileName.TextColor3 = Color3.fromRGB(240, 240, 245)
ProfileName.TextSize = 10
ProfileName.Font = Enum.Font.GothamBold
ProfileName.TextXAlignment = Enum.TextXAlignment.Left
ProfileName.TextTruncate = Enum.TextTruncate.AtEnd
ProfileName.ZIndex = 43
ProfileName.Parent = ProfileCard

local ProfileUser = Instance.new("TextLabel")
ProfileUser.Size = UDim2.new(1, -48, 0, 16)
ProfileUser.Position = UDim2.new(0, 44, 0, 22)
ProfileUser.BackgroundTransparency = 1
ProfileUser.Text = "@Username"
ProfileUser.TextColor3 = Color3.fromRGB(140, 140, 155)
ProfileUser.TextSize = 9
ProfileUser.Font = Enum.Font.Gotham
ProfileUser.TextXAlignment = Enum.TextXAlignment.Left
ProfileUser.TextTruncate = Enum.TextTruncate.AtEnd
ProfileUser.ZIndex = 43
ProfileUser.Parent = ProfileCard

-- Asset Items Scroll Grid (Bottom Right)
local AssetGridList = Instance.new("ScrollingFrame")
AssetGridList.Size = UDim2.new(1, 0, 1, -50)
AssetGridList.Position = UDim2.new(0, 0, 0, 50)
AssetGridList.BackgroundTransparency = 1
AssetGridList.BorderSizePixel = 0
AssetGridList.ScrollBarThickness = 2
AssetGridList.ScrollBarImageColor3 = Color3.fromRGB(60, 60, 75)
AssetGridList.AutomaticCanvasSize = Enum.AutomaticSize.Y
AssetGridList.ZIndex = 42
AssetGridList.Parent = RightPane

local AssetGridLayout = Instance.new("UIGridLayout")
AssetGridLayout.CellSize = UDim2.new(0, 62, 0, 78)
AssetGridLayout.CellPadding = UDim2.new(0, 6, 0, 6)
AssetGridLayout.SortOrder = Enum.SortOrder.LayoutOrder
AssetGridLayout.Parent = AssetGridList

-- Confirmation Modal Frame
local ConfirmFrame = Instance.new("Frame")
ConfirmFrame.Size = UDim2.new(1, -20, 0, 70)
ConfirmFrame.Position = UDim2.new(0, 10, 0, 130)
ConfirmFrame.BackgroundColor3 = Color3.fromRGB(32, 32, 40)
ConfirmFrame.BorderSizePixel = 0
ConfirmFrame.Visible = false
ConfirmFrame.ZIndex = 50
ConfirmFrame.Parent = Main

local ConfirmCorner = Instance.new("UICorner")
ConfirmCorner.CornerRadius = UDim.new(0, 8)
ConfirmCorner.Parent = ConfirmFrame

local ConfirmText = Instance.new("TextLabel")
ConfirmText.Size = UDim2.new(1, -10, 0, 24)
ConfirmText.Position = UDim2.new(0, 5, 0, 4)
ConfirmText.BackgroundTransparency = 1
ConfirmText.Text = "Confirm action?"
ConfirmText.TextColor3 = Color3.fromRGB(240, 240, 245)
ConfirmText.TextSize = 10
ConfirmText.Font = Enum.Font.GothamBold
ConfirmText.ZIndex = 51
ConfirmText.Parent = ConfirmFrame

local CancelButton = Instance.new("TextButton")
CancelButton.Size = UDim2.new(0.5, -6, 0, 26)
CancelButton.Position = UDim2.new(0, 4, 0, 36)
CancelButton.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
CancelButton.Text = "CANCEL"
CancelButton.TextColor3 = Color3.fromRGB(255, 255, 255)
CancelButton.TextSize = 9
CancelButton.Font = Enum.Font.GothamBold
CancelButton.ZIndex = 51
CancelButton.Parent = ConfirmFrame

local CancelCorner = Instance.new("UICorner")
CancelCorner.CornerRadius = UDim.new(0, 4)
CancelCorner.Parent = CancelButton

local ConfirmAction = Instance.new("TextButton")
ConfirmAction.Size = UDim2.new(0.5, -6, 0, 26)
ConfirmAction.Position = UDim2.new(0.5, 2, 0, 36)
ConfirmAction.BackgroundColor3 = Color3.fromRGB(150, 50, 50)
ConfirmAction.Text = "CONFIRM"
ConfirmAction.TextColor3 = Color3.fromRGB(255, 255, 255)
ConfirmAction.TextSize = 9
ConfirmAction.Font = Enum.Font.GothamBold
ConfirmAction.ZIndex = 51
ConfirmAction.Parent = ConfirmFrame

local ConfirmActionCorner = Instance.new("UICorner")
ConfirmActionCorner.CornerRadius = UDim.new(0, 4)
ConfirmActionCorner.Parent = ConfirmAction

-- Selection Popover Frame
local SelectFrame = Instance.new("Frame")
SelectFrame.Size = UDim2.new(0, 200, 0, 74)
SelectFrame.Position = UDim2.new(0.5, -100, 0.8, 0)
SelectFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 38)
SelectFrame.BorderSizePixel = 0
SelectFrame.Visible = false
SelectFrame.ZIndex = 60
SelectFrame.Parent = ScreenGui

local SelectCorner = Instance.new("UICorner")
SelectCorner.CornerRadius = UDim.new(0, 8)
SelectCorner.Parent = SelectFrame

local SelectedName = Instance.new("TextLabel")
SelectedName.Size = UDim2.new(1, -16, 0, 22)
SelectedName.Position = UDim2.new(0, 8, 0, 4)
SelectedName.BackgroundTransparency = 1
SelectedName.Text = "@Player"
SelectedName.TextColor3 = Color3.fromRGB(255, 255, 255)
SelectedName.TextSize = 11
SelectedName.Font = Enum.Font.GothamBold
SelectedName.TextXAlignment = Enum.TextXAlignment.Left
SelectedName.TextTruncate = Enum.TextTruncate.AtEnd
SelectedName.ZIndex = 61
SelectedName.Parent = SelectFrame

local HoldButton = Instance.new("TextButton")
HoldButton.Size = UDim2.new(1, -80, 0, 30)
HoldButton.Position = UDim2.new(0, 8, 0, 32)
HoldButton.BackgroundColor3 = Color3.fromRGB(55, 95, 175)
HoldButton.Text = "HOLD TO COPY"
HoldButton.TextColor3 = Color3.fromRGB(255, 255, 255)
HoldButton.TextSize = 10
HoldButton.Font = Enum.Font.GothamBold
HoldButton.ZIndex = 61
HoldButton.Parent = SelectFrame

local HoldCorner = Instance.new("UICorner")
HoldCorner.CornerRadius = UDim.new(0, 5)
HoldCorner.Parent = HoldButton

local SelectCancel = Instance.new("TextButton")
SelectCancel.Size = UDim2.new(0, 58, 0, 30)
SelectCancel.Position = UDim2.new(1, -66, 0, 32)
SelectCancel.BackgroundColor3 = Color3.fromRGB(85, 45, 45)
SelectCancel.Text = "CANCEL"
SelectCancel.TextColor3 = Color3.fromRGB(255, 255, 255)
SelectCancel.TextSize = 9
SelectCancel.Font = Enum.Font.GothamBold
SelectCancel.ZIndex = 61
SelectCancel.Parent = SelectFrame

local SelectCancelCorner = Instance.new("UICorner")
SelectCancelCorner.CornerRadius = UDim.new(0, 5)
SelectCancelCorner.Parent = SelectCancel

-- Dragging Behavior
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

-- Helper Functions
local function updateStatus()
	Status.Text = "Saved Avatars: " .. tostring(#copiedAvatars)
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
	if not IS_CATALOG_GAME or not data then return end
	local wearPayload = {{
		["Properties"] = data.Properties,
		["Action"] = "CreateAndWearHumanoidDescription",
		["RigType"] = data.RigType
	}}

	pcall(function()
		catalogGuiRemote:InvokeServer(unpack(wearPayload))
	end)
end

local function saveCurrentOutfit()
	if not IS_CATALOG_GAME then return end
	pcall(function()
		savedOutfitsRemote:InvokeServer({
			OutfitName = "Saved Outfit",
			Configs = {},
			Action = "CreateNewOutfit"
		})
	end)
	Status.Text = "Current outfit saved!"
	task.delay(2, updateStatus)
end

local function destroyScriptAndUI()
	for _, conn in ipairs(connections) do
		if conn and conn.Connected then conn:Disconnect() end
	end
	table.clear(connections)
	ScreenGui:Destroy()
end

local function populateAssetInspector(data)
	for _, child in ipairs(AssetGridList:GetChildren()) do
		if child:IsA("Frame") then child:Destroy() end
	end

	ProfileName.Text = data.DisplayName or data.Name
	ProfileUser.Text = "@" .. data.Name
	ProfileIcon.Image = "rbxthumb://type=AvatarBust&id=" .. tostring(data.UserId or 1) .. "&w=420&h=420"
	FullAvatarRender.Image = "rbxthumb://type=AvatarBust&id=" .. tostring(data.UserId or 1) .. "&w=420&h=420"

	local function addAssetCard(assetId)
		if not assetId or assetId == 0 or assetId == "" then return end

		local AssetCard = Instance.new("Frame")
		AssetCard.Size = UDim2.new(0, 62, 0, 78)
		AssetCard.BackgroundColor3 = Color3.fromRGB(25, 25, 32)
		AssetCard.BorderSizePixel = 0
		AssetCard.ZIndex = 43
		AssetCard.Parent = AssetGridList

		local CardCorner = Instance.new("UICorner")
		CardCorner.CornerRadius = UDim.new(0, 5)
		CardCorner.Parent = AssetCard

		local AssetThumb = Instance.new("ImageLabel")
		AssetThumb.Size = UDim2.new(1, -6, 0, 50)
		AssetThumb.Position = UDim2.new(0, 3, 0, 3)
		AssetThumb.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
		AssetThumb.Image = "rbxthumb://type=Asset&id=" .. tostring(assetId) .. "&w=420&h=420"
		AssetThumb.ScaleType = Enum.ScaleType.Fit
		AssetThumb.ZIndex = 44
		AssetThumb.Parent = AssetCard

		local ThumbCorner = Instance.new("UICorner")
		ThumbCorner.CornerRadius = UDim.new(0, 4)
		ThumbCorner.Parent = AssetThumb

		local CopyBtn = Instance.new("TextButton")
		CopyBtn.Size = UDim2.new(1, -6, 0, 18)
		CopyBtn.Position = UDim2.new(0, 3, 0, 56)
		CopyBtn.BackgroundColor3 = Color3.fromRGB(55, 95, 175)
		CopyBtn.Text = "COPY ID"
		CopyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
		CopyBtn.TextSize = 7
		CopyBtn.Font = Enum.Font.GothamBold
		CopyBtn.ZIndex = 44
		CopyBtn.Parent = AssetCard

		local CopyCorner = Instance.new("UICorner")
		CopyCorner.CornerRadius = UDim.new(0, 3)
		CopyCorner.Parent = CopyBtn

		CopyBtn.Activated:Connect(function()
			if setclipboard then
				setclipboard(tostring(assetId))
				CopyBtn.Text = "COPIED"
				CopyBtn.BackgroundColor3 = Color3.fromRGB(46, 125, 85)
				task.delay(1.2, function()
					CopyBtn.Text = "COPY ID"
					CopyBtn.BackgroundColor3 = Color3.fromRGB(55, 95, 175)
				end)
			end
		end)
	end

	local props = data.Properties or {}
	local singleProperties = {
		"Shirt", "Pants", "GraphicTShirt", "Face", "Head", "Torso", 
		"LeftArm", "RightArm", "LeftLeg", "RightLeg", "Eyes", "Lips"
	}

	for _, propKey in ipairs(singleProperties) do
		if props[propKey] and tonumber(props[propKey]) and tonumber(props[propKey]) > 0 then
			addAssetCard(props[propKey])
		end
	end

	local accessoryTypes = {
		"HatAccessory", "HairAccessory", "FaceAccessory", "NeckAccessory",
		"ShouldersAccessory", "FrontAccessory", "BackAccessory", "WaistAccessory"
	}

	for _, accKey in ipairs(accessoryTypes) do
		if props[accKey] and props[accKey] ~= "" then
			for id in string.gmatch(tostring(props[accKey]), "%d+") do
				addAssetCard(id)
			end
		end
	end

	if props.LayeredAccessories and type(props.LayeredAccessories) == "table" then
		for _, layered in ipairs(props.LayeredAccessories) do
			if layered.AssetId then
				addAssetCard(layered.AssetId)
			end
		end
	end

	InspectorModal.Visible = true
end

local function deleteAvatarEntry(data)
	for i, item in ipairs(copiedAvatars) do
		if item == data then
			if item.UI then item.UI:Destroy() end
			table.remove(copiedAvatars, i)
			break
		end
	end
	saveToWorkspace()
	updateStatus()
end

local function createAvatarCard(data, index)
	local Card = Instance.new("Frame")
	Card.Size = UDim2.new(0, cardCellWidth, 0, 120)
	Card.BackgroundColor3 = Color3.fromRGB(28, 28, 36)
	Card.BorderSizePixel = 0
	Card.LayoutOrder = index
	Card.ClipsDescendants = true
	Card.Parent = List

	local Corner = Instance.new("UICorner")
	Corner.CornerRadius = UDim.new(0, 6)
	Corner.Parent = Card

	local CardStroke = Instance.new("UIStroke")
	CardStroke.Color = Color3.fromRGB(40, 40, 50)
	CardStroke.Thickness = 1
	CardStroke.Parent = Card

	local Thumbnail = Instance.new("ImageLabel")
	Thumbnail.Size = UDim2.new(1, -8, 0, 82)
	Thumbnail.Position = UDim2.new(0, 4, 0, 4)
	Thumbnail.BackgroundColor3 = Color3.fromRGB(20, 20, 26)
	Thumbnail.Image = "rbxthumb://type=AvatarBust&id=" .. tostring(data.UserId or 1) .. "&w=420&h=420"
	Thumbnail.ScaleType = Enum.ScaleType.Fit
	Thumbnail.Parent = Card

	local ThumbCorner = Instance.new("UICorner")
	ThumbCorner.CornerRadius = UDim.new(0, 4)
	ThumbCorner.Parent = Thumbnail

	local NameLabel = Instance.new("TextLabel")
	NameLabel.Size = UDim2.new(1, -6, 0, 26)
	NameLabel.Position = UDim2.new(0, 3, 0, 90)
	NameLabel.BackgroundTransparency = 1
	NameLabel.Text = "@" .. data.Name
	NameLabel.TextColor3 = Color3.fromRGB(230, 230, 240)
	NameLabel.TextSize = 9
	NameLabel.Font = Enum.Font.GothamBold
	NameLabel.TextTruncate = Enum.TextTruncate.AtEnd
	NameLabel.Parent = Card

	local CardButton = Instance.new("TextButton")
	CardButton.Size = UDim2.new(1, 0, 1, 0)
	CardButton.BackgroundTransparency = 1
	CardButton.Text = ""
	CardButton.Parent = Card

	data.UI = Card
	data.NameLabel = NameLabel

	CardButton.Activated:Connect(function()
		currentActiveData = data
		ModalTitle.Text = "@" .. data.Name
		ActionModal.Visible = true
	end)
end

local function updateOrders()
	for index, data in ipairs(copiedAvatars) do
		data.Order = index
		if data.UI and data.UI.Parent then
			data.UI.LayoutOrder = index
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
			createAvatarCard(data, index)
		end
		updateStatus()
	end
end

local function clearCopiedFits()
	for _, data in ipairs(copiedAvatars) do
		if data.UI then data.UI:Destroy() end
	end
	table.clear(copiedAvatars)
	if delfile and isfile and isfile(FILE_PATH) then
		pcall(function() delfile(FILE_PATH) end)
	end
	updateStatus()
	Status.Text = "Saved avatars cleared!"
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
			UserId = targetPlayer.UserId,
			DisplayName = targetPlayer.DisplayName,
			Properties = properties,
			RigType = humanoid.RigType,
			Signature = getAvatarSignature(properties, humanoid.RigType),
			Order = 1
		}
	end)

	if not success then
		copying = false
		return
	end

	for _, existing in ipairs(copiedAvatars) do
		if existing.Signature == data.Signature then
			Status.Text = "Already saved!"
			task.delay(2, updateStatus)
			copying = false
			return
		end
	end

	table.insert(copiedAvatars, 1, data)
	createAvatarCard(data, 1)
	updateOrders()
	updateStatus()

	Status.Text = "Saved @" .. data.Name .. "!"
	task.delay(2, updateStatus)

	task.delay(0.3, function() copying = false end)
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
	if player then selectPlayer(player) end
end

-- Input Connections
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

				task.delay(0.5, hideSelectFrame)
				break
			end
			task.wait()
		end
	end)
end

HoldButton.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		beginHold()
	end
end)

HoldButton.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		holdingCopy = false
		if selectedPlayer then HoldButton.Text = "HOLD TO COPY" end
	end
end)

-- UI Interactions & Confirm Mechanics
SelectCancel.Activated:Connect(hideSelectFrame)

CopySelfBtn.Activated:Connect(function()
	copyForStorage(LocalPlayer)
end)

if IS_CATALOG_GAME then
	SaveButton.Activated:Connect(function()
		ConfirmText.Text = "Save your current outfit?"
		currentConfirmAction = saveCurrentOutfit

		ConfirmFrame.Visible = true
		SaveButton.Visible = false
		CopySelfBtn.Visible = false
		ClearButton.Visible = false
		UnloadButton.Visible = false
		Status.Visible = false
		ListContainer.Visible = false
	end)
end

ModalClose.Activated:Connect(function()
	ActionModal.Visible = false
	currentActiveData = nil
end)

ModalWear.Activated:Connect(function()
	if IS_CATALOG_GAME and currentActiveData then
		wearCopiedAvatar(currentActiveData)
		ActionModal.Visible = false
	end
end)

ModalInspect.Activated:Connect(function()
	if currentActiveData then
		ActionModal.Visible = false
		populateAssetInspector(currentActiveData)
	end
end)

ModalDelete.Activated:Connect(function()
	if currentActiveData then
		local dataToDelete = currentActiveData
		ActionModal.Visible = false
		ConfirmText.Text = "Delete @" .. dataToDelete.Name .. "?"
		currentConfirmAction = function() deleteAvatarEntry(dataToDelete) end

		ConfirmFrame.Visible = true
		SaveButton.Visible = false
		CopySelfBtn.Visible = false
		ClearButton.Visible = false
		UnloadButton.Visible = false
		Status.Visible = false
		ListContainer.Visible = false
	end
end)

InspectClose.Activated:Connect(function()
	InspectorModal.Visible = false
end)

ClearButton.Activated:Connect(function()
	if #copiedAvatars == 0 then
		Status.Text = "Nothing to clear!"
		task.delay(2, updateStatus)
		return
	end

	ConfirmText.Text = "Clear all saved fits?"
	currentConfirmAction = clearCopiedFits

	ConfirmFrame.Visible = true
	SaveButton.Visible = false
	CopySelfBtn.Visible = false
	ClearButton.Visible = false
	UnloadButton.Visible = false
	Status.Visible = false
	ListContainer.Visible = false
end)

UnloadButton.Activated:Connect(function()
	ConfirmText.Text = "Destroy UI and unload?"
	currentConfirmAction = destroyScriptAndUI

	ConfirmFrame.Visible = true
	SaveButton.Visible = false
	CopySelfBtn.Visible = false
	ClearButton.Visible = false
	UnloadButton.Visible = false
	Status.Visible = false
	ListContainer.Visible = false
end)

CancelButton.Activated:Connect(function()
	ConfirmFrame.Visible = false
	SaveButton.Visible = true
	CopySelfBtn.Visible = true
	ClearButton.Visible = true
	UnloadButton.Visible = true
	Status.Visible = true
	ListContainer.Visible = true
	currentConfirmAction = nil
	updateStatus()
end)

ConfirmAction.Activated:Connect(function()
	ConfirmFrame.Visible = false
	SaveButton.Visible = true
	CopySelfBtn.Visible = true
	ClearButton.Visible = true
	UnloadButton.Visible = true
	Status.Visible = true
	ListContainer.Visible = true

	if currentConfirmAction then
		currentConfirmAction()
		currentConfirmAction = nil
	end
end)

Minimize.Activated:Connect(function()
	minimized = not minimized
	if minimized then
		hideSelectFrame()
		applyTween(Main, {Size = UDim2.new(0, 180, 0, 38)})

		WarningBanner.Visible = false
		SaveButton.Visible = false
		CopySelfBtn.Visible = false
		ClearButton.Visible = false
		UnloadButton.Visible = false
		Status.Visible = false
		ListContainer.Visible = false
		ConfirmFrame.Visible = false
		ActionModal.Visible = false
		InspectorModal.Visible = false
		Minimize.Text = "+"
	else
		applyTween(Main, {Size = UDim2.new(0, mainWidth, 0, mainHeight)})
		WarningBanner.Visible = not IS_CATALOG_GAME
		SaveButton.Visible = true
		CopySelfBtn.Visible = true
		ClearButton.Visible = true
		UnloadButton.Visible = true
		Status.Visible = true
		ListContainer.Visible = true
		Minimize.Text = "-"
		updateStatus()
	end
end)

-- Boot System
loadFromWorkspace()
updateStatus()
