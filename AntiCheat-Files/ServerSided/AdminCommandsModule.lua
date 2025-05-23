local aCM = {}
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

local iHM = require(game:WaitForChild("ReplicatedStorage"):WaitForChild("InfoHolderModule"));
local user = nil;
local prefix = ";";

-- Modify to your liking
local tpLocations = {
	-- ["example"] = CFrame.new(X, Y, Z);
};

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
			if not suc then iHM.sendNotification(tostring(err), user.Name); end;
		end;
	};
	JUMPPOWER = {
		aliases = {"jp", "jumppower"};
		func = function(args: number)
			local suc, err = pcall(function()
				user.Character.Humanoid.JumpPower = args[1];
			end);
			if not suc then iHM.sendNotification(tostring(err), user.Name); end;
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
			if not suc then iHM.sendNotification(tostring(err), user.Name); end;
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
								task.wait(0.5);
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
		aliases = {"kill", "k"};
		func = function(args: Player?)
			if args[1] == "all" then
				for i,v in pairs(game:GetService("Players"):GetPlayers()) do
					v.Character.Humanoid.Health = 0;
				end;
			elseif getPlayer(args[1]) then
				getPlayer(args[1]).Character.Humanoid.Health = 0;
			else
				iHM.sendNotification("Invalid Player", user.Name);
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
				iHM.sendNotification("Error executing command: " .. error, user.Name);
			end;
		else
			iHM.sendNotification("Invalid Command: " .. cmd, user.Name);
		end;
	end);
end;

return aCM;
