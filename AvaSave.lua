-- [[ Made by Knightingale | ScriptBlox.com ]] --
-- Official script V2.10

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
	local State = {}
	local function getService(name)
			local ok, service = pcall(function()
				local s = game:GetService(name)
				return (type(cloneref) == "function") and cloneref(s) or s
			end)
			return ok and service or game:GetService(name)
		end

		State.Players = getService("Players")
		State.ReplicatedStorage = getService("ReplicatedStorage")
		State.HttpService = getService("HttpService")
		State.MarketplaceService = getService("MarketplaceService")
		State.UserInputService = getService("UserInputService")
		State.TweenService = getService("TweenService")
		State.Workspace = getService("Workspace")
		State.CoreGui = getService("CoreGui")

		State.LocalPlayer = State.Players.LocalPlayer or State.Players:GetPropertyChangedSignal("LocalPlayer"):Wait() or State.Players.LocalPlayer
		State.Mouse = State.LocalPlayer:GetMouse()

		State.catalogEvents = State.ReplicatedStorage:FindFirstChild("Events")
		State.catalogGuiRemote = State.catalogEvents and State.catalogEvents:FindFirstChild("CatalogGuiRemote")
		State.savedOutfitsRemote = State.catalogEvents and State.catalogEvents:FindFirstChild("SavedOutfitsRemote")
		State.IS_CATALOG_GAME = (State.catalogGuiRemote ~= nil and State.savedOutfitsRemote ~= nil)

		State.SCREEN_GUI_NAME = "AvatarSaverV2_UI"
		State.ScreenGui = Instance.new("ScreenGui")
		State.ScreenGui.Name = State.SCREEN_GUI_NAME
		State.ScreenGui.ResetOnSpawn = false
		State.ScreenGui.IgnoreGuiInset = true

		State.parented = false
		if type(gethui) == "function" then
			pcall(function()
				local existing = gethui():FindFirstChild(State.SCREEN_GUI_NAME)
				if existing then existing:Destroy() end
				State.ScreenGui.Parent = gethui()
				State.parented = true
			end)
		end

		if not State.parented and syn and type(syn.protect_gui) == "function" then
			pcall(function()
				syn.protect_gui(State.ScreenGui)
				local existing = State.CoreGui:FindFirstChild(State.SCREEN_GUI_NAME)
				if existing then existing:Destroy() end
				State.ScreenGui.Parent = State.CoreGui
				State.parented = true
			end)
		end

		if not State.parented then
			pcall(function()
				local existing = State.CoreGui:FindFirstChild(State.SCREEN_GUI_NAME)
				if existing then existing:Destroy() end
				State.ScreenGui.Parent = State.CoreGui
				State.parented = true
			end)
		end

		if not State.parented then
			local playerGui = State.LocalPlayer:WaitForChild("PlayerGui", 5)
			if playerGui then
				local existing = playerGui:FindFirstChild(State.SCREEN_GUI_NAME)
				if existing then existing:Destroy() end
				State.ScreenGui.Parent = playerGui
			end
		end

		State.FOLDER_NAME = "Avatar Saver v2"
		State.FILE_PATH = State.FOLDER_NAME .. "/SavedAvatars.json"

		if type(makefolder) == "function" and type(isfolder) == "function" then
			pcall(function()
				if not isfolder(State.FOLDER_NAME) then makefolder(State.FOLDER_NAME) end
			end)
		end

		State.viewportSize = State.Workspace.CurrentCamera and State.Workspace.CurrentCamera.ViewportSize or Vector2.new(1024, 768)
		State.isMobile = (State.viewportSize.X < 700 or State.viewportSize.Y < 500)
	State.mainWidth = State.isMobile and 310 or 360
	State.mainHeight = State.isMobile and 280 or 320

		State.copiedAvatars = {}
		State.dragging = false
		State.dragStart, State.startPosition = nil, nil
		State.minimized = false
		State.inspectorOpen = false
		State.copying = false
		State.selectedPlayer = nil
	local function wire(signal, callback)
	local connection = signal:Connect(callback)
	runtimeConnections[#runtimeConnections + 1] = connection
	return connection
	end
		State.currentActiveData = nil
		State.currentConfirmAction = nil
		State.currentPage = "Saved"
		State.socialPages = {}
		State.socialThumbnailCache = {}
		State.socialLoading = {}
	State.worldPlayerPopupEnabled = true

		State.lastUIClickTime = 0
		State.touchStartPos = Vector2.zero
		State.touchStartTime = 0
		State.MAX_TAP_DISTANCE = 12
		State.MAX_TAP_DURATION = 0.35

		local function markUIClick()
			State.lastUIClickTime = os.clock()
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

		State.profileRigCache = {}

		local function getProfileRigType(userId)
			if not userId then return Enum.HumanoidRigType.R15 end
			if State.profileRigCache[userId] then return State.profileRigCache[userId] end

			local rigType = Enum.HumanoidRigType.R15
			pcall(function()
				local info = State.Players:GetCharacterAppearanceInfoAsync(userId)
				if info and tostring(info.playerAvatarType):upper() == "R6" then
					rigType = Enum.HumanoidRigType.R6
				else
					rigType = Enum.HumanoidRigType.R15
				end
			end)

			State.profileRigCache[userId] = rigType
			return rigType
		end

		local function isInputOverUI(inputPosition)
			if not inputPosition then return false end
			local x, y = inputPosition.X, inputPosition.Y

			local targetGuis = {}
			pcall(function() if type(gethui) == "function" then table.insert(targetGuis, gethui()) end end)
			pcall(function() table.insert(targetGuis, State.CoreGui) end)
			pcall(function()
				if State.LocalPlayer and State.LocalPlayer:FindFirstChild("PlayerGui") then
					table.insert(targetGuis, State.LocalPlayer.PlayerGui)
				end
			end)

			for _, root in ipairs(targetGuis) do
				local objects = {}
				pcall(function()
					objects = root:GetGuiObjectsAtPosition(x, y)
				end)
				for _, obj in ipairs(objects) do
					if obj:IsDescendantOf(State.ScreenGui) then
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
						local decoded = type(rawRef) == "string" and State.HttpService:JSONDecode(rawRef) or rawRef
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

	State.renderQueue = {}
	State.isProcessingQueue = false

		local function processRenderQueue()
			if State.isProcessingQueue then return end
			State.isProcessingQueue = true

	while #State.renderQueue > 0 do
				if not scriptAlive then break end
	local taskData = table.remove(State.renderQueue, 1)
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
						if type(State.Players.CreateHumanoidModelFromDescriptionAsync) == "function" then
							return State.Players:CreateHumanoidModelFromDescriptionAsync(desc, rigTypeEnum)
						end
						return State.Players:CreateHumanoidModelFromDescription(desc, rigTypeEnum)
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

	State.isProcessingQueue = false
		end

		local function renderSavedAvatarPreview(parentContainer, data, isFullBody)
			if not scriptAlive then return end
			table.insert(State.renderQueue, {
				Container = parentContainer,
				Data = data,
				IsFullBody = isFullBody
			})
	task.spawn(processRenderQueue)
		end

		local function getAvatarSignature(properties, rigType)
			local ok, result = pcall(function()
				return State.HttpService:JSONEncode({
					Properties = properties,
					RigType = tostring(rigType)
				})
			end)
			return ok and result or tostring(properties)
		end

		local function applyTween(instance, properties, duration)
			local tweenInfo = TweenInfo.new(duration or 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
			local tween = State.TweenService:Create(instance, tweenInfo, properties)
			tween:Play()
			return tween
		end

		local function saveToWorkspace()
			if type(writefile) ~= "function" then return end

			local exportData = {}
			for index, data in ipairs(State.copiedAvatars) do
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
				writefile(State.FILE_PATH, State.HttpService:JSONEncode(exportData))
			end)
		end

		State.Main = Instance.new("Frame")
		State.Main.Name = "Main"
		State.Main.Size = UDim2.new(0, State.mainWidth, 0, State.mainHeight)
		State.Main.Position = UDim2.new(0.5, -State.mainWidth/2, 0.5, -State.mainHeight/2)
		State.Main.BackgroundColor3 = Color3.fromRGB(20, 20, 26)
		State.Main.BorderSizePixel = 0
		State.Main.ClipsDescendants = true
		State.Main.Active = true
		State.Main.Parent = State.ScreenGui

		State.MainCorner = Instance.new("UICorner")
		State.MainCorner.CornerRadius = UDim.new(0, 8)
		State.MainCorner.Parent = State.Main

		State.MainStroke = Instance.new("UIStroke")
		State.MainStroke.Color = Color3.fromRGB(45, 45, 55)
		State.MainStroke.Thickness = 1
		State.MainStroke.Parent = State.Main

		State.TitleBar = Instance.new("Frame")
		State.TitleBar.Name = "TitleBar"
		State.TitleBar.Size = UDim2.new(1, 0, 0, 34)
		State.TitleBar.BackgroundColor3 = Color3.fromRGB(28, 28, 36)
		State.TitleBar.BorderSizePixel = 0
		State.TitleBar.ZIndex = 10
		State.TitleBar.Active = true
		State.TitleBar.Parent = State.Main

		State.TitleBarCorner = Instance.new("UICorner")
		State.TitleBarCorner.CornerRadius = UDim.new(0, 8)
		State.TitleBarCorner.Parent = State.TitleBar

		State.Title = Instance.new("TextLabel")
		State.Title.Size = UDim2.new(0, State.isMobile and 94 or 112, 1, 0)
		State.Title.Position = UDim2.new(0, 12, 0, 0)
		State.Title.BackgroundTransparency = 1
		State.Title.Text = "Avatar Saver V2"
		State.Title.TextColor3 = Color3.fromRGB(235, 235, 245)
		State.Title.TextSize = State.isMobile and 10 or 12
		State.Title.Font = Enum.Font.GothamBold
		State.Title.TextXAlignment = Enum.TextXAlignment.Left
		State.Title.TextTruncate = Enum.TextTruncate.AtEnd
		State.Title.ZIndex = 11
		State.Title.Parent = State.TitleBar

		State.Watermark = Instance.new("TextLabel")
		State.Watermark.Name = "Watermark"
	State.Watermark.Size = UDim2.new(1, (State.isMobile and -172 or -190), 1, 0)
	State.Watermark.Position = UDim2.new(0, State.isMobile and 140 or 158, 0, 0)
		State.Watermark.BackgroundTransparency = 1
		State.Watermark.Text = "| Made by Knightingale\n| More on ScriptBlox.com"
		State.Watermark.TextColor3 = Color3.fromRGB(120, 120, 135)
	State.Watermark.TextSize = State.isMobile and 7 or 8
		State.Watermark.Font = Enum.Font.GothamMedium
		State.Watermark.TextXAlignment = Enum.TextXAlignment.Left
		State.Watermark.TextYAlignment = Enum.TextYAlignment.Center
		State.Watermark.TextTruncate = Enum.TextTruncate.AtEnd
		State.Watermark.ZIndex = 11
		State.Watermark.Parent = State.TitleBar

	State.WatermarkEmojiButton = Instance.new("TextButton")
	State.WatermarkEmojiButton.Name = "WatermarkEmojiButton"
	State.WatermarkEmojiButton.Size = UDim2.new(0, 26, 0, 26)
	State.WatermarkEmojiButton.Position = UDim2.new(0, State.isMobile and 110 or 128, 0, 4)
	State.WatermarkEmojiButton.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
	State.WatermarkEmojiButton.TextColor3 = Color3.fromRGB(235, 235, 245)
	State.WatermarkEmojiButton.TextSize = State.isMobile and 18 or 20
	State.WatermarkEmojiButton.Font = Enum.Font.Gotham
	State.WatermarkEmojiButton.AutoButtonColor = false
	State.WatermarkEmojiButton.ZIndex = 11
	State.WatermarkEmojiButton.Active = true
	State.WatermarkEmojiButton.Parent = State.TitleBar

	State.WatermarkEmojiCorner = Instance.new("UICorner")
	State.WatermarkEmojiCorner.CornerRadius = UDim.new(0, 5)
	State.WatermarkEmojiCorner.Parent = State.WatermarkEmojiButton

	State.watermarkEmojis = {
	utf8.char(0x1F5E1, 0xFE0F),
	utf8.char(0x2694, 0xFE0F),
	utf8.char(0x1F6E1, 0xFE0F)
	}
	State.watermarkEmojiIndex = 1
	State.WatermarkEmojiButton.Text = State.watermarkEmojis[State.watermarkEmojiIndex]

	State.WatermarkEmojiButton.Activated:Connect(function()
	markUIClick()
	State.watermarkEmojiIndex = (State.watermarkEmojiIndex % #State.watermarkEmojis) + 1
	State.WatermarkEmojiButton.Text = State.watermarkEmojis[State.watermarkEmojiIndex]
	end)

		State.Minimize = Instance.new("TextButton")
		State.Minimize.Size = UDim2.new(0, 22, 0, 22)
		State.Minimize.Position = UDim2.new(1, -28, 0, 6)
		State.Minimize.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
		State.Minimize.Text = "-"
		State.Minimize.TextColor3 = Color3.fromRGB(200, 200, 210)
		State.Minimize.TextSize = 13
		State.Minimize.Font = Enum.Font.GothamBold
		State.Minimize.ZIndex = 11
		State.Minimize.Active = true
		State.Minimize.Parent = State.TitleBar

		State.MinCorner = Instance.new("UICorner")
		State.MinCorner.CornerRadius = UDim.new(0, 4)
		State.MinCorner.Parent = State.Minimize

		State.ContentX = (State.isMobile and 46 or 50) + 16
		State.ContentWidth = -(State.ContentX + 8)

		State.ActionOffsetY = 38

		State.SaveButton = Instance.new("TextButton")
		State.SaveButton.Size = UDim2.new(0, math.floor((State.mainWidth - State.ContentX - 16) / 3), 0, 24)
		State.SaveButton.Position = UDim2.new(0, State.ContentX, 0, State.ActionOffsetY)
		State.SaveButton.BackgroundColor3 = State.IS_CATALOG_GAME and Color3.fromRGB(46, 125, 85) or Color3.fromRGB(55, 55, 65)
		State.SaveButton.Text = "SAVE CURRENT\nAVATAR TO CAC"
		State.SaveButton.TextColor3 = State.IS_CATALOG_GAME and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(130, 130, 140)
		State.SaveButton.TextSize = 7
		State.SaveButton.TextWrapped = true
		State.SaveButton.Font = Enum.Font.GothamBold
		State.SaveButton.Active = true
		State.SaveButton.Parent = State.Main

		State.SaveCorner = Instance.new("UICorner")
		State.SaveCorner.CornerRadius = UDim.new(0, 6)
		State.SaveCorner.Parent = State.SaveButton

		State.CopySelfBtn = Instance.new("TextButton")
		State.CopySelfBtn.Size = UDim2.new(0, math.floor((State.mainWidth - State.ContentX - 16) / 3), 0, 24)
		State.CopySelfBtn.Position = UDim2.new(0, State.ContentX + math.floor((State.mainWidth - State.ContentX - 16) / 3) + 4, 0, State.ActionOffsetY)
		State.CopySelfBtn.BackgroundColor3 = Color3.fromRGB(55, 95, 175)
		State.CopySelfBtn.Text = "SAVE SELF"
		State.CopySelfBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
		State.CopySelfBtn.TextSize = 8
		State.CopySelfBtn.Font = Enum.Font.GothamBold
		State.CopySelfBtn.Active = true
		State.CopySelfBtn.Parent = State.Main

		State.CopySelfCorner = Instance.new("UICorner")
		State.CopySelfCorner.CornerRadius = UDim.new(0, 6)
		State.CopySelfCorner.Parent = State.CopySelfBtn

		State.ClearButton = Instance.new("TextButton")
		State.ClearButton.Size = UDim2.new(0, math.floor((State.mainWidth - State.ContentX - 16) / 3), 0, 24)
		State.ClearButton.Position = UDim2.new(0, State.ContentX + 2 * (math.floor((State.mainWidth - State.ContentX - 16) / 3) + 4), 0, State.ActionOffsetY)
		State.ClearButton.BackgroundColor3 = Color3.fromRGB(135, 80, 50)
		State.ClearButton.Text = "CLEAR ALL"
		State.ClearButton.TextColor3 = Color3.fromRGB(255, 255, 255)
		State.ClearButton.TextSize = 8
		State.ClearButton.Font = Enum.Font.GothamBold
		State.ClearButton.Active = true
		State.ClearButton.Parent = State.Main

		State.ClearCorner = Instance.new("UICorner")
		State.ClearCorner.CornerRadius = UDim.new(0, 6)
		State.ClearCorner.Parent = State.ClearButton

		State.UnloadButton = Instance.new("TextButton")
		State.UnloadButton.Size = UDim2.new(0, math.floor((State.mainWidth - State.ContentX - 8) * 0.24 - 4), 0, 24)
		State.UnloadButton.Position = UDim2.new(0, State.ContentX + 0.72 * (State.mainWidth - State.ContentX - 8) + 2, 0, State.ActionOffsetY)
		State.UnloadButton.BackgroundColor3 = Color3.fromRGB(135, 50, 50)
		State.UnloadButton.Text = "DESTROY UI"
		State.UnloadButton.TextColor3 = Color3.fromRGB(255, 255, 255)
		State.UnloadButton.TextSize = 8
		State.UnloadButton.Font = Enum.Font.GothamBold
		State.UnloadButton.Active = true
		State.UnloadButton.Parent = State.Main

		State.UnloadCorner = Instance.new("UICorner")
		State.UnloadCorner.CornerRadius = UDim.new(0, 6)
		State.UnloadCorner.Parent = State.UnloadButton

		State.Status = Instance.new("TextLabel")
		State.Status.Size = UDim2.new(1, State.ContentWidth, 0, 14)
		State.Status.Position = UDim2.new(0, State.ContentX, 0, State.ActionOffsetY + 27)
		State.Status.BackgroundTransparency = 1
		State.Status.Text = "Saved Avatars: 0"
		State.Status.TextColor3 = Color3.fromRGB(150, 150, 165)
		State.Status.TextSize = 9
		State.Status.Font = Enum.Font.Gotham
		State.Status.TextXAlignment = Enum.TextXAlignment.Left
		State.Status.Parent = State.Main

		State.SearchBox = Instance.new("TextBox")
		State.SearchBox.Name = "SavedAvatarSearch"
		State.SearchBox.Size = UDim2.new(0, State.isMobile and 104 or 132, 0, 18)
		State.SearchBox.Position = UDim2.new(1, -(State.isMobile and 104 or 132) - 8, 0, State.ActionOffsetY + 25)
		State.SearchBox.BackgroundColor3 = Color3.fromRGB(72, 72, 82)
		State.SearchBox.BorderSizePixel = 0
		State.SearchBox.PlaceholderText = "Search Avatar"
		State.SearchBox.PlaceholderColor3 = Color3.fromRGB(195, 195, 205)
		State.SearchBox.Text = ""
		State.SearchBox.TextColor3 = Color3.fromRGB(255, 255, 255)
		State.SearchBox.TextSize = 7
		State.SearchBox.Font = Enum.Font.GothamBold
		State.SearchBox.ClearTextOnFocus = false
		State.SearchBox.TextXAlignment = Enum.TextXAlignment.Left
		State.SearchBox.ZIndex = 6
		State.SearchBox.Active = true
		State.SearchBox.Parent = State.Main

		State.SearchCorner = Instance.new("UICorner")
		State.SearchCorner.CornerRadius = UDim.new(1, 0)
		State.SearchCorner.Parent = State.SearchBox

		State.ContainerOffsetY = State.ActionOffsetY + 43

		State.ListContainer = Instance.new("Frame")
		State.ListContainer.Size = UDim2.new(1, State.ContentWidth, 1, -(State.ContainerOffsetY + 8))
		State.ListContainer.Position = UDim2.new(0, State.ContentX, 0, State.ContainerOffsetY)
		State.ListContainer.BackgroundTransparency = 1
		State.ListContainer.ClipsDescendants = true
		State.ListContainer.Active = true
		State.ListContainer.Parent = State.Main

		State.List = Instance.new("ScrollingFrame")
		State.List.Size = UDim2.new(1, 0, 1, 0)
		State.List.BackgroundTransparency = 1
		State.List.BorderSizePixel = 0
		State.List.ScrollBarThickness = 2
		State.List.ScrollBarImageColor3 = Color3.fromRGB(60, 60, 75)
		State.List.CanvasSize = UDim2.new(0, 0, 0, 0)
		State.List.AutomaticCanvasSize = Enum.AutomaticSize.Y
		State.List.Active = true
		State.List.Parent = State.ListContainer

		State.Grid = Instance.new("UIGridLayout")
		State.cardCellWidth = UDim2.new(0.31, 0, 0, State.isMobile and 118 or 122)
		State.Grid.CellSize = UDim2.new(0.31, 0, 0, State.isMobile and 108 or 112)
		State.Grid.CellPadding = UDim2.new(0, State.isMobile and 5 or 6, 0, 7)
		State.Grid.SortOrder = Enum.SortOrder.LayoutOrder
		State.Grid.Parent = State.List

		State.EmptyMessage = Instance.new("TextLabel")
		State.EmptyMessage.Size = UDim2.new(1, 0, 0, 40)
		State.EmptyMessage.Position = UDim2.new(0, 0, 0, 20)
		State.EmptyMessage.BackgroundTransparency = 1
		State.EmptyMessage.Text = "Click any player or use SAVE SELF to save an avatar."
		State.EmptyMessage.TextColor3 = Color3.fromRGB(110, 110, 125)
		State.EmptyMessage.TextSize = 10
		State.EmptyMessage.Font = Enum.Font.Gotham
		State.EmptyMessage.Parent = State.ListContainer

		State.Sidebar = Instance.new("Frame")
		State.Sidebar.Name = "Sidebar"
	State.Sidebar.Size = UDim2.new(0, State.isMobile and 46 or 50, 0, 0)
	State.Sidebar.AutomaticSize = Enum.AutomaticSize.Y
		State.Sidebar.Position = UDim2.new(0, 8, 0, 38)
		State.Sidebar.BackgroundColor3 = Color3.fromRGB(25, 25, 32)
		State.Sidebar.BorderSizePixel = 0
		State.Sidebar.ZIndex = 5
		State.Sidebar.Active = true
		State.Sidebar.Parent = State.Main

		State.SidebarCorner = Instance.new("UICorner")
		State.SidebarCorner.CornerRadius = UDim.new(0, 7)
		State.SidebarCorner.Parent = State.Sidebar

		State.SidebarStroke = Instance.new("UIStroke")
		State.SidebarStroke.Color = Color3.fromRGB(48, 48, 60)
		State.SidebarStroke.Thickness = 1
		State.SidebarStroke.Parent = State.Sidebar

		State.SideLayout = Instance.new("UIListLayout")
		State.SideLayout.Padding = UDim.new(0, 5)
		State.SideLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
		State.SideLayout.VerticalAlignment = Enum.VerticalAlignment.Top
		State.SideLayout.SortOrder = Enum.SortOrder.LayoutOrder
		State.SideLayout.Parent = State.Sidebar

		State.SidePadding = Instance.new("UIPadding")
		State.SidePadding.PaddingTop = UDim.new(0, 7)
		State.SidePadding.PaddingLeft = UDim.new(0, 5)
		State.SidePadding.PaddingRight = UDim.new(0, 5)
		State.SidePadding.PaddingBottom = UDim.new(0, 7)
		State.SidePadding.Parent = State.Sidebar

		local function createNavButton(name, iconText, order, isDestructive)
			local button = Instance.new("TextButton")
			button.Name = name
			button.Size = UDim2.new(1, 0, 0, State.isMobile and 32 or 34)
			button.LayoutOrder = order
			button.BackgroundColor3 = isDestructive and Color3.fromRGB(90, 35, 35) or Color3.fromRGB(35, 35, 45)
			button.BorderSizePixel = 0
			button.Text = iconText
			button.TextColor3 = isDestructive and Color3.fromRGB(255, 225, 225) or Color3.fromRGB(190, 190, 205)
			button.TextSize = State.isMobile and 17 or 18
			button.Font = Enum.Font.Gotham
			button.TextWrapped = false
			button.TextScaled = false
			button.AutoButtonColor = false
			button.ZIndex = 6
			button.Active = true
			button.Parent = State.Sidebar

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

		State.SavedNav = createNavButton("SavedNav", utf8.char(0x1F4BE), 1, false)
		State.PlayersNav = createNavButton("PlayersNav", utf8.char(0x1F5A5), 2, false)
		State.FriendsNav = createNavButton("FriendsNav", utf8.char(0x1F464), 3, false)
	State.WorldPopupNav = createNavButton("WorldPopupNav", utf8.char(0x1F446, 0x1F3FB), 4, false)
	 State.WorldPopupNav.Size = UDim2.new(0, State.isMobile and 32 or 34, 0, State.isMobile and 32 or 34)
	 State.WorldPopupNav:FindFirstChildOfClass("UICorner").CornerRadius = UDim.new(0.5, 0)
	State.WorldPopupNav.TextSize = State.isMobile and 18 or 20

		State.UnloadButton.Parent = State.Sidebar
		State.UnloadButton.Size = UDim2.new(0, State.isMobile and 32 or 34, 0, State.isMobile and 32 or 34)
		State.UnloadButton.Position = UDim2.new(0, 0, 0, 0)
	State.UnloadButton.LayoutOrder = 5
		State.UnloadButton.BackgroundColor3 = Color3.fromRGB(100, 25, 25)
		State.UnloadButton.Text = utf8.char(0x1F4E4)
		State.UnloadButton.TextColor3 = Color3.fromRGB(255, 225, 225)
		State.UnloadButton.TextSize = State.isMobile and 17 or 18
		State.UnloadButton.Font = Enum.Font.Gotham
		State.UnloadButton.TextWrapped = false
		State.UnloadButton.BorderSizePixel = 0
		State.UnloadButton.ZIndex = 6
		State.UnloadCorner.CornerRadius = UDim.new(0.5, 0)

		local function createSocialPage(name, titleText)
			local page = Instance.new("Frame")
			page.Name = name
			page.Size = UDim2.new(1, State.ContentWidth, 1, -52)
			page.Position = UDim2.new(0, State.ContentX, 0, 44)
			page.BackgroundTransparency = 1
			page.Visible = false
			page.ZIndex = 5
			page.ClipsDescendants = true
			page.Parent = State.Main

			local title = Instance.new("TextLabel")
			title.Size = UDim2.new(1, -(State.isMobile and 108 or 136), 0, 16)
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
			searchBox.Size = UDim2.new(0, State.isMobile and 102 or 130, 0, 16)
			searchBox.Position = UDim2.new(1, -(State.isMobile and 104 or 132), 0, 0)
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
			local socialCellWidth = UDim2.new(0.31, 0, 0, State.isMobile and 108 or 112)
			layout.CellSize = socialCellWidth
			layout.CellPadding = UDim2.new(0, State.isMobile and 5 or 6, 0, 7)
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

			State.socialPages[name] = {Frame = page, Scroll = scroll, Layout = layout, Status = status, Empty = empty, SearchBox = searchBox, Items = {}, NextPage = nil, Finished = true}
			searchBox.PlaceholderText = name == "FriendsPage" and "Search Friends" or "Search Players"
			return State.socialPages[name]
		end

		State.PlayersPage = createSocialPage("PlayersPage", "PLAYERS IN SERVER")
		State.FriendsPage = createSocialPage("FriendsPage", "FRIENDS LIST")

		State.ActionModal = Instance.new("Frame")
		State.ActionModal.Size = UDim2.new(0, State.isMobile and 188 or 220, 0, 150)
		State.ActionModal.Position = UDim2.new(0, 8, 0, 42)
		State.ActionModal.BackgroundTransparency = 1
		State.ActionModal.BorderSizePixel = 0
		State.ActionModal.Visible = false
		State.ActionModal.Active = false
		State.ActionModal.ZIndex = 30
		State.ActionModal.ClipsDescendants = false
		State.ActionModal.Parent = State.Main

		State.ModalBox = Instance.new("Frame")
		State.ModalBox.Size = UDim2.new(1, 0, 1, 0)
		State.ModalBox.Position = UDim2.new(0, 0, 0, 0)
		State.ModalBox.BackgroundColor3 = Color3.fromRGB(28, 28, 36)
		State.ModalBox.BorderSizePixel = 0
		State.ModalBox.ZIndex = 31
		State.ModalBox.Active = true
		State.ModalBox.Parent = State.ActionModal

		State.ModalCorner = Instance.new("UICorner")
		State.ModalCorner.CornerRadius = UDim.new(0, 8)
		State.ModalCorner.Parent = State.ModalBox

		State.ModalStroke = Instance.new("UIStroke")
		State.ModalStroke.Color = Color3.fromRGB(48, 48, 60)
		State.ModalStroke.Thickness = 1
		State.ModalStroke.Parent = State.ModalBox

		State.ModalTitle = Instance.new("TextLabel")
		State.ModalTitle.Size = UDim2.new(1, -30, 0, 26)
		State.ModalTitle.Position = UDim2.new(0, 10, 0, 6)
		State.ModalTitle.BackgroundTransparency = 1
		State.ModalTitle.Text = "@Player"
		State.ModalTitle.TextColor3 = Color3.fromRGB(240, 240, 245)
		State.ModalTitle.TextSize = 11
		State.ModalTitle.Font = Enum.Font.GothamBold
		State.ModalTitle.TextTruncate = Enum.TextTruncate.AtEnd
		State.ModalTitle.ZIndex = 32
		State.ModalTitle.Parent = State.ModalBox

		State.ModalWear = Instance.new("TextButton")
		State.ModalWear.Size = UDim2.new(1, -20, 0, 26)
		State.ModalWear.Position = UDim2.new(0, 10, 0, 36)
		State.ModalWear.BackgroundColor3 = State.IS_CATALOG_GAME and Color3.fromRGB(55, 95, 175) or Color3.fromRGB(55, 55, 65)
		State.ModalWear.Text = State.IS_CATALOG_GAME and "WEAR AVATAR" or "WEAR [CAC ONLY]"
		State.ModalWear.TextColor3 = State.IS_CATALOG_GAME and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(130, 130, 140)
		State.ModalWear.TextSize = 9
		State.ModalWear.Font = Enum.Font.GothamBold
		State.ModalWear.ZIndex = 32
		State.ModalWear.Active = true
		State.ModalWear.Parent = State.ModalBox

		State.ModalWearCorner = Instance.new("UICorner")
		State.ModalWearCorner.CornerRadius = UDim.new(0, 6)
		State.ModalWearCorner.Parent = State.ModalWear

		State.ModalInspect = Instance.new("TextButton")
		State.ModalInspect.Size = UDim2.new(1, -20, 0, 26)
		State.ModalInspect.Position = UDim2.new(0, 10, 0, 68)
		State.ModalInspect.BackgroundColor3 = Color3.fromRGB(60, 110, 100)
		State.ModalInspect.Text = "INSPECT AVATAR"
		State.ModalInspect.TextColor3 = Color3.fromRGB(255, 255, 255)
		State.ModalInspect.TextSize = 9
		State.ModalInspect.Font = Enum.Font.GothamBold
		State.ModalInspect.ZIndex = 32
		State.ModalInspect.Active = true
		State.ModalInspect.Parent = State.ModalBox

		State.ModalInspectCorner = Instance.new("UICorner")
		State.ModalInspectCorner.CornerRadius = UDim.new(0, 6)
		State.ModalInspectCorner.Parent = State.ModalInspect

		State.ModalDelete = Instance.new("TextButton")
		State.ModalDelete.Size = UDim2.new(1, -20, 0, 26)
		State.ModalDelete.Position = UDim2.new(0, 10, 0, 100)
		State.ModalDelete.BackgroundColor3 = Color3.fromRGB(150, 50, 50)
		State.ModalDelete.Text = "DELETE"
		State.ModalDelete.TextColor3 = Color3.fromRGB(255, 255, 255)
		State.ModalDelete.TextSize = 9
		State.ModalDelete.Font = Enum.Font.GothamBold
		State.ModalDelete.ZIndex = 32
		State.ModalDelete.Active = true
		State.ModalDelete.Parent = State.ModalBox

		State.ModalDeleteCorner = Instance.new("UICorner")
		State.ModalDeleteCorner.CornerRadius = UDim.new(0, 6)
		State.ModalDeleteCorner.Parent = State.ModalDelete

		State.ModalClose = Instance.new("TextButton")
		State.ModalClose.Size = UDim2.new(0, 20, 0, 20)
		State.ModalClose.Position = UDim2.new(1, -24, 0, 6)
		State.ModalClose.BackgroundColor3 = Color3.fromRGB(65, 65, 75)
		State.ModalClose.BackgroundTransparency = 0
		State.ModalClose.Text = "X"
		State.ModalClose.TextColor3 = Color3.fromRGB(160, 160, 175)
		State.ModalClose.TextSize = 10
		State.ModalClose.Font = Enum.Font.GothamBold
		State.ModalClose.ZIndex = 32
		State.ModalClose.Active = true
		State.ModalClose.Parent = State.ModalBox

		State.InspectorModal = Instance.new("Frame")
		State.InspectorModal.Name = "AvatarInspectorPage"
		State.InspectorModal.Size = UDim2.new(1, 0, 1, -34)
		State.InspectorModal.Position = UDim2.new(0, 0, 0, 34)
		State.InspectorModal.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
		State.InspectorModal.BorderSizePixel = 0
		State.InspectorModal.Visible = false
		State.InspectorModal.Active = true
		State.InspectorModal.ZIndex = 20
		State.InspectorModal.ClipsDescendants = true
		State.InspectorModal.Parent = State.Main

		State.InspectorCorner = Instance.new("UICorner")
		State.InspectorCorner.CornerRadius = UDim.new(0, 8)
		State.InspectorCorner.Parent = State.InspectorModal

		State.InspectHeader = Instance.new("Frame")
		State.InspectHeader.Name = "InspectHeader"
		State.InspectHeader.Size = UDim2.new(1, 0, 0, 30)
		State.InspectHeader.BackgroundColor3 = Color3.fromRGB(25, 25, 32)
		State.InspectHeader.BorderSizePixel = 0
		State.InspectHeader.ZIndex = 21
		State.InspectHeader.Active = true
		State.InspectHeader.Parent = State.InspectorModal

		State.InspectHeaderCorner = Instance.new("UICorner")
		State.InspectHeaderCorner.CornerRadius = UDim.new(0, 8)
		State.InspectHeaderCorner.Parent = State.InspectHeader

		State.InspectTitle = Instance.new("TextLabel")
		State.InspectTitle.Size = UDim2.new(1, -58, 1, 0)
		State.InspectTitle.Position = UDim2.new(0, 12, 0, 0)
		State.InspectTitle.BackgroundTransparency = 1
		State.InspectTitle.Text = "Avatar Inspector"
		State.InspectTitle.TextColor3 = Color3.fromRGB(235, 235, 245)
		State.InspectTitle.TextSize = 11
		State.InspectTitle.Font = Enum.Font.GothamBold
		State.InspectTitle.TextXAlignment = Enum.TextXAlignment.Left
		State.InspectTitle.ZIndex = 22
		State.InspectTitle.Parent = State.InspectHeader

		State.InspectBack = Instance.new("TextButton")
		State.InspectBack.Name = "InspectBack"
		State.InspectBack.Size = UDim2.new(0, 44, 0, 20)
		State.InspectBack.Position = UDim2.new(1, -50, 0, 5)
		State.InspectBack.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
		State.InspectBack.Text = "BACK"
		State.InspectBack.TextColor3 = Color3.fromRGB(200, 200, 210)
		State.InspectBack.TextSize = 8
		State.InspectBack.Font = Enum.Font.GothamBold
		State.InspectBack.ZIndex = 22
		State.InspectBack.Active = true
		State.InspectBack.Parent = State.InspectHeader

		State.InspectBackCorner = Instance.new("UICorner")
		State.InspectBackCorner.CornerRadius = UDim.new(0, 4)
		State.InspectBackCorner.Parent = State.InspectBack

		State.LeftPane = Instance.new("Frame")
		State.LeftPane.Size = UDim2.new(0.38, -6, 1, -36)
		State.LeftPane.Position = UDim2.new(0, 6, 0, 32)
		State.LeftPane.BackgroundColor3 = Color3.fromRGB(48, 48, 56)
		State.LeftPane.BorderSizePixel = 0
		State.LeftPane.ZIndex = 21
		State.LeftPane.ClipsDescendants = true
		State.LeftPane.Active = true
		State.LeftPane.Parent = State.InspectorModal

		State.LeftCorner = Instance.new("UICorner")
		State.LeftCorner.CornerRadius = UDim.new(0, 6)
		State.LeftCorner.Parent = State.LeftPane

		State.InspectorWearButton = Instance.new("TextButton")
		State.InspectorWearButton.AnchorPoint = Vector2.new(0.5, 1)
		State.InspectorWearButton.Size = UDim2.new(0, 70, 0, 18)
		State.InspectorWearButton.Position = UDim2.new(0.5, 0, 1, -6)
		State.InspectorWearButton.BackgroundColor3 = State.IS_CATALOG_GAME and Color3.fromRGB(55, 95, 175) or Color3.fromRGB(55, 55, 65)
		State.InspectorWearButton.BorderSizePixel = 0
		State.InspectorWearButton.Text = State.IS_CATALOG_GAME and "WEAR" or "WEAR [CAC ONLY]"
		State.InspectorWearButton.TextColor3 = State.IS_CATALOG_GAME and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(130, 130, 140)
		State.InspectorWearButton.TextSize = 8
		State.InspectorWearButton.Font = Enum.Font.GothamBold
		State.InspectorWearButton.ZIndex = 30
		State.InspectorWearButton.Active = State.IS_CATALOG_GAME
		State.InspectorWearButton.Parent = State.LeftPane

		State.InspectorWearButtonCorner = Instance.new("UICorner")
		State.InspectorWearButtonCorner.CornerRadius = UDim.new(1, 0)
		State.InspectorWearButtonCorner.Parent = State.InspectorWearButton
		State.InspectorSaveAvatarButton = Instance.new("TextButton")
		State.InspectorSaveAvatarButton.Name = "InspectorSaveAvatarButton"
		State.InspectorSaveAvatarButton.AnchorPoint = Vector2.new(0.5, 0)
		State.InspectorSaveAvatarButton.Size = UDim2.new(0, 94, 0, 18)
		State.InspectorSaveAvatarButton.Position = UDim2.new(0.5, 0, 0, 6)
		State.InspectorSaveAvatarButton.BackgroundColor3 = Color3.fromRGB(46, 125, 85)
		State.InspectorSaveAvatarButton.BorderSizePixel = 0
		State.InspectorSaveAvatarButton.Text = "SAVE AVATAR"
		State.InspectorSaveAvatarButton.TextColor3 = Color3.fromRGB(255, 255, 255)
		State.InspectorSaveAvatarButton.TextSize = 8
		State.InspectorSaveAvatarButton.Font = Enum.Font.GothamBold
		State.InspectorSaveAvatarButton.ZIndex = 30
		State.InspectorSaveAvatarButton.Active = true
		State.InspectorSaveAvatarButton.Visible = false
		State.InspectorSaveAvatarButton.Parent = State.LeftPane
		Instance.new("UICorner", State.InspectorSaveAvatarButton).CornerRadius = UDim.new(1, 0)

		State.RightPane = Instance.new("Frame")
		State.RightPane.Size = UDim2.new(0.62, -10, 1, -36)
		State.RightPane.Position = UDim2.new(0.38, 4, 0, 32)
		State.RightPane.BackgroundTransparency = 1
		State.RightPane.ZIndex = 21
		State.RightPane.Active = true
		State.RightPane.Parent = State.InspectorModal

		State.ProfileCard = Instance.new("Frame")
		State.ProfileCard.Size = UDim2.new(1, 0, 0, 40)
		State.ProfileCard.BackgroundColor3 = Color3.fromRGB(25, 25, 32)
		State.ProfileCard.BorderSizePixel = 0
		State.ProfileCard.ZIndex = 22
		State.ProfileCard.Active = true
		State.ProfileCard.Parent = State.RightPane

		State.ProfileCorner = Instance.new("UICorner")
		State.ProfileCorner.CornerRadius = UDim.new(0, 6)
		State.ProfileCorner.Parent = State.ProfileCard

		State.ProfileIcon = Instance.new("ImageLabel")
		State.ProfileIcon.Size = UDim2.new(0, 30, 0, 30)
		State.ProfileIcon.Position = UDim2.new(0, 5, 0, 5)
		State.ProfileIcon.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
		State.ProfileIcon.ScaleType = Enum.ScaleType.Fit
		State.ProfileIcon.ZIndex = 23
		State.ProfileIcon.Parent = State.ProfileCard

		State.IconCorner = Instance.new("UICorner")
		State.IconCorner.CornerRadius = UDim.new(1, 0)
		State.IconCorner.Parent = State.ProfileIcon

		State.ProfileName = Instance.new("TextLabel")
		State.ProfileName.Size = UDim2.new(1, -102, 0, 15)
		State.ProfileName.Position = UDim2.new(0, 40, 0, 3)
		State.ProfileName.BackgroundTransparency = 1
		State.ProfileName.Text = "DisplayName"
		State.ProfileName.TextColor3 = Color3.fromRGB(240, 240, 245)
		State.ProfileName.TextSize = 9
		State.ProfileName.Font = Enum.Font.GothamBold
		State.ProfileName.TextXAlignment = Enum.TextXAlignment.Left
		State.ProfileName.TextScaled = true
		State.ProfileName.ZIndex = 23
		State.ProfileName.Parent = State.ProfileCard

		State.NameConstraint = Instance.new("UITextSizeConstraint")
		State.NameConstraint.MinTextSize = 7
		State.NameConstraint.MaxTextSize = 10
		State.NameConstraint.Parent = State.ProfileName

		State.ProfileUserBtn = Instance.new("TextButton")
		State.ProfileUserBtn.Size = UDim2.new(1, -102, 0, 16)
		State.ProfileUserBtn.Position = UDim2.new(0, 40, 0, 19)
		State.ProfileUserBtn.BackgroundTransparency = 1
		State.ProfileUserBtn.Text = "@Username"
		State.ProfileUserBtn.TextColor3 = Color3.fromRGB(140, 140, 155)
		State.ProfileUserBtn.TextSize = 7
		State.ProfileUserBtn.Font = Enum.Font.Gotham
		State.ProfileUserBtn.TextXAlignment = Enum.TextXAlignment.Left
		State.ProfileUserBtn.TextScaled = true
		State.ProfileUserBtn.ZIndex = 23
		State.ProfileUserBtn.Active = true
		State.ProfileUserBtn.Parent = State.ProfileCard

		State.UserConstraint = Instance.new("UITextSizeConstraint")
		State.UserConstraint.MinTextSize = 5
		State.UserConstraint.MaxTextSize = 8
		State.UserConstraint.Parent = State.ProfileUserBtn

		State.InspectorProfileCopy = Instance.new("TextButton")
		State.InspectorProfileCopy.Size = UDim2.new(0, 56, 0, 22)
		State.InspectorProfileCopy.Position = UDim2.new(1, -61, 0, 9)
		State.InspectorProfileCopy.BackgroundColor3 = Color3.fromRGB(60, 110, 100)
		State.InspectorProfileCopy.Text = "VIEW\nPROFILE"
		State.InspectorProfileCopy.TextColor3 = Color3.fromRGB(255, 255, 255)
		State.InspectorProfileCopy.TextSize = 7
		State.InspectorProfileCopy.Font = Enum.Font.GothamBold
		State.InspectorProfileCopy.ZIndex = 23
		State.InspectorProfileCopy.Active = true
		State.InspectorProfileCopy.Parent = State.ProfileCard

		State.InspectorProfileCopyCorner = Instance.new("UICorner")
		State.InspectorProfileCopyCorner.CornerRadius = UDim.new(0, 5)
		State.InspectorProfileCopyCorner.Parent = State.InspectorProfileCopy

		State.AssetGridList = Instance.new("ScrollingFrame")
		State.AssetGridList.Size = UDim2.new(1, 0, 1, -44)
		State.AssetGridList.Position = UDim2.new(0, 0, 0, 44)
		State.AssetGridList.BackgroundTransparency = 1
		State.AssetGridList.BorderSizePixel = 0
		State.AssetGridList.ScrollBarThickness = 2
		State.AssetGridList.ScrollBarImageColor3 = Color3.fromRGB(60, 60, 75)
		State.AssetGridList.AutomaticCanvasSize = Enum.AutomaticSize.Y
		State.AssetGridList.ZIndex = 22
		State.AssetGridList.Active = true
		State.AssetGridList.Parent = State.RightPane

		State.AssetGridLayout = Instance.new("UIGridLayout")
		State.AssetGridLayout.CellSize = UDim2.new(0.48, -2, 0, 72)
		State.AssetGridLayout.CellPadding = UDim2.new(0, 4, 0, 4)
		State.AssetGridLayout.SortOrder = Enum.SortOrder.LayoutOrder
		State.AssetGridLayout.Parent = State.AssetGridList

		State.ConfirmOverlay = Instance.new("TextButton")
		State.ConfirmOverlay.Name = "ConfirmOverlay"
		State.ConfirmOverlay.Size = UDim2.new(1, 0, 1, -34)
		State.ConfirmOverlay.Position = UDim2.new(0, 0, 0, 34)
		State.ConfirmOverlay.BackgroundColor3 = Color3.fromRGB(8, 8, 12)
		State.ConfirmOverlay.BackgroundTransparency = 0.45
		State.ConfirmOverlay.BorderSizePixel = 0
		State.ConfirmOverlay.Text = ""
		State.ConfirmOverlay.AutoButtonColor = false
		State.ConfirmOverlay.Modal = false
		State.ConfirmOverlay.Visible = false
		State.ConfirmOverlay.Active = true
		State.ConfirmOverlay.ZIndex = 49
		State.ConfirmOverlay.Parent = State.Main

		State.ConfirmFrame = Instance.new("Frame")
		State.ConfirmFrame.Size = UDim2.new(1, -20, 0, 70)
		State.ConfirmFrame.AnchorPoint = Vector2.new(0.5, 0.5)
		State.ConfirmFrame.Position = UDim2.new(0.5, 0, 0.5, -17)
		State.ConfirmFrame.BackgroundColor3 = Color3.fromRGB(32, 32, 40)
		State.ConfirmFrame.BorderSizePixel = 0
		State.ConfirmFrame.Visible = false
		State.ConfirmFrame.Active = true
		State.ConfirmFrame.ZIndex = 50
		State.ConfirmFrame.ClipsDescendants = true
		State.ConfirmFrame.Parent = State.ConfirmOverlay

		State.ConfirmCorner = Instance.new("UICorner")
		State.ConfirmCorner.CornerRadius = UDim.new(0, 8)
		State.ConfirmCorner.Parent = State.ConfirmFrame

		State.ConfirmText = Instance.new("TextLabel")
		State.ConfirmText.Size = UDim2.new(1, -10, 0, 24)
		State.ConfirmText.Position = UDim2.new(0, 5, 0, 4)
		State.ConfirmText.BackgroundTransparency = 1
		State.ConfirmText.Text = "Confirm action?"
		State.ConfirmText.TextColor3 = Color3.fromRGB(240, 240, 245)
		State.ConfirmText.TextSize = 10
		State.ConfirmText.Font = Enum.Font.GothamBold
		State.ConfirmText.ZIndex = 51
		State.ConfirmText.Parent = State.ConfirmFrame

		State.CancelButton = Instance.new("TextButton")
		State.CancelButton.Size = UDim2.new(0.5, -6, 0, 26)
		State.CancelButton.Position = UDim2.new(0, 4, 0, 36)
		State.CancelButton.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
		State.CancelButton.Text = "CANCEL"
		State.CancelButton.TextColor3 = Color3.fromRGB(255, 255, 255)
		State.CancelButton.TextSize = 9
		State.CancelButton.Font = Enum.Font.GothamBold
		State.CancelButton.ZIndex = 51
		State.CancelButton.Active = true
		State.CancelButton.Parent = State.ConfirmFrame

		State.CancelCorner = Instance.new("UICorner")
		State.CancelCorner.CornerRadius = UDim.new(0, 6)
		State.CancelCorner.Parent = State.CancelButton

		State.ConfirmAction = Instance.new("TextButton")
		State.ConfirmAction.Size = UDim2.new(0.5, -6, 0, 26)
		State.ConfirmAction.Position = UDim2.new(0.5, 2, 0, 36)
		State.ConfirmAction.BackgroundColor3 = Color3.fromRGB(150, 50, 50)
		State.ConfirmAction.Text = "CONFIRM"
		State.ConfirmAction.TextColor3 = Color3.fromRGB(255, 255, 255)
		State.ConfirmAction.TextSize = 9
		State.ConfirmAction.Font = Enum.Font.GothamBold
		State.ConfirmAction.ZIndex = 51
		State.ConfirmAction.Active = true
		State.ConfirmAction.Parent = State.ConfirmFrame

		State.ConfirmActionCorner = Instance.new("UICorner")
		State.ConfirmActionCorner.CornerRadius = UDim.new(0, 6)
		State.ConfirmActionCorner.Parent = State.ConfirmAction

		State.SelectFrame = Instance.new("Frame")
		State.SelectFrame.Size = UDim2.new(0, 200, 0, 70)
		State.SelectFrame.Position = UDim2.new(0.5, -100, 0.8, 0)
		State.SelectFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 38)
		State.SelectFrame.BorderSizePixel = 0
		State.SelectFrame.Visible = false
		State.SelectFrame.Active = true
		State.SelectFrame.ZIndex = 60
		State.SelectFrame.ClipsDescendants = true
		State.SelectFrame.Parent = State.ScreenGui

		State.SelectInputBlocker = Instance.new("TextButton")
		State.SelectInputBlocker.Size = UDim2.new(1, 0, 1, 0)
		State.SelectInputBlocker.BackgroundTransparency = 1
		State.SelectInputBlocker.Text = ""
		State.SelectInputBlocker.AutoButtonColor = false
		State.SelectInputBlocker.Modal = true
		State.SelectInputBlocker.ZIndex = 60
		State.SelectInputBlocker.Active = true
		State.SelectInputBlocker.Parent = State.SelectFrame

		State.SelectCorner = Instance.new("UICorner")
		State.SelectCorner.CornerRadius = UDim.new(0, 8)
		State.SelectCorner.Parent = State.SelectFrame

		State.SelectedProfileIcon = Instance.new("ImageLabel")
		State.SelectedProfileIcon.Size = UDim2.new(0, 24, 0, 24)
		State.SelectedProfileIcon.Position = UDim2.new(0, 8, 0, 4)
		State.SelectedProfileIcon.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
		State.SelectedProfileIcon.ScaleType = Enum.ScaleType.Fit
		State.SelectedProfileIcon.ZIndex = 61
		State.SelectedProfileIcon.Parent = State.SelectFrame

		State.SelectedProfileIconCorner = Instance.new("UICorner")
		State.SelectedProfileIconCorner.CornerRadius = UDim.new(1, 0)
		State.SelectedProfileIconCorner.Parent = State.SelectedProfileIcon

		State.SelectedName = Instance.new("TextLabel")
		State.SelectedName.Size = UDim2.new(1, -92, 0, 22)
		State.SelectedName.Position = UDim2.new(0, 38, 0, 5)
		State.SelectedName.BackgroundTransparency = 1
		State.SelectedName.Text = "@Player"
		State.SelectedName.TextColor3 = Color3.fromRGB(255, 255, 255)
		State.SelectedName.TextSize = 10
		State.SelectedName.Font = Enum.Font.GothamBold
		State.SelectedName.TextXAlignment = Enum.TextXAlignment.Left
		State.SelectedName.TextTruncate = Enum.TextTruncate.AtEnd
		State.SelectedName.ZIndex = 61
		State.SelectedName.Parent = State.SelectFrame

		State.CopyProfileButton = Instance.new("TextButton")
		State.CopyProfileButton.Size = UDim2.new(0, 46, 0, 22)
		State.CopyProfileButton.Position = UDim2.new(1, -54, 0, 5)
		State.CopyProfileButton.BackgroundColor3 = Color3.fromRGB(60, 110, 100)
		State.CopyProfileButton.Text = "SAVE\nPROFILE"
		State.CopyProfileButton.TextColor3 = Color3.fromRGB(255, 255, 255)
		State.CopyProfileButton.TextSize = 7
		State.CopyProfileButton.Font = Enum.Font.GothamBold
		State.CopyProfileButton.ZIndex = 61
		State.CopyProfileButton.Active = true
		State.CopyProfileButton.Parent = State.SelectFrame

		State.CopyProfileCorner = Instance.new("UICorner")
		State.CopyProfileCorner.CornerRadius = UDim.new(0, 6)
		State.CopyProfileCorner.Parent = State.CopyProfileButton

		State.HoldButton = Instance.new("TextButton")
		State.HoldButton.Size = UDim2.new(1, -76, 0, 28)
		State.HoldButton.Position = UDim2.new(0, 8, 0, 30)
		State.HoldButton.BackgroundColor3 = Color3.fromRGB(55, 95, 175)
		State.HoldButton.Text = "SAVE WEARING"
		State.HoldButton.TextColor3 = Color3.fromRGB(255, 255, 255)
		State.HoldButton.TextSize = 9
		State.HoldButton.Font = Enum.Font.GothamBold
		State.HoldButton.ZIndex = 61
		State.HoldButton.Active = true
		State.HoldButton.Parent = State.SelectFrame

		State.HoldCorner = Instance.new("UICorner")
		State.HoldCorner.CornerRadius = UDim.new(0, 6)
		State.HoldCorner.Parent = State.HoldButton

		State.SelectCancel = Instance.new("TextButton")
		State.SelectCancel.Size = UDim2.new(0, 54, 0, 28)
		State.SelectCancel.Position = UDim2.new(1, -62, 0, 30)
		State.SelectCancel.BackgroundColor3 = Color3.fromRGB(85, 45, 45)
		State.SelectCancel.Text = "CANCEL"
		State.SelectCancel.TextColor3 = Color3.fromRGB(255, 255, 255)
		State.SelectCancel.TextSize = 9
		State.SelectCancel.Font = Enum.Font.GothamBold
		State.SelectCancel.ZIndex = 61
		State.SelectCancel.Active = true
		State.SelectCancel.Parent = State.SelectFrame

		State.SelectCancelCorner = Instance.new("UICorner")
		State.SelectCancelCorner.CornerRadius = UDim.new(0, 6)
		State.SelectCancelCorner.Parent = State.SelectCancel

		local function pointInsideGui(guiObject, position)
			local guiPos = guiObject.AbsolutePosition
			local guiSize = guiObject.AbsoluteSize
			return position.X >= guiPos.X
				and position.Y >= guiPos.Y
				and position.X <= guiPos.X + guiSize.X
				and position.Y <= guiPos.Y + guiSize.Y
		end

	wire(State.UserInputService.InputChanged, function(input)
			if State.dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
				local delta = input.Position - State.dragStart
				State.Main.Position = UDim2.new(
					State.startPosition.X.Scale,
					State.startPosition.X.Offset + delta.X,
					State.startPosition.Y.Scale,
					State.startPosition.Y.Offset + delta.Y
				)
			end
	end)

	wire(State.UserInputService.InputEnded, function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				State.dragging = false
			end
	end)

		local function updateStatus()
			if not scriptAlive then return end
			State.Status.Text = "Saved Avatars: " .. tostring(#State.copiedAvatars)
			State.EmptyMessage.Visible = (#State.copiedAvatars == 0) and not State.minimized
		end

		local function hideSelectFrame()
			if not scriptAlive then return end
			markUIClick()
			State.selectedPlayer = nil
			State.SelectFrame.Visible = false
			State.HoldButton.Text = "SAVE WEARING"
			State.HoldButton.BackgroundColor3 = Color3.fromRGB(55, 95, 175)
			State.HoldButton.Active = true
			State.CopyProfileButton.Text = "SAVE\nPROFILE"
			State.CopyProfileButton.BackgroundColor3 = Color3.fromRGB(60, 110, 100)
			State.CopyProfileButton.Active = true
		end

	local function updateWorldPopupToggle()
	if State.worldPlayerPopupEnabled then
	State.WorldPopupNav.BackgroundColor3 = Color3.fromRGB(35, 190, 75)
	State.WorldPopupNav.TextColor3 = Color3.fromRGB(255, 255, 255)
	State.WorldPopupNav.Outline.Color = Color3.fromRGB(95, 235, 125)
	else
	State.WorldPopupNav.BackgroundColor3 = Color3.fromRGB(210, 45, 45)
	State.WorldPopupNav.TextColor3 = Color3.fromRGB(255, 255, 255)
	State.WorldPopupNav.Outline.Color = Color3.fromRGB(245, 100, 100)
	end
	end

	updateWorldPopupToggle()

	State.WorldPopupNav.Activated:Connect(function()
	markUIClick()
	State.worldPlayerPopupEnabled = not State.worldPlayerPopupEnabled
	if not State.worldPlayerPopupEnabled then
	hideSelectFrame()
	end
	updateWorldPopupToggle()
	end)

		local function wearCopiedAvatar(data)
			if not State.IS_CATALOG_GAME or not data or not data.Properties then return end

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
				State.catalogGuiRemote:InvokeServer(wearPayload)
			end)
			return ok
		end

		local function saveCurrentOutfit()
			if not State.IS_CATALOG_GAME then return end
			pcall(function()
				State.savedOutfitsRemote:InvokeServer({
					OutfitName = "Unnamed Outfit",
					Configs = {},
					Action = "CreateNewOutfit"
				})
			end)
			if not scriptAlive then return end
			State.Status.Text = "Current outfit saved!"
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
			for _, child in ipairs(State.AssetGridList:GetChildren()) do
				if child:IsA("Frame") then child:Destroy() end
			end

			State.ProfileName.Text = data.DisplayName or data.Name
			local userIdStr = tostring(data.UserId or "0")
			State.ProfileUserBtn.Text = "@" .. data.Name
			State.ProfileIcon.Image = "rbxthumb://type=AvatarBust&id=" .. userIdStr .. "&w=420&h=420"

			renderSavedAvatarPreview(State.LeftPane, data, true)
			local inspectorSaveButton = State.LeftPane:FindFirstChild("InspectorSaveAvatarButton")
			if inspectorSaveButton then
				inspectorSaveButton.Visible = data._InspectorSocialSave == true
			end
			State.InspectorProfileCopy.Text = data._InspectorProfileState and "INSPECTING\nPROFILE" or "VIEW\nPROFILE"
			State.InspectorProfileCopy.BackgroundColor3 = data._InspectorProfileState and Color3.fromRGB(85, 85, 95) or Color3.fromRGB(60, 110, 100)
			State.InspectorProfileCopy.TextColor3 = data._InspectorProfileState and Color3.fromRGB(180, 180, 190) or Color3.fromRGB(255, 255, 255)
			State.InspectorProfileCopy.Active = not data._InspectorProfileState

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
				AssetCard.Parent = State.AssetGridList

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

			State.Sidebar.Visible = false
			State.ListContainer.Visible = false
			State.SearchBox.Visible = false
			State.SaveButton.Visible = false
			State.CopySelfBtn.Visible = false
			State.ClearButton.Visible = false
			State.Status.Visible = false
			State.PlayersPage.Frame.Visible = false
			State.FriendsPage.Frame.Visible = false
			State.inspectorOpen = true
			State.InspectorModal.Visible = true
		end

	State.ProfileUserBtn.Activated:Connect(function()
			markUIClick()
			if State.currentActiveData and State.currentActiveData.Name and safeSetClipboard("@" .. State.currentActiveData.Name) then
				local oldText = State.ProfileUserBtn.Text
				State.ProfileUserBtn.Text = "COPIED USERNAME!"
				State.ProfileUserBtn.TextColor3 = Color3.fromRGB(100, 220, 150)
				task.delay(1.2, function()
					State.ProfileUserBtn.Text = oldText
					State.ProfileUserBtn.TextColor3 = Color3.fromRGB(140, 140, 155)
				end)
			end
		end)

		local function deleteAvatarEntry(data)
			for i, item in ipairs(State.copiedAvatars) do
				if item == data then
					if item.UI then item.UI:Destroy() end
					table.remove(State.copiedAvatars, i)
					break
				end
			end
			saveToWorkspace()
			updateStatus()
		end

		local function createAvatarCard(data, index)
			local Card = Instance.new("Frame")
			Card.Name = "SavedAvatarCard"
			Card.Size = State.cardCellWidth
			Card.BackgroundColor3 = Color3.fromRGB(28, 28, 36)
			Card.BorderSizePixel = 0
			Card.LayoutOrder = index
			Card.ClipsDescendants = true
			Card.Active = true
			Card.ZIndex = 6
			Card.Parent = State.List

			local Corner = Instance.new("UICorner")
			Corner.CornerRadius = UDim.new(0, 6)
			Corner.Parent = Card

			local CardStroke = Instance.new("UIStroke")
			CardStroke.Color = Color3.fromRGB(40, 40, 50)
			CardStroke.Thickness = 1
			CardStroke.Parent = Card

			local PreviewContainer = Instance.new("Frame")
			PreviewContainer.Size = UDim2.new(1, -8, 0, State.isMobile and 70 or 76)
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
			NameLabel.Position = UDim2.new(0, 3, 0, State.isMobile and 74 or 80)
			NameLabel.BackgroundTransparency = 1
			NameLabel.Text = tostring(data.DisplayName or data.Name or "Unknown")
			NameLabel.TextColor3 = Color3.fromRGB(230, 230, 240)
			NameLabel.TextSize = State.isMobile and 7 or 8
			NameLabel.Font = Enum.Font.GothamBold
			NameLabel.TextTruncate = Enum.TextTruncate.AtEnd
			NameLabel.TextXAlignment = Enum.TextXAlignment.Left
			NameLabel.ZIndex = 8
			NameLabel.Parent = Card

			local UsernameButton = Instance.new("TextButton")
			UsernameButton.Name = "Username"
			UsernameButton.Size = UDim2.new(1, -6, 0, 13)
			UsernameButton.Position = UDim2.new(0, 3, 0, State.isMobile and 87 or 93)
			UsernameButton.BackgroundTransparency = 1
			UsernameButton.Text = "@" .. tostring(data.Name or "unknown")
			UsernameButton.TextColor3 = Color3.fromRGB(140, 140, 155)
			UsernameButton.TextSize = State.isMobile and 6 or 7
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
				State.currentActiveData = data
				State.ModalTitle.Text = "@" .. tostring(data.Name or "unknown")
				local mainPos = State.Main.AbsolutePosition
				local cardPos = Card.AbsolutePosition
				local cardSize = Card.AbsoluteSize
				local popupSize = State.ActionModal.AbsoluteSize
				local relX = cardPos.X - mainPos.X
				local relY = cardPos.Y - mainPos.Y + cardSize.Y + 6
				local maxX = math.max(8, State.Main.AbsoluteSize.X - popupSize.X - 8)
				local maxY = math.max(42, State.Main.AbsoluteSize.Y - popupSize.Y - 8)
				if relY > maxY then relY = cardPos.Y - mainPos.Y - popupSize.Y - 6 end
				relX = math.clamp(relX, 8, maxX)
				relY = math.clamp(relY, 42, maxY)
				State.ActionModal.Position = UDim2.new(0, relX, 0, relY)
				State.ActionModal.Visible = true
			end)
		end

		local function updateOrders()
			for index, data in ipairs(State.copiedAvatars) do
				data.Order = index
				if data.UI and data.UI.Parent then
					data.UI.LayoutOrder = index
				end
			end
			saveToWorkspace()
		end

		local function filterSavedAvatarCards(query)
			query = string.lower(tostring(query or ""))
			for _, data in ipairs(State.copiedAvatars) do
				local displayName = string.lower(tostring(data.DisplayName or ""))
				local username = string.lower(tostring(data.Name or ""))
				local matches = query == "" or displayName:find(query, 1, true) or username:find(query, 1, true)
				if data.UI and data.UI.Parent then data.UI.Visible = matches and true or false end
			end
		end

		local function loadFromWorkspace()
			if type(readfile) ~= "function" or type(isfile) ~= "function" then return end

			local exists, isF = pcall(isfile, State.FILE_PATH)
			if not (exists and isF) then return end

			local ok, result = pcall(function()
				return State.HttpService:JSONDecode(readfile(State.FILE_PATH))
			end)

			if ok and type(result) == "table" then
				table.clear(State.copiedAvatars)
				for index, data in ipairs(result) do
					table.insert(State.copiedAvatars, data)
					createAvatarCard(data, index)
				end
				updateStatus()
			end
		end

		local function clearCopiedFits()
			for _, data in ipairs(State.copiedAvatars) do
				if data.UI then data.UI:Destroy() end
			end
			table.clear(State.copiedAvatars)
			if type(delfile) == "function" and type(isfile) == "function" then
				pcall(function() if isfile(State.FILE_PATH) then delfile(State.FILE_PATH) end end)
			end
			updateStatus()
			State.Status.Text = "Saved avatars cleared!"
			task.delay(2, updateStatus)
		end

		local function setProfileThumbnail(imageLabel, userId)
			if not imageLabel or not userId then return end
			task.spawn(function()
				local ok, content = pcall(function()
	local image = State.Players:GetUserThumbnailAsync(userId, Enum.ThumbnailType.AvatarBust, Enum.ThumbnailSize.Size100x100)
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
					return State.MarketplaceService:GetProductInfoAsync(assetId, Enum.InfoType.Asset)
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

			for _, existing in ipairs(State.copiedAvatars) do
				if existing.Signature == data.Signature then
					State.Status.Text = "Already saved!"
					task.delay(2, updateStatus)
					return false
				end
			end

			table.insert(State.copiedAvatars, 1, data)
			createAvatarCard(data, 1)
			filterSavedAvatarCards(State.SearchBox.Text)
			updateOrders()
			updateStatus()
			State.Status.Text = "Saved @" .. data.Name .. "!"
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
			for _, existing in ipairs(State.copiedAvatars) do
				if existing.Signature == profileData.Signature then
					State.Status.Text = "Already saved!"
					task.delay(2, updateStatus)
					return false
				end
			end
			table.insert(State.copiedAvatars, 1, profileData)
			createAvatarCard(profileData, 1)
			filterSavedAvatarCards(State.SearchBox.Text)
			updateOrders()
			updateStatus()
			State.Status.Text = "Saved @" .. profileData.Name .. "!"
			task.delay(2, updateStatus)
			return true
		end

		local function copyForStorage(targetPlayer)
			if State.copying or not targetPlayer or not targetPlayer.Character then return false end
			local humanoid = targetPlayer.Character:FindFirstChildOfClass("Humanoid")
			if not humanoid then return false end

			State.copying = true
			local ok, desc = pcall(function()
				return humanoid:GetAppliedDescription()
			end)

			if not ok or not desc then
				State.copying = false
				return false
			end

			if not hasCopyableMarketplaceAsset(desc) then
				State.copying = false
				return false
			end

			local copied = copyDescriptionForStorage(targetPlayer, desc)
			State.copying = false
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
			if not State.IS_CATALOG_GAME or not data then return end
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
			if State.copying or not cardData or not cardData.UserId then return end
			State.copying = true
			local oldText = profileButton.Text
			local oldColor = profileButton.BackgroundColor3
			profileButton.Text = "..."
			profileButton.Active = false
			local ok, desc = pcall(function()
				return State.Players:GetHumanoidDescriptionFromUserIdAsync(cardData.UserId)
			end)
			if not scriptAlive then
				State.copying = false
				return
			end
			if ok and desc then
				if inspectOnly then
					local props = createCopiedProperties(desc, nil)
					local rigType = getProfileRigType(cardData.UserId)
					State.currentActiveData = {Name = cardData.Username, UserId = cardData.UserId, DisplayName = cardData.DisplayName, Properties = props, RigType = (rigType == Enum.HumanoidRigType.R6) and "R6" or "R15", Signature = getAvatarSignature(props, rigType), Order = 1, _InspectorSocialSave = true, _InspectorProfileState = true}
					State.copying = false
					State.ActionModal.Visible = false
					populateAssetInspector(State.currentActiveData)
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
			State.copying = false
		end

		local function copySocialCurrent(cardData, currentButton, inspectOnly)
			if State.copying or not cardData then return end
			local player = State.Players:GetPlayerByUserId(tonumber(cardData.UserId) or 0)
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

			State.copying = true
			currentButton.Text = "CHECKING..."
			currentButton.Active = false
			local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
			local ok, desc = pcall(function()
				return humanoid and humanoid:GetAppliedDescription()
			end)
			if not scriptAlive then
				State.copying = false
				return
			end
			local copied = false
			if ok and desc then
				if inspectOnly then
					local props = createCopiedProperties(desc, player.Character)
					local rigType = humanoid and humanoid.RigType or getProfileRigType(cardData.UserId)
					State.currentActiveData = {Name = cardData.Username, UserId = cardData.UserId, DisplayName = cardData.DisplayName, Properties = props, RigType = (rigType == Enum.HumanoidRigType.R6) and "R6" or "R15", Signature = getAvatarSignature(props, rigType), Order = 1, _InspectorSocialSave = true, _InspectorProfileState = false}
					State.copying = false
					State.ActionModal.Visible = false
					populateAssetInspector(State.currentActiveData)
					currentButton.Text = "VIEW\nWEARING"
					currentButton.BackgroundColor3 = Color3.fromRGB(60, 110, 100)
					currentButton.Active = true
					return
				end
				if hasCopyableMarketplaceAsset(desc) then
					copied = copyDescriptionForStorage(player, desc)
				end
			end
			State.copying = false
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
			local cached = State.socialThumbnailCache[id]
			if cached then
				imageLabel.Image = cached
				return
			end
			task.spawn(function()
				local ok, content = pcall(function()
					local image = State.Players:GetUserThumbnailAsync(id, Enum.ThumbnailType.AvatarBust, Enum.ThumbnailSize.Size100x100)
					return image
				end)
				if not scriptAlive then return end
				if ok and content and content ~= "" then
					State.socialThumbnailCache[id] = content
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
			profileButton.TextSize = State.isMobile and 6 or 7
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
			viewProfileButton.TextSize = State.isMobile and 6 or 7
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
			currentButton.TextSize = State.isMobile and 6 or 7
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
			viewWearingButton.TextSize = State.isMobile and 6 or 7
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
			displayName.Position = UDim2.new(0, 3, 0, State.isMobile and 74 or 80)
			displayName.BackgroundTransparency = 1
			displayName.Text = tostring(item.DisplayName or item.Username or "Unknown")
			displayName.TextColor3 = Color3.fromRGB(230, 230, 240)
			displayName.TextSize = State.isMobile and 7 or 8
			displayName.Font = Enum.Font.GothamBold
			displayName.TextTruncate = Enum.TextTruncate.AtEnd
			displayName.TextXAlignment = Enum.TextXAlignment.Left
			displayName.ZIndex = 9
			displayName.Parent = card

			local username = Instance.new("TextButton")
			username.Name = "Username"
			username.Size = UDim2.new(1, -6, 0, 13)
			username.Position = UDim2.new(0, 3, 0, State.isMobile and 87 or 93)
			username.BackgroundTransparency = 1
			username.Text = "@" .. tostring(item.Username)
			username.TextColor3 = Color3.fromRGB(140, 140, 155)
			username.TextSize = State.isMobile and 6 or 7
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
			local pageData = State.PlayersPage
			clearSocialPage(pageData)
			local players = State.Players:GetPlayers()
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
			if State.socialLoading.Friends then return end
			State.socialLoading.Friends = true
			if firstLoad then
				clearSocialPage(pageData)
				pageData.NextPage = nil
				pageData.Finished = true
				setSocialStatus(pageData, "Loading friends...")
			end
			local success, pages = pcall(function()
				if firstLoad or not pageData.NextPage then
					return State.Players:GetFriendsAsync(State.LocalPlayer.UserId)
				end
				return pageData.NextPage
			end)
			if not success or not pages then
				setSocialStatus(pageData, "Unable to load friends right now.")
				pageData.Empty.Visible = (#pageData.Items == 0)
				pageData.Empty.Text = "Roblox did not return the friends list."
				State.socialLoading.Friends = false
				return
			end
			if not scriptAlive then
				State.socialLoading.Friends = false
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
			State.socialLoading.Friends = false
		end

		local function setPage(name)
			State.currentPage = name
			State.ActionModal.Visible = false
			local saved = name == "Saved"
			State.ListContainer.Visible = saved
			State.SearchBox.Visible = saved
			State.SaveButton.Visible = saved
			State.CopySelfBtn.Visible = saved
			State.ClearButton.Visible = saved
			State.Status.Visible = saved
			State.PlayersPage.Frame.Visible = (name == "Players")
			State.PlayersPage.SearchBox.Visible = (name == "Players")
			State.FriendsPage.Frame.Visible = (name == "Friends")
			State.FriendsPage.SearchBox.Visible = (name == "Friends")
	State.SavedNav.BackgroundColor3 = saved and Color3.fromRGB(0, 150, 255) or Color3.fromRGB(35, 35, 45)
	State.PlayersNav.BackgroundColor3 = name == "Players" and Color3.fromRGB(0, 150, 255) or Color3.fromRGB(35, 35, 45)
	State.FriendsNav.BackgroundColor3 = name == "Friends" and Color3.fromRGB(0, 150, 255) or Color3.fromRGB(35, 35, 45)
			State.SavedNav.TextColor3 = saved and Color3.fromRGB(255,255,255) or Color3.fromRGB(175,175,190)
			State.PlayersNav.TextColor3 = name == "Players" and Color3.fromRGB(255,255,255) or Color3.fromRGB(175,175,190)
			State.FriendsNav.TextColor3 = name == "Friends" and Color3.fromRGB(255,255,255) or Color3.fromRGB(175,175,190)
	State.SavedNav.Outline.Color = saved and Color3.fromRGB(90, 205, 255) or Color3.fromRGB(58, 58, 72)
	State.PlayersNav.Outline.Color = name == "Players" and Color3.fromRGB(90, 205, 255) or Color3.fromRGB(58, 58, 72)
	State.FriendsNav.Outline.Color = name == "Friends" and Color3.fromRGB(90, 205, 255) or Color3.fromRGB(58, 58, 72)
			if name == "Players" then loadServerPlayers() end
			if name == "Friends" and #State.FriendsPage.Items == 0 then loadFriendPage(State.FriendsPage, true) end
		end

	State.SavedNav.Activated:Connect(function() markUIClick(); setPage("Saved") end)
	State.PlayersNav.Activated:Connect(function() markUIClick(); setPage("Players") end)
	State.FriendsNav.Activated:Connect(function() markUIClick(); setPage("Friends") end)

	wire(State.Players.PlayerAdded, function()
			if State.currentPage == "Players" then task.defer(loadServerPlayers) end
	end)
	wire(State.Players.PlayerRemoving, function()
			if State.currentPage == "Players" then task.defer(loadServerPlayers) end
	end)
	wire(State.PlayersPage.Scroll:GetPropertyChangedSignal("CanvasPosition"), function()
			hideSocialActions(State.PlayersPage)
	end)
	wire(State.FriendsPage.Scroll:GetPropertyChangedSignal("CanvasPosition"), function()
			hideSocialActions(State.FriendsPage)
			if State.currentPage == "Friends" and not State.FriendsPage.Finished and not State.socialLoading.Friends then
				local canvasY = State.FriendsPage.Scroll.CanvasPosition.Y
				local viewportY = State.FriendsPage.Scroll.AbsoluteSize.Y
				local canvasSizeY = State.FriendsPage.Scroll.AbsoluteCanvasSize.Y
				if canvasY + viewportY >= canvasSizeY - 80 then
					local ok = pcall(function()
						if not State.FriendsPage.NextPage.IsFinished then State.FriendsPage.NextPage:AdvanceToNextPageAsync() end
					end)
					if ok then task.defer(function() loadFriendPage(State.FriendsPage, false) end) end
				end
			end
	end)

		local function getPlayerFromTarget(target)
			if not target then return nil end
			local model = target:FindFirstAncestorOfClass("Model")
			if not model then return nil end
			local humanoid = model:FindFirstChildOfClass("Humanoid")
			if not humanoid then return nil end
			local player = State.Players:GetPlayerFromCharacter(model)
			return (player and player ~= State.LocalPlayer) and player or nil
		end

		local function selectPlayer(player)
			if not player or player == State.LocalPlayer or not player.Character then return end
			State.selectedPlayer = player
			State.SelectedName.Text = "@" .. player.Name
			setProfileThumbnail(State.SelectedProfileIcon, player.UserId)

			State.HoldButton.Text = "SAVE WEARING"
			State.HoldButton.BackgroundColor3 = Color3.fromRGB(55, 95, 175)
			State.HoldButton.Active = true

			State.CopyProfileButton.Text = "SAVE\nPROFILE"
			State.CopyProfileButton.BackgroundColor3 = Color3.fromRGB(60, 110, 100)
			State.CopyProfileButton.Active = true

			State.SelectFrame.Visible = true
		end

		local function handlePlayerClick(inputPosition)
			if not State.Mouse then return end
	if not State.worldPlayerPopupEnabled then return end
			if os.clock() - State.lastUIClickTime < 0.25 then return end
			if State.ActionModal.Visible then return end
			if inputPosition and isInputOverUI(inputPosition) then return end

			local player = getPlayerFromTarget(State.Mouse.Target)
			if player then
				if State.InspectorModal.Visible then
					State.inspectorOpen = false
					State.InspectorModal.Visible = false
				end
				selectPlayer(player)
			else
				if State.SelectFrame.Visible then
					hideSelectFrame()
				end
			end
		end

	wire(State.UserInputService.TouchStarted, function(touch, gameProcessed)
			if gameProcessed then return end
			State.touchStartPos = Vector2.new(touch.Position.X, touch.Position.Y)
			State.touchStartTime = os.clock()
	end)

	wire(State.UserInputService.TouchEnded, function(touch, gameProcessed)
			if gameProcessed then return end
			local endPos = Vector2.new(touch.Position.X, touch.Position.Y)
			local dist = (endPos - State.touchStartPos).Magnitude
			local duration = os.clock() - State.touchStartTime

			if dist <= State.MAX_TAP_DISTANCE and duration <= State.MAX_TAP_DURATION then
				handlePlayerClick(endPos)
			end
	end)

	wire(State.UserInputService.InputBegan, function(input, gameProcessed)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				if pointInsideGui(State.TitleBar, input.Position)
					and not pointInsideGui(State.Minimize, input.Position)
					and not pointInsideGui(State.WatermarkEmojiButton, input.Position) then
					State.dragging = true
					State.dragStart = input.Position
					State.startPosition = State.Main.Position
				end
			end

			if gameProcessed then return end
			if input.UserInputType == Enum.UserInputType.MouseButton1 and not State.UserInputService.TouchEnabled then
				handlePlayerClick(input.Position)
			end
	end)

	State.HoldButton.Activated:Connect(function()
			markUIClick()
			if not State.selectedPlayer or State.copying or not State.HoldButton.Active then return end
			State.HoldButton.Text = "SAVING..."
			State.HoldButton.BackgroundColor3 = Color3.fromRGB(70, 70, 80)
			State.HoldButton.Active = false

			local player = State.selectedPlayer
			local copied = copyForStorage(player)

			if copied then
				State.HoldButton.Text = "SAVE SUCCESSFUL!"
				State.HoldButton.BackgroundColor3 = Color3.fromRGB(46, 125, 85)
				task.delay(0.35, hideSelectFrame)
			else
				if State.selectedPlayer == player and State.SelectFrame.Visible then
					State.HoldButton.Text = "UNABLE TO SAVE"
					State.HoldButton.BackgroundColor3 = Color3.fromRGB(75, 75, 82)
					State.HoldButton.Active = false
				end
			end
		end)

	State.CopyProfileButton.Activated:Connect(function()
			markUIClick()
			if not State.selectedPlayer or State.copying then return end
			local player = State.selectedPlayer
			State.CopyProfileButton.Text = "..."
			State.CopyProfileButton.Active = false
			local ok, desc = pcall(function()
				return State.Players:GetHumanoidDescriptionFromUserIdAsync(player.UserId)
			end)
			if ok and desc then
				local copied = copyProfileDescriptionForStorage({
					Name = player.Name,
					UserId = player.UserId,
					DisplayName = player.DisplayName
				}, desc)
				if copied then
					State.CopyProfileButton.Text = "SAVED!"
					State.CopyProfileButton.BackgroundColor3 = Color3.fromRGB(46, 125, 85)
					if State.selectedPlayer == player and State.SelectFrame.Visible then task.delay(0.35, hideSelectFrame) end
				else
					State.CopyProfileButton.Text = "SAVE\nPROFILE"
					State.CopyProfileButton.Active = true
				end
			else
				State.CopyProfileButton.Text = "SAVE\nPROFILE"
				State.CopyProfileButton.Active = true
			end
		end)

	State.SelectCancel.Activated:Connect(hideSelectFrame)

	State.SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
			filterSavedAvatarCards(State.SearchBox.Text)
		end)

	State.PlayersPage.SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
			filterSocialPage(State.PlayersPage, State.PlayersPage.SearchBox.Text)
		end)

	State.FriendsPage.SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
			filterSocialPage(State.FriendsPage, State.FriendsPage.SearchBox.Text)
		end)

	State.CopySelfBtn.Activated:Connect(function()
			markUIClick()
			copyForStorage(State.LocalPlayer)
		end)

		if State.IS_CATALOG_GAME then
	State.SaveButton.Activated:Connect(function()
				markUIClick()
				State.ConfirmText.Text = "Save Your Current Avatar in CAC?"
				State.currentConfirmAction = saveCurrentOutfit

				State.ConfirmOverlay.Visible = true
				State.ConfirmFrame.Visible = true
			end)
		end

	State.ModalClose.Activated:Connect(function()
			markUIClick()
			State.ActionModal.Visible = false
			State.currentActiveData = nil
		end)

	State.ModalWear.Activated:Connect(function()
			markUIClick()
			if not State.IS_CATALOG_GAME or not State.currentActiveData then return end
			local data = State.currentActiveData
			runWearAction(
				State.ModalWear,
				data,
				"SUCCESS",
				"WEAR AVATAR",
				Color3.fromRGB(55, 95, 175)
			)
			task.delay(1.2, function()
				if State.ModalWear.Parent then
					State.ActionModal.Visible = false
				end
			end)
		end)

	State.ModalInspect.Activated:Connect(function()
			markUIClick()
			if State.currentActiveData then
				State.LeftPane:FindFirstChild("InspectorSaveAvatarButton").Visible = false
				State.ActionModal.Visible = false
				populateAssetInspector(State.currentActiveData)
			end
		end)

	State.ModalDelete.Activated:Connect(function()
			markUIClick()
			if State.currentActiveData then
				local dataToDelete = State.currentActiveData
				State.ActionModal.Visible = false
				State.ConfirmText.Text = "Delete @" .. dataToDelete.Name .. "?"
				State.currentConfirmAction = function() deleteAvatarEntry(dataToDelete) end

				State.ConfirmOverlay.Visible = true
				State.ConfirmFrame.Visible = true
			end
		end)

	State.InspectBack.Activated:Connect(function()
			markUIClick()
			if State.currentActiveData and State.currentActiveData._InspectorPreviousData then
				State.currentActiveData = State.currentActiveData._InspectorPreviousData
				populateAssetInspector(State.currentActiveData)
				State.InspectorModal.Visible = true
				return
			end
			State.inspectorOpen = false
			State.LeftPane:FindFirstChild("InspectorSaveAvatarButton").Visible = false
			State.InspectorModal.Visible = false
			State.Sidebar.Visible = true
			setPage(State.currentPage)
		end)
	State.LeftPane:FindFirstChild("InspectorSaveAvatarButton").Activated:Connect(function()
			markUIClick()
			local button = State.LeftPane:FindFirstChild("InspectorSaveAvatarButton")
			if not button or not button.Visible or not State.currentActiveData or not State.currentActiveData.Properties then return end
			button.Active = false
			button.Text = "..."
			local saved = false
			local duplicate = false
			local data = State.currentActiveData
			for _, existing in ipairs(State.copiedAvatars) do
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
					table.insert(State.copiedAvatars, 1, savedData)
					createAvatarCard(savedData, 1)
					filterSavedAvatarCards(State.SearchBox.Text)
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

	State.InspectorWearButton.Activated:Connect(function()
			markUIClick()
			if not State.IS_CATALOG_GAME or not State.currentActiveData then return end
			local data = State.currentActiveData
			runWearAction(
				State.InspectorWearButton,
				data,
				"DONE!",
				"WEAR",
				Color3.fromRGB(55, 95, 175)
			)
		end)

	State.InspectorProfileCopy.Activated:Connect(function()
			markUIClick()
			if not State.currentActiveData or State.currentActiveData._InspectorProfileState or State.copying then return end
			State.InspectorProfileCopy.Text = "..."
			State.InspectorProfileCopy.Active = false
			local data = State.currentActiveData
			local ok, desc = pcall(function()
				return State.Players:GetHumanoidDescriptionFromUserIdAsync(data.UserId)
			end)
			if ok and desc then
				local props = createCopiedProperties(desc, nil)
				local rigType = getProfileRigType(data.UserId)
				State.currentActiveData = {Name = data.Name, UserId = data.UserId, DisplayName = data.DisplayName, Properties = props, RigType = (rigType == Enum.HumanoidRigType.R6) and "R6" or "R15", Signature = getAvatarSignature(props, rigType), Order = 1, _InspectorPreviousData = data, _InspectorSocialSave = true, _InspectorProfileState = true}
				populateAssetInspector(State.currentActiveData)
			else
				State.InspectorProfileCopy.Text = "VIEW\nPROFILE"
				State.InspectorProfileCopy.BackgroundColor3 = Color3.fromRGB(60, 110, 100)
				State.InspectorProfileCopy.Active = true
			end
		end)

	State.ClearButton.Activated:Connect(function()
			markUIClick()
			if #State.copiedAvatars == 0 then
				State.Status.Text = "Nothing to clear!"
				task.delay(2, updateStatus)
				return
			end

			State.ConfirmText.Text = "WARNING!!! Clear ALL Saved Avatars?"
			State.currentConfirmAction = clearCopiedFits

			State.ConfirmOverlay.Visible = true
			State.ConfirmFrame.Visible = true
		end)

	State.UnloadButton.Activated:Connect(function()
			markUIClick()
			State.ConfirmText.Text = "Destroy UI and unload?"
			State.currentConfirmAction = destroyScriptAndUI

			State.ConfirmOverlay.Visible = true
			State.ConfirmFrame.Visible = true
		end)

	State.CancelButton.Activated:Connect(function()
			markUIClick()
			State.ConfirmFrame.Visible = false
			State.ConfirmOverlay.Visible = false
			State.currentConfirmAction = nil
			updateStatus()
		end)

	State.ConfirmAction.Activated:Connect(function()
			markUIClick()
			State.ConfirmFrame.Visible = false
			State.ConfirmOverlay.Visible = false

			if State.currentConfirmAction then
				local action = State.currentConfirmAction
				State.currentConfirmAction = nil
				action()
			end
		end)

	State.Minimize.Activated:Connect(function()
			markUIClick()
			State.minimized = not State.minimized
			if State.minimized then
				hideSelectFrame()
				applyTween(State.Main, {Size = UDim2.new(0, 180, 0, 34)})

				State.SaveButton.Visible = false
				State.CopySelfBtn.Visible = false
				State.ClearButton.Visible = false
				State.UnloadButton.Visible = false
				State.Status.Visible = false
				State.SearchBox.Visible = false
				State.ListContainer.Visible = false
				State.ConfirmFrame.Visible = false
				State.ConfirmOverlay.Visible = false
				State.ActionModal.Visible = false
				State.InspectorModal.Visible = false
				State.Sidebar.Visible = false
				State.PlayersPage.Frame.Visible = false
				State.FriendsPage.Frame.Visible = false
				State.Minimize.Text = "+"
			else
				applyTween(State.Main, {Size = UDim2.new(0, State.mainWidth, 0, State.mainHeight)})
				State.SaveButton.Visible = true
				State.CopySelfBtn.Visible = true
				State.ClearButton.Visible = true
				State.UnloadButton.Visible = true
				State.Status.Visible = true
				State.SearchBox.Visible = true
				State.ListContainer.Visible = true
				State.Sidebar.Visible = true
				setPage(State.currentPage)
				if State.inspectorOpen then
					State.Sidebar.Visible = false
					State.ListContainer.Visible = false
					State.SearchBox.Visible = false
					State.SaveButton.Visible = false
					State.CopySelfBtn.Visible = false
					State.ClearButton.Visible = false
					State.Status.Visible = false
					State.PlayersPage.Frame.Visible = false
					State.FriendsPage.Frame.Visible = false
					State.InspectorModal.Visible = true
				else
					State.InspectorModal.Visible = false
				end
				State.ConfirmOverlay.Visible = State.currentConfirmAction ~= nil
				State.ConfirmFrame.Visible = State.currentConfirmAction ~= nil
				State.Minimize.Text = "-"
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
