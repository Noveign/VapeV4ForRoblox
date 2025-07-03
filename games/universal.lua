local loadstring = function(...)
	local res, err = loadstring(...)
	if err and vape then
		vape:CreateNotification('Vape', 'Failed to load : '..err, 30, 'alert')
	end
	return res
end
local isfile = isfile or function(file)
	local suc, res = pcall(function()
		return readfile(file)
	end)
	return suc and res ~= nil and res ~= ''
end
local function downloadFile(path, func)
	if not isfile(path) then
		local suc, res = pcall(function()
			return game:HttpGet('https://raw.githubusercontent.com/7GrandDadPGN/VapeV4ForRoblox/'..readfile('newvape/profiles/commit.txt')..'/'..select(1, path:gsub('newvape/', '')), true)
		end)
		if not suc or res == '404: Not Found' then
			error(res)
		end
		if path:find('.lua') then
			res = '--This watermark is used to delete the file if its cached, remove it to make the file persist after vape updates.\n'..res
		end
		writefile(path, res)
	end
	return (func or readfile)(path)
end
local run = function(func)
	func()
end
local queue_on_teleport = queue_on_teleport or function() end
local cloneref = cloneref or function(obj)
	return obj
end

local playersService = cloneref(game:GetService('Players'))
local replicatedStorage = cloneref(game:GetService('ReplicatedStorage'))
local runService = cloneref(game:GetService('RunService'))
local inputService = cloneref(game:GetService('UserInputService'))
local tweenService = cloneref(game:GetService('TweenService'))
local lightingService = cloneref(game:GetService('Lighting'))
local marketplaceService = cloneref(game:GetService('MarketplaceService'))
local teleportService = cloneref(game:GetService('TeleportService'))
local httpService = cloneref(game:GetService('HttpService'))
local guiService = cloneref(game:GetService('GuiService'))
local groupService = cloneref(game:GetService('GroupService'))
local textChatService = cloneref(game:GetService('TextChatService'))
local contextService = cloneref(game:GetService('ContextActionService'))
local coreGui = cloneref(game:GetService('CoreGui'))

local isnetworkowner = identifyexecutor and table.find({'AWP', 'Nihon'}, ({identifyexecutor()})[1]) and isnetworkowner or function()
	return true
end
local gameCamera = workspace.CurrentCamera or workspace:FindFirstChildWhichIsA('Camera')
local lplr = playersService.LocalPlayer
local assetfunction = getcustomasset

local vape = shared.vape
local tween = vape.Libraries.tween
local targetinfo = vape.Libraries.targetinfo
local getfontsize = vape.Libraries.getfontsize
local getcustomasset = vape.Libraries.getcustomasset

local TargetStrafeVector, SpiderShift, WaypointFolder
local Spider = {Enabled = false}
local Phase = {Enabled = false}

local function addBlur(parent)
	local blur = Instance.new('ImageLabel')
	blur.Name = 'Blur'
	blur.Size = UDim2.new(1, 89, 1, 52)
	blur.Position = UDim2.fromOffset(-48, -31)
	blur.BackgroundTransparency = 1
	blur.Image = getcustomasset('newvape/assets/new/blur.png')
	blur.ScaleType = Enum.ScaleType.Slice
	blur.SliceCenter = Rect.new(52, 31, 261, 502)
	blur.Parent = parent
	return blur
end

local function calculateMoveVector(vec)
	local c, s
	local _, _, _, R00, R01, R02, _, _, R12, _, _, R22 = gameCamera.CFrame:GetComponents()
	if R12 < 1 and R12 > -1 then
		c = R22
		s = R02
	else
		c = R00
		s = -R01 * math.sign(R12)
	end
	vec = Vector3.new((c * vec.X + s * vec.Z), 0, (c * vec.Z - s * vec.X)) / math.sqrt(c * c + s * s)
	return vec.Unit == vec.Unit and vec.Unit or Vector3.zero
end

local function isFriend(plr, recolor)
	if vape.Categories.Friends.Options['Use friends'].Enabled then
		local friend = table.find(vape.Categories.Friends.ListEnabled, plr.Name) and true
		if recolor then
			friend = friend and vape.Categories.Friends.Options['Recolor visuals'].Enabled
		end
		return friend
	end
	return nil
end

local function isTarget(plr)
	return table.find(vape.Categories.Targets.ListEnabled, plr.Name) and true
end

local function canClick()
	local mousepos = (inputService:GetMouseLocation() - guiService:GetGuiInset())
	for _, v in lplr.PlayerGui:GetGuiObjectsAtPosition(mousepos.X, mousepos.Y) do
		local obj = v:FindFirstAncestorOfClass('ScreenGui')
		if v.Active and v.Visible and obj and obj.Enabled then
			return false
		end
	end
	for _, v in coreGui:GetGuiObjectsAtPosition(mousepos.X, mousepos.Y) do
		local obj = v:FindFirstAncestorOfClass('ScreenGui')
		if v.Active and v.Visible and obj and obj.Enabled then
			return false
		end
	end
	return (not vape.gui.ScaledGui.ClickGui.Visible) and (not inputService:GetFocusedTextBox())
end

local function getTableSize(tab)
	local ind = 0
	for _ in tab do ind += 1 end
	return ind
end

local function getTool()
	return lplr.Character and lplr.Character:FindFirstChildWhichIsA('Tool', true) or nil
end

local function notif(...)
	return vape:CreateNotification(...)
end

local function removeTags(str)
	str = str:gsub('<br%s*/>', '\n')
	return (str:gsub('<[^<>]->', ''))
end

local visited, attempted, tpSwitch = {}, {}, false
local cacheExpire, cache = tick()
local function serverHop(pointer, filter)
	visited = shared.vapeserverhoplist and shared.vapeserverhoplist:split('/') or {}
	if not table.find(visited, game.JobId) then
		table.insert(visited, game.JobId)
	end
	if not pointer then
		notif('Vape', 'Searching for an available server.', 2)
	end

	local suc, httpdata = pcall(function()
		return cacheExpire < tick() and game:HttpGet('https://games.roblox.com/v1/games/'..game.PlaceId..'/servers/Public?sortOrder='..(filter == 'Ascending' and 1 or 2)..'&excludeFullGames=true&limit=100'..(pointer and '&cursor='..pointer or '')) or cache
	end)
	local data = suc and httpService:JSONDecode(httpdata) or nil
	if data and data.data then
		for _, v in data.data do
			if tonumber(v.playing) < playersService.MaxPlayers and not table.find(visited, v.id) and not table.find(attempted, v.id) then
				cacheExpire, cache = tick() + 60, httpdata
				table.insert(attempted, v.id)

				notif('Vape', 'Found! Teleporting.', 5)
				teleportService:TeleportToPlaceInstance(game.PlaceId, v.id)
				return
			end
		end

		if data.nextPageCursor then
			serverHop(data.nextPageCursor, filter)
		else
			notif('Vape', 'Failed to find an available server.', 5, 'warning')
		end
	else
		notif('Vape', 'Failed to grab servers. ('..(data and data.errors[1].message or 'no data')..')', 5, 'warning')
	end
end

vape:Clean(lplr.OnTeleport:Connect(function()
	if not tpSwitch then
		tpSwitch = true
		queue_on_teleport("shared.vapeserverhoplist = '"..table.concat(visited, '/').."'\nshared.vapeserverhopprevious = '"..game.JobId.."'")
	end
end))

local frictionTable, oldfrict, entitylib = {}, {}
local function updateVelocity()
	if getTableSize(frictionTable) > 0 then
		if entitylib.isAlive then
			for _, v in entitylib.character.Character:GetChildren() do
				if v:IsA('BasePart') and v.Name ~= 'HumanoidRootPart' and not oldfrict[v] then
					oldfrict[v] = v.CustomPhysicalProperties or 'none'
					v.CustomPhysicalProperties = PhysicalProperties.new(0.0001, 0.2, 0.5, 1, 1)
				end
			end
		end
	else
		for i, v in oldfrict do
			i.CustomPhysicalProperties = v ~= 'none' and v or nil
		end
		table.clear(oldfrict)
	end
end

local function motorMove(target, cf)
	local part = Instance.new('Part')
	part.Anchored = true
	part.Parent = workspace
	local motor = Instance.new('Motor6D')
	motor.Part0 = target
	motor.Part1 = part
	motor.C1 = cf
	motor.Parent = part
	task.delay(0, part.Destroy, part)
end

local hash = loadstring(downloadFile('newvape/libraries/hash.lua'), 'hash')()
local prediction = loadstring(downloadFile('newvape/libraries/prediction.lua'), 'prediction')()
entitylib = loadstring(downloadFile('newvape/libraries/entity.lua'), 'entitylibrary')()
local whitelist = {
	alreadychecked = {},
	customtags = {},
	data = {WhitelistedUsers = {}},
	hashes = setmetatable({}, {
		__index = function(_, v)
			return hash and hash.sha512(v..'SelfReport') or ''
		end
	}),
	hooked = false,
	loaded = false,
	localprio = 0,
	said = {}
}
vape.Libraries.entity = entitylib
vape.Libraries.whitelist = whitelist
vape.Libraries.prediction = prediction
vape.Libraries.hash = hash
vape.Libraries.auraanims = {
	Normal = {
		{CFrame = CFrame.new(-0.17, -0.14, -0.12) * CFrame.Angles(math.rad(-53), math.rad(50), math.rad(-64)), Time = 0.1},
		{CFrame = CFrame.new(-0.55, -0.59, -0.1) * CFrame.Angles(math.rad(-161), math.rad(54), math.rad(-6)), Time = 0.08},
		{CFrame = CFrame.new(-0.62, -0.68, -0.07) * CFrame.Angles(math.rad(-167), math.rad(47), math.rad(-1)), Time = 0.03},
		{CFrame = CFrame.new(-0.56, -0.86, 0.23) * CFrame.Angles(math.rad(-167), math.rad(49), math.rad(-1)), Time = 0.03}
	},
	Random = {},
	['Horizontal Spin'] = {
		{CFrame = CFrame.Angles(math.rad(-10), math.rad(-90), math.rad(-80)), Time = 0.12},
		{CFrame = CFrame.Angles(math.rad(-10), math.rad(180), math.rad(-80)), Time = 0.12},
		{CFrame = CFrame.Angles(math.rad(-10), math.rad(90), math.rad(-80)), Time = 0.12},
		{CFrame = CFrame.Angles(math.rad(-10), 0, math.rad(-80)), Time = 0.12}
	},
	['Vertical Spin'] = {
		{CFrame = CFrame.Angles(math.rad(-90), 0, math.rad(15)), Time = 0.12},
		{CFrame = CFrame.Angles(math.rad(180), 0, math.rad(15)), Time = 0.12},
		{CFrame = CFrame.Angles(math.rad(90), 0, math.rad(15)), Time = 0.12},
		{CFrame = CFrame.Angles(0, 0, math.rad(15)), Time = 0.12}
	},
	Exhibition = {
		{CFrame = CFrame.new(0.69, -0.7, 0.6) * CFrame.Angles(math.rad(-30), math.rad(50), math.rad(-90)), Time = 0.1},
		{CFrame = CFrame.new(0.7, -0.71, 0.59) * CFrame.Angles(math.rad(-84), math.rad(50), math.rad(-38)), Time = 0.2}
	},
	['Exhibition Old'] = {
		{CFrame = CFrame.new(0.69, -0.7, 0.6) * CFrame.Angles(math.rad(-30), math.rad(50), math.rad(-90)), Time = 0.15},
		{CFrame = CFrame.new(0.69, -0.7, 0.6) * CFrame.Angles(math.rad(-30), math.rad(50), math.rad(-90)), Time = 0.05},
		{CFrame = CFrame.new(0.7, -0.71, 0.59) * CFrame.Angles(math.rad(-84), math.rad(50), math.rad(-38)), Time = 0.1},
		{CFrame = CFrame.new(0.7, -0.71, 0.59) * CFrame.Angles(math.rad(-84), math.rad(50), math.rad(-38)), Time = 0.05},
		{CFrame = CFrame.new(0.63, -0.1, 1.37) * CFrame.Angles(math.rad(-84), math.rad(50), math.rad(-38)), Time = 0.15}
	}
}

local SpeedMethods
local SpeedMethodList = {'Velocity'}
SpeedMethods = {
	Velocity = function(options, moveDirection)
		local root = entitylib.character.RootPart
		root.AssemblyLinearVelocity = (moveDirection * options.Value.Value) + Vector3.new(0, root.AssemblyLinearVelocity.Y, 0)
	end,
	Impulse = function(options, moveDirection)
		local root = entitylib.character.RootPart
		local diff = ((moveDirection * options.Value.Value) - root.AssemblyLinearVelocity) * Vector3.new(1, 0, 1)
		if diff.Magnitude > (moveDirection == Vector3.zero and 10 or 2) then
			root:ApplyImpulse(diff * root.AssemblyMass)
		end
	end,
	CFrame = function(options, moveDirection, dt)
		local root = entitylib.character.RootPart
		local dest = (moveDirection * math.max(options.Value.Value - entitylib.character.Humanoid.WalkSpeed, 0) * dt)
		if options.WallCheck.Enabled then
			options.rayCheck.FilterDescendantsInstances = {lplr.Character, gameCamera}
			options.rayCheck.CollisionGroup = root.CollisionGroup
			local ray = workspace:Raycast(root.Position, dest, options.rayCheck)
			if ray then
				dest = ((ray.Position + ray.Normal) - root.Position)
			end
		end
		root.CFrame += dest
	end,
	TP = function(options, moveDirection)
		if options.TPTiming < tick() then
			options.TPTiming = tick() + options.TPFrequency.Value
			SpeedMethods.CFrame(options, moveDirection, 1)
		end
	end,
	WalkSpeed = function(options)
		if not options.WalkSpeed then options.WalkSpeed = entitylib.character.Humanoid.WalkSpeed end
		entitylib.character.Humanoid.WalkSpeed = options.Value.Value
	end,
	Pulse = function(options, moveDirection)
		local root = entitylib.character.RootPart
		local dt = math.max(options.Value.Value - entitylib.character.Humanoid.WalkSpeed, 0)
		dt = dt * (1 - math.min((tick() % (options.PulseLength.Value + options.PulseDelay.Value)) / options.PulseLength.Value, 1))
		root.AssemblyLinearVelocity = (moveDirection * (entitylib.character.Humanoid.WalkSpeed + dt)) + Vector3.new(0, root.AssemblyLinearVelocity.Y, 0)
	end
}
for name in SpeedMethods do
	if not table.find(SpeedMethodList, name) then
		table.insert(SpeedMethodList, name)
	end
end

run(function()
	entitylib.getUpdateConnections = function(ent)
		local hum = ent.Humanoid
		return {
			hum:GetPropertyChangedSignal('Health'),
			hum:GetPropertyChangedSignal('MaxHealth'),
			{
				Connect = function()
					ent.Friend = ent.Player and isFriend(ent.Player) or nil
					ent.Target = ent.Player and isTarget(ent.Player) or nil
					return {
						Disconnect = function() end
					}
				end
			}
		}
	end

	entitylib.targetCheck = function(ent)
		if ent.TeamCheck then
			return ent:TeamCheck()
		end
		if ent.NPC then return true end
		if isFriend(ent.Player) then return false end
		if not select(2, whitelist:get(ent.Player)) then return false end
		if vape.Categories.Main.Options['Teams by server'].Enabled then
			if not lplr.Team then return true end
			if not ent.Player.Team then return true end
			if ent.Player.Team ~= lplr.Team then return true end
			return #ent.Player.Team:GetPlayers() == #playersService:GetPlayers()
		end
		return true
	end

	entitylib.getEntityColor = function(ent)
		ent = ent.Player
		if not (ent and vape.Categories.Main.Options['Use team color'].Enabled) then return end
		if isFriend(ent, true) then
			return Color3.fromHSV(vape.Categories.Friends.Options['Friends color'].Hue, vape.Categories.Friends.Options['Friends color'].Sat, vape.Categories.Friends.Options['Friends color'].Value)
		end
		return tostring(ent.TeamColor) ~= 'White' and ent.TeamColor.Color or nil
	end

	vape:Clean(function()
		entitylib.kill()
		entitylib = nil
	end)
	vape:Clean(vape.Categories.Friends.Update.Event:Connect(function() entitylib.refresh() end))
	vape:Clean(vape.Categories.Targets.Update.Event:Connect(function() entitylib.refresh() end))
	vape:Clean(entitylib.Events.LocalAdded:Connect(updateVelocity))
	vape:Clean(workspace:GetPropertyChangedSignal('CurrentCamera'):Connect(function()
		gameCamera = workspace.CurrentCamera or workspace:FindFirstChildWhichIsA('Camera')
	end))
end)

run(function()
	function whitelist:get(plr)
		local plrstr = self.hashes[plr.Name..plr.UserId]
		for _, v in self.data.WhitelistedUsers do
			if v.hash == plrstr then
				return v.level, v.attackable or whitelist.localprio >= v.level, v.tags
			end
		end
		return 0, true
	end

	function whitelist:isingame()
		for _, v in playersService:GetPlayers() do
			if self:get(v) ~= 0 then return true end
		end
		return false
	end

	function whitelist:tag(plr, text, rich)
		local plrtag, newtag = select(3, self:get(plr)) or self.customtags[plr.Name] or {}, ''
		if not text then return plrtag end
		for _, v in plrtag do
			newtag = newtag..(rich and '<font color="#'..v.color:ToHex()..'">['..v.text..']</font>' or '['..removeTags(v.text)..']')..' '
		end
		return newtag
	end

	function whitelist:getplayer(arg)
		if arg == 'default' and self.localprio == 0 then return true end
		if arg == 'private' and self.localprio == 1 then return true end
		if arg and lplr.Name:lower():sub(1, arg:len()) == arg:lower() then return true end
		return false
	end

	local olduninject
	function whitelist:playeradded(v, joined)
		if self:get(v) ~= 0 then
			if self.alreadychecked[v.UserId] then return end
			self.alreadychecked[v.UserId] = true
			self:hook()
			if self.localprio == 0 then
				olduninject = vape.Uninject
				vape.Uninject = function()
					notif('Vape', 'No escaping the private members :)', 10)
				end
				if joined then
					task.wait(10)
				end
				if textChatService.ChatVersion == Enum.ChatVersion.TextChatService then
					local oldchannel = textChatService.ChatInputBarConfiguration.TargetTextChannel
					local newchannel = cloneref(game:GetService('RobloxReplicatedStorage')).ExperienceChat.WhisperChat:InvokeServer(v.UserId)
					if newchannel then
						newchannel:SendAsync('helloimusinginhaler')
					end
					textChatService.ChatInputBarConfiguration.TargetTextChannel = oldchannel
				elseif replicatedStorage:FindFirstChild('DefaultChatSystemChatEvents') then
					replicatedStorage.DefaultChatSystemChatEvents.SayMessageRequest:FireServer('/w '..v.Name..' helloimusinginhaler', 'All')
				end
			end
		end
	end

	function whitelist:process(msg, plr)
		if plr == lplr and msg == 'helloimusinginhaler' then return true end

		if self.localprio > 0 and not self.said[plr.Name] and msg == 'helloimusinginhaler' and plr ~= lplr then
			self.said[plr.Name] = true
			notif('Vape', plr.Name..' is using vape!', 60)
			self.customtags[plr.Name] = {{
				text = 'VAPE USER',
				color = Color3.new(1, 1, 0)
			}}
			local newent = entitylib.getEntity(plr)
			if newent then
				entitylib.Events.EntityUpdated:Fire(newent)
			end
			return true
		end

		if self.localprio < self:get(plr) or plr == lplr then
			local args = msg:split(' ')
			table.remove(args, 1)
			if self:getplayer(args[1]) then
				table.remove(args, 1)
				for cmd, func in self.commands do
					if msg:sub(1, cmd:len() + 1):lower() == ';'..cmd:lower() then
						func(args, plr)
						return true
					end
				end
			end
		end

		return false
	end

	function whitelist:newchat(obj, plr, skip)
		obj.Text = self:tag(plr, true, true)..obj.Text
		local sub = obj.ContentText:find(': ')
		if sub then
			if not skip and self:process(obj.ContentText:sub(sub + 3, #obj.ContentText), plr) then
				obj.Visible = false
			end
		end
	end

	function whitelist:oldchat(func)
		local msgtable, oldchat = debug.getupvalue(func, 3)
		if typeof(msgtable) == 'table' and msgtable.CurrentChannel then
			whitelist.oldchattable = msgtable
		end

		oldchat = hookfunction(func, function(data, ...)
			local plr = playersService:GetPlayerByUserId(data.SpeakerUserId)
			if plr then
				data.ExtraData.Tags = data.ExtraData.Tags or {}
				for _, v in self:tag(plr) do
					table.insert(data.ExtraData.Tags, {TagText = v.text, TagColor = v.color})
				end
				if data.Message and self:process(data.Message, plr) then
					data.Message = ''
				end
			end
			return oldchat(data, ...)
		end)

		vape:Clean(function()
			hookfunction(func, oldchat)
		end)
	end

	function whitelist:hook()
		if self.hooked then return end
		self.hooked = true

		local exp = coreGui:FindFirstChild('ExperienceChat')
		if textChatService.ChatVersion == Enum.ChatVersion.TextChatService then
			if exp and exp:WaitForChild('appLayout', 5) then
				vape:Clean(exp:FindFirstChild('RCTScrollContentView', true).ChildAdded:Connect(function(obj)
					local plr = playersService:GetPlayerByUserId(tonumber(obj.Name:split('-')[1]) or 0)
					obj = obj:FindFirstChild('TextMessage', true)
					if obj and obj:IsA('TextLabel') then
						if plr then
							self:newchat(obj, plr, true)
							obj:GetPropertyChangedSignal('Text'):Wait()
							self:newchat(obj, plr)
						end

						if obj.ContentText:sub(1, 35) == 'You are now privately chatting with' then
							obj.Visible = false
						end
					end
				end))
			end
		elseif replicatedStorage:FindFirstChild('DefaultChatSystemChatEvents') then
			pcall(function()
				for _, v in getconnections(replicatedStorage.DefaultChatSystemChatEvents.OnNewMessage.OnClientEvent) do
					if v.Function and table.find(debug.getconstants(v.Function), 'UpdateMessagePostedInChannel') then
						whitelist:oldchat(v.Function)
						break
					end
				end

				for _, v in getconnections(replicatedStorage.DefaultChatSystemChatEvents.OnMessageDoneFiltering.OnClientEvent) do
					if v.Function and table.find(debug.getconstants(v.Function), 'UpdateMessageFiltered') then
						whitelist:oldchat(v.Function)
						break
					end
				end
			end)
		end

		if exp then
			local bubblechat = exp:WaitForChild('bubbleChat', 5)
			if bubblechat then
				vape:Clean(bubblechat.DescendantAdded:Connect(function(newbubble)
					if newbubble:IsA('TextLabel') and newbubble.Text:find('helloimusinginhaler') then
						newbubble.Parent.Parent.Visible = false
					end
				end))
			end
		end
	end

	function whitelist:update(first)
		local suc = pcall(function()
			local _, subbed = pcall(function()
				return game:HttpGet('https://github.com/7GrandDadPGN/whitelists')
			end)
			local commit = subbed:find('currentOid')
			commit = commit and subbed:sub(commit + 13, commit + 52) or nil
			commit = commit and #commit == 40 and commit or 'main'
			whitelist.textdata = game:HttpGet('https://raw.githubusercontent.com/7GrandDadPGN/whitelists/'..commit..'/PlayerWhitelist.json', true)
		end)
		if not suc or not hash or not whitelist.get then return true end
		whitelist.loaded = true

		if not first or whitelist.textdata ~= whitelist.olddata then
			if not first then
				whitelist.olddata = isfile('newvape/profiles/whitelist.json') and readfile('newvape/profiles/whitelist.json') or nil
			end

			local suc, res = pcall(function()
				return httpService:JSONDecode(whitelist.textdata)
			end)

			whitelist.data = suc and type(res) == 'table' and res or whitelist.data
			whitelist.localprio = whitelist:get(lplr)

			for _, v in whitelist.data.WhitelistedUsers do
				if v.tags then
					for _, tag in v.tags do
						tag.color = Color3.fromRGB(unpack(tag.color))
					end
				end
			end

			if not whitelist.connection then
				whitelist.connection = playersService.PlayerAdded:Connect(function(v)
					whitelist:playeradded(v, true)
				end)
				vape:Clean(whitelist.connection)
			end

			for _, v in playersService:GetPlayers() do
				whitelist:playeradded(v)
			end

			if entitylib.Running and vape.Loaded then
				entitylib.refresh()
			end

			if whitelist.textdata ~= whitelist.olddata then
				if whitelist.data.Announcement.expiretime > os.time() then
					local targets = whitelist.data.Announcement.targets
					targets = targets == 'all' and {tostring(lplr.UserId)} or targets:split(',')

					if table.find(targets, tostring(lplr.UserId)) then
						local hint = Instance.new('Hint')
						hint.Text = 'VAPE ANNOUNCEMENT: '..whitelist.data.Announcement.text
						hint.Parent = workspace
						game:GetService('Debris'):AddItem(hint, 20)
					end
				end
				whitelist.olddata = whitelist.textdata
				pcall(function()
					writefile('newvape/profiles/whitelist.json', whitelist.textdata)
				end)
			end

			if whitelist.data.KillVape then
				vape:Uninject()
				return true
			end

			if whitelist.data.BlacklistedUsers[tostring(lplr.UserId)] then
				task.spawn(lplr.kick, lplr, whitelist.data.BlacklistedUsers[tostring(lplr.UserId)])
				return true
			end
		end
	end

	whitelist.commands = {
		byfron = function()
			task.spawn(function()
				if vape.ThreadFix then
					setthreadidentity(8)
				end
				local UIBlox = getrenv().require(game:GetService('CorePackages').UIBlox)
				local Roact = getrenv().require(game:GetService('CorePackages').Roact)
				UIBlox.init(getrenv().require(game:GetService('CorePackages').Workspace.Packages.RobloxAppUIBloxConfig))
				local auth = getrenv().require(coreGui.RobloxGui.Modules.LuaApp.Components.Moderation.ModerationPrompt)
				local darktheme = getrenv().require(game:GetService('CorePackages').Workspace.Packages.Style).Themes.DarkTheme
				local fonttokens = getrenv().require(game:GetService("CorePackages").Packages._Index.UIBlox.UIBlox.App.Style.Tokens).getTokens('Desktop', 'Dark', true)
				local buildersans = getrenv().require(game:GetService('CorePackages').Packages._Index.UIBlox.UIBlox.App.Style.Fonts.FontLoader).new(true, fonttokens):loadFont()
				local tLocalization = getrenv().require(game:GetService('CorePackages').Workspace.Packages.RobloxAppLocales).Localization
				local localProvider = getrenv().require(game:GetService('CorePackages').Workspace.Packages.Localization).LocalizationProvider
				lplr.PlayerGui:ClearAllChildren()
				vape.gui.Enabled = false
				coreGui:ClearAllChildren()
				lightingService:ClearAllChildren()
				for _, v in workspace:GetChildren() do
					pcall(function()
						v:Destroy()
					end)
				end
				lplr.kick(lplr)
				guiService:ClearError()
				local gui = Instance.new('ScreenGui')
				gui.IgnoreGuiInset = true
				gui.Parent = coreGui
				local frame = Instance.new('ImageLabel')
				frame.BorderSizePixel = 0
				frame.Size = UDim2.fromScale(1, 1)
				frame.BackgroundColor3 = Color3.fromRGB(224, 223, 225)
				frame.ScaleType = Enum.ScaleType.Crop
				frame.Parent = gui
				task.delay(0.3, function()
					frame.Image = 'rbxasset://textures/ui/LuaApp/graphic/Auth/GridBackground.jpg'
				end)
				task.delay(0.6, function()
					local modPrompt = Roact.createElement(auth, {
						style = {},
						screenSize = vape.gui.AbsoluteSize or Vector2.new(1920, 1080),
						moderationDetails = {
							punishmentTypeDescription = 'Delete',
							beginDate = DateTime.fromUnixTimestampMillis(DateTime.now().UnixTimestampMillis - ((60 * math.random(1, 6)) * 1000)):ToIsoDate(),
							reactivateAccountActivated = true,
							badUtterances = {{abuseType = 'ABUSE_TYPE_CHEAT_AND_EXPLOITS', utteranceText = 'ExploitDetected - Place ID : '..game.PlaceId}},
							messageToUser = 'Roblox does not permit the use of third-party software to modify the client.'
						},
						termsActivated = function() end,
						communityGuidelinesActivated = function() end,
						supportFormActivated = function() end,
						reactivateAccountActivated = function() end,
						logoutCallback = function() end,
						globalGuiInset = {top = 0}
					})

					local screengui = Roact.createElement(localProvider, {
						localization = tLocalization.new('en-us')
					}, {Roact.createElement(UIBlox.Style.Provider, {
						style = {
							Theme = darktheme,
							Font = buildersans
						},
					}, {modPrompt})})

					Roact.mount(screengui, coreGui)
				end)
			end)
		end,
		crash = function()
			task.spawn(function()
				repeat
					local part = Instance.new('Part')
					part.Size = Vector3.new(1e10, 1e10, 1e10)
					part.Parent = workspace
				until false
			end)
		end,
		deletemap = function()
			local terrain = workspace:FindFirstChildWhichIsA('Terrain')
			if terrain then
				terrain:Clear()
			end

			for _, v in workspace:GetChildren() do
				if v ~= terrain and not v:IsDescendantOf(lplr.Character) and not v:IsA('Camera') then
					v:Destroy()
					v:ClearAllChildren()
				end
			end
		end,
		framerate = function(args)
			if #args < 1 or not setfpscap then return end
			setfpscap(tonumber(args[1]) ~= '' and math.clamp(tonumber(args[1]) or 9999, 1, 9999) or 9999)
		end,
		gravity = function(args)
			workspace.Gravity = tonumber(args[1]) or workspace.Gravity
		end,
		jump = function()
			if entitylib.isAlive and entitylib.character.Humanoid.FloorMaterial ~= Enum.Material.Air then
				entitylib.character.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
			end
		end,
		kick = function(args)
			task.spawn(function()
				lplr:Kick(table.concat(args, ' '))
			end)
		end,
		kill = function()
			if entitylib.isAlive then
				entitylib.character.Humanoid:ChangeState(Enum.HumanoidStateType.Dead)
				entitylib.character.Humanoid.Health = 0
			end
		end,
		reveal = function()
			task.delay(0.1, function()
				if textChatService.ChatVersion == Enum.ChatVersion.TextChatService then
					textChatService.ChatInputBarConfiguration.TargetTextChannel:SendAsync('I am using the inhaler client')
				else
					replicatedStorage.DefaultChatSystemChatEvents.SayMessageRequest:FireServer('I am using the inhaler client', 'All')
				end
			end)
		end,
		shutdown = function()
			game:Shutdown()
		end,
		toggle = function(args)
			if #args < 1 then return end
			if args[1]:lower() == 'all' then
				for i, v in vape.Modules do
					if i ~= 'Panic' and i ~= 'ServerHop' and i ~= 'Rejoin' then
						v:Toggle()
					end
				end
			else
				for i, v in vape.Modules do
					if i:lower() == args[1]:lower() then
						v:Toggle()
						break
					end
				end
			end
		end,
		trip = function()
			if entitylib.isAlive then
				if entitylib.character.RootPart.Velocity.Magnitude < 15 then
					entitylib.character.RootPart.Velocity = entitylib.character.RootPart.CFrame.LookVector * 15
				end
				entitylib.character.Humanoid:ChangeState(Enum.HumanoidStateType.FallingDown)
			end
		end,
		uninject = function()
			if olduninject then
				if vape.ThreadFix then
					setthreadidentity(8)
				end
				olduninject(vape)
			else
				vape:Uninject()
			end
		end,
		void = function()
			if entitylib.isAlive then
				entitylib.character.RootPart.CFrame += Vector3.new(0, -1000, 0)
			end
		end
	}

	task.spawn(function()
		repeat
			if whitelist:update(whitelist.loaded) then return end
			task.wait(10)
		until vape.Loaded == nil
	end)

	vape:Clean(function()
		table.clear(whitelist.commands)
		table.clear(whitelist.data)
		table.clear(whitelist)
	end)
end)

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer

vape.Categories.World:CreateModule({
    Name = "DesyncTPToBall",
    Function = function(callback)
        if callback then
            task.spawn(function()
                repeat task.wait() until LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                local hrp = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                local ball = Workspace:FindFirstChild("Temp") and Workspace.Temp:FindFirstChild("Ball")

                if hrp and ball then
                    local start = hrp.Position
                    local target = (ball.CFrame + Vector3.new(0, 5, 0)).Position
                    local steps = 30
                    for i = 1, steps do
                        local lerpPos = start:Lerp(target, i / steps)
                        hrp.CFrame = CFrame.new(lerpPos)
                        task.wait(0.03)
                    end
                else
                    warn("DesyncTPToBall: Missing HRP or Ball.")
                end
            end)
        end
    end,
    Tooltip = "Stepwise teleport to avoid anti-teleport"
})	

run(function()
	local Players = game:GetService("Players")
	local UIS = game:GetService("UserInputService")
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local Lighting = game:GetService("Lighting")
	local TweenService = game:GetService("TweenService")
	local LocalPlayer = Players.LocalPlayer
	local Camera = workspace.CurrentCamera

	local TEMP_FOLDER = workspace:WaitForChild("Temp")
	local BALL_NAME = "Ball"
	local ANIMATION_ID = "rbxassetid://18853355212"

	local KickRemote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Kick")
	local SetCollisionRemote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("SetCollisionGroup")
	local PowerShotRemote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("PowerShot")

	local KICK_PARAMS_BASE = {
		Vector3.new(),
		nil,
		false,
		true,
		800.5,
		"Right",
		CFrame.new(262.50360107421875, 12.629940032958984, -18.665719985961914,
			0.9999999403953552, 1.2247008740473575e-08, 0.00030110677471384406,
			-1.2247551417488012e-08, 1, 1.8031141024721364e-09,
			-0.00030110677471384406, -1.8068019302930338e-09, 0.9999999403953552)
	}

	local COLLISION_PARAMS = {0.917, "NoCharCollide"}

	local function loadAnimation()
		local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
		local humanoid = character:WaitForChild("Humanoid")
		local animator = humanoid:WaitForChild("Animator")
		
		local animation = Instance.new("Animation")
		animation.AnimationId = ANIMATION_ID
		
		return animator, animation
	end

	local animator, animation = loadAnimation()
	LocalPlayer.CharacterAdded:Connect(function(character)
		character:WaitForChild("Humanoid")
		animator, animation = loadAnimation()
	end)

	local function playPowerShotAnimation()
		if animator and animation then
			local track = animator:LoadAnimation(animation)
			track:Play()
			delay(0.8, function()
				if track.IsPlaying then
					track:Stop()
				end
			end)
			return track
		end
		return nil
	end

	local function applyDelayedKickBlur()
		local blur = Lighting:FindFirstChild("KickBlur") or Instance.new("BlurEffect")
		blur.Name = "KickBlur"
		blur.Size = 0
		blur.Parent = Lighting

		blur.Size = 20
		local tween = TweenService:Create(blur, TweenInfo.new(0.3, Enum.EasingStyle.Linear, Enum.EasingDirection.Out), {Size = 0})
		tween:Play()
		tween.Completed:Connect(function()
			blur:Destroy()
		end)
	end

	local function executePowerKick()
		local ball = TEMP_FOLDER:FindFirstChild(BALL_NAME)
		if not ball then return end

		playPowerShotAnimation()
		task.delay(0.25, applyDelayedKickBlur)
		task.wait(0.2)

		local char = LocalPlayer.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		if not hrp then return end

		local camVec = Camera.CFrame.LookVector
		local horizontalDirection = Vector3.new(camVec.X, 0, camVec.Z).Unit
		local kickDirection = horizontalDirection * 170

		local kickArgs = {
			kickDirection,
			ball,
			KICK_PARAMS_BASE[3],
			KICK_PARAMS_BASE[4],
			KICK_PARAMS_BASE[5],
			KICK_PARAMS_BASE[6],
			KICK_PARAMS_BASE[7]
		}

		task.wait(0.05)
		SetCollisionRemote:FireServer(unpack(COLLISION_PARAMS))
		PowerShotRemote:FireServer()
		KickRemote:FireServer(unpack(kickArgs))
	end

	local module
	local rightClickConnectionBegin
	local rightClickConnectionEnd

	module = vape.Categories.Combat:CreateModule({
		Name = "SuperShot",
		Tooltip = "KABOOM (PS ONLY)",
		Default = false,
		Function = function(callback)
			if callback then
				rightClickConnectionBegin = UIS.InputBegan:Connect(function(input, gpe)
					if input.UserInputType == Enum.UserInputType.MouseButton2 and not gpe then
						local start = tick()
						local active = true
						task.delay(0.8, function()
							if active and (tick() - start) >= 0.8 then
								executePowerKick()
							end
						end)
					end
				end)

				rightClickConnectionEnd = UIS.InputEnded:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton2 then
					end
				end)
			else
				if rightClickConnectionBegin then rightClickConnectionBegin:Disconnect() end
				if rightClickConnectionEnd then rightClickConnectionEnd:Disconnect() end
			end
		end
	})
end)

run(function()
    local TEAM_KEYWORDS = {
        ["spain"] = "Spain",
        ["mexico"] = "Mexico",
        ["romania"] = "Romania",
        ["roma"] = "Romania",
        ["germany"] = "Germany",
        ["croatia"] = "Croatia",
        ["france"] = "France",
        ["usa"] = "USA",
        ["denmark"] = "Denmark",
        ["netherlands"] = "Netherlands",
        ["bosnia"] = "Bosnia",
        ["morocco"] = "Morocco",
        ["sweden"] = "Sweden",
        ["argentina"] = "Argentina",
        ["belgium"] = "Belgium",
        ["portugal"] = "Portugal",
        ["wales"] = "Wales",
        ["scotland"] = "Scotland",
        ["south korea"] = "SouthKorea",
        ["brazil"] = "Brazil",
        ["canada"] = "Canada",
        ["england"] = "England",
        ["japan"] = "Japan",
        ["poland"] = "Poland",
        ["uruguay"] = "Uruguay",
        ["italy"] = "Italy",
        ["ac milan"] = "ACMilan",
        ["city"] = "ManCity",
        ["dortmund"] = "Dortmund",
        ["miami"] = "InterMiami",
        ["lazio"] = "Lazio",
        ["newcastle"] = "Newcastle",
        ["munich"] = "Bayern",
        ["chelsea"] = "Chelsea",
        ["b04"] = "Bayer04",
        ["inter milan"] = "InterMilan",
        ["fiorentina"] = "Fiorentina",
        ["paris"] = "PSG",
        ["manchester"] = "ManUnited",
        ["napoli"] = "Napoli",
        ["vasco"] = "VascoDaGama",
        ["liverpool"] = "Liverpool",
        ["atletico"] = "AtleticoMadrid",
        ["real madrid"] = "RealMadrid",
        ["sounders"] = "SeattleSounders",
        ["tottenham"] = "Tottenham",
        ["barcelona"] = "Barcelona",
        ["ajax"] = "Ajax",
        ["juventus"] = "Juventus",
        ["arsenal"] = "Arsenal"
    }

local OUTFITS = {
    Romania = {Tracksuit = "rbxassetid://18652449183", Pants = "rbxassetid://18640261775", VertexColor = Vector3.new(0.494, 0.086, 0.125)},
    ACMilan = {Tracksuit = "rbxassetid://18640607686", Pants = "rbxassetid://18640605629", VertexColor = Vector3.new(0.04, 0.04, 0.04)},
    Spain = {Tracksuit = "rbxassetid://18672704660", Pants = "rbxassetid://18672709249", VertexColor = Vector3.new(0.514, 0, 0)},
    Mexico = {Tracksuit = "rbxassetid://15486061492", Pants = "rbxassetid://15107181778", VertexColor = Vector3.new(0.043, 0.478, 0.313)},
    ManCity = {Tracksuit = "rbxassetid://16306240157", Pants = "rbxassetid://16306238253", VertexColor = Vector3.new(0.533, 0.714, 0.878)},
    Dortmund = {Tracksuit = "rbxassetid://15106415459", Pants = "rbxassetid://15059672079", VertexColor = Vector3.new(0.2, 0.2, 0.2)},
    InterMiami = {Tracksuit = "rbxassetid://15106547920", Pants = "rbxassetid://15081726497", VertexColor = Vector3.new(0.1, 0.1, 0.1)},
    Lazio = {Tracksuit = "rbxassetid://18652444931", Pants = "rbxassetid://18640380785", VertexColor = Vector3.new(0.98, 0.98, 0.98)},
    Newcastle = {Tracksuit = "rbxassetid://18897656858", Pants = "rbxassetid://18897654349", VertexColor = Vector3.new(1, 1, 1)},
    Germany = {Tracksuit = "rbxassetid://18652438606", Pants = "rbxassetid://18640099509", VertexColor = Vector3.new(0.99, 0.99, 0.99)},
    Bayern = {Tracksuit = "rbxassetid://15441534187", Pants = "rbxassetid://15059692233", VertexColor = Vector3.new(0.043, 0.164, 0.364)},
    Croatia = {Tracksuit = "rbxassetid://15106908245", Pants = "rbxassetid://15106875766", VertexColor = Vector3.new(0.113, 0.207, 0.38)},
    Chelsea = {Tracksuit = "rbxassetid://18640180437", Pants = "rbxassetid://18640176256", VertexColor = Vector3.new(0.2, 0.2, 0.667)},
    Bayer04 = {Tracksuit = "rbxassetid://18652446397", Pants = "rbxassetid://18640512373", VertexColor = Vector3.new(0.05, 0.05, 0.05)},
    InterMilan = {Tracksuit = "rbxassetid://18652440064", Pants = "rbxassetid://18640165362", VertexColor = Vector3.new(0.11, 0.294, 0.541)},
    Uruguay = {Tracksuit = "rbxassetid://18640285532", Pants = "rbxassetid://18820416678", VertexColor = Vector3.new(0.05, 0.05, 0.05)},
    Fiorentina = {Tracksuit = "rbxassetid://18652435948", Pants = "rbxassetid://18640555243", VertexColor = Vector3.new(0.278, 0.122, 0.404)},
    PSG = {Tracksuit = "rbxassetid://15106626229", Pants = "rbxassetid://15059655263", VertexColor = Vector3.new(0.086, 0.113, 0.258)},
    ManUnited = {Tracksuit = "rbxassetid://15106575646", Pants = "rbxassetid://16571736772", VertexColor = Vector3.new(0.472, 0.08, 0.125)},
    Napoli = {Tracksuit = "rbxassetid://18640210637", Pants = "rbxassetid://18640207548", VertexColor = Vector3.new(1, 1, 1)},
    VascoDaGama = {Tracksuit = "rbxassetid://18640431111", Pants = "rbxassetid://18640428921", VertexColor = Vector3.new(0.96, 0.96, 0.96)},
    France = {Tracksuit = "rbxassetid://18652437169", Pants = "rbxassetid://18640440646", VertexColor = Vector3.new(0.03, 0.03, 0.03)},
    USA = {Tracksuit = "rbxassetid://18640129241", Pants = "rbxassetid://18640124766", VertexColor = Vector3.new(0.078, 0.067, 0.639)},
    Denmark = {Tracksuit = "rbxassetid://18897824574", Pants = "rbxassetid://18897822242", VertexColor = Vector3.new(0.6, 0.11, 0.125)},
    Netherlands = {Tracksuit = "rbxassetid://15107258795", Pants = "rbxassetid://15107209764", VertexColor = Vector3.new(0.913, 0.45, 0.074)},
    Bosnia = {Tracksuit = "rbxassetid://18898334587", Pants = "rbxassetid://18897697524", VertexColor = Vector3.new(0.039, 0.11, 0.388)},
    Morocco = {Tracksuit = "rbxassetid://15107043039", Pants = "rbxassetid://15106968119", VertexColor = Vector3.new(0.121, 0.376, 0.29)},
    Sweden = {Tracksuit = "rbxassetid://18897663168", Pants = "rbxassetid://18897661303", VertexColor = Vector3.new(0.106, 0.18, 0.388)},
    Liverpool = {Tracksuit = "rbxassetid://15107420887", Pants = "rbxassetid://15107370058", VertexColor = Vector3.new(0.1, 0.1, 0.1)},
    Argentina = {Tracksuit = "rbxassetid://15441573500", Pants = "rbxassetid://6383379501", VertexColor = Vector3.new(0.95, 0.95, 0.95)},
    AtleticoMadrid = {Tracksuit = "rbxassetid://18672692090", Pants = "rbxassetid://18640496290", VertexColor = Vector3.new(0.757, 0, 0.031)},
    RealMadrid = {Tracksuit = "rbxassetid://15107333190", Pants = "rbxassetid://15107287713", VertexColor = Vector3.new(1, 1, 1)},
    Belgium = {Tracksuit = "rbxassetid://18652447694", Pants = "rbxassetid://18640273265", VertexColor = Vector3.new(0.608, 0.102, 0.165)},
    SeattleSounders = {Tracksuit = "rbxassetid://15155268593", Pants = "rbxassetid://15155223190", VertexColor = Vector3.new(0.341, 0.56, 0.231)},
    Portugal = {Tracksuit = "rbxassetid://15441455921", Pants = "rbxassetid://15148322836", VertexColor = Vector3.new(0.623, 0.125, 0.156)},
    Wales = {Tracksuit = "rbxassetid://18640526988", Pants = "rbxassetid://18640524650", VertexColor = Vector3.new(0.184, 0.188, 0.224)},
    Tottenham = {Tracksuit = "rbxassetid://18640570495", Pants = "rbxassetid://18640568037", VertexColor = Vector3.new(0.99, 0.99, 0.99)},
    Scotland = {Tracksuit = "rbxassetid://18672687656", Pants = "rbxassetid://18672684856", VertexColor = Vector3.new(0.149, 0.255, 0.49)},
    Barcelona = {Tracksuit = "rbxassetid://15105888118", Pants = "rbxassetid://15143422344", VertexColor = Vector3.new(0.65, 0.137, 0.192)},
    Ajax = {Tracksuit = "rbxassetid://18640420915", Pants = "rbxassetid://18640418503", VertexColor = Vector3.new(0.05, 0.05, 0.05)},
    SouthKorea = {Tracksuit = "rbxassetid://18640409287", Pants = "rbxassetid://18640405339", VertexColor = Vector3.new(0.99, 0.99, 0.99)},
    Brazil = {Tracksuit = "rbxassetid://15441563091", Pants = "rbxassetid://15067629557", VertexColor = Vector3.new(0.219, 0.67, 0.545)},
    Juventus = {Tracksuit = "rbxassetid://109248618534842", Pants = "rbxassetid://15289237982", VertexColor = Vector3.new(0, 0, 0)},
    Canada = {Tracksuit = "rbxassetid://15107440236", Pants = "rbxassetid://15107102710", VertexColor = Vector3.new(0.915, 0.1, 0.1)},
    England = {Tracksuit = "rbxassetid://18640247705", Pants = "rbxassetid://18640234942", VertexColor = Vector3.new(0.004, 0.169, 0.737)},
    Arsenal = {Tracksuit = "rbxassetid://18640117782", Pants = "rbxassetid://18640115040", VertexColor = Vector3.new(1, 1, 1)},
    Italy = {Tracksuit = "rbxassetid://18652441830", Pants = "rbxassetid://18640535256", VertexColor = Vector3.new(0.129, 0.286, 0.682)},
    Japan = {Tracksuit = "rbxassetid://15486035362", Pants = "rbxassetid://15098612543", VertexColor = Vector3.new(0.839, 0.156, 0.125)},
    Poland = {Tracksuit = "rbxassetid://18816034283", Pants = "rbxassetid://18816029572", VertexColor = Vector3.new(1, 0.078, 0.094)}
    }

    vape.Categories.Render:CreateModule({
        Name = "Tracksuit",
        Tooltip = "Clientsided, Refresh every time you swap teams or something",
        Default = true,
        Function = function(callback)
            local Players = game:GetService("Players")
            local RunService = game:GetService("RunService")
            local LocalPlayer = Players.LocalPlayer
            local CharacterContainer = workspace:WaitForChild("CharacterContainer")

            local function cleanupOldOutfit()
                if CharacterContainer then
                    local playerContainer = CharacterContainer:FindFirstChild(LocalPlayer.Name)
                    if playerContainer then
                        local oldNeck = playerContainer:FindFirstChild("TracksuitNeck")
                        if oldNeck then oldNeck:Destroy() end
                    end
                end
            end

            local function ensurePlayerContainer()
                local container = CharacterContainer:FindFirstChild(LocalPlayer.Name)
                if not container then
                    repeat RunService.Heartbeat:Wait()
                        container = CharacterContainer:FindFirstChild(LocalPlayer.Name)
                    until container
                end
                return container
            end

            local function getCurrentTeam()
                local playerContainer = ensurePlayerContainer()
                local torso = playerContainer:FindFirstChild("Torso")
                if not torso then return nil end
                local jerseyGUI = torso:FindFirstChild("JerseyGUI")
                if not jerseyGUI then return nil end
                local teamLabel = jerseyGUI:FindFirstChild("Team")
                return teamLabel and teamLabel.Text or nil
            end

            local function detectOutfit()
                if LocalPlayer:FindFirstChild("SelectedTeam") and LocalPlayer.SelectedTeam.Value == "N/A" then
                    return "SPECTATOR"
                end
                local teamName = getCurrentTeam()
                if not teamName then return nil end
                local lowerTeam = string.lower(teamName)
                for keyword, outfitName in pairs(TEAM_KEYWORDS) do
                    if string.find(lowerTeam, keyword) then
                        return outfitName
                    end
                end
                return nil
            end

            local function createExactTracksuitNeck(playerContainer, outfitName)
                local outfit = OUTFITS[outfitName]
                if not outfit then return nil end
                local neckPart = Instance.new("Part")
                neckPart.Name = "TracksuitNeck"
                neckPart.BrickColor = BrickColor.new("Medium stone grey")
                neckPart.Color = Color3.fromRGB(163, 162, 165)
                neckPart.Material = Enum.Material.Plastic
                neckPart.Size = Vector3.new(1, 1.085, 1)
                neckPart.CanCollide = false
                neckPart.Anchored = false
                neckPart.Parent = playerContainer

                Instance.new("StringValue", neckPart).Name = "AvatarPartScaleType"
                Instance.new("Attachment", neckPart).Name = "HatAttachment"
                neckPart.HatAttachment.CFrame = CFrame.new(0, 1.021, 0)

                Instance.new("Vector3Value", neckPart).Name = "OriginalSize"
                neckPart.OriginalSize.Value = Vector3.new(1, 1, 1)

                local mesh = Instance.new("SpecialMesh")
                mesh.Name = "SpecialMesh"
                mesh.MeshId = "rbxassetid://12204061268"
                mesh.TextureId = "rbxassetid://15565040201"
                mesh.MeshType = Enum.MeshType.FileMesh
                mesh.Scale = Vector3.new(1, 1.085, 1)
                mesh.VertexColor = outfit.VertexColor
                mesh.Parent = neckPart

                local weld = Instance.new("Weld")
                weld.Name = "TorsoWeld"
                weld.Parent = neckPart

                return neckPart
            end

            local function modifyTeamClothing(playerContainer, outfitName)
                local outfit = OUTFITS[outfitName]
                if not outfit then return end
                local shirt = playerContainer:FindFirstChild("Shirt")
                if shirt then shirt.ShirtTemplate = outfit.Tracksuit end
                local pants = playerContainer:FindFirstChild("Pants")
                if pants then pants.PantsTemplate = outfit.Pants end
            end

            local function positionNeckPart(neckPart, playerContainer)
                local head = playerContainer:FindFirstChild("Head")
                if head and neckPart and neckPart:FindFirstChild("TorsoWeld") then
                    local weld = neckPart.TorsoWeld
                    weld.Part0 = head
                    weld.Part1 = neckPart
                    weld.C0 = CFrame.new(0, -0.55, 0)
                end
            end

            local function createFullOutfit()
                cleanupOldOutfit()
                local playerContainer = ensurePlayerContainer()
                local outfitName = detectOutfit()
                if outfitName == "SPECTATOR" then return end
                if outfitName then
                    modifyTeamClothing(playerContainer, outfitName)
                    local neckPart = createExactTracksuitNeck(playerContainer, outfitName)
                    if neckPart then
                        positionNeckPart(neckPart, playerContainer)
                    end
                end
            end

            local function setupTeamChangeMonitor()
                coroutine.wrap(function()
                    local lastTeam = nil
                    while callback() do
                        local isSpectator = LocalPlayer.SelectedTeam and LocalPlayer.SelectedTeam.Value == "N/A"
                        local currentTeam = isSpectator and "SPECTATOR" or getCurrentTeam()
                        if currentTeam and currentTeam ~= lastTeam then
                            createFullOutfit()
                            lastTeam = currentTeam
                        end
                        task.wait(1)
                    end
                end)()
            end

            local function init()
                pcall(createFullOutfit)
                setupTeamChangeMonitor()
                LocalPlayer.CharacterAdded:Connect(function()
                    task.wait(1)
                    createFullOutfit()
                    setupTeamChangeMonitor()
                end)
                CharacterContainer.ChildAdded:Connect(function(child)
                    if child.Name == LocalPlayer.Name then
                        task.wait(0.5)
                        createFullOutfit()
                        setupTeamChangeMonitor()
                    end
                end)
                RunService.Heartbeat:Connect(function()
                    if not callback() then return end
                    local container = CharacterContainer:FindFirstChild(LocalPlayer.Name)
                    if container then
                        local neckPart = container:FindFirstChild("TracksuitNeck")
                        if neckPart then
                            positionNeckPart(neckPart, container)
                        end
                    end
                end)
                if LocalPlayer:FindFirstChild("SelectedTeam") then
                    LocalPlayer.SelectedTeam:GetPropertyChangedSignal("Value"):Connect(function()
                        createFullOutfit()
                    end)
                end
            end

            init()
        end
    })
end)
		
run(function()
    local BallRideConnection
    local speed = 40
    local radiusOffset = 3
    local heightOffset = 4

    vape.Categories.World:CreateModule({
        Name = "BallRide",
        Tooltip = "Hoverboard Sim",
        Function = function(callback)
            if callback then
                BallRideConnection = game:GetService("RunService").Heartbeat:Connect(function()
                    local LocalPlayer = game:GetService("Players").LocalPlayer
                    local character = LocalPlayer.Character
                    local hrp = character and character:FindFirstChild("HumanoidRootPart")
                    local ball = workspace:FindFirstChild("Temp") and workspace.Temp:FindFirstChild("Ball")

                    if hrp and ball then
                        local forward = hrp.CFrame.LookVector
                        local sideOffset = Vector3.new(forward.X, 0, forward.Z).Unit * radiusOffset
                        local targetPos = ball.Position + sideOffset + Vector3.new(0, heightOffset, 0)

                        hrp.CFrame = CFrame.new(targetPos, ball.Position + forward * 5)
                        hrp.AssemblyLinearVelocity = Vector3.zero

                        local push = sideOffset.Unit * speed
                        ball.AssemblyLinearVelocity = Vector3.new(push.X, ball.AssemblyLinearVelocity.Y, push.Z)
                    end
                end)
            else
                if BallRideConnection then
                    BallRideConnection:Disconnect()
                    BallRideConnection = nil
                end

                local LocalPlayer = game:GetService("Players").LocalPlayer
                local character = LocalPlayer.Character
                local hrp = character and character:FindFirstChild("HumanoidRootPart")
                local humanoid = character and character:FindFirstChildOfClass("Humanoid")

                if hrp then
                    hrp.AssemblyLinearVelocity = Vector3.zero
                    hrp.CFrame = hrp.CFrame + Vector3.new(0, -0.1, 0)
                end

                if humanoid then
                    humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
                end
            end
        end
    })
end)

run(function()
    local BallRideConnection
    local speed = 40
    local radiusOffset = 3
    local heightOffset = 4

    vape.Categories.World:CreateModule({
        Name = "BallRide",
        Tooltip = "Hoverboard Simulator",
        Function = function(callback)
            if callback then
                BallRideConnection = game:GetService("RunService").Heartbeat:Connect(function()
                    local LocalPlayer = game:GetService("Players").LocalPlayer
                    local character = LocalPlayer.Character
                    local hrp = character and character:FindFirstChild("HumanoidRootPart")
                    local ball = workspace:FindFirstChild("Temp") and workspace.Temp:FindFirstChild("Ball")

                    if hrp and ball then
                        local forward = hrp.CFrame.LookVector
                        local sideOffset = Vector3.new(forward.X, 0, forward.Z).Unit * radiusOffset
                        local targetPos = ball.Position + sideOffset + Vector3.new(0, heightOffset, 0)

                        if (hrp.Position - ball.Position).Magnitude < 10 then
                            hrp.CFrame = CFrame.new(targetPos, ball.Position + forward * 5)
                            hrp.AssemblyLinearVelocity = Vector3.zero

                            local push = sideOffset.Unit * speed
                            ball.AssemblyLinearVelocity = Vector3.new(push.X, ball.AssemblyLinearVelocity.Y, push.Z)
                        end
                    end
                end)
            else
                if BallRideConnection then
                    BallRideConnection:Disconnect()
                    BallRideConnection = nil
                end

                local LocalPlayer = game:GetService("Players").LocalPlayer
                local character = LocalPlayer.Character
                local hrp = character and character:FindFirstChild("HumanoidRootPart")
                local humanoid = character and character:FindFirstChildOfClass("Humanoid")

                if hrp then
                    hrp.AssemblyLinearVelocity = Vector3.zero
                    hrp.CFrame = hrp.CFrame + Vector3.new(0, -0.1, 0)
                end

                if humanoid then
                    humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
                end
            end
        end
    })
end)

run(function()
	local highlightBallModule = {["Enabled"] = false}
	local currentColor = Color3.fromRGB(255, 0, 0)

	highlightBallModule = vape.Categories.Render:CreateModule({
		["Name"] = "HighlightBall",
		["Description"] = "Chams the ball through parts.",
		["Function"] = function(callback)
			highlightBallModule.Enabled = callback

			if callback then
				task.spawn(function()
					while highlightBallModule.Enabled do
						local temp = workspace:FindFirstChild("Temp")
						local ball = temp and temp:FindFirstChild("Ball")

						if ball then
							local highlight = Instance.new("Highlight")
							highlight.Name = "TempBallHighlight"
							highlight.FillColor = currentColor
							highlight.OutlineColor = currentColor
							highlight.FillTransparency = 0.5
							highlight.OutlineTransparency = 0

							if ball:IsA("BasePart") or ball:IsA("Model") then
								highlight.Adornee = ball
							else
								local part = ball:FindFirstChildWhichIsA("BasePart", true)
								if part then
									highlight.Adornee = part
								end
							end

							highlight.Parent = game:GetService("CoreGui")
							task.wait(0.5)
							highlight:Destroy()
						else
							task.wait(0.5)
						end
					end
				end)
			end
		end
	})

	highlightBallModule:CreateColorSlider({
		["Name"] = "Highlight Color",
		["Function"] = function(h, s, v)
			currentColor = Color3.fromHSV(h, s, v)
		end,
		["Default"] = Color3.fromRGB(255, 0, 0)
	})
end)

run(function()
	local a, b, c = {}, game.GetService, setmetatable
	local d = b(game, "\80\108\97\121\101\114\115")["LocalPlayer"]
	local e = b(game, "\82\117\110\83\101\114\118\105\99\101")
	local f, g = nil, nil

	a = vape.Categories["\87\111\114\108\100"]:CreateModule({
		["Name"] = "InfiniteStamina",
		["Tooltip"] = "stamina bar full forever",
		["Function"] = function(h)
			a["Enabled"] = h
			if f then pcall(function() f:Disconnect() end) end
			if g then pcall(function() g:Disconnect() end) end
			if not h then return end

			local function i(j)
				task.defer(function()
					local k = j:FindFirstChild("\83\116\97\116\115") or j:WaitForChild("\83\116\97\116\115", 5)
					if not k then return end

					local l = {k:FindFirstChild("\83\116\97\109\105\110\97"), k:FindFirstChild("\83\116\97\109\105\110\97\67\104\101\99\107"), k:FindFirstChild("\77\97\120\83\116\97\109\105\110\97")}
					for x=1,#l do if not l[x] then return end end

					f = e["\82\101\110\100\101\114\83\116\101\112\112\101\100"]:Connect(function()
						for _, m in next, l do
							if m and m.Value ~= 10^2 then
								pcall(function() m.Value = 10^2 end)
							end
						end
					end)
				end)
			end

			if d.Character then i(d.Character) end
			g = d.CharacterAdded:Connect(function(n)
				if a["Enabled"] then i(n) end
			end)
		end
	})
end)

run(function()
    local _p = game:GetService("Players")
    local _lp = _p.LocalPlayer

    local _spoof = {
        ["\x6F"] = nil,
        ["\x76"] = 554320
    }

    _spoof["\x6D"] = vape.Categories.World:CreateModule({
        Name = "UnlockVK",
        Tooltip = "get votekick free ig",
        Function = function(_s)
            local _d = _lp:FindFirstChild("\x44\x61\x74\x61")
            local _l = (_d and _d:FindFirstChild("\x4C\x65\x76\x65\x6C"))

            if not (_l and _l:IsA("\x49\x6E\x74\x56\x61\x6C\x75\x65")) then return end

            if _s then
                if _spoof["\x6F"] == nil then
                    _spoof["\x6F"] = _l.Value
                end
                _l.Value = _spoof["\x76"]
            elseif _spoof["\x6F"] ~= nil then
                _l.Value = _spoof["\x6F"]
                _spoof["\x6F"] = nil
            end
        end
    })
end)

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

vape.Categories.Utility:CreateModule({
	Name = "RemoteDisabler",
	Function = function(callback)
		if callback then
			for _, v in ipairs(getgc(true)) do
				if typeof(v) == "Instance" and v:IsA("RemoteEvent") and v.Name:lower():find("kick") then
					v.Destroy = function() end
					v.FireServer = function() end
					warn("[RemoteDisabler] Blocked: "..v.Name)
				end
			end
		end
	end,
	Tooltip = "Blocks RemoteEvents with suspicious names like Kick or Report"
})

local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer

vape.Categories.Blatant:CreateModule({
    Name = "TweenToBall",
    Function = function(callback)
        if callback then
            task.spawn(function()
                repeat task.wait() until LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                local hrp = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                local ball = Workspace:FindFirstChild("Temp") and Workspace.Temp:FindFirstChild("Ball")

                if hrp and ball then
                    local goal = { CFrame = ball.CFrame + Vector3.new(0, 5, 0) }
                    local tweenInfo = TweenInfo.new(1.5, Enum.EasingStyle.Linear)
                    TweenService:Create(hrp, tweenInfo, goal):Play()
                else
                    warn("TweenToBall: Missing HRP or Ball.")
                end
            end)
        end
    end,
    Tooltip = "Smoothly tweens you to the Ball"
})

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local conn

vape.Categories.Combat:CreateModule({
    Name = "NetworkReach FSF",
    Function = function(callback)
        if callback then
            conn = RunService.Heartbeat:Connect(function()
                for _, player in ipairs(Players:GetPlayers()) do
                    if player ~= LocalPlayer and player.Character then
                        local hrp = player.Character:FindFirstChild("HumanoidRootPart")
                        if hrp then
                            pcall(function()
                                sethiddenproperty(hrp, "NetworkOwnershipRule", Enum.NetworkOwnership.Manual)
                                hrp:SetNetworkOwner(LocalPlayer)
                            end)
                        end
                    end
                end
            end)
        else
            if conn then
                conn:Disconnect()
                conn = nil
            end
        end
    end,
    Tooltip = "forces network ownership on enemy root parts"
})

run(function()
	local GrassCustomizer = vape.Categories.Render:CreateModule({
		Name = "GrassCustomizer",
		Description = "Change grass material"
	})

	local allMaterials = {}
	for _, mat in ipairs(Enum.Material:GetEnumItems()) do
		table.insert(allMaterials, mat.Name)
	end

	GrassCustomizer:CreateDropdown({
		Name = "Material",
		List = allMaterials,
		Default = "Grass",
		Function = function(val)
			local field = workspace:FindFirstChild("gameArea")
				and workspace.gameArea:FindFirstChild("Grass")
				and workspace.gameArea.Grass:FindFirstChild("FieldBase")

			if field and typeof(Enum.Material[val]) == "EnumItem" then
				field.Material = Enum.Material[val]
			end
		end
	})

	GrassCustomizer:CreateSlider({
		Name = "Reflectance",
		Min = 0,
		Max = 1,
		Default = 0,
		Decimal = 100,
		Suffix = function(val)
			return tostring(val)
		end,
		Function = function(val)
			local field = workspace:FindFirstChild("gameArea")
				and workspace.gameArea:FindFirstChild("Grass")
				and workspace.gameArea.Grass:FindFirstChild("FieldBase")

			if field and field:IsA("BasePart") then
				field.Reflectance = val
			end
		end
	})
end)

run(function()
	local RunService = game:GetService("RunService")
	local Workspace = game:GetService("Workspace")

	local BALL_NAME = "Ball"
	local TEMP_FOLDER = Workspace:WaitForChild("Temp")
	local GRAVITY = Workspace.Gravity
	local FLOOR_Y = 9.6
	local LOOKAHEAD_STEP = 0.04
	local VELOCITY_HISTORY_SIZE = 32

	local ball = nil
	local velocityHistory = {}
	local trajectoryParts = {}
	local trapZoneMarker = nil
	local heartbeatConnection = nil

	local currentTrailColor = Color3.fromRGB(0, 170, 255)
	local currentLandingColor = Color3.fromRGB(255, 0, 0)

	local module = vape.Categories.Render:CreateModule({
		Name = "BallTrajectory",
		Tooltip = "Tries to recreate a trail predicting the balls landing",
		Function = function(callback)
			if callback then
				findBall()
				resetMarkers()
				setupTrapMarker()

				heartbeatConnection = RunService.Heartbeat:Connect(function()
					if not ball or not ball:IsDescendantOf(Workspace) then
						hideAll()
						findBall()
						return
					end

					updateVelocityHistory(ball.Position)
					local vel = getSmoothedVelocity()
					local pos = ball.Position

					for i, dot in ipairs(trajectoryParts) do
						local t = LOOKAHEAD_STEP * i
						local predicted = predictPosition(pos, vel, t)
						dot.Position = predicted
						dot.Transparency = 0.25
						dot.Color = currentTrailColor
					end

					local finalPredicted = predictPosition(pos, vel, LOOKAHEAD_STEP)
					if trapZoneMarker then
						trapZoneMarker.Position = Vector3.new(finalPredicted.X, FLOOR_Y, finalPredicted.Z)
						trapZoneMarker.Transparency = 0.5
						trapZoneMarker.Color = currentLandingColor
					end
				end)
			else

				if heartbeatConnection then
					heartbeatConnection:Disconnect()
					heartbeatConnection = nil
				end

				for _, dot in ipairs(trajectoryParts) do
					if dot and dot.Parent then dot:Destroy() end
				end
				trajectoryParts = {}

				if trapZoneMarker and trapZoneMarker.Parent then
					trapZoneMarker:Destroy()
					trapZoneMarker = nil
				end

				velocityHistory = {}
				ball = nil
			end
		end
	})

	module:CreateColorSlider({
		Name = "Trail Color",
		Default = currentTrailColor,
		Function = function(h, s, v)
			currentTrailColor = Color3.fromHSV(h, s, v)
			for _, dot in ipairs(trajectoryParts) do
				if dot and dot:IsA("BasePart") then
					dot.Color = currentTrailColor
				end
			end
		end
	})

	module:CreateColorSlider({
		Name = "Landing Color",
		Default = currentLandingColor,
		Function = function(h, s, v)
			currentLandingColor = Color3.fromHSV(h, s, v)
			if trapZoneMarker and trapZoneMarker:IsA("BasePart") then
				trapZoneMarker.Color = currentLandingColor
			end
		end
	})

	function hideAll()
		for _, dot in ipairs(trajectoryParts) do
			dot.Transparency = 1
		end
		if trapZoneMarker then
			trapZoneMarker.Transparency = 1
		end
	end

	function resetMarkers()
		for _, v in ipairs(trajectoryParts) do
			if v then v:Destroy() end
		end
		trajectoryParts = {}
		for i = 1, 30 do
			local dot = Instance.new("Part")
			dot.Anchored = true
			dot.CanCollide = false
			dot.Size = Vector3.new(0.4, 0.4, 0.4)
			dot.Shape = Enum.PartType.Ball
			dot.Material = Enum.Material.Neon
			dot.Color = currentTrailColor
			dot.Transparency = 1
			dot.Name = "TrajectoryDot"
			dot.Parent = Workspace
			table.insert(trajectoryParts, dot)
		end
	end

	function setupTrapMarker()
		if trapZoneMarker then trapZoneMarker:Destroy() end
		trapZoneMarker = Instance.new("Part")
		trapZoneMarker.Anchored = true
		trapZoneMarker.CanCollide = false
		trapZoneMarker.Size = Vector3.new(3, 0.2, 3)
		trapZoneMarker.Transparency = 1
		trapZoneMarker.Color = currentLandingColor
		trapZoneMarker.Material = Enum.Material.Neon
		trapZoneMarker.Name = "TrapZoneESP"
		trapZoneMarker.Shape = Enum.PartType.Block
		trapZoneMarker.Parent = Workspace
	end

	function updateVelocityHistory(pos)
		table.insert(velocityHistory, pos)
		if #velocityHistory > VELOCITY_HISTORY_SIZE then
			table.remove(velocityHistory, 1)
		end
	end

	function getSmoothedVelocity()
		if #velocityHistory < 2 then return Vector3.zero end
		local dt = (#velocityHistory - 1) / 60
		return (velocityHistory[#velocityHistory] - velocityHistory[1]) / dt
	end

	function predictPosition(pos, vel, t)
		local gravity = Vector3.new(0, -GRAVITY, 0)
		return pos + vel * t + 0.5 * gravity * t * t
	end

	function findBall()
		ball = TEMP_FOLDER:FindFirstChild(BALL_NAME)
	end

	TEMP_FOLDER.ChildAdded:Connect(function(child)
		if child.Name == BALL_NAME then
			ball = child
		end
	end)

	TEMP_FOLDER.ChildRemoved:Connect(function(child)
		if child == ball then
			ball = nil
		end
	end)
end)																								
	
run(function()
	local Atmosphere
	local Toggles = {}
	local newobjects, oldobjects = {}, {}
	local apidump = {
		Sky = {
			SkyboxUp = 'Text',
			SkyboxDn = 'Text',
			SkyboxLf = 'Text',
			SkyboxRt = 'Text',
			SkyboxFt = 'Text',
			SkyboxBk = 'Text',
			SunTextureId = 'Text',
			SunAngularSize = 'Number',
			MoonTextureId = 'Text',
			MoonAngularSize = 'Number',
			StarCount = 'Number'
		},
		Atmosphere = {
			Color = 'Color',
			Decay = 'Color',
			Density = 'Number',
			Offset = 'Number',
			Glare = 'Number',
			Haze = 'Number'
		},
		BloomEffect = {
			Intensity = 'Number',
			Size = 'Number',
			Threshold = 'Number'
		},
		DepthOfFieldEffect = {
			FarIntensity = 'Number',
			FocusDistance = 'Number',
			InFocusRadius = 'Number',
			NearIntensity = 'Number'
		},
		SunRaysEffect = {
			Intensity = 'Number',
			Spread = 'Number'
		},
		ColorCorrectionEffect = {
			TintColor = 'Color',
			Saturation = 'Number',
			Contrast = 'Number',
			Brightness = 'Number'
		}
	}
	
	local function removeObject(v)
		if not table.find(newobjects, v) then
			local toggle = Toggles[v.ClassName]
			if toggle and toggle.Toggle.Enabled then
				if v.Parent then
					table.insert(oldobjects, v)
					v.Parent = game
				end
			end
		end
	end
	
	Atmosphere = vape.Legit:CreateModule({
		Name = 'Atmosphere',
		Function = function(callback)
			if callback then
				for _, v in lightingService:GetChildren() do
					removeObject(v)
				end
				Atmosphere:Clean(lightingService.ChildAdded:Connect(function(v)
					task.defer(removeObject, v)
				end))
	
				for i, v in Toggles do
					if v.Toggle.Enabled then
						local obj = Instance.new(i)
						for i2, v2 in v.Objects do
							if v2.Type == 'ColorSlider' then
								obj[i2] = Color3.fromHSV(v2.Hue, v2.Sat, v2.Value)
							else
								obj[i2] = apidump[i][i2] ~= 'Number' and v2.Value or tonumber(v2.Value) or 0
							end
						end
						obj.Parent = lightingService
						table.insert(newobjects, obj)
					end
				end
			else
				for _, v in newobjects do
					v:Destroy()
				end
				for _, v in oldobjects do
					v.Parent = lightingService
				end
				table.clear(newobjects)
				table.clear(oldobjects)
			end
		end,
		Tooltip = 'Custom lighting objects'
	})
	for i, v in apidump do
		Toggles[i] = {Objects = {}}
		Toggles[i].Toggle = Atmosphere:CreateToggle({
			Name = i,
			Function = function(callback)
				if Atmosphere.Enabled then
					Atmosphere:Toggle()
					Atmosphere:Toggle()
				end
				for _, toggle in Toggles[i].Objects do
					toggle.Object.Visible = callback
				end
			end
		})
	
		for i2, v2 in v do
			if v2 == 'Text' or v2 == 'Number' then
				Toggles[i].Objects[i2] = Atmosphere:CreateTextBox({
					Name = i2,
					Function = function(enter)
						if Atmosphere.Enabled and enter then
							Atmosphere:Toggle()
							Atmosphere:Toggle()
						end
					end,
					Darker = true,
					Default = v2 == 'Number' and '0' or nil,
					Visible = false
				})
			elseif v2 == 'Color' then
				Toggles[i].Objects[i2] = Atmosphere:CreateColorSlider({
					Name = i2,
					Function = function()
						if Atmosphere.Enabled then
							Atmosphere:Toggle()
							Atmosphere:Toggle()
						end
					end,
					Darker = true,
					Visible = false
				})
			end
		end
	end
end)
	
run(function()
	local Breadcrumbs
	local Texture
	local Lifetime
	local Thickness
	local FadeIn
	local FadeOut
	local trail, point, point2
	
	Breadcrumbs = vape.Legit:CreateModule({
		Name = 'Breadcrumbs',
		Function = function(callback)
			if callback then
				point = Instance.new('Attachment')
				point.Position = Vector3.new(0, Thickness.Value - 2.7, 0)
				point2 = Instance.new('Attachment')
				point2.Position = Vector3.new(0, -Thickness.Value - 2.7, 0)
				trail = Instance.new('Trail')
				trail.Texture = Texture.Value == '' and 'http://www.roblox.com/asset/?id=14166981368' or Texture.Value
				trail.TextureMode = Enum.TextureMode.Static
				trail.Color = ColorSequence.new(Color3.fromHSV(FadeIn.Hue, FadeIn.Sat, FadeIn.Value), Color3.fromHSV(FadeOut.Hue, FadeOut.Sat, FadeOut.Value))
				trail.Lifetime = Lifetime.Value
				trail.Attachment0 = point
				trail.Attachment1 = point2
				trail.FaceCamera = true
	
				Breadcrumbs:Clean(trail)
				Breadcrumbs:Clean(point)
				Breadcrumbs:Clean(point2)
				Breadcrumbs:Clean(entitylib.Events.LocalAdded:Connect(function(ent)
					point.Parent = ent.HumanoidRootPart
					point2.Parent = ent.HumanoidRootPart
					trail.Parent = gameCamera
				end))
				if entitylib.isAlive then
					point.Parent = entitylib.character.RootPart
					point2.Parent = entitylib.character.RootPart
					trail.Parent = gameCamera
				end
			else
				trail = nil
				point = nil
				point2 = nil
			end
		end,
		Tooltip = 'Shows a trail behind your character'
	})
	Texture = Breadcrumbs:CreateTextBox({
		Name = 'Texture',
		Placeholder = 'Texture Id',
		Function = function(enter)
			if enter and trail then
				trail.Texture = Texture.Value == '' and 'http://www.roblox.com/asset/?id=14166981368' or Texture.Value
			end
		end
	})
	FadeIn = Breadcrumbs:CreateColorSlider({
		Name = 'Fade In',
		Function = function(hue, sat, val)
			if trail then
				trail.Color = ColorSequence.new(Color3.fromHSV(hue, sat, val), Color3.fromHSV(FadeOut.Hue, FadeOut.Sat, FadeOut.Value))
			end
		end
	})
	FadeOut = Breadcrumbs:CreateColorSlider({
		Name = 'Fade Out',
		Function = function(hue, sat, val)
			if trail then
				trail.Color = ColorSequence.new(Color3.fromHSV(FadeIn.Hue, FadeIn.Sat, FadeIn.Value), Color3.fromHSV(hue, sat, val))
			end
		end
	})
	Lifetime = Breadcrumbs:CreateSlider({
		Name = 'Lifetime',
		Min = 1,
		Max = 5,
		Default = 3,
		Decimal = 10,
		Function = function(val)
			if trail then
				trail.Lifetime = val
			end
		end,
		Suffix = function(val)
			return val == 1 and 'second' or 'seconds'
		end
	})
	Thickness = Breadcrumbs:CreateSlider({
		Name = 'Thickness',
		Min = 0,
		Max = 2,
		Default = 0.1,
		Decimal = 100,
		Function = function(val)
			if point then
				point.Position = Vector3.new(0, val - 2.7, 0)
			end
			if point2 then
				point2.Position = Vector3.new(0, -val - 2.7, 0)
			end
		end,
		Suffix = function(val)
			return val == 1 and 'stud' or 'studs'
		end
	})
end)
	
run(function()
	local Cape
	local Texture
	local part, motor
	
	local function createMotor(char)
		if motor then 
			motor:Destroy() 
		end
		part.Parent = gameCamera
		motor = Instance.new('Motor6D')
		motor.MaxVelocity = 0.08
		motor.Part0 = part
		motor.Part1 = char.Character:FindFirstChild('UpperTorso') or char.RootPart
		motor.C0 = CFrame.new(0, 2, 0) * CFrame.Angles(0, math.rad(-90), 0)
		motor.C1 = CFrame.new(0, motor.Part1.Size.Y / 2, 0.45) * CFrame.Angles(0, math.rad(90), 0)
		motor.Parent = part
	end
	
	Cape = vape.Legit:CreateModule({
		Name = 'Cape',
		Function = function(callback)
			if callback then
				part = Instance.new('Part')
				part.Size = Vector3.new(2, 4, 0.1)
				part.CanCollide = false
				part.CanQuery = false
				part.Massless = true
				part.Transparency = 0
				part.Material = Enum.Material.SmoothPlastic
				part.Color = Color3.new()
				part.CastShadow = false
				part.Parent = gameCamera
				local capesurface = Instance.new('SurfaceGui')
				capesurface.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
				capesurface.Adornee = part
				capesurface.Parent = part
	
				if Texture.Value:find('.webm') then
					local decal = Instance.new('VideoFrame')
					decal.Video = getcustomasset(Texture.Value)
					decal.Size = UDim2.fromScale(1, 1)
					decal.BackgroundTransparency = 1
					decal.Looped = true
					decal.Parent = capesurface
					decal:Play()
				else
					local decal = Instance.new('ImageLabel')
					decal.Image = Texture.Value ~= '' and (Texture.Value:find('rbxasset') and Texture.Value or assetfunction(Texture.Value)) or 'rbxassetid://14637958134'
					decal.Size = UDim2.fromScale(1, 1)
					decal.BackgroundTransparency = 1
					decal.Parent = capesurface
				end
				Cape:Clean(part)
				Cape:Clean(entitylib.Events.LocalAdded:Connect(createMotor))
				if entitylib.isAlive then
					createMotor(entitylib.character)
				end
	
				repeat
					if motor and entitylib.isAlive then
						local velo = math.min(entitylib.character.RootPart.Velocity.Magnitude, 90)
						motor.DesiredAngle = math.rad(6) + math.rad(velo) + (velo > 1 and math.abs(math.cos(tick() * 5)) / 3 or 0)
					end
					capesurface.Enabled = (gameCamera.CFrame.Position - gameCamera.Focus.Position).Magnitude > 0.6
					part.Transparency = (gameCamera.CFrame.Position - gameCamera.Focus.Position).Magnitude > 0.6 and 0 or 1
					task.wait()
				until not Cape.Enabled
			else
				part = nil
				motor = nil
			end
		end,
		Tooltip = 'Add\'s a cape to your character'
	})
	Texture = Cape:CreateTextBox({
		Name = 'Texture'
	})
end)
	
run(function()
	local ChinaHat
	local Material
	local Color
	local hat
	
	ChinaHat = vape.Legit:CreateModule({
		Name = 'China Hat',
		Function = function(callback)
			if callback then
				if vape.ThreadFix then
					setthreadidentity(8)
				end
				hat = Instance.new('MeshPart')
				hat.Size = Vector3.new(3, 0.7, 3)
				hat.Name = 'ChinaHat'
				hat.Material = Enum.Material[Material.Value]
				hat.Color = Color3.fromHSV(Color.Hue, Color.Sat, Color.Value)
				hat.CanCollide = false
				hat.CanQuery = false
				hat.Massless = true
				hat.MeshId = 'http://www.roblox.com/asset/?id=1778999'
				hat.Transparency = 1 - Color.Opacity
				hat.Parent = gameCamera
				hat.CFrame = entitylib.isAlive and entitylib.character.Head.CFrame + Vector3.new(0, 1, 0) or CFrame.identity
				local weld = Instance.new('WeldConstraint')
				weld.Part0 = hat
				weld.Part1 = entitylib.isAlive and entitylib.character.Head or nil
				weld.Parent = hat
				ChinaHat:Clean(hat)
				ChinaHat:Clean(entitylib.Events.LocalAdded:Connect(function(char)
					if weld then 
						weld:Destroy() 
					end
					hat.Parent = gameCamera
					hat.CFrame = char.Head.CFrame + Vector3.new(0, 1, 0)
					hat.Velocity = Vector3.zero
					weld = Instance.new('WeldConstraint')
					weld.Part0 = hat
					weld.Part1 = char.Head
					weld.Parent = hat
				end))
	
				repeat
					hat.LocalTransparencyModifier = ((gameCamera.CFrame.Position - gameCamera.Focus.Position).Magnitude <= 0.6 and 1 or 0)
					task.wait()
				until not ChinaHat.Enabled
			else
				hat = nil
			end
		end,
		Tooltip = 'Puts a china hat on your character (ty mastadawn)'
	})
	local materials = {'ForceField'}
	for _, v in Enum.Material:GetEnumItems() do
		if v.Name ~= 'ForceField' then
			table.insert(materials, v.Name)
		end
	end
	Material = ChinaHat:CreateDropdown({
		Name = 'Material',
		List = materials,
		Function = function(val)
			if hat then
				hat.Material = Enum.Material[val]
			end
		end
	})
	Color = ChinaHat:CreateColorSlider({
		Name = 'Hat Color',
		DefaultOpacity = 0.7,
		Function = function(hue, sat, val, opacity)
			if hat then
				hat.Color = Color3.fromHSV(hue, sat, val)
				hat.Transparency = 1 - opacity
			end
		end
	})
end)
	
run(function()
	local Clock
	local TwentyFourHour
	local label
	
	Clock = vape.Legit:CreateModule({
		Name = 'Clock',
		Function = function(callback)
			if callback then
				repeat
					label.Text = DateTime.now():FormatLocalTime('LT', TwentyFourHour.Enabled and 'zh-cn' or 'en-us')
					task.wait(1)
				until not Clock.Enabled
			end
		end,
		Size = UDim2.fromOffset(100, 41),
		Tooltip = 'Shows the current local time'
	})
	Clock:CreateFont({
		Name = 'Font',
		Blacklist = 'Gotham',
		Function = function(val)
			label.FontFace = val
		end
	})
	Clock:CreateColorSlider({
		Name = 'Color',
		DefaultValue = 0,
		DefaultOpacity = 0.5,
		Function = function(hue, sat, val, opacity)
			label.BackgroundColor3 = Color3.fromHSV(hue, sat, val)
			label.BackgroundTransparency = 1 - opacity
		end
	})
	TwentyFourHour = Clock:CreateToggle({
		Name = '24 Hour Clock'
	})
	label = Instance.new('TextLabel')
	label.Size = UDim2.new(0, 100, 0, 41)
	label.BackgroundTransparency = 0.5
	label.TextSize = 15
	label.Font = Enum.Font.Gotham
	label.Text = '0:00 PM'
	label.TextColor3 = Color3.new(1, 1, 1)
	label.BackgroundColor3 = Color3.new()
	label.Parent = Clock.Children
	local corner = Instance.new('UICorner')
	corner.CornerRadius = UDim.new(0, 4)
	corner.Parent = label
end)
	
run(function()
	local Disguise
	local Mode
	local IDBox
	local desc
	
	local function itemAdded(v, manual)
		if (not v:GetAttribute('Disguise')) and ((v:IsA('Accessory') and (not v:GetAttribute('InvItem')) and (not v:GetAttribute('ArmorSlot'))) or v:IsA('ShirtGraphic') or v:IsA('Shirt') or v:IsA('Pants') or v:IsA('BodyColors') or manual) then
			repeat
				task.wait()
				v.Parent = game
			until v.Parent == game
			v:ClearAllChildren()
			v:Destroy()
		end
	end
	
	local function characterAdded(char)
		if Mode.Value == 'Character' then
			task.wait(0.1)
			char.Character.Archivable = true
			local clone = char.Character:Clone()
			repeat
				if pcall(function()
					desc = playersService:GetHumanoidDescriptionFromUserId(IDBox.Value == '' and 239702688 or tonumber(IDBox.Value))
				end) and desc then break end
				task.wait(1)
			until not Disguise.Enabled
			if not Disguise.Enabled then
				clone:ClearAllChildren()
				clone:Destroy()
				clone = nil
				if desc then
					desc:Destroy()
					desc = nil
				end
				return
			end
			clone.Parent = game
	
			local originalDesc = char.Humanoid:WaitForChild('HumanoidDescription', 2) or {
				HeightScale = 1,
				SetEmotes = function() end,
				SetEquippedEmotes = function() end
			}
			originalDesc.JumpAnimation = desc.JumpAnimation
			desc.HeightScale = originalDesc.HeightScale
	
			for _, v in clone:GetChildren() do
				if v:IsA('Accessory') or v:IsA('ShirtGraphic') or v:IsA('Shirt') or v:IsA('Pants') then
					v:ClearAllChildren()
					v:Destroy()
				end
			end
	
			clone.Humanoid:ApplyDescriptionClientServer(desc)
			for _, v in char.Character:GetChildren() do
				itemAdded(v)
			end
			Disguise:Clean(char.Character.ChildAdded:Connect(itemAdded))
	
			for _, v in clone:WaitForChild('Animate'):GetChildren() do
				if not char.Character:FindFirstChild('Animate') then return end
				local real = char.Character.Animate:FindFirstChild(v.Name)
				if v and real then
					local anim = v:FindFirstChildWhichIsA('Animation') or {AnimationId = ''}
					local realanim = real:FindFirstChildWhichIsA('Animation') or {AnimationId = ''}
					if realanim then
						realanim.AnimationId = anim.AnimationId
					end
				end
			end
	
			for _, v in clone:GetChildren() do
				v:SetAttribute('Disguise', true)
				if v:IsA('Accessory') then
					for _, v2 in v:GetDescendants() do
						if v2:IsA('Weld') and v2.Part1 then
							v2.Part1 = char.Character[v2.Part1.Name]
						end
					end
					v.Parent = char.Character
				elseif v:IsA('ShirtGraphic') or v:IsA('Shirt') or v:IsA('Pants') or v:IsA('BodyColors') then
					v.Parent = char.Character
				elseif v.Name == 'Head' and char.Head:IsA('MeshPart') and (not char.Head:FindFirstChild('FaceControls')) then
					char.Head.MeshId = v.MeshId
				end
			end
	
			local localface = char.Character:FindFirstChild('face', true)
			local cloneface = clone:FindFirstChild('face', true)
			if localface and cloneface then
				itemAdded(localface, true)
				cloneface.Parent = char.Head
			end
			originalDesc:SetEmotes(desc:GetEmotes())
			originalDesc:SetEquippedEmotes(desc:GetEquippedEmotes())
			clone:ClearAllChildren()
			clone:Destroy()
			clone = nil
			if desc then
				desc:Destroy()
				desc = nil
			end
		else
			local data
			repeat
				if pcall(function()
					data = marketplaceService:GetProductInfo(IDBox.Value == '' and 43 or tonumber(IDBox.Value), Enum.InfoType.Bundle)
				end) then break end
				task.wait(1)
			until not Disguise.Enabled
			if not Disguise.Enabled then
				if data then
					table.clear(data)
					data = nil
				end
				return
			end
			if data.BundleType == 'AvatarAnimations' then
				local animate = char.Character:FindFirstChild('Animate')
				if not animate then return end
				for _, v in desc.Items do
					local animtype = v.Name:split(' ')[2]:lower()
					if animtype ~= 'animation' then
						local suc, res = pcall(function() return game:GetObjects('rbxassetid://'..v.Id) end)
						if suc then
							animate[animtype]:FindFirstChildWhichIsA('Animation').AnimationId = res[1]:FindFirstChildWhichIsA('Animation', true).AnimationId
						end
					end
				end
			else
				notif('Disguise', 'that\'s not an animation pack', 5, 'warning')
			end
		end
	end
	
	Disguise = vape.Legit:CreateModule({
		Name = 'Disguise',
		Function = function(callback)
			if callback then
				Disguise:Clean(entitylib.Events.LocalAdded:Connect(characterAdded))
				if entitylib.isAlive then
					characterAdded(entitylib.character)
				end
			end
		end,
		Tooltip = 'Changes your character or animation to a specific ID (animation packs or userid\'s only)'
	})
	Mode = Disguise:CreateDropdown({
		Name = 'Mode',
		List = {'Character', 'Animation'},
		Function = function()
			if Disguise.Enabled then
				Disguise:Toggle()
				Disguise:Toggle()
			end
		end
	})
	IDBox = Disguise:CreateTextBox({
		Name = 'Disguise',
		Placeholder = 'Disguise User Id',
		Function = function()
			if Disguise.Enabled then
				Disguise:Toggle()
				Disguise:Toggle()
			end
		end
	})
end)
	
run(function()
	local FOV
	local Value
	local oldfov
	
	FOV = vape.Legit:CreateModule({
		Name = 'FOV',
		Function = function(callback)
			if callback then
				oldfov = gameCamera.FieldOfView
				repeat
					gameCamera.FieldOfView = Value.Value
					task.wait()
				until not FOV.Enabled
			else
				gameCamera.FieldOfView = oldfov
			end
		end,
		Tooltip = 'Adjusts camera vision'
	})
	Value = FOV:CreateSlider({
		Name = 'FOV',
		Min = 30,
		Max = 120
	})
end)
	
run(function()
	--[[
		Grabbing an accurate count of the current framerate
		Source: https://devforum.roblox.com/t/get-client-FPS-trough-a-script/282631
	]]
	local FPS
	local label
	
	FPS = vape.Legit:CreateModule({
		Name = 'FPS',
		Function = function(callback)
			if callback then
				local frames = {}
				local startClock = os.clock()
				local updateTick = tick()
				FPS:Clean(runService.Heartbeat:Connect(function()
					local updateClock = os.clock()
					for i = #frames, 1, -1 do
						frames[i + 1] = frames[i] >= updateClock - 1 and frames[i] or nil
					end
					frames[1] = updateClock
					if updateTick < tick() then
						updateTick = tick() + 1
						label.Text = math.floor(os.clock() - startClock >= 1 and #frames or #frames / (os.clock() - startClock))..' FPS'
					end
				end))
			end
		end,
		Size = UDim2.fromOffset(100, 41),
		Tooltip = 'Shows the current framerate'
	})
	FPS:CreateFont({
		Name = 'Font',
		Blacklist = 'Gotham',
		Function = function(val)
			label.FontFace = val
		end
	})
	FPS:CreateColorSlider({
		Name = 'Color',
		DefaultValue = 0,
		DefaultOpacity = 0.5,
		Function = function(hue, sat, val, opacity)
			label.BackgroundColor3 = Color3.fromHSV(hue, sat, val)
			label.BackgroundTransparency = 1 - opacity
		end
	})
	label = Instance.new('TextLabel')
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 0.5
	label.TextSize = 15
	label.Font = Enum.Font.Gotham
	label.Text = 'inf FPS'
	label.TextColor3 = Color3.new(1, 1, 1)
	label.BackgroundColor3 = Color3.new()
	label.Parent = FPS.Children
	local corner = Instance.new('UICorner')
	corner.CornerRadius = UDim.new(0, 4)
	corner.Parent = label
end)
	
run(function()
	local Keystrokes
	local Style
	local Color
	local keys, holder = {}
	
	local function createKeystroke(keybutton, pos, pos2, text)
		if keys[keybutton] then
			keys[keybutton].Key:Destroy()
			keys[keybutton] = nil
		end
		local key = Instance.new('Frame')
		key.Size = keybutton == Enum.KeyCode.Space and UDim2.new(0, 110, 0, 24) or UDim2.new(0, 34, 0, 36)
		key.BackgroundColor3 = Color3.fromHSV(Color.Hue, Color.Sat, Color.Value)
		key.BackgroundTransparency = 1 - Color.Opacity
		key.Position = pos
		key.Name = keybutton.Name
		key.Parent = holder
		local keytext = Instance.new('TextLabel')
		keytext.BackgroundTransparency = 1
		keytext.Size = UDim2.fromScale(1, 1)
		keytext.Font = Enum.Font.Gotham
		keytext.Text = text or keybutton.Name
		keytext.TextXAlignment = Enum.TextXAlignment.Left
		keytext.TextYAlignment = Enum.TextYAlignment.Top
		keytext.Position = pos2
		keytext.TextSize = keybutton == Enum.KeyCode.Space and 18 or 15
		keytext.TextColor3 = Color3.new(1, 1, 1)
		keytext.Parent = key
		local corner = Instance.new('UICorner')
		corner.CornerRadius = UDim.new(0, 4)
		corner.Parent = key
		keys[keybutton] = {Key = key}
	end
	
	Keystrokes = vape.Legit:CreateModule({
		Name = 'Keystrokes',
		Function = function(callback)
			if callback then
				createKeystroke(Enum.KeyCode.W, UDim2.new(0, 38, 0, 0), UDim2.new(0, 6, 0, 5), Style.Value == 'Arrow' and '↑' or nil)
				createKeystroke(Enum.KeyCode.S, UDim2.new(0, 38, 0, 42), UDim2.new(0, 8, 0, 5), Style.Value == 'Arrow' and '↓' or nil)
				createKeystroke(Enum.KeyCode.A, UDim2.new(0, 0, 0, 42), UDim2.new(0, 7, 0, 5), Style.Value == 'Arrow' and '←' or nil)
				createKeystroke(Enum.KeyCode.D, UDim2.new(0, 76, 0, 42), UDim2.new(0, 8, 0, 5), Style.Value == 'Arrow' and '→' or nil)
	
				Keystrokes:Clean(inputService.InputBegan:Connect(function(inputType)
					local key = keys[inputType.KeyCode]
					if key then
						if key.Tween then
							key.Tween:Cancel()
						end
						if key.Tween2 then
							key.Tween2:Cancel()
						end
	
						key.Pressed = true
						key.Tween = tweenService:Create(key.Key, TweenInfo.new(0.1), {
							BackgroundColor3 = Color3.new(1, 1, 1), 
							BackgroundTransparency = 0
						})
						key.Tween2 = tweenService:Create(key.Key.TextLabel, TweenInfo.new(0.1), {
							TextColor3 = Color3.new()
						})
						key.Tween:Play()
						key.Tween2:Play()
					end
				end))
	
				Keystrokes:Clean(inputService.InputEnded:Connect(function(inputType)
					local key = keys[inputType.KeyCode]
					if key then
						if key.Tween then
							key.Tween:Cancel()
						end
						if key.Tween2 then
							key.Tween2:Cancel()
						end
	
						key.Pressed = false
						key.Tween = tweenService:Create(key.Key, TweenInfo.new(0.1), {
							BackgroundColor3 = Color3.fromHSV(Color.Hue, Color.Sat, Color.Value), 
							BackgroundTransparency = 1 - Color.Opacity
						})
						key.Tween2 = tweenService:Create(key.Key.TextLabel, TweenInfo.new(0.1), {
							TextColor3 = Color3.new(1, 1, 1)
						})
						key.Tween:Play()
						key.Tween2:Play()
					end
				end))
			end
		end,
		Size = UDim2.fromOffset(110, 176),
		Tooltip = 'Shows movement keys onscreen'
	})
	holder = Instance.new('Frame')
	holder.Size = UDim2.fromScale(1, 1)
	holder.BackgroundTransparency = 1
	holder.Parent = Keystrokes.Children
	Style = Keystrokes:CreateDropdown({
		Name = 'Key Style',
		List = {'Keyboard', 'Arrow'},
		Function = function()
			if Keystrokes.Enabled then
				Keystrokes:Toggle()
				Keystrokes:Toggle()
			end
		end
	})
	Color = Keystrokes:CreateColorSlider({
		Name = 'Color',
		DefaultValue = 0,
		DefaultOpacity = 0.5,
		Function = function(hue, sat, val, opacity)
			for _, v in keys do
				if not v.Pressed then
					v.Key.BackgroundColor3 = Color3.fromHSV(hue, sat, val)
					v.Key.BackgroundTransparency = 1 - opacity
				end
			end
		end
	})
	Keystrokes:CreateToggle({
		Name = 'Show Spacebar',
		Function = function(callback)
			Keystrokes.Children.Size = UDim2.fromOffset(110, callback and 107 or 78)
			if callback then
				createKeystroke(Enum.KeyCode.Space, UDim2.new(0, 0, 0, 83), UDim2.new(0, 25, 0, -10), '______')
			else
				keys[Enum.KeyCode.Space].Key:Destroy()
				keys[Enum.KeyCode.Space] = nil
			end
		end,
		Default = true
	})
end)
	
run(function()
	local Memory
	local label
	
	Memory = vape.Legit:CreateModule({
		Name = 'Memory',
		Function = function(callback)
			if callback then
				repeat
					label.Text = math.floor(tonumber(game:GetService('Stats'):FindFirstChild('PerformanceStats').Memory:GetValue()))..' MB'
					task.wait(1)
				until not Memory.Enabled
			end
		end,
		Size = UDim2.fromOffset(100, 41),
		Tooltip = 'A label showing the memory currently used by roblox'
	})
	Memory:CreateFont({
		Name = 'Font',
		Blacklist = 'Gotham',
		Function = function(val)
			label.FontFace = val
		end
	})
	Memory:CreateColorSlider({
		Name = 'Color',
		DefaultValue = 0,
		DefaultOpacity = 0.5,
		Function = function(hue, sat, val, opacity)
			label.BackgroundColor3 = Color3.fromHSV(hue, sat, val)
			label.BackgroundTransparency = 1 - opacity
		end
	})
	label = Instance.new('TextLabel')
	label.Size = UDim2.new(0, 100, 0, 41)
	label.BackgroundTransparency = 0.5
	label.TextSize = 15
	label.Font = Enum.Font.Gotham
	label.Text = '0 MB'
	label.TextColor3 = Color3.new(1, 1, 1)
	label.BackgroundColor3 = Color3.new()
	label.Parent = Memory.Children
	local corner = Instance.new('UICorner')
	corner.CornerRadius = UDim.new(0, 4)
	corner.Parent = label
end)
	
run(function()
	local Ping
	local label
	
	Ping = vape.Legit:CreateModule({
		Name = 'Ping',
		Function = function(callback)
			if callback then
				repeat
					label.Text = math.floor(tonumber(game:GetService('Stats'):FindFirstChild('PerformanceStats').Ping:GetValue()))..' ms'
					task.wait(1)
				until not Ping.Enabled
			end
		end,
		Size = UDim2.fromOffset(100, 41),
		Tooltip = 'Shows the current connection speed to the roblox server'
	})
	Ping:CreateFont({
		Name = 'Font',
		Blacklist = 'Gotham',
		Function = function(val)
			label.FontFace = val
		end
	})
	Ping:CreateColorSlider({
		Name = 'Color',
		DefaultValue = 0,
		DefaultOpacity = 0.5,
		Function = function(hue, sat, val, opacity)
			label.BackgroundColor3 = Color3.fromHSV(hue, sat, val)
			label.BackgroundTransparency = 1 - opacity
		end
	})
	label = Instance.new('TextLabel')
	label.Size = UDim2.new(0, 100, 0, 41)
	label.BackgroundTransparency = 0.5
	label.TextSize = 15
	label.Font = Enum.Font.Gotham
	label.Text = '0 ms'
	label.TextColor3 = Color3.new(1, 1, 1)
	label.BackgroundColor3 = Color3.new()
	label.Parent = Ping.Children
	local corner = Instance.new('UICorner')
	corner.CornerRadius = UDim.new(0, 4)
	corner.Parent = label
end)
	
run(function()
	local SongBeats
	local List
	local FOV
	local FOVValue = {}
	local Volume
	local alreadypicked = {}
	local beattick = tick()
	local oldfov, songobj, songbpm, songtween
	
	local function choosesong()
		local list = List.ListEnabled
		if #alreadypicked >= #list then
			table.clear(alreadypicked)
		end
	
		if #list <= 0 then
			notif('SongBeats', 'no songs', 10)
			SongBeats:Toggle()
			return
		end
	
		local chosensong = list[math.random(1, #list)]
		if #list > 1 and table.find(alreadypicked, chosensong) then
			repeat
				task.wait()
				chosensong = list[math.random(1, #list)]
			until not table.find(alreadypicked, chosensong) or not SongBeats.Enabled
		end
		if not SongBeats.Enabled then return end
	
		local split = chosensong:split('/')
		if not isfile(split[1]) then
			notif('SongBeats', 'Missing song ('..split[1]..')', 10)
			SongBeats:Toggle()
			return
		end
	
		songobj.SoundId = assetfunction(split[1])
		repeat task.wait() until songobj.IsLoaded or not SongBeats.Enabled
		if SongBeats.Enabled then
			beattick = tick() + (tonumber(split[3]) or 0)
			songbpm = 60 / (tonumber(split[2]) or 50)
			songobj:Play()
		end
	end
	
	SongBeats = vape.Legit:CreateModule({
		Name = 'Song Beats',
		Function = function(callback)
			if callback then
				songobj = Instance.new('Sound')
				songobj.Volume = Volume.Value / 100
				songobj.Parent = workspace
				oldfov = gameCamera.FieldOfView
	
				repeat
					if not songobj.Playing then
						choosesong()
					end
					if beattick < tick() and SongBeats.Enabled and FOV.Enabled then
						beattick = tick() + songbpm
						gameCamera.FieldOfView = oldfov - FOVValue.Value
						songtween = tweenService:Create(gameCamera, TweenInfo.new(math.min(songbpm, 0.2), Enum.EasingStyle.Linear), {
							FieldOfView = oldfov
						})
						songtween:Play()
					end
					task.wait()
				until not SongBeats.Enabled
			else
				if songobj then
					songobj:Destroy()
				end
				if songtween then
					songtween:Cancel()
				end
				if oldfov then
					gameCamera.FieldOfView = oldfov
				end
				table.clear(alreadypicked)
			end
		end,
		Tooltip = 'Built in mp3 player'
	})
	List = SongBeats:CreateTextList({
		Name = 'Songs',
		Placeholder = 'filepath/bpm/start'
	})
	FOV = SongBeats:CreateToggle({
		Name = 'Beat FOV',
		Function = function(callback)
			if FOVValue.Object then
				FOVValue.Object.Visible = callback
			end
			if SongBeats.Enabled then
				SongBeats:Toggle()
				SongBeats:Toggle()
			end
		end,
		Default = true
	})
	FOVValue = SongBeats:CreateSlider({
		Name = 'Adjustment',
		Min = 1,
		Max = 30,
		Default = 5,
		Darker = true
	})
	Volume = SongBeats:CreateSlider({
		Name = 'Volume',
		Function = function(val)
			if songobj then
				songobj.Volume = val / 100
			end
		end,
		Min = 1,
		Max = 100,
		Default = 100,
		Suffix = '%'
	})
end)
	
run(function()
	local Speedmeter
	local label
	
	Speedmeter = vape.Legit:CreateModule({
		Name = 'Speedmeter',
		Function = function(callback)
			if callback then
				repeat
					local lastpos = entitylib.isAlive and entitylib.character.HumanoidRootPart.Position * Vector3.new(1, 0, 1) or Vector3.zero
					local dt = task.wait(0.2)
					local newpos = entitylib.isAlive and entitylib.character.HumanoidRootPart.Position * Vector3.new(1, 0, 1) or Vector3.zero
					label.Text = math.round(((lastpos - newpos) / dt).Magnitude)..' sps'
				until not Speedmeter.Enabled
			end
		end,
		Size = UDim2.fromOffset(100, 41),
		Tooltip = 'A label showing the average velocity in studs'
	})
	Speedmeter:CreateFont({
		Name = 'Font',
		Blacklist = 'Gotham',
		Function = function(val)
			label.FontFace = val
		end
	})
	Speedmeter:CreateColorSlider({
		Name = 'Color',
		DefaultValue = 0,
		DefaultOpacity = 0.5,
		Function = function(hue, sat, val, opacity)
			label.BackgroundColor3 = Color3.fromHSV(hue, sat, val)
			label.BackgroundTransparency = 1 - opacity
		end
	})
	label = Instance.new('TextLabel')
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 0.5
	label.TextSize = 15
	label.Font = Enum.Font.Gotham
	label.Text = '0 sps'
	label.TextColor3 = Color3.new(1, 1, 1)
	label.BackgroundColor3 = Color3.new()
	label.Parent = Speedmeter.Children
	local corner = Instance.new('UICorner')
	corner.CornerRadius = UDim.new(0, 4)
	corner.Parent = label
end)
	
run(function()
	local TimeChanger
	local Value
	local old
	
	TimeChanger = vape.Legit:CreateModule({
		Name = 'Time Changer',
		Function = function(callback)
			if callback then
				old = lightingService.TimeOfDay
				lightingService.TimeOfDay = Value.Value..':00:00'
			else
				lightingService.TimeOfDay = old
				old = nil
			end
		end,
		Tooltip = 'Change the time of the current world'
	})
	Value = TimeChanger:CreateSlider({
		Name = 'Time',
		Min = 0,
		Max = 24,
		Default = 12,
		Function = function(val)
			if TimeChanger.Enabled then 
				lightingService.TimeOfDay = val..':00:00'
			end
		end
	})
	
end)
