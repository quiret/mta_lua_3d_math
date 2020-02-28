-- Optimizations.
local tostring = tostring;

function createConditionBoolean(value)
    local cond = {};
    
    function cond.getSolutionType()
        return "boolean";
    end
    
    function cond.solve()
        return value;
    end
    
    function cond.toString()
        return tostring(value);
    end
    
    return cond;
end