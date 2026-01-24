require "TimedActions/ISFollowToTimedAction"

local ISFollowPlayer = {}

---@param worldobjects IsoObject[]
---@param playerObj IsoPlayer
---@param clickedPlayer IsoPlayer
function ISFollowPlayer.FollowAction(worldobjects, playerObj, clickedPlayer)
    ISTimedActionQueue.add(ISFollowToTimedAction:new(playerObj, clickedPlayer)) -- still need to figure out
    -- ISFollowPlayer.StartFollowing(playerObj, clickedPlayer)

end

---@param player integer Player index (0-3 for splitscreen)
---@param context ISContextMenu The context menu to populate
---@param worldobjects IsoObject[] World objects clicked by the player
---@param test boolean If true, only checking if option should appear
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
                        local movingObjects = sq:getMovingObjects()
                        for i = 0, movingObjects:size() - 1 do
                            local clickedPlayer = movingObjects:get(i)
                            -- Check instanceof FIRST before calling any IsoPlayer-specific methods
                            if instanceof(clickedPlayer, "IsoPlayer") then
                                ---@cast clickedPlayer IsoPlayer
                                local username = clickedPlayer:getUsername()
                                if ISFollowPlayer.CanFollowPlayer(playerObj, clickedPlayer) and not followers[username] then
                                    followers[username] = clickedPlayer
                                    followerCount = followerCount + 1
                                end
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
    local isName = SandboxVars.ISFollowPlayer.realName
    for k,v in pairs(followers) do
        local characterName = v:getDescriptor():getForename() .. " " .. v:getDescriptor():getSurname();
        local followOpt = subMenu:addOption((isName and characterName or v:getUsername()), worldobjects, ISFollowPlayer.FollowAction, playerObj, v)
        followOpt.iconTexture = getTexture("media/ui/follow.png")
    end
end

---@param character IsoPlayer The player who wants to follow
---@param clickedPlayer IsoPlayer The player to be followed
---@return boolean canFollow Whether following is allowed
function ISFollowPlayer.CanFollowPlayer(character, clickedPlayer)
    -- instanceof check is now done in caller (onFillContext)
    if clickedPlayer:getUsername() == character:getUsername() then
        return false
    end
    if isAdmin() then
        return true
    end
    if SandboxVars.ISFollowPlayer.disabled then
        return false
    end

    if not clickedPlayer:getSafety():isEnabled() then
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