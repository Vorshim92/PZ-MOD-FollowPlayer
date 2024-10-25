---@class ISVector2
---@field public vector Vector2
local ISVector2 = {}
ISVector2.__index = ISVector2

function ISVector2:new(x, y)
    local newObj = {}
    setmetatable(newObj, ISVector2)
    newObj.vector = Vector2.new()
    newObj.vector:set(x, y)
    return newObj
end

function ISVector2:add(other)
    self.vector:add(other.vector)
    return self
end

function ISVector2:scale(scalar)
    self.vector:scale(scalar)
    return self
end

function ISVector2:normalize()
    self.vector:normalize()
    return self
end

function ISVector2:rotate(angle)
    self.vector:rotate(angle)
    return self
end

function ISVector2:getX()
    return self.vector:getX()
end

function ISVector2:getY()
    return self.vector:getY()
end

function ISVector2:set(x, y)
    self.vector:set(x, y)
    return self
end

function ISVector2:clone()
    local newVector = ISVector2:new(0, 0)
    newVector.vector = self.vector:clone()
    return newVector
end

return ISVector2







-- ---comment
-- ---@param player IsoPlayer
-- ---@return Vector2
-- function ISVector2:lastAngle2Vector(player)
--     if not player then return nil end
--     local lastAngleVector = player:getLastAngle()
--     if not lastAngleVector then return nil end
--     return lastAngleVector
-- end

-- ---comment
-- ---@param isoplayer IsoPlayer
-- ---@return Vector2
-- function ISVector2:isoPlayer2Vector(isoplayer)
--     if not isoplayer then return nil end
--     if not isoplayer.getX then return nil end
--     local x = isoplayer:getX()
--     local y = isoplayer:getY()
--     if not x or not y then return nil end
--     return ISVector2.new(x, y)
-- end