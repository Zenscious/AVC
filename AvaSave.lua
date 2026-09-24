-- [[ Made by Knightingale | ScriptBlox.com ]] --
-- Official script V2.9

local runtimeConnections = {}

	local accessoryPropertyNames = {
		"HatAccessory", "HairAccessory", "FaceAccessory", "NeckAccessory",
		"ShouldersAccessory", "FrontAccessory", "BackAccessory", "WaistAccessory",
		"JacketAccessory", "ShortsAccessory", "SweaterAccessory", "TShirtAccessory",
		"PantsAccessory", "ShoesAccessory", "DressSkirtAccessory",
		"EyelashAccessory", "EyebrowAccessory", "MoodAccessory"
	}
local scriptAlive = true

local function emergencyCleanup()
	scriptAlive = false
	for _, conn in ipairs(runtimeConnections) do
		pcall(function()
			if conn and conn.Connected then conn:Disconnect() end
		end)
	end
	table.clear(runtimeConnections)

	local roots = {}
	pcall(function()
		if type(gethui) == "function" then table.insert(roots, gethui()) end
	end)
	pcall(function() table.insert(roots, game:GetService("CoreGui")) end)
	pcall(function()
		local player = game:GetService("Players").LocalPlayer
		if player then table.insert(roots, player:FindFirstChild("PlayerGui")) end
	end)

	for _, root in ipairs(roots) do
		if root then
			pcall(function()
				local ui = root:FindFirstChild("AvatarSaverV2_UI")
				if ui then ui:Destroy() end
			end)
		end
	end

	pcall(function()
		if type(getgenv) == "function" and getgenv().__AvatarSaverV2Cleanup == emergencyCleanup then
			getgenv().__AvatarSaverV2Cleanup = nil
		end
	end)
end

pcall(function()
	if type(getgenv) == "function" then
		if type(getgenv().__AvatarSaverV2Cleanup) == "function" then
			pcall(getgenv().__AvatarSaverV2Cleanup)
		end
		getgenv().__AvatarSaverV2Cleanup = emergencyCleanup
	end
end)

local success, err = pcall(function()
local function getService(name)
		local ok, service = pcall(function()
			local s = game:GetService(name)
			return (type(cloneref) == "function") and cloneref(s) or s
		end)
		return ok and service or game:GetService(name)
	end

	local Players = getService("Players")
	local ReplicatedStorage = getService("ReplicatedStorage")
	local HttpService = getService("HttpService")
	local MarketplaceService = getService("MarketplaceService")
	local UserInputService = getService("UserInputService")
	local TweenService = getService("TweenService")
	local Workspace = getService("Workspace")
	local CoreGui = getService("CoreGui")

	local LocalPlayer = Players.LocalPlayer or Players:GetPropertyChangedSignal("LocalPlayer"):Wait() or Players.LocalPlayer
	local Mouse = LocalPlayer:GetMouse()

	local catalogEvents = ReplicatedStorage:FindFirstChild("Events")
	local catalogGuiRemote = catalogEvents and catalogEvents:FindFirstChild("CatalogGuiRemote")
	local savedOutfitsRemote = catalogEvents and catalogEvents:FindFirstChild("SavedOutfitsRemote")
	local IS_CATALOG_GAME = (catalogGuiRemote ~= nil and savedOutfitsRemote ~= nil)

	local SCREEN_GUI_NAME = "AvatarSaverV2_UI"
	local ScreenGui = Instance.new("ScreenGui")
	ScreenGui.Name = SCREEN_GUI_NAME
	ScreenGui.ResetOnSpawn = false
	ScreenGui.IgnoreGuiInset = true

	local parented = false
	if type(gethui) == "function" then
		pcall(function()
			local existing = gethui():FindFirstChild(SCREEN_GUI_NAME)
			if existing then existing:Destroy() end
			ScreenGui.Parent = gethui()
			parented = true
		end)
	end

	if not parented and syn and type(syn.protect_gui) == "function" then
		pcall(function()
			syn.protect_gui(ScreenGui)
			local existing = CoreGui:FindFirstChild(SCREEN_GUI_NAME)
			if existing then existing:Destroy() end
			ScreenGui.Parent = CoreGui
			parented = true
		end)
	end

	if not parented then
		pcall(function()
			local existing = CoreGui:FindFirstChild(SCREEN_GUI_NAME)
			if existing then existing:Destroy() end
			ScreenGui.Parent = CoreGui
			parented = true
		end)
	end

	if not parented then
		local playerGui = LocalPlayer:WaitForChild("PlayerGui", 5)
		if playerGui then
			local existing = playerGui:FindFirstChild(SCREEN_GUI_NAME)
			if existing then existing:Destroy() end
			ScreenGui.Parent = playerGui
		end
	end

	local FOLDER_NAME = "Avatar Saver v2"
	local FILE_PATH = FOLDER_NAME .. "/SavedAvatars.json"

	if type(makefolder) == "function" and type(isfolder) == "function" then
		pcall(function()
			if not isfolder(FOLDER_NAME) then makefolder(FOLDER_NAME) end
		end)
	end

	local viewportSize = Workspace.CurrentCamera and Workspace.CurrentCamera.ViewportSize or Vector2.new(1024, 768)
	local isMobile = (viewportSize.X < 700 or viewportSize.Y < 500)
local mainWidth = isMobile and 310 or 360
local mainHeight = isMobile and 280 or 320

	local copiedAvatars = {}
	local dragging = false
	local dragStart, startPosition
	local minimized = false
	local inspectorOpen = false
	local copying = false
	local selectedPlayer = nil
	local connections = runtimeConnections
local function wire(signal, callback)
local connection = signal:Connect(callback)
connections[#connections + 1] = connection
return connection
end
	local currentActiveData = nil
	local currentConfirmAction = nil
	local currentPage = "Saved"
	local socialPages = {}
	local socialThumbnailCache = {}
	local socialLoading = {}
local worldPlayerPopupEnabled = true

	local lastUIClickTime = 0
	local touchStartPos = Vector2.zero
	local touchStartTime = 0
	local MAX_TAP_DISTANCE = 12
	local MAX_TAP_DURATION = 0.35

	local function markUIClick()
		lastUIClickTime = os.clock()
	end

	local function getEnumRigType(rigVal)
		if rigVal == Enum.HumanoidRigType.R6 or rigVal == Enum.HumanoidRigType.R15 then
			return rigVal
		end
		local str = tostring(rigVal or "")
		if str:find("R6") then
			return Enum.HumanoidRigType.R6
		end
		return Enum.HumanoidRigType.R15
	end

	local profileRigCache = {}

	local function getProfileRigType(userId)
		if not userId then return Enum.HumanoidRigType.R15 end
		if profileRigCache[userId] then return profileRigCache[userId] end

		local rigType = Enum.HumanoidRigType.R15
		pcall(function()
			local info = Players:GetCharacterAppearanceInfoAsync(userId)
			if info and tostring(info.playerAvatarType):upper() == "R6" then
				rigType = Enum.HumanoidRigType.R6
			else
				rigType = Enum.HumanoidRigType.R15
			end
		end)

		profileRigCache[userId] = rigType
		return rigType
	end

	local function isInputOverUI(inputPosition)
		if not inputPosition then return false end
		local x, y = inputPosition.X, inputPosition.Y

		local targetGuis = {}
		pcall(function() if type(gethui) == "function" then table.insert(targetGuis, gethui()) end end)
		pcall(function() table.insert(targetGuis, CoreGui) end)
		pcall(function()
			if LocalPlayer and LocalPlayer:FindFirstChild("PlayerGui") then
				table.insert(targetGuis, LocalPlayer.PlayerGui)
			end
		end)

		for _, root in ipairs(targetGuis) do
			local objects = {}
			pcall(function()
				objects = root:GetGuiObjectsAtPosition(x, y)
			end)
			for _, obj in ipairs(objects) do
				if obj:IsDescendantOf(ScreenGui) then
					return true
				end
			end
		end
		return false
	end

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
		if type(v) == "table" then
			return {X = tonumber(v.X) or 0, Y = tonumber(v.Y) or 0, Z = tonumber(v.Z) or 0, Vector3 = true}
		end
		return {X = v.X, Y = v.Y, Z = v.Z, Vector3 = true}
	end

	local function getLayeredAccessories(desc)
		local result = {}
		pcall(function()
			if type(desc.GetAccessories) == "function" then
				for _, accessory in ipairs(desc:GetAccessories(true)) do
					if accessory.IsLayered then
						table.insert(result, {
							Rotation = vector(accessory.Rotation),
							AssetId = accessory.AssetId,
							AccessoryType = accessory.AccessoryType and accessory.AccessoryType.Name or "Unknown",
							Position = vector(accessory.Position),
							Order = accessory.Order or 1,
							IsLayered = true,
							Puffiness = accessory.Puffiness or 0.5,
							Scale = vector(accessory.Scale)
						})
					end
				end
			end
		end)
		return result
	end

	local function getAccessoryRefinements(desc, character)
		local refinements = {}

		pcall(function()
			if character then
				local rawRef = character:GetAttribute("AccessoryRefinements") or (desc and desc:GetAttribute("AccessoryRefinements"))
				if rawRef then
					local decoded = type(rawRef) == "string" and HttpService:JSONDecode(rawRef) or rawRef
					if type(decoded) == "table" then
						for idStr, refData in pairs(decoded) do
							refinements[tostring(idStr)] = refData
						end
					end
				end
			end
		end)

		pcall(function()
			if desc and type(desc.GetAccessories) == "function" then
				for _, accessory in ipairs(desc:GetAccessories(true)) do
					local idStr = tostring(accessory.AssetId or 0)
					if idStr ~= "0" then
						local hasPos = accessory.Position and (math.abs(accessory.Position.X) > 0.0001 or math.abs(accessory.Position.Y) > 0.0001 or math.abs(accessory.Position.Z) > 0.0001)
						local hasScale = accessory.Scale and (math.abs(accessory.Scale.X - 1) > 0.0001 or math.abs(accessory.Scale.Y - 1) > 0.0001 or math.abs(accessory.Scale.Z - 1) > 0.0001)
						local hasRot = accessory.Rotation and (math.abs(accessory.Rotation.X) > 0.0001 or math.abs(accessory.Rotation.Y) > 0.0001 or math.abs(accessory.Rotation.Z) > 0.0001)

						if hasPos or hasScale or hasRot then
							local ref = refinements[idStr] or {}
							if hasPos then ref.Position = vector(accessory.Position) end
							if hasScale then ref.Scale = vector(accessory.Scale) end
							if hasRot then ref.Rotation = vector(accessory.Rotation) end
							refinements[idStr] = ref
						end
					end
				end
			end
		end)

		if character then
			pcall(function()
				for _, child in ipairs(character:GetChildren()) do
					if child:IsA("Accessory") then
						local handle = child:FindFirstChild("Handle")
						local assetId = child:GetAttribute("AssetId")
						if not assetId and handle then
							local mesh = handle:FindFirstChildOfClass("SpecialMesh")
							if mesh and mesh.MeshId then
								assetId = tonumber(string.match(mesh.MeshId, "%d+"))
							end
						end

						if assetId then
							local idStr = tostring(assetId)
							local ref = refinements[idStr] or {}

							local attrPos = child:GetAttribute("Position") or child:GetAttribute("RefinementPosition")
							local attrScale = child:GetAttribute("Scale") or child:GetAttribute("RefinementScale")
							local attrRot = child:GetAttribute("Rotation") or child:GetAttribute("RefinementRotation")

							if typeof(attrPos) == "Vector3" then ref.Position = vector(attrPos)
							elseif type(attrPos) == "table" then ref.Position = vector(attrPos) end

							if typeof(attrScale) == "Vector3" then ref.Scale = vector(attrScale)
							elseif type(attrScale) == "table" then ref.Scale = vector(attrScale) end

							if typeof(attrRot) == "Vector3" then ref.Rotation = vector(attrRot)
							elseif type(attrRot) == "table" then ref.Rotation = vector(attrRot) end

							if ref.Position or ref.Scale or ref.Rotation then
								refinements[idStr] = ref
							end
						end
					end
				end
			end)
		end
		return refinements
	end

	local function getHeadShape(desc)
		local headShape = ""
		pcall(function()
			for _, child in ipairs(desc:GetChildren()) do
				if child:IsA("BodyPartDescription") and child.BodyPart == Enum.BodyPart.Head then
					local value = child.HeadShape
					if type(value) == "string" and value ~= "" then
						headShape = value
						break
					end
				end
			end
		end)
		return headShape
	end

	local function getMakeups(desc)
		local makeups = {}
		local seen = {}

		local function addMakeup(makeup)
			if not makeup then return end
			local assetId = tonumber(makeup.AssetId)
			if not assetId or assetId <= 0 then return end
			local makeupType = makeup.MakeupType
			local typeName = (makeupType and makeupType.Name) or tostring(makeupType or "")
			local order = tonumber(makeup.Order) or 1
			local key = tostring(assetId) .. "|" .. typeName .. "|" .. tostring(order)
			if seen[key] then return end
			seen[key] = true
			table.insert(makeups, {
				Order = order,
				AssetId = assetId,
				MakeupType = typeName
			})
		end

		pcall(function()
			for _, child in ipairs(desc:GetChildren()) do
				if child:IsA("MakeupDescription") then
					addMakeup(child)
				end
			end
		end)

		if #makeups == 0 then
			pcall(function()
				if type(desc.GetMakeups) == "function" then
					for _, makeup in ipairs(desc:GetMakeups()) do
						addMakeup(makeup)
					end
				end
			end)
		end

		return makeups
	end

	local function createCopiedProperties(desc, character)
		local accLists = {
			HatAccessory = {}, HairAccessory = {}, FaceAccessory = {}, NeckAccessory = {},
			ShouldersAccessory = {}, FrontAccessory = {}, BackAccessory = {}, WaistAccessory = {},
			JacketAccessory = {}, ShortsAccessory = {}, SweaterAccessory = {}, TShirtAccessory = {},
			PantsAccessory = {}, ShoesAccessory = {}, DressSkirtAccessory = {},
			EyelashAccessory = {}, EyebrowAccessory = {}, MoodAccessory = {}
		}

		local function addAccToCategory(category, id)
			id = tostring(id)
			if id and id ~= "" and id ~= "0" and not table.find(accLists[category], id) then
				table.insert(accLists[category], id)
			end
		end

		for propName in pairs(accLists) do
			pcall(function()
				local val = desc[propName]
				if val then
					for id in string.gmatch(tostring(val), "%d+") do
						addAccToCategory(propName, id)
					end
				end
			end)
		end

		pcall(function()
			if type(desc.GetAccessories) == "function" then
				local typeToCat = {
					[Enum.AccessoryType.Hat] = "HatAccessory",
					[Enum.AccessoryType.Hair] = "HairAccessory",
					[Enum.AccessoryType.Face] = "FaceAccessory",
					[Enum.AccessoryType.Neck] = "NeckAccessory",
					[Enum.AccessoryType.Shoulder] = "ShouldersAccessory",
					[Enum.AccessoryType.Front] = "FrontAccessory",
					[Enum.AccessoryType.Back] = "BackAccessory",
					[Enum.AccessoryType.Waist] = "WaistAccessory",
					[Enum.AccessoryType.TShirt] = "TShirtAccessory",
					[Enum.AccessoryType.Shirt] = "ShirtAccessory", 
					[Enum.AccessoryType.Pants] = "PantsAccessory",
					[Enum.AccessoryType.Jacket] = "JacketAccessory",
					[Enum.AccessoryType.Sweater] = "SweaterAccessory",
					[Enum.AccessoryType.Shorts] = "ShortsAccessory",
					[Enum.AccessoryType.LeftShoe] = "ShoesAccessory",
					[Enum.AccessoryType.RightShoe] = "ShoesAccessory",
					[Enum.AccessoryType.DressSkirt] = "DressSkirtAccessory",
					[Enum.AccessoryType.Eyebrow] = "EyebrowAccessory",
					[Enum.AccessoryType.Eyelash] = "EyelashAccessory"
				}
				for _, acc in ipairs(desc:GetAccessories(true)) do
					if not acc.IsLayered and acc.AccessoryType and typeToCat[acc.AccessoryType] then
						addAccToCategory(typeToCat[acc.AccessoryType], acc.AssetId)
					end
				end
			end
		end)

		local props = {
			["WalkAnimation"] = desc.WalkAnimation or 0,
			["MoodAnimation"] = desc.MoodAnimation or 0,
			["ClimbAnimation"] = desc.ClimbAnimation or 0,
			["FallAnimation"] = desc.FallAnimation or 0,
			["RunAnimation"] = desc.RunAnimation or 0,
			["SwimAnimation"] = desc.SwimAnimation or 0,
			["IdleAnimation"] = desc.IdleAnimation or 0,
			["JumpAnimation"] = desc.JumpAnimation or 0,

			["Face"] = desc.Face or 0,
			["Shirt"] = desc.Shirt or 0,
			["Pants"] = desc.Pants or 0,
			["GraphicTShirt"] = desc.GraphicTShirt or 0,

			["RightArmColor"] = rgb(desc.RightArmColor),
			["TorsoColor"] = rgb(desc.TorsoColor),
			["RightLegColor"] = rgb(desc.RightLegColor),
			["LeftLegColor"] = rgb(desc.LeftLegColor),
			["LeftArmColor"] = rgb(desc.LeftArmColor),
			["HeadColor"] = rgb(desc.HeadColor),

			["Head"] = desc.Head or 0,
			["Torso"] = desc.Torso or 0,
			["LeftArm"] = desc.LeftArm or 0,
			["RightArm"] = desc.RightArm or 0,
			["LeftLeg"] = desc.LeftLeg or 0,
			["RightLeg"] = desc.RightLeg or 0,
			
			["HeadShape"] = getHeadShape(desc),
			["MakeupItems"] = getMakeups(desc),

			["ProportionScale"] = desc.ProportionScale or 0,
			["DepthScale"] = desc.DepthScale or 1,
			["HeightScale"] = desc.HeightScale or 1,
			["WidthScale"] = desc.WidthScale or 1,
			["BodyTypeScale"] = desc.BodyTypeScale or 0,
			["HeadScale"] = desc.HeadScale or 1,

			["HatAccessory"] = table.concat(accLists.HatAccessory, ","),
			["HairAccessory"] = table.concat(accLists.HairAccessory, ","),
			["FaceAccessory"] = table.concat(accLists.FaceAccessory, ","),
			["NeckAccessory"] = table.concat(accLists.NeckAccessory, ","),
			["ShouldersAccessory"] = table.concat(accLists.ShouldersAccessory, ","),
			["FrontAccessory"] = table.concat(accLists.FrontAccessory, ","),
			["BackAccessory"] = table.concat(accLists.BackAccessory, ","),
			["WaistAccessory"] = table.concat(accLists.WaistAccessory, ","),

			["JacketAccessory"] = table.concat(accLists.JacketAccessory, ","),
			["ShortsAccessory"] = table.concat(accLists.ShortsAccessory, ","),
			["SweaterAccessory"] = table.concat(accLists.SweaterAccessory, ","),
			["TShirtAccessory"] = table.concat(accLists.TShirtAccessory, ","),
			["PantsAccessory"] = table.concat(accLists.PantsAccessory, ","),
			["ShoesAccessory"] = table.concat(accLists.ShoesAccessory, ","),
			["DressSkirtAccessory"] = table.concat(accLists.DressSkirtAccessory, ","),
			["EyelashAccessory"] = table.concat(accLists.EyelashAccessory, ","),
			["EyebrowAccessory"] = table.concat(accLists.EyebrowAccessory, ","),

			["LayeredAccessories"] = getLayeredAccessories(desc),
			["AccessoryRefinements"] = getAccessoryRefinements(desc, character),
			["StaticFacialAnimation"] = pcall(function() return desc.StaticFacialAnimation end) and desc.StaticFacialAnimation or false
		}

		pcall(function()
			local allAccessories = {}
			for _, accessory in ipairs(desc:GetAccessories(true)) do
				local entry = {
					AssetId = accessory.AssetId,
					AccessoryType = accessory.AccessoryType and accessory.AccessoryType.Name or "Unknown",
					IsLayered = accessory.IsLayered == true
				}
				if accessory.Order ~= nil then entry.Order = accessory.Order end
				if accessory.Puffiness ~= nil then entry.Puffiness = accessory.Puffiness end
				table.insert(allAccessories, entry)
			end
			props["AllAccessories"] = allAccessories
		end)

		pcall(function()
			if type(desc.GetEmotes) == "function" then
				props["Emotes"] = desc:GetEmotes()
			end
		end)

		pcall(function()
			if type(desc.GetEquippedEmotes) == "function" then
				props["EquippedEmotes"] = desc:GetEquippedEmotes()
			end
		end)

		return props
	end

	local function reconstructHumanoidDescription(props, includeHeadShape)
		local desc = Instance.new("HumanoidDescription")
		if not props then return desc end

		local directProps = {
			"Face", "Shirt", "Pants", "GraphicTShirt", "Head", "Torso",
			"LeftArm", "RightArm", "LeftLeg", "RightLeg",
			"WalkAnimation", "MoodAnimation", "ClimbAnimation", "FallAnimation",
			"RunAnimation", "SwimAnimation", "IdleAnimation", "JumpAnimation"
		}

		for _, prop in ipairs(directProps) do
			if props[prop] then
				pcall(function() desc[prop] = tonumber(props[prop]) or 0 end)
			end
		end
		
		if includeHeadShape and props.HeadShape and props.HeadShape ~= "" and tonumber(props.Head) and tonumber(props.Head) > 0 then
			pcall(function()
				local headDescription = Instance.new("BodyPartDescription")
				headDescription.BodyPart = Enum.BodyPart.Head
				headDescription.AssetId = tonumber(props.Head)
				headDescription.HeadShape = tostring(props.HeadShape)
				headDescription.Parent = desc
			end)
		end
		
		if props.StaticFacialAnimation ~= nil then
			pcall(function() desc.StaticFacialAnimation = props.StaticFacialAnimation == true end)
		end

		if props.AllAccessories and type(props.AllAccessories) == "table" then
			local accessories = {}
			for _, entry in ipairs(props.AllAccessories) do
				if entry.AssetId and entry.AccessoryType then
					local accessory = {
						AssetId = tonumber(entry.AssetId),
						AccessoryType = Enum.AccessoryType[entry.AccessoryType] or Enum.AccessoryType.Unknown
					}
					if entry.IsLayered then
						accessory.IsLayered = true
						accessory.Order = tonumber(entry.Order) or 0
						if entry.Puffiness ~= nil then accessory.Puffiness = tonumber(entry.Puffiness) or 0 end
					end
					table.insert(accessories, accessory)
				end
			end
			pcall(function() desc:SetAccessories(accessories, true) end)
		else
			for _, acc in ipairs(accessoryPropertyNames) do
				if props[acc] then
					pcall(function() desc[acc] = tostring(props[acc]) end)
				end
			end
		end

		if props.MakeupItems and type(props.MakeupItems) == "table" then
			for _, m in ipairs(props.MakeupItems) do
				pcall(function()
					local assetId = tonumber(m.AssetId)
					if not assetId or assetId <= 0 then return end
					local mType = Enum.MakeupType[tostring(m.MakeupType)]
					if not mType then return end
					local makeupDescription = Instance.new("MakeupDescription")
					makeupDescription.AssetId = assetId
					makeupDescription.Order = tonumber(m.Order) or 1
					makeupDescription.MakeupType = mType
					makeupDescription.Parent = desc
				end)
			end
		end

		local colorProps = {"RightArmColor", "TorsoColor", "RightLegColor", "LeftLegColor", "LeftArmColor", "HeadColor"}
		for _, colKey in ipairs(colorProps) do
			if props[colKey] and type(props[colKey]) == "table" then
				pcall(function()
					local c = props[colKey]
					desc[colKey] = Color3.fromRGB(c.r or 255, c.g or 255, c.b or 255)
				end)
			end
		end

		local scaleProps = {"ProportionScale", "DepthScale", "HeightScale", "WidthScale", "BodyTypeScale", "HeadScale"}
		for _, scaleKey in ipairs(scaleProps) do
			if props[scaleKey] then
				pcall(function() desc[scaleKey] = tonumber(props[scaleKey]) or 1 end)
			end
		end

		if props.Emotes and type(props.Emotes) == "table" then
			pcall(function() desc:SetEmotes(props.Emotes) end)
		end
		if props.EquippedEmotes and type(props.EquippedEmotes) == "table" then
			pcall(function() desc:SetEquippedEmotes(props.EquippedEmotes) end)
		end

		return desc
	end

local renderQueue = {}
local isProcessingQueue = false

	local function processRenderQueue()
		if isProcessingQueue then return end
		isProcessingQueue = true

while #renderQueue > 0 do
			if not scriptAlive then break end
local taskData = table.remove(renderQueue, 1)
			local parentContainer = taskData.Container
			local data = taskData.Data
			local isFullBody = taskData.IsFullBody

			if parentContainer and parentContainer.Parent and parentContainer:IsDescendantOf(game) then
				local existingViewport = parentContainer:FindFirstChild("SavedAvatarViewport")
				if existingViewport then existingViewport:Destroy() end

				local viewport = Instance.new("ViewportFrame")
				viewport.Name = "SavedAvatarViewport"
				viewport.Size = UDim2.new(1, 0, 1, 0)
				viewport.BackgroundTransparency = 1
				viewport.ZIndex = parentContainer.ZIndex + 1
				viewport.Parent = parentContainer

				local worldModel = Instance.new("WorldModel")
				worldModel.Parent = viewport

				local camera = Instance.new("Camera")
				viewport.CurrentCamera = camera
				camera.Parent = viewport

				local desc = reconstructHumanoidDescription(data.Properties, false)
				local rigTypeEnum = getEnumRigType(data.RigType)

				local successModel, model = pcall(function()
					if type(Players.CreateHumanoidModelFromDescriptionAsync) == "function" then
						return Players:CreateHumanoidModelFromDescriptionAsync(desc, rigTypeEnum)
					end
					return Players:CreateHumanoidModelFromDescription(desc, rigTypeEnum)
				end)

				if successModel and model and parentContainer.Parent then
					model.Parent = worldModel
					model:PivotTo(CFrame.new(0, 0, 0))

					local head = model:FindFirstChild("Head")
					local root = model:FindFirstChild("HumanoidRootPart") or head or model.PrimaryPart

					if root then
						local lookVector = head and head.CFrame.LookVector or root.CFrame.LookVector
						if lookVector.Magnitude == 0 then lookVector = Vector3.new(0, 0, -1) end

						if isFullBody then
							local cf, size = model:GetBoundingBox()
							local targetPos = cf.Position + Vector3.new(0, 0.2, 0)
							local dist = math.max(size.Y, size.X, size.Z) * 1.15
							if dist < 4.5 then dist = 5.2 end
							local camPos = targetPos + (lookVector * dist)
							camera.CFrame = CFrame.lookAt(camPos, targetPos)
						else
							local headPos = head and head.Position or (root.Position + Vector3.new(0, 1.5, 0))
							local camPos = headPos + (lookVector * 2.7) + Vector3.new(0, 0.1, 0)
							camera.CFrame = CFrame.lookAt(camPos, headPos)
						end
					end
				end
			end
			task.wait(0.04)
		end

isProcessingQueue = false
	end

	local function renderSavedAvatarPreview(parentContainer, data, isFullBody)
		if not scriptAlive then return end
		table.insert(renderQueue, {
			Container = parentContainer,
			Data = data,
			IsFullBody = isFullBody
		})
task.spawn(processRenderQueue)
	end

	local function getAvatarSignature(properties, rigType)
		local ok, result = pcall(function()
			return HttpService:JSONEncode({
				Properties = properties,
				RigType = tostring(rigType)
			})
		end)
		return ok and result or tostring(properties)
	end

	local function applyTween(instance, properties, duration)
		local tweenInfo = TweenInfo.new(duration or 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		local tween = TweenService:Create(instance, tweenInfo, properties)
		tween:Play()
		return tween
	end

	local function saveToWorkspace()
		if type(writefile) ~= "function" then return end

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

	local Main = Instance.new("Frame")
	Main.Name = "Main"
	Main.Size = UDim2.new(0, mainWidth, 0, mainHeight)
	Main.Position = UDim2.new(0.5, -mainWidth/2, 0.5, -mainHeight/2)
	Main.BackgroundColor3 = Color3.fromRGB(20, 20, 26)
	Main.BorderSizePixel = 0
	Main.ClipsDescendants = true
	Main.Active = true
	Main.Parent = ScreenGui

	local MainCorner = Instance.new("UICorner")
	MainCorner.CornerRadius = UDim.new(0, 8)
	MainCorner.Parent = Main

	local MainStroke = Instance.new("UIStroke")
	MainStroke.Color = Color3.fromRGB(45, 45, 55)
	MainStroke.Thickness = 1
	MainStroke.Parent = Main

	local TitleBar = Instance.new("Frame")
	TitleBar.Name = "TitleBar"
	TitleBar.Size = UDim2.new(1, 0, 0, 34)
	TitleBar.BackgroundColor3 = Color3.fromRGB(28, 28, 36)
	TitleBar.BorderSizePixel = 0
	TitleBar.ZIndex = 10
	TitleBar.Active = true
	TitleBar.Parent = Main

	local TitleBarCorner = Instance.new("UICorner")
	TitleBarCorner.CornerRadius = UDim.new(0, 8)
	TitleBarCorner.Parent = TitleBar

	local Title = Instance.new("TextLabel")
	Title.Size = UDim2.new(0, isMobile and 94 or 112, 1, 0)
	Title.Position = UDim2.new(0, 12, 0, 0)
	Title.BackgroundTransparency = 1
	Title.Text = "Avatar Saver V2"
	Title.TextColor3 = Color3.fromRGB(235, 235, 245)
	Title.TextSize = isMobile and 10 or 12
	Title.Font = Enum.Font.GothamBold
	Title.TextXAlignment = Enum.TextXAlignment.Left
	Title.TextTruncate = Enum.TextTruncate.AtEnd
	Title.ZIndex = 11
	Title.Parent = TitleBar

	local Watermark = Instance.new("TextLabel")
	Watermark.Name = "Watermark"
Watermark.Size = UDim2.new(1, (isMobile and -172 or -190), 1, 0)
Watermark.Position = UDim2.new(0, isMobile and 140 or 158, 0, 0)
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
WatermarkEmojiButton.Position = UDim2.new(0, isMobile and 110 or 128, 0, 4)
WatermarkEmojiButton.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
WatermarkEmojiButton.TextColor3 = Color3.fromRGB(235, 235, 245)
WatermarkEmojiButton.TextSize = isMobile and 18 or 20
WatermarkEmojiButton.Font = Enum.Font.Gotham
WatermarkEmojiButton.AutoButtonColor = false
WatermarkEmojiButton.ZIndex = 11
WatermarkEmojiButton.Active = true
WatermarkEmojiButton.Parent = TitleBar

local WatermarkEmojiCorner = Instance.new("UICorner")
WatermarkEmojiCorner.CornerRadius = UDim.new(0, 5)
WatermarkEmojiCorner.Parent = WatermarkEmojiButton

local watermarkEmojis = {
utf8.char(0x1F5E1, 0xFE0F),
utf8.char(0x2694, 0xFE0F),
utf8.char(0x1F6E1, 0xFE0F)
}
local watermarkEmojiIndex = 1
WatermarkEmojiButton.Text = watermarkEmojis[watermarkEmojiIndex]

WatermarkEmojiButton.Activated:Connect(function()
markUIClick()
watermarkEmojiIndex = (watermarkEmojiIndex % #watermarkEmojis) + 1
WatermarkEmojiButton.Text = watermarkEmojis[watermarkEmojiIndex]
end)

	local Minimize = Instance.new("TextButton")
	Minimize.Size = UDim2.new(0, 22, 0, 22)
	Minimize.Position = UDim2.new(1, -28, 0, 6)
	Minimize.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
	Minimize.Text = "-"
	Minimize.TextColor3 = Color3.fromRGB(200, 200, 210)
	Minimize.TextSize = 13
	Minimize.Font = Enum.Font.GothamBold
	Minimize.ZIndex = 11
	Minimize.Active = true
	Minimize.Parent = TitleBar

	local MinCorner = Instance.new("UICorner")
	MinCorner.CornerRadius = UDim.new(0, 4)
	MinCorner.Parent = Minimize

	local ContentX = (isMobile and 46 or 50) + 16
	local ContentWidth = -(ContentX + 8)

	local ActionOffsetY = 38

	local SaveButton = Instance.new("TextButton")
	SaveButton.Size = UDim2.new(0, math.floor((mainWidth - ContentX - 16) / 3), 0, 24)
	SaveButton.Position = UDim2.new(0, ContentX, 0, ActionOffsetY)
	SaveButton.BackgroundColor3 = IS_CATALOG_GAME and Color3.fromRGB(46, 125, 85) or Color3.fromRGB(55, 55, 65)
	SaveButton.Text = "SAVE CURRENT\nAVATAR TO CAC"
	SaveButton.TextColor3 = IS_CATALOG_GAME and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(130, 130, 140)
	SaveButton.TextSize = 7
	SaveButton.TextWrapped = true
	SaveButton.Font = Enum.Font.GothamBold
	SaveButton.Active = true
	SaveButton.Parent = Main

	local SaveCorner = Instance.new("UICorner")
	SaveCorner.CornerRadius = UDim.new(0, 6)
	SaveCorner.Parent = SaveButton

	local CopySelfBtn = Instance.new("TextButton")
	CopySelfBtn.Size = UDim2.new(0, math.floor((mainWidth - ContentX - 16) / 3), 0, 24)
	CopySelfBtn.Position = UDim2.new(0, ContentX + math.floor((mainWidth - ContentX - 16) / 3) + 4, 0, ActionOffsetY)
	CopySelfBtn.BackgroundColor3 = Color3.fromRGB(55, 95, 175)
	CopySelfBtn.Text = "SAVE SELF"
	CopySelfBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	CopySelfBtn.TextSize = 8
	CopySelfBtn.Font = Enum.Font.GothamBold
	CopySelfBtn.Active = true
	CopySelfBtn.Parent = Main

	local CopySelfCorner = Instance.new("UICorner")
	CopySelfCorner.CornerRadius = UDim.new(0, 6)
	CopySelfCorner.Parent = CopySelfBtn

	local ClearButton = Instance.new("TextButton")
	ClearButton.Size = UDim2.new(0, math.floor((mainWidth - ContentX - 16) / 3), 0, 24)
	ClearButton.Position = UDim2.new(0, ContentX + 2 * (math.floor((mainWidth - ContentX - 16) / 3) + 4), 0, ActionOffsetY)
	ClearButton.BackgroundColor3 = Color3.fromRGB(135, 80, 50)
	ClearButton.Text = "CLEAR ALL"
	ClearButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	ClearButton.TextSize = 8
	ClearButton.Font = Enum.Font.GothamBold
	ClearButton.Active = true
	ClearButton.Parent = Main

	local ClearCorner = Instance.new("UICorner")
	ClearCorner.CornerRadius = UDim.new(0, 6)
	ClearCorner.Parent = ClearButton

	local UnloadButton = Instance.new("TextButton")
	UnloadButton.Size = UDim2.new(0, math.floor((mainWidth - ContentX - 8) * 0.24 - 4), 0, 24)
	UnloadButton.Position = UDim2.new(0, ContentX + 0.72 * (mainWidth - ContentX - 8) + 2, 0, ActionOffsetY)
	UnloadButton.BackgroundColor3 = Color3.fromRGB(135, 50, 50)
	UnloadButton.Text = "DESTROY UI"
	UnloadButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	UnloadButton.TextSize = 8
	UnloadButton.Font = Enum.Font.GothamBold
	UnloadButton.Active = true
	UnloadButton.Parent = Main

	local UnloadCorner = Instance.new("UICorner")
	UnloadCorner.CornerRadius = UDim.new(0, 6)
	UnloadCorner.Parent = UnloadButton

	local Status = Instance.new("TextLabel")
	Status.Size = UDim2.new(1, ContentWidth, 0, 14)
	Status.Position = UDim2.new(0, ContentX, 0, ActionOffsetY + 27)
	Status.BackgroundTransparency = 1
	Status.Text = "Saved Avatars: 0"
	Status.TextColor3 = Color3.fromRGB(150, 150, 165)
	Status.TextSize = 9
	Status.Font = Enum.Font.Gotham
	Status.TextXAlignment = Enum.TextXAlignment.Left
	Status.Parent = Main

	local SearchBox = Instance.new("TextBox")
	SearchBox.Name = "SavedAvatarSearch"
	SearchBox.Size = UDim2.new(0, isMobile and 104 or 132, 0, 18)
	SearchBox.Position = UDim2.new(1, -(isMobile and 104 or 132) - 8, 0, ActionOffsetY + 25)
	SearchBox.BackgroundColor3 = Color3.fromRGB(72, 72, 82)
	SearchBox.BorderSizePixel = 0
	SearchBox.PlaceholderText = "Search Avatar"
	SearchBox.PlaceholderColor3 = Color3.fromRGB(195, 195, 205)
	SearchBox.Text = ""
	SearchBox.TextColor3 = Color3.fromRGB(255, 255, 255)
	SearchBox.TextSize = 7
	SearchBox.Font = Enum.Font.GothamBold
	SearchBox.ClearTextOnFocus = false
	SearchBox.TextXAlignment = Enum.TextXAlignment.Left
	SearchBox.ZIndex = 6
	SearchBox.Active = true
	SearchBox.Parent = Main

	local SearchCorner = Instance.new("UICorner")
	SearchCorner.CornerRadius = UDim.new(1, 0)
	SearchCorner.Parent = SearchBox


	local ContainerOffsetY = ActionOffsetY + 43

	local ListContainer = Instance.new("Frame")
	ListContainer.Size = UDim2.new(1, ContentWidth, 1, -(ContainerOffsetY + 8))
	ListContainer.Position = UDim2.new(0, ContentX, 0, ContainerOffsetY)
	ListContainer.BackgroundTransparency = 1
	ListContainer.ClipsDescendants = true
	ListContainer.Active = true
	ListContainer.Parent = Main

	local List = Instance.new("ScrollingFrame")
	List.Size = UDim2.new(1, 0, 1, 0)
	List.BackgroundTransparency = 1
	List.BorderSizePixel = 0
	List.ScrollBarThickness = 2
	List.ScrollBarImageColor3 = Color3.fromRGB(60, 60, 75)
	List.CanvasSize = UDim2.new(0, 0, 0, 0)
	List.AutomaticCanvasSize = Enum.AutomaticSize.Y
	List.Active = true
	List.Parent = ListContainer

	local Grid = Instance.new("UIGridLayout")
	local cardCellWidth = UDim2.new(0.31, 0, 0, isMobile and 118 or 122)
	Grid.CellSize = UDim2.new(0.31, 0, 0, isMobile and 108 or 112)
	Grid.CellPadding = UDim2.new(0, isMobile and 5 or 6, 0, 7)
	Grid.SortOrder = Enum.SortOrder.LayoutOrder
	Grid.Parent = List

	local EmptyMessage = Instance.new("TextLabel")
	EmptyMessage.Size = UDim2.new(1, 0, 0, 40)
	EmptyMessage.Position = UDim2.new(0, 0, 0, 20)
	EmptyMessage.BackgroundTransparency = 1
	EmptyMessage.Text = "Click any player or use SAVE SELF to save an avatar."
	EmptyMessage.TextColor3 = Color3.fromRGB(110, 110, 125)
	EmptyMessage.TextSize = 10
	EmptyMessage.Font = Enum.Font.Gotham
	EmptyMessage.Parent = ListContainer

	local Sidebar = Instance.new("Frame")
	Sidebar.Name = "Sidebar"
Sidebar.Size = UDim2.new(0, isMobile and 46 or 50, 0, 0)
Sidebar.AutomaticSize = Enum.AutomaticSize.Y
	Sidebar.Position = UDim2.new(0, 8, 0, 38)
	Sidebar.BackgroundColor3 = Color3.fromRGB(25, 25, 32)
	Sidebar.BorderSizePixel = 0
	Sidebar.ZIndex = 5
	Sidebar.Active = true
	Sidebar.Parent = Main

	local SidebarCorner = Instance.new("UICorner")
	SidebarCorner.CornerRadius = UDim.new(0, 7)
	SidebarCorner.Parent = Sidebar

	local SidebarStroke = Instance.new("UIStroke")
	SidebarStroke.Color = Color3.fromRGB(48, 48, 60)
	SidebarStroke.Thickness = 1
	SidebarStroke.Parent = Sidebar

	local SideLayout = Instance.new("UIListLayout")
	SideLayout.Padding = UDim.new(0, 5)
	SideLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	SideLayout.VerticalAlignment = Enum.VerticalAlignment.Top
	SideLayout.SortOrder = Enum.SortOrder.LayoutOrder
	SideLayout.Parent = Sidebar

	local SidePadding = Instance.new("UIPadding")
	SidePadding.PaddingTop = UDim.new(0, 7)
	SidePadding.PaddingLeft = UDim.new(0, 5)
	SidePadding.PaddingRight = UDim.new(0, 5)
	SidePadding.PaddingBottom = UDim.new(0, 7)
	SidePadding.Parent = Sidebar

	local function createNavButton(name, iconText, order, isDestructive)
		local button = Instance.new("TextButton")
		button.Name = name
		button.Size = UDim2.new(1, 0, 0, isMobile and 32 or 34)
		button.LayoutOrder = order
		button.BackgroundColor3 = isDestructive and Color3.fromRGB(90, 35, 35) or Color3.fromRGB(35, 35, 45)
		button.BorderSizePixel = 0
		button.Text = iconText
		button.TextColor3 = isDestructive and Color3.fromRGB(255, 225, 225) or Color3.fromRGB(190, 190, 205)
		button.TextSize = isMobile and 17 or 18
		button.Font = Enum.Font.Gotham
		button.TextWrapped = false
		button.TextScaled = false
		button.AutoButtonColor = false
		button.ZIndex = 6
		button.Active = true
		button.Parent = Sidebar

		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 6)
		corner.Parent = button

		local stroke = Instance.new("UIStroke")
		stroke.Name = "Outline"
		stroke.Color = isDestructive and Color3.fromRGB(125, 45, 45) or Color3.fromRGB(58, 58, 72)
		stroke.Thickness = 1
		stroke.Parent = button

		return button
	end

	local SavedNav = createNavButton("SavedNav", utf8.char(0x1F4BE), 1, false)
	local PlayersNav = createNavButton("PlayersNav", utf8.char(0x1F5A5), 2, false)
	local FriendsNav = createNavButton("FriendsNav", utf8.char(0x1F464), 3, false)
local WorldPopupNav = createNavButton("WorldPopupNav", utf8.char(0x1F446, 0x1F3FB), 4, false)
 WorldPopupNav.Size = UDim2.new(0, isMobile and 32 or 34, 0, isMobile and 32 or 34)
 WorldPopupNav:FindFirstChildOfClass("UICorner").CornerRadius = UDim.new(0.5, 0)
WorldPopupNav.TextSize = isMobile and 18 or 20

	UnloadButton.Parent = Sidebar
	UnloadButton.Size = UDim2.new(0, isMobile and 32 or 34, 0, isMobile and 32 or 34)
	UnloadButton.Position = UDim2.new(0, 0, 0, 0)
UnloadButton.LayoutOrder = 5
	UnloadButton.BackgroundColor3 = Color3.fromRGB(100, 25, 25)
	UnloadButton.Text = utf8.char(0x1F4E4)
	UnloadButton.TextColor3 = Color3.fromRGB(255, 225, 225)
	UnloadButton.TextSize = isMobile and 17 or 18
	UnloadButton.Font = Enum.Font.Gotham
	UnloadButton.TextWrapped = false
	UnloadButton.BorderSizePixel = 0
	UnloadButton.ZIndex = 6
	UnloadCorner.CornerRadius = UDim.new(0.5, 0)

	local function createSocialPage(name, titleText)
		local page = Instance.new("Frame")
		page.Name = name
		page.Size = UDim2.new(1, ContentWidth, 1, -52)
		page.Position = UDim2.new(0, ContentX, 0, 44)
		page.BackgroundTransparency = 1
		page.Visible = false
		page.ZIndex = 5
		page.ClipsDescendants = true
		page.Parent = Main

		local title = Instance.new("TextLabel")
		title.Size = UDim2.new(1, -(isMobile and 108 or 136), 0, 16)
		title.Position = UDim2.new(0, 2, 0, 0)
		title.BackgroundTransparency = 1
		title.Text = titleText
		title.TextColor3 = Color3.fromRGB(230, 230, 240)
		title.TextSize = 9
		title.Font = Enum.Font.GothamBold
		title.TextXAlignment = Enum.TextXAlignment.Left
		title.ZIndex = 6
		title.Parent = page

		local searchBox = Instance.new("TextBox")
		searchBox.Name = "SearchBox"
		searchBox.Size = UDim2.new(0, isMobile and 102 or 130, 0, 16)
		searchBox.Position = UDim2.new(1, -(isMobile and 104 or 132), 0, 0)
		searchBox.BackgroundColor3 = Color3.fromRGB(72, 72, 82)
		searchBox.BorderSizePixel = 0
		searchBox.PlaceholderText = "Search Players"
		searchBox.PlaceholderColor3 = Color3.fromRGB(195, 195, 205)
		searchBox.Text = ""
		searchBox.TextColor3 = Color3.fromRGB(255, 255, 255)
		searchBox.TextSize = 7
		searchBox.Font = Enum.Font.GothamBold
		searchBox.ClearTextOnFocus = false
		searchBox.TextXAlignment = Enum.TextXAlignment.Left
		searchBox.ZIndex = 7
		searchBox.Active = true
		searchBox.Parent = page

		local searchCorner = Instance.new("UICorner")
		searchCorner.CornerRadius = UDim.new(1, 0)
		searchCorner.Parent = searchBox


		local status = Instance.new("TextLabel")
		status.Size = UDim2.new(1, -4, 0, 13)
		status.Position = UDim2.new(0, 2, 0, 15)
		status.BackgroundTransparency = 1
		status.Text = "Loading..."
		status.TextColor3 = Color3.fromRGB(125, 125, 140)
		status.TextSize = 7
		status.Font = Enum.Font.Gotham
		status.TextXAlignment = Enum.TextXAlignment.Left
		status.ZIndex = 6
		status.Parent = page

		local scroll = Instance.new("ScrollingFrame")
		scroll.Name = "Grid"
		scroll.Size = UDim2.new(1, 0, 1, -29)
		scroll.Position = UDim2.new(0, 0, 0, 29)
		scroll.BackgroundTransparency = 1
		scroll.BorderSizePixel = 0
		scroll.ScrollBarThickness = 2
		scroll.ScrollBarImageColor3 = Color3.fromRGB(60, 60, 75)
		scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
		scroll.Active = true
		scroll.ZIndex = 5
		scroll.Parent = page

		local layout = Instance.new("UIGridLayout")
		local socialCellWidth = UDim2.new(0.31, 0, 0, isMobile and 108 or 112)
		layout.CellSize = socialCellWidth
		layout.CellPadding = UDim2.new(0, isMobile and 5 or 6, 0, 7)
		layout.SortOrder = Enum.SortOrder.LayoutOrder
		layout.Parent = scroll

		local empty = Instance.new("TextLabel")
		empty.Size = UDim2.new(1, 0, 0, 40)
		empty.Position = UDim2.new(0, 0, 0, 24)
		empty.BackgroundTransparency = 1
		empty.Text = ""
		empty.TextColor3 = Color3.fromRGB(110, 110, 125)
		empty.TextSize = 8
		empty.Font = Enum.Font.Gotham
		empty.TextWrapped = true
		empty.Visible = false
		empty.ZIndex = 6
		empty.Parent = page

		socialPages[name] = {Frame = page, Scroll = scroll, Layout = layout, Status = status, Empty = empty, SearchBox = searchBox, Items = {}, NextPage = nil, Finished = true}
		searchBox.PlaceholderText = name == "FriendsPage" and "Search Friends" or "Search Players"
		return socialPages[name]
	end

	local PlayersPage = createSocialPage("PlayersPage", "PLAYERS IN SERVER")
	local FriendsPage = createSocialPage("FriendsPage", "FRIENDS LIST")

	local ActionModal = Instance.new("Frame")
	ActionModal.Size = UDim2.new(0, isMobile and 188 or 220, 0, 150)
	ActionModal.Position = UDim2.new(0, 8, 0, 42)
	ActionModal.BackgroundTransparency = 1
	ActionModal.BorderSizePixel = 0
	ActionModal.Visible = false
	ActionModal.Active = false
	ActionModal.ZIndex = 30
	ActionModal.ClipsDescendants = false
	ActionModal.Parent = Main

	local ModalBox = Instance.new("Frame")
	ModalBox.Size = UDim2.new(1, 0, 1, 0)
	ModalBox.Position = UDim2.new(0, 0, 0, 0)
	ModalBox.BackgroundColor3 = Color3.fromRGB(28, 28, 36)
	ModalBox.BorderSizePixel = 0
	ModalBox.ZIndex = 31
	ModalBox.Active = true
	ModalBox.Parent = ActionModal

	local ModalCorner = Instance.new("UICorner")
	ModalCorner.CornerRadius = UDim.new(0, 8)
	ModalCorner.Parent = ModalBox

	local ModalStroke = Instance.new("UIStroke")
	ModalStroke.Color = Color3.fromRGB(48, 48, 60)
	ModalStroke.Thickness = 1
	ModalStroke.Parent = ModalBox

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
	ModalWear.Size = UDim2.new(1, -20, 0, 26)
	ModalWear.Position = UDim2.new(0, 10, 0, 36)
	ModalWear.BackgroundColor3 = IS_CATALOG_GAME and Color3.fromRGB(55, 95, 175) or Color3.fromRGB(55, 55, 65)
	ModalWear.Text = IS_CATALOG_GAME and "WEAR AVATAR" or "WEAR [CAC ONLY]"
	ModalWear.TextColor3 = IS_CATALOG_GAME and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(130, 130, 140)
	ModalWear.TextSize = 9
	ModalWear.Font = Enum.Font.GothamBold
	ModalWear.ZIndex = 32
	ModalWear.Active = true
	ModalWear.Parent = ModalBox

	local ModalWearCorner = Instance.new("UICorner")
	ModalWearCorner.CornerRadius = UDim.new(0, 6)
	ModalWearCorner.Parent = ModalWear

	local ModalInspect = Instance.new("TextButton")
	ModalInspect.Size = UDim2.new(1, -20, 0, 26)
	ModalInspect.Position = UDim2.new(0, 10, 0, 68)
	ModalInspect.BackgroundColor3 = Color3.fromRGB(60, 110, 100)
	ModalInspect.Text = "INSPECT AVATAR"
	ModalInspect.TextColor3 = Color3.fromRGB(255, 255, 255)
	ModalInspect.TextSize = 9
	ModalInspect.Font = Enum.Font.GothamBold
	ModalInspect.ZIndex = 32
	ModalInspect.Active = true
	ModalInspect.Parent = ModalBox

	local ModalInspectCorner = Instance.new("UICorner")
	ModalInspectCorner.CornerRadius = UDim.new(0, 6)
	ModalInspectCorner.Parent = ModalInspect

	local ModalDelete = Instance.new("TextButton")
	ModalDelete.Size = UDim2.new(1, -20, 0, 26)
	ModalDelete.Position = UDim2.new(0, 10, 0, 100)
	ModalDelete.BackgroundColor3 = Color3.fromRGB(150, 50, 50)
	ModalDelete.Text = "DELETE"
	ModalDelete.TextColor3 = Color3.fromRGB(255, 255, 255)
	ModalDelete.TextSize = 9
	ModalDelete.Font = Enum.Font.GothamBold
	ModalDelete.ZIndex = 32
	ModalDelete.Active = true
	ModalDelete.Parent = ModalBox

	local ModalDeleteCorner = Instance.new("UICorner")
	ModalDeleteCorner.CornerRadius = UDim.new(0, 6)
	ModalDeleteCorner.Parent = ModalDelete

	local ModalClose = Instance.new("TextButton")
	ModalClose.Size = UDim2.new(0, 20, 0, 20)
	ModalClose.Position = UDim2.new(1, -24, 0, 6)
	ModalClose.BackgroundColor3 = Color3.fromRGB(65, 65, 75)
	ModalClose.BackgroundTransparency = 0
	ModalClose.Text = "X"
	ModalClose.TextColor3 = Color3.fromRGB(160, 160, 175)
	ModalClose.TextSize = 10
	ModalClose.Font = Enum.Font.GothamBold
	ModalClose.ZIndex = 32
	ModalClose.Active = true
	ModalClose.Parent = ModalBox

	local InspectorModal = Instance.new("Frame")
	InspectorModal.Name = "AvatarInspectorPage"
	InspectorModal.Size = UDim2.new(1, 0, 1, -34)
	InspectorModal.Position = UDim2.new(0, 0, 0, 34)
	InspectorModal.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
	InspectorModal.BorderSizePixel = 0
	InspectorModal.Visible = false
	InspectorModal.Active = true
	InspectorModal.ZIndex = 20
	InspectorModal.ClipsDescendants = true
	InspectorModal.Parent = Main

	local InspectorCorner = Instance.new("UICorner")
	InspectorCorner.CornerRadius = UDim.new(0, 8)
	InspectorCorner.Parent = InspectorModal

	local InspectHeader = Instance.new("Frame")
	InspectHeader.Name = "InspectHeader"
	InspectHeader.Size = UDim2.new(1, 0, 0, 30)
	InspectHeader.BackgroundColor3 = Color3.fromRGB(25, 25, 32)
	InspectHeader.BorderSizePixel = 0
	InspectHeader.ZIndex = 21
	InspectHeader.Active = true
	InspectHeader.Parent = InspectorModal

	local InspectHeaderCorner = Instance.new("UICorner")
	InspectHeaderCorner.CornerRadius = UDim.new(0, 8)
	InspectHeaderCorner.Parent = InspectHeader

	local InspectTitle = Instance.new("TextLabel")
	InspectTitle.Size = UDim2.new(1, -58, 1, 0)
	InspectTitle.Position = UDim2.new(0, 12, 0, 0)
	InspectTitle.BackgroundTransparency = 1
	InspectTitle.Text = "Avatar Inspector"
	InspectTitle.TextColor3 = Color3.fromRGB(235, 235, 245)
	InspectTitle.TextSize = 11
	InspectTitle.Font = Enum.Font.GothamBold
	InspectTitle.TextXAlignment = Enum.TextXAlignment.Left
	InspectTitle.ZIndex = 22
	InspectTitle.Parent = InspectHeader

	local InspectBack = Instance.new("TextButton")
	InspectBack.Name = "InspectBack"
	InspectBack.Size = UDim2.new(0, 44, 0, 20)
	InspectBack.Position = UDim2.new(1, -50, 0, 5)
	InspectBack.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
	InspectBack.Text = "BACK"
	InspectBack.TextColor3 = Color3.fromRGB(200, 200, 210)
	InspectBack.TextSize = 8
	InspectBack.Font = Enum.Font.GothamBold
	InspectBack.ZIndex = 22
	InspectBack.Active = true
	InspectBack.Parent = InspectHeader

	local InspectBackCorner = Instance.new("UICorner")
	InspectBackCorner.CornerRadius = UDim.new(0, 4)
	InspectBackCorner.Parent = InspectBack

	local LeftPane = Instance.new("Frame")
	LeftPane.Size = UDim2.new(0.38, -6, 1, -36)
	LeftPane.Position = UDim2.new(0, 6, 0, 32)
	LeftPane.BackgroundColor3 = Color3.fromRGB(48, 48, 56)
	LeftPane.BorderSizePixel = 0
	LeftPane.ZIndex = 21
	LeftPane.ClipsDescendants = true
	LeftPane.Active = true
	LeftPane.Parent = InspectorModal

	local LeftCorner = Instance.new("UICorner")
	LeftCorner.CornerRadius = UDim.new(0, 6)
	LeftCorner.Parent = LeftPane

	local InspectorWearButton = Instance.new("TextButton")
	InspectorWearButton.AnchorPoint = Vector2.new(0.5, 1)
	InspectorWearButton.Size = UDim2.new(0, 70, 0, 18)
	InspectorWearButton.Position = UDim2.new(0.5, 0, 1, -6)
	InspectorWearButton.BackgroundColor3 = IS_CATALOG_GAME and Color3.fromRGB(55, 95, 175) or Color3.fromRGB(55, 55, 65)
	InspectorWearButton.BorderSizePixel = 0
	InspectorWearButton.Text = IS_CATALOG_GAME and "WEAR" or "WEAR [CAC ONLY]"
	InspectorWearButton.TextColor3 = IS_CATALOG_GAME and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(130, 130, 140)
	InspectorWearButton.TextSize = 8
	InspectorWearButton.Font = Enum.Font.GothamBold
	InspectorWearButton.ZIndex = 30
	InspectorWearButton.Active = IS_CATALOG_GAME
	InspectorWearButton.Parent = LeftPane

	local InspectorWearButtonCorner = Instance.new("UICorner")
	InspectorWearButtonCorner.CornerRadius = UDim.new(1, 0)
	InspectorWearButtonCorner.Parent = InspectorWearButton
	local InspectorSaveAvatarButton = Instance.new("TextButton")
	InspectorSaveAvatarButton.Name = "InspectorSaveAvatarButton"
	InspectorSaveAvatarButton.AnchorPoint = Vector2.new(0.5, 0)
	InspectorSaveAvatarButton.Size = UDim2.new(0, 94, 0, 18)
	InspectorSaveAvatarButton.Position = UDim2.new(0.5, 0, 0, 6)
	InspectorSaveAvatarButton.BackgroundColor3 = Color3.fromRGB(46, 125, 85)
	InspectorSaveAvatarButton.BorderSizePixel = 0
	InspectorSaveAvatarButton.Text = "SAVE AVATAR"
	InspectorSaveAvatarButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	InspectorSaveAvatarButton.TextSize = 8
	InspectorSaveAvatarButton.Font = Enum.Font.GothamBold
	InspectorSaveAvatarButton.ZIndex = 30
	InspectorSaveAvatarButton.Active = true
	InspectorSaveAvatarButton.Visible = false
	InspectorSaveAvatarButton.Parent = LeftPane
	Instance.new("UICorner", InspectorSaveAvatarButton).CornerRadius = UDim.new(1, 0)

	local RightPane = Instance.new("Frame")
	RightPane.Size = UDim2.new(0.62, -10, 1, -36)
	RightPane.Position = UDim2.new(0.38, 4, 0, 32)
	RightPane.BackgroundTransparency = 1
	RightPane.ZIndex = 21
	RightPane.Active = true
	RightPane.Parent = InspectorModal

	local ProfileCard = Instance.new("Frame")
	ProfileCard.Size = UDim2.new(1, 0, 0, 40)
	ProfileCard.BackgroundColor3 = Color3.fromRGB(25, 25, 32)
	ProfileCard.BorderSizePixel = 0
	ProfileCard.ZIndex = 22
	ProfileCard.Active = true
	ProfileCard.Parent = RightPane

	local ProfileCorner = Instance.new("UICorner")
	ProfileCorner.CornerRadius = UDim.new(0, 6)
	ProfileCorner.Parent = ProfileCard

	local ProfileIcon = Instance.new("ImageLabel")
	ProfileIcon.Size = UDim2.new(0, 30, 0, 30)
	ProfileIcon.Position = UDim2.new(0, 5, 0, 5)
	ProfileIcon.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
	ProfileIcon.ScaleType = Enum.ScaleType.Fit
	ProfileIcon.ZIndex = 23
	ProfileIcon.Parent = ProfileCard

	local IconCorner = Instance.new("UICorner")
	IconCorner.CornerRadius = UDim.new(1, 0)
	IconCorner.Parent = ProfileIcon

	local ProfileName = Instance.new("TextLabel")
	ProfileName.Size = UDim2.new(1, -102, 0, 15)
	ProfileName.Position = UDim2.new(0, 40, 0, 3)
	ProfileName.BackgroundTransparency = 1
	ProfileName.Text = "DisplayName"
	ProfileName.TextColor3 = Color3.fromRGB(240, 240, 245)
	ProfileName.TextSize = 9
	ProfileName.Font = Enum.Font.GothamBold
	ProfileName.TextXAlignment = Enum.TextXAlignment.Left
	ProfileName.TextScaled = true
	ProfileName.ZIndex = 23
	ProfileName.Parent = ProfileCard

	local NameConstraint = Instance.new("UITextSizeConstraint")
	NameConstraint.MinTextSize = 7
	NameConstraint.MaxTextSize = 10
	NameConstraint.Parent = ProfileName

	local ProfileUserBtn = Instance.new("TextButton")
	ProfileUserBtn.Size = UDim2.new(1, -102, 0, 16)
	ProfileUserBtn.Position = UDim2.new(0, 40, 0, 19)
	ProfileUserBtn.BackgroundTransparency = 1
	ProfileUserBtn.Text = "@Username"
	ProfileUserBtn.TextColor3 = Color3.fromRGB(140, 140, 155)
	ProfileUserBtn.TextSize = 7
	ProfileUserBtn.Font = Enum.Font.Gotham
	ProfileUserBtn.TextXAlignment = Enum.TextXAlignment.Left
	ProfileUserBtn.TextScaled = true
	ProfileUserBtn.ZIndex = 23
	ProfileUserBtn.Active = true
	ProfileUserBtn.Parent = ProfileCard

	local UserConstraint = Instance.new("UITextSizeConstraint")
	UserConstraint.MinTextSize = 5
	UserConstraint.MaxTextSize = 8
	UserConstraint.Parent = ProfileUserBtn

	local InspectorProfileCopy = Instance.new("TextButton")
	InspectorProfileCopy.Size = UDim2.new(0, 56, 0, 22)
	InspectorProfileCopy.Position = UDim2.new(1, -61, 0, 9)
	InspectorProfileCopy.BackgroundColor3 = Color3.fromRGB(60, 110, 100)
	InspectorProfileCopy.Text = "VIEW\nPROFILE"
	InspectorProfileCopy.TextColor3 = Color3.fromRGB(255, 255, 255)
	InspectorProfileCopy.TextSize = 7
	InspectorProfileCopy.Font = Enum.Font.GothamBold
	InspectorProfileCopy.ZIndex = 23
	InspectorProfileCopy.Active = true
	InspectorProfileCopy.Parent = ProfileCard

	local InspectorProfileCopyCorner = Instance.new("UICorner")
	InspectorProfileCopyCorner.CornerRadius = UDim.new(0, 5)
	InspectorProfileCopyCorner.Parent = InspectorProfileCopy

	local AssetGridList = Instance.new("ScrollingFrame")
	AssetGridList.Size = UDim2.new(1, 0, 1, -44)
	AssetGridList.Position = UDim2.new(0, 0, 0, 44)
	AssetGridList.BackgroundTransparency = 1
	AssetGridList.BorderSizePixel = 0
	AssetGridList.ScrollBarThickness = 2
	AssetGridList.ScrollBarImageColor3 = Color3.fromRGB(60, 60, 75)
	AssetGridList.AutomaticCanvasSize = Enum.AutomaticSize.Y
	AssetGridList.ZIndex = 22
	AssetGridList.Active = true
	AssetGridList.Parent = RightPane

	local AssetGridLayout = Instance.new("UIGridLayout")
	AssetGridLayout.CellSize = UDim2.new(0.48, -2, 0, 72)
	AssetGridLayout.CellPadding = UDim2.new(0, 4, 0, 4)
	AssetGridLayout.SortOrder = Enum.SortOrder.LayoutOrder
	AssetGridLayout.Parent = AssetGridList

	local ConfirmOverlay = Instance.new("TextButton")
	ConfirmOverlay.Name = "ConfirmOverlay"
	ConfirmOverlay.Size = UDim2.new(1, 0, 1, -34)
	ConfirmOverlay.Position = UDim2.new(0, 0, 0, 34)
	ConfirmOverlay.BackgroundColor3 = Color3.fromRGB(8, 8, 12)
	ConfirmOverlay.BackgroundTransparency = 0.45
	ConfirmOverlay.BorderSizePixel = 0
	ConfirmOverlay.Text = ""
	ConfirmOverlay.AutoButtonColor = false
	ConfirmOverlay.Modal = false
	ConfirmOverlay.Visible = false
	ConfirmOverlay.Active = true
	ConfirmOverlay.ZIndex = 49
	ConfirmOverlay.Parent = Main

	local ConfirmFrame = Instance.new("Frame")
	ConfirmFrame.Size = UDim2.new(1, -20, 0, 70)
	ConfirmFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	ConfirmFrame.Position = UDim2.new(0.5, 0, 0.5, -17)
	ConfirmFrame.BackgroundColor3 = Color3.fromRGB(32, 32, 40)
	ConfirmFrame.BorderSizePixel = 0
	ConfirmFrame.Visible = false
	ConfirmFrame.Active = true
	ConfirmFrame.ZIndex = 50
	ConfirmFrame.ClipsDescendants = true
	ConfirmFrame.Parent = ConfirmOverlay

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
	CancelButton.Active = true
	CancelButton.Parent = ConfirmFrame

	local CancelCorner = Instance.new("UICorner")
	CancelCorner.CornerRadius = UDim.new(0, 6)
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
	ConfirmAction.Active = true
	ConfirmAction.Parent = ConfirmFrame

	local ConfirmActionCorner = Instance.new("UICorner")
	ConfirmActionCorner.CornerRadius = UDim.new(0, 6)
	ConfirmActionCorner.Parent = ConfirmAction

	local SelectFrame = Instance.new("Frame")
	SelectFrame.Size = UDim2.new(0, 200, 0, 70)
	SelectFrame.Position = UDim2.new(0.5, -100, 0.8, 0)
	SelectFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 38)
	SelectFrame.BorderSizePixel = 0
	SelectFrame.Visible = false
	SelectFrame.Active = true
	SelectFrame.ZIndex = 60
	SelectFrame.ClipsDescendants = true
	SelectFrame.Parent = ScreenGui

	local SelectInputBlocker = Instance.new("TextButton")
	SelectInputBlocker.Size = UDim2.new(1, 0, 1, 0)
	SelectInputBlocker.BackgroundTransparency = 1
	SelectInputBlocker.Text = ""
	SelectInputBlocker.AutoButtonColor = false
	SelectInputBlocker.Modal = true
	SelectInputBlocker.ZIndex = 60
	SelectInputBlocker.Active = true
	SelectInputBlocker.Parent = SelectFrame

	local SelectCorner = Instance.new("UICorner")
	SelectCorner.CornerRadius = UDim.new(0, 8)
	SelectCorner.Parent = SelectFrame

	local SelectedProfileIcon = Instance.new("ImageLabel")
	SelectedProfileIcon.Size = UDim2.new(0, 24, 0, 24)
	SelectedProfileIcon.Position = UDim2.new(0, 8, 0, 4)
	SelectedProfileIcon.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
	SelectedProfileIcon.ScaleType = Enum.ScaleType.Fit
	SelectedProfileIcon.ZIndex = 61
	SelectedProfileIcon.Parent = SelectFrame

	local SelectedProfileIconCorner = Instance.new("UICorner")
	SelectedProfileIconCorner.CornerRadius = UDim.new(1, 0)
	SelectedProfileIconCorner.Parent = SelectedProfileIcon

	local SelectedName = Instance.new("TextLabel")
	SelectedName.Size = UDim2.new(1, -92, 0, 22)
	SelectedName.Position = UDim2.new(0, 38, 0, 5)
	SelectedName.BackgroundTransparency = 1
	SelectedName.Text = "@Player"
	SelectedName.TextColor3 = Color3.fromRGB(255, 255, 255)
	SelectedName.TextSize = 10
	SelectedName.Font = Enum.Font.GothamBold
	SelectedName.TextXAlignment = Enum.TextXAlignment.Left
	SelectedName.TextTruncate = Enum.TextTruncate.AtEnd
	SelectedName.ZIndex = 61
	SelectedName.Parent = SelectFrame

	local CopyProfileButton = Instance.new("TextButton")
	CopyProfileButton.Size = UDim2.new(0, 46, 0, 22)
	CopyProfileButton.Position = UDim2.new(1, -54, 0, 5)
	CopyProfileButton.BackgroundColor3 = Color3.fromRGB(60, 110, 100)
	CopyProfileButton.Text = "SAVE\nPROFILE"
	CopyProfileButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	CopyProfileButton.TextSize = 7
	CopyProfileButton.Font = Enum.Font.GothamBold
	CopyProfileButton.ZIndex = 61
	CopyProfileButton.Active = true
	CopyProfileButton.Parent = SelectFrame

	local CopyProfileCorner = Instance.new("UICorner")
	CopyProfileCorner.CornerRadius = UDim.new(0, 6)
	CopyProfileCorner.Parent = CopyProfileButton

	local HoldButton = Instance.new("TextButton")
	HoldButton.Size = UDim2.new(1, -76, 0, 28)
	HoldButton.Position = UDim2.new(0, 8, 0, 30)
	HoldButton.BackgroundColor3 = Color3.fromRGB(55, 95, 175)
	HoldButton.Text = "SAVE WEARING"
	HoldButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	HoldButton.TextSize = 9
	HoldButton.Font = Enum.Font.GothamBold
	HoldButton.ZIndex = 61
	HoldButton.Active = true
	HoldButton.Parent = SelectFrame

	local HoldCorner = Instance.new("UICorner")
	HoldCorner.CornerRadius = UDim.new(0, 6)
	HoldCorner.Parent = HoldButton

	local SelectCancel = Instance.new("TextButton")
	SelectCancel.Size = UDim2.new(0, 54, 0, 28)
	SelectCancel.Position = UDim2.new(1, -62, 0, 30)
	SelectCancel.BackgroundColor3 = Color3.fromRGB(85, 45, 45)
	SelectCancel.Text = "CANCEL"
	SelectCancel.TextColor3 = Color3.fromRGB(255, 255, 255)
	SelectCancel.TextSize = 9
	SelectCancel.Font = Enum.Font.GothamBold
	SelectCancel.ZIndex = 61
	SelectCancel.Active = true
	SelectCancel.Parent = SelectFrame

	local SelectCancelCorner = Instance.new("UICorner")
	SelectCancelCorner.CornerRadius = UDim.new(0, 6)
	SelectCancelCorner.Parent = SelectCancel

	local function pointInsideGui(guiObject, position)
		local guiPos = guiObject.AbsolutePosition
		local guiSize = guiObject.AbsoluteSize
		return position.X >= guiPos.X
			and position.Y >= guiPos.Y
			and position.X <= guiPos.X + guiSize.X
			and position.Y <= guiPos.Y + guiSize.Y
	end

wire(UserInputService.InputChanged, function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			local delta = input.Position - dragStart
			Main.Position = UDim2.new(
				startPosition.X.Scale,
				startPosition.X.Offset + delta.X,
				startPosition.Y.Scale,
				startPosition.Y.Offset + delta.Y
			)
		end
end)

wire(UserInputService.InputEnded, function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
end)

	local function updateStatus()
		if not scriptAlive then return end
		Status.Text = "Saved Avatars: " .. tostring(#copiedAvatars)
		EmptyMessage.Visible = (#copiedAvatars == 0) and not minimized
	end

	local function hideSelectFrame()
		if not scriptAlive then return end
		markUIClick()
		selectedPlayer = nil
		SelectFrame.Visible = false
		HoldButton.Text = "SAVE WEARING"
		HoldButton.BackgroundColor3 = Color3.fromRGB(55, 95, 175)
		HoldButton.Active = true
		CopyProfileButton.Text = "SAVE\nPROFILE"
		CopyProfileButton.BackgroundColor3 = Color3.fromRGB(60, 110, 100)
		CopyProfileButton.Active = true
	end

local function updateWorldPopupToggle()
if worldPlayerPopupEnabled then
WorldPopupNav.BackgroundColor3 = Color3.fromRGB(35, 190, 75)
WorldPopupNav.TextColor3 = Color3.fromRGB(255, 255, 255)
WorldPopupNav.Outline.Color = Color3.fromRGB(95, 235, 125)
else
WorldPopupNav.BackgroundColor3 = Color3.fromRGB(210, 45, 45)
WorldPopupNav.TextColor3 = Color3.fromRGB(255, 255, 255)
WorldPopupNav.Outline.Color = Color3.fromRGB(245, 100, 100)
end
end

updateWorldPopupToggle()

WorldPopupNav.Activated:Connect(function()
markUIClick()
worldPlayerPopupEnabled = not worldPlayerPopupEnabled
if not worldPlayerPopupEnabled then
hideSelectFrame()
end
updateWorldPopupToggle()
end)

	local function wearCopiedAvatar(data)
		if not IS_CATALOG_GAME or not data or not data.Properties then return end

		local rigTypeEnum = getEnumRigType(data.RigType)

		local cleanProps = {}
		for k, v in pairs(data.Properties) do
			if k ~= "Emotes" and k ~= "EquippedEmotes" and k ~= "AllAccessories" then
				cleanProps[k] = v
			end
		end

		local wearPayload = {
			Properties = cleanProps,
			Action = "CreateAndWearHumanoidDescription",
			RigType = rigTypeEnum
		}

		local ok = pcall(function()
			catalogGuiRemote:InvokeServer(wearPayload)
		end)
		return ok
	end

	local function saveCurrentOutfit()
		if not IS_CATALOG_GAME then return end
		pcall(function()
			savedOutfitsRemote:InvokeServer({
				OutfitName = "Unnamed Outfit",
				Configs = {},
				Action = "CreateNewOutfit"
			})
		end)
		if not scriptAlive then return end
		Status.Text = "Current outfit saved!"
		task.delay(2, updateStatus)
	end

	local function destroyScriptAndUI()
		emergencyCleanup()
	end

	local function safeSetClipboard(text)
		if type(setclipboard) == "function" then
			return pcall(function()
				setclipboard(tostring(text))
			end)
		end
		return false
	end

	local function populateAssetInspector(data)
		for _, child in ipairs(AssetGridList:GetChildren()) do
			if child:IsA("Frame") then child:Destroy() end
		end

		ProfileName.Text = data.DisplayName or data.Name
		local userIdStr = tostring(data.UserId or "0")
		ProfileUserBtn.Text = "@" .. data.Name
		ProfileIcon.Image = "rbxthumb://type=AvatarBust&id=" .. userIdStr .. "&w=420&h=420"

		renderSavedAvatarPreview(LeftPane, data, true)
		local inspectorSaveButton = LeftPane:FindFirstChild("InspectorSaveAvatarButton")
		if inspectorSaveButton then
			inspectorSaveButton.Visible = data._InspectorSocialSave == true
		end
		InspectorProfileCopy.Text = data._InspectorProfileState and "INSPECTING\nPROFILE" or "VIEW\nPROFILE"
		InspectorProfileCopy.BackgroundColor3 = data._InspectorProfileState and Color3.fromRGB(85, 85, 95) or Color3.fromRGB(60, 110, 100)
		InspectorProfileCopy.TextColor3 = data._InspectorProfileState and Color3.fromRGB(180, 180, 190) or Color3.fromRGB(255, 255, 255)
		InspectorProfileCopy.Active = not data._InspectorProfileState

		local seenAssets = {}
		local function addAssetCard(assetId)
			if not assetId or assetId == 0 or assetId == "" or seenAssets[tostring(assetId)] then return end
			seenAssets[tostring(assetId)] = true

			local AssetCard = Instance.new("Frame")
			AssetCard.Size = UDim2.new(0.48, -2, 0, 72)
			AssetCard.BackgroundColor3 = Color3.fromRGB(25, 25, 32)
			AssetCard.BorderSizePixel = 0
			AssetCard.ZIndex = 43
			AssetCard.Active = true
			AssetCard.Parent = AssetGridList

			local CardCorner = Instance.new("UICorner")
			CardCorner.CornerRadius = UDim.new(0, 6)
			CardCorner.Parent = AssetCard

			local AssetThumb = Instance.new("ImageLabel")
			AssetThumb.Size = UDim2.new(1, -6, 0, 46)
			AssetThumb.Position = UDim2.new(0, 3, 0, 3)
			AssetThumb.BackgroundColor3 = Color3.fromRGB(45, 45, 52)
			AssetThumb.Image = "rbxthumb://type=Asset&id=" .. tostring(assetId) .. "&w=420&h=420"
			AssetThumb.ScaleType = Enum.ScaleType.Fit
			AssetThumb.ZIndex = 44
			AssetThumb.Parent = AssetCard

			local ThumbCorner = Instance.new("UICorner")
			ThumbCorner.CornerRadius = UDim.new(0, 4)
			ThumbCorner.Parent = AssetThumb

			local CopyBtn = Instance.new("TextButton")
			CopyBtn.Size = UDim2.new(1, -6, 0, 16)
			CopyBtn.Position = UDim2.new(0, 3, 0, 52)
			CopyBtn.BackgroundColor3 = Color3.fromRGB(55, 95, 175)
			CopyBtn.Text = "COPY ID"
			CopyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
			CopyBtn.TextSize = 7
			CopyBtn.Font = Enum.Font.GothamBold
			CopyBtn.ZIndex = 44
			CopyBtn.Active = true
			CopyBtn.Parent = AssetCard

			local CopyCorner = Instance.new("UICorner")
			CopyCorner.CornerRadius = UDim.new(0, 4)
			CopyCorner.Parent = CopyBtn

			CopyBtn.Activated:Connect(function()
				markUIClick()
				if safeSetClipboard(assetId) then
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
			"LeftArm", "RightArm", "LeftLeg", "RightLeg",
			"WalkAnimation", "MoodAnimation", "ClimbAnimation", "FallAnimation",
			"RunAnimation", "SwimAnimation", "IdleAnimation", "JumpAnimation"
		}

		for _, propKey in ipairs(singleProperties) do
			if props[propKey] and tonumber(props[propKey]) and tonumber(props[propKey]) > 0 then
				addAssetCard(props[propKey])
			end
		end


		for _, accKey in ipairs(accessoryPropertyNames) do
			if props[accKey] and props[accKey] ~= "" then
				for id in string.gmatch(tostring(props[accKey]), "%d+") do
					addAssetCard(id)
				end
			end
		end
		
		if props.MakeupItems and type(props.MakeupItems) == "table" then
			for _, makeup in ipairs(props.MakeupItems) do
				if makeup.AssetId then addAssetCard(makeup.AssetId) end
			end
		end

		if props.LayeredAccessories and type(props.LayeredAccessories) == "table" then
			for _, layered in ipairs(props.LayeredAccessories) do
				if layered.AssetId then addAssetCard(layered.AssetId) end
			end
		end

		if props.AccessoryRefinements and type(props.AccessoryRefinements) == "table" then
			for assetIdStr, _ in pairs(props.AccessoryRefinements) do
				addAssetCard(assetIdStr)
			end
		end

		if props.Emotes and type(props.Emotes) == "table" then
			for _, assetList in pairs(props.Emotes) do
				if type(assetList) == "table" then
					for _, id in ipairs(assetList) do addAssetCard(id) end
				end
			end
		end

		Sidebar.Visible = false
		ListContainer.Visible = false
		SearchBox.Visible = false
		SaveButton.Visible = false
		CopySelfBtn.Visible = false
		ClearButton.Visible = false
		Status.Visible = false
		PlayersPage.Frame.Visible = false
		FriendsPage.Frame.Visible = false
		inspectorOpen = true
		InspectorModal.Visible = true
	end

ProfileUserBtn.Activated:Connect(function()
		markUIClick()
		if currentActiveData and currentActiveData.Name and safeSetClipboard("@" .. currentActiveData.Name) then
			local oldText = ProfileUserBtn.Text
			ProfileUserBtn.Text = "COPIED USERNAME!"
			ProfileUserBtn.TextColor3 = Color3.fromRGB(100, 220, 150)
			task.delay(1.2, function()
				ProfileUserBtn.Text = oldText
				ProfileUserBtn.TextColor3 = Color3.fromRGB(140, 140, 155)
			end)
		end
	end)

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
		Card.Name = "SavedAvatarCard"
		Card.Size = cardCellWidth
		Card.BackgroundColor3 = Color3.fromRGB(28, 28, 36)
		Card.BorderSizePixel = 0
		Card.LayoutOrder = index
		Card.ClipsDescendants = true
		Card.Active = true
		Card.ZIndex = 6
		Card.Parent = List

		local Corner = Instance.new("UICorner")
		Corner.CornerRadius = UDim.new(0, 6)
		Corner.Parent = Card

		local CardStroke = Instance.new("UIStroke")
		CardStroke.Color = Color3.fromRGB(40, 40, 50)
		CardStroke.Thickness = 1
		CardStroke.Parent = Card

		local PreviewContainer = Instance.new("Frame")
		PreviewContainer.Size = UDim2.new(1, -8, 0, isMobile and 70 or 76)
		PreviewContainer.Position = UDim2.new(0, 4, 0, 4)
		PreviewContainer.BackgroundColor3 = Color3.fromRGB(48, 48, 56)
		PreviewContainer.BorderSizePixel = 0
		PreviewContainer.Active = true
		PreviewContainer.ZIndex = 7
		PreviewContainer.Parent = Card

		local ThumbCorner = Instance.new("UICorner")
		ThumbCorner.CornerRadius = UDim.new(0, 4)
		ThumbCorner.Parent = PreviewContainer

		renderSavedAvatarPreview(PreviewContainer, data, false)

		local NameLabel = Instance.new("TextLabel")
		NameLabel.Name = "DisplayName"
		NameLabel.Size = UDim2.new(1, -6, 0, 14)
		NameLabel.Position = UDim2.new(0, 3, 0, isMobile and 74 or 80)
		NameLabel.BackgroundTransparency = 1
		NameLabel.Text = tostring(data.DisplayName or data.Name or "Unknown")
		NameLabel.TextColor3 = Color3.fromRGB(230, 230, 240)
		NameLabel.TextSize = isMobile and 7 or 8
		NameLabel.Font = Enum.Font.GothamBold
		NameLabel.TextTruncate = Enum.TextTruncate.AtEnd
		NameLabel.TextXAlignment = Enum.TextXAlignment.Left
		NameLabel.ZIndex = 8
		NameLabel.Parent = Card

		local UsernameButton = Instance.new("TextButton")
		UsernameButton.Name = "Username"
		UsernameButton.Size = UDim2.new(1, -6, 0, 13)
		UsernameButton.Position = UDim2.new(0, 3, 0, isMobile and 87 or 93)
		UsernameButton.BackgroundTransparency = 1
		UsernameButton.Text = "@" .. tostring(data.Name or "unknown")
		UsernameButton.TextColor3 = Color3.fromRGB(140, 140, 155)
		UsernameButton.TextSize = isMobile and 6 or 7
		UsernameButton.Font = Enum.Font.Gotham
		UsernameButton.TextTruncate = Enum.TextTruncate.AtEnd
		UsernameButton.TextXAlignment = Enum.TextXAlignment.Left
		UsernameButton.ZIndex = 11
		UsernameButton.Active = true
		UsernameButton.AutoButtonColor = false
		UsernameButton.Parent = Card

		local CardButton = Instance.new("TextButton")
		CardButton.Size = UDim2.new(1, 0, 1, 0)
		CardButton.BackgroundTransparency = 1
		CardButton.Text = ""
		CardButton.ZIndex = 9
		CardButton.Active = true
		CardButton.Parent = Card

		data.UI = Card
		data.NameLabel = NameLabel
		data.UsernameButton = UsernameButton

		UsernameButton.Activated:Connect(function()
			markUIClick()
			if data.Name and safeSetClipboard("@" .. data.Name) then
				local oldText = UsernameButton.Text
				UsernameButton.Text = "Copied Username!"
				UsernameButton.TextColor3 = Color3.fromRGB(100, 220, 150)
				task.delay(1.1, function()
					if UsernameButton and UsernameButton.Parent then
						UsernameButton.Text = oldText
						UsernameButton.TextColor3 = Color3.fromRGB(140, 140, 155)
					end
				end)
			end
		end)

		CardButton.Activated:Connect(function()
			markUIClick()
			currentActiveData = data
			ModalTitle.Text = "@" .. tostring(data.Name or "unknown")
			local mainPos = Main.AbsolutePosition
			local cardPos = Card.AbsolutePosition
			local cardSize = Card.AbsoluteSize
			local popupSize = ActionModal.AbsoluteSize
			local relX = cardPos.X - mainPos.X
			local relY = cardPos.Y - mainPos.Y + cardSize.Y + 6
			local maxX = math.max(8, Main.AbsoluteSize.X - popupSize.X - 8)
			local maxY = math.max(42, Main.AbsoluteSize.Y - popupSize.Y - 8)
			if relY > maxY then relY = cardPos.Y - mainPos.Y - popupSize.Y - 6 end
			relX = math.clamp(relX, 8, maxX)
			relY = math.clamp(relY, 42, maxY)
			ActionModal.Position = UDim2.new(0, relX, 0, relY)
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

	local function filterSavedAvatarCards(query)
		query = string.lower(tostring(query or ""))
		for _, data in ipairs(copiedAvatars) do
			local displayName = string.lower(tostring(data.DisplayName or ""))
			local username = string.lower(tostring(data.Name or ""))
			local matches = query == "" or displayName:find(query, 1, true) or username:find(query, 1, true)
			if data.UI and data.UI.Parent then data.UI.Visible = matches and true or false end
		end
	end

	local function loadFromWorkspace()
		if type(readfile) ~= "function" or type(isfile) ~= "function" then return end

		local exists, isF = pcall(isfile, FILE_PATH)
		if not (exists and isF) then return end

		local ok, result = pcall(function()
			return HttpService:JSONDecode(readfile(FILE_PATH))
		end)

		if ok and type(result) == "table" then
			table.clear(copiedAvatars)
			for index, data in ipairs(result) do
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
		if type(delfile) == "function" and type(isfile) == "function" then
			pcall(function() if isfile(FILE_PATH) then delfile(FILE_PATH) end end)
		end
		updateStatus()
		Status.Text = "Saved avatars cleared!"
		task.delay(2, updateStatus)
	end

	local function setProfileThumbnail(imageLabel, userId)
		if not imageLabel or not userId then return end
		task.spawn(function()
			local ok, content = pcall(function()
local image = Players:GetUserThumbnailAsync(userId, Enum.ThumbnailType.AvatarBust, Enum.ThumbnailSize.Size100x100)
				return image
			end)
if not scriptAlive then return end
if ok and content and imageLabel.Parent then
				imageLabel.Image = content
			elseif imageLabel.Parent then
imageLabel.Image = "rbxthumb://type=AvatarBust&id=" .. tostring(userId) .. "&w=100&h=100"
			end
		end)
	end

	local function getDescriptionAssetIds(desc)
		local ids = {}
		local seen = {}
		local function addId(id)
			id = tonumber(id)
			if id and id > 0 and not seen[id] then
				seen[id] = true
				table.insert(ids, id)
			end
		end

		local directAssetProps = {
			"Face", "Shirt", "Pants", "GraphicTShirt", "Head", "Torso",
			"LeftArm", "RightArm", "LeftLeg", "RightLeg"
		}
		for _, prop in ipairs(directAssetProps) do
			pcall(function() addId(desc[prop]) end)
		end

		for _, prop in ipairs(accessoryPropertyNames) do
			pcall(function()
				local value = desc[prop]
				for id in string.gmatch(tostring(value or ""), "%d+") do addId(id) end
			end)
		end

		pcall(function()
			for _, accessory in ipairs(desc:GetAccessories(true)) do
				addId(accessory.AssetId)
			end
		end)
		
		pcall(function()
			for _, child in ipairs(desc:GetChildren()) do
				if child:IsA("MakeupDescription") then
					addId(child.AssetId)
				end
			end
		end)

		pcall(function()
			if type(desc.GetMakeups) == "function" then
				for _, makeup in ipairs(desc:GetMakeups()) do
					addId(makeup.AssetId)
				end
			end
		end)

		pcall(function()
			if type(desc.GetEmotes) == "function" then
				for _, assetList in pairs(desc:GetEmotes()) do
					if type(assetList) == "table" then
						for _, id in ipairs(assetList) do addId(id) end
					end
				end
			end
		end)
		return ids
	end

	local function hasCopyableMarketplaceAsset(desc)
		local ids = getDescriptionAssetIds(desc)
		for _, assetId in ipairs(ids) do
			local ok = pcall(function()
				return MarketplaceService:GetProductInfoAsync(assetId, Enum.InfoType.Asset)
			end)
			if ok then return true end
		end
		return false
	end

	local function copyDescriptionForStorage(targetPlayer, desc)
		if not targetPlayer or not desc then return false end
		local ok, data = pcall(function()
			local character = targetPlayer.Character
			local humanoid = character and character:FindFirstChildOfClass("Humanoid")
			local properties = createCopiedProperties(desc, character)
			local rigTypeEnum = (humanoid and humanoid.RigType == Enum.HumanoidRigType.R6) and Enum.HumanoidRigType.R6 or Enum.HumanoidRigType.R15

			return {
				Name = targetPlayer.Name,
				UserId = targetPlayer.UserId,
				DisplayName = targetPlayer.DisplayName,
				Properties = properties,
				RigType = (rigTypeEnum == Enum.HumanoidRigType.R6) and "R6" or "R15",
				Signature = getAvatarSignature(properties, rigTypeEnum),
				Order = 1
			}
		end)
		if not ok or not data then return false end

		for _, existing in ipairs(copiedAvatars) do
			if existing.Signature == data.Signature then
				Status.Text = "Already saved!"
				task.delay(2, updateStatus)
				return false
			end
		end

		table.insert(copiedAvatars, 1, data)
		createAvatarCard(data, 1)
		filterSavedAvatarCards(SearchBox.Text)
		updateOrders()
		updateStatus()
		Status.Text = "Saved @" .. data.Name .. "!"
		task.delay(2, updateStatus)
		return true
	end

	local function copyProfileDescriptionForStorage(data, desc)
		if not data or not desc then return false end
		local properties = createCopiedProperties(desc, nil)
		local rigTypeEnum = getProfileRigType(data.UserId)
		local profileData = {
			Name = data.Name,
			UserId = data.UserId,
			DisplayName = data.DisplayName,
			Properties = properties,
			RigType = (rigTypeEnum == Enum.HumanoidRigType.R6) and "R6" or "R15",
			Signature = getAvatarSignature(properties, rigTypeEnum),
			Order = 1
		}
		for _, existing in ipairs(copiedAvatars) do
			if existing.Signature == profileData.Signature then
				Status.Text = "Already saved!"
				task.delay(2, updateStatus)
				return false
			end
		end
		table.insert(copiedAvatars, 1, profileData)
		createAvatarCard(profileData, 1)
		filterSavedAvatarCards(SearchBox.Text)
		updateOrders()
		updateStatus()
		Status.Text = "Saved @" .. profileData.Name .. "!"
		task.delay(2, updateStatus)
		return true
	end

	local function copyForStorage(targetPlayer)
		if copying or not targetPlayer or not targetPlayer.Character then return false end
		local humanoid = targetPlayer.Character:FindFirstChildOfClass("Humanoid")
		if not humanoid then return false end

		copying = true
		local ok, desc = pcall(function()
			return humanoid:GetAppliedDescription()
		end)

		if not ok or not desc then
			copying = false
			return false
		end

		if not hasCopyableMarketplaceAsset(desc) then
			copying = false
			return false
		end

		local copied = copyDescriptionForStorage(targetPlayer, desc)
		copying = false
		return copied
	end

	local function setSocialStatus(pageData, text)
		if pageData and pageData.Status then pageData.Status.Text = text end
	end

	local function hideSocialActions(pageData)
		if not pageData then return end
		for _, card in ipairs(pageData.Items) do
			if card and card.ActionPanel then
				card.ActionPanel.Visible = false
			end
		end
		pageData.ActiveCard = nil
	end

	local function copySocialUsername(cardData, button)
		if not cardData or not cardData.Username then return end
		local old = button.Text
		if safeSetClipboard("@" .. cardData.Username) then
			button.Text = "Copied Username!"
			button.TextColor3 = Color3.fromRGB(100, 220, 150)
			task.delay(1.2, function()
				if button and button.Parent then
					button.Text = old
					button.TextColor3 = Color3.fromRGB(150, 150, 165)
				end
			end)
		end
	end

	local function socialActionFeedback(button, text, color, restoreText, restoreColor, delayTime)
		button.Text = text
		button.BackgroundColor3 = color
		button.Active = false
		task.delay(delayTime or 1.2, function()
			if button and button.Parent then
				button.Text = restoreText
				button.BackgroundColor3 = restoreColor
				button.Active = true
			end
		end)
	end

	local function runWearAction(button, data, successText, resetText, resetColor)
		if not IS_CATALOG_GAME or not data then return end
		button.Active = false
		button.Text = "..."
		local ok = wearCopiedAvatar(data)
		if ok then
			button.Text = successText
			button.BackgroundColor3 = Color3.fromRGB(46, 125, 85)
		else
			button.Text = "FAIL"
			button.BackgroundColor3 = Color3.fromRGB(150, 55, 55)
		end
		task.delay(1.2, function()
			if button and button.Parent then
				button.Text = resetText
				button.BackgroundColor3 = resetColor
				button.Active = true
			end
		end)
	end

	local function copySocialProfile(cardData, profileButton, inspectOnly)
		if copying or not cardData or not cardData.UserId then return end
		copying = true
		local oldText = profileButton.Text
		local oldColor = profileButton.BackgroundColor3
		profileButton.Text = "..."
		profileButton.Active = false
		local ok, desc = pcall(function()
			return Players:GetHumanoidDescriptionFromUserIdAsync(cardData.UserId)
		end)
		if not scriptAlive then
			copying = false
			return
		end
		if ok and desc then
			if inspectOnly then
				local props = createCopiedProperties(desc, nil)
				local rigType = getProfileRigType(cardData.UserId)
				currentActiveData = {Name = cardData.Username, UserId = cardData.UserId, DisplayName = cardData.DisplayName, Properties = props, RigType = (rigType == Enum.HumanoidRigType.R6) and "R6" or "R15", Signature = getAvatarSignature(props, rigType), Order = 1, _InspectorSocialSave = true, _InspectorProfileState = true}
				copying = false
				ActionModal.Visible = false
				populateAssetInspector(currentActiveData)
				profileButton.Text = "VIEW\nPROFILE"
				profileButton.BackgroundColor3 = Color3.fromRGB(60, 110, 100)
				profileButton.Active = true
				return
			end
			local copied = copyProfileDescriptionForStorage({
				Name = cardData.Username,
				UserId = cardData.UserId,
				DisplayName = cardData.DisplayName
			}, desc)
			if copied then
				socialActionFeedback(profileButton, "SAVED!", Color3.fromRGB(46, 125, 85), oldText, oldColor, 0.9)
			else
				profileButton.Text = oldText
				profileButton.Active = true
			end
		else
			socialActionFeedback(profileButton, "FAILED", Color3.fromRGB(90, 60, 60), oldText, oldColor, 1.2)
		end
		copying = false
	end

	local function copySocialCurrent(cardData, currentButton, inspectOnly)
		if copying or not cardData then return end
		local player = Players:GetPlayerByUserId(tonumber(cardData.UserId) or 0)
		if not player or not player.Character then
			currentButton.Text = "NOT IN SERVER"
			currentButton.Active = false
			currentButton.BackgroundColor3 = Color3.fromRGB(70, 70, 80)
			task.delay(1.4, function()
				if currentButton and currentButton.Parent then
					currentButton.Text = "VIEW\nWEARING"
					currentButton.Active = true
					currentButton.BackgroundColor3 = Color3.fromRGB(60, 110, 100)
				end
			end)
			return
		end

		copying = true
		currentButton.Text = "CHECKING..."
		currentButton.Active = false
		local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
		local ok, desc = pcall(function()
			return humanoid and humanoid:GetAppliedDescription()
		end)
		if not scriptAlive then
			copying = false
			return
		end
		local copied = false
		if ok and desc then
			if inspectOnly then
				local props = createCopiedProperties(desc, player.Character)
				local rigType = humanoid and humanoid.RigType or getProfileRigType(cardData.UserId)
				currentActiveData = {Name = cardData.Username, UserId = cardData.UserId, DisplayName = cardData.DisplayName, Properties = props, RigType = (rigType == Enum.HumanoidRigType.R6) and "R6" or "R15", Signature = getAvatarSignature(props, rigType), Order = 1, _InspectorSocialSave = true, _InspectorProfileState = false}
				copying = false
				ActionModal.Visible = false
				populateAssetInspector(currentActiveData)
				currentButton.Text = "VIEW\nWEARING"
				currentButton.BackgroundColor3 = Color3.fromRGB(60, 110, 100)
				currentButton.Active = true
				return
			end
			if hasCopyableMarketplaceAsset(desc) then
				copied = copyDescriptionForStorage(player, desc)
			end
		end
		copying = false
		if copied then
			socialActionFeedback(currentButton, "SAVED!", Color3.fromRGB(46, 125, 85), "SAVE\nWEARING", Color3.fromRGB(55, 95, 175), 0.9)
		else
			socialActionFeedback(
				currentButton,
				"UNABLE",
				Color3.fromRGB(75, 75, 82),
				"VIEW\nWEARING",
				Color3.fromRGB(60, 110, 100),
				1.2
			)
		end
	end

	local function setSocialThumbnail(imageLabel, userId)
		local id = tonumber(userId)
		if not id then return end
		local cached = socialThumbnailCache[id]
		if cached then
			imageLabel.Image = cached
			return
		end
		task.spawn(function()
			local ok, content = pcall(function()
				local image = Players:GetUserThumbnailAsync(id, Enum.ThumbnailType.AvatarBust, Enum.ThumbnailSize.Size100x100)
				return image
			end)
			if not scriptAlive then return end
			if ok and content and content ~= "" then
				socialThumbnailCache[id] = content
				if imageLabel and imageLabel.Parent then imageLabel.Image = content end
			end
		end)
	end

	local function createSocialCard(pageData, item, index)
		local card = Instance.new("Frame")
		card.Name = "PlayerCard"
		card.LayoutOrder = index
		card.BackgroundColor3 = Color3.fromRGB(28, 28, 36)
		card.BorderSizePixel = 0
		card.ClipsDescendants = true
		card.Active = true
		card.ZIndex = 6
		card.Parent = pageData.Scroll

		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 6)
		corner.Parent = card

		local stroke = Instance.new("UIStroke")
		stroke.Color = Color3.fromRGB(40, 40, 50)
		stroke.Thickness = 1
		stroke.Parent = card

		local actionPanel = Instance.new("Frame")
		actionPanel.Name = "ActionPanel"
		actionPanel.Size = UDim2.new(1, -8, 0, 72)
		actionPanel.Position = UDim2.new(0, 4, 0, 4)
		actionPanel.BackgroundTransparency = 1
		actionPanel.BorderSizePixel = 0
		actionPanel.Visible = false
		actionPanel.ZIndex = 12
		actionPanel.Parent = card
		local profileButton = Instance.new("TextButton")
		profileButton.Size = UDim2.new(0.5, -5, 0, 30)
		profileButton.Position = UDim2.new(0, 3, 0, 39)
		profileButton.BackgroundColor3 = Color3.fromRGB(55, 95, 175)
		profileButton.Text = "SAVE\nPROFILE"
		profileButton.TextColor3 = Color3.fromRGB(255, 255, 255)
		profileButton.TextSize = isMobile and 6 or 7
		profileButton.TextWrapped = true
		profileButton.Font = Enum.Font.GothamBold
		profileButton.ZIndex = 13
		profileButton.Active = true
		profileButton.Parent = actionPanel
		local profileButtonCorner = Instance.new("UICorner")
		profileButtonCorner.CornerRadius = UDim.new(0, 6)
		profileButtonCorner.Parent = profileButton
		local viewProfileButton = Instance.new("TextButton")
		viewProfileButton.Size = UDim2.new(0.5, -5, 0, 30)
		viewProfileButton.Position = UDim2.new(0, 3, 0, 3)
		viewProfileButton.BackgroundColor3 = Color3.fromRGB(60, 110, 100)
		viewProfileButton.Text = "VIEW\nPROFILE"
		viewProfileButton.TextColor3 = Color3.fromRGB(255, 255, 255)
		viewProfileButton.TextSize = isMobile and 6 or 7
		viewProfileButton.TextWrapped = true
		viewProfileButton.Font = Enum.Font.GothamBold
		viewProfileButton.ZIndex = 13
		viewProfileButton.Active = true
		viewProfileButton.Parent = actionPanel
		local viewProfileButtonCorner = Instance.new("UICorner")
		viewProfileButtonCorner.CornerRadius = UDim.new(0, 6)
		viewProfileButtonCorner.Parent = viewProfileButton
		local currentButton = Instance.new("TextButton")
		currentButton.Size = UDim2.new(0.5, -5, 0, 30)
		currentButton.Position = UDim2.new(0.5, 2, 0, 39)
		currentButton.BackgroundColor3 = Color3.fromRGB(55, 95, 175)
		currentButton.Text = "SAVE\nWEARING"
		currentButton.TextColor3 = Color3.fromRGB(255, 255, 255)
		currentButton.TextSize = isMobile and 6 or 7
		currentButton.TextWrapped = true
		currentButton.Font = Enum.Font.GothamBold
		currentButton.ZIndex = 13
		currentButton.Active = true
		currentButton.Parent = actionPanel
		local currentButtonCorner = Instance.new("UICorner")
		currentButtonCorner.CornerRadius = UDim.new(0, 6)
		currentButtonCorner.Parent = currentButton
		local viewWearingButton = Instance.new("TextButton")
		viewWearingButton.Size = UDim2.new(0.5, -5, 0, 30)
		viewWearingButton.Position = UDim2.new(0.5, 2, 0, 3)
		viewWearingButton.BackgroundColor3 = Color3.fromRGB(60, 110, 100)
		viewWearingButton.Text = "VIEW\nWEARING"
		viewWearingButton.TextColor3 = Color3.fromRGB(255, 255, 255)
		viewWearingButton.TextSize = isMobile and 6 or 7
		viewWearingButton.TextWrapped = true
		viewWearingButton.Font = Enum.Font.GothamBold
		viewWearingButton.ZIndex = 13
		viewWearingButton.Active = true
		viewWearingButton.Parent = actionPanel
		local viewWearingButtonCorner = Instance.new("UICorner")
		viewWearingButtonCorner.CornerRadius = UDim.new(0, 6)
		viewWearingButtonCorner.Parent = viewWearingButton
		local preview = Instance.new("ImageLabel")
		preview.Name = "Thumbnail"
		preview.Size = UDim2.new(1, -8, 0, 72)
		preview.Position = UDim2.new(0, 4, 0, 4)
		preview.BackgroundColor3 = Color3.fromRGB(48, 48, 56)
		preview.BorderSizePixel = 0
		preview.ScaleType = Enum.ScaleType.Fit
		preview.Image = "rbxassetid://0"
		preview.ZIndex = 7
		preview.Parent = card
		local pc = Instance.new("UICorner")
		pc.CornerRadius = UDim.new(0, 4)
		pc.Parent = preview

		local displayName = Instance.new("TextLabel")
		displayName.Name = "DisplayName"
		displayName.Size = UDim2.new(1, -6, 0, 14)
		displayName.Position = UDim2.new(0, 3, 0, isMobile and 74 or 80)
		displayName.BackgroundTransparency = 1
		displayName.Text = tostring(item.DisplayName or item.Username or "Unknown")
		displayName.TextColor3 = Color3.fromRGB(230, 230, 240)
		displayName.TextSize = isMobile and 7 or 8
		displayName.Font = Enum.Font.GothamBold
		displayName.TextTruncate = Enum.TextTruncate.AtEnd
		displayName.TextXAlignment = Enum.TextXAlignment.Left
		displayName.ZIndex = 9
		displayName.Parent = card

		local username = Instance.new("TextButton")
		username.Name = "Username"
		username.Size = UDim2.new(1, -6, 0, 13)
		username.Position = UDim2.new(0, 3, 0, isMobile and 87 or 93)
		username.BackgroundTransparency = 1
		username.Text = "@" .. tostring(item.Username)
		username.TextColor3 = Color3.fromRGB(140, 140, 155)
		username.TextSize = isMobile and 6 or 7
		username.Font = Enum.Font.Gotham
		username.TextTruncate = Enum.TextTruncate.AtEnd
		username.TextXAlignment = Enum.TextXAlignment.Left
		username.ZIndex = 9
		username.Active = true
		username.Parent = card

		local cardData = {
			UserId = tonumber(item.UserId),
			Username = item.Username,
			DisplayName = item.DisplayName,
			Card = card,
			ActionPanel = actionPanel,
			CurrentButton = currentButton,
			ProfileButton = profileButton,
			ViewProfileButton = viewProfileButton,
			ViewWearingButton = viewWearingButton
		}
		table.insert(pageData.Items, cardData)

		setSocialThumbnail(preview, cardData.UserId)

		local function selectCard()
			markUIClick()
			if pageData.ActiveCard and pageData.ActiveCard ~= cardData then
				pageData.ActiveCard.ActionPanel.Visible = false
			end
			pageData.ActiveCard = cardData
			actionPanel.Visible = not actionPanel.Visible
		end

		preview.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then selectCard() end
		end)
		username.Activated:Connect(function()
			markUIClick()
			copySocialUsername(cardData, username)
		end)
		profileButton.Activated:Connect(function()
			markUIClick()
			copySocialProfile(cardData, profileButton)
		end)
		currentButton.Activated:Connect(function()
			markUIClick()
			copySocialCurrent(cardData, currentButton)
		end)
		viewProfileButton.Activated:Connect(function()
			markUIClick()
			copySocialProfile(cardData, viewProfileButton, true)
		end)
		viewWearingButton.Activated:Connect(function()
			markUIClick()
			copySocialCurrent(cardData, viewWearingButton, true)
		end)
	end

	local function clearSocialPage(pageData)
		for _, child in ipairs(pageData.Scroll:GetChildren()) do
			if child:IsA("Frame") then child:Destroy() end
		end
		table.clear(pageData.Items)
		pageData.ActiveCard = nil
	end

	local function filterSocialPage(pageData, query)
		local text = string.lower(tostring(query or ""))
		local visibleCount = 0
		for _, cardData in ipairs(pageData.Items) do
			local username = string.lower(tostring(cardData.Username or ""))
			local displayName = string.lower(tostring(cardData.DisplayName or ""))
			local matches = text == "" or string.find(username, text, 1, true) ~= nil or string.find(displayName, text, 1, true) ~= nil
			cardData.Card.Visible = matches
			if matches then visibleCount = visibleCount + 1 end
		end
		pageData.Empty.Visible = visibleCount == 0
		if visibleCount == 0 then
			pageData.Empty.Text = text == "" and "No entries found." or "No matching entries found."
		end
	end

	local function loadServerPlayers()
		local pageData = PlayersPage
		clearSocialPage(pageData)
		local players = Players:GetPlayers()
		table.sort(players, function(a, b) return string.lower(a.Name) < string.lower(b.Name) end)
		for i, player in ipairs(players) do
			createSocialCard(pageData, {UserId = player.UserId, Username = player.Name, DisplayName = player.DisplayName}, i)
		end
		pageData.Empty.Visible = (#players == 0)
		pageData.Empty.Text = "No players are currently in this server."
		setSocialStatus(pageData, tostring(#players) .. " player" .. (#players == 1 and "" or "s") .. " in server")
		filterSocialPage(pageData, pageData.SearchBox.Text)
	end

	local function loadFriendPage(pageData, firstLoad)
		if socialLoading.Friends then return end
		socialLoading.Friends = true
		if firstLoad then
			clearSocialPage(pageData)
			pageData.NextPage = nil
			pageData.Finished = true
			setSocialStatus(pageData, "Loading friends...")
		end
		local success, pages = pcall(function()
			if firstLoad or not pageData.NextPage then
				return Players:GetFriendsAsync(LocalPlayer.UserId)
			end
			return pageData.NextPage
		end)
		if not success or not pages then
			setSocialStatus(pageData, "Unable to load friends right now.")
			pageData.Empty.Visible = (#pageData.Items == 0)
			pageData.Empty.Text = "Roblox did not return the friends list."
			socialLoading.Friends = false
			return
		end
		if not scriptAlive then
			socialLoading.Friends = false
			return
		end

		local currentPageItems = pages:GetCurrentPage()
		local startIndex = #pageData.Items + 1
		for offset, friend in ipairs(currentPageItems) do
			createSocialCard(pageData, {
				UserId = friend.Id,
				Username = friend.Username,
				DisplayName = friend.DisplayName
			}, startIndex + offset - 1)
		end
		pageData.NextPage = pages
		pageData.Finished = pages.IsFinished
		pageData.Empty.Visible = (#pageData.Items == 0)
		pageData.Empty.Text = "No friends found."
		setSocialStatus(pageData, tostring(#pageData.Items) .. " friend" .. (#pageData.Items == 1 and "" or "s") .. (pageData.Finished and "" or " • scroll for more"))
		filterSocialPage(pageData, pageData.SearchBox.Text)
		socialLoading.Friends = false
	end

	local function setPage(name)
		currentPage = name
		ActionModal.Visible = false
		local saved = name == "Saved"
		ListContainer.Visible = saved
		SearchBox.Visible = saved
		SaveButton.Visible = saved
		CopySelfBtn.Visible = saved
		ClearButton.Visible = saved
		Status.Visible = saved
		PlayersPage.Frame.Visible = (name == "Players")
		PlayersPage.SearchBox.Visible = (name == "Players")
		FriendsPage.Frame.Visible = (name == "Friends")
		FriendsPage.SearchBox.Visible = (name == "Friends")
SavedNav.BackgroundColor3 = saved and Color3.fromRGB(0, 150, 255) or Color3.fromRGB(35, 35, 45)
PlayersNav.BackgroundColor3 = name == "Players" and Color3.fromRGB(0, 150, 255) or Color3.fromRGB(35, 35, 45)
FriendsNav.BackgroundColor3 = name == "Friends" and Color3.fromRGB(0, 150, 255) or Color3.fromRGB(35, 35, 45)
		SavedNav.TextColor3 = saved and Color3.fromRGB(255,255,255) or Color3.fromRGB(175,175,190)
		PlayersNav.TextColor3 = name == "Players" and Color3.fromRGB(255,255,255) or Color3.fromRGB(175,175,190)
		FriendsNav.TextColor3 = name == "Friends" and Color3.fromRGB(255,255,255) or Color3.fromRGB(175,175,190)
SavedNav.Outline.Color = saved and Color3.fromRGB(90, 205, 255) or Color3.fromRGB(58, 58, 72)
PlayersNav.Outline.Color = name == "Players" and Color3.fromRGB(90, 205, 255) or Color3.fromRGB(58, 58, 72)
FriendsNav.Outline.Color = name == "Friends" and Color3.fromRGB(90, 205, 255) or Color3.fromRGB(58, 58, 72)
		if name == "Players" then loadServerPlayers() end
		if name == "Friends" and #FriendsPage.Items == 0 then loadFriendPage(FriendsPage, true) end
	end

SavedNav.Activated:Connect(function() markUIClick(); setPage("Saved") end)
PlayersNav.Activated:Connect(function() markUIClick(); setPage("Players") end)
FriendsNav.Activated:Connect(function() markUIClick(); setPage("Friends") end)

wire(Players.PlayerAdded, function()
		if currentPage == "Players" then task.defer(loadServerPlayers) end
end)
wire(Players.PlayerRemoving, function()
		if currentPage == "Players" then task.defer(loadServerPlayers) end
end)
wire(PlayersPage.Scroll:GetPropertyChangedSignal("CanvasPosition"), function()
		hideSocialActions(PlayersPage)
end)
wire(FriendsPage.Scroll:GetPropertyChangedSignal("CanvasPosition"), function()
		hideSocialActions(FriendsPage)
		if currentPage == "Friends" and not FriendsPage.Finished and not socialLoading.Friends then
			local canvasY = FriendsPage.Scroll.CanvasPosition.Y
			local viewportY = FriendsPage.Scroll.AbsoluteSize.Y
			local canvasSizeY = FriendsPage.Scroll.AbsoluteCanvasSize.Y
			if canvasY + viewportY >= canvasSizeY - 80 then
				local ok = pcall(function()
					if not FriendsPage.NextPage.IsFinished then FriendsPage.NextPage:AdvanceToNextPageAsync() end
				end)
				if ok then task.defer(function() loadFriendPage(FriendsPage, false) end) end
			end
		end
end)

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
		setProfileThumbnail(SelectedProfileIcon, player.UserId)

		HoldButton.Text = "SAVE WEARING"
		HoldButton.BackgroundColor3 = Color3.fromRGB(55, 95, 175)
		HoldButton.Active = true

		CopyProfileButton.Text = "SAVE\nPROFILE"
		CopyProfileButton.BackgroundColor3 = Color3.fromRGB(60, 110, 100)
		CopyProfileButton.Active = true

		SelectFrame.Visible = true
	end

	local function handlePlayerClick(inputPosition)
		if not Mouse then return end
if not worldPlayerPopupEnabled then return end
		if os.clock() - lastUIClickTime < 0.25 then return end
		if ActionModal.Visible then return end
		if inputPosition and isInputOverUI(inputPosition) then return end

		local player = getPlayerFromTarget(Mouse.Target)
		if player then
			if InspectorModal.Visible then
				inspectorOpen = false
				InspectorModal.Visible = false
			end
			selectPlayer(player)
		else
			if SelectFrame.Visible then
				hideSelectFrame()
			end
		end
	end

wire(UserInputService.TouchStarted, function(touch, gameProcessed)
		if gameProcessed then return end
		touchStartPos = Vector2.new(touch.Position.X, touch.Position.Y)
		touchStartTime = os.clock()
end)

wire(UserInputService.TouchEnded, function(touch, gameProcessed)
		if gameProcessed then return end
		local endPos = Vector2.new(touch.Position.X, touch.Position.Y)
		local dist = (endPos - touchStartPos).Magnitude
		local duration = os.clock() - touchStartTime

		if dist <= MAX_TAP_DISTANCE and duration <= MAX_TAP_DURATION then
			handlePlayerClick(endPos)
		end
end)

wire(UserInputService.InputBegan, function(input, gameProcessed)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			if pointInsideGui(TitleBar, input.Position)
				and not pointInsideGui(Minimize, input.Position)
				and not pointInsideGui(WatermarkEmojiButton, input.Position) then
				dragging = true
				dragStart = input.Position
				startPosition = Main.Position
			end
		end

		if gameProcessed then return end
		if input.UserInputType == Enum.UserInputType.MouseButton1 and not UserInputService.TouchEnabled then
			handlePlayerClick(input.Position)
		end
end)

HoldButton.Activated:Connect(function()
		markUIClick()
		if not selectedPlayer or copying or not HoldButton.Active then return end
		HoldButton.Text = "SAVING..."
		HoldButton.BackgroundColor3 = Color3.fromRGB(70, 70, 80)
		HoldButton.Active = false

		local player = selectedPlayer
		local copied = copyForStorage(player)

		if copied then
			HoldButton.Text = "SAVE SUCCESSFUL!"
			HoldButton.BackgroundColor3 = Color3.fromRGB(46, 125, 85)
			task.delay(0.35, hideSelectFrame)
		else
			if selectedPlayer == player and SelectFrame.Visible then
				HoldButton.Text = "UNABLE TO SAVE"
				HoldButton.BackgroundColor3 = Color3.fromRGB(75, 75, 82)
				HoldButton.Active = false
			end
		end
	end)

CopyProfileButton.Activated:Connect(function()
		markUIClick()
		if not selectedPlayer or copying then return end
		local player = selectedPlayer
		CopyProfileButton.Text = "..."
		CopyProfileButton.Active = false
		local ok, desc = pcall(function()
			return Players:GetHumanoidDescriptionFromUserIdAsync(player.UserId)
		end)
		if ok and desc then
			local copied = copyProfileDescriptionForStorage({
				Name = player.Name,
				UserId = player.UserId,
				DisplayName = player.DisplayName
			}, desc)
			if copied then
				CopyProfileButton.Text = "SAVED!"
				CopyProfileButton.BackgroundColor3 = Color3.fromRGB(46, 125, 85)
				if selectedPlayer == player and SelectFrame.Visible then task.delay(0.35, hideSelectFrame) end
			else
				CopyProfileButton.Text = "SAVE\nPROFILE"
				CopyProfileButton.Active = true
			end
		else
			CopyProfileButton.Text = "SAVE\nPROFILE"
			CopyProfileButton.Active = true
		end
	end)

SelectCancel.Activated:Connect(hideSelectFrame)

SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
		filterSavedAvatarCards(SearchBox.Text)
	end)

PlayersPage.SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
		filterSocialPage(PlayersPage, PlayersPage.SearchBox.Text)
	end)

FriendsPage.SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
		filterSocialPage(FriendsPage, FriendsPage.SearchBox.Text)
	end)

CopySelfBtn.Activated:Connect(function()
		markUIClick()
		copyForStorage(LocalPlayer)
	end)

	if IS_CATALOG_GAME then
SaveButton.Activated:Connect(function()
			markUIClick()
			ConfirmText.Text = "Save Your Current Avatar in CAC?"
			currentConfirmAction = saveCurrentOutfit

			ConfirmOverlay.Visible = true
			ConfirmFrame.Visible = true
		end)
	end

ModalClose.Activated:Connect(function()
		markUIClick()
		ActionModal.Visible = false
		currentActiveData = nil
	end)

ModalWear.Activated:Connect(function()
		markUIClick()
		if not IS_CATALOG_GAME or not currentActiveData then return end
		local data = currentActiveData
		runWearAction(
			ModalWear,
			data,
			"SUCCESS",
			"WEAR AVATAR",
			Color3.fromRGB(55, 95, 175)
		)
		task.delay(1.2, function()
			if ModalWear.Parent then
				ActionModal.Visible = false
			end
		end)
	end)

ModalInspect.Activated:Connect(function()
		markUIClick()
		if currentActiveData then
			LeftPane:FindFirstChild("InspectorSaveAvatarButton").Visible = false
			ActionModal.Visible = false
			populateAssetInspector(currentActiveData)
		end
	end)

ModalDelete.Activated:Connect(function()
		markUIClick()
		if currentActiveData then
			local dataToDelete = currentActiveData
			ActionModal.Visible = false
			ConfirmText.Text = "Delete @" .. dataToDelete.Name .. "?"
			currentConfirmAction = function() deleteAvatarEntry(dataToDelete) end

			ConfirmOverlay.Visible = true
			ConfirmFrame.Visible = true
		end
	end)

InspectBack.Activated:Connect(function()
		markUIClick()
		if currentActiveData and currentActiveData._InspectorPreviousData then
			currentActiveData = currentActiveData._InspectorPreviousData
			populateAssetInspector(currentActiveData)
			InspectorModal.Visible = true
			return
		end
		inspectorOpen = false
		LeftPane:FindFirstChild("InspectorSaveAvatarButton").Visible = false
		InspectorModal.Visible = false
		Sidebar.Visible = true
		setPage(currentPage)
	end)


LeftPane:FindFirstChild("InspectorSaveAvatarButton").Activated:Connect(function()
		markUIClick()
		local button = LeftPane:FindFirstChild("InspectorSaveAvatarButton")
		if not button or not button.Visible or not currentActiveData or not currentActiveData.Properties then return end
		button.Active = false
		button.Text = "..."
		local saved = false
		local duplicate = false
		local data = currentActiveData
		for _, existing in ipairs(copiedAvatars) do
			if existing.Signature == data.Signature then
				duplicate = true
				break
			end
		end
		if duplicate then
			button.Text = "ALREADY SAVED"
			button.BackgroundColor3 = Color3.fromRGB(90, 90, 100)
		else
			local savedData = {
				Name = data.Name,
				UserId = data.UserId,
				DisplayName = data.DisplayName,
				Properties = data.Properties,
				RigType = data.RigType,
				Signature = data.Signature,
				Order = 1
			}
			local ok = pcall(function()
				table.insert(copiedAvatars, 1, savedData)
				createAvatarCard(savedData, 1)
				filterSavedAvatarCards(SearchBox.Text)
				updateOrders()
				updateStatus()
			end)
			saved = ok
			if saved then
				button.Text = "SAVED!"
				button.BackgroundColor3 = Color3.fromRGB(46, 125, 85)
			else
				button.Text = "FAIL"
				button.BackgroundColor3 = Color3.fromRGB(150, 55, 55)
			end
		end
		task.delay(1.2, function()
			if button and button.Parent then
				button.Text = "SAVE AVATAR"
				button.BackgroundColor3 = Color3.fromRGB(46, 125, 85)
				button.Active = true
			end
		end)
	end)

InspectorWearButton.Activated:Connect(function()
		markUIClick()
		if not IS_CATALOG_GAME or not currentActiveData then return end
		local data = currentActiveData
		runWearAction(
			InspectorWearButton,
			data,
			"DONE!",
			"WEAR",
			Color3.fromRGB(55, 95, 175)
		)
	end)

InspectorProfileCopy.Activated:Connect(function()
		markUIClick()
		if not currentActiveData or currentActiveData._InspectorProfileState or copying then return end
		InspectorProfileCopy.Text = "..."
		InspectorProfileCopy.Active = false
		local data = currentActiveData
		local ok, desc = pcall(function()
			return Players:GetHumanoidDescriptionFromUserIdAsync(data.UserId)
		end)
		if ok and desc then
			local props = createCopiedProperties(desc, nil)
			local rigType = getProfileRigType(data.UserId)
			currentActiveData = {Name = data.Name, UserId = data.UserId, DisplayName = data.DisplayName, Properties = props, RigType = (rigType == Enum.HumanoidRigType.R6) and "R6" or "R15", Signature = getAvatarSignature(props, rigType), Order = 1, _InspectorPreviousData = data, _InspectorSocialSave = true, _InspectorProfileState = true}
			populateAssetInspector(currentActiveData)
		else
			InspectorProfileCopy.Text = "VIEW\nPROFILE"
			InspectorProfileCopy.BackgroundColor3 = Color3.fromRGB(60, 110, 100)
			InspectorProfileCopy.Active = true
		end
	end)

ClearButton.Activated:Connect(function()
		markUIClick()
		if #copiedAvatars == 0 then
			Status.Text = "Nothing to clear!"
			task.delay(2, updateStatus)
			return
		end

		ConfirmText.Text = "WARNING!!! Clear ALL Saved Avatars?"
		currentConfirmAction = clearCopiedFits

		ConfirmOverlay.Visible = true
		ConfirmFrame.Visible = true
	end)

UnloadButton.Activated:Connect(function()
		markUIClick()
		ConfirmText.Text = "Destroy UI and unload?"
		currentConfirmAction = destroyScriptAndUI

		ConfirmOverlay.Visible = true
		ConfirmFrame.Visible = true
	end)

CancelButton.Activated:Connect(function()
		markUIClick()
		ConfirmFrame.Visible = false
		ConfirmOverlay.Visible = false
		currentConfirmAction = nil
		updateStatus()
	end)

ConfirmAction.Activated:Connect(function()
		markUIClick()
		ConfirmFrame.Visible = false
		ConfirmOverlay.Visible = false

		if currentConfirmAction then
			local action = currentConfirmAction
			currentConfirmAction = nil
			action()
		end
	end)

Minimize.Activated:Connect(function()
		markUIClick()
		minimized = not minimized
		if minimized then
			hideSelectFrame()
			applyTween(Main, {Size = UDim2.new(0, 180, 0, 34)})

			SaveButton.Visible = false
			CopySelfBtn.Visible = false
			ClearButton.Visible = false
			UnloadButton.Visible = false
			Status.Visible = false
			SearchBox.Visible = false
			ListContainer.Visible = false
			ConfirmFrame.Visible = false
			ConfirmOverlay.Visible = false
			ActionModal.Visible = false
			InspectorModal.Visible = false
			Sidebar.Visible = false
			PlayersPage.Frame.Visible = false
			FriendsPage.Frame.Visible = false
			Minimize.Text = "+"
		else
			applyTween(Main, {Size = UDim2.new(0, mainWidth, 0, mainHeight)})
			SaveButton.Visible = true
			CopySelfBtn.Visible = true
			ClearButton.Visible = true
			UnloadButton.Visible = true
			Status.Visible = true
			SearchBox.Visible = true
			ListContainer.Visible = true
			Sidebar.Visible = true
			setPage(currentPage)
			if inspectorOpen then
				Sidebar.Visible = false
				ListContainer.Visible = false
				SearchBox.Visible = false
				SaveButton.Visible = false
				CopySelfBtn.Visible = false
				ClearButton.Visible = false
				Status.Visible = false
				PlayersPage.Frame.Visible = false
				FriendsPage.Frame.Visible = false
				InspectorModal.Visible = true
			else
				InspectorModal.Visible = false
			end
			ConfirmOverlay.Visible = currentConfirmAction ~= nil
			ConfirmFrame.Visible = currentConfirmAction ~= nil
			Minimize.Text = "-"
			updateStatus()
		end
	end)

if not scriptAlive then return end
loadFromWorkspace()
updateStatus()
setPage("Saved")
end)

if not success then
emergencyCleanup()
warn("[Avatar Saver V2] Initialization failed: " .. tostring(err))
end
