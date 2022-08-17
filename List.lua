local Symbol = require("Symbol")
local None = Symbol.new("None")

local List = {}
local ListMetatable = {}
local storage = {}

local function enumerate(iter)
    iter = iter()
    local i = -1

    return function()
        i = i + 1
        local item = iter()
        if item then
            return i, item
        else
            return nil
        end
    end
end

local env = getfenv()
env.None = None
env.enumerate = enumerate
env.range = range

function ListMetatable:__call(...)
    local instance = {}
    storage[instance] = {...}
    setmetatable(instance, self)
    return instance
end

local function parse(expr, len, is_left)
    if expr == "" then
        expr = is_left and 0 or len-1
    else
        expr, err = loadstring("return "..expr)
        if expr then
            expr = expr()
        else
            error(err, 3)
        end
    end

    if expr < 0 then
        expr = expr + len
    end

    return expr
end

function List:__index(index)
    self = storage[self]
    local T = type(index)

    if T == "string" then
        local item = List[index]
        if item then
            return item
        else
            local colon_index = string.find(index, ":")
            if colon_index then
                local lp = string.sub(index, 1, colon_index-1)
                local rp = string.sub(index, colon_index+1, #index)

                local len = #self

                lp = parse(lp, len, true)
                rp = parse(rp, len, false)

                local new = List()

                for i = lp, rp do
                    new:append(self[i+1])
                end
                return new
            else
                error(string.format("AttributeError: 'list' object has no attribute '%s'", index), 2)
            end
        end
    elseif T == "number" and index % 1 == 0 then
        index = index + 1
        local item = index > 0 and self[index] or self[#self+index]
        if item then
            return item
        else
            error("IndexError: list index out of range", 2)
        end
    elseif T == "boolean" then
        local item = self[index and 2 or 1]

        if item then
            return item
        else
            error("IndexError: list index out of range", 2)
        end
    else
        error("TypeError: list indices must be integers or slices, not list", 2)
    end
end

function List:__tostring()
    self = storage[self]
    local t = {}

    for i, v in ipairs(self) do
        if type(v) == "string" then
            v = "'"..v.."'"
        end
        t[i] = tostring(v)
    end

    return '['..table.concat(t, ", ")..']'
end

function List:__add(other)
    local new = List()
    for item in self() do
        new:append(item)
    end
    for item in other() do
        new:append(item)
    end
    return new
end

function range(min, max, step)
    local i = -1
    
    return function()
        return function()
            i = i + step
            if i < max then return i end
        end
    end
end

function List:__call()
    self = storage[self]
    local i = 0
    local len = #self

    return function()
        i = i + 1
        return i <= len and self[i] or nil
    end
end

function List:append(...)
    local args_count = select("#", ...)

    if args_count ~= 1 then
        error(string.format("TypeError: list.append() takes exactly one argument (%d given)", args_count), 2)
    end

    item = ...

    self = storage[self]
    if item == nil then
        item = None
    end
    table.insert(self, item)
end

return setmetatable(List, ListMetatable)
