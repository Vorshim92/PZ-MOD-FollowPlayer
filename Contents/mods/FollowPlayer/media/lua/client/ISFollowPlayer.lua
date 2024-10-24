local options = getDebugOptions()

for i=1,options:getOptionCount() do
    local option = options:getOptionByIndex(i-1)
    local category = string.split(option:getName(), "\\.")
    print(category)
    for _,catOpt in ipairs(category) do
        print(catOpt:getName())
        print(catOpt:getValue())
    end
end

-- option:setValue(selected)
--   getDebugOptions():save()