require "TimedActions/ISBaseTimedAction"

---@class ISFollowToTimedAction : ISBaseTimedAction
---@field character IsoPlayer The character performing the follow action
---@field clickedplayer IsoPlayer The player being followed
---@field square IsoGridSquare The current square of the clicked player
---@field tick number Counter for path recalculation timing
---@field stopOnWalk boolean Whether to stop when walking
---@field stopOnRun boolean Whether to stop when running
---@field maxTime number Maximum action time (-1 for unlimited)
---@field isFollow boolean Whether currently pathfinding to target
---@field result PathFindBehavior2.BehaviorResult|nil The result of the pathfinding behavior
ISFollowToTimedAction = ISBaseTimedAction:derive("ISFollowToTimedAction")

--- Check if the target player is valid (exists, alive, not disconnected)
---@return boolean
function ISFollowToTimedAction:isTargetValid()
    if not self.clickedplayer then return false end
    if not instanceof(self.clickedplayer, "IsoPlayer") then return false end
    -- Check if player object is still valid (not disconnected)
    if self.clickedplayer:getObjectIndex() == -1 then return false end
    if self.clickedplayer:isDead() then return false end
    return true
end

--- Validate before the action starts
---@return boolean
function ISFollowToTimedAction:isValidStart()
    if not self:isTargetValid() then return false end
    if self.clickedplayer:isAsleep() then return false end
    if self.character:getVehicle() then return false end
    if self.clickedplayer:getVehicle() then return false end
    return true
end

---@return boolean
function ISFollowToTimedAction:isValid()
    if not self:isTargetValid() then return false end
    if self.character:getVehicle() then return false end
    if self.clickedplayer:getVehicle() then return false end
    return getGameSpeed() <= 2
end

--- Cancel pathfinding and reset movement flags
function ISFollowToTimedAction:cancelPathfinding()
    self.character:getPathFindBehavior2():cancel()
    self.character:setPath2(nil)
    self.character:setForceSprint(false)
    self.character:setForceRun(false)
    self.isFollow = false
end

--- Set movement speed based on distance to target
---@param distanceSq number Squared distance to target
function ISFollowToTimedAction:setMovementSpeed(distanceSq)
    if distanceSq > 225 then
        -- Sprint when far (>15 tiles)
        if not self.character:isForceSprint() then
            self.character:setForceSprint(true)
            self.character:setForceRun(false)
        end
    elseif distanceSq > 25 then
        -- Run when medium distance (>5 tiles)
        if not self.character:isForceRun() then
            self.character:setForceSprint(false)
            self.character:setForceRun(true)
        end
    else
        -- Walk when close
        if self.character:isForceRun() or self.character:isForceSprint() then
            self.character:setForceSprint(false)
            self.character:setForceRun(false)
        end
    end
end

--- Recalculate path to the target player
function ISFollowToTimedAction:recalculatePath()
    self.character:getPathFindBehavior2():pathToCharacter(self.clickedplayer)
    self.isFollow = true
end

function ISFollowToTimedAction:update()
    -- Check for player input to cancel
    if self.character:pressedMovement(false) or self.character:pressedCancelAction() or self.character:pressedAim() then
        self:forceStop()
        return
    end

    -- Validate target is still valid
    if not self:isTargetValid() then
        self:forceStop()
        return
    end

    local distanceSq = self.character:getDistanceSq(self.clickedplayer)

    -- Stop following if close enough
    if distanceSq < 4 then
        if self.isFollow then
            self:cancelPathfinding()
        end
        return
    end

    -- Stop if too far (target teleported or disconnected)
    if distanceSq > 900 then
        self:forceStop()
        return
    end

    -- Adjust movement speed based on distance
    self:setMovementSpeed(distanceSq)

    -- Recalculate path periodically or if not following
    self.tick = self.tick + 1
    if not self.isFollow or self.tick > 20 then
        self:recalculatePath()
        self.tick = 0
    else
        self.result = self.character:getPathFindBehavior2():update()

        if self.result == BehaviorResult.Failed then
            self:forceStop()
            return
        end

        if self.result == BehaviorResult.Succeeded then
            self.isFollow = false
        end
    end
end

function ISFollowToTimedAction:start()
    self:recalculatePath()
end

function ISFollowToTimedAction:stop()
    self:cancelPathfinding()
    ISBaseTimedAction.stop(self)
end

function ISFollowToTimedAction:perform()
    self:cancelPathfinding()
    ISBaseTimedAction.perform(self)
end

---@param character IsoPlayer The character that will follow
---@param clickedplayer IsoPlayer The player to follow
---@return ISFollowToTimedAction
function ISFollowToTimedAction:new(character, clickedplayer)
    local o = ISBaseTimedAction.new(self, character)
    o.clickedplayer = clickedplayer
    o.square = clickedplayer:getSquare()
    o.tick = 0
    o.stopOnWalk = false
    o.stopOnRun = false
    o.maxTime = -1
    o.isFollow = false
    return o
end
