script_name("Autovest")
script_version("1.5")
script_author("Mike")
--original_author("akacross")
require("moonloader")
require("sampfuncs")
require('extensions-lite')
local sampev = require('lib.samp.events')
local effil = require("effil")
local json = require("dkjson")
local path = getWorkingDirectory() .. '\\config\\' 
local cfg = path .. 'autovest.json'
local _last_vest = 0
local _enabled = true
local specstate = false
local autoaccepter = false
local autoacceptertoggle = false
local _you_are_not_bodyguard = true
local ped, h = playerPed, playerHandle
local blank = {}
local autovest = {
    autosave = true,
    autovestcmd = "autovest",
    autoacceptercmd = "av",
    ddmodecmd = "ddmode",
    vestmodecmd = "vestmode",
    timer = 12,
    ddmode = false,
    enablebydefault = true,
    vestmode = 0,
    skinsurl = "https://raw.githubusercontent.com/Mikeyamaguchi/autovester/main/skins.json",
}

function main()
	blank = table.deepcopy(autovest)
	if not doesDirectoryExist(path) then
		createDirectory(path)
	end
	if doesFileExist(cfg) then
		loadJson()
	else
		blankJson()
	end
	while not isSampAvailable() do
		wait(100)
	end
	local res_aduty, aduty = getSampfuncsGlobalVar("aduty")
	if res_aduty then
		if aduty == 0 then
			setSampfuncsGlobalVar('aduty', 0)
		end
	else
	    setSampfuncsGlobalVar('aduty', 0)
	end
	local res_hideme, hideme = getSampfuncsGlobalVar("HideMe_check")
	if res_hideme then
		if hideme == 0 then
			setSampfuncsGlobalVar('HideMe_check', 0)
		end
	else
		setSampfuncsGlobalVar('HideMe_check', 0)
	end
	autovest.timer = autovest.ddmode and 7 or 12
	sampAddChatMessage("[Autovest]{ffff00} vestmode is currently set to "..vestmodename(autovest.vestmode)..".", 1999280)
	sampRegisterChatCommand(autovest.autovestcmd, function()
		_enabled = not _enabled
		sampAddChatMessage(string.format("[Autovest]{ffff00} Automatic vest %s.", _enabled and 'enabled' or 'disabled'), 1999280)
	end)
	sampRegisterChatCommand(autovest.autoacceptercmd, function()
		autoaccepter = not autoaccepter
		sampAddChatMessage(string.format("[Autovest]{ffff00} Autoaccepter is now %s.", autoaccepter and 'enabled' or 'disabled'), 1999280)
	end)
	sampRegisterChatCommand(autovest.ddmodecmd, function()
		autovest.ddmode = not autovest.ddmode
		sampAddChatMessage(string.format("[Autovest]{ffff00} ddmode is now %s.", autovest.ddmode and 'enabled' or 'disabled'), 1999280)
		autovest.timer = autovest.ddmode and 7 or 12
	end)
	sampRegisterChatCommand(autovest.vestmodecmd, function(params)
		if string.len(params) > 0 then
			if params == 'allies' then
				autovest.vestmode = 0
				sampAddChatMessage("[Autovest]{ffff00} vestmode is now set to allies.", 1999280)
			elseif params == 'everyone' then
				autovest.vestmode = 2
				sampAddChatMessage("[Autovest]{ffff00} vestmode is now set to everyone.", 1999280)
			else
				sampAddChatMessage("[Autovest]{ffff00} vestmode is currently set to "..vestmodename(autovest.vestmode)..".", 1999280)
				sampAddChatMessage('USAGE: /'..autovest.vestmodecmd..' [allies/everyone]', -1)
			end
		else
			sampAddChatMessage("[Autovest]{ffff00} vestmode is currently set to "..vestmodename(autovest.vestmode)..".", 1999280)
			sampAddChatMessage('USAGE: /'..autovest.vestmodecmd..' [allies/everyone]', -1)
		end
	end)
	autovest.timer = autovest.ddmode and 7 or 12
    if autovest.ddmode then
		_you_are_not_bodyguard = true
	end
	if not autovest.enablebydefault then
		_enabled = false
	end
	loadskinids()
	while true do
		wait(0)
		local _, aduty = getSampfuncsGlobalVar("aduty")
		local _, HideMe = getSampfuncsGlobalVar("HideMe_check")
		if _enabled and autovest.timer <= localClock() - _last_vest and not specstate and HideMe == 0 and aduty == 0 then
			if _you_are_not_bodyguard then
				autovest.timer = autovest.ddmode and 7 or 12
				for PlayerID = 0, sampGetMaxPlayerId(false) do
					local result, playerped = sampGetCharHandleBySampPlayerId(PlayerID)
					if result and not sampIsPlayerPaused(PlayerID) then
						local myX, myY, myZ = getCharCoordinates(ped)
						local playerX, playerY, playerZ = getCharCoordinates(playerped)
						local dist = getDistanceBetweenCoords3d(myX, myY, myZ, playerX, playerY, playerZ)
						if (autovest.ddmode and tostring(dist) or dist) < (autovest.ddmode and tostring(0.9) or 6) then
							if sampGetPlayerArmor(PlayerID) < 48 then
								local pAnimId = sampGetPlayerAnimationId(select(2, sampGetPlayerIdByCharHandle(ped)))
								local pAnimId2 = sampGetPlayerAnimationId(playerid)
								local aim, _ = getCharPlayerIsTargeting(h)
								if pAnimId ~= 1158 and pAnimId ~= 1159 and pAnimId ~= 1160 and pAnimId ~= 1161 and pAnimId ~= 1162
								and pAnimId ~= 1163 and pAnimId ~= 1164 and pAnimId ~= 1165 and pAnimId ~= 1166 and pAnimId ~= 1167
								and pAnimId ~= 1069 and pAnimId ~= 1070 and pAnimId2 ~= 746 and not aim then
									if autovest.vestmode == 0 then
										if has_number(skins, getCharModel(ped)) then
											sendGuard(PlayerID)
										end
										if autovest.vestmode == 2 then
											sendGuard(PlayerID)
										end
										if autoaccepter and autoacceptertoggle then
											local _, playerped = storeClosestEntities(ped)
											local result, PlayerID = sampGetPlayerIdByCharHandle(playerped)
											if result and playerped ~= ped then
												if getCharArmour(ped) < 49 and sampGetPlayerAnimationId(ped) ~= 746 then
													autoaccepternickname = sampGetPlayerNickname(PlayerID)
													local playerx, playery, playerz = getCharCoordinates(ped)
													local pedx, pedy, pedz = getCharCoordinates(playerped)
													if getDistanceBetweenCoords3d(playerx, playery, playerz, pedx, pedy, pedz) < 4 then
														if autoaccepternickname == autoaccepternick then
															sampSendChat("/accept bodyguard")
															autoacceptertoggle = false
														end
													end
												end
											end
										end
									end
								end
							end
						end
					end
				end
			end
		end
	end
end

function sendGuard(id)
	if autovest.ddmode then
		sampSendChat('/guardnear')
	else
		sampSendChat(string.format("/guard %d 200", id))
	end
	_last_vest = localClock()
end

function sampevHandler()
	sampev.onServerMessage = function(color, text)
		if string.find(text, "has taken control of the") and color == -65366 and autoaccepter then
			autoaccepter = false
			sampAddChatMessage("[Autovest]{ffff00} Automatic vest disabled because point had ended.", 1999280)
		end
		if text:find("That player isn't near you.") and color == -1347440726 then
			if autovest.ddmode then
				_last_vest = localClock() - 6.8
			else
				_last_vest = localClock() - 11.8
			end
		end
		if text:find("You can't /guard while aiming.") and color == -1347440726 then
			if autovest.ddmode then
				_last_vest = localClock() - 6.8
			else
				_last_vest = localClock() - 11.8
			end
		end
		if text:find("You must wait") and text:find("seconds before selling another vest.") then
			cooldown = text:find("wait %d+ seconds")
			autovest.timer = cooldown + 0.5
		end
		if text:find("You are not a bodyguard.") and color ==  -1347440726 then
			_you_are_not_bodyguard = false
		end
		if text:match("* You are now a Bodyguard, type /help to see your new commands.") then
			_you_are_not_bodyguard = true
		end
		if text:find("* Bodyguard ") and text:find(" wants to protect you for $200, type /accept bodyguard to accept.") and color == 869072810 then
			if color >= 40 and text ~= 746 then
				autoaccepternick = text:match("%* Bodyguard (.+) wants to protect you for %$200, type %/accept bodyguard to accept%.")
				autoaccepternick = autoaccepternick:gsub("%s+", "_")
				autoacceptertoggle = true
			end
			if getCharArmour(ped) < 48 and sampGetPlayerAnimationId(ped) ~= 746 and autoaccepter and not specstate then
				sampSendChat("/accept bodyguard")
				autoacceptertoggle = false
			end
			sampev.onTogglePlayerSpectating = function(state)
				specstate = state
			end
		end
	end
end

function loadskinids()
	local skins = {}
	local function resolve(response)
		if response.text ~= nil then
			local success, jsonData = pcall(json.decode, response.text)
			if success then
				for _, skinid in ipairs(jsonData) do
					table.insert(skins, tonumber(skinid))
				end
			else
				sampAddChatMessage(string.format("{ABB2B9}[%s]{FFFFFF} Error decoding JSON: %s", script.this.name, jsonData), -1)
			end
		else
			sampAddChatMessage(string.format("{ABB2B9}[%s]{FFFFFF} No Skin ID found in the URL.", script.this.name), -1)
		end
	end
	local function reject(err)
		sampAddChatMessage(string.format("{ABB2B9}[%s]{FFFFFF} %s", script.this.name, err), -1)
	end
	local request_thread = effil.thread(function(method, url, args)
		local requests = require 'requests'
		local result, response = pcall(requests.request, method, url, args)
		if result then
			response.json, response.xml = nil, nil
			return true, response
		else
			return false, response
		end
	end)('GET', autovest.skinsurl, nil)
	lua_thread.create(function()
		local runner = request_thread
		while true do
			local status, err = runner:status()
			if not err then
				if status == 'completed' then
					local result, response = runner:get()
					if result then
						resolve(response)
					else
						reject(response)
					end
					return
				elseif status == 'canceled' then
					return reject(status)
				end
			else
				return reject(err)
			end
			wait(0)
		end
	end)
	return skins
end

function onScriptTerminate(scr, quitGame)
    if scr == script.this then
        if autovest.autosave then
            saveJson()
        end
    end
end

function blankJson()
    autovest = table.deepcopy(blank)
    saveJson()
    loadJson()
end

function loadJson()
    local f = io.open(cfg, "r")
    if f then
        local jsonData = f:read("*all")
        f:close()
        autovest = json.decode(jsonData)
    end
end

function saveJson()
    local f = io.open(cfg, "w")
    if f then
        local jsonData = json.encode(autovest, { indent = true })
        f:write(jsonData)
        f:close()
    end
end

function has_number(tab, val)
    for index, value in ipairs(tab) do
        if tonumber(value) == val then
            return true
        end
    end
    return false
end

function vestmodename(vestmode)
	if vestmode == 0 then
		return 'allies'
	elseif vestmode == 2 then
		return 'Everyone'
	end
end

sampevHandler()