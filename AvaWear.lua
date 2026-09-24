-- [[ Made by Knightingale | ScriptBlox.com ]] --
-- Official script V1.71 (71 versions and fixes loll)

local success, err = pcall(function()

local function getService(name)
	local ok, service = pcall(function()
		local s = game:GetService(name)
		return (type(cloneref) == "function") and cloneref(s) or s
	end)
	return ok and service or game:GetService(name)
end

local Players = getService("Players")
local HttpService = getService("HttpService")
local UserInputService = getService("UserInputService")
local RunService = getService("RunService")
local ContentProvider = getService("ContentProvider")
local TweenService = getService("TweenService")
local Workspace = getService("Workspace")
local CoreGui = getService("CoreGui")
local InsertService = getService("InsertService")

local LocalPlayer = Players.LocalPlayer
if not LocalPlayer then
	error("LocalPlayer was not available.")
end

local FOLDER_NAME = "Avatar Saver v2"
local FILE_PATH = FOLDER_NAME .. "/SavedAvatars.json"
local SCREEN_GUI_NAME = "LocalWearer_UI"

local runtimeConnections = {}
local scriptAlive = true
local tryOnActive = false
local localTryOnModel = nil
local hiddenCharacterParts = {}
local hiddenCharacterDecals = {}
local localTryOnConnections = {}
local localTryOnRootPart = nil
local localTryOnGroundOffset = Vector3.zero
local localTryOnGroundOffsetValid = false
local localTryOnNeutralCloneFeetRootOffsetY = nil
local localTryOnSwimOffset = Vector3.zero
local currentVerticalOffset = Vector3.zero
local localTryOnSeatedHipOffsetLocal = Vector3.zero
local localTryOnSeatedHipOffsetValid = false
local localTryOnSeatTransitionActive = false
local localTryOnSeatTransitionStartLocal = Vector3.zero
local localTryOnSeatTransitionStartedAt = 0
local localTryOnSwimTransitionActive = false
local localTryOnSwimTransitionStart = Vector3.zero
local localTryOnSwimTransitionStartedAt = 0
local localTryOnLastSwimming = false
local localTryOnSeatPart = nil
local localTryOnPositionMode = "Ground"
local localTryOnSeatCalibrationPending = false
local localTryOnSeatCalibrationToken = 0
local localTryOnGroundCalibrationFrames = 0
local localTryOnHiddenInFirstPerson = false
local localTryOnBuilding = false
local localTryOnBuildId = 0
local localTryOnMissingRecoveryPending = false
local localTryOnCollisionParts = {}
local deathConnection = nil
local characterAddedConnection = nil
local searchDebounceThread = nil

local activeCloneTracks = {}
local activeCloneStopConnections = {}
local activeCloneEmoteAnimations = {}
local activeEmotePlayerTrack = nil
local animPlayedConnection = nil
local emoteAssetAnimationCache = {}

local function parseAssetId(val)
	if not val then return nil end
	if type(val) == "number" then return val > 0 and val or nil end
	local digits = string.match(tostring(val), "%d+")
	return digits and tonumber(digits) or nil
end

local function cloneEmoteTable(emotes)
	local copy = {}
	if type(emotes) ~= "table" then return copy end
	for name, ids in pairs(emotes) do
		if type(name) == "string" and type(ids) == "table" then
			local idList = {}
			for _, assetId in ipairs(ids) do
				local parsed = parseAssetId(assetId)
				if parsed then idList[#idList + 1] = parsed end
			end
			if #idList > 0 then copy[name] = idList end
		end
	end
	return copy
end

local BLUE_NORMAL = Color3.fromRGB(25, 115, 230)
local BLUE_HOVER = Color3.fromRGB(45, 135, 255)
local GREEN_NORMAL = Color3.fromRGB(35, 175, 80)
local GREEN_HOVER = Color3.fromRGB(50, 200, 95)

local R6_DEFAULTS = {
	Idle = "rbxassetid://180435571",
	Walk = "rbxassetid://180426354",
	Run = "rbxassetid://180426354",
	Jump = "rbxassetid://125750702",
	Fall = "rbxassetid://180436148",
	Climb = "rbxassetid://180436334",
	Swim = "rbxassetid://180426354",
	SwimIdle = "rbxassetid://180435571",
	Sit = "rbxassetid://178130996"
}

local R15_DEFAULTS = {
	Idle = "rbxassetid://507766388",
	Walk = "rbxassetid://913403211",
	Run = "rbxassetid://913384386",
	Jump = "rbxassetid://507765000",
	Fall = "rbxassetid://507767968",
	Climb = "rbxassetid://507765644",
	Swim = "rbxassetid://913389285",
	SwimIdle = "rbxassetid://507785072",
	Sit = "rbxassetid://507768133"
}

local R6_EMOTE_LIBRARY = {
	wave = { "rbxassetid://128777973" },
	point = { "rbxassetid://128853357" },
	dance = {
		"rbxassetid://182435998",
		"rbxassetid://182491037",
		"rbxassetid://182491065"
	},
	dance1 = {
		"rbxassetid://182435998",
		"rbxassetid://182491037",
		"rbxassetid://182491065"
	},
	dance2 = {
		"rbxassetid://182436842",
		"rbxassetid://182491248",
		"rbxassetid://182491277"
	},
	dance3 = {
		"rbxassetid://182436935",
		"rbxassetid://182491368",
		"rbxassetid://182491423"
	},
	laugh = { "rbxassetid://129423131" },
	cheer = { "rbxassetid://129423030" }
}

local R6_EMOTE_LOOPED = {
	wave = false,
	point = false,
	dance = true,
	dance1 = true,
	dance2 = true,
	dance3 = true,
	laugh = false,
	cheer = false
}

local PLAYER_LEGACY_EMOTE_IDS = {
	["507770239"] = "wave",
	["507770453"] = "point",
	["507771019"] = "dance",
	["507771955"] = "dance",
	["507772104"] = "dance",
	["507776043"] = "dance2",
	["507776720"] = "dance2",
	["507776879"] = "dance2",
	["507777268"] = "dance3",
	["507777451"] = "dance3",
	["507777623"] = "dance3",
	["507770818"] = "laugh",
	["507770677"] = "cheer",
}

for emoteName, assetList in pairs(R6_EMOTE_LIBRARY) do
	for _, assetId in ipairs(assetList) do
		local parsed = parseAssetId(assetId)
		if parsed then PLAYER_LEGACY_EMOTE_IDS[tostring(parsed)] = emoteName end
	end
end

local previewQueue = {}
local previewQueueRunning = false
local previewQueueGeneration = 0
local previewStates = {}

local previewModelCache = {}
local previewCacheOrder = {}
local PREVIEW_CACHE_LIMIT = 24

local function getPreviewCacheKey(data)
	if not data then return nil end
	local stableId = data.Signature or data.FileName or data.UserId or data.Name
	if stableId ~= nil then
		return tostring(stableId) .. "|" .. tostring(data.RigType)
	end
	local ok, encoded = pcall(function()
		return HttpService:JSONEncode({
			Properties = data.Properties,
			RigType = tostring(data.RigType)
		})
	end)
	if ok and encoded then return encoded end
	return tostring(data)
end

local function clearPreviewModelCache()
	for key, model in pairs(previewModelCache) do
		pcall(function() if model then model:Destroy() end end)
		previewModelCache[key] = nil
	end
	table.clear(previewCacheOrder)
end

local function touchPreviewCache(key)
	for i = #previewCacheOrder, 1, -1 do
		if previewCacheOrder[i] == key then table.remove(previewCacheOrder, i) end
	end
	table.insert(previewCacheOrder, key)
	while #previewCacheOrder > PREVIEW_CACHE_LIMIT do
		local oldKey = table.remove(previewCacheOrder, 1)
		local oldModel = previewModelCache[oldKey]
		previewModelCache[oldKey] = nil
		pcall(function() if oldModel then oldModel:Destroy() end end)
	end
end

local function wire(signal, callback)
	local connection = signal:Connect(callback)
	runtimeConnections[#runtimeConnections + 1] = connection
	return connection
end

local function disconnectConnection(connection)
	if connection then
		pcall(function()
			if connection.Connected then connection:Disconnect() end
		end)
	end
end

local function setLocalTryOnConnection(name, signal, callback)
	disconnectConnection(localTryOnConnections[name])
	if signal and callback then
		localTryOnConnections[name] = signal:Connect(callback)
	else
		localTryOnConnections[name] = nil
	end
	return localTryOnConnections[name]
end

local function disconnectLocalTryOnConnections()
	for name, connection in pairs(localTryOnConnections) do
		disconnectConnection(connection)
		localTryOnConnections[name] = nil
	end
	table.clear(localTryOnCollisionParts)
end

local function resetLocalTryOnState()
	localTryOnRootPart = nil
	localTryOnGroundOffset = Vector3.zero
	localTryOnGroundOffsetValid = false
	localTryOnNeutralCloneFeetRootOffsetY = nil
	localTryOnSwimOffset = Vector3.zero
	currentVerticalOffset = Vector3.zero
	localTryOnSeatedHipOffsetLocal = Vector3.zero
	localTryOnSeatedHipOffsetValid = false
	localTryOnSeatTransitionActive = false
	localTryOnSeatTransitionStartLocal = Vector3.zero
	localTryOnSeatTransitionStartedAt = 0
	localTryOnSwimTransitionActive = false
	localTryOnSwimTransitionStart = Vector3.zero
	localTryOnSwimTransitionStartedAt = 0
	localTryOnLastSwimming = false
	localTryOnSeatPart = nil
	localTryOnPositionMode = "Ground"
	localTryOnSeatCalibrationPending = false
	localTryOnSeatCalibrationToken = localTryOnSeatCalibrationToken + 1
	localTryOnGroundCalibrationFrames = 0
	localTryOnHiddenInFirstPerson = false
end

local function vector3FromSaved(value, fallback)
	if typeof(value) == "Vector3" then return value end
	if type(value) == "table" then
		return Vector3.new(
			tonumber(value.X or value.x) or fallback.X,
			tonumber(value.Y or value.y) or fallback.Y,
			tonumber(value.Z or value.z) or fallback.Z
		)
	end
	return fallback
end

local function getEnumRigType(value)
	if typeof(value) == "EnumItem" then return value end
	local text = tostring(value or "")
	if text:find("R6") then return Enum.HumanoidRigType.R6 end
	return Enum.HumanoidRigType.R15
end

local function stopAllCloneTracks(fadeTime)
	for _, stoppedConnection in pairs(activeCloneStopConnections) do
		disconnectConnection(stoppedConnection)
	end
	table.clear(activeCloneStopConnections)

	for playerTrack, cloneTrack in pairs(activeCloneTracks) do
		pcall(function() cloneTrack:Stop(fadeTime or 0.05) end)
		local animation = activeCloneEmoteAnimations[playerTrack]
		if animation then pcall(function() animation:Destroy() end) end
		activeCloneEmoteAnimations[playerTrack] = nil
	end
	table.clear(activeCloneTracks)
	table.clear(activeCloneEmoteAnimations)
	activeEmotePlayerTrack = nil
end

local function cleanupAnimationSync()
	stopAllCloneTracks()
	disconnectConnection(animPlayedConnection)
	animPlayedConnection = nil
end

local function cleanup()
	scriptAlive = false
	localTryOnBuildId = localTryOnBuildId + 1
	localTryOnBuilding = false
	tryOnActive = false
	cleanupAnimationSync()

	if searchDebounceThread then
		task.cancel(searchDebounceThread)
		searchDebounceThread = nil
	end

	previewQueueGeneration = previewQueueGeneration + 1
	clearPreviewModelCache()
	table.clear(previewQueue)
	table.clear(previewStates)
	previewQueueRunning = false

	disconnectConnection(deathConnection)
	deathConnection = nil
	disconnectConnection(characterAddedConnection)
	characterAddedConnection = nil
	disconnectLocalTryOnConnections()

	pcall(function() if localTryOnModel then localTryOnModel:Destroy() end end)
	localTryOnModel = nil
	resetLocalTryOnState()

	for part, oldTransparency in pairs(hiddenCharacterParts) do
		pcall(function()
			if part and part.Parent then
				part.LocalTransparencyModifier = oldTransparency
			end
		end)
	end
	table.clear(hiddenCharacterParts)

	for decal, oldTransparency in pairs(hiddenCharacterDecals) do
		pcall(function()
			if decal and decal.Parent then
				decal.Transparency = oldTransparency
			end
		end)
	end
	table.clear(hiddenCharacterDecals)

	for _, connection in ipairs(runtimeConnections) do
		disconnectConnection(connection)
	end
	table.clear(runtimeConnections)

	pcall(function()
		local roots = {}
		if type(gethui) == "function" then table.insert(roots, gethui()) end
		table.insert(roots, CoreGui)
		if LocalPlayer then table.insert(roots, LocalPlayer:FindFirstChildOfClass("PlayerGui")) end
		for _, root in ipairs(roots) do
			if root then
				local ui = root:FindFirstChild(SCREEN_GUI_NAME)
				if ui then ui:Destroy() end
			end
		end
	end)

	pcall(function()
		if type(getgenv) == "function" and getgenv().__LocalWearerCleanup == cleanup then
			getgenv().__LocalWearerCleanup = nil
		end
	end)
end

pcall(function()
	if type(getgenv) == "function" and type(getgenv().__LocalWearerCleanup) == "function" then
		pcall(getgenv().__LocalWearerCleanup)
	end
end)

cleanup()
scriptAlive = true

pcall(function()
	if type(getgenv) == "function" then
		getgenv().__LocalWearerCleanup = cleanup
	end
end)

local camera = Workspace.CurrentCamera
local viewportSize = camera and camera.ViewportSize or Vector2.new(1024, 768)
local isMobile = (viewportSize.X < 700 or viewportSize.Y < 500)

local mainWidth = isMobile and 300 or 340
local mainHeight = isMobile and 290 or 330
local minimizedWidth = 160

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = SCREEN_GUI_NAME
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true

local parented = false
if type(gethui) == "function" then
	pcall(function() ScreenGui.Parent = gethui() parented = true end)
end
if not parented then
	pcall(function() ScreenGui.Parent = CoreGui parented = true end)
end
if not parented then
	local playerGui = LocalPlayer:FindFirstChildOfClass("PlayerGui")
	if playerGui then ScreenGui.Parent = playerGui parented = true end
end
if not parented then error("Unable to create Local Wearer UI.") end

local savedAvatars = {}
local selectedAvatar = nil
local avatarCards = {}

local function addCorner(parent, radius)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius or 6)
	corner.Parent = parent
	return corner
end

local function addStroke(parent, color, thickness)
	local stroke = Instance.new("UIStroke")
	stroke.Color = color or Color3.fromRGB(55, 55, 70)
	stroke.Thickness = thickness or 1
	stroke.Parent = parent
	return stroke
end

local function createButton(parent, name, text, baseColor, hoverColor)
	local button = Instance.new("TextButton")
	button.Name = name
	local normalColor = baseColor or Color3.fromRGB(35, 38, 48)
	local hover = hoverColor or Color3.fromRGB(48, 52, 66)

	button.BackgroundColor3 = normalColor
	button.BorderSizePixel = 0
	button.Text = text
	button.TextColor3 = Color3.fromRGB(255, 255, 255)
	button.TextSize = isMobile and 9 or 10
	button.Font = Enum.Font.GothamBold
	button.AutoButtonColor = false
	button.Active = true
	button.Parent = parent
	addCorner(button, 6)
	addStroke(button, Color3.fromRGB(60, 62, 78), 1)

	wire(button.MouseEnter, function() TweenService:Create(button, TweenInfo.new(0.15), {BackgroundColor3 = hover}):Play() end)
	wire(button.MouseLeave, function() TweenService:Create(button, TweenInfo.new(0.15), {BackgroundColor3 = normalColor}):Play() end)
	return button
end

local Main = Instance.new("Frame")
Main.Name = "Main"
Main.Size = UDim2.new(0, mainWidth, 0, mainHeight)
Main.Position = UDim2.new(0.5, -mainWidth / 2, 0.5, -mainHeight / 2)
Main.BackgroundColor3 = Color3.fromRGB(22, 22, 28)
Main.BorderSizePixel = 0
Main.ClipsDescendants = true
Main.Active = true
Main.Parent = ScreenGui
addCorner(Main, 10)
addStroke(Main, Color3.fromRGB(50, 50, 65), 1)

local TitleBar = Instance.new("Frame")
TitleBar.Name = "TitleBar"
TitleBar.Size = UDim2.new(1, 0, 0, 36)
TitleBar.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
TitleBar.BorderSizePixel = 0
TitleBar.ZIndex = 10
TitleBar.Active = true
TitleBar.Parent = Main
addCorner(TitleBar, 10)

local Title = Instance.new("TextLabel")
Title.Name = "Title"
Title.Size = UDim2.new(1, -60, 1, 0)
Title.Position = UDim2.new(0, 12, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "Local Wearer"
Title.TextColor3 = Color3.fromRGB(240, 240, 250)
Title.TextSize = isMobile and 11 or 13
Title.Font = Enum.Font.GothamBold
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.ZIndex = 11
Title.Parent = TitleBar

local Watermark = Instance.new("TextLabel")
Watermark.Name = "Watermark"
Watermark.Size = UDim2.new(1, (isMobile and -178 or -190), 1, 0)
Watermark.Position = UDim2.new(0, isMobile and 138 or 158, 0, 0)
Watermark.BackgroundTransparency = 1
Watermark.Text = "| Made by Knightingale\n| More on ScriptBlox.com"
Watermark.TextColor3 = Color3.fromRGB(120, 120, 135)
Watermark.TextSize = isMobile and 7 or 8
Watermark.Font = Enum.Font.GothamMedium
Watermark.TextXAlignment = Enum.TextXAlignment.Left
Watermark.TextYAlignment = Enum.TextYAlignment.Center
Watermark.TextTruncate = Enum.TextTruncate.AtEnd
Watermark.ZIndex = 11
Watermark.Parent = TitleBar

local WatermarkEmojiButton = Instance.new("TextButton")
WatermarkEmojiButton.Name = "WatermarkEmojiButton"
WatermarkEmojiButton.Size = UDim2.new(0, 26, 0, 26)
WatermarkEmojiButton.Position = UDim2.new(0, isMobile and 108 or 128, 0, 5)
WatermarkEmojiButton.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
WatermarkEmojiButton.BorderSizePixel = 0
WatermarkEmojiButton.TextColor3 = Color3.fromRGB(235, 235, 245)
WatermarkEmojiButton.TextSize = isMobile and 18 or 20
WatermarkEmojiButton.Font = Enum.Font.Gotham
WatermarkEmojiButton.AutoButtonColor = false
WatermarkEmojiButton.ZIndex = 12
WatermarkEmojiButton.Active = true
WatermarkEmojiButton.Parent = TitleBar
addCorner(WatermarkEmojiButton, 5)

local watermarkEmojis = { utf8.char(0x1F5E1, 0xFE0F), utf8.char(0x2694, 0xFE0F), utf8.char(0x1F6E1, 0xFE0F) }
local watermarkEmojiIndex = 1
WatermarkEmojiButton.Text = watermarkEmojis[watermarkEmojiIndex]

wire(WatermarkEmojiButton.Activated, function()
	watermarkEmojiIndex = (watermarkEmojiIndex % #watermarkEmojis) + 1
	WatermarkEmojiButton.Text = watermarkEmojis[watermarkEmojiIndex]
end)

local MinimizeButton = createButton(TitleBar, "Minimize", "-")
MinimizeButton.Size = UDim2.new(0, 22, 0, 22)
MinimizeButton.Position = UDim2.new(1, -54, 0, 7)
MinimizeButton.TextSize = 13
MinimizeButton.ZIndex = 12

local DestroyButton = createButton(TitleBar, "Destroy", "X", Color3.fromRGB(220, 40, 50), Color3.fromRGB(250, 60, 70))
DestroyButton.Size = UDim2.new(0, 22, 0, 22)
DestroyButton.Position = UDim2.new(1, -28, 0, 7)
DestroyButton.TextSize = 10
DestroyButton.ZIndex = 12

local ConfirmOverlay = Instance.new("TextButton")
ConfirmOverlay.Name = "ConfirmOverlay"
ConfirmOverlay.Size = UDim2.new(1, 0, 1, 0)
ConfirmOverlay.BackgroundColor3 = Color3.fromRGB(14, 14, 18)
ConfirmOverlay.BackgroundTransparency = 0.15
ConfirmOverlay.BorderSizePixel = 0
ConfirmOverlay.ZIndex = 50
ConfirmOverlay.Visible = false
ConfirmOverlay.Active = true
ConfirmOverlay.AutoButtonColor = false
ConfirmOverlay.Text = ""
ConfirmOverlay.Parent = Main
addCorner(ConfirmOverlay, 10)

local ConfirmBox = Instance.new("Frame")
ConfirmBox.Name = "ConfirmBox"
ConfirmBox.Size = UDim2.new(0.86, 0, 0, 115)
ConfirmBox.Position = UDim2.new(0.07, 0, 0.5, -57)
ConfirmBox.BackgroundColor3 = Color3.fromRGB(28, 28, 36)
ConfirmBox.BorderSizePixel = 0
ConfirmBox.ZIndex = 51
ConfirmBox.Parent = ConfirmOverlay
addCorner(ConfirmBox, 8)
addStroke(ConfirmBox, Color3.fromRGB(65, 65, 85), 1)

local ConfirmText = Instance.new("TextLabel")
ConfirmText.Name = "ConfirmText"
ConfirmText.Size = UDim2.new(1, -16, 0, 48)
ConfirmText.Position = UDim2.new(0, 8, 0, 10)
ConfirmText.BackgroundTransparency = 1
ConfirmText.Text = "Are you sure?"
ConfirmText.TextColor3 = Color3.fromRGB(240, 240, 250)
ConfirmText.TextSize = isMobile and 10 or 11
ConfirmText.Font = Enum.Font.GothamBold
ConfirmText.TextWrapped = true
ConfirmText.ZIndex = 52
ConfirmText.Parent = ConfirmBox

local ConfirmYesBtn = createButton(ConfirmBox, "YesButton", "YES", Color3.fromRGB(215, 45, 55), Color3.fromRGB(245, 60, 70))
ConfirmYesBtn.Size = UDim2.new(0.44, 0, 0, 26)
ConfirmYesBtn.Position = UDim2.new(0.04, 0, 1, -34)
ConfirmYesBtn.ZIndex = 53

local ConfirmNoBtn = createButton(ConfirmBox, "NoButton", "CANCEL", Color3.fromRGB(45, 48, 60), Color3.fromRGB(58, 62, 76))
ConfirmNoBtn.Size = UDim2.new(0.44, 0, 0, 26)
ConfirmNoBtn.Position = UDim2.new(0.52, 0, 1, -34)
ConfirmNoBtn.ZIndex = 53

local currentConfirmAction = nil
local minimized = false
local savedMainHeight = mainHeight

local function showConfirmation(message, onConfirm)
	ConfirmText.Text = tostring(message or "Are you sure?")
	currentConfirmAction = onConfirm
	ConfirmOverlay.Visible = not minimized
end

local function hideConfirmation()
	ConfirmOverlay.Visible = false
	currentConfirmAction = nil
end

wire(ConfirmYesBtn.Activated, function()
	local action = currentConfirmAction
	hideConfirmation()
	if type(action) == "function" then action() end
end)

wire(ConfirmNoBtn.Activated, hideConfirmation)

local SearchBox = Instance.new("TextBox")
SearchBox.Name = "SearchBox"
SearchBox.Size = UDim2.new(1, -90, 0, 26)
SearchBox.Position = UDim2.new(0, 10, 0, 44)
SearchBox.BackgroundColor3 = Color3.fromRGB(32, 32, 42)
SearchBox.BorderSizePixel = 0
SearchBox.PlaceholderText = "Search saved avatars..."
SearchBox.PlaceholderColor3 = Color3.fromRGB(130, 130, 145)
SearchBox.Text = ""
SearchBox.TextColor3 = Color3.fromRGB(235, 235, 245)
SearchBox.TextSize = isMobile and 9 or 10
SearchBox.Font = Enum.Font.Gotham
SearchBox.ClearTextOnFocus = false
SearchBox.TextXAlignment = Enum.TextXAlignment.Left
SearchBox.Parent = Main
addCorner(SearchBox, 6)
addStroke(SearchBox, Color3.fromRGB(45, 45, 58), 1)

local RefreshButton = createButton(Main, "RefreshButton", "Refresh")
RefreshButton.Size = UDim2.new(0, 65, 0, 26)
RefreshButton.Position = UDim2.new(1, -75, 0, 44)
RefreshButton.ZIndex = 5

local List = Instance.new("ScrollingFrame")
List.Name = "AvatarList"
List.Size = UDim2.new(1, -20, 1, -118)
List.Position = UDim2.new(0, 10, 0, 78)
List.BackgroundTransparency = 1
List.BorderSizePixel = 0
List.ScrollBarThickness = 4
List.ScrollBarImageColor3 = Color3.fromRGB(70, 70, 90)
List.AutomaticCanvasSize = Enum.AutomaticSize.Y
List.Parent = Main

local Grid = Instance.new("UIGridLayout")
Grid.CellSize = UDim2.new(0, isMobile and 132 or 148, 0, isMobile and 88 or 94)
Grid.CellPadding = UDim2.new(0, 6, 0, 6)
Grid.SortOrder = Enum.SortOrder.LayoutOrder
Grid.Parent = List

local WearButton = Instance.new("TextButton")
WearButton.Name = "WearButton"
WearButton.Size = UDim2.new(0, 120, 0, 26)
WearButton.Position = UDim2.new(1, -130, 1, -33)
WearButton.BackgroundColor3 = BLUE_NORMAL
WearButton.BorderSizePixel = 0
WearButton.Text = "TRY ON LOCAL"
WearButton.TextColor3 = Color3.fromRGB(255, 255, 255)
WearButton.TextSize = isMobile and 9 or 10
WearButton.Font = Enum.Font.GothamBold
WearButton.AutoButtonColor = false
WearButton.Active = true
WearButton.ZIndex = 9
WearButton.Parent = Main
addCorner(WearButton, 6)
addStroke(WearButton, Color3.fromRGB(60, 62, 78), 1)

local function updateWearButtonState()
	local isActive = tryOnActive or (localTryOnModel ~= nil)
	local baseCol = isActive and GREEN_NORMAL or BLUE_NORMAL
	WearButton.BackgroundColor3 = baseCol
	if localTryOnBuilding then
		WearButton.Text = "..."
	else
		WearButton.Text = isActive and "ACTIVE (TAP TO UNDO)" or "TRY ON AVATAR"
	end
end

wire(WearButton.MouseEnter, function()
	local isActive = tryOnActive or (localTryOnModel ~= nil)
	local hoverCol = isActive and GREEN_HOVER or BLUE_HOVER
	TweenService:Create(WearButton, TweenInfo.new(0.15), {BackgroundColor3 = hoverCol}):Play()
end)

wire(WearButton.MouseLeave, function()
	local isActive = tryOnActive or (localTryOnModel ~= nil)
	local baseCol = isActive and GREEN_NORMAL or BLUE_NORMAL
	TweenService:Create(WearButton, TweenInfo.new(0.15), {BackgroundColor3 = baseCol}):Play()
end)

local Status = Instance.new("TextLabel")
Status.Name = "Status"
Status.Size = UDim2.new(1, -148, 0, 26)
Status.Position = UDim2.new(0, 10, 1, -33)
Status.BackgroundTransparency = 1
Status.Text = "Initializing..."
Status.TextColor3 = Color3.fromRGB(140, 140, 160)
Status.TextSize = 9
Status.Font = Enum.Font.Gotham
Status.TextXAlignment = Enum.TextXAlignment.Left
Status.TextYAlignment = Enum.TextYAlignment.Center
Status.TextTruncate = Enum.TextTruncate.AtEnd
Status.ZIndex = 6
Status.Parent = Main

local ErrorPopup = Instance.new("Frame")
ErrorPopup.Name = "WearDiagnostics"
ErrorPopup.Size = UDim2.new(0.9, 0, 0, 140)
ErrorPopup.Position = UDim2.new(0.05, 0, 0.5, -70)
ErrorPopup.BackgroundColor3 = Color3.fromRGB(28, 20, 25)
ErrorPopup.BorderSizePixel = 0
ErrorPopup.Visible = false
ErrorPopup.ZIndex = 60
ErrorPopup.Parent = Main
addCorner(ErrorPopup, 8)
addStroke(ErrorPopup, Color3.fromRGB(130, 50, 65), 1)

local ErrorTitle = Instance.new("TextLabel")
ErrorTitle.Name = "ErrorTitle"
ErrorTitle.Size = UDim2.new(1, -36, 0, 24)
ErrorTitle.Position = UDim2.new(0, 10, 0, 4)
ErrorTitle.BackgroundTransparency = 1
ErrorTitle.Text = "Diagnostic Log"
ErrorTitle.TextColor3 = Color3.fromRGB(255, 120, 140)
ErrorTitle.TextSize = isMobile and 9 or 10
ErrorTitle.Font = Enum.Font.GothamBold
ErrorTitle.TextXAlignment = Enum.TextXAlignment.Left
ErrorTitle.ZIndex = 61
ErrorTitle.Parent = ErrorPopup

local ErrorCloseBtn = createButton(ErrorPopup, "ErrorClose", "X", Color3.fromRGB(60, 30, 38), Color3.fromRGB(90, 40, 50))
ErrorCloseBtn.Size = UDim2.new(0, 20, 0, 20)
ErrorCloseBtn.Position = UDim2.new(1, -26, 0, 6)
ErrorCloseBtn.TextSize = 10
ErrorCloseBtn.ZIndex = 62

local ErrorScroll = Instance.new("ScrollingFrame")
ErrorScroll.Name = "ErrorScroll"
ErrorScroll.Size = UDim2.new(1, -16, 1, -36)
ErrorScroll.Position = UDim2.new(0, 8, 0, 30)
ErrorScroll.BackgroundTransparency = 1
ErrorScroll.BorderSizePixel = 0
ErrorScroll.ScrollBarThickness = 3
ErrorScroll.ScrollBarImageColor3 = Color3.fromRGB(160, 80, 95)
ErrorScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
ErrorScroll.ZIndex = 61
ErrorScroll.Parent = ErrorPopup

local ErrorText = Instance.new("TextLabel")
ErrorText.Name = "FullError"
ErrorText.Size = UDim2.new(1, -6, 0, 0)
ErrorText.AutomaticSize = Enum.AutomaticSize.Y
ErrorText.BackgroundTransparency = 1
ErrorText.Text = ""
ErrorText.TextColor3 = Color3.fromRGB(255, 210, 220)
ErrorText.TextSize = isMobile and 8 or 9
ErrorText.Font = Enum.Font.Code
ErrorText.TextWrapped = true
ErrorText.TextXAlignment = Enum.TextXAlignment.Left
ErrorText.TextYAlignment = Enum.TextYAlignment.Top
ErrorText.ZIndex = 62
ErrorText.Parent = ErrorScroll

wire(ErrorCloseBtn.Activated, function() ErrorPopup.Visible = false end)

local function clearDiagnostics()
	ErrorPopup.Visible = false
	ErrorText.Text = ""
	ErrorScroll.CanvasPosition = Vector2.zero
end

local function showDiagnostics(summary, detail)
	Status.Text = tostring(summary or "Wear failed.")
	ErrorText.Text = tostring(detail or "No additional error text was returned.")
	ErrorPopup.Visible = true
	task.defer(function()
		if ErrorScroll.Parent then ErrorScroll.CanvasPosition = Vector2.zero end
	end)
end

local SEATED_TRY_ON_BLOCK_MESSAGE = "Please wear avatars while standing still. Cannot wear avatars while sitting at the moment because of the avatar placement glitch similar to wearing while flying and wearing while doing a forward/backward swim. The bug/glitch is under maintenance and is fixing right away. Thank you for understanding.\n\nKnightingale."

local function isCharacterCurrentlySitting(character, humanoid)
	humanoid = humanoid or (character and character:FindFirstChildOfClass("Humanoid"))
	if not humanoid then return false end

	local state = humanoid:GetState()
	return humanoid.Sit
		or humanoid.SeatPart ~= nil
		or state == Enum.HumanoidStateType.Seated
end

local function showSeatedTryOnBlocked()
	showDiagnostics("[!] Cannot wear avatars while sitting.", SEATED_TRY_ON_BLOCK_MESSAGE)
end

local accessoryPropertyNames = {
	"HatAccessory", "HairAccessory", "FaceAccessory", "NeckAccessory",
	"ShouldersAccessory", "FrontAccessory", "BackAccessory", "WaistAccessory",
	"JacketAccessory", "ShortsAccessory", "SweaterAccessory", "TShirtAccessory",
	"PantsAccessory", "ShoesAccessory", "DressSkirtAccessory", "EyelashAccessory",
	"EyebrowAccessory", "MoodAccessory"
}

local function loadSavedAvatars()
	local previousSignature = selectedAvatar and selectedAvatar.Signature
	local previousName = selectedAvatar and selectedAvatar.Name

	table.clear(savedAvatars)

	if type(readfile) ~= "function" or type(isfile) ~= "function" then
		Status.Text = "[!] File API unavailable."
		return false
	end
	local exists, fileExists = pcall(isfile, FILE_PATH)
	if not exists or not fileExists then
		Status.Text = "[!] SavedAvatars.json missing."
		return false
	end
	local ok, result = pcall(function()
		return HttpService:JSONDecode(readfile(FILE_PATH))
	end)
	if not ok or type(result) ~= "table" then
		showDiagnostics("Failed to read SavedAvatars.json.", tostring(result))
		return false
	end
	for _, data in ipairs(result) do
		if type(data) == "table" and type(data.Properties) == "table" then
			table.insert(savedAvatars, data)
		end
	end
	if previousSignature or previousName then
		selectedAvatar = nil
		for _, data in ipairs(savedAvatars) do
			if (previousSignature and data.Signature == previousSignature) or
			   (not previousSignature and previousName and data.Name == previousName) then
				selectedAvatar = data
				break
			end
		end
	end

	Status.Text = "[File] " .. tostring(#savedAvatars) .. " avatar(s) loaded."
	clearDiagnostics()
	return true
end

local function applyBodyColors(character, props)
	if not character or type(props) ~= "table" then return end
	local bodyColors = character:FindFirstChildOfClass("BodyColors") or Instance.new("BodyColors")
	bodyColors.Parent = character
	local colorProps = {
		HeadColor = "HeadColor3", TorsoColor = "TorsoColor3", LeftArmColor = "LeftArmColor3",
		RightArmColor = "RightArmColor3", LeftLegColor = "LeftLegColor3", RightLegColor = "RightLegColor3"
	}
	for propKey, colorKey in pairs(colorProps) do
		local colorData = props[propKey]
		if type(colorData) == "table" then
			pcall(function()
				bodyColors[colorKey] = Color3.fromRGB(
					colorData.r or colorData.R or 255,
					colorData.g or colorData.G or 255,
					colorData.b or colorData.B or 255
				)
			end)
		end
	end
end

local function applyHeadShapeToModel(model, props)
	if not model or type(props) ~= "table" or props.HeadShape == nil then return end
	local head = model:FindFirstChild("Head")
	if not head then return end

	local shapeStr = tostring(props.HeadShape):lower()
	local specialMesh = head:FindFirstChildOfClass("SpecialMesh")

	if specialMesh then
		if shapeStr:find("block") then
			specialMesh.MeshType = Enum.MeshType.Brick
		elseif shapeStr:find("round") or shapeStr:find("standard") then
			specialMesh.MeshType = Enum.MeshType.Head
		end
	end
end

local function applyHeadShapeToDescription(description, props)
	if not description or type(props) ~= "table" then return false end

	local rawShape = props.HeadShape
	local shape = tostring(rawShape or "")
	shape = string.match(shape, "^%s*(.-)%s*$")
	if shape == "" then return false end

	local headAssetId = parseAssetId(props.Head)
		or parseAssetId(props.HeadAssetId)
		or parseAssetId(props.HeadId)
		or (type(props.BodyParts) == "table" and parseAssetId(props.BodyParts.Head))
		or (type(props.EquippedAssets) == "table" and parseAssetId(props.EquippedAssets.Head))
	if not headAssetId then return false end

	local ok = pcall(function()
		local headDescription = Instance.new("BodyPartDescription")
		headDescription.BodyPart = Enum.BodyPart.Head
		headDescription.AssetId = headAssetId
		headDescription.HeadShape = shape
		headDescription.Parent = description
	end)

	return ok
end

local function reconstructHumanoidDescription(props)
	local desc = Instance.new("HumanoidDescription")
	if type(props) ~= "table" then return desc end

	local headShape = tostring(props.HeadShape or "")
	headShape = string.match(headShape, "^%s*(.-)%s*$")
	local hasHeadShape = headShape ~= ""
	local headShapeApplied = applyHeadShapeToDescription(desc, props)

	local directProps = {
		"Face", "Shirt", "Pants", "GraphicTShirt", "Head", "Torso",
		"LeftArm", "RightArm", "LeftLeg", "RightLeg", "WalkAnimation",
		"MoodAnimation", "ClimbAnimation", "FallAnimation", "RunAnimation",
		"SwimAnimation", "IdleAnimation", "JumpAnimation"
	}
	for _, prop in ipairs(directProps) do
		local parsedId = parseAssetId(props[prop])
		if parsedId and not (prop == "Head" and hasHeadShape and headShapeApplied) then
			pcall(function() desc[prop] = parsedId end)
		end
	end

	if not headShapeApplied and (desc.Head == 0 or not desc.Head) then
		local fallbackHeadId = parseAssetId(props.HeadAssetId) or parseAssetId(props.HeadId)
			or (type(props.BodyParts) == "table" and parseAssetId(props.BodyParts.Head))
			or (type(props.EquippedAssets) == "table" and parseAssetId(props.EquippedAssets.Head))
		if fallbackHeadId then pcall(function() desc.Head = fallbackHeadId end) end
	end

	if props.StaticFacialAnimation ~= nil then
		pcall(function() desc.StaticFacialAnimation = props.StaticFacialAnimation == true end)
	end
	if type(props.Emotes) == "table" then pcall(function() desc:SetEmotes(props.Emotes) end) end
	if type(props.EquippedEmotes) == "table" then pcall(function() desc:SetEquippedEmotes(props.EquippedEmotes) end) end

	if type(props.MakeupItems) == "table" then
		for _, makeup in ipairs(props.MakeupItems) do
			pcall(function()
				local assetId = parseAssetId(makeup.AssetId)
				local makeupType = Enum.MakeupType[tostring(makeup.MakeupType)]
				if assetId and makeupType then
					local makeupDescription = Instance.new("MakeupDescription")
					makeupDescription.AssetId = assetId
					makeupDescription.Order = tonumber(makeup.Order) or 1
					makeupDescription.MakeupType = makeupType
					makeupDescription.Parent = desc
				end
			end)
		end
	end

	local refinements = props.AccessoryRefinements or {}
	if props.AllAccessories and type(props.AllAccessories) == "table" then
		local accessories = {}
		for _, entry in ipairs(props.AllAccessories) do
			if type(entry) == "table" and entry.AssetId and entry.AccessoryType then
				local parsedAssetId = parseAssetId(entry.AssetId)
				local accessoryType = Enum.AccessoryType[entry.AccessoryType]
				if parsedAssetId and accessoryType then
					local accessory = { AssetId = parsedAssetId, AccessoryType = accessoryType }
					local refData = refinements[tostring(parsedAssetId)] or entry
					if refData then
						if refData.Position then accessory.Position = vector3FromSaved(refData.Position, Vector3.zero) end
						if refData.Rotation then accessory.Rotation = vector3FromSaved(refData.Rotation, Vector3.zero) end
						if refData.Scale then accessory.Scale = vector3FromSaved(refData.Scale, Vector3.one) end
					end
					if entry.IsLayered then
						accessory.IsLayered = true
						accessory.Order = tonumber(entry.Order) or 0
						if entry.Puffiness ~= nil then accessory.Puffiness = tonumber(entry.Puffiness) or 0 end
					end
					table.insert(accessories, accessory)
				end
			end
		end
		pcall(function() desc:SetAccessories(accessories, true) end)
	else
		for _, propertyName in ipairs(accessoryPropertyNames) do
			if props[propertyName] ~= nil then
				pcall(function() desc[propertyName] = tostring(props[propertyName]) end)
			end
		end
	end

	local colorProps = { "RightArmColor", "TorsoColor", "RightLegColor", "LeftLegColor", "LeftArmColor", "HeadColor" }
	for _, colorName in ipairs(colorProps) do
		local colorData = props[colorName]
		if type(colorData) == "table" then
			pcall(function()
				desc[colorName] = Color3.fromRGB(
					colorData.r or colorData.R or 255,
					colorData.g or colorData.G or 255,
					colorData.b or colorData.B or 255
				)
			end)
		end
	end

	local scaleProps = { "ProportionScale", "DepthScale", "HeightScale", "WidthScale", "BodyTypeScale", "HeadScale" }
	for _, scaleName in ipairs(scaleProps) do
		if props[scaleName] ~= nil then pcall(function() desc[scaleName] = tonumber(props[scaleName]) or 1 end) end
	end

	return desc
end

local function applyRigidAccessoryRefinements(model, props)
	local refinements = props and props.AccessoryRefinements
	if type(refinements) ~= "table" then return 0 end
	local matched = 0
	local used = {}
	for _, accessory in ipairs(model:GetDescendants()) do
		if accessory:IsA("Accessory") then
			local handle = accessory:FindFirstChild("Handle")
			if handle then
				local assetId = nil
				pcall(function() assetId = parseAssetId(accessory:GetAttribute("AssetId")) end)
				if not assetId then pcall(function() assetId = parseAssetId(handle:GetAttribute("AssetId")) end) end
				if not assetId then
					local specialMesh = handle:FindFirstChildOfClass("SpecialMesh")
					if specialMesh and specialMesh.MeshId then assetId = parseAssetId(specialMesh.MeshId) end
				end
				if not assetId and handle:IsA("MeshPart") and handle.MeshId then assetId = parseAssetId(handle.MeshId) end

				local ref = (assetId and refinements[tostring(assetId)]) or refinements[accessory.Name]
				if ref and type(ref) == "table" then
					local key = assetId or accessory.Name
					if not used[key] then
						local position = vector3FromSaved(ref.Position, Vector3.zero)
						local rotation = vector3FromSaved(ref.Rotation, Vector3.zero)
						local scale = vector3FromSaved(ref.Scale, Vector3.one)

						local offsetCF = CFrame.new(position) * CFrame.Angles(
							math.rad(rotation.X), math.rad(rotation.Y), math.rad(rotation.Z)
						)

						local attachment = handle:FindFirstChildOfClass("Attachment")
						if attachment then
							attachment.CFrame = attachment.CFrame * offsetCF
						else
							local weld = handle:FindFirstChildOfClass("Weld") or handle:FindFirstChildOfClass("WeldConstraint") or handle:FindFirstChildOfClass("ManualWeld")
							if weld and weld:IsA("Weld") then weld.C0 = weld.C0 * offsetCF end
						end

						if scale ~= Vector3.one then
							handle.Size = handle.Size * scale
							local specialMesh = handle:FindFirstChildOfClass("SpecialMesh")
							if specialMesh then specialMesh.Scale = specialMesh.Scale * scale end
						end
						used[key] = true
						matched = matched + 1
					end
				end
			end
		end
	end
	return matched
end

local function getAnimationIdFromFolder(container, animName)
	if not container then return nil end
	local target = container:FindFirstChild(animName)
		or container:FindFirstChild(string.lower(animName))
		or (animName == "SwimIdle" and (container:FindFirstChild("swimidle") or container:FindFirstChild("SwimIdle")))
		or (animName == "Swim" and (container:FindFirstChild("swim") or container:FindFirstChild("Swim")))
	if not target then return nil end

	if target:IsA("Animation") and target.AnimationId ~= "" then return target.AnimationId
	elseif target:IsA("StringValue") and target.Value ~= "" then return target.Value end

	for _, child in ipairs(target:GetChildren()) do
		if child:IsA("Animation") and child.AnimationId ~= "" then return child.AnimationId
		elseif child:IsA("StringValue") and child.Value ~= "" then return child.Value end
	end
	return nil
end

local function resolveAnimationIds(cloneModel, savedProps, isR6)
	local defaults = isR6 and R6_DEFAULTS or R15_DEFAULTS
	local animFolder = cloneModel:FindFirstChild("Animate")
	local animIds = {}
	local animKeys = {"Idle", "Walk", "Run", "Jump", "Fall", "Climb", "Swim", "SwimIdle", "Sit"}

	for _, key in ipairs(animKeys) do
		if key == "Sit" then
			local cloneSitId = getAnimationIdFromFolder(animFolder, "Sit")
			animIds[key] = cloneSitId or defaults[key]
		elseif isR6 then
			animIds[key] = defaults[key]
		else
			local idFromAnimate = getAnimationIdFromFolder(animFolder, key)
			local propKey = key .. "Animation"
			local rawPropVal = savedProps and savedProps[propKey]
			local parsedPropId = parseAssetId(rawPropVal)

			local finalId = (idFromAnimate and idFromAnimate ~= "") and idFromAnimate or nil
			if not finalId and parsedPropId then finalId = "rbxassetid://" .. tostring(parsedPropId) end
			if not finalId or finalId == "" then finalId = defaults[key] end
			animIds[key] = finalId
		end
	end
	return animIds
end

local function getAppliedPlayerEmoteData(humanoid)
	if not humanoid then return {}, {} end
	local description = nil
	local ok = pcall(function()
		description = humanoid:GetAppliedDescription()
	end)
	if not ok or not description then return {}, {} end

	local emotes = {}
	local equipped = {}
	pcall(function()
		emotes = cloneEmoteTable(description:GetEmotes())
	end)
	pcall(function()
		local value = description:GetEquippedEmotes()
		if type(value) == "table" then
			for _, entry in ipairs(value) do
				if type(entry) == "table" and type(entry.Name) == "string" and entry.Name ~= "" then
					equipped[#equipped + 1] = {
						Slot = tonumber(entry.Slot) or (#equipped + 1),
						Name = entry.Name
					}
				end
			end
		end
	end)
	pcall(function() description:Destroy() end)
	return emotes, equipped
end

local function mergePlayerEmotesIntoDescription(description, playerHumanoid, rigType)
	if not description or getEnumRigType(rigType) ~= Enum.HumanoidRigType.R15 then
		return
	end

	local playerEmotes, playerEquippedEmotes = getAppliedPlayerEmoteData(playerHumanoid)
	local merged = {}
	pcall(function()
		merged = cloneEmoteTable(description:GetEmotes())
	end)
	for name, ids in pairs(playerEmotes) do
		merged[name] = ids
	end

	if next(merged) ~= nil then
		pcall(function() description:SetEmotes(merged) end)
	end

	if #playerEquippedEmotes > 0 then
		local validEquipped = {}
		for _, entry in ipairs(playerEquippedEmotes) do
			if merged[entry.Name] then
				validEquipped[#validEquipped + 1] = entry
			end
		end
		if #validEquipped > 0 then
			pcall(function() description:SetEquippedEmotes(validEquipped) end)
		end
	end
end

local function bindAnimationSync(playerCharacter, cloneModel, savedProps, rigType)
	cleanupAnimationSync()

	local playerHumanoid = playerCharacter and playerCharacter:FindFirstChildOfClass("Humanoid")
	local cloneHumanoid = cloneModel and cloneModel:FindFirstChildOfClass("Humanoid")
	if not playerHumanoid or not cloneHumanoid then return function() end end

	local playerAnimator = playerHumanoid:FindFirstChildOfClass("Animator")
	local cloneAnimator = cloneHumanoid:FindFirstChildOfClass("Animator")
	if not cloneAnimator then
		cloneAnimator = Instance.new("Animator")
		cloneAnimator.Parent = cloneHumanoid
	end

	for _, track in ipairs(cloneAnimator:GetPlayingAnimationTracks()) do
		pcall(function() track:Stop(0) end)
	end

	local enumRig = getEnumRigType(rigType)
	local isR6 = (enumRig == Enum.HumanoidRigType.R6)
		or (cloneModel:FindFirstChild("Torso") ~= nil and cloneModel:FindFirstChild("UpperTorso") == nil)
	local defaults = isR6 and R6_DEFAULTS or R15_DEFAULTS
	local animIds = resolveAnimationIds(cloneModel, savedProps, isR6)

	local playerEmoteByAssetId = {}
	local playerEmoteByAnimationId = {}
	local playerEmotePlayNameByCanonical = {}
	local equippedEmoteNames = {}

	local function normalizeEmoteName(rawName)
		local value = string.lower(tostring(rawName or ""))
		value = string.match(value, "^%s*(.-)%s*$") or value
		value = value:gsub("[^%w]+", "")
		return value
	end

	local function rememberEmoteAsset(assetId, emoteName, exactNameForPlayback)
		local parsed = parseAssetId(assetId)
		if not parsed then return end
		local normalized = normalizeEmoteName(emoteName)
		if normalized == "" then return end
		playerEmoteByAssetId[tostring(parsed)] = normalized
		local exactName = exactNameForPlayback or emoteName
		if type(exactName) == "string" and exactName ~= "" then
			playerEmotePlayNameByCanonical[normalized] = exactName
		end
	end

	local function rememberResolvedAnimation(emoteAnimationId, emoteName, exactNameForPlayback)
		local parsed = parseAssetId(emoteAnimationId)
		if not parsed then return end
		local normalized = normalizeEmoteName(emoteName)
		if normalized == "" then return end
		playerEmoteByAnimationId[tostring(parsed)] = normalized
		local exactName = exactNameForPlayback or emoteName
		if type(exactName) == "string" and exactName ~= "" then
			playerEmotePlayNameByCanonical[normalized] = exactName
		end
	end

	local function extractAnimationIdFromLoadedEmoteAsset(root)
		if not root then return nil end
		if root:IsA("Animation") and root.AnimationId ~= "" then
			return root.AnimationId
		end
		for _, instance in ipairs(root:GetDescendants()) do
			if instance:IsA("Animation") and instance.AnimationId ~= "" then
				return instance.AnimationId
			end
		end
		return nil
	end

	local function resolveEmoteCatalogAssetToAnimationId(catalogAssetId)
		local parsed = parseAssetId(catalogAssetId)
		if not parsed then return nil end
		local key = tostring(parsed)
		if emoteAssetAnimationCache[key] ~= nil then
			return emoteAssetAnimationCache[key]
		end

		local animationId = nil

		pcall(function()
			if type(game.GetObjects) == "function" then
				local objects = game:GetObjects("rbxassetid://" .. key)
				if type(objects) == "table" then
					for _, root in ipairs(objects) do
						animationId = extractAnimationIdFromLoadedEmoteAsset(root)
						if animationId then
							pcall(function() root:Destroy() end)
							break
						end
					end
				end
			end
		end)

		if not animationId and InsertService then
			pcall(function()
				local root = InsertService:LoadAsset(parsed)
				animationId = extractAnimationIdFromLoadedEmoteAsset(root)
				if root then root:Destroy() end
			end)
		end

		if animationId then
			emoteAssetAnimationCache[key] = animationId
		end
		return animationId
	end

	local appliedDescription = nil
	local appliedDescriptionOk = pcall(function()
		appliedDescription = playerHumanoid:GetAppliedDescription()
	end)
	if appliedDescriptionOk and appliedDescription then
		pcall(function()
			local equipped = appliedDescription:GetEquippedEmotes()
			if type(equipped) == "table" then
				for _, entry in ipairs(equipped) do
					if type(entry) == "table" and type(entry.Name) == "string" then
						equippedEmoteNames[normalizeEmoteName(entry.Name)] = entry.Name
					end
				end
			end
		end)

		pcall(function()
			local emotes = appliedDescription:GetEmotes()
			if type(emotes) == "table" then
				for name, ids in pairs(emotes) do
					if type(ids) == "table" then
						local exactName = type(name) == "string" and name or tostring(name)
						for _, assetId in ipairs(ids) do
							rememberEmoteAsset(assetId, exactName, exactName)
							local actualAnimationId = resolveEmoteCatalogAssetToAnimationId(assetId)
							if actualAnimationId then
								rememberResolvedAnimation(actualAnimationId, exactName, exactName)
							end
						end
					end
				end
			end
		end)
		pcall(function() appliedDescription:Destroy() end)
	end

	for emoteName, assetList in pairs(R6_EMOTE_LIBRARY) do
		for _, assetId in ipairs(assetList) do
			rememberEmoteAsset(assetId, emoteName)
		end
	end

	local playerAnimate = playerCharacter:FindFirstChild("Animate")
	local knownEmoteNames = {}
	for emoteName in pairs(R6_EMOTE_LIBRARY) do
		knownEmoteNames[normalizeEmoteName(emoteName)] = emoteName
	end
	for normalized, exactName in pairs(equippedEmoteNames) do
		knownEmoteNames[normalized] = exactName
	end

	local function getNamedEmoteFromHierarchy(animation)
		if not animation then return nil end

		local function checkName(instance)
			if not instance then return nil end
			local normalized = normalizeEmoteName(instance.Name)
			return knownEmoteNames[normalized]
		end

		local direct = checkName(animation)
		if direct then return direct end

		local parent = animation.Parent
		while parent and parent ~= playerCharacter do
			local named = checkName(parent)
			if named then return named end
			if parent == playerAnimate then break end
			parent = parent.Parent
		end
		return nil
	end

	local locomotionFolderNames = {
		idle = true,
		walk = true,
		run = true,
		jump = true,
		fall = true,
		climb = true,
		swim = true,
		swimidle = true,
		sit = true,
		seated = true,
		tool = true,
		toolnone = true,
		toolnoneanim = true,
		toolslash = true,
		toollunge = true,
		slash = true,
		lunge = true,
	}

	local function hasLocomotionOrToolAncestor(animation)
		if not animation then return false end
		local normalizedName = normalizeEmoteName(animation.Name)
		if locomotionFolderNames[normalizedName] then return true end

		local parent = animation.Parent
		while parent and parent ~= playerCharacter do
			local parentName = normalizeEmoteName(parent.Name)
			if locomotionFolderNames[parentName] then return true end
			parent = parent.Parent
		end
		return false
	end

	local function isLikelyR15EmoteTrack(playerTrack)
		if isR6 or not playerTrack or not playerTrack.Animation then return false end
		if hasLocomotionOrToolAncestor(playerTrack.Animation) then return false end

		local priority = playerTrack.Priority
		local isCore = priority == Enum.AnimationPriority.Core
		local isAction = priority == Enum.AnimationPriority.Action
			or priority == Enum.AnimationPriority.Action2
			or priority == Enum.AnimationPriority.Action3
			or priority == Enum.AnimationPriority.Action4
		if not isCore and not isAction then return false end

		local animationId = parseAssetId(playerTrack.Animation.AnimationId)
		if not animationId then return false end

		if next(equippedEmoteNames) ~= nil
			or next(playerEmoteByAnimationId) ~= nil
			or next(playerEmoteByAssetId) ~= nil then
			return true
		end

		return false
	end

	if playerAnimate then
		for _, instance in ipairs(playerAnimate:GetDescendants()) do
			if instance:IsA("Animation") then
				local emoteName = getNamedEmoteFromHierarchy(instance)
				if emoteName then
					rememberEmoteAsset(instance.AnimationId, emoteName)
				end
			end
		end
	end

	local function resolvePlayerEmoteName(playerTrack)
		if not playerTrack or not playerTrack.Animation then return nil, false end

		local assetId = parseAssetId(playerTrack.Animation.AnimationId)
		if assetId then
			local assetKey = tostring(assetId)

			local resolvedAnimationMapped = playerEmoteByAnimationId[assetKey]
			if resolvedAnimationMapped then
				return resolvedAnimationMapped, true
			end

			local legacyMapped = PLAYER_LEGACY_EMOTE_IDS[assetKey]
			if legacyMapped then return legacyMapped, true end

			local mapped = playerEmoteByAssetId[assetKey]
			if mapped then return mapped, true end
		end

		local named = getNamedEmoteFromHierarchy(playerTrack.Animation)
		if named then return normalizeEmoteName(named), true end

		if isLikelyR15EmoteTrack(playerTrack) then
			return "__direct_r15_emote_track__", false
		end

	return nil, false
	end

	local function chooseR6EmoteAnimation(emoteName)
		local list = R6_EMOTE_LIBRARY[emoteName]
		if type(list) ~= "table" or #list == 0 then return nil end

		if #list == 1 then return list[1] end
		local index = (math.floor(os.clock() * 1000) % #list) + 1
		return list[index]
	end
	local function findFreshCloneEmoteTrack(beforeTracks, expectedAssetId)
		local expectedParsed = parseAssetId(expectedAssetId)
		local expectedKey = expectedParsed and tostring(expectedParsed) or nil
		local fallback = nil

		for _, candidate in ipairs(cloneAnimator:GetPlayingAnimationTracks()) do
			if candidate and candidate.IsPlaying and not beforeTracks[candidate] then
				local candidateId = candidate.Animation and parseAssetId(candidate.Animation.AnimationId)
				if expectedKey and candidateId and tostring(candidateId) == expectedKey then
					return candidate
				end
				fallback = fallback or candidate
			end
		end

		return fallback
	end

	local function syncInitialEmotePhase(playerTrack, cloneTrack)
		if not playerTrack or not cloneTrack then return end
		if not playerTrack.IsPlaying or not cloneTrack.IsPlaying then return end

		local playerAnimation = playerTrack.Animation
		local cloneAnimation = cloneTrack.Animation
		local playerId = playerAnimation and parseAssetId(playerAnimation.AnimationId)
		local cloneId = cloneAnimation and parseAssetId(cloneAnimation.AnimationId)

		if not playerId or not cloneId or playerId ~= cloneId then return end

		local function applyPhase()
			if not playerTrack.IsPlaying or not cloneTrack.IsPlaying then return true end
			if playerTrack.Length <= 0 or cloneTrack.Length <= 0 then return false end

			local playerPhase = math.clamp(playerTrack.TimePosition / playerTrack.Length, 0, 0.999999)
			local targetPosition = playerPhase * cloneTrack.Length
			pcall(function()
				cloneTrack.TimePosition = targetPosition
			end)
			return true
		end

		if applyPhase() then return end

		task.spawn(function()
			for _ = 1, 4 do
				RunService.Heartbeat:Wait()
				if not scriptAlive then return end
				if applyPhase() then return end
			end
		end)
	end

	local function tryPlayRegisteredR15Emote(emoteName, playerTrack)
		if isR6 then return nil, nil end

		local playbackName = playerEmotePlayNameByCanonical[emoteName]
		if not playbackName then return nil, nil end

		local beforeTracks = {}
		for _, track in ipairs(cloneAnimator:GetPlayingAnimationTracks()) do
			beforeTracks[track] = true
		end

		local ok, result = pcall(function()
			return cloneHumanoid:PlayEmoteAsync(playbackName)
		end)
		if not ok or result ~= true then return nil, nil end

		local expectedAssetId = playerTrack
			and playerTrack.Animation
			and playerTrack.Animation.AnimationId

		local cloneTrack = nil
		local deadline = os.clock() + 0.35
		repeat
			cloneTrack = findFreshCloneEmoteTrack(beforeTracks, expectedAssetId)
			if cloneTrack then break end
			RunService.Heartbeat:Wait()
		until os.clock() >= deadline

		if not cloneTrack then
			local expectedParsed = parseAssetId(expectedAssetId)
			if expectedParsed then
				pcall(function()
					cloneTrack = cloneAnimator:GetTrackByAnimationId("rbxassetid://" .. tostring(expectedParsed))
				end)
			end
		end

		if cloneTrack then
			pcall(function() cloneTrack.Priority = Enum.AnimationPriority.Action end)
			pcall(function() cloneTrack.Looped = true end)
			syncInitialEmotePhase(playerTrack, cloneTrack)
		end

		return cloneTrack
	end

	local function loadDirectCloneEmote(animationId, emoteName, playerTrack)
		if not animationId or animationId == "" then return nil, nil end

		local animation = Instance.new("Animation")
		animation.AnimationId = animationId

		local ok, cloneTrack = pcall(function()
			return cloneAnimator:LoadAnimation(animation)
		end)
		if not ok or not cloneTrack then
			animation:Destroy()
			return nil, nil
		end

		cloneTrack.Priority = Enum.AnimationPriority.Action
		if isR6 then
			cloneTrack.Looped = R6_EMOTE_LOOPED[emoteName] == true
		else
			cloneTrack.Looped = playerTrack.Looped
		end

		local playedOk = pcall(function()
			cloneTrack:Play(0.08, 1, 1)
		end)
		if not playedOk then
			pcall(function() cloneTrack:Stop(0) end)
			animation:Destroy()
			return nil, nil
		end

		syncInitialEmotePhase(playerTrack, cloneTrack)
		return cloneTrack, animation
	end

	local catchEmoteTrack

	local function playCloneEmote(playerTrack, emoteName, isDirectR15Track)
		if not playerTrack or not emoteName then return false end

		stopAllCloneTracks(0.08)

		local cloneTrack = nil
		local animationObject = nil

		if not isR6 and not isDirectR15Track then
			cloneTrack = tryPlayRegisteredR15Emote(emoteName, playerTrack)
		end

		if not cloneTrack then
			local animationId = nil
			if isR6 then
				animationId = chooseR6EmoteAnimation(emoteName)
			else
				animationId = playerTrack.Animation.AnimationId
			end

			cloneTrack, animationObject = loadDirectCloneEmote(animationId, emoteName, playerTrack)
		end

		if not cloneTrack then
			return false
		end

		activeCloneTracks[playerTrack] = cloneTrack
		activeCloneEmoteAnimations[playerTrack] = animationObject
		activeEmotePlayerTrack = playerTrack

		local stoppedConnection
		stoppedConnection = playerTrack.Stopped:Connect(function()
			task.delay(0.12, function()
				if not scriptAlive or activeEmotePlayerTrack ~= playerTrack then return end
				if playerAnimator then
					for _, replacementTrack in ipairs(playerAnimator:GetPlayingAnimationTracks()) do
						if replacementTrack and replacementTrack.IsPlaying then
							local replacementName = resolvePlayerEmoteName(replacementTrack)
							if replacementName == emoteName then
								catchEmoteTrack(replacementTrack)
								return
							end
						end
					end
				end

				local active = activeCloneTracks[playerTrack]
				activeCloneTracks[playerTrack] = nil
				activeCloneStopConnections[playerTrack] = nil
				local activeAnimation = activeCloneEmoteAnimations[playerTrack]
				activeCloneEmoteAnimations[playerTrack] = nil
				if active then pcall(function() active:Stop(0.08) end) end
				if activeAnimation then pcall(function() activeAnimation:Destroy() end) end
				disconnectConnection(stoppedConnection)
				if activeEmotePlayerTrack == playerTrack then activeEmotePlayerTrack = nil end
			end)
		end)

		activeCloneStopConnections[playerTrack] = stoppedConnection
		return true
	end

	catchEmoteTrack = function(playerTrack)
		if not playerTrack or not playerTrack.IsPlaying then return false end
		if activeCloneTracks[playerTrack] then return true end
		local emoteName, isKnownEmote = resolvePlayerEmoteName(playerTrack)
		if not emoteName then return false end
		if next(activeCloneTracks) ~= nil and activeEmotePlayerTrack ~= playerTrack and not isKnownEmote then
			return false
		end
		local directR15 = (emoteName == "__direct_r15_emote_track__")
		return playCloneEmote(playerTrack, emoteName, directR15)
	end

	if playerAnimator then
		for _, track in ipairs(playerAnimator:GetPlayingAnimationTracks()) do
			task.defer(catchEmoteTrack, track)
		end
		animPlayedConnection = playerAnimator.AnimationPlayed:Connect(function(playerTrack)
			task.defer(catchEmoteTrack, playerTrack)
		end)
	end

	local loadedTracks = {}
	for key, animId in pairs(animIds) do
		if animId and animId ~= "" then
			local animObj = Instance.new("Animation")
			animObj.AnimationId = animId
			local ok, track = pcall(function() return cloneAnimator:LoadAnimation(animObj) end)

			if (not ok or not track) and isR6 and defaults[key] then
				local fallbackObj = Instance.new("Animation")
				fallbackObj.AnimationId = defaults[key]
				ok, track = pcall(function() return cloneAnimator:LoadAnimation(fallbackObj) end)
			end

			if ok and track then
				if key == "Idle" then track.Priority = Enum.AnimationPriority.Idle
				elseif key == "Walk" or key == "Run" or key == "Climb" or key == "Swim" or key == "SwimIdle" then track.Priority = Enum.AnimationPriority.Movement
				elseif key == "Jump" or key == "Fall" or key == "Sit" then track.Priority = Enum.AnimationPriority.Action
				else track.Priority = Enum.AnimationPriority.Core end

				track.Looped = (key ~= "Jump")
				loadedTracks[key] = track
			end
		end
	end

	local activeKey = nil

	return function()
		if not scriptAlive or not cloneModel or not cloneModel.Parent then return end

		local playerRoot = playerCharacter:FindFirstChild("HumanoidRootPart") or playerCharacter.PrimaryPart
		local moveSpeed, verticalVel, totalVel = 0, 0, 0
		local moveDirectionMagnitude = 0

		if playerRoot then
			local vel = playerRoot.AssemblyLinearVelocity or playerRoot.Velocity
			moveSpeed = Vector3.new(vel.X, 0, vel.Z).Magnitude
			verticalVel = vel.Y
			totalVel = vel.Magnitude
		end

		if playerHumanoid then
			moveDirectionMagnitude = playerHumanoid.MoveDirection.Magnitude
		end

		local state = playerHumanoid and playerHumanoid:GetState()
		local isSeated = playerHumanoid and (playerHumanoid.Sit or playerHumanoid.SeatPart ~= nil or state == Enum.HumanoidStateType.Seated) or false

		if not isR6 and activeEmotePlayerTrack then
			local activePlayerEmoteTrack = activeEmotePlayerTrack
			local activeCloneEmoteTrack = activeCloneTracks[activePlayerEmoteTrack]
			if activePlayerEmoteTrack.IsPlaying and activeCloneEmoteTrack and activeCloneEmoteTrack.IsPlaying then
				pcall(function() activeCloneEmoteTrack.Looped = true end)
			end
		end

		local intentionalMovement = moveDirectionMagnitude > 0.05 and moveSpeed > 1.2

		local shouldReleaseEmote = isSeated or intentionalMovement
			or state == Enum.HumanoidStateType.Jumping
			or state == Enum.HumanoidStateType.Freefall
			or state == Enum.HumanoidStateType.Climbing
			or state == Enum.HumanoidStateType.Swimming

		if shouldReleaseEmote and next(activeCloneTracks) ~= nil then
			stopAllCloneTracks(0.08)
		end

		local desiredKey = "Idle"
		local climbPlaybackSpeed = 0

		if isSeated and isR6 then
			local sitTrack = loadedTracks.Sit
			if sitTrack then
				for key, track in pairs(loadedTracks) do
					if key ~= "Sit" and track.IsPlaying then
						pcall(function() track:Stop(0.05) end)
					end
				end
				sitTrack.Priority = Enum.AnimationPriority.Action4
				sitTrack.Looped = true
				if not sitTrack.IsPlaying then
					pcall(function() sitTrack:Play(0.08, 1, 1) end)
				else
					pcall(function() sitTrack:AdjustWeight(1, 0.05) end)
				end
				activeKey = "Sit"
				return
			end
			desiredKey = "Sit"
		elseif isSeated then desiredKey = "Sit"
		elseif state == Enum.HumanoidStateType.Climbing then
			desiredKey = "Climb"
			if verticalVel > 0.1 then
				climbPlaybackSpeed = math.clamp(verticalVel / 8, 0.4, 2.0)
			elseif verticalVel < -0.1 then
				climbPlaybackSpeed = -math.clamp(math.abs(verticalVel) / 8, 0.4, 2.0)
			end
		elseif state == Enum.HumanoidStateType.Swimming then desiredKey = (totalVel > 0.75) and "Swim" or "SwimIdle"
		elseif state == Enum.HumanoidStateType.Jumping then desiredKey = "Jump"
		elseif state == Enum.HumanoidStateType.Freefall then
			desiredKey = (activeKey == "Jump" and loadedTracks["Jump"] and loadedTracks["Jump"].IsPlaying and verticalVel > 0.1) and "Jump" or "Fall"
		else
			if moveSpeed > 1.2 then
				desiredKey = (moveSpeed > 12 and loadedTracks["Run"]) and "Run" or "Walk"
			else desiredKey = "Idle" end
		end

		if not loadedTracks[desiredKey] then
			if desiredKey == "SwimIdle" then desiredKey = loadedTracks["Swim"] and "Swim" or (loadedTracks["Idle"] and "Idle" or "Walk")
			elseif desiredKey == "Swim" then desiredKey = loadedTracks["SwimIdle"] and "SwimIdle" or (loadedTracks["Walk"] and "Walk" or "Idle")
			elseif desiredKey == "Run" then desiredKey = "Walk" end
			if not loadedTracks[desiredKey] then desiredKey = "Idle" end
		end

		local activeTrack = activeKey and loadedTracks[activeKey]
		local desiredTrack = desiredKey and loadedTracks[desiredKey]

		local sameAnimationAsset = activeTrack and desiredTrack
			and activeTrack.Animation and desiredTrack.Animation
			and activeTrack.Animation.AnimationId == desiredTrack.Animation.AnimationId

		if activeKey ~= desiredKey and not sameAnimationAsset then
			if activeTrack then pcall(function() activeTrack:Stop(0.15) end) end
			activeKey = desiredKey
			activeTrack = loadedTracks[activeKey]
			if activeTrack then
				if activeKey == "Climb" then
					pcall(function() activeTrack:Play(0.15, 1, 0) end)
					if activeTrack.Length > 0 then
						pcall(function()
							activeTrack.TimePosition = (climbPlaybackSpeed < 0) and math.max(activeTrack.Length - 0.001, 0) or 0
						end)
					end
					pcall(function() activeTrack:AdjustSpeed(climbPlaybackSpeed) end)
				else
					pcall(function() activeTrack:Play(0.15) end)
				end
			end
		elseif activeTrack and not activeTrack.IsPlaying then
			if activeKey == "Climb" then
				pcall(function() activeTrack:Play(0.15, 1, 0) end)
				if activeTrack.Length > 0 then
					pcall(function()
						activeTrack.TimePosition = (climbPlaybackSpeed < 0) and math.max(activeTrack.Length - 0.001, 0) or 0
					end)
				end
				pcall(function() activeTrack:AdjustSpeed(climbPlaybackSpeed) end)
			else
				pcall(function() activeTrack:Play(0.15) end)
			end
		end

		if activeKey == "Walk" or activeKey == "Run" then
			local currentTrack = loadedTracks[activeKey]
			if currentTrack and currentTrack.IsPlaying then
				pcall(function() currentTrack:AdjustSpeed(math.clamp(moveSpeed / 14, 0.6, 2.0)) end)
			end
		elseif activeKey == "Climb" then
			local currentTrack = loadedTracks[activeKey]
			if currentTrack and currentTrack.IsPlaying then
				pcall(function() currentTrack:AdjustSpeed(climbPlaybackSpeed) end)
			end
		elseif activeKey == "Swim" or activeKey == "SwimIdle" then
			local currentTrack = loadedTracks[activeKey]
			if currentTrack and currentTrack.IsPlaying then
				local targetSpeed = isR6 and math.clamp(totalVel / 12, 0.5, 1.8) or math.clamp(totalVel / 10, 0.6, 2.0)
				if activeKey == "SwimIdle" and totalVel < 0.5 then targetSpeed = 1.0 end
				pcall(function() currentTrack:AdjustSpeed(targetSpeed) end)
			end
		end
	end
end

local function queuePreview(card, data)
	if not scriptAlive or not card or not data or not card.Parent then return end
	local state = previewStates[data]
	if state == "queued" or state == "loading" or state == "ready" then return end

	previewStates[data] = "queued"
	previewQueue[#previewQueue + 1] = {
		Card = card,
		Data = data,
		Generation = previewQueueGeneration
	}
end

local function preloadAvatarVisualContent(model)
	if not model then return false end
	local targets = {}
	for _, instance in ipairs(model:GetDescendants()) do
		if instance:IsA("MeshPart")
			or instance:IsA("SpecialMesh")
			or instance:IsA("Decal")
			or instance:IsA("Texture") then
			targets[#targets + 1] = instance
		end
	end
	if #targets == 0 then return true end
	return pcall(function() ContentProvider:PreloadAsync(targets) end)
end

local function createPreviewViewport(parentContainer)
	if not parentContainer or not parentContainer.Parent then return nil end

	local oldPreview = parentContainer:FindFirstChild("Preview")
	if oldPreview then oldPreview:Destroy() end

	local viewport = Instance.new("ViewportFrame")
	viewport.Name = "Preview"
	viewport.Size = UDim2.new(1, 0, 1, 0)
	viewport.BackgroundTransparency = 1
	viewport.BorderSizePixel = 0
	viewport.ZIndex = parentContainer.ZIndex + 1
	viewport.Parent = parentContainer

	local worldModel = Instance.new("WorldModel")
	worldModel.Parent = viewport

	local camera = Instance.new("Camera")
	camera.FieldOfView = 30
	camera.Parent = viewport
	viewport.CurrentCamera = camera

	return viewport, worldModel, camera
end

local function positionPreviewCamera(camera, model)
	if not camera or not model then return end
	local head = model:FindFirstChild("Head", true)
	local root = model:FindFirstChild("HumanoidRootPart", true) or head or model.PrimaryPart
	if not root then return end

	local cf, size = model:GetBoundingBox()
	if size.Magnitude <= 0 then return end

	local targetPosition = cf.Position + Vector3.new(0, size.Y * 0.04, 0)
	local lookVector = head and head.CFrame.LookVector or root.CFrame.LookVector
	if lookVector.Magnitude == 0 then lookVector = Vector3.new(0, 0, -1) end

	local distance = math.max(math.max(size.Y, size.X, size.Z) * 1.85, 5.5)
	camera.CFrame = CFrame.lookAt(targetPosition + lookVector.Unit * distance, targetPosition)
end

local function buildPreviewTemplate(data, cacheKey)
	if not data or not data.Properties then return nil end

	local description = reconstructHumanoidDescription(data.Properties)
	local rigType = getEnumRigType(data.RigType)
	local ok, model = pcall(function()
		if type(Players.CreateHumanoidModelFromDescriptionAsync) == "function" then
			return Players:CreateHumanoidModelFromDescriptionAsync(description, rigType)
		end
		return Players:CreateHumanoidModelFromDescription(description, rigType)
	end)
	pcall(function() description:Destroy() end)

	if not ok or not model or not model:IsA("Model") then
		if model and typeof(model) == "Instance" then pcall(function() model:Destroy() end) end
		return nil
	end

	model.Parent = nil
	model:PivotTo(CFrame.new(0, 0, 0))
	applyBodyColors(model, data.Properties)
	applyHeadShapeToModel(model, data.Properties)

	if cacheKey then
		previewModelCache[cacheKey] = model
		touchPreviewCache(cacheKey)
	end
	return model
end

local function renderPreview(card, data)
	if not card or not card.Parent or not data then return false end
	local previewContainer = card:FindFirstChild("PreviewContainer")
	if not previewContainer then return false end

	local cacheKey = getPreviewCacheKey(data)
	local template = cacheKey and previewModelCache[cacheKey]
	if template and template.Parent ~= nil then
		previewModelCache[cacheKey] = nil
		template = nil
	elseif template then
		touchPreviewCache(cacheKey)
	end

	for attempt = 1, 3 do
		if not scriptAlive or not card.Parent then return false end

		local viewport, worldModel, camera = createPreviewViewport(previewContainer)
		if not viewport then return false end

		if not template then
			template = buildPreviewTemplate(data, cacheKey)
		end

		if template then
			local model
			local cloneOk = pcall(function() model = template:Clone() end)
			if cloneOk and model then
				model.Parent = worldModel
				model:PivotTo(CFrame.new(0, 0, 0))
				task.wait()
				if model.Parent == worldModel and model:FindFirstChildOfClass("Humanoid") then
					positionPreviewCamera(camera, model)
					return true
				end
				pcall(function() model:Destroy() end)
			end
		end

		pcall(function() viewport:Destroy() end)
		if attempt < 3 then task.wait(0.12 * attempt) end
	end

	return false
end

local function processPreviewQueue()
	if previewQueueRunning then return end
	previewQueueRunning = true

	while scriptAlive and #previewQueue > 0 do
		local taskData = table.remove(previewQueue, 1)
		if taskData and taskData.Generation == previewQueueGeneration then
			local card = taskData.Card
			local data = taskData.Data
			if card and card.Parent and data then
				previewStates[data] = "loading"
				local ok, rendered = pcall(function()
					return renderPreview(card, data)
				end)
				if ok and rendered then
					previewStates[data] = "ready"
				else
					previewStates[data] = "unavailable"
				end
			end
		end
		task.wait(0.04)
	end

	previewQueueRunning = false
end

local function clearAvatarCards()
	previewQueueGeneration = previewQueueGeneration + 1
	table.clear(previewQueue)
	table.clear(previewStates)
	table.clear(avatarCards)
	clearPreviewModelCache()

	for _, child in ipairs(List:GetChildren()) do
		if child:IsA("Frame") and child.Name == "AvatarCard" then child:Destroy() end
	end
end

local function createAvatarCard(data, index)
	local Card = Instance.new("Frame")
	Card.Name = "AvatarCard"
	Card.Size = UDim2.new(0, isMobile and 132 or 148, 0, isMobile and 88 or 94)
	Card.BackgroundColor3 = Color3.fromRGB(28, 28, 36)
	Card.BorderSizePixel = 0
	Card.LayoutOrder = index
	Card.ClipsDescendants = true
	Card.Parent = List
	addCorner(Card, 8)
	addStroke(Card, Color3.fromRGB(45, 45, 58), 1)

	local PreviewContainer = Instance.new("Frame")
	PreviewContainer.Name = "PreviewContainer"
	PreviewContainer.Size = UDim2.new(0, isMobile and 60 or 66, 1, -8)
	PreviewContainer.Position = UDim2.new(0, 4, 0, 4)
	PreviewContainer.BackgroundColor3 = Color3.fromRGB(42, 42, 52)
	PreviewContainer.BorderSizePixel = 0
	PreviewContainer.Parent = Card
	addCorner(PreviewContainer, 6)

	local NameLabel = Instance.new("TextLabel")
	NameLabel.Name = "DisplayName"
	NameLabel.Size = UDim2.new(1, isMobile and -70 or -78, 0, 18)
	NameLabel.Position = UDim2.new(0, isMobile and 68 or 74, 0, 10)
	NameLabel.BackgroundTransparency = 1
	NameLabel.Text = tostring(data.DisplayName or data.Name or "Unknown")
	NameLabel.TextColor3 = Color3.fromRGB(235, 235, 245)
	NameLabel.TextSize = isMobile and 8 or 9
	NameLabel.Font = Enum.Font.GothamBold
	NameLabel.TextTruncate = Enum.TextTruncate.AtEnd
	NameLabel.TextXAlignment = Enum.TextXAlignment.Left
	NameLabel.Parent = Card

	local Username = Instance.new("TextLabel")
	Username.Name = "Username"
	Username.Size = UDim2.new(1, isMobile and -70 or -78, 0, 16)
	Username.Position = UDim2.new(0, isMobile and 68 or 74, 0, 30)
	Username.BackgroundTransparency = 1
	Username.Text = "@" .. tostring(data.Name or "unknown")
	Username.TextColor3 = Color3.fromRGB(145, 145, 160)
	Username.TextSize = isMobile and 7 or 8
	Username.Font = Enum.Font.Gotham
	Username.TextTruncate = Enum.TextTruncate.AtEnd
	Username.TextXAlignment = Enum.TextXAlignment.Left
	Username.Parent = Card

	local SelectButton = Instance.new("TextButton")
	SelectButton.Name = "SelectButton"
	SelectButton.BackgroundColor3 = (selectedAvatar == data) and Color3.fromRGB(0, 170, 255) or Color3.fromRGB(35, 38, 48)
	SelectButton.BorderSizePixel = 0
	SelectButton.Text = (selectedAvatar == data) and "Selected" or "SELECT"
	SelectButton.TextColor3 = Color3.fromRGB(225, 225, 235)
	SelectButton.TextSize = 8
	SelectButton.Font = Enum.Font.GothamBold
	SelectButton.AutoButtonColor = false
	SelectButton.Size = UDim2.new(1, -76, 0, 22)
	SelectButton.Position = UDim2.new(0, 70, 1, -28)
	SelectButton.Parent = Card
	addCorner(SelectButton, 6)
	addStroke(SelectButton, Color3.fromRGB(60, 62, 78), 1)

	wire(SelectButton.MouseEnter, function()
		TweenService:Create(SelectButton, TweenInfo.new(0.15), {BackgroundColor3 = (selectedAvatar == data) and Color3.fromRGB(30, 180, 255) or Color3.fromRGB(48, 52, 66)}):Play()
	end)
	wire(SelectButton.MouseLeave, function()
		TweenService:Create(SelectButton, TweenInfo.new(0.15), {BackgroundColor3 = (selectedAvatar == data) and Color3.fromRGB(0, 170, 255) or Color3.fromRGB(35, 38, 48)}):Play()
	end)

	wire(SelectButton.Activated, function()
		selectedAvatar = data
		for _, child in ipairs(List:GetChildren()) do
			if child:IsA("Frame") and child.Name == "AvatarCard" then
				local btn = child:FindFirstChild("SelectButton")
				if btn then
					local isSelected = (btn == SelectButton)
					btn.Text = isSelected and "Selected" or "SELECT"
					btn.BackgroundColor3 = isSelected and Color3.fromRGB(0, 170, 255) or Color3.fromRGB(35, 38, 48)
				end
			end
		end
		Status.Text = "[OK] Selected: @" .. tostring(data.Name or "unknown")
		clearDiagnostics()
	end)

	avatarCards[data] = Card
end

local function filterAvatarCards(query)
	query = string.lower(string.match(tostring(query or ""), "^%s*(.-)%s*$"))
	local shown = 0
	previewQueueGeneration = previewQueueGeneration + 1
	table.clear(previewQueue)

	for _, data in ipairs(savedAvatars) do
		local matches = query == ""
			or string.lower(tostring(data.DisplayName or "")):find(query, 1, true)
			or string.lower(tostring(data.Name or "")):find(query, 1, true)
			or string.lower(tostring(data.FileName or "")):find(query, 1, true)
			or string.lower(tostring(data.UserId or "")):find(query, 1, true)
			or string.lower(tostring(data.RigType or "")):find(query, 1, true)

		local card = avatarCards[data]
		if card and card.Parent then
			card.Visible = matches
			if matches then
				shown += 1
				if previewStates[data] ~= "ready" then
					previewStates[data] = nil
					queuePreview(card, data)
				end
			else
				previewStates[data] = (previewStates[data] == "ready") and "ready" or nil
			end
		end
	end

	Status.Text = "[File] " .. tostring(shown) .. "/" .. tostring(#savedAvatars) .. " avatar(s) shown"
	if not previewQueueRunning then task.spawn(processPreviewQueue) end
end

local function populateAvatarList()
	clearAvatarCards()
	for index, data in ipairs(savedAvatars) do createAvatarCard(data, index) end
	filterAvatarCards(SearchBox.Text)
end

local function restoreLocalCharacter()
	for part, oldTransparency in pairs(hiddenCharacterParts) do
		pcall(function()
			if part and part.Parent then part.LocalTransparencyModifier = oldTransparency end
		end)
	end
	table.clear(hiddenCharacterParts)

	for decal, oldTransparency in pairs(hiddenCharacterDecals) do
		pcall(function()
			if decal and decal.Parent then decal.Transparency = oldTransparency end
		end)
	end
	table.clear(hiddenCharacterDecals)
end

local function destroyOrphanedLocalTryOnModels(exceptModel)
	for _, instance in ipairs(Workspace:GetDescendants()) do
		if instance:IsA("Model") and instance.Name == "LocalWearer_LocalTryOn" and instance ~= exceptModel then
			pcall(function() instance:Destroy() end)
		end
	end
end

local function stopLocalTryOn(preserveActiveState)
	localTryOnBuildId = localTryOnBuildId + 1
	localTryOnBuilding = false
	localTryOnMissingRecoveryPending = false
	if not preserveActiveState then tryOnActive = false end

	cleanupAnimationSync()
	disconnectLocalTryOnConnections()

	if localTryOnModel then
		pcall(function() localTryOnModel:Destroy() end)
		localTryOnModel = nil
	end

	destroyOrphanedLocalTryOnModels(nil)

	resetLocalTryOnState()
	restoreLocalCharacter()
	updateWearButtonState()
end

local function abortLocalTryOnForSeatedPlayer()
	stopLocalTryOn(false)
	WearButton.Active = true
	updateWearButtonState()
	showSeatedTryOnBlocked()
end

local CHARACTER_BODY_PART_NAMES = {
	Head = true,
	HumanoidRootPart = true,
	Torso = true,
	UpperTorso = true,
	LowerTorso = true,
	["Left Arm"] = true,
	["Right Arm"] = true,
	["Left Leg"] = true,
	["Right Leg"] = true,
	LeftUpperArm = true,
	LeftLowerArm = true,
	LeftHand = true,
	RightUpperArm = true,
	RightLowerArm = true,
	RightHand = true,
	LeftUpperLeg = true,
	LeftLowerLeg = true,
	LeftFoot = true,
	RightUpperLeg = true,
	RightLowerLeg = true,
	RightFoot = true,
}

local function getCharacterTopLevel(instance, character)
	local current = instance
	while current and current.Parent and current.Parent ~= character do
		current = current.Parent
	end
	return current and current.Parent == character and current or nil
end

local function isExternalCharacterAttachment(instance, character)
	if instance:FindFirstAncestorOfClass("Tool") or instance:FindFirstAncestorOfClass("VehicleSeat") then
		return true
	end

	local topLevel = getCharacterTopLevel(instance, character)
	if not topLevel then return true end

	if topLevel:IsA("Accessory") then
		return false
	end

	local modelAncestor = instance:FindFirstAncestorOfClass("Model")
	if modelAncestor and modelAncestor ~= character then
		return true
	end

	if topLevel:IsA("BasePart") and CHARACTER_BODY_PART_NAMES[topLevel.Name] then
		if instance:IsA("BasePart") and instance ~= topLevel and instance.Parent == topLevel and not CHARACTER_BODY_PART_NAMES[instance.Name] then
			return true
		end
		return false
	end

	return true
end

local function hideCharacterInstance(instance)
	if not instance then return end
	local character = LocalPlayer.Character
	if not character or not instance:IsDescendantOf(character) then return end
	if isExternalCharacterAttachment(instance, character) then return end

	if instance:IsA("BasePart") then
		if hiddenCharacterParts[instance] == nil then
			hiddenCharacterParts[instance] = instance.LocalTransparencyModifier
		end
		instance.LocalTransparencyModifier = 1
	elseif instance:IsA("Decal") or instance:IsA("Texture") then
		if hiddenCharacterDecals[instance] == nil then
			hiddenCharacterDecals[instance] = instance.Transparency
		end
		instance.Transparency = 1
	end
end

local function hideCharacterLocally(character)
	if not character then return end
	for _, instance in ipairs(character:GetDescendants()) do
		hideCharacterInstance(instance)
	end
	setLocalTryOnConnection("visibility", character.DescendantAdded, hideCharacterInstance)
end

local function enforceCharacterHidden()
	for part in pairs(hiddenCharacterParts) do
		if part and part.Parent and part.LocalTransparencyModifier ~= 1 then
			part.LocalTransparencyModifier = 1
		end
	end
	for decal in pairs(hiddenCharacterDecals) do
		if decal and decal.Parent and decal.Transparency ~= 1 then
			decal.Transparency = 1
		end
	end
end

local function isFirstPersonCamera(character)
	local camera = Workspace.CurrentCamera
	local head = character and character:FindFirstChild("Head", true)
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not camera or not head or not humanoid then return false end

	local cameraDistance = (camera.CFrame.Position - head.Position).Magnitude
	local cameraFollowsCharacter = camera.CameraSubject == humanoid or (camera.CameraSubject and camera.CameraSubject:IsDescendantOf(character))
	return cameraFollowsCharacter and cameraDistance <= 1.65
end

local function setLocalTryOnFirstPersonVisibility(hidden)
	if not localTryOnModel or localTryOnHiddenInFirstPerson == hidden then return end
	localTryOnHiddenInFirstPerson = hidden

	for _, instance in ipairs(localTryOnModel:GetDescendants()) do
		if instance:IsA("BasePart") then
			instance.LocalTransparencyModifier = hidden and 1 or 0
		elseif instance:IsA("Decal") or instance:IsA("Texture") then
			pcall(function() instance.LocalTransparencyModifier = hidden and 1 or 0 end)
		end
	end
end

local function disableLocalTryOnCollision(instance)
	if not instance or not instance:IsA("BasePart") then return end
	localTryOnCollisionParts[instance] = true
	pcall(function()
		if instance.CanCollide then instance.CanCollide = false end
		if instance.CanTouch then instance.CanTouch = false end
		if instance.CanQuery then instance.CanQuery = false end
		if not instance.Massless then instance.Massless = true end
	end)
end

local function enforceLocalTryOnNoCollision()
	for instance in pairs(localTryOnCollisionParts) do
		if instance and instance.Parent then
			pcall(function()
				if instance.CanCollide then instance.CanCollide = false end
				if instance.CanTouch then instance.CanTouch = false end
				if instance.CanQuery then instance.CanQuery = false end
				if not instance.Massless then instance.Massless = true end
			end)
		else
			localTryOnCollisionParts[instance] = nil
		end
	end
end

local function isLocalTryOnModelValid(model)
	if not model or not model:IsA("Model") then return false end
	if not model:IsDescendantOf(Workspace) then return false end
	if not model:FindFirstChildOfClass("Humanoid") then return false end
	local root = model:FindFirstChild("HumanoidRootPart", true) or model.PrimaryPart or model:FindFirstChild("Head", true)
	return root ~= nil and root:IsA("BasePart")
end

local function prepareLocalModel(model)
	local modelHumanoid = model:FindFirstChildOfClass("Humanoid")
	if modelHumanoid then
		modelHumanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
		modelHumanoid.RequiresNeck = false
		modelHumanoid.AutomaticScalingEnabled = false
		pcall(function() modelHumanoid.EvaluateStateMachine = false end)
		pcall(function()
			for _, state in ipairs(Enum.HumanoidStateType:GetEnumItems()) do
				if state ~= Enum.HumanoidStateType.None then modelHumanoid:SetStateEnabled(state, false) end
			end
			modelHumanoid:ChangeState(Enum.HumanoidStateType.None)
		end)
	end

	local rootPart = model:FindFirstChild("HumanoidRootPart") or model.PrimaryPart
	for _, instance in ipairs(model:GetDescendants()) do
		if instance:IsA("BasePart") then
			instance.Anchored = (instance == rootPart)
			instance.CanCollide = false
			instance.CanTouch = false
			instance.CanQuery = false
			instance.Massless = true
			instance.LocalTransparencyModifier = 0
		elseif instance:IsA("Decal") or instance:IsA("Texture") then
			pcall(function() instance.LocalTransparencyModifier = 0 end)
		elseif instance:IsA("Script") or instance:IsA("LocalScript") then
			pcall(function() instance.Disabled = true end)
		end
	end
end

local function setLocalTryOnStagingVisibility(model, hidden)
	if not model then return end
	for _, instance in ipairs(model:GetDescendants()) do
		if instance:IsA("BasePart") then
			instance.LocalTransparencyModifier = hidden and 1 or 0
		elseif instance:IsA("Decal") or instance:IsA("Texture") then
			pcall(function() instance.LocalTransparencyModifier = hidden and 1 or 0 end)
		end
	end
end

local function getPartBottomY(part)
	local halfSize = part.Size / 2
	local lowestY = math.huge
	for _, x in ipairs({-halfSize.X, halfSize.X}) do
		for _, y in ipairs({-halfSize.Y, halfSize.Y}) do
			for _, z in ipairs({-halfSize.Z, halfSize.Z}) do
				lowestY = math.min(lowestY, part.CFrame:PointToWorldSpace(Vector3.new(x, y, z)).Y)
			end
		end
	end
	return lowestY
end

local function getFeetBottomY(model)
	local footNames = {"LeftFoot", "RightFoot", "Left Leg", "Right Leg"}
	local lowestY = math.huge
	local foundFoot = false
	local seen = {}

	for _, footName in ipairs(footNames) do
		local foot = model:FindFirstChild(footName, true)
		if foot and foot:IsA("BasePart") and not seen[foot] then
			seen[foot] = true
			foundFoot = true
			lowestY = math.min(lowestY, getPartBottomY(foot))
		end
	end
	return foundFoot and lowestY or nil
end

local function calculateLocalTryOnSwimOffset(character, model, characterRoot, generatedRoot)
	local charTorso = character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso") or characterRoot
	local modelTorso = model:FindFirstChild("UpperTorso") or model:FindFirstChild("Torso") or generatedRoot
	local charTorsoY = characterRoot.CFrame:ToObjectSpace(charTorso.CFrame).Y
	local modelTorsoY = generatedRoot.CFrame:ToObjectSpace(modelTorso.CFrame).Y
	return Vector3.new(0, charTorsoY - modelTorsoY, 0)
end

local function calculateGroundOffsetFromCurrentPlacement(character, model, currentOffset)
	if not character or not model then return nil end
	local characterFeetY = getFeetBottomY(character)
	local modelFeetY = getFeetBottomY(model)
	if not characterFeetY or not modelFeetY then return nil end

	local currentOffsetY = currentOffset and currentOffset.Y or 0
	return Vector3.new(0, characterFeetY - modelFeetY + currentOffsetY, 0)
end

local function calculateGroundOffsetFromNeutralCloneFeet(character, characterRoot)
	if not character or not characterRoot or localTryOnNeutralCloneFeetRootOffsetY == nil then return nil end
	local characterFeetY = getFeetBottomY(character)
	if not characterFeetY then return nil end
	return Vector3.new(0, characterFeetY - characterRoot.Position.Y - localTryOnNeutralCloneFeetRootOffsetY, 0)
end

local function getLocalTryOnHipReference(model)
	if not model then return nil end

	local lowerTorso = model:FindFirstChild("LowerTorso", true)
	if lowerTorso and lowerTorso:IsA("BasePart") then
		local leftHipRigAttachment = lowerTorso:FindFirstChild("LeftHipRigAttachment")
		local rightHipRigAttachment = lowerTorso:FindFirstChild("RightHipRigAttachment")
		if leftHipRigAttachment and leftHipRigAttachment:IsA("Attachment")
			and rightHipRigAttachment and rightHipRigAttachment:IsA("Attachment") then
			return (leftHipRigAttachment.WorldPosition + rightHipRigAttachment.WorldPosition) * 0.5
		end

		local leftUpperLeg = model:FindFirstChild("LeftUpperLeg", true)
		local rightUpperLeg = model:FindFirstChild("RightUpperLeg", true)
		local leftHipAttachment = leftUpperLeg and leftUpperLeg:FindFirstChild("LeftHipAttachment")
		local rightHipAttachment = rightUpperLeg and rightUpperLeg:FindFirstChild("RightHipAttachment")
		if leftHipAttachment and leftHipAttachment:IsA("Attachment")
			and rightHipAttachment and rightHipAttachment:IsA("Attachment") then
			return (leftHipAttachment.WorldPosition + rightHipAttachment.WorldPosition) * 0.5
		end
	end

	local torso = model:FindFirstChild("Torso", true)
	if torso and torso:IsA("BasePart") then
		local leftHip = torso:FindFirstChild("Left Hip")
		local rightHip = torso:FindFirstChild("Right Hip")
		if leftHip and leftHip:IsA("Motor6D") and rightHip and rightHip:IsA("Motor6D") then
			local leftPart0 = leftHip.Part0 or torso
			local rightPart0 = rightHip.Part0 or torso
			local leftJointWorld = leftPart0.CFrame * leftHip.C0 * leftHip.Transform
			local rightJointWorld = rightPart0.CFrame * rightHip.C0 * rightHip.Transform
			return (leftJointWorld.Position + rightJointWorld.Position) * 0.5
		end
	end

	return nil
end

local function calculateLocalTryOnSeatedHipOffset(character, model, currentOffset)
	if not scriptAlive or not model or model ~= localTryOnModel or not model:IsDescendantOf(Workspace) then return nil end
	if not character or not character.Parent then return nil end

	local characterHip = getLocalTryOnHipReference(character)
	local modelHip = getLocalTryOnHipReference(model)
	if not characterHip or not modelHip then return nil end

	local baseOffset = currentOffset or Vector3.zero
	return baseOffset + (characterHip - modelHip)
end

local function getLocalTryOnSeatedHipOffsetLocal(characterRoot, worldOffset)
	if not characterRoot or not worldOffset then return Vector3.zero end
	return characterRoot.CFrame:VectorToObjectSpace(worldOffset)
end

local function isCloneSitAnimationSettled(model)
	if not model then return false end

	local humanoid = model:FindFirstChildOfClass("Humanoid")
	if not humanoid then return false end

	local animator = humanoid:FindFirstChildOfClass("Animator")
	if not animator then return false end

	local enumRig = humanoid.RigType
	local isR6 = enumRig == Enum.HumanoidRigType.R6
		or (model:FindFirstChild("Torso") ~= nil and model:FindFirstChild("UpperTorso") == nil)
	local resolved = resolveAnimationIds(model, nil, isR6)
	local sitId = parseAssetId(resolved and resolved.Sit)
	if not sitId then return false end

	local sitTrack = nil
	for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
		if track and track.Animation then
			local trackId = parseAssetId(track.Animation.AnimationId)
			if trackId == sitId and track.IsPlaying then
				sitTrack = track
				break
			end
		end
	end
	if not sitTrack then return false end

	if sitTrack.WeightTarget < 0.95 then return false end
	if math.abs(sitTrack.WeightCurrent - sitTrack.WeightTarget) > 0.02 then return false end

	for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
		if track ~= sitTrack and track.IsPlaying and track.WeightCurrent > 0.05 then
			return false
		end
	end

	return true
end

local function isPlayerSitAnimationCleared(character)
	if not character then return true end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return true end

	local animator = humanoid:FindFirstChildOfClass("Animator")
	if not animator then return true end

	local isR6 = humanoid.RigType == Enum.HumanoidRigType.R6
		or (character:FindFirstChild("Torso") ~= nil and character:FindFirstChild("UpperTorso") == nil)
	local resolved = resolveAnimationIds(character, nil, isR6)
	local sitId = parseAssetId(resolved and resolved.Sit)
	if not sitId then return true end

	for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
		if track and track.Animation then
			local trackId = parseAssetId(track.Animation.AnimationId)
			if trackId == sitId and (track.IsPlaying or track.WeightCurrent > 0.05 or track.WeightTarget > 0.05) then
				return false
			end
		end
	end

	return true
end

local function waitForCloneSitAnimationToSettle(character, model, playerHumanoid, seatPart, timeoutSeconds)
	local deadline = os.clock() + (timeoutSeconds or 0.6)

	while scriptAlive and os.clock() < deadline do
		if not character or not character.Parent or not playerHumanoid then return false end
		if not model or model ~= localTryOnModel or not model:IsDescendantOf(Workspace) then return false end

		local state = playerHumanoid:GetState()
		local stillSeated = playerHumanoid.Sit
			or playerHumanoid.SeatPart ~= nil
			or state == Enum.HumanoidStateType.Seated
		if not stillSeated or playerHumanoid.SeatPart ~= seatPart then return false end

		if isCloneSitAnimationSettled(model) then
			return true
		end

		RunService.Heartbeat:Wait()
	end

	return false
end

local function scheduleSeatHipCalibrationAfterHeartbeat(character, model, playerHumanoid, seatPart, baseGroundOffset)
	localTryOnSeatCalibrationToken = localTryOnSeatCalibrationToken + 1
	local calibrationToken = localTryOnSeatCalibrationToken
	localTryOnSeatCalibrationPending = true

	task.spawn(function()
		local settled = waitForCloneSitAnimationToSettle(character, model, playerHumanoid, seatPart, 0.6)

		if not scriptAlive or calibrationToken ~= localTryOnSeatCalibrationToken then return end
		if not settled then
			localTryOnSeatCalibrationPending = false
			return
		end
		if not model or model ~= localTryOnModel or not model:IsDescendantOf(Workspace) then
			localTryOnSeatCalibrationPending = false
			return
		end
		if not character or not character.Parent or not playerHumanoid then
			localTryOnSeatCalibrationPending = false
			return
		end

		local state = playerHumanoid:GetState()
		local stillSeated = playerHumanoid.Sit or playerHumanoid.SeatPart ~= nil or state == Enum.HumanoidStateType.Seated
		if not stillSeated or playerHumanoid.SeatPart ~= seatPart then
			localTryOnSeatCalibrationPending = false
			return
		end

		local characterRoot = character:FindFirstChild("HumanoidRootPart") or character.PrimaryPart
		if not characterRoot then
			localTryOnSeatCalibrationPending = false
			return
		end

		local seatedOffset = calculateLocalTryOnSeatedHipOffset(character, model, baseGroundOffset)
		if seatedOffset then
			localTryOnSeatedHipOffsetLocal = getLocalTryOnSeatedHipOffsetLocal(characterRoot, seatedOffset)
			localTryOnSeatedHipOffsetValid = true
			localTryOnPositionMode = "Seat"
		end
		localTryOnSeatCalibrationPending = false
	end)
end

local function isGroundPlacementState(state)
	return state == Enum.HumanoidStateType.Running
		or state == Enum.HumanoidStateType.Landed
		or state == Enum.HumanoidStateType.Standing
		or state == Enum.HumanoidStateType.PlatformStanding
end

local function tryOnSelectedAvatarLocally()
	if localTryOnBuilding then return end

	local selectedData = selectedAvatar
	if not selectedData or not selectedData.Properties then
		Status.Text = "[!] Select an avatar first."
		clearDiagnostics()
		return
	end

	local character = LocalPlayer.Character
	local initialHumanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not character or not character.Parent then
		showDiagnostics("Local try-on failed.", "Your character is not available yet. Waiting for spawn...")
		return
	end

	if isCharacterCurrentlySitting(character, initialHumanoid) then
		abortLocalTryOnForSeatedPlayer()
		return
	end

	tryOnActive = true
	stopLocalTryOn(true)
	localTryOnBuildId = localTryOnBuildId + 1
	local currentBuildId = localTryOnBuildId
	localTryOnBuilding = true
	WearButton.Active = false
	updateWearButtonState()
	Status.Text = "[...] Building local avatar..."
	clearDiagnostics()

	local rigType = getEnumRigType(selectedData.RigType)
	local playerHumanoidForEmotes = initialHumanoid
	local lastTryOnError = "Unknown local avatar creation failure."
	local seatDetectedDuringBuild = false

	if initialHumanoid then
		setLocalTryOnConnection("buildSeat", initialHumanoid.Seated, function(active)
			if active then
				seatDetectedDuringBuild = true
			end
		end)
	end

	local function seatBlockedDuringBuild()
		return seatDetectedDuringBuild or isCharacterCurrentlySitting(character, initialHumanoid)
	end

	for attempt = 1, 3 do
		if seatBlockedDuringBuild() then
			abortLocalTryOnForSeatedPlayer()
			return
		end
		if not scriptAlive or currentBuildId ~= localTryOnBuildId then
			localTryOnBuilding = false
			WearButton.Active = true
			updateWearButtonState()
			return
		end

		if attempt > 1 then
			Status.Text = string.format("[...] Retrying local avatar... (%d/3)", attempt)
			task.wait(0.1 * (attempt - 1))
			if seatBlockedDuringBuild() then
				abortLocalTryOnForSeatedPlayer()
				return
			end
			if not scriptAlive or currentBuildId ~= localTryOnBuildId then
				localTryOnBuilding = false
				WearButton.Active = true
				updateWearButtonState()
				return
			end
		end

		local description = reconstructHumanoidDescription(selectedData.Properties)
		mergePlayerEmotesIntoDescription(description, playerHumanoidForEmotes, rigType)

		local okCreate, modelOrError = pcall(function()
			return Players:CreateHumanoidModelFromDescriptionAsync(description, rigType)
		end)
		pcall(function() description:Destroy() end)

		if seatBlockedDuringBuild() then
			if typeof(modelOrError) == "Instance" then
				pcall(function() modelOrError:Destroy() end)
			end
			abortLocalTryOnForSeatedPlayer()
			return
		end

		if not okCreate or typeof(modelOrError) ~= "Instance" or not modelOrError:IsA("Model") then
			lastTryOnError = tostring(modelOrError)
			if modelOrError and typeof(modelOrError) == "Instance" then
				pcall(function() modelOrError:Destroy() end)
			end
			continue
		end

		local model = modelOrError
		local updateCloneAnims = nil
		local okSetup, setupError = pcall(function()
			model.Name = "LocalWearer_LocalTryOn"
			applyBodyColors(model, selectedData.Properties)
			applyHeadShapeToModel(model, selectedData.Properties)
			applyRigidAccessoryRefinements(model, selectedData.Properties)

			local generatedRoot = model:FindFirstChild("HumanoidRootPart", true) or model.PrimaryPart or model:FindFirstChild("Head", true)
			local characterRoot = character:FindFirstChild("HumanoidRootPart") or character.PrimaryPart

			if not generatedRoot then error("Generated avatar missing root part.") end
			if not characterRoot then error("Your character missing root part.") end

			prepareLocalModel(model)

			for _, instance in ipairs(model:GetDescendants()) do
				disableLocalTryOnCollision(instance)
			end

			setLocalTryOnConnection("collision", model.DescendantAdded, disableLocalTryOnCollision)

			setLocalTryOnConnection("preSimulation", RunService.PreSimulation, enforceLocalTryOnNoCollision)
			enforceLocalTryOnNoCollision()

			setLocalTryOnStagingVisibility(model, true)
			generatedRoot.CFrame = characterRoot.CFrame + Vector3.new(0, 100, 0)
			model.Parent = Workspace
			if not isLocalTryOnModelValid(model) then
				error("Generated avatar was removed or invalid immediately after entering Workspace.")
			end

			localTryOnModel = model

			RunService.Heartbeat:Wait()
			if seatBlockedDuringBuild() then
				error("Local try-on blocked: player became seated during avatar build.")
			end
			if not isLocalTryOnModelValid(model) then
				error("Generated avatar did not survive initial rig settling.")
			end

			generatedRoot = model:FindFirstChild("HumanoidRootPart", true) or model.PrimaryPart or model:FindFirstChild("Head", true)
			if not generatedRoot then error("Generated avatar root disappeared after rig settling.") end

			generatedRoot.CFrame = characterRoot.CFrame

			local initialState = initialHumanoid and initialHumanoid:GetState()
			local initiallySwimming = initialState == Enum.HumanoidStateType.Swimming

			currentVerticalOffset = Vector3.zero
			localTryOnRootPart = generatedRoot
			localTryOnSwimOffset = calculateLocalTryOnSwimOffset(character, model, characterRoot, generatedRoot)
			local cloneFeetY = getFeetBottomY(model)
			localTryOnNeutralCloneFeetRootOffsetY = cloneFeetY and (cloneFeetY - characterRoot.Position.Y) or nil
			localTryOnGroundOffset = calculateGroundOffsetFromCurrentPlacement(character, model, Vector3.zero)
			if not localTryOnGroundOffset then
				error("Could not establish initial feet-to-feet ground alignment.")
			end
			localTryOnGroundOffsetValid = true
			localTryOnSeatedHipOffsetValid = false
			localTryOnPositionMode = "Ground"
			localTryOnSeatCalibrationPending = false
			localTryOnSeatCalibrationToken = localTryOnSeatCalibrationToken + 1
			localTryOnGroundCalibrationFrames = 0
			localTryOnSwimTransitionActive = false
			localTryOnSwimTransitionStart = Vector3.zero
			localTryOnSwimTransitionStartedAt = 0
			localTryOnLastSwimming = initiallySwimming
			localTryOnSeatPart = nil

			currentVerticalOffset = initiallySwimming and localTryOnSwimOffset or localTryOnGroundOffset
			localTryOnRootPart.CFrame = characterRoot.CFrame + currentVerticalOffset

			enforceLocalTryOnNoCollision()
			setLocalTryOnStagingVisibility(model, false)
			localTryOnHiddenInFirstPerson = false
			setLocalTryOnFirstPersonVisibility(isFirstPersonCamera(character))

			updateCloneAnims = bindAnimationSync(character, model, selectedData.Properties, selectedData.RigType)

			if seatBlockedDuringBuild() then
				error("Local try-on blocked: player became seated during avatar build.")
			end

			if not isLocalTryOnModelValid(model) then
				error("Generated avatar did not survive animation setup.")
			end

			hideCharacterLocally(character)

			task.spawn(function()
				if scriptAlive and model.Parent and model:IsDescendantOf(Workspace) then
					preloadAvatarVisualContent(model)
				end
			end)
		end)

		if not okSetup then
			if localTryOnModel == model then localTryOnModel = nil end
			setLocalTryOnConnection("collision", nil)
			setLocalTryOnConnection("preSimulation", nil)
			pcall(function() model:Destroy() end)
			lastTryOnError = tostring(setupError)
			if seatBlockedDuringBuild() then
				abortLocalTryOnForSeatedPlayer()
				return
			end
		end

		if okSetup and scriptAlive and currentBuildId == localTryOnBuildId and isLocalTryOnModelValid(model) then
			if seatBlockedDuringBuild() then
				abortLocalTryOnForSeatedPlayer()
				return
			end

			destroyOrphanedLocalTryOnModels(model)
			enforceLocalTryOnNoCollision()
			setLocalTryOnConnection("buildSeat", nil)
			localTryOnBuilding = false
			WearButton.Active = true
			setLocalTryOnConnection("position", RunService.RenderStepped, function()
				if not scriptAlive then return end

				if not localTryOnModel or not localTryOnModel:IsDescendantOf(Workspace) then
					if tryOnActive and not localTryOnBuilding and not localTryOnMissingRecoveryPending then
						localTryOnMissingRecoveryPending = true
						local missingBuildId = localTryOnBuildId
						task.delay(0.15, function()
							localTryOnMissingRecoveryPending = false
							if not scriptAlive or missingBuildId ~= localTryOnBuildId or localTryOnBuilding or not tryOnActive then return end
							if not localTryOnModel or not localTryOnModel:IsDescendantOf(Workspace) then
								stopLocalTryOn(false)
								Status.Text = "[!] Local try-on was removed by this experience. Original avatar restored."
								showDiagnostics(
									"Local try-on unavailable in this experience.",
									"The generated avatar was removed after creation. Your real avatar has been restored. Try again; some games replace or restrict local Humanoid models."
								)
							end
						end)
					end
					return
				end

				localTryOnMissingRecoveryPending = false
				enforceLocalTryOnNoCollision()

				if not character or not character.Parent then
					stopLocalTryOn(tryOnActive)
					updateWearButtonState()
					if tryOnActive then Status.Text = "[...] Character respawning..." end
					return
				end

				local characterRoot = character:FindFirstChild("HumanoidRootPart") or character.PrimaryPart
				local playerHumanoid = character:FindFirstChildOfClass("Humanoid")

				if not characterRoot or not localTryOnRootPart then
					stopLocalTryOn(tryOnActive)
					updateWearButtonState()
					if tryOnActive then Status.Text = "[...] Waiting for character..." end
					return
				end

				local currentState = playerHumanoid and playerHumanoid:GetState()
				local isSwimming = (currentState == Enum.HumanoidStateType.Swimming)
				local isSeated = playerHumanoid and (playerHumanoid.Sit or playerHumanoid.SeatPart ~= nil or currentState == Enum.HumanoidStateType.Seated) or false
				local seatPart = playerHumanoid and playerHumanoid.SeatPart or nil

				if not isSeated and isSwimming ~= localTryOnLastSwimming then
					localTryOnLastSwimming = isSwimming
					localTryOnSwimTransitionActive = isSwimming or localTryOnGroundOffsetValid
					localTryOnSwimTransitionStart = currentVerticalOffset
					localTryOnSwimTransitionStartedAt = os.clock()
				elseif isSeated then
					localTryOnLastSwimming = isSwimming
					localTryOnSwimTransitionActive = false
				end

				if updateCloneAnims then updateCloneAnims() end

				local targetOffset = currentVerticalOffset

				if isSeated then
					if (localTryOnPositionMode ~= "Seat" and not localTryOnSeatCalibrationPending) or localTryOnSeatPart ~= seatPart then
						localTryOnPositionMode = "SeatCalibration"
						localTryOnGroundCalibrationFrames = 0
						localTryOnSeatPart = seatPart
						localTryOnSeatedHipOffsetValid = false
						localTryOnSeatTransitionActive = false
						if not localTryOnSeatCalibrationPending then
							scheduleSeatHipCalibrationAfterHeartbeat(character, localTryOnModel, playerHumanoid, seatPart, localTryOnGroundOffset)
						end
					end

					if localTryOnSeatedHipOffsetValid then
						if not localTryOnSeatTransitionActive then
							localTryOnSeatTransitionActive = true
							localTryOnSeatTransitionStartLocal = characterRoot.CFrame:VectorToObjectSpace(currentVerticalOffset)
							localTryOnSeatTransitionStartedAt = os.clock()
						end

						local alpha = math.clamp((os.clock() - localTryOnSeatTransitionStartedAt) / 0.16, 0, 1)
						local eased = alpha * alpha * (3 - 2 * alpha)
						local blendedLocalOffset = localTryOnSeatTransitionStartLocal:Lerp(localTryOnSeatedHipOffsetLocal, eased)
						targetOffset = characterRoot.CFrame:VectorToWorldSpace(blendedLocalOffset)
					else
						targetOffset = currentVerticalOffset
					end
				else
					if localTryOnPositionMode == "Seat" or localTryOnPositionMode == "SeatCalibration" then
						localTryOnSeatCalibrationToken = localTryOnSeatCalibrationToken + 1
						localTryOnSeatCalibrationPending = false
						localTryOnSeatPart = nil
						localTryOnSeatedHipOffsetValid = false
						localTryOnSeatTransitionActive = false
						localTryOnSeatTransitionStartLocal = Vector3.zero
						localTryOnSeatTransitionStartedAt = 0
						if localTryOnGroundOffsetValid then
							localTryOnPositionMode = "Ground"
							localTryOnGroundCalibrationFrames = 0
							targetOffset = isSwimming and localTryOnSwimOffset or localTryOnGroundOffset
						else
							localTryOnPositionMode = "GroundCalibration"
							localTryOnGroundCalibrationFrames = 2
						end
					end

					if localTryOnPositionMode == "GroundCalibration" then
						if not isSwimming and isGroundPlacementState(currentState) then
							if not isPlayerSitAnimationCleared(character) then
								localTryOnGroundCalibrationFrames = 2
							elseif localTryOnGroundCalibrationFrames > 0 then
								localTryOnGroundCalibrationFrames = localTryOnGroundCalibrationFrames - 1
							end
							if localTryOnGroundCalibrationFrames == 0 and isPlayerSitAnimationCleared(character) then
								local groundOffset = calculateGroundOffsetFromNeutralCloneFeet(character, characterRoot)
								if groundOffset then
									localTryOnGroundOffset = groundOffset
									localTryOnGroundOffsetValid = true
									localTryOnPositionMode = "Ground"
									targetOffset = groundOffset
								else
									localTryOnGroundCalibrationFrames = 1
								end
							end
						else
							localTryOnGroundCalibrationFrames = 2
						end
						targetOffset = (localTryOnPositionMode == "Ground") and localTryOnGroundOffset or targetOffset
					elseif isSwimming then
						local desiredSwimOffset = localTryOnSwimOffset
						if localTryOnSwimTransitionActive then
							local alpha = math.clamp((os.clock() - localTryOnSwimTransitionStartedAt) / 0.16, 0, 1)
							local eased = alpha * alpha * (3 - 2 * alpha)
							targetOffset = localTryOnSwimTransitionStart:Lerp(desiredSwimOffset, eased)
							if alpha >= 1 then
								localTryOnSwimTransitionActive = false
								targetOffset = desiredSwimOffset
							end
						else
							targetOffset = desiredSwimOffset
						end
					else
						local desiredGroundOffset = localTryOnGroundOffset
						if localTryOnSwimTransitionActive then
							local alpha = math.clamp((os.clock() - localTryOnSwimTransitionStartedAt) / 0.16, 0, 1)
							local eased = alpha * alpha * (3 - 2 * alpha)
							targetOffset = localTryOnSwimTransitionStart:Lerp(desiredGroundOffset, eased)
							if alpha >= 1 then
								localTryOnSwimTransitionActive = false
								targetOffset = desiredGroundOffset
							end
						else
							targetOffset = desiredGroundOffset
						end
					end
				end

				currentVerticalOffset = targetOffset
				localTryOnRootPart.CFrame = characterRoot.CFrame + currentVerticalOffset

				enforceCharacterHidden()
				setLocalTryOnFirstPersonVisibility(isFirstPersonCamera(character))
			end)

			updateWearButtonState()
			Status.Text = "[OK] Local try-on active!"
			return
		end

		lastTryOnError = tostring(setupError)
		pcall(function() model:Destroy() end)
		localTryOnModel = nil
		localTryOnRootPart = nil
		localTryOnGroundOffset = Vector3.zero
		localTryOnSwimOffset = Vector3.zero
		currentVerticalOffset = Vector3.zero
		localTryOnSeatedHipOffsetValid = false
		localTryOnSeatPart = nil
		localTryOnPositionMode = "Ground"
		localTryOnSeatCalibrationPending = false
		localTryOnSeatCalibrationToken = localTryOnSeatCalibrationToken + 1
		resetLocalTryOnState()
		disconnectLocalTryOnConnections()
	end

	setLocalTryOnConnection("buildSeat", nil)
	localTryOnBuilding = false
	WearButton.Active = true
	updateWearButtonState()
	showDiagnostics("Local try-on failed.", lastTryOnError)
end

local function toggleLocalTryOn()
	if localTryOnBuilding then return end
	if localTryOnModel or tryOnActive then
		tryOnActive = false
		stopLocalTryOn(false)
		updateWearButtonState()
		Status.Text = "Local try-on cleared."
		clearDiagnostics()
	else
		tryOnSelectedAvatarLocally()
	end
end

local function bindCharacterLifecycle(character)
	disconnectConnection(deathConnection)
	deathConnection = nil

	if not character then return end

	task.spawn(function()
		local humanoid = character:WaitForChild("Humanoid", 10)
		local root = character:WaitForChild("HumanoidRootPart", 10)

		if not humanoid or not root or not scriptAlive then return end

		deathConnection = humanoid.Died:Connect(function()
			if tryOnActive or localTryOnModel or localTryOnBuilding then
				stopLocalTryOn(true)
				WearButton.Active = false
				updateWearButtonState()
				Status.Text = "[...] Character died. Respawning try-on..."
			end
		end)

		if tryOnActive and selectedAvatar and scriptAlive then
			task.wait(0.15)
			if scriptAlive and LocalPlayer.Character == character then
				tryOnSelectedAvatarLocally()
			end
		else
			WearButton.Active = true
			updateWearButtonState()
		end
	end)
end

characterAddedConnection = LocalPlayer.CharacterAdded:Connect(bindCharacterLifecycle)

wire(WearButton.Activated, toggleLocalTryOn)

wire(SearchBox:GetPropertyChangedSignal("Text"), function()
	if not scriptAlive then return end
	if searchDebounceThread then task.cancel(searchDebounceThread) searchDebounceThread = nil end
	searchDebounceThread = task.delay(0.15, function()
		if scriptAlive then filterAvatarCards(SearchBox.Text) end
	end)
end)

local isRefreshing = false
wire(RefreshButton.Activated, function()
	if isRefreshing then return end
	showConfirmation("Refresh Avatar Lists?", function()
		isRefreshing = true
		RefreshButton.Text = "..."
		Status.Text = "Refreshing saved avatars..."
		previewQueueGeneration = previewQueueGeneration + 1
		table.clear(previewQueue)
		table.clear(previewStates)
		task.wait(0.1)
		loadSavedAvatars()
		populateAvatarList()
		RefreshButton.Text = "Refresh"
		task.delay(0.5, function() isRefreshing = false end)
	end)
end)

local dragging = false
local dragStart, startPosition

local function pointInsideGui(guiObject, position)
	local guiPos, guiSize = guiObject.AbsolutePosition, guiObject.AbsoluteSize
	return position.X >= guiPos.X and position.Y >= guiPos.Y and position.X <= guiPos.X + guiSize.X and position.Y <= guiPos.Y + guiSize.Y
end

wire(UserInputService.InputBegan, function(input)
	if (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch)
	   and pointInsideGui(TitleBar, input.Position) then
		dragging = true
		dragStart = input.Position
		startPosition = Main.Position
	end
end)

wire(UserInputService.InputChanged, function(input)
	if not dragging then return end
	if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
		local delta = input.Position - dragStart
		Main.Position = UDim2.new(
			startPosition.X.Scale, startPosition.X.Offset + delta.X,
			startPosition.Y.Scale, startPosition.Y.Offset + delta.Y
		)
	end
end)

wire(UserInputService.InputEnded, function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = false
		dragStart = nil
		startPosition = nil
	end
end)

wire(MinimizeButton.Activated, function()
	minimized = not minimized
	if minimized then
		MinimizeButton.Text = "+"
		Main.Size = UDim2.new(0, minimizedWidth, 0, 36)
		SearchBox.Visible, RefreshButton.Visible, List.Visible = false, false, false
		Status.Visible, ErrorPopup.Visible, WearButton.Visible, ConfirmOverlay.Visible = false, false, false, false
	else
		MinimizeButton.Text = "-"
		Main.Size = UDim2.new(0, mainWidth, 0, savedMainHeight)
		SearchBox.Visible, RefreshButton.Visible, List.Visible = true, true, true
		Status.Visible, WearButton.Visible = true, true
		if currentConfirmAction then ConfirmOverlay.Visible = true end
	end
end)

wire(DestroyButton.Activated, function()
	showConfirmation("Unload and Destroy script?", function()
		stopLocalTryOn(false)
		cleanup()
	end)
end)

if LocalPlayer.Character then bindCharacterLifecycle(LocalPlayer.Character) end

loadSavedAvatars()
populateAvatarList()
task.defer(function()
	if scriptAlive and not previewQueueRunning then task.spawn(processPreviewQueue) end
end)

end)

if not success then
	warn("[Local Wearer] " .. tostring(err))
end
