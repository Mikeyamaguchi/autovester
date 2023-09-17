script_name("Autovest")
script_version("3.9")
script_author("Mike")
local script_version = 3.9
require("sampfuncs")
local sampev = require('lib.samp.events')
local dlstatus = require('moonloader').download_status
local effil = require("effil")
local inicfg = require('inicfg')
local path = getWorkingDirectory() .. '\\config\\'
local cfg = path .. thisScript().name .. '.ini'
local script_path = thisScript().path
local skinsurl = "https://raw.githubusercontent.com/Mikeyamaguchi/autovester/main/skins.txt"
local update_url = "https://raw.githubusercontent.com/Mikeyamaguchi/autovester/main/version.txt"
local script_url = "https://raw.githubusercontent.com/Mikeyamaguchi/autovester/main/autovest.luac"
local _last_vest = 0
local timer = 10
local specstate = false
local autoacceptertoggle = false
local _you_are_not_bodyguard = true
local ped, h = playerPed, playerHandle
local autovest = {}
local skins = {}

function main()
    if not doesDirectoryExist(path) then
        createDirectory(path)
    end
    if doesFileExist(cfg) then
        autovest = inicfg.load(nil, cfg)
        repairmissing()
        inicfg.save(autovest, cfg)
    else
        autovest = {}
        repairmissing()
        inicfg.save(autovest, cfg)
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
    timer = autovest.General.ddmode and 5 or 10
    sampAddChatMessage("[Autovest]: {ffffff}Successfully Loaded!", 0x1E90FF)
    sampRegisterChatCommand(autovest.Commands.autovest, function()
        autovest.General.autovest = not autovest.General.autovest
        sampAddChatMessage(string.format("[Autovest]: {ffffff}Autovest is now %s.", autovest.General.autovest and 'activated' or 'deactivated'), 0x1E90FF)
    end)
    sampRegisterChatCommand(autovest.Commands.autoaccept, function()
        autovest.General.autoaccept = not autovest.General.autoaccept
        sampAddChatMessage(string.format("[Autovest]: {ffffff}Auto Accept Vest is now %s.", autovest.General.autoaccept and 'activated' or 'deactivated'), 0x1E90FF)
    end)
    sampRegisterChatCommand(autovest.Commands.ddmode, function()
        autovest.General.ddmode = not autovest.General.ddmode
        sampAddChatMessage(string.format("[Autovest]: {ffffff}Diamond Donator Mode is now %s.", autovest.General.ddmode and 'activated' or 'deactivated'), 0x1E90FF)
        timer = autovest.General.ddmode and 5 or 10
    end)
    loadskinids()
    update_script(false, false)
    while true do
        wait(0)
        local _, aduty = getSampfuncsGlobalVar("aduty")
        local _, HideMe = getSampfuncsGlobalVar("HideMe_check")
        if autovest.General.autovest and timer <= localClock() - _last_vest and not specstate and HideMe == 0 and aduty == 0 then
            if _you_are_not_bodyguard then
                timer = autovest.General.ddmode and 5 or 10
                for PlayerID = 0, sampGetMaxPlayerId(false) do
                    local result, playerped = sampGetCharHandleBySampPlayerId(PlayerID)
                    if result and not sampIsPlayerPaused(PlayerID) then
                        local myX, myY, myZ = getCharCoordinates(ped)
                        local playerX, playerY, playerZ = getCharCoordinates(playerped)
                        local dist = getDistanceBetweenCoords3d(myX, myY, myZ, playerX, playerY, playerZ)
                        if (autovest.General.ddmode and tostring(dist) or dist) < (autovest.General.ddmode and tostring(0.9) or 6) then
                            if sampGetPlayerArmor(PlayerID) < 49 then
                                local pAnimId = sampGetPlayerAnimationId(select(2, sampGetPlayerIdByCharHandle(ped)))
                                local pAnimId2 = sampGetPlayerAnimationId(playerid)
                                local aim, _ = getCharPlayerIsTargeting(h)
                                if pAnimId ~= 1158 and pAnimId ~= 1159 and pAnimId ~= 1160 and pAnimId ~= 1161 and pAnimId ~= 1162
                                    and pAnimId ~= 1163 and pAnimId ~= 1164 and pAnimId ~= 1165 and pAnimId ~= 1166 and pAnimId ~= 1167
                                    and pAnimId ~= 1069 and pAnimId ~= 1070 and pAnimId2 ~= 746 and not aim then
                                    if has_number(skins, getCharModel(playerped)) then
                                        if autovest.General.ddmode then
                                            sampSendChat('/guardnear')
                                        else
                                            sampSendChat(string.format("/guard %d 200", PlayerID))
                                        end
                                    end
                                    if autovest.General.autoaccept and autoacceptertoggle then
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


function sampevHandler()
    sampev.onServerMessage = function(color, text)
        if string.find(text, "has taken control of the") and color == -65366 and autovest.General.autoaccept then
            autovest.General.autoaccept = false
            sampAddChatMessage("[Autovest]: {ffffff}Auto accept vest deactivated as the point has concluded", 0x1E90FF)
        end
        if text:find("That player isn't near you.") and color == -1347440726 then
            if autovest.General.ddmode then
                _last_vest = localClock() - 6.8
            else
                _last_vest = localClock() - 11.8
            end
        end
        if text:find("You can't /guard while aiming.") and color == -1347440726 then
            if autovest.General.ddmode then
                _last_vest = localClock() - 6.8
            else
                _last_vest = localClock() - 11.8
                return false
            end
        end
        if text:find("You must wait") and text:find("seconds before selling another vest.") then
            cooldown = text:find("wait %d+ seconds")
            timer = cooldown + 0.5
            return false
        end
        if text:find("You are not a bodyguard.") and color == -1347440726 then
            _you_are_not_bodyguard = false
        end
        if text:match("* You are now a Bodyguard, type /help to see your new commands.") and color == 869072810 then
            _you_are_not_bodyguard = true
        end
        if text:find("* Bodyguard ") and text:find(" wants to protect you for $200, type /accept bodyguard to accept.") and color == 869072810 then
            if color >= 40 and text ~= 746 then
                autoaccepternick = text:match("%* Bodyguard (.+) wants to protect you for %$200, type %/accept bodyguard to accept%.")
                autoaccepternick = autoaccepternick:gsub("%s+", "_")
                autoacceptertoggle = true
            end
            if getCharArmour(ped) < 48 and sampGetPlayerAnimationId(ped) ~= 746 and autovest.General.autoaccept and not specstate then
                sampSendChat("/accept bodyguard")
                autoacceptertoggle = false
            end
            sampev.onTogglePlayerSpectating = function(state)
                specstate = state
            end
        end
    end
end

function repairmissing()
    if autovest.General == nil then
        autovest.General = {}
    end
    if autovest.General.autovest == nil then
        autovest.General.autovest = false
    end
    if autovest.General.autoaccept == nil then
        autovest.General.autoaccept = false
    end
    if autovest.General.ddmode == nil then
        autovest.General.ddmode = false
    end
    if autovest.Commands == nil then
        autovest.Commands = {}
    end
    if autovest.Commands.autovest == nil then
        autovest.Commands.autovest = "avest"
    end
    if autovest.Commands.autoaccept == nil then
        autovest.Commands.autoaccept = "av"
    end
    if autovest.Commands.ddmode == nil then
        autovest.Commands.ddmode = "ddmode"
    end
end

function has_number(tab, val)
    for _, value in ipairs(tab) do
        if tonumber(value) == val then
            return true
        end
    end
    return false
end

function loadskinids()
    asyncHttpRequest('GET', skinsurl, nil,
    function(response)
        if response.text ~= nil then
            for skinid in response.text:gmatch("%d+") do
                table.insert(skins, tonumber(skinid))
            end
            if #skins == nil then
                sampAddChatMessage("[Autovest]: {FFFFFF}No Skin IDs found in the URL.", 0x1E90FF)
            end
        else
            sampAddChatMessage("[Autovest]: {FFFFFF}Failed to fetch Skin IDs from the URL.", 0x1E90FF)
        end
    end,
    function(err)
        sampAddChatMessage(string.format("[Autovest]: {FFFFFF}%s", err), 0x1E90FF)
    end)
end

function update_script(noupdatecheck, noerrorcheck)
	asyncHttpRequest('GET', update_url, nil,
		function(response)
			if response.text ~= nil then
				update_version = response.text:match("version: (.+)")
				if update_version ~= nil then
					if tonumber(update_version) > script_version then
						sampAddChatMessage("[Autovest]: {FFFFFF}Fresh Autovest version ready. Update rolling...", 0x1E90FF)
						downloadUrlToFile(script_url, script_path, function(id, status)
							if status == dlstatus.STATUS_ENDDOWNLOADDATA then
								sampAddChatMessage("[Autovest]: {FFFFFF}Update complete! Reloading Autovest...", 0x1E90FF)
								thisScript():reload()
							end
						end)
					else
						if noupdatecheck then
							sampAddChatMessage("[Autovest]: {FFFFFF}Autovest is up to date.", 0x1E90FF)
						end
					end
				end
			end
		end,
		function(err)
			if noerrorcheck then
				sampAddChatMessage(string.format("[Autovest]: {FFFFFF}%s", err), 0x1E90FF)
			end
		end
	)
end

function asyncHttpRequest(method, url, args, resolve, reject)
    local request_thread = effil.thread(function(method, url, args)
        local requests = require 'requests'
        local result, response = pcall(requests.request, method, url, args)
        if result then
            response.json, response.xml = nil, nil
            return true, response
        else
            return false, response
        end
    end)
    (method, url, args)
    if not resolve then
        resolve = function()
        end
    end
    if not reject then
        reject = function()
        end
    end
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
end

function onScriptTerminate(scr, quitGame)
    if scr == script.this then
        inicfg.save(autovest, cfg)
    end
end

sampevHandler()
