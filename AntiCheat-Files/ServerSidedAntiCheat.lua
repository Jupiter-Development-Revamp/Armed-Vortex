-- Place inside ServerScriptService
-- Fully Tested
-- NOT EDITABLE (unless you know what your doing)
--[[
    Project: Armed-Vortex;
    Developers: Prometheus, ExFamous;
    Contributors: nil;
    Description: Serversided anticheat;
    Version: v1.0;
    Update Date: nil; -- no updates yet
]]

-- Requiring the module
local iHM = require(game:WaitForChild("ReplicatedStorage"):WaitForChild("InfoHolderModule"));

local webhookURL = "" -- replace with your own webhook URL
local function sendToWebhook(message)
	local HttpService = game:GetService("HttpService")

	local data = {
		content = message
	}

	local jsonData = HttpService:JSONEncode(data)

	local success, response = pcall(function()
		return HttpService:PostAsync(webhookURL, jsonData, Enum.HttpContentType.ApplicationJson)
	end)

	if success then
		print("Data sent successfully")
	else
		warn("Failed to send data: " .. response)
	end
end


-- Quick check if the Anti-Cheat is being disabled
if iHM.avCon.DEBUGINFO.dOO then
	print("AntiCheat Disabled!");
	return;
end;

-- Initialize the module's function
iHM.Initialize();

-- Check if Debug Mode is enabled
if iHM.avCon.DEBUGINFO.dM then
	print("ServerSidedAntiCheat Connection... Successful!");
end;

-- Define the server-sided AntiCheat configurations
local ssAC = {
	pD = { -- Everything the serversided AntiCheat will detect
		wS = { -- Speed Hacks, And Teleporting, And Jump Hacks, And Fly Hacks, And Invis Hacks
			ENABLED = true;
			SETTINGS = { -- Do not modify if you dont know what you're doing
				checkInterval = 0.6; -- Seconds
				toleranceDelta = 16 + 1.4; -- 22.4 studs, Roblox's docs state how this works
			};
		};
		aB = {-- AimBots
			ENABLED = true;
			SETTINGS = {
				aimSnap = 1.5;
				checkInterval = 0.3;
				previousAimData = {};
			};
		};
		aA = {-- Account (NOT PLAYER) age restrictions -- Prevents Accounts under a certain age play your game
			ENABLED = true;
			SETTINGS = {
				minimumAge = 10; -- In days
			};
		};
	};
};

-- Function to handle Speed/Teleport/JumpPower detection
local function detectSpeedHacks(player: Player?, character: Model?)
	local lastPosition = character.HumanoidRootPart.Position;

	while player.Parent and ssAC.pD.wS.ENABLED and task.wait(ssAC.pD.wS.SETTINGS.checkInterval) do
		local newPosition = character.HumanoidRootPart.Position;
		local distanceMoved = (lastPosition - newPosition).Magnitude;

		if distanceMoved > ssAC.pD.wS.SETTINGS.toleranceDelta then
			iHM.addStrike(player.UserId);
			if iHM.avCon.DEBUGINFO.dM then
				print(player.Name .. " is cheating -- Teleport/Speed Bypass/Jumppower Bypass/Flying/Invis");
				sendToWebhook(player.Name .. " is cheating -- Teleport/Speed Bypass/Jumppower Bypass/Flying/Invis");
			end;
			task.wait(2);
		end;
		lastPosition = newPosition;
	end;
end;

local function detectAimBot(player: Player?, character: Model?)
	while player.Parent and ssAC.pD.aB.ENABLED do
		local head = character:FindFirstChild("Head") or nil;
		if head then
			local aimVector = head.CFrame.LookVector;
			local prevData = ssAC.pD.aB.SETTINGS.previousAimData[player];
			if not prevData then
				prevData = {aimVector = aimVector, timestamp = tick()};
				ssAC.pD.aB.SETTINGS.previousAimData[player] = prevData;
			end
			local timeDelta = tick() - prevData.timestamp;
			if (prevData.aimVector - aimVector).magnitude > ssAC.pD.aB.SETTINGS.aimSnap and timeDelta < ssAC.pD.aB.SETTINGS.checkInterval then
				for _, otherPlayer in pairs(game:GetService("Players"):GetPlayers()) do
					if otherPlayer ~= player and otherPlayer.Character and otherPlayer.Character:FindFirstChild("Head") then
						local otherHead = otherPlayer.Character.Head;
						local directionToOther = (otherHead.Position - head.Position).unit;
						if aimVector:Dot(directionToOther) > 0.99 then -- Needs to be adjusted
							iHM.addStrike(player.UserId);
							if iHM.avCon.DEBUGINFO.dM then
								print(player.Name .. " is cheating -- Aimbot Detected");
								sendToWebhook(player.Name .. " is cheating Aimbot Detected");
							end;
							break;
						end;
					end;
				end;
			end;
			ssAC.pD.aB.SETTINGS.previousAimData[player] = {aimVector = aimVector, timestamp = tick()};
		end;
		task.wait();
	end;
end;

local function agePrevention(player: Player?)
	if ssAC.pD.aA.ENABLED and player.AccountAge < ssAC.pD.aA.SETTINGS.minimumAge then
		player:Kick("Your account is underaged.");
		if iHM.avCon.DEBUGINFO.dM then
			print(player.Name .. " or " .. player.DisplayName .. " has just been kicked due to account not meeting age");
		end;
	end;
end;

-- Here is where we will handle our AntiCheat logic
game:GetService("Players").PlayerAdded:Connect(function(player)
	local oS, aD = iHM.checkLevel(player);
	if oS == "Owner" or "Admin" and aD == true then
		if iHM.avCon.DEBUGINFO.dM then
			print("AntiCheat is off for " .. player.Name);
		end; 
		return;
	end;
	agePrevention(player);
	player.CharacterAdded:Connect(function(character)
		character:WaitForChild("HumanoidRootPart");
		character:WaitForChild("Humanoid");
		coroutine.wrap(detectSpeedHacks)(player, character);
		coroutine.wrap(detectAimBot)(player, character);
	end);
end);

game:GetService("Players").PlayerRemoving:Connect(function(player)
	ssAC.pD.aB.SETTINGS.previousAimData[player] = nil;
end)
