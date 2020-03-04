-- Optimizations.
local tostring = tostring;

-- Initialize the single global true boolean.
local _true_boolean = {};

function _true_boolean.getSolutionType()
    return "boolean";
end

function _true_boolean.solve()
    return true;
end

function _true_boolean.toString()
    return "true";
end

-- Initialize the single global false boolean.
local _false_boolean = {};

function _false_boolean.getSolutionType()
    return "boolean";
end

function _false_boolean.solve()
    return false;
end

function _false_boolean.toString()
    return "false";
end

-- Just a helper to fetch the correct boolean conditional object.
function createConditionBoolean(value)
    if (value) then
        return _true_boolean;
    end
    
    return _false_boolean;
end