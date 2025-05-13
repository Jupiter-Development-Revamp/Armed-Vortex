-- Place inside ServerScriptService
-- Fully Tested
-- NOT EDITABLE (unless you know what your doing)
--[[
    Project: Armed-Vortex;
    Developers: StyxDeveloper;
    Contributors: nil;
    Description: Serversided anticheat;
    Version: v1.1.1;
    Update Date: 5/13/2025;
	Monitors animations played and checks against a blacklisted one.
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

local function detectSpeedHacks(player: Player?, character: Model?)
	local lastPosition = character.HumanoidRootPart.Position;

	while player.Parent and iHM.ssAC.pD.wS.ENABLED and task.wait(iHM.ssAC.pD.wS.SETTINGS.checkInterval) do
		local newPosition = character.HumanoidRootPart.Position;
		local horizontalDistanceMoved = math.sqrt((lastPosition.X - newPosition.X)^2 + (lastPosition.Z - newPosition.Z)^2);

		if horizontalDistanceMoved > iHM.ssAC.pD.wS.SETTINGS.toleranceDelta then
			iHM.addStrike(player.UserId);
			if iHM.avCon.DEBUGINFO.dM then
				print(player.Name .. " is cheating -- Speed Hack Bypass Detected (" .. horizontalDistanceMoved .. " studs)");
				iHM.sendToWebhook(player.Name .. " is cheating -- Speed Hack Bypass Detected (" .. horizontalDistanceMoved .. " studs)");
			end;
			task.wait(2);
		end;
		lastPosition = newPosition;
	end;
end;

local function detectJumpHacks(player: Player?, character: Model?)
	if not character then return; end;
	local humanoid = character:FindFirstChildWhichIsA("Humanoid");
	local rootPart = character:FindFirstChild("HumanoidRootPart");
	if not humanoid or not rootPart then return; end;

	local lastY = rootPart.Position.Y
	while player.Parent and iHM.ssAC.pD.jP.ENABLED do
		task.wait(0.5);
		local heightDiff = rootPart.Position.Y - lastY;
		if heightDiff > iHM.ssAC.pD.jP.SETTINGS.expectedJumpPower then
			iHM.addStrike(player.UserId);
			if iHM.avCon.DEBUGINFO.dM then
				print(player.Name .. " is cheating -- Jump Power Bypass Detected (" .. heightDiff .. " studs)");
				iHM.sendToWebhook(player.Name .. " is cheating -- Jump Power Bypass Detected (" .. heightDiff .. " studs)");
			end;
			task.wait(2);
		end;
		lastY = rootPart.Position.Y;
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
			iHM.sendToWebhook(player.Name .. " alt has been detected, account is " .. player.AccountAge .. " days old.");
		end;
		player:Kick("Your account is underaged.");
	end;
end;

local function badAnimationDetection(player: Player, character: Model)
	local humanoid = character:FindFirstChildOfClass("Humanoid");
	if not humanoid then return; end;
	local animationConnection
	animationConnection = humanoid.AnimationPlayed:Connect(function(track)
		local animId = track.Animation and track.Animation.AnimationId or "unknown";
		if iHM.ssAC.pD.BAD_ANIMATION_IDS[animId] then
			warn("[ANIMATION BAN] " .. player.Name .. " attempted to play a banned animation: " .. animId);
			iHM.sendNotification("Why? Do you think your funny, because you are not!", player.Name);
			iHM.sendToWebhook(player.Name .. " was kicked for using inappropriate animations!");
			player:Kick("Inappropriate animation detected.");
		end;
	end);
	character.AncestryChanged:Connect(function(_, parent)
		if not parent then
			animationConnection:Disconnect();
		end;
	end);
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
		coroutine.wrap(detectJumpHacks)(player, character);
		coroutine.wrap(detectAimBot)(player, character);
		coroutine.wrap(badAnimationDetection)(player, character);
	end);
	iHM.sendNotification("The game is protected by Jupiter Development!", player.Name);
end);

game:GetService("Players").PlayerRemoving:Connect(function(player)
	previousAimData[player] = nil;
end);
