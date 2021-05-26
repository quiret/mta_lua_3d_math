-- Optimizations.
local ipairs = ipairs;
local _G = _G;
local table = table;
local tinsert = table.insert;
local tremove = table.remove;
local tostring = tostring;
local error = error;

-- Global imports.
local createConditionBoolean = createConditionBoolean;

if not (createConditionBoolean) then
    error("cannot find required global imports; fatal script error.");
end

local function createSeparatedConditionString(vars, sep)
    local str = "( ";
    local sepStr = " " .. sep .. " ";
    
    local hasItem = false;
    
    for m,n in ipairs(vars) do
        if ( hasItem ) then
            str = str .. sepStr;
        end

        str = str .. n.toString();
        
        hasItem = true;
    end
    
    str = str .. " )";
    
    return str;
end

local function resolve_cond(cond)
    if (cond.resolve) then
        return cond.resolve();
    end
    
    return cond;
end
_G.resolve_cond = resolve_cond;

function createConditionAND(_initial_cond)
    local cond = {};
    local vars = {};
    local is_invalid = false;
    local has_only_true = false;
    
    if not (_initial_cond == nil) then
        has_only_true = _initial_cond;
    end
    
    function cond.clone()
        local new_cond = createConditionAND();
        
        for m,n in ipairs(vars) do
            new_cond.addVar(n);
        end
        
        return new_cond;
    end
    
    function cond.reset(start_cond)
        vars = {};
        is_invalid = false;
        has_only_true = false;
        
        if not (start_cond == nil) then
            has_only_true = start_cond;
        end
    end
    
    function cond.getSolutionType()
        if (has_only_true) or (is_invalid) or (#vars == 0) then
            return "boolean";
        end
        
        if (#vars == 1) then
            return vars[1].getSolutionType();
        end
        
        return "and-dynamic";
    end
    
    function cond.solve()
        if (is_invalid) then
            return false;
        end
        
        if (has_only_true) then
            return true;
        end
        
        if (#vars == 0) then
            return false;
        end
        
        if (#vars == 1) then
            return vars[1].solve();
        end
    end
    
    function cond.getChainType()
        if (has_only_true) or (is_invalid) then
            return "none";
        end
        
        return "and";
    end
    
    function cond.getVar(idx, userdata)
        return vars[idx];
    end
    
    function cond.getVarCount()
        if (is_invalid) or (has_only_true) then
            return 0;
        end
        
        return #vars;
    end
    
    function cond.forAllVars(cb)
        if (is_invalid) or (has_only_true) then
            return;
        end
        
        for m,n in ipairs(vars) do
            cb(m, nil, n);
        end
    end
    
    -- TODO: think about this, because I had a reason to suggest removal of this function.
    function cond.getVars()
        if (is_invalid) or (has_only_true) then
            return {};
        end
        
        return vars;
    end
    
    local function event_handle_newVar(var, type_of_op)
        -- Optimization.
        local solutionType = var.getSolutionType();
        
        if (solutionType == "boolean") then
            if ( var.solve() == false ) then
                is_invalid = true;
            else
                if (type_of_op == "add-var") and (#vars == 0) and (is_invalid == false) or
                   (type_of_op == "repl-var") and (#vars == 1) then
                    
                    has_only_true = true;
                end
            end
            
            return false;
        end
        
        has_only_true = false;
        return true;
    end
    
    function cond.addVar(var)
        if (is_invalid) then
            return;
        end
        
        if not (var) then
            error("invalid value for var", 2);
        end
        
        if (event_handle_newVar(var, "add-var")) then
            tinsert(vars, var);
        end
    end
    
    function cond.addCond(constructor, ...)
        if (is_invalid) then
            return;
        end
        
        cond.addVar(constructor(...));
    end
    
    function cond.replaceVar(idx, userdata, replaceBy)
        -- userdata is unused, always pass it over as nil!
    
        if (is_invalid) then
            math_assert( false, "replaceVar error in and-dynamic: always false", 2 );
        end
        
        if (has_only_true) then
            math_assert( false, "replaceVar error in and-dynamic: always true", 2 );
        end
    
        local replacedVar = vars[idx];
        
        if not (replacedVar) then
            math_assert( false, "replaceVar error in and-dynamic: invalid idx " .. idx .. " (has " .. #vars .. " variable[s])", 2 );
        end
        
        -- TODO: maybe fix support for boolean-state.
        
        if (event_handle_newVar(replaceBy, "repl-var")) then
            vars[idx] = replaceBy;
        else
            if (has_only_true == false) then
                tremove( vars, idx );
            end
            
            return "removed";
        end
        
        return "ok";
    end
    
    function cond.establishAND(var)
        if (is_invalid) then
            return;
        end
    
        local solutionType = var.getSolutionType();
        
        if (solutionType == "and-dynamic") then
            var = resolve_cond(var);
            
            for m,n in ipairs(var.getVars()) do
                cond.establishAND(n);
            end
        else
            cond.addVar(var);
        end
    end
    
    function cond.pushthroughAND(var)
        if (is_invalid) then
            return;
        end
    
        local anyORCond = false;
        
        for m,n in ipairs(vars) do
            if (n.getSolutionType() == "or-dynamic") then
                n = resolve_cond(n);
                n.pushthroughAND(var);
                anyORCond = true;
            end
        end
        
        if not (anyORCond) then
            cond.establishAND(var);
        end
    end
    
    function cond.toStringEQ()
        if (#vars == 1) then
            return vars[1].toStringEQ();
        elseif (#vars == 0) then
            return "false";
        end
    end
    
    function cond.toString()
        if (is_invalid) then
            return "false";
        elseif (has_only_true) then
            return "true";
        elseif (#vars == 1) then
            return vars[1].toString();
        elseif (#vars == 0) then
            return "false";
        end
            
        return createSeparatedConditionString( vars, "AND" );
    end
    
    function cond.resolve()
        if (is_invalid) then
            return createConditionBoolean(false);
        elseif (has_only_true) then
            return createConditionBoolean(true);
        elseif (#vars == 1) then
            return resolve_cond( vars[1] );
        end
        
        return cond;
    end
    
    -- Calculates an equivalent condition which is an OR condition.
    -- Unused.
    function cond.spliceOnce()
        local rootCond = createConditionOR();
        
        if (has_only_true) or (is_invalid) then
            return rootCond;
        end

        for m,n in ipairs(vars) do
            rootCond.establishAND(n);
        end
        
        return rootCond;
    end
    
    return cond;
end

local function travel_and_line(andcond, cb)
    if (andcond.getSolutionType() == "and-dynamic") then
        andcond = resolve_cond(andcond);
        
        for m,n in ipairs(andcond.getVars()) do
            travel_and_line(n, cb);
        end
    else
        cb(andcond);
    end
end
_G.travel_and_line = travel_and_line;

local function for_all_cases(cond, cb)
    if (cond.getSolutionType() == "or-dynamic") then
        cond = resolve_cond(cond);
        for m,n in ipairs(cond.getVars()) do
            for_all_cases(n, cb);
        end
    else
        cb(cond);
    end
end
_G.for_all_cases = for_all_cases;

function createConditionOR(_initial_cond)
    local cond = {};
    local vars = vars_in or {};
    local is_valid_straight = false;
    local has_always_false = false;
    
    if not (_initial_cond == nil) then
        if (_initial_cond) then
            is_valid_straight = true;
        else
            has_always_false = true;
        end
    end
    
    function cond.clone()
        local newcond = createConditionOR();
        
        for m,n in ipairs(vars) do
            newcond.addVar(n);
        end
        
        return newcond;
    end
    
    function cond.getSolutionType()
        if (is_valid_straight) or (has_always_false) then
            return "boolean";
        end
        
        if (#vars == 1) then
            return vars[1].getSolutionType();
        end
        
        return "or-dynamic";
    end
    
    function cond.solve()
        if (is_valid_straight) then
            return true;
        elseif (has_always_false) then
            return false;
        elseif (#vars == 1) then
            return vars[1].solve();
        end
    end
    
    function cond.getChainType()
        if (is_valid_straight) or (has_always_false) then
            return "none";
        end
        
        return "or";
    end
    
    function cond.reset()
        is_valid_straight = false;
        vars = {};
    end
    
    function cond.getVar(idx, userdata)
        return vars[idx];
    end
    
    function cond.getVarCount()
        if (is_valid_straight) or (has_always_false) then
            return 0;
        end
        
        return #vars;
    end
    
    function cond.forAllVars(cb)
        if (is_valid_straight) or (has_always_false) then
            return;
        end
        
        for m,n in ipairs(vars) do
            cb(m, nil, n);
        end
    end
    
    function cond.getVars()
        if (is_valid_straight) or (has_always_false) then
            return {};
        end
        
        return vars;
    end
    
    local function event_handle_newVar(var, type_of_op)
        -- Optimization.
        local solutionType = var.getSolutionType();
        
        if (solutionType == "boolean") then
            if (var.solve() == true) then
                is_valid_straight = true;
                has_always_false = false;
            else
                if (type_of_op == "add-var") and (#vars == 0) or
                   (type_of_op == "repl-var") and (#vars == 1) then
                    
                    has_always_false = true;
                end
            end
            
            return false;
        end
        
        has_always_false = false;
        return true;
    end
    
    function cond.addVar(var)
        if (is_valid_straight) then
            return;
        end
        
        if (event_handle_newVar(var, "add-var")) then
            tinsert(vars, var);
        end
    end
    
    function cond.addCond(constructor, ...)
        if (is_valid_straight) then
            return;
        end
        
        cond.addVar(constructor(...));
    end
    
    function cond.replaceVar(idx, userdata, replaceBy)
        -- userdata is unused, always pass as nil!
    
        if (is_valid_straight) then
            math_assert( false, "replaceVar error in or-dynamic: always true", 2 );
        end
        
        if (has_always_false) then
            math_assert( false, "replaceVar error in or-dynamic: always false", 2 );
        end
    
        local replacedVar = vars[idx];
        
        if not (replacedVar) then
            math_assert( false, "replaceVar error in or-dynamic: invalid idx " .. idx .. " (has " .. #vars .. " variable[s])", 2 );
        end
        
        if (event_handle_newVar(replaceBy, "repl-var")) then
            vars[idx] = replaceBy;
        else
            if (has_always_false == false) then
                tremove(vars, idx);
            end
            
            return "removed";
        end
        
        return "ok";
    end
    
    function cond.toString()
        if (is_valid_straight) then
            return "true";
        elseif (has_always_false) then
            return "false";
        elseif (#vars == 1) then
            return vars[1].toString();
        end
        
        return createSeparatedConditionString( vars, "OR" );
    end
    
    function cond.resolve()
        if (is_valid_straight) then
            return createConditionBoolean(true);
        elseif (has_always_false) then
            return createConditionBoolean(false);
        elseif (#vars == 1) then
            return resolve_cond( vars[1] );
        end
        
        return cond;
    end
    
    function cond.toStringEQ()
        if (#vars == 1) then
            return vars[1].toStringEQ();
        end
    end
    
    local function conjunct_cond(cond, conjitem)
        local solutionType = cond.getSolutionType();
        
        if (solutionType == "or-dynamic") then
            cond.establishAND(conjitem);
            return cond;
        end

        if (solutionType == "and-dynamic") then
            travel_and_line(conjitem,
                function(n)
                    cond.addVar(n);
                end
            );
            
            return cond;
        end
        
        local newcond = createConditionAND();
        newcond.addVar(cond);
        newcond.establishAND(conjitem);
        return newcond;
    end
    
    local function conjunct_cond_new(cond, conjitem)
        cond = resolve_cond(cond);
    
        if (cond.clone) then
            return conjunct_cond(cond.clone(), conjitem);
        end
        
        return conjunct_cond(cond, conjitem);
    end
    
    function cond.distributeAND(otherCond)
        if (has_always_false) then
            return;
        end
        
        local solutionType = otherCond.getSolutionType();
        
        if (solutionType == "or-dynamic") then
            otherCond = resolve_cond(otherCond);
        
            local oldVars = vars;
            cond.reset();
            
            for _,orCond in ipairs(oldVars) do
                for_all_cases(otherCond,
                    function(subOrCond)
                        cond.addVar(conjunct_cond_new(orCond, subOrCond));
                    end
                );
            end
        else
            cond.establishAND(otherCond);
        end
    end
    
    function cond.establishAND(otherCond)
        if (has_always_false) then
            return;
        end
    
        local solutionType = otherCond.getSolutionType();
        
        if (solutionType == "boolean") then
            if (otherCond.solve() == false) then
                cond.reset(false);
            end
        else
            if (#vars == 0) then
                cond.addVar( otherCond );
            else
                for m,subvar in ipairs(vars) do
                    vars[m] = conjunct_cond_new( subvar, otherCond );
                end
            end
        end
    end
    
    function cond.pushthroughAND(otherCond)
        if (#vars == 0) then
            cond.establishAND(otherCond);
            return;
        end
        
        local m = 1;
        
        while ( m <= #vars ) do
            local orVar = vars[m];
            local solutionType = orVar.getSolutionType();
            
            local should_advance = true;
            
            if (solutionType == "and-dynamic") or (solutionType == "or-dynamic") then
                orVar = resolve_cond( orVar );
                orVar = orVar.clone();
                orVar.pushthroughAND(otherCond);
                should_advance = not ( cond.replaceVar( m, orVar ) == "removed" );
            else
                local replRet = cond.replaceVar( m, conjunct_cond( orVar, otherCond ) );
                should_advance = not ( replRet == "removed" );
            end
            
            if (cond.getChainType() == "none") then
                break;
            end
            
            if (should_advance) then
                m = m + 1;
            end
        end
    end
    
    return cond;
end