local Symbol = {}
Symbol.__index = Symbol

function Symbol.new(name)
    return setmetatable({
        name = name
    }, Symbol)
end

function Symbol:__tostring()
    return self.name
end

return Symbol
