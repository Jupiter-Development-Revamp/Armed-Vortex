local aCM = {}
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

local iHM = require(game:WaitForChild("ReplicatedStorage"):WaitForChild("InfoHolderModule"));
local user = nil;
local prefix = ";";

local function sendReport(message, Reason, Player, Desc, Proof)
	local data = {
		['embeds'] = {{
			['title'] = "Reported Player",
			['description'] = "A player has submitted an in-game report!",
			['thumbnail'] = {
				['url'] = 'https://media.discordapp.net/attachments/1038554017736953977/1042150401564225536/stufflogo2.jpg?width=676&height=676',
			},
			["fields"] = {
				{
					["name"] = "Submitted by",
					["value"] = Player.Name,
					["inline"] = true
				},
				{
					["name"] = "Player Reported",
					["value"] = Player.Name,
					["inline"] = false
				},
				{
					["name"] = "Reason for Report",
					["value"] = Reason,
					["inline"] = false
				},
				{
					["name"] = "Description",
					["value"] = Desc,
					["inline"] = false
				},
				{
					["name"] = "Evidence",
					["value"] = Proof,
					["inline"] = false
				},
			}
		}}
	}
	iHM.sendToWebhook(data)
end

-- Modify to your liking
local tpLocations = {
	-- ["example"] = CFrame.new(X, Y, Z);
};

local function warnPlayer(player: Player, message: string, color: BrickColor) -- Not an actual warning, sends stuff to their console -- If they have Admin their going to have that GUI
	-- You should make this into a GUI
	warn(message)
end



local function stringSimilarity(s1: string, s2: string)
	local m, n = #s1, #s2;
	local cost = {};

	for i = 0, m do cost[i] = {} end;
	for i = 0, m do cost[i][0] = i end;
	for j = 0, n do cost[0][j] = j end;

	for i = 1, m do
		for j = 1, n do
			local c = (s1:sub(i, i) == s2:sub(j, j)) and 0 or 1;
			cost[i][j] = math.min(cost[i - 1][j] + 1, cost[i][j - 1] + 1, cost[i - 1][j - 1] + c);
		end;
	end;
	return 1 - cost[m][n] / math.max(m, n);
end;

local function getPlayer(name)
	if not (name == "me") and #name <= 2 then return false end;
	if name == "me" then return user end;

	for _, player in pairs(game.Players:GetPlayers()) do
		if stringSimilarity(player.Name, name) > 0.6 or (stringSimilarity(player.DisplayName, name) > 0.4 and stringSimilarity(player.Name, name) == 0.4) then
			return player;
		end;
	end;

	return false;
end;

local cmds = {
	TEST = {
		aliases = {"test","print"};
		func = function(args: table)
			print(table.concat(args, " "));
		end;
	};
	KICK = {
		aliases = {"kick"};
		func = function(args: table)
			local player = getPlayer(args[1]);
			if not player then return end;
			player:Kick(table.concat(args, " ", 2));
		end;
	};
	PREFIX = {
		aliases = {"prefix"};
		func = function(args: string)
			prefix = args[1];
		end;
	};
	WALKSPEED = {
		aliases = {"ws", "walkspeed"};
		func = function(args: number)
			local suc, err = pcall(function()
				user.Character.Humanoid.WalkSpeed = args[1];
			end);
			if not suc then warnPlayer(user, err, "red"); end;
		end;
	};
	JUMPPOWER = {
		aliases = {"jp", "jumppower"};
		func = function(args: number)
			local suc, err = pcall(function()
				user.Character.Humanoid.JumpPower = args[1];
			end);
			if not suc then warnPlayer(user, err, "red"); end;
		end;
	};
	TP = {
		aliases = {"goto", "tpto"};
		func = function(args: "a: CFrame? | Player? | Location?")
			local suc, err = pcall(function()
				if args[1] and args[2] and args[3] then
					user.Character:PivotTo(CFrame.new(args[1], args[2], args[3]));
				elseif getPlayer(args[1]) then
					user.Character:PivotTo(args[1].Character:GetPrimaryPartCFrame());
				else
					for i, v in pairs(tpLocations) do
						if stringSimilarity(i, args[1]:lower()) >= 0.7 then
							user.Character:PivotTo(v);
						end;
					end;
				end;
			end);
			if not suc then warnPlayer(user, err, "red"); end;
		end;
	};
	BRING = {
		aliases = {"bring", "tp"};
		func = function(args: "a: all? | Player?, b: Player? | CFrame? | Location?")
			local p1 = getPlayer(args[1]) or user;
			local p2 = getPlayer(args[2]) or user;

			if p1 and p2 then
				iHM.PLAYERS[game:GetService("Players"):GetUserIdFromNameAsync(p1.Name)].TEMPPASS = true;
				p1.Character:PivotTo(p2.Character:GetPrimaryPartCFrame());
				task.wait(1);
				iHM.PLAYERS[game:GetService("Players"):GetUserIdFromNameAsync(p1.Name)].TEMPPASS = false;

			elseif args[1] == "all" then
				if p2 then
					for _, p in pairs(game:GetService("Players"):GetPlayers()) do
						iHM.PLAYERS[game:GetService("Players"):GetUserIdFromNameAsync(p.Name)].TEMPPASS = true;
						p.Character:PivotTo(p2.Character:GetPrimaryPartCFrame());
						task.wait(1);
						iHM.PLAYERS[game:GetService("Players"):GetUserIdFromNameAsync(p.Name)].TEMPPASS = false;
					end;
				else
					for i, v in pairs(tpLocations) do
						if stringSimilarity(i:lower(), args[2]:lower()) >= 0.7 then
							for _, p in pairs(game:GetService("Players"):GetPlayers()) do
								iHM.PLAYERS[game:GetService("Players"):GetUserIdFromNameAsync(p.Name)].TEMPPASS = true;
								p.Character:PivotTo(v);
								task.wait(0.5); -- needs to test
								iHM.PLAYERS[game:GetService("Players"):GetUserIdFromNameAsync(p.Name)].TEMPPASS = false;
							end;
							break;
						end;
					end;
				end;
			end;
		end;
	};
	KILL = {
		aliases = {};
		func = function(args: Player?)
			if args[1] == "all" then
				for i,v in pairs(game:GetService("Players"):GetPlayers()) do
					v.Character.Humanoid.Health = 0;
				end;
			elseif getPlayer(args[1]) then
				getPlayer(args[1]).Character.Humanoid.Health = 0;
			else
				warnPlayer(user, "Invalid Player", "red");
			end;
		end;
	};
};


function aCM.logic(player, args: "table?")
	if player.Name ~= args.playerName then
		iHM.avCon.PLAYERS[player.UserId].STRIKES = 3;
	elseif player.UserId ~= args.userId then
		iHM.avCon.PLAYERS[player.UserId].STRIKES = 3;
	end;
	
end;

function aCM.init(User)
	user = User
	user.Chatted:Connect(function(message)
		if message:sub(1, #prefix) ~= prefix then return end;

		local args = message:split(" ");
		local cmd = args[1]:sub(#prefix + 1):lower();
		table.remove(args, 1);

		local bestMatch, highestScore = nil, 0;

		for name, cmdData in pairs(cmds) do
			for _, alias in ipairs(cmdData.aliases) do
				local similarity = stringSimilarity(cmd, alias:lower());
				if similarity > highestScore then
					highestScore = similarity;
					bestMatch = cmdData;
				end;
			end;
		end;

		if bestMatch and highestScore >= 0.7 then
			local success, error = pcall(bestMatch.func, args);
			if not success then
				warn("Error executing command: " .. error);
			end;
		else
			warn("Invalid Command: " .. cmd);
		end;
	end);
end;

return aCM;

--[[ -- need to do
Mod/Admin abilities
Users -- Vote for moderator review on player -- LEVEL 4
Moderation -- Kick - Chatlogs - spectate - serverban -- LEVEL 3 [GUI Based for everything] 
Admin -- Ban - Chatlogs - spectate - serverban - gameban - Admin Commands -- LEVEL 2 [GUI and Chat Commands]
Owner -- Ban - Chatlogs - spectate - serverban - gameban - unban - Admin Commands -- LEVEL 1 [GUI and Chat Commands]

Chat Commands -- Prefix - Walkspeed - Jumppower - Goto - Bring - Kill
]]
