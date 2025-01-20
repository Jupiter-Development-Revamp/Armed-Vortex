-- Place inside ServerScriptService
-- Fully Tested
-- NOT EDITABLE (unless you know what your doing)
--[[
    Project: Armed-Vortex;
    Developers: StyxDeveloper, ExFamous;
    Contributors: nil;
    Description: Serversided anticheat;
    Version: v1.1;
    Update Date: 1/20/2025;
	Settings moved, added support for GUI, Updated AimBot settings
]]

-- Requiring the module
local iHM = require(game:WaitForChild("ReplicatedStorage"):WaitForChild("InfoHolderModule"));

-- Quick check if the Anti-Cheat is being disabled
if iHM.avCon.DEBUGINFO.dOO then
	print("AntiCheat Disabled!");
	return;
end;

-- Initialize the module's function
iHM.Initialize();

local previousAimData = {};

-- Check if Debug Mode is enabled
if iHM.avCon.DEBUGINFO.dM then
	print("ServerSidedAntiCheat Connection... Successful!");
end;

-- Function to handle Speed/Teleport/JumpPower detection
local function detectSpeedHacks(player: Player?, character: Model?)
	local lastPosition = character.HumanoidRootPart.Position;

	while player.Parent and iHM.ssAC.pD.wS.ENABLED and task.wait(iHM.ssAC.pD.wS.SETTINGS.checkInterval) do
		local newPosition = character.HumanoidRootPart.Position;
		local distanceMoved = (lastPosition - newPosition).Magnitude;

		if distanceMoved > iHM.ssAC.pD.wS.SETTINGS.toleranceDelta then
			iHM.addStrike(player.UserId);
			if iHM.avCon.DEBUGINFO.dM then
				print(player.Name .. " is cheating -- Teleport/Speed Bypass/Jumppower Bypass/Flying/Invis");
				iHM.sendToWebhook(player.Name .. " is cheating -- Teleport/Speed Bypass/Jumppower Bypass/Flying/Invis");
			end;
			task.wait(2);
		end;
		lastPosition = newPosition;
	end;
end;

local function detectAimBot(player: Player?, character: Model?)
	while player.Parent and iHM.ssAC.pD.aB.ENABLED do
		local head = character:FindFirstChild("Head") or nil;
		if head then
			local aimVector = head.CFrame.LookVector;
			local prevData = previousAimData[player];
			if not prevData then
				prevData = {aimVector = aimVector, timestamp = tick()};
				previousAimData[player] = prevData;
			end
			local timeDelta = tick() - prevData.timestamp;
			if (prevData.aimVector - aimVector).magnitude > iHM.ssAC.pD.aB.SETTINGS.aimSnap and timeDelta < iHM.ssAC.pD.aB.SETTINGS.checkInterval then
				for _, otherPlayer in pairs(game:GetService("Players"):GetPlayers()) do
					if otherPlayer ~= player and otherPlayer.Character and otherPlayer.Character:FindFirstChild("Head") then
						local otherHead = otherPlayer.Character.Head;
						local directionToOther = (otherHead.Position - head.Position).unit;
						if aimVector:Dot(directionToOther) > 0.99 then -- Needs to be adjusted
							iHM.addStrike(player.UserId);
							if iHM.avCon.DEBUGINFO.dM then
								print(player.Name .. " is cheating -- Aimbot Detected");
								iHM.sendToWebhook(player.Name .. " is cheating Aimbot Detected");
							end;
							break;
						end;
					end;
				end;
			end;
			previousAimData[player] = {aimVector = aimVector, timestamp = tick()};
		end;
		task.wait();
	end;
end;

local function agePrevention(player: Player?)
	if iHM.ssAC.pD.aA.ENABLED and player.AccountAge < iHM.ssAC.pD.aA.SETTINGS.minimumAge then
		if iHM.avCon.DEBUGINFO.dM then
			print(player.Name .. " or " .. player.DisplayName .. " has just been kicked due to account not meeting age");
			iHM.sendToWebhook(player.Name .. " alt has been detected, account is " .. player.AccountAge .. " days old.")
		end;
		player:Kick("Your account is underaged.");
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
	iHM.sendNotification("The game is protected by Jupiter Development!", player.Name);
end);

game:GetService("Players").PlayerRemoving:Connect(function(player)
	previousAimData[player] = nil;
end);
