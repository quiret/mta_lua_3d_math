-- Optimizations.
local tostring = tostring;
local _G = _G;
local error = error;

-- Global imports.
local _math_eq = _math_eq;
local _math_geq = _math_geq;
local _math_leq = _math_leq;
local output_math_debug = output_math_debug;
local createConditionBoolean = createConditionBoolean;
local mcs_multsum = mcs_multsum;

if not (_math_eq) or not (_math_geq) or not (_math_leq) or
   not (output_math_debug) or not (createConditionBoolean) or
   not (mcs_multsum) then
   
    error("cannot import global function; fatal script error.");
end

-- 0 = a1*k1 + b1*k2 + k3
local function createCondition2DLinearEquality(k1, k2, k3)
    -- Pre-calculate the conditional object.
    local c1, c2;
    local solutionType;
    
    if not (_math_eq(k1, 0)) then
        solutionType = "a1equal";
        c1 = (-k2)/k1;
        c2 = (-k3)/k1;
    elseif not (_math_eq(k2, 0)) then
        solutionType = "b1equal";
        c1 = (-k3)/k2;
    else
        return createConditionBoolean( _math_eq(k3, 0) );
    end
    
    local cond = {};
    
    function cond.getSolutionType()
        return solutionType;
    end
    
    function cond.solve()
        if (solutionType == "a1equal") then
            -- a1 = c1*b1 + c2
            return c1, c2;
        elseif (solutionType == "b1equal") then
            -- b1 = c1
            return c1;
        end
    end
    
    function cond.toStringEQ()
        if (solutionType == "a1equal") then
            return mcs_multsum({c1, c2}, {"b1"});
        elseif (solutionType == "b1equal") then
            return tostring( c1 );
        end
        
        return "unknown";
    end
    
    function cond.toString()
        if (solutionType == "a1equal") then
            return "a1 = " .. cond.toStringEQ();
        elseif (solutionType == "b1equal") then
            return "b1 = " .. cond.toStringEQ();
        end
        
        return "unknown";
    end
    
    function cond.disambiguate(otherCond, doPrintDebug)
        local ourSolutionType = cond.getSolutionType();
        local otherSolutionType = otherCond.getSolutionType();
        
        if (ourSolutionType == "a1equal") then
            if (otherSolutionType == "a1min") then
                local k1b, k2b = cond.solve();
                local k1l, k2l = otherCond.solve();
                
                if (doPrintDebug) then
                    output_math_debug( "DISAMB: " .. cond.toStringEQ() .. " >= " .. otherCond.toStringEQ() );
                end
                
                return createCondition2DLinearInequalityLTEQ( 0, k1b - k1l, k2b - k2l );
            elseif (otherSolutionType == "a1max") then
                local k1l, k2l = cond.solve();
                local k1b, k2b = otherCond.solve();
                
                if (doPrintDebug) then
                    output_math_debug( "DISAMB: " .. cond.toStringEQ() .. " <= " .. otherCond.toStringEQ() );
                end
                
                return createCondition2DLinearInequalityLTEQ( 0, k1b - k1l, k2b - k2l );
            elseif (otherSolutionType == "a1inferior") then
                local k1rb, k2rb = cond.solve();
                local k1rl, k2rl = otherCond.solve();
                
                if (doPrintDebug) then
                    output_math_debug( "DISAMB: " .. cond.toStringEQ() .. " > " .. otherCond.toStringEQ() );
                end
                
                return createCondition2DLinearInequalityLTEQ( 0, k1rb - k1rl, k2rb - k2rl );
            elseif (otherSolutionType == "a1superior") then
                local k1rl, k2rl = cond.solve();
                local k1rb, k2rb = otherCond.solve();
                
                if (doPrintDebug) then
                    output_math_debug( "DISAMB: " .. cond.toStringEQ() .. " < " .. otherCond.toStringEQ() );
                end
                
                return createCondition2DLinearInequalityLTEQ( 0, k1rb - k1rl, k2rb - k2rl );
            elseif (otherSolutionType == "a1equal") then
                local k1a, k2a = cond.solve();
                local k1b, k2b = otherCond.solve();
                
                if (doPrintDebug) then
                    output_math_debug( "REDUCE: " .. cond.toStringEQ() .. " = " .. otherCond.toStringEQ() );
                end
                
                return createCondition2DLinearEquality( 0, k1a - k1b, k2a - k2b );
            end
        elseif (ourSolutionType == "b1equal") then
            if (otherSolutionType == "b1min") then
                local k1b = cond.solve();
                local k1l = otherCond.solve();
                
                if (doPrintDebug) then
                    output_math_debug( "DISAMBCHECK: " .. cond.toStringEQ() .. " >= " .. otherCond.toStringEQ() );
                end
                
                return createConditionBoolean( _math_geq(k1b, k1l) );
            elseif (otherSolutionType == "b1max") then
                local k1l = cond.solve();
                local k1b = otherCond.solve();
                
                if (doPrintDebug) then
                    output_math_debug( "DISAMBCHECK: " .. cond.toStringEQ() .. " <= " .. otherCond.toStringEQ() );
                end
                
                return createConditionBoolean( _math_leq(k1l, k1b) );
            elseif (otherSolutionType == "b1inferior") then
                local k1rb = cond.solve();
                local k1rl = otherCond.solve();
                
                if (doPrintDebug) then
                    output_math_debug( "DISAMBCHECK: " .. cond.toStringEQ() .. " > " .. otherCond.toStringEQ() );
                end
                
                return createConditionBoolean(k1rb > k1rl);
            elseif (otherSolutionType == "b1superior") then
                local k1rl = cond.solve();
                local k1rb = otherCond.solve();
                
                if (doPrintDebug) then
                    output_math_debug( "DISAMBCHECK: " .. cond.toStringEQ() .. " < " .. otherCond.toStringEQ() );
                end
                
                return createConditionBoolean(k1rl < k1rb);
            elseif (otherSolutionType == "b1equal") then
                local k1a = cond.solve();
                local k1b = otherCond.solve();
                
                if (doPrintDebug) then
                    output_math_debug( "REDUCE: " .. cond.toStringEQ() .. " = " .. otherCond.toStringEQ() );
                end
                
                return createConditionBoolean(_math_eq(k1a, k1b));
            end
        end
        
        math_assert( false, "DISAMB ERROR: " .. ourSolutionType .. " and " .. otherSolutionType );
        
        return false;
    end
    
    return cond;
end
_G.createCondition2DLinearEquality = createCondition2DLinearEquality;

-- 0 != a1*k1 + b1*k2 + k3
function createCondition2DLinearInequalityNEQ(k1, k2, k3)
    -- Pre-calculate the condition.
    local c1, c2;
    local solutionType;
    
    if not (_math_eq(k1, 0)) then
        solutionType = "a1nequal";
        c1 = (-k2)/k1;
        c2 = (-k3)/k1;
    elseif not (_math_eq(k2, 0)) then
        solutionType = "b1nequal";
        c1 = (-k3)/k2;
    else
        return createConditionBoolean( not _math_eq(k3, 0) );
    end
    
    local cond = {};
    
    function cond.getSolutionType()
        return solutionType;
    end
    
    function cond.solve()
        if (solutionType == "a1nequal") then
            -- a1 != b1*c1 + c2
            return c1, c2;
        elseif (solutionType == "b1nequal") then
            -- b1 != c1
            return c1;
        end
    end
    
    function cond.toStringEQ()
        if (solutionType == "a1nequal") then
            return mcs_multsum({c1, c2}, {"b1"});
        elseif (solutionType == "b1nequal") then
            return tostring( c1 );
        end
        
        return "unknown";
    end
    
    function cond.toString()
        if (solutionType == "a1nequal") then
            return "a1 != " .. cond.toStringEQ();
        elseif (solutionType == "b1nequal") then
            return "b1 != " .. cond.toStringEQ();
        end
        
        return "unknown";
    end
    
    function cond.disambiguate(otherCond, doPrintDebug)
        if (doPrintDebug) then
            output_math_debug( "not meant to disambiguate a non-equal condition" );
        end
        
        return false;
    end
    
    return cond;
end
_G.createCondition2DLinearInequalityNEQ = createCondition2DLinearInequalityNEQ;

local function sharedCalculateValidityUpper2DInequality(cond, otherCond, doPrintDebug)
    local ourSolutionType = cond.getSolutionType();
    local otherSolutionType = otherCond.getSolutionType();
    
    if (ourSolutionType == "b1min") and (otherSolutionType == "b1superior") or
       (ourSolutionType == "b1inferior") and (otherSolutionType == "b1max") or
       (ourSolutionType == "b1inferior") and (otherSolutionType == "b1superior") then
        
        local lk1 = cond.solve();
        local uk1 = otherCond.solve();
        
        if (doPrintDebug) or (cfg_output_trivial_calc) then
            output_math_debug( "CALCVAL: " .. cond.toStringEQ() .. " < " .. otherCond.toStringEQ() );
        end
        
        return createConditionBoolean( lk1 < uk1 );
    elseif (ourSolutionType == "b1min") and (otherSolutionType == "b1max") then
        local mink1 = cond.solve();
        local maxk1 = otherCond.solve();
        
        if (doPrintDebug) or (cfg_output_trivial_calc) then
            output_math_debug( "CALCVAL: " .. cond.toStringEQ() .. " <= " .. otherCond.toStringEQ() );
        end
        
        return createConditionBoolean( _math_leq(mink1, maxk1) );
    elseif (ourSolutionType == "a1min") and (otherSolutionType == "a1superior") or
             (ourSolutionType == "a1inferior") and (otherSolutionType == "a1max") or
             (ourSolutionType == "a1inferior") and (otherSolutionType == "a1superior") then
        
        local lk1, lk2 = cond.solve();
        local uk1, uk2 = otherCond.solve();
        
        if (doPrintDebug) then
            output_math_debug( "CALCVAL: " .. cond.toStringEQ() .. " < " .. otherCond.toStringEQ() );
        end
        
        return createCondition2DLinearInequalityLT( 0, uk1 - lk1, uk2 - lk2 );
    elseif (ourSolutionType == "a1min") and (otherSolutionType == "a1max") then
        local mink1, mink2 = cond.solve();
        local maxk1, maxk2 = otherCond.solve();
        
        if (doPrintDebug) then
            output_math_debug( "CALCVAL: " .. cond.toStringEQ() .. " <= " .. otherCond.toStringEQ() );
        end
        
        return createCondition2DLinearInequalityLTEQ( 0, maxk1 - mink1, maxk2 - mink2 );
    end
    
    math_assert( false, "CALCVAL ERROR: " .. ourSolutionType .. " and " .. otherSolutionType );
    
    return false;
end

-- 0 < a1*k1 + b1*k2 + k3
local function createCondition2DLinearInequalityLT(k1, k2, k3)
    -- Pre-calculate the condition.
    local solutionType;
    local is_a1_bound = false;
    local is_b1_bound = false;
    local c1, c2;
    
    if not (_math_eq(k1, 0)) then
        if (k1 > 0) then
            solutionType = "a1inferior";
        else
            solutionType = "a1superior";
        end
        
        is_a1_bound = true;
        c1 = (-k2)/k1;
        c2 = (-k3)/k1;
    elseif not (_math_eq(k2, 0)) then
        if (k2 > 0) then
            solutionType = "b1inferior";
        else
            solutionType = "b1superior";
        end
        
        is_b1_bound = true;
        c1 = (-k3)/k2;
    else
        return createConditionBoolean( 0 < k3 );
    end
    
    local cond = {};
    
    function cond.getSolutionType()
        return solutionType;
    end
    
    function cond.solve()
        if (is_a1_bound) then
            -- a1 </> c1*b1 + c2
            return c1, c2;
        elseif (is_b1_bound) then
            -- b1 </> c1
            return c1;
        end
    end
    
    function cond.toStringEQ()
        if (solutionType == "a1superior") or (solutionType == "a1inferior") then
            return mcs_multsum({c1, c2}, {"b1"});
        elseif (solutionType == "b1superior") or (solutionType == "b1inferior") then
            return tostring( c1 );
        end
        
        return "unknown";
    end
    
    function cond.toString()
        if (solutionType == "a1superior") then
            return "a1 < " .. cond.toStringEQ();
        elseif (solutionType == "a1inferior") then
            return "a1 > " .. cond.toStringEQ();
        elseif (solutionType == "b1superior") then
            return "b1 < " .. cond.toStringEQ();
        elseif (solutionType == "b1inferior") then
            return "b1 > " .. cond.toStringEQ();
        end
        
        return "unknown";
    end
    
    function cond.disambiguate(otherCond, doPrintDebug)
        local ourSolutionType = cond.getSolutionType();
        local otherSolutionType = otherCond.getSolutionType();
        
        if (ourSolutionType == "a1inferior") then
            if (otherSolutionType == "a1inferior") or (otherSolutionType == "a1min") then
                local k1b, k2b = cond.solve();
                local k1l, k2l = otherCond.solve();
                
                if (doPrintDebug) then
                    output_math_debug( "SOLINF: " .. cond.toStringEQ() .. " >= " .. otherCond.toStringEQ() );
                end
                
                return createCondition2DLinearInequalityLTEQ( 0, k1b - k1l, k2b - k2l );
            elseif (otherSolutionType == "a1equal") then
                return createConditionBoolean(false);
            end
        elseif (ourSolutionType == "a1superior") then
            if (otherSolutionType == "a1superior") or (otherSolutionType == "a1max") then
                local k1l, k2l = cond.solve();
                local k1b, k2b = otherCond.solve();
                
                if (doPrintDebug) then
                    output_math_debug( "SOLSUP: " .. cond.toStringEQ() .. " <= " .. otherCond.toStringEQ() );
                end
                
                return createCondition2DLinearInequalityLTEQ( 0, k1b - k1l, k2b - k2l );
            elseif (otherSolutionType == "a1equal") then
                return createConditionBoolean(false);
            end
        elseif (ourSolutionType == "b1inferior") then
            if (otherSolutionType == "b1inferior") or (otherSolutionType == "b1min") then
                local k1b = cond.solve();
                local k1l = otherCond.solve();
                
                if (doPrintDebug) and (cfg_output_trivial_calc) then
                    output_math_debug( "INFCHECK: " .. cond.toStringEQ() .. " >= " .. otherCond.toStringEQ() );
                end
                
                return createConditionBoolean( _math_geq(k1b, k1l) );
            elseif (otherSolutionType == "b1equal") then
                return createConditionBoolean(false);
            end
        elseif (ourSolutionType == "b1superior") then
            if (otherSolutionType == "b1superior") or (otherSolutionType == "b1max") then
                local k1l = cond.solve();
                local k1b = otherCond.solve();
                
                if (doPrintDebug) and (cfg_output_trivial_calc) then
                    output_math_debug( "SUPCHECK: " .. cond.toStringEQ() .. " <= " .. otherCond.toStringEQ() );
                end
                
                return createConditionBoolean( _math_leq(k1l, k1b) );
            elseif (otherSolutionType == "b1equal") then
                return createConditionBoolean(false);
            end
        end
        
        math_assert( false, "DISAMB ERROR: " .. ourSolutionType .. " and " .. otherSolutionType );
        
        return false;
    end
    
    function cond.calcValidityUpper(otherCond, doPrintDebug)
        return sharedCalculateValidityUpper2DInequality(cond, otherCond, doPrintDebug);
    end
    
    return cond;
end
_G.createCondition2DLinearInequalityLT = createCondition2DLinearInequalityLT;

-- 0 <= a1*k1 + b1*k2 + k3
local function createCondition2DLinearInequalityLTEQ(k1, k2, k3)
    -- Pre-calculate the condition.
    local solutionType;
    local is_a1_bound = false;
    local is_b1_bound = false;
    local c1, c2;
    
    if not (_math_eq(k1, 0)) then
        if (k1 > 0) then
            solutionType = "a1min";
        else
            solutionType = "a1max";
        end
        
        is_a1_bound = true;
        c1 = (-k2)/k1;
        c2 = (-k3)/k1;
    elseif not (_math_eq(k2, 0)) then
        if (k2 > 0) then
            solutionType = "b1min";
        else
            solutionType = "b1max";
        end
        
        is_b1_bound = true;
        c1 = (-k3)/k2;
    else
        return createConditionBoolean( _math_leq(0, k3) );
    end
    
    local cond = {};

    function cond.getSolutionType()
        return solutionType;
    end
    
    function cond.solve()
        if (is_a1_bound) then
            -- a1 </>= c1*b1 + c2
            return c1, c2;
        elseif (is_b1_bound) then
            -- b1 </>= c1
            return c1;
        end
    end
    
    function cond.toStringEQ()
        if (solutionType == "a1max") or (solutionType == "a1min") then
            return mcs_multsum({c1, c2}, {"b1"});
        elseif (solutionType == "b1max") or (solutionType == "b1min") then
            return tostring( c1 );
        end
        
        return "unknown";
    end

    function cond.toString()
        if (solutionType == "a1max") then
            return "a1 <= " .. cond.toStringEQ();
        elseif (solutionType == "a1min") then
            return "a1 >= " .. cond.toStringEQ();
        elseif (solutionType == "b1max") then
            return "b1 <= " .. cond.toStringEQ();
        elseif (solutionType == "b1min") then
            return "b1 >= " .. cond.toStringEQ();
        elseif (solutionType == "boolean") then
            return tostring( cond.solve() );
        end
        
        return "unknown";
    end
    
    -- Returns a condition that is required to be valid exactly-when that condition is valid in comparison
    -- to given other condition.
    function cond.disambiguate(otherCond, doPrintDebug)
        local ourSolutionType = cond.getSolutionType();
        local otherSolutionType = otherCond.getSolutionType();
        
        if (ourSolutionType == "a1min") then
            if (otherSolutionType == "a1min") then
                local k1b, k2b = cond.solve();
                local k1l, k2l = otherCond.solve();
                
                if (doPrintDebug) then
                    output_math_debug( "SOLINF: " .. cond.toStringEQ() .. " >= " .. otherCond.toStringEQ() );
                end
                
                return createCondition2DLinearInequalityLTEQ( 0, k1b - k1l, k2b - k2l );
            elseif (otherSolutionType == "a1inferior") then
                local k1rb, k2rb = cond.solve();
                local k1rl, k2rl = otherCond.solve();
                
                if (doPrintDebug) then
                    output_math_debug( "SOLINF: " .. cond.toStringEQ() .. " > " .. otherCond.toStringEQ() );
                end
                
                return createCondition2DLinearInequalityLT( 0, k1rb - k1rl, k2rb - k2rl );
            elseif (otherSolutionType == "a1equal") then
                return createConditionBoolean(false);
            end
        elseif (ourSolutionType == "a1max") then
            if (otherSolutionType == "a1max") then
                local k1l, k2l = cond.solve();
                local k1b, k2b = otherCond.solve();
                
                if (doPrintDebug) then
                    output_math_debug( "SOLSUP: " .. cond.toStringEQ() .. " <= " .. otherCond.toStringEQ() );
                end
                
                return createCondition2DLinearInequalityLTEQ( 0, k1b - k1l, k2b - k2l );
            elseif (otherSolutionType == "a1superior") then
                local k1rl, k2rl = cond.solve();
                local k1rb, k2rb = otherCond.solve();
                
                if (doPrintDebug) then
                    output_math_debug( "SOLSUP: " .. cond.toStringEQ() .. " < " .. otherCond.toStringEQ() );
                end
                
                return createCondition2DLinearInequalityLT( 0, k1rb - k1rl, k2rb - k2rl );
            elseif (otherSolutionType == "a1equal") then
                return createConditionBoolean(false);
            end
        elseif (ourSolutionType == "b1min") then
            if (otherSolutionType == "b1min") then
                local k1b = cond.solve();
                local k1l = otherCond.solve();
                
                if (doPrintDebug) and (cfg_output_trivial_calc) then
                    output_math_debug( "INFCHECK: " .. cond.toStringEQ() .. " >= " .. otherCond.toStringEQ() );
                end
                
                return createConditionBoolean( _math_geq(k1b, k1l) );
            elseif (otherSolutionType == "b1inferior") then
                local k1rb = cond.solve();
                local k1rl = otherCond.solve();
                
                if (doPrintDebug) and (cfg_output_trivial_calc) then
                    output_math_debug( "INFCHECK: " .. cond.toStringEQ() .. " > " .. otherCond.toStringEQ() );
                end
                
                return createConditionBoolean( k1rb > k1rl );
            elseif (otherSolutionType == "b1equal") then
                return createConditionBoolean(false);
            end
        elseif (ourSolutionType == "b1max") then
            if (otherSolutionType == "b1max") then
                local k1l = cond.solve();
                local k1b = otherCond.solve();
                
                if (doPrintDebug) and (cfg_output_trivial_calc) then
                    output_math_debug( "SUPCHECK: " .. cond.toStringEQ() .. " <= " .. otherCond.toStringEQ() );
                end
                
                return createConditionBoolean( _math_leq(k1l, k1b) );
            elseif (otherSolutionType == "b1superior") then
                local k1rl = cond.solve();
                local k1rb = otherCond.solve();
                
                if (doPrintDebug) and (cfg_output_trivial_calc) then
                    output_math_debug( "SUPCHECK: " .. cond.toStringEQ() .. " < " .. otherCond.toStringEQ() );
                end
                
                return createConditionBoolean( k1rl < k1rb );
            elseif (otherSolutionType == "b1equal") then
                return createConditionBoolean(false);
            end
        end
        
        math_assert( false, "DISAMB ERROR: " .. ourSolutionType .. " and " .. otherSolutionType );
        
        return false;
    end
    
    function cond.calcValidityUpper(otherCond, doPrintDebug)
        return sharedCalculateValidityUpper2DInequality(cond, otherCond, doPrintDebug);
    end
    
    return cond;
end
_G.createCondition2DLinearInequalityLTEQ = createCondition2DLinearInequalityLTEQ;