-- need to learn timedaction 

--***********************************************************
--**                    ROBERT JOHNSON                     **
--***********************************************************

require "TimedActions/ISBaseTimedAction"

ISFollowToTimedAction = ISBaseTimedAction:derive("ISFollowToTimedAction");

function ISFollowToTimedAction:isValid()
	if self.character:getVehicle() then return false end
    return getGameSpeed() <= 2;
end

function ISFollowToTimedAction:update()
    -- print(self.locationX .. " x " .. self.locationY)
    if instanceof(self.character, "IsoPlayer") and
            (self.character:pressedMovement(false) or self.character:pressedCancelAction()) then
        self:forceStop()
        return
    end

    self.result = self.character:getPathFindBehavior2():update(); --??

    if self.result == BehaviorResult.Failed then -- this stop the action if the character keeps trying to touch the clickedplayer, need to remove it? or we just need to change the behaviour of the path to let the charecter going to -1x -1y of the clickedplayer so that the character doesn't keep trying to touch the clickedplayer?
        print ("ISFollowToTimedAction: pathfind failed");
        self:forceStop();
        return;
    end

    if self.result == BehaviorResult.Working then
        --qui possiamo aggiornare il pathindex? con add node "pathNextIsSet" maybe?
        print ("ISFollowToTimedAction: pathfind working");
        return;
    end

    -- if self.character:getDistanceSq(self.clickedplayer) == 1 then
    --     self:forceComplete();
    --     return
    -- end

    -- need to recalcolate path if the clickedplayer moved
    local x2,y2 = self.clickedplayer:getX(), self.clickedplayer:getY()
    if x2 ~= self.locationX or y2 ~= self.locationY then
        --print ("ISFollowToTimedAction: recalculating path")
        self.locationX = x2
        self.locationY = y2
        self.character:pathToCharacter(self.clickedplayer);
        
    end

    if self.additionalTest ~= nil then
       if self.additionalTest(self.additionalContext) then
			--print ("ISFollowToTimedAction: hit complete");
			self:forceComplete();
            return
       end
    end
    -- if self.result == BehaviorResult.Succeeded then
	-- 	--print ("ISFollowToTimedAction: hit complete");
    --     self:forceComplete();
    -- end

end

function ISFollowToTimedAction:start()
    --print ("ISFollowToTimedAction: Calling pathfind method.");
    self.character:pathToCharacter(self.clickedplayer);
    --self.action:Pathfind(getPlayer(), self.location:getX(), self.location:getY(), self.location:getZ());
end

function ISFollowToTimedAction:stop()
    --print ("ISFollowToTimedAction: Pathfind cancelled.")
    ISBaseTimedAction.stop(self);
	self.character:getPathFindBehavior2():cancel()
    self.character:setPath2(nil);
end

function ISFollowToTimedAction:perform()
    --print ("ISFollowToTimedAction: Pathfind complete.")
	self.character:getPathFindBehavior2():cancel()
    self.character:setPath2(nil);

    ISBaseTimedAction.perform(self);

    if self.onCompleteFunc then
        local args = self.onCompleteArgs
        self.onCompleteFunc(args[1], args[2], args[3], args[4])
    end
end

function ISFollowToTimedAction:setOnComplete(func, arg1, arg2, arg3, arg4)
    self.onCompleteFunc = func
    self.onCompleteArgs = { arg1, arg2, arg3, arg4 }
end

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

    o.stopOnWalk = false;
    o.stopOnRun = false;
    o.maxTime = -1;
    o.clickedplayer = clickedplayer
    o.locationX = clickedplayer:getX()
    o.locationY = clickedplayer:getY()
    o.pathIndex = 0;
    o.additionalTest = additionalTest;
    o.additionalContext = additionalContext;
    return o
end
