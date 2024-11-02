local ISFollowPlayer = {}

function ISFollowPlayer.FollowAction(worldobjects, playerObj, clickedPlayer)
    ISTimedActionQueue.add(ISFollowToTimedAction:new(playerObj, clickedPlayer)) -- still need to figure out
    -- ISFollowPlayer.StartFollowing(playerObj, clickedPlayer)

end

function ISFollowPlayer.onFillContext(player, context, worldobjects, test)

    if test then return ISWorldObjectContextMenu.setTest() end
    local playerObj = getSpecificPlayer(player)
    local followerCount = 0
    local followers = {}

    for _, v in ipairs(worldobjects) do
        if v:getSquare() then
            -- help detecting a player by checking nearby squares
            for x = v:getSquare():getX() - 1, v:getSquare():getX() + 1 do
                for y = v:getSquare():getY() - 1, v:getSquare():getY() + 1 do
                    local sq = getCell():getGridSquare(x, y, v:getSquare():getZ())
                    if sq then
                        for i = 0, sq:getMovingObjects():size() - 1 do
                            local clickedPlayer = sq:getMovingObjects():get(i)

                            if ISFollowPlayer.CanFollowPlayer(playerObj, clickedPlayer) and not followers[clickedPlayer:getUsername()] then
                                followers[clickedPlayer:getUsername()] = clickedPlayer
                                followerCount = followerCount + 1
                            end
                        end
                    end
                end
            end
        end
    end

    if followerCount == 0 then
        return
    end
    
    local newOption = context:addOptionOnTop(getText("ContextMenu_Follow"), worldobjects, nil);
    local subMenu = ISContextMenu:getNew(context)
    context:addSubMenu(newOption, subMenu)
    for k,v in pairs(followers) do
        subMenu:addOption(v:getDisplayName(), worldobjects, ISFollowPlayer.FollowAction, playerObj, v)
    end
end

 function ISFollowPlayer.CanFollowPlayer(character, clickedPlayer)
    if not instanceof(clickedPlayer, "IsoPlayer") or clickedPlayer:getUsername() == character:getUsername() then
        return false
    end
    if isAdmin() then
        return true
    end
    if SandboxVars.ISFollowPlayer.disabled then
        return false
    end

    if clickedPlayer:isAsleep() then
        return false
    end

    if  clickedPlayer:isInvisible() then
        return false
    end

    if clickedPlayer:isDriving() then
        return false
    end
    

    return true
end



Events.OnFillWorldObjectContextMenu.Add(ISFollowPlayer.onFillContext)