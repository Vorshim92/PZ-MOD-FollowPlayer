local ISVector2 = require('ISVector2')

ISFollowPlayer = {}
function ISFollowPlayer.ActivateFollow(player, clickedPlayer)
    -- maybe this just for admin when debug is enabled?
    -- local dbgOptions = getDebugOptions()
    -- if dbgOptions then
    --     for i=1,dbgOptions:getOptionCount() do
    --         local option = dbgOptions:getOptionByIndex(i-1)
    --         print(option:getName())
    --         if option:getName() == "Multiplayer.Debug.Follow.Player" then
    --             print("Value before: " .. tostring(option:getValue()))
    --             option:setValue(true)
    --             print("Value after: " .. tostring(option:getValue()))
    --             getDebugOptions():save()
                print("COMPLIMENTI VORSHIM")
    --             break
    --         end
    --     end
    -- end
    local vectorStop = ISVector2:new(0,0)

    local x,y = player:getX(), player:getY()
    print("player position x: " .. x .. " y: " .. y)
    local x2,y2 = clickedPlayer:getX(), clickedPlayer:getY()
    print("clickedPlayer position x: " .. x2 .. " y: " .. y2)
    -- Vector2 var3 = new Vector2(var2.x - var0.x, var0.y - var2.y); from updateMovementFromInput
    local var3 = ISVector2:new(x2 - x, y - y2)
    var3:rotate(-math.pi / 4) -- Rotate by -45 degrees
    var3:normalize()
    player:setPlayerMoveDir(var3.vector)


    -- if (!var2.isTeleporting() && !(var2.getDistanceSq(var0) > 10.0F)) {
    --     if (var2.getDistanceSq(var0) > 5.0F) {
    --        var0.setRunning(true);
    --        var0.setSprinting(true);
    --     } else if (var2.getDistanceSq(var0) > 2.5F) {
    --        var0.setRunning(true);
    --     } else if (var2.getDistanceSq(var0) < 1.25F) {
    --        var1.moveX = 0.0F;
    --        var1.moveY = 0.0F;
    --     }
    local distanceSq = clickedPlayer:getDistanceSq(player)
    print("distanceSq: " .. tostring(distanceSq))
    if distanceSq <= 100.0 then
        if distanceSq > 25.0 then -- 5^2 = 25
            player:setRunning(true)
            player:setSprinting(true)
        elseif distanceSq > 6.25 then -- 2.5^2 = 6.25
            player:setRunning(true)
        elseif distanceSq < 1.5625 then -- 1.25^2 = 1.5625
            player:setRunning(false)
            player:setSprinting(false)
            player:setPlayerMoveDir(vectorStop.vector)
        end
    else
        -- Handle the case when the target is too far
        player:setPlayerMoveDir(vectorStop.vector)
    end
    
end

function ISFollowPlayer.FollowAction(worldobjects, playerObj, clickedPlayer)
    -- ISTimedActionQueue.add(ISFollowPlayerTimedAction:new(playerObj, clickedPlayer)) -- still need to figure out
    ISFollowPlayer.StartFollowing(playerObj, clickedPlayer)

end

--alternative method with Events onTick
function ISFollowPlayer.StartFollowing(playerObj, clickedPlayer)
    local function followTick()
        if playerObj:isDead() or clickedPlayer:isDead() then
            Events.OnTick.Remove(followTick)
            return
        end

        local distanceSq = clickedPlayer:getDistanceSq(playerObj)
        if distanceSq < 1.5625 then -- Close enough
            playerObj:setPlayerMoveDir(ISVector2:new(0, 0).vector)
            Events.OnTick.Remove(followTick)
            return
        elseif distanceSq > 10000 then -- Too far away (e.g., 100 units)
            playerObj:setPlayerMoveDir(ISVector2:new(0, 0).vector)
            Events.OnTick.Remove(followTick)
            return
        end

        ISFollowPlayer.ActivateFollow(playerObj, clickedPlayer)
    end
    Events.OnTick.Add(followTick)
end
--Avoiding Multiple Follow Actions
-- Ensure that you don't add multiple OnTick events for the same player. You might need to keep track of whether a player is already following someone.




-- public static boolean updateMovementFromInput(IsoPlayer var0, IsoPlayer.MoveVars var1) -- MPDebugAI.class
function ISFollowPlayer.MovementFromInput(player, x, y)
    -- from IsoPlayer
    -- public void setPlayerMoveDir(Vector2 var1) {
    --     this.playerMoveDir.set(var1);
    --  }
  
end


function ISFollowPlayer.onFillContext(player, context, worldobjects, test)

    if test then return ISWorldObjectContextMenu.setTest() end
    local playerObj = getSpecificPlayer(player)
    local followerCount = 0
    local followers = {}
    for i, obj in ipairs(worldobjects) do
        if instanceof(obj, "IsoPlayer") then
            if not followers[obj:getUsername()] then
                followers[obj:getUsername()] = obj
                followerCount = followerCount + 1
            end
        end
    end
    -- for _, v in ipairs(worldobjects) do
    --     if v:getSquare() then
    --         -- help detecting a player by checking nearby squares
    --         for x = v:getSquare():getX() - 1, v:getSquare():getX() + 1 do
    --             for y = v:getSquare():getY() - 1, v:getSquare():getY() + 1 do
    --                 local sq = getCell():getGridSquare(x, y, v:getSquare():getZ())
    --                 if sq then
    --                     for i = 0, sq:getMovingObjects():size() - 1 do
    --                         local clickedPlayer = sq:getMovingObjects():get(i)

    --                         if ISFollowPlayer.CanFollowPlayer(playerObj, clickedPlayer) and not followers[clickedPlayer:getUsername()] then
    --                             followers[clickedPlayer:getUsername()] = clickedPlayer
    --                             followerCount = followerCount + 1
    --                         end
    --                     end
    --                 end
    --             end
    --         end
    --     end
    -- end

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
    -- if not isClient() or SandboxVars.PlayerTradeOptions.disabled then
    --     return false
    -- end

    -- You already thade with someone.
    -- if ISTradingUI.instance and ISTradingUI.instance:isVisible() then
    --     return false
    -- end

    if not instanceof(clickedPlayer, "IsoPlayer") or clickedPlayer == character then
        return false
    end

    if clickedPlayer:isAsleep() then
        return false
    end

    if  clickedPlayer:isInvisible() then
        return false
    end

    return true
end



Events.OnFillWorldObjectContextMenu.Add(ISFollowPlayer.onFillContext)


--per calcolare la distanza dal player:
-- if math.abs(playerObj:getX() - clickedPlayer:getX()) > 2 or math.abs(playerObj:getY() - clickedPlayer:getY()) > 2 then
-- end
-- oppure 
-- local distanceSq = playerObj:getDistanceSq(clickedPlayer)

-- per la creazione del tooltip
-- local tooltip = ISWorldObjectContextMenu.addToolTip();
-- 			option.notAvailable = true;
-- 			tooltip.description = getText("ContextMenu_GetCloser", clickedPlayer:getDisplayName());
-- 			option.toolTip = tooltip;


-- alternativa al for worldobjects che ho fatto io:

-- for _, v in ipairs(worldobjects) do
--     if v:getSquare() then
--         -- help detecting a player by checking nearby squares
--         for x = v:getSquare():getX() - 1, v:getSquare():getX() + 1 do
--             for y = v:getSquare():getY() - 1, v:getSquare():getY() + 1 do
--                 local sq = getCell():getGridSquare(x, y, v:getSquare():getZ())
--                 if sq then
--                     for i = 0, sq:getMovingObjects():size() - 1 do
--                         local clickedPlayer = sq:getMovingObjects():get(i)

--                         if TweakWorldObjectContextMenu.CanTradeWith(character, clickedPlayer) and not traders[clickedPlayer:getUsername()] then
--                             traders[clickedPlayer:getUsername()] = clickedPlayer

--                             local optionTrade = tradeSubMenu:addOption(getText('ContextMenu_Stranger'), worldobjects, ISWorldObjectContextMenu.onTrade, character, clickedPlayer)
--                             if (math.abs(character:getX() - clickedPlayer:getX()) > 2 or math.abs(character:getY() - clickedPlayer:getY()) > 2) then
--                                 local tooltip = ISWorldObjectContextMenu.addToolTip()
--                                 optionTrade.notAvailable = true
--                                 tooltip.description = getText("ContextMenu_GetCloserToTrade", getText('ContextMenu_Stranger'))
--                                 optionTrade.toolTip = tooltip
--                             end
--                         end

--                         if TweakWorldObjectContextMenu.CanHealPlayer(character, clickedPlayer) and not patients[clickedPlayer:getUsername()] then
--                             patients[clickedPlayer:getUsername()] = clickedPlayer

--                             local optionMedicalCheck = medicalCheckSubMenu:addOption(getText('ContextMenu_Stranger'), worldobjects, ISWorldObjectContextMenu.onMedicalCheck, character, clickedPlayer)
--                             if (math.abs(character:getX() - clickedPlayer:getX()) > 2 or math.abs(character:getY() - clickedPlayer:getY()) > 2) then
--                                 local tooltip = ISWorldObjectContextMenu.addToolTip()
--                                 optionMedicalCheck.notAvailable = true
--                                 tooltip.description = getText("ContextMenu_GetCloser", getText('ContextMenu_Stranger'))
--                                 optionMedicalCheck.toolTip = tooltip
--                             end
--                         end
--                     end
--                 end
--             end
--         end
--     end
-- end





-- option:setValue(selected)
--   getDebugOptions():save()


-- for debugconsole in game
-- vorshim = function ()
--     local options = getDebugOptions()
--     if options then
--         for i=1,options:getOptionCount() do
--             local option = options:getOptionByIndex(i-1)
--             print(option:getName())
--             if option:getName() == "Multiplayer.Debug.Follow.Player" then
--                 print("Value before: " .. option:getValue())
--                 option:setValue(true)
--                 print("Value after: " .. option:getValue())
--                 getDebugOptions():save()
--                 print("COMPLIMENTI VORSHIM")
--                 break
--             end
--         end
--     end
-- end