-- need to learn timedaction 

--***********************************************************
--**                    ROBERT JOHNSON                     **
--***********************************************************

require "TimedActions/ISBaseTimedAction"

ISFollowToTimedAction = ISBaseTimedAction:derive("ISFollowToTimedAction");


function ISFollowToTimedAction:isValid()
	if self.character:getVehicle() then return false end
	if self.clickedplayer:getVehicle() then return false end
    return getGameSpeed() <= 2;
end

function ISFollowToTimedAction:update()
    if (self.character:pressedMovement(false) or self.character:pressedCancelAction() or self.character:pressedAim()) then
        self:forceStop()
        return
    end

    
    local distanceSq = self.character:getDistanceSq(self.clickedplayer)
    -- print("distanza dal clickedplayer: " .. distanceSq)
    if distanceSq < 4 then
        if self.isFollow then
            self.character:getPathFindBehavior2():cancel()
            self.character:setPath2(nil)
            self.character:setForceSprint(false)
            self.character:setForceRun(false)
            self.isFollow = false
        end
        return
    elseif distanceSq > 900 then
        self:forceStop()
        return
    elseif distanceSq > 225 then
        if not self.character:isForceSprint() then
            self.character:setForceSprint(true)
            self.character:setForceRun(false)
        end
    elseif distanceSq > 25 then
        if not self.character:isForceRun() then
            self.character:setForceSprint(false)
            self.character:setForceRun(true)
        end
    else
        if self.character:isForceRun() or self.character:isForceSprint() then
            self.character:setForceSprint(false)
            self.character:setForceRun(false)
        end
    end

    -- need to recalcolate path if the clickedplayer moved
    -- local square = self.clickedplayer:getSquare()

    -- if square ~= self.square then
    --     self:updatePathToBehindPlayer()
    -- end

    self.tick = self.tick + 1
    if not self.isFollow or self.tick > 20 then
        self:start()
        self.tick = 0
    else
        self.result = self.character:getPathFindBehavior2():update();

        if self.result == BehaviorResult.Failed then
            self:forceStop();
            return;
        end

        if self.result == BehaviorResult.Succeeded then
            self.isFollow = false
        end
    end
end

-- function ISFollowToTimedAction:updatePathToBehindPlayer()
--     -- Get the clickedplayer's position and direction
--     local cpX = self.clickedplayer:getX()
--     local cpY = self.clickedplayer:getY()
--     local cpZ = self.clickedplayer:getZ()
--     local cpDir = self.clickedplayer:getDir()

--     -- Get the opposite direction
--     local oppositeDir = IsoDirections.reverse(cpDir)

--     -- Get the vector for that direction using ToVector()
--     local dirVector = oppositeDir:ToVector()

--     -- Desired distance behind the clickedplayer
--     local desiredDistanceBehind = 1 -- Adjust this value as needed

--     -- Calculate target position
--     local targetX = cpX + dirVector:getX() --* desiredDistanceBehind
--     local targetY = cpY + dirVector:getY() --* desiredDistanceBehind
--     local targetZ = cpZ

--     -- Path to that location
--     self.character:pathToLocation(targetX, targetY, targetZ)

--     -- Update the stored square
--     self.square = self.clickedplayer:getSquare()
-- end


function ISFollowToTimedAction:start()
    print ("ISFollowToTimedAction:start");
    -- self:updatePathToBehindPlayer()
    self.character:getPathFindBehavior2():pathToCharacter(self.clickedplayer)
    self.isFollow = true
    --self.action:Pathfind(getPlayer(), self.location:getX(), self.location:getY(), self.location:getZ());
end

function ISFollowToTimedAction:stop()
    --print ("ISFollowToTimedAction: Pathfind cancelled.")
    ISBaseTimedAction.stop(self);
	self.character:getPathFindBehavior2():cancel()
    self.character:setPath2(nil)
    self.character:setForceSprint(false)
    self.character:setForceRun(false)
end

function ISFollowToTimedAction:perform()
    --print ("ISFollowToTimedAction: Pathfind complete.")
	self.character:getPathFindBehavior2():cancel()
    self.character:setPath2(nil);
    self.character:setForceSprint(false)
    self.character:setForceRun(false)
    ISBaseTimedAction.perform(self);

    -- if self.onCompleteFunc then
    --     local args = self.onCompleteArgs
    --     self.onCompleteFunc(args[1], args[2], args[3], args[4])
    -- end
end

-- function ISFollowToTimedAction:setOnComplete(func, arg1, arg2, arg3, arg4)
--     self.onCompleteFunc = func
--     self.onCompleteArgs = { arg1, arg2, arg3, arg4 }
-- end

--
-- Can pass in an additional test to allow the walk to action to complete early.
--
-- Example if you have walking to a door, you can end it early if you get to the door, so you don't walk through it
-- meaning you'll always barricade the side of the door you reach first.
-- Example a doorN is on the tile below it, not above it. Walking down the character would walk through the door
-- Then barricade it from below.
--
function ISFollowToTimedAction:new (character, clickedplayer, additionalTest, additionalContext)
    local o = {}
    setmetatable(o, self)
    self.__index = self
    o.character = character;
    o.clickedplayer = clickedplayer
    o.square = clickedplayer:getSquare()
    o.tick = 0;
    o.stopOnWalk = false;
    o.stopOnRun = false;
    o.maxTime = -1;
    o.isFollow = false
    return o
end