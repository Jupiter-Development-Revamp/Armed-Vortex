-- PLACE THIS INSIDE REPLICATED STORAGE TO ENSURE 100% WORKAGE!
-- Half of this is made to be edited for others, not just us (Exfamous, StyxDeveloper)
--[[
    Project: Armed-Vortex;
    Developers: StyxDeveloper, ExFamous;
    Contributors: nil;
    Description: InfoHandlerModule;
    Version: v1.1.3;
    Update Date: 5/13/2025;
    	Added support for bad animations;
]]

-- {{ MODULE TABLE }} --
local aVM = {} -- Armed Vortex

-- {{ CONFIG }} --
aVM.avCon = { -- Armed-Vortex Configuration
	-- DONT MESS WITH THIS UNLESS YOU KNOW WHAT YOU ARE DOING!
	-- THIS IS USED TO FIND BUGS AND FIX THEM!
	DEBUGINFO = { -- Debugging and Error Pentesting
		dM = false; -- DEBUG MODE -- CHANGE IF ISSUES PRESENTED IN THIS FILE!
		dOO = false; -- Detection Overwrite -- CHANGE IF ISSUES PRESENTED IN THIS FILE! -- USED TO DISABLE THIS FILE!
	};

	MECHANICS = { -- Anti-Cheats logic - THIS FILE HANDLES ALL LOGIC
		-- CHANGE FOR YOUR BENEFIT
		STRIKES = {
			sT = 3; -- Strike Threshold -- CHANGE IF YOU WANT TO USE THE STRIKE SYSTEM!
			bS = { -- Ban System -- CHANGE TO USE THE BAN SYSTEM -- THESE ARE IN DAYS
				firstBan = 3; -- FEEL FREE TO CHANGE
				secondBan = 7; -- FEEL FREE TO CHANGE
				thirdBan = -1; -- DO NOT CHANGE
			};
		};
		SYSTEM = {
			kS = true; -- Kick System Enabled -- CHANGE IF YOU WANT TO USE THE KICK SYSTEM!
			bS = false; -- Ban System Enabled -- CHANGE IF YOU WANT TO USE THE BAN SYSTEM!
			wH = ""; -- WebHook for Armed Vortex notifications -- Change for your WebHook
		};    
	};
	OWNERCONFIGS = { -- User Configurations
        --[[
            FORMAT:
            ["USERNAME"] = {
                ["LEVEL"] = nil; -- [1 = Owner] - [2 = Admin] - [3 = Mod] -- 1-2 AntiCheat is disabled. 
                ["ADMIN"] = true; -- [true = Chat + UI Commands] - [false = No Admin] -- Can be nil results in false, automatically disables AntiCheat if true
           };
        --]]

		-- For test purposes
		--[[
		["Jupiter_Development"] = {
			["LEVEL"] = 1;
			["ADMIN"] = true;
		};		
		]]

		["diva49ers"] = {
			["LEVEL"] = 1;
			["ADMIN"] = true;
		};
	};
	PLAYERS = {
		-- INFO THAT WILL BE PROVIDED USERID - STRIKES - SERVERBAN
	};
};

aVM.ssAC = {
	pD = { -- Everything the server-sided AntiCheat will detect
		wS = {
			ENABLED = true;
			SETTINGS = { -- Do not modify if you dont know what you're doing
				checkInterval = 0.6; -- Seconds
				toleranceDelta = 16 + 1.4; -- 22.4 studs, Roblox's docs state how this works
			};
		};
		aB = { -- AimBots
			ENABLED = true;
			SETTINGS = {
				aimSnap = 0.8; -- Threshold for snapping to target (0 to 1 scale)
				checkInterval = 0.3; -- Interval in seconds between aim check
			};
		};
		aA = { -- Account age restrictions to prevent underage players
			ENABLED = true;
			SETTINGS = {
				minimumAge = 10; -- Minimum account age in days
			};
		};
		jP = {
			ENABLED = true;
			SETTINGS = {
				expectedJumpPower = 9 + 1.4;	
			};
		};
		BAD_ANIMATION_IDS = {
			["rbxassetid://72042024"] = true;
			["rbxassetid://698251653"] = true;
			["rbxassetid://148840371"] = true;
			["rbxassetid://5918726674"] = true;
		};
	};
};

-- Function to send data to the webhook
function aVM.sendToWebhook(message)
	local HttpService = game:GetService("HttpService")

	local data = 
		{
			["content"] = message

		}

	local jsonData = HttpService:JSONEncode(data)

	local success, response = pcall(function()
		return HttpService:PostAsync(aVM.avCon.MECHANICS.SYSTEM.wH, jsonData, Enum.HttpContentType.ApplicationJson)
	end)
end

-- Quick Check
if aVM.avCon.DEBUGINFO.dOO then
	if aVM.avCon.DEBUGINFO.dM then
		print("You have disabled the AntiCheat! | INFOHOLDERMODULE!");
	end;
	aVM.sendToWebhook("Anti-Cheat is disabled!");
	return "Disabled";
end;

-- {{ FUNCTIONS }} --
function aVM.checkLevel(user: Player?)
	local l = aVM.avCon.OWNERCONFIGS[user.Name] and aVM.avCon.OWNERCONFIGS[user.Name]["LEVEL"]
	local ad = aVM.avCon.OWNERCONFIGS[user.Name] and aVM.avCon.OWNERCONFIGS[user.Name]["ADMIN"]

	local oS = nil

	if l == 1 then
		oS = "Owner"
		aVM.sendToWebhook("Owner detected "..user.Name)
	elseif l == 2 then
		oS = "Admin"
	elseif l == 3 then
		oS = "Mod"
		aVM.sendToWebhook("Mod detected")
	else
		oS = "false"
	end

	ad = ad ~= nil and tostring(ad) or "false"

	return oS, ad
end

function aVM.sendNotification(message: string?, who: string?)
	if not message or message == "" then
		return;
	end;
	local notificationEvent = game:GetService("ReplicatedStorage").Remotes:WaitForChild("NotificationEvent");
	if not notificationEvent then
		repeat task.wait() until notificationEvent;
		return;
	end;
	if who == nil or who == "all" then
		notificationEvent:FireAllClients(nil, message);
	else
		notificationEvent:FireClient(game:GetService("Players")[who], message);
	end;
end;

function aVM.Initialize()
	local players = game:GetService("Players");

	players.PlayerAdded:Connect(function(user)
		local suc, err = pcall(function()
			task.spawn(function()
				if not aVM.avCon.PLAYERS[user.UserId] then
					aVM.avCon.PLAYERS[user.UserId] = {
						["STRIKES"] = 0;
						["SERVERBAN"] = false;
						["TEMPPASS"] = false;
					};
				end;
				while players:FindFirstChild(user.Name) and task.wait(1) do
					if aVM.avCon.PLAYERS[user.UserId].STRIKES >= aVM.avCon.MECHANICS.STRIKES.sT then
						if aVM.avCon.MECHANICS.SYSTEM.kS then
							user:Kick("You have been kicked by the Anti-Cheat.");
							aVM.sendToWebhook(user.Name .. " has just been kicked, exploit detected.")
							if aVM.avCon.DEBUGINFO.dM then
								print(user.Name .. " has just been kicked!");
							end;
							task.wait(2)
						end;
					end;
					if aVM.avCon.PLAYERS[user.UserId].SERVERBAN == true then
						user:Kick("You have been server banned!");
					end;
					if aVM.avCon.MECHANICS.SYSTEM.bS then
						local banHistory = players:GetBanHistoryAsync(user.UserId);
						local banDuration;
						for _,v in pairs(banHistory) do
							banDuration = v.Duration or false;
							break
						end;
						if banDuration then
							banDuration = (banDuration/60)/60/24;
							for i,v in pairs(aVM.avCon.MECHANICS.STRIKES.bS) do
								if v == banDuration then
									banDuration = i;
									break;
								end;
							end;
							if banDuration == "firstBan" then
								banDuration = aVM.avCon.MECHANICS.STRIKES.bS.secondBan;
							elseif banDuration == "secondBan" then
								banDuration = aVM.avCon.MECHANICS.STRIKES.bS.thirdBan;
							elseif banDuration == false then
								banDuration = aVM.avCon.MECHANICS.STRIKES.bS.firstBan;
							end;
						end;

						local config = {
							UserIds = {user.UserId};
							Duration = banDuration * 24 * 60 * 60;
							DisplayReason = "AVAC: " .. user.Name .. " is banned for exploiting!";
							PrivateReason = "Note: This ban was from the Anti-Cheat, they were detected for cheating.";
						};

						players:BanAsync(config);
						aVM.sendToWebhook(user.Name .. " has just been banned for " .. config.Duration .. " days, " .. config.PrivateReason);
					end;
				end;
			end);
			task.spawn(function()
				local oS, aD = aVM.checkLevel(user);
				if aVM.avCon.DEBUGINFO.dM then 
					print(oS, aD);
				end;
				if oS ~= "false" and aD == "true" then
					require(game:WaitForChild("ReplicatedStorage"):WaitForChild("AdminCommandsModule")).init(user);
				end;
			end);
		end);
		if not suc and aVM.avCon.DEBUGINFO.dM then
			print("AVAC: Error while initialize! \n Error: " .. err);
		end;
	end);
	if aVM.avCon.DEBUGINFO.dM then
		print("INFOHOLDERMODULE: Initialized!");
	end;
end;


function aVM.addStrike(playerUserId: number?, reason: string)
	local PLAYERS = aVM.avCon.PLAYERS;
	local suc, err = pcall(function()
		if PLAYERS[playerUserId] and PLAYERS[playerUserId].TEMPPASS == false then
			PLAYERS[playerUserId].STRIKES = PLAYERS[playerUserId].STRIKES + 1;
			local player = game:GetService("Players"):GetPlayerByUserId(playerUserId);
			if player and aVM.avCon.DEBUGINFO.dM then
				aVM.sendNotification("Exploit Detected, stop exploiting!", player.Name);
			end;
		end;
	end);
	if not suc and aVM.avCon.DEBUGINFO.dM then
		print("[Error]: " .. err);
	end;
end;

return aVM;
