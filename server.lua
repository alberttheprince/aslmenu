-- Optional server-side script for animation syncing
RegisterNetEvent('asl:syncAnimation')
AddEventHandler('asl:syncAnimation', function(targetPlayerId, animationData)
    local source = source
    
    -- Verify players are near each other
    local sourceCoords = GetEntityCoords(GetPlayerPed(source)) 
    local targetCoords = GetEntityCoords(GetPlayerPed(targetPlayerId)) 
    local distance = #(sourceCoords - targetCoords)
    
    if distance <= 15.0 then
        -- Notify target player that someone is signing to them
        TriggerClientEvent('asl:receiveAnimation', targetPlayerId, source, animationData)
    end
end) 

-- Log ASL usage (optional)
RegisterNetEvent('asl:logUsage')
AddEventHandler('asl:logUsage', function(message)
    local source = source
    local playerName = GetPlayerName(source)
    print(string.format("[ASL] %s (%d) signed: %s", playerName, source, message))
end)
