local isASLActive = false
local aslCamera = nil
local currentAnimations = {}
local targetPlayer = nil
local isCameraLocked = false
local isThirdPersonMode = false  -- New flag for third-person mode
local isTypingActive = false  -- Track if currently typing in third-person mode

-- Utility Functions
local function LoadAnimDict(dict)
    if not HasAnimDictLoaded(dict) then
        RequestAnimDict(dict)
        while not HasAnimDictLoaded(dict) do
            Wait(1)
        end
    end
end

local function GetNearestPlayer()
    local players = GetActivePlayers()
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    local nearestPlayer = nil
    local nearestDistance = math.huge
    
    for _, player in ipairs(players) do
        if player ~= PlayerId() then
            local targetPed = GetPlayerPed(player)
            if DoesEntityExist(targetPed) then
                local targetCoords = GetEntityCoords(targetPed)
                local distance = #(playerCoords - targetCoords)
                
                if distance < Config.Settings.maxTargetDistance and distance < nearestDistance then
                    nearestDistance = distance
                    nearestPlayer = targetPed
                end
            end
        end
    end
    
    return nearestPlayer, nearestDistance
end

local function CreateASLCamera()
    local playerPed = PlayerPedId()
    
    if not targetPlayer then  -- Self mode (no target)
        -- Position camera in front of player looking at them
        local playerCoords = GetEntityCoords(playerPed)
        local playerHeading = GetEntityHeading(playerPed)
        
        -- Calculate position in front of player
        local rad = math.rad(playerHeading)
        local distance = 1.5 -- Distance in front of player
        local height = 0.5 -- Height offset
        
        local camX = playerCoords.x - math.sin(rad) * distance
        local camY = playerCoords.y + math.cos(rad) * distance
        local camZ = playerCoords.z + height
        
        -- Create camera
        aslCamera = CreateCamWithParams(
            "DEFAULT_SCRIPTED_CAMERA",
            camX, camY, camZ,
            0.0, 0.0, 0.0,
            Config.Settings.cameraFOV,
            true, 2
        )
        
        -- Point camera at player's upper body
        PointCamAtEntity(aslCamera, playerPed, 0.0, 0.0, 0.5, true)
    else
        -- Normal mode: Camera from player position looking at target
        local playerCoords = GetEntityCoords(playerPed)
        local playerHeading = GetEntityHeading(playerPed)
        local rad = math.rad(playerHeading)
        
        -- Position camera at same height, slightly forward
        local forwardOffset = 0.5  -- Move camera forward from player
        local height = 0.5  -- Same height offset
        
        local camX = playerCoords.x - math.sin(rad) * forwardOffset
        local camY = playerCoords.y + math.cos(rad) * forwardOffset
        local camZ = playerCoords.z + height
        
        -- Create camera
        aslCamera = CreateCamWithParams(
            "DEFAULT_SCRIPTED_CAMERA",
            camX, camY, camZ,
            0.0, 0.0, 0.0,
            Config.Settings.cameraFOV,
            true, 2
        )
        
        -- Focus on the target player
        PointCamAtEntity(aslCamera, targetPlayer, 0.0, 0.0, 0.5, true)
    end
    
    -- Smooth transition to camera
    RenderScriptCams(true, true, Config.Settings.cameraTransitionTime, true, true)
    
    return aslCamera
end

local function RestoreCamera()
    if aslCamera then
        RenderScriptCams(false, true, Config.Settings.cameraTransitionTime, true, true)
        DestroyCam(aslCamera, false)
        aslCamera = nil
    end
    
    -- Restore third person view
    SetFollowPedCamViewMode(0)
end

local function NormalizeText(text)
    local normalized = string.lower(text)
    
    -- Replace abbreviations
    for abbr, full in pairs(Config.TextRules.abbreviations) do
        normalized = string.gsub(normalized, "%f[%a]" .. abbr .. "%f[%A]", full)
    end
    
    return normalized
end

local function ParseTextForAnimations(text)
    local animations = {}
    local normalizedText = NormalizeText(text)
    
    -- First, check if the entire text matches a phrase animation
    if Config.PhraseAnimations[normalizedText] then
        local animData = Config.PhraseAnimations[normalizedText]
        table.insert(animations, {
            type = "phrase",
            animation = animData,
            text = normalizedText,
            duration = animData.duration or Config.Settings.wordDuration
        })
        return animations
    end
    
    -- Check for partial phrase matches
    for phrase, animData in pairs(Config.PhraseAnimations) do
        if string.find(normalizedText, phrase, 1, true) then
            -- Add the phrase animation
            table.insert(animations, {
                type = "phrase",
                animation = animData,
                text = phrase,
                duration = animData.duration or Config.Settings.wordDuration
            })
            -- Remove the phrase from the text
            normalizedText = string.gsub(normalizedText, phrase, "")
        end
    end
    
    -- Split remaining text into words
    local words = {}
    for word in string.gmatch(normalizedText, "%S+") do
        table.insert(words, word)
    end
    
    -- Process each word
    for _, word in ipairs(words) do
        -- Check if word has a phrase animation
        if Config.PhraseAnimations[word] then
            local animData = Config.PhraseAnimations[word]
            table.insert(animations, {
                type = "word",
                animation = animData,
                text = word,
                duration = animData.duration or Config.Settings.wordDuration
            })
        else
            -- Spell out the word letter by letter
            for i = 1, #word do
                local char = string.sub(word, i, i)
                
                if Config.LetterAnimations[char] then
                    table.insert(animations, {
                        type = "letter",
                        animation = Config.LetterAnimations[char],
                        text = char,
                        duration = Config.Settings.letterDuration
                    })
                elseif Config.NumberAnimations[char] then
                    table.insert(animations, {
                        type = "number",
                        animation = Config.NumberAnimations[char],
                        text = char,
                        duration = Config.Settings.letterDuration
                    })
                elseif Config.SpecialAnimations[char] then
                    if Config.SpecialAnimations[char] then
                        table.insert(animations, {
                            type = "special",
                            animation = Config.SpecialAnimations[char],
                            text = char,
                            duration = Config.Settings.letterDuration
                        })
                    end
                end
            end
            
            -- Add pause between words
            table.insert(animations, {
                type = "pause",
                duration = Config.Settings.pauseBetweenWords
            })
        end
    end
    
    return animations
end

local function PlayASLAnimation(animData)
    local playerPed = PlayerPedId()
    
    if animData.type == "pause" then
        -- Just wait during pause
        Wait(animData.duration)
        return
    end
    
    -- Check if animation data exists
    if not animData.animation or not animData.animation.dict or not animData.animation.name then
        if Config.Settings.debugMode then
            print(string.format("^3[ASL Debug] Missing animation data for: %s^0", animData.text or "unknown"))
        end
        return
    end
    
    -- Extract dictionary and animation name
    local animDict = animData.animation.dict
    local animName = animData.animation.name
    
    -- Debug output
    if Config.Settings.debugMode then
        print(string.format("^2[ASL Debug] Playing: Dict=%s, Name=%s, Text=%s^0", animDict, animName, animData.text))
    end
    
    -- Load animation dictionary
    LoadAnimDict(animDict)
    
    -- Verify animation loaded
    if not HasAnimDictLoaded(animDict) then
        if Config.Settings.debugMode then
            print(string.format("^1[ASL Debug] Failed to load animation dictionary: %s^0", animDict))
        end
        SendNUIMessage({
            type = 'updateStatus',
            status = 'Animation not found: ' .. animDict
        })
        return
    end
    
    -- Play animation
    TaskPlayAnim(
        playerPed,
        animDict,
        animName,
        Config.Settings.blendInSpeed,
        Config.Settings.blendOutSpeed,
        animData.duration,
        Config.Settings.animFlag,
        0.0,
        false, false, false
    )
    
    -- Check if animation started
    if not IsEntityPlayingAnim(playerPed, animDict, animName, 3) then
        Wait(50) -- Small delay to let animation start
        if not IsEntityPlayingAnim(playerPed, animDict, animName, 3) and Config.Settings.debugMode then
            print(string.format("^3[ASL Debug] Animation may not have started: %s/%s^0", animDict, animName))
        end
    end
    
    -- Wait for animation to complete
    Wait(animData.duration)
    
    -- Add pause between letters
    if animData.type == "letter" then
        Wait(Config.Settings.pauseBetweenLetters)
    end
    
    -- Clean up dictionary if not needed
    RemoveAnimDict(animDict)
end

-- Modified StartASLMode for signing to others
local function StartASLMode()
    if isASLActive then 
        StopASLMode()
        return 
    end
    
    -- Find nearest player (required for normal mode)
    local nearest, distance = GetNearestPlayer()
    if not nearest then
        TriggerEvent('chat:addMessage', {
            color = {255, 100, 100},
            args = {"ASL", "No players nearby to sign to!"}
        })
        return
    end
    targetPlayer = nearest
    
    -- Create camera
    CreateASLCamera()
    isCameraLocked = true
    isASLActive = true
    isThirdPersonMode = false
    
    -- Show persistent input
    SetNuiFocus(true, true)
    SendNUIMessage({
        type = 'showASLInput',
        persistent = true
    })
end

-- New function for self-signing mode
local function StartASLSelfMode()
    if isASLActive then 
        StopASLMode()
        return 
    end
    
    -- No target needed for self mode
    targetPlayer = nil
    
    -- Create camera for self viewing
    CreateASLCamera()
    isCameraLocked = true
    isASLActive = true
    isThirdPersonMode = false
    
    -- Show persistent input
    SetNuiFocus(true, true)
    SendNUIMessage({
        type = 'showASLInput',
        persistent = true
    })
end

-- NEW: Third-person ASL mode without camera lock
local function StartASLThirdPersonMode()
    if isASLActive then 
        StopASLMode()
        return 
    end
    
    -- No target or camera needed for third-person mode
    targetPlayer = nil
    isASLActive = true
    isCameraLocked = false
    isThirdPersonMode = true
    
    -- Don't lock controls initially - just show the UI
    SetNuiFocus(false, false)
    SendNUIMessage({
        type = 'showASLInput',
        persistent = true,
        thirdPerson = true
    })
    
    -- Notify user they're in third-person mode
    TriggerEvent('chat:addMessage', {
        color = {100, 200, 100},
        args = {"ASL", "Third-person mode - Press ENTER to type, ESC to exit. You can move freely!"}
    })
end

-- Function to toggle text input in third-person mode
local function ToggleThirdPersonInput(enable)
    if isThirdPersonMode and isASLActive then
        if enable then
            isTypingActive = true
            SetNuiFocus(true, false)  -- Enable keyboard input, no cursor
            SendNUIMessage({
                type = 'focusInput'
            })
        else
            isTypingActive = false
            SetNuiFocus(false, false)  -- Disable NUI focus completely
            SendNUIMessage({
                type = 'blurInput'
            })
        end
    end
end

-- Process text without closing
local function ProcessASLText(text)
    if not text or text == "" then return end
    
    -- Parse text into animations
    currentAnimations = ParseTextForAnimations(text)
    
    if #currentAnimations == 0 then
        SendNUIMessage({
            type = 'updateStatus',
            status = 'No valid animations found'
        })
        return
    end
    
    -- Start playing animations
    CreateThread(function()
        for _, animData in ipairs(currentAnimations) do
            if not isASLActive then break end
            
            -- Send signing status to NUI (skip for pauses)
            if animData.type ~= "pause" and animData.text then
                SendNUIMessage({
                    type = 'updateStatus',
                    status = 'Signing: ' .. string.upper(animData.text)
                })
            end
            
            PlayASLAnimation(animData)
        end
        
        -- Clear status when done
        if isASLActive then
            SendNUIMessage({
                type = 'updateStatus',
                status = ''
            })
        end
    end)
end

-- Modified NUI Callbacks
RegisterNUICallback('submitASLText', function(data, cb)
    -- Process text but don't close
    ProcessASLText(data.text)
    
    -- In third-person mode, release focus after submitting
    if isThirdPersonMode then
        ToggleThirdPersonInput(false)
    end
    
    cb('ok')
end)

RegisterNUICallback('closeASL', function(data, cb)
    StopASLMode()
    cb('ok')
end)

RegisterNUICallback('releaseThirdPersonFocus', function(data, cb)
    if isThirdPersonMode then
        ToggleThirdPersonInput(false)
    end
    cb('ok')
end)

-- Modified StopASLMode
function StopASLMode()
    if not isASLActive then return end
    
    isASLActive = false
    isCameraLocked = false
    isThirdPersonMode = false
    isTypingActive = false  -- Reset typing state
    targetPlayer = nil
    currentAnimations = {}
    
    -- Clear animations
    local playerPed = PlayerPedId()
    ClearPedTasks(playerPed)
    
    -- Restore camera (only if it exists)
    if aslCamera then
        RestoreCamera()
    end
    
    -- Hide NUI
    SetNuiFocus(false, false)
    SendNUIMessage({
        type = 'hideASLInput'
    })
    
    -- Notify
    TriggerEvent('chat:addMessage', {
        color = {100, 200, 100},
        args = {"ASL", "Stopped signing"}
    })
end

-- Register main command
RegisterCommand('asl', function(source, args, rawCommand)
    if #args > 0 then
        -- Start ASL mode if not active
        if not isASLActive then
            StartASLMode()
            Wait(500) -- Wait for camera to position
        end
        
        -- Process the text directly
        local inputText = table.concat(args, " ")
        ProcessASLText(inputText)
    else
        -- Toggle ASL mode
        StartASLMode()
    end
end, false)

-- Self signing command
RegisterCommand('aslself', function(source, args, rawCommand)
    if #args > 0 then
        -- Start self mode if not active
        if not isASLActive then
            StartASLSelfMode()
            Wait(500) -- Wait for camera to position
        end
        
        -- Process the text directly
        local inputText = table.concat(args, " ")
        ProcessASLText(inputText)
    else
        -- Toggle self mode
        StartASLSelfMode()
    end
end, false)

-- NEW: Third-person ASL command
RegisterCommand('asl2', function(source, args, rawCommand)
    if #args > 0 then
        -- Start third-person mode if not active
        if not isASLActive then
            StartASLThirdPersonMode()
        end
        
        -- Process the text directly
        local inputText = table.concat(args, " ")
        ProcessASLText(inputText)
    else
        -- Toggle third-person mode
        StartASLThirdPersonMode()
    end
end, false)

-- Handle controls while signing (modified for third-person mode)
CreateThread(function()
    while true do
        Wait(0)
        if isASLActive then
            -- Only hide HUD and disable movement if NOT in third-person mode
            if not isThirdPersonMode then
                -- Hide HUD elements
                HideHudAndRadarThisFrame()
                
                -- Disable movement if configured
                if not Config.Settings.allowMovement then
                    DisableControlAction(0, 30, true)  -- Move left/right
                    DisableControlAction(0, 31, true)  -- Move forward/back
                    DisableControlAction(0, 32, true)  -- Move forward
                    DisableControlAction(0, 33, true)  -- Move back
                    DisableControlAction(0, 34, true)  -- Move left
                    DisableControlAction(0, 35, true)  -- Move right
                end
            end
            -- In third-person mode, allow all movement and keep HUD visible
        end
    end
end)

-- Handle Enter key for third-person text input
CreateThread(function()
    while true do
        Wait(0)
        if isASLActive and isThirdPersonMode and not isTypingActive then
            -- Check multiple possible Enter key controls
            if IsControlJustPressed(0, 18) or  -- Enter (phone)
               IsControlJustPressed(0, 201) or  -- Frontend accept
               IsControlJustPressed(0, 176) then -- Enter (alternative)
                ToggleThirdPersonInput(true)
            end
        end
    end
end)

-- Alternative: Register a key mapping for Enter in third-person mode
RegisterCommand('asl_activate_input', function()
    if isASLActive and isThirdPersonMode and not isTypingActive then
        ToggleThirdPersonInput(true)
    end
end, false)
RegisterKeyMapping('asl_activate_input', 'Activate ASL Input (Third Person)', 'keyboard', 'RETURN')

-- Register ESC keybind for closing ASL
RegisterKeyMapping('aslclose', 'Close ASL Mode', 'keyboard', 'ESCAPE')
RegisterCommand('aslclose', function()
    if isASLActive then
        StopASLMode()
    end
end, false)

-- Cleanup on resource stop
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        StopASLMode()
    end
end)

-- Updated help command
RegisterCommand('aslhelp', function()
    TriggerEvent('chat:addMessage', {
        color = {100, 200, 255},
        multiline = true,
        args = {"ASL Help", [[
Commands:
- /asl - Sign to nearest player (camera focus)
- /asl [text] - Sign text directly to nearest player
- /aslself - Sign to yourself (practice mode with camera)
- /aslself [text] - Sign text directly in self mode
- /asl2 - Third-person signing (move while signing!)
- /asl2 [text] - Sign text in third-person mode
- /asldebug - Toggle debug mode
- Press ESC or type 'exit' to close ASL mode

Third-Person Mode Controls (/asl2):
- Press ENTER to activate text input
- Press ENTER again to sign the text
- Press ESC to exit text input or close ASL
- You can move freely with WASD when not typing

Modes:
- Camera modes (/asl, /aslself): Focuses camera, no movement
- Third-person mode (/asl2): Keep normal view, move freely

The system will:
- Play full phrase animations when available
- Otherwise spell words letter by letter
- In third-person mode, you can walk/run while signing!]]
        }
    })
end, false)

-- Debug mode toggle
RegisterCommand('asldebug', function()
    Config.Settings.debugMode = not Config.Settings.debugMode
    TriggerEvent('chat:addMessage', {
        color = {200, 200, 100},
        args = {"ASL", "Debug mode " .. (Config.Settings.debugMode and "enabled" or "disabled")}
    })
end, false)