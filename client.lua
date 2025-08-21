local isASLActive = false
local aslCamera = nil
local currentAnimations = {}
local targetPlayer = nil

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
    -- Get player head position for camera
    local playerPed = PlayerPedId()
    local headBone = GetPedBoneIndex(playerPed, 31086) -- SKEL_Head
    local headCoords = GetPedBoneCoords(playerPed, headBone, 0.0, 0.0, 0.0)
    
    -- Create camera
    aslCamera = CreateCamWithParams(
        "DEFAULT_SCRIPTED_CAMERA",
        headCoords.x, headCoords.y, headCoords.z + 0.2,
        0.0, 0.0, 0.0,
        Config.Settings.cameraFOV,
        true, 2
    )
    
    -- Focus on the target player if found
    if targetPlayer then
        PointCamAtEntity(aslCamera, targetPlayer, 0.0, 0.0, 0.5, true)
    end
    
    -- Enable first-person view
    SetFollowPedCamViewMode(4)
    
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

local function GetTextInput(title, maxLength)
    AddTextEntry('ASL_INPUT', title)
    DisplayOnscreenKeyboard(1, "ASL_INPUT", "", "", "", "", "", maxLength or 100)
    
    while UpdateOnscreenKeyboard() == 0 do
        DisableAllControlActions(0)
        Wait(0)
    end
    
    if UpdateOnscreenKeyboard() == 1 then
        local result = GetOnscreenKeyboardResult()
        Wait(100)
        return result
    else
        return nil
    end
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
        TriggerEvent('chat:addMessage', {
            color = {255, 100, 100},
            args = {"ASL", "Animation not found: " .. animDict}
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
    
    -- Show subtitle if enabled
    if Config.Settings.showSubtitles then
        local endTime = GetGameTimer() + animData.duration
        CreateThread(function()
            while GetGameTimer() < endTime and isASLActive do
                Wait(0)
                DrawSubtitle("Signing: " .. string.upper(animData.text))
            end
        end)
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

function DrawSubtitle(text)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextScale(0.5, 0.5)
    SetTextColour(255, 255, 255, 255)
    SetTextDropShadow(0, 0, 0, 0, 255)
    SetTextEdge(2, 0, 0, 0, 255)
    SetTextDropShadow()
    SetTextOutline()
    SetTextCentre(1)
    SetTextEntry("STRING")
    AddTextComponentString(text)
    DrawText(0.5, 0.85)
end

function DrawInstructions()
    local text = "Press ~r~X~w~ to stop signing"
    SetTextFont(0)
    SetTextProportional(1)
    SetTextScale(0.3, 0.3)
    SetTextColour(255, 255, 255, 200)
    SetTextEntry("STRING")
    AddTextComponentString(text)
    DrawText(0.5, 0.92)
end

local function StartASLMode()
    if isASLActive then return end
    
    -- Find nearest player (unless in test mode)
    if not Config.Settings.testMode then
        local nearest, distance = GetNearestPlayer()
        if not nearest then
            TriggerEvent('chat:addMessage', {
                color = {255, 100, 100},
                args = {"ASL", "No players nearby to sign to!"}
            })
            return
        end
        targetPlayer = nearest
    else
        -- Test mode - no target required
        targetPlayer = nil
        if Config.Settings.debugMode then
            print("^3[ASL Debug] Test mode enabled - no target player required^0")
        end
    end
    
    isASLActive = true
    
    -- Get text input
    local inputText = GetTextInput("Enter text to sign in ASL:", 100)
    if not inputText or inputText == "" then
        isASLActive = false
        targetPlayer = nil
        return
    end
    
    -- Create camera and focus on target
    CreateASLCamera()
    
    -- Parse text into animations
    currentAnimations = ParseTextForAnimations(inputText)
    
    if #currentAnimations == 0 then
        TriggerEvent('chat:addMessage', {
            color = {255, 100, 100},
            args = {"ASL", "No valid animations found for: " .. inputText}
        })
        StopASLMode()
        return
    end
    
    -- Start playing animations
    CreateThread(function()
        for _, animData in ipairs(currentAnimations) do
            if not isASLActive then break end
            PlayASLAnimation(animData)
        end
        
        -- Finished all animations
        if isASLActive then
            Wait(1000) -- Brief pause at end
            StopASLMode()
        end
    end)
    
    -- Handle controls while signing
    CreateThread(function()
        while isASLActive do
            Wait(0)
            
            -- Show instructions
            if Config.Settings.showInstructions then
                DrawInstructions()
            end
            
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
            
            -- Check for stop key
            if IsDisabledControlJustPressed(0, Config.Settings.stopKey) then
                StopASLMode()
            end
        end
    end)
end

function StopASLMode()
    if not isASLActive then return end
    
    isASLActive = false
    targetPlayer = nil
    currentAnimations = {}
    
    -- Clear animations
    local playerPed = PlayerPedId()
    ClearPedTasks(playerPed)
    
    -- Restore camera
    RestoreCamera()
    
    -- Notify
    TriggerEvent('chat:addMessage', {
        color = {100, 200, 100},
        args = {"ASL", "Stopped signing"}
    })
end

-- Register main command
RegisterCommand('asl', function(source, args, rawCommand)
    if #args > 0 then
        -- Direct text input via command
        local inputText = table.concat(args, " ")
        
        -- Find nearest player (unless in test mode)
        if not Config.Settings.testMode then
            local nearest, distance = GetNearestPlayer()
            if not nearest then
                TriggerEvent('chat:addMessage', {
                    color = {255, 100, 100},
                    args = {"ASL", "No players nearby to sign to!"}
                })
                return
            end
            targetPlayer = nearest
        else
            targetPlayer = nil
        end
        
        isASLActive = true
        
        -- Create camera and start signing
        CreateASLCamera()
        currentAnimations = ParseTextForAnimations(inputText)
        
        -- Start animation playback
        CreateThread(function()
            for _, animData in ipairs(currentAnimations) do
                if not isASLActive then break end
                PlayASLAnimation(animData)
            end
            
            if isASLActive then
                Wait(1000)
                StopASLMode()
            end
        end)
        
        -- Handle controls
        CreateThread(function()
            while isASLActive do
                Wait(0)
                if Config.Settings.showInstructions then
                    DrawInstructions()
                end
                HideHudAndRadarThisFrame()
                
                if not Config.Settings.allowMovement then
                    DisableControlAction(0, 30, true)
                    DisableControlAction(0, 31, true)
                    DisableControlAction(0, 32, true)
                    DisableControlAction(0, 33, true)
                    DisableControlAction(0, 34, true)
                    DisableControlAction(0, 35, true)
                end
                
                if IsDisabledControlJustPressed(0, Config.Settings.stopKey) then
                    StopASLMode()
                end
            end
        end)
    else
        -- No arguments, show text input prompt
        StartASLMode()
    end
end, false)

-- Cleanup on resource stop
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        StopASLMode()
    end
end)

-- Help command
RegisterCommand('aslhelp', function()
    TriggerEvent('chat:addMessage', {
        color = {100, 200, 255},
        multiline = true,
        args = {"ASL Help", [[
Commands:
- /asl - Opens text prompt for signing
- /asl [text] - Sign text directly
- /asldebug - Toggle debug mode
- /asltest - Toggle test mode (no nearby player required)
- Press X while signing to stop

The system will:
- Find the nearest player and focus on them
- Play full phrase animations when available
- Otherwise spell words letter by letter
- Show subtitles of what you're signing]]
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

-- Test mode toggle
RegisterCommand('asltest', function()
    Config.Settings.testMode = not Config.Settings.testMode
    TriggerEvent('chat:addMessage', {
        color = {200, 200, 100},
        args = {"ASL", "Test mode " .. (Config.Settings.testMode and "enabled (no target required)" or "disabled")}
    })
end, false)