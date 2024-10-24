local ISVector2 = {}

-- public Vector2 getLastAngle() {
--     return this.lastAngle;
--  }


function ISVector2.newVector(x,y)
    local player = getPlayer()
    if not player then return nil end
    -- workaround using getLastAngle of isoPlayer to create javaobject vector from the player
    local tempVector = player:getLastAngle()
    if not tempVector then return nil end
    local newVector = tempVector:clone()
    newVector:set(x,y)
    return newVector
end

function ISVector2.isoplayer2vector(isoplayer)
    if not isoplayer then return nil end
    if not isoplayer.getX then return nil end
    local x = isoplayer:getX()
    local y = isoplayer:getY()
    if not x or not y then return nil end
    return ISVector2.newVector(x,y)
end

return ISVector2