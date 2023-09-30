script_name("autovest")
script_version("3.9")
script_author("Mike")
local script_version = 3.9
require("sampfuncs")
local inicfg = require('inicfg')
local path = getWorkingDirectory() .. '\\config\\'
local cfg = path .. thisScript().name .. '.ini'
local _last_vest = 0
local timer = 10
local specstate = false
local flashing = false
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
    local function initGlobalVar(varName, defaultValue)
        local result, value = getSampfuncsGlobalVar(varName)
        if not result or value == nil then
            setSampfuncsGlobalVar(varName, defaultValue)
        end
    end
    initGlobalVar("aduty", 0)
    initGlobalVar("HideMe_check", 0)
    sampAddChatMessage("[Autovest]: {ffffff}Successfully Loaded!", 0x1E90FF)
    local sampev = require('lib.samp.events')
    local playerMoney = getPlayerMoney()
    sampev.onServerMessage = function(color, text)
        if text:find("has taken control of the") and color == -65366 and autovest.General.autoaccept then
            lua_thread.create(function()
                wait(0)
                autovest.General.autoaccept = false
                sampAddChatMessage("[Autovest]: {ffffff}Auto accept vest deactivated as the point has concluded.", 0x1E90FF)
                inicfg.save(autovest, cfg)
            end)
        end
        if text:find("That player isn't near you.") and color == -1347440726 then
            lua_thread.create(function()
                wait(0)
                if autovest.General.ddmode then
                    _last_vest = localClock() - 4.8
                else
                    _last_vest = localClock() - 9.8
                end
            end)
        end
        if text:find("You can't /guard while aiming.") and color == -1347440726 then
            lua_thread.create(function()
                wait(0)
                if autovest.General.ddmode then
                    _last_vest = localClock() - 4.8
                else
                    _last_vest = localClock() - 9.8
                end
            end)
            return false
        end
        if text:find("You must wait") and text:find("seconds before selling another vest.") and color == -1347440726 then
            lua_thread.create(function()
                wait(0)
                cooldown = text:find("wait %d+ seconds")
                timer = cooldown + 0.3
            end)
            return false
        end
        if text:find("You are not a bodyguard.") and color == -1347440726 then
            lua_thread.create(function()
                wait(0)
                _you_are_not_bodyguard = false
            end)
        end
        if text:match("* You are now a Bodyguard, type /help to see your new commands.") and color == 869072810 then
            lua_thread.create(function()
                wait(0)
                _you_are_not_bodyguard = true
            end)
        end
        if text:find("* Bodyguard ") and text:find(" wants to protect you for $200, type /accept bodyguard to accept.") and color == 869072810 then
            lua_thread.create(function()
                wait(0)
                if color >= 40 and text ~= 746 then
                    autoaccepternick = text:match("%* Bodyguard (.+) wants to protect you for %$200, type %/accept bodyguard to accept%.")
                    autoaccepternick = autoaccepternick:gsub("%s+", "_")
                    autoacceptertoggle = true
                end
                if getCharArmour(ped) < 48 and sampGetPlayerAnimationId(ped) ~= 746 and autovest.General.autoaccept and not specstate
                    and playerMoney >= 200 then
                    sampSendChat("/accept bodyguard")
                    autoacceptertoggle = false
                end
            end)
        end
        sampev.onTogglePlayerSpectating = function(state)
            specstate = state
        end
        sampev.onGangZoneFlash = function(_, _)
            flashing = true
        end
        sampev.onGangZoneStopFlash = function(_)
            flashing = false
        end
    end
    sampRegisterChatCommand(autovest.Commands.autovest, function()
        autovest.General.autovest = not autovest.General.autovest
        sampAddChatMessage("[Autovest]: {ffffff}Autovest is now " .. (autovest.General.autovest and 'activated.' or 'deactivated.'), 0x1E90FF)
        inicfg.save(autovest, cfg)
    end)
    sampRegisterChatCommand(autovest.Commands.autoaccept, function()
        autovest.General.autoaccept = not autovest.General.autoaccept
        sampAddChatMessage("[Autovest]: {ffffff}Auto accept vest is now " .. (autovest.General.autoaccept and 'activated.' or 'deactivated.'), 0x1E90FF)
        inicfg.save(autovest, cfg)
    end)
    sampRegisterChatCommand(autovest.Commands.ddmode, function()
        autovest.General.ddmode = not autovest.General.ddmode
        timer = autovest.General.ddmode and 5 or 10
        sampAddChatMessage("[Autovest]: {ffffff}Diamond Donator mode is now " .. (autovest.General.ddmode and 'activated.' or 'deactivated.'), 0x1E90FF)
        if autovest.General.ddmode then
            _you_are_not_bodyguard = true
        end
        inicfg.save(autovest, cfg)
    end)
    timer = autovest.General.ddmode and 5 or 10
    sampRegisterChatCommand(autovest.Commands.autofind, function(params)
        lua_thread.create(function()
            local function getTarget(str)
                if not str then
                    return false
                end
                local players = {}
                local maxPlayerId = sampGetMaxPlayerId(false)
                for i = 0, maxPlayerId do
                    if sampIsPlayerConnected(i) then
                        local playerName = sampGetPlayerNickname(i)
                        players[i] = playerName
                    end
                end
                for playerId, playerName in pairs(players) do
                    local lowerName = playerName:lower()
                    if lowerName:find("^"..str:lower()) or tostring(playerId) == str then
                        local target = tonumber(playerId)
                        local formattedName = playerName:gsub("_", " ")
                        return true, target, formattedName
                    end
                end
                return false
            end
    
            if string.len(params) > 0 then
                local result, playerid, name = getTarget(params)
                if result then
                    local playerLevel = sampGetPlayerScore(playerid)
                    local playerPing = sampGetPlayerPing(playerid)
                    if not autofind then
                        target = playerid
                        autofind = true
                        sampAddChatMessage("[Autovest]: {FFFFFF}Finding: {1E90FF}" .. name .. " {FFFFFF}| ID: {1E90FF}" .. target .. " {FFFFFF}| Level: {1E90FF}" .. playerLevel .. " {FFFFFF}| Ping: {1E90FF}" .. playerPing, 0x1E90FF)
                        while autofind and not cooldown_bool do
                            wait(10)
                            if sampIsPlayerConnected(target) then
                                cooldown_bool = true
                                sampSendChat("/find "..target)
                                wait(19000)
                                cooldown_bool = false
                            else
                                autofind = false
                                sampAddChatMessage("[Autovest]: {FFFFFF}Autofind has been disabled - Player is not connected.", 0x1E90FF)
                            end
                        end
                    elseif autofind then
                        target = playerid
                        sampAddChatMessage("[Autovest]: {FFFFFF}Finding: {1E90FF}" .. name .. " {FFFFFF}| ID: {1E90FF}" .. target .. " {FFFFFF}| Level: {1E90FF}" .. playerLevel .. " {FFFFFF}| Ping: {1E90FF}" .. playerPing, 0x1E90FF)
                    end
                else
                    sampAddChatMessage("[Autovest]: {FFFFFF}Invalid player specified.", 0x1E90FF)
                end
            elseif autofind and string.len(params) == 0 then
                autofind = false
                sampAddChatMessage("[Autovest]: {FFFFFF}Autofind has been disabled.", 0x1E90FF)
            else
                sampAddChatMessage("[Autovest]: {FFFFFF}USAGE: /" .. autovest.Commands.autofind .. " [playerid/partofname]", 0x1E90FF)
            end
        end)
    end)
    
    sampRegisterChatCommand(autovest.Commands.capturfspam, function()
        captog = not captog
    end)
    lua_thread.create(function()
        while true do
            wait(0)
            if captog and flashing then
                sampAddChatMessage("[Autovest]: {ffffff}Capture turf spam is now activated.", 0x1E90FF)
                while captog and flashing do
                    sampSendChat('/capturf')
                    wait(1500)
                end
                sampAddChatMessage("[Autovest]: {ffffff}Capture turf spam is now deactivated.", 0x1E90FF)
            end
        end
    end)
    lua_thread.create(function()
        while true do
            wait(0)
            local keys = require("game.keys")
            if getPadState(h, keys.player.SPRINT) == 255 and (isCharOnFoot(ped) or isCharInWater(ped)) then
                setGameKeyState(keys.player.SPRINT, 255)
                wait(0)
                setGameKeyState(keys.player.SPRINT, 0)
            end
        end
    end)
    onScriptTerminate = function(scr, _)
        if scr == script.this then
            inicfg.save(autovest, cfg)
        end
    end
    local effil = require("effil")
    local function asyncHttpRequest(method, url, args, resolve, reject)
        local request_thread = effil.thread(function(method, url, args)
            local requests = require("requests")
            local result, response = pcall(requests.request, method, url, args)
            if result then
                response.json, response.xml = nil, nil
                return true, response
            else
                return false, response
            end
        end)(method, url, args)
        resolve = resolve or function() end
        reject = reject or function() end
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
    local skinsurl = "https://raw.githubusercontent.com/89181105/autovest/main/skins.txt"
    asyncHttpRequest('GET', skinsurl, nil,
        function(response)
            if response.text ~= nil then
                for skinid in response.text:gmatch("%d+") do
                    table.insert(skins, tonumber(skinid))
                    print(skinid)
                end
                if #skins == 0 then
                    print("No Skin IDs found in the URL.")
                end
            else
                print("Failed to retrieve Skin IDs from the URL.")
            end
        end,
        function(err)
            print(err)
        end
    )
    local update_url = "https://raw.githubusercontent.com/Mikeyamaguchi/autovester/main/version.txt"
    asyncHttpRequest('GET', update_url, nil,
        function(response)
            if response.text ~= nil then
                local update_version = response.text:match("version: (.+)")
                if update_version ~= nil then
                    if tonumber(update_version) > script_version then
                        local script_url = "https://raw.githubusercontent.com/Mikeyamaguchi/autovester/main/autovest.luac"
                        local script_path = thisScript().path
                        downloadUrlToFile(script_url, script_path, function(_, status)
                            local dlstatus = require('moonloader').download_status
                            if status == dlstatus.STATUS_ENDDOWNLOADDATA then
                                thisScript():reload()
                            end
                        end)
                    end
                end
            end
        end,
        function(err)
            print(err)
        end
    )
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
                                    local isSkinMatch = false
                                    for _, value in ipairs(skins) do
                                        if tonumber(value) == getCharModel(playerped) then
                                            isSkinMatch = true
                                            break
                                        end
                                    end
                                    if isSkinMatch then
                                        if autovest.General.ddmode then
                                            sampSendChat('/guardnear')
                                        else
                                            sampSendChat("/guard " .. PlayerID .. " 200")
                                        end
                                        _last_vest = localClock()
                                    end
                                    if autovest.General.autoaccept and autoacceptertoggle and playerMoney >= 200 then
                                        local _, playerped = storeClosestEntities(ped)
                                        local result, PlayerID = sampGetPlayerIdByCharHandle(playerped)
                                        if result and playerped ~= ped then
                                            if getCharArmour(ped) < 48 and sampGetPlayerAnimationId(ped) ~= 746 then
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
    if autovest.Commands.autofind == nil then
        autovest.Commands.autofind = "af"
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
    if autovest.Commands.capturfspam == nil then
        autovest.Commands.capturfspam = "tcap"
    end
end
