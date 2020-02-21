-- Created by (c)The_GTA.
-- 0 = |a1|*k1 + |b1|*k2 + k3
function createConditionAbsoluteLinearEquality(k1, k2, k3)
    local cond = {};
    
    function cond.getSolutionType()
        if not (k1 == 0) then
            return "a1absequal";
        elseif not (k2 == 0) then
            return "b1absequal";
        end
        
        return "boolean";
    end
    
    function cond.solve()
        if not (k1 == 0) then
            local c1 = (-k2)/k1;
            local c2 = (-k3)/k1;
            
            -- |a1| = c1*|b1| + c2
            return c1, c2;
        elseif not (k2 == 0) then
            local c1 = (-k3)/k2;
            
            -- |b1| = c1
            return c1;
        else
            -- boolean
            return ( k3 == 0 );
        end
    end
    
    function cond.toStringEQ()
        local solutionType = cond.getSolutionType();
        local c1, c2 = cond.solve();
        
        if (solutionType == "a1absequal") then
            return c1 .. "*|b1| + " .. c2;
        elseif (solutionType == "b1absequal") then
            return tostring( c1 );
        elseif (solutionType == "boolean") then
            return tostring( c1 );
        end
        
        return "unknown";
    end
    
    function cond.toString()
        local solutionType = cond.getSolutionType();
        
        if (solutionType == "a1absequal") then
            return "|a1| = " .. cond.toStringEQ();
        elseif (solutionType == "b1absequal") then
            return "|b1| = " .. cond.toStringEQ();
        elseif (solutionType == "boolean") then
            return tostring( cond.solve() );
        end
        
        return "unknown";
    end
    
    function cond.disambiguate(otherCond)
        local ourSolutionType = cond.getSolutionType();
        local otherSolutionType = otherCond.getSolutionType();
        
        if (ourSolutionType == "a1absequal") then
            if (otherSolutionType == "a1min") then
                local k1b, k2b = cond.solve();
                local k1l, k2l = otherCond.solve();
                
                output_math_debug( "DISAMB: " .. cond.toStringEQ() .. " >= " .. otherCond.toStringEQ() );
                
                return createConditionAbsoluteLinearInequalityLTEQ( 0, k1b - k1l, k2b - k2l );
            elseif (otherSolutionType == "a1absmax") then
                local k1l, k2l = cond.solve();
                local k1b, k2b = otherCond.solve();
                
                output_math_debug( "DISAMB: " .. cond.toStringEQ() .. " <= " .. otherCond.toStringEQ() );
                
                return createConditionAbsoluteLinearInequalityLTEQ( 0, k1b - k1l, k2b - k2l );
            elseif (otherSolutionType == "a1absinferior") then
                local k1rb, k2rb = cond.solve();
                local k1rl, k2rl = otherCond.solve();
                
                output_math_debug( "DISAMB: " .. cond.toStringEQ() .. " > " .. otherCond.toStringEQ() );
                
                return createConditionAbsoluteLinearInequality( 0, k1rb - k1rl, k2rb - k2rl );
            elseif (otherSolutionType == "a1abssuperior") then
                local k1rl, k2rl = cond.solve();
                local k1rb, k2rb = otherCond.solve();
                
                output_math_debug( "DISAMB: " .. cond.toStringEQ() .. " < " .. otherCond.toStringEQ() );
                
                return createConditionAbsoluteLinearInequality( 0, k1rb - k1rl, k2rb - k2rl );
            elseif (otherSolutionType == "a1absequal") then
                -- Meow. We assume that if both are equal then both are valid. Could be a very evil assumption!
                return createConditionBoolean(true);
            end
        elseif (ourSolutionType == "b1absequal") then
            if (otherSolutionType == "b1absmin") then
                local k1b = cond.solve();
                local k1l = otherCond.solve();
                
                output_math_debug( "DISAMBCHECK: " .. cond.toStringEQ() .. " >= " .. otherCond.toStringEQ() );
                
                return createConditionBoolean(k1b >= k1l);
            elseif (otherSolutionType == "b1absmax") then
                local k1l = cond.solve();
                local k1b = otherCond.solve();
                
                output_math_debug( "DISAMBCHECK: " .. cond.toStringEQ() .. " <= " .. otherCond.toStringEQ() );
                
                return createConditionBoolean(k1l <= k1b);
            elseif (otherSolutionType == "b1absinferior") then
                local k1rb = cond.solve();
                local k1rl = otherCond.solve();
                
                output_math_debug( "DISAMBCHECK: " .. cond.toStringEQ() .. " > " .. otherCond.toStringEQ() );
                
                return createConditionBoolean(k1rb > k1rl);
            elseif (otherSolutionType == "b1abssuperior") then
                local k1rl = cond.solve();
                local k1rb = otherCond.solve();
                
                output_math_debug( "DISAMBCHECK: " .. cond.toStringEQ() .. " < " .. otherCond.toStringEQ() );
                
                return createConditionBoolean(k1rl < k1rb);
            elseif (otherSolutionType == "b1absequal") then
                local k1a = cond.solve();
                local k1b = otherCond.solve();
                
                output_math_debug( "DISAMBCHECK: " .. cond.toStringEQ() .. " = " .. otherCond.toStringEQ() );
                
                return createConditionBoolean(k1a == k1b);
            end
        end
        
        output_math_debug( "DISAMB ERROR: " .. ourSolutionType .. " and " .. otherSolutionType );
        
        return false;
    end
    
    return cond;
end

-- 0 < |a1|*k1 + |b1|*k2 + k3
function createConditionAbsoluteLinearInequality(k1, k2, k3)
    local cond = {};
    local is_always_true = false;
    
    if (k1 <= 0) and (k2 <= 0) and (k3 <= 0) then
        k1 = 0;
        k2 = 0;
        k3 = 0;
    end
    
    if (k1 > 0) and (k2 > 0) and (k3 > 0) then
        k1 = 0;
        k2 = 0;
        k3 = 0;
        is_always_true = true;
    end
    
    function cond.getSolutionType()
        if (k1 > 0) then
            return "a1absinferior";
        elseif (k1 < 0) then
            return "a1abssuperior";
        elseif (k2 > 0) then
            return "b1absinferior";
        elseif (k2 < 0) then
            return "b1abssuperior";
        else
            return "boolean";
        end
    end
    
    function cond.solve()
        if not (k1 == 0) then
            local c1 = (-k2)/k1;
            local c2 = (-k3)/k1;
            
            -- |a1| </> c1*|b1| + c2
            return c1, c2;
        elseif not (k2 == 0) then
            local c1 = (-k3)/k2;
            
            -- |b1| </> c1
            return c1;
        elseif (is_always_true) then
            return true;
        else
            return ( 0 < k3 );
        end
    end
    
    function cond.toStringEQ()
        local solutionType = cond.getSolutionType();
        local c1, c2 = cond.solve();
        
        if (solutionType == "a1abssuperior") or (solutionType == "a1absinferior") then
            return c1 .. "*|b1| + " .. c2;
        elseif (solutionType == "b1abssuperior") or (solutionType == "b1absinferior") then
            return tostring( c1 );
        elseif (solutionType == "boolean") then
            return tostring( c1 );
        end
        
        return "unknown";
    end
    
    function cond.toString()
        local solutionType = cond.getSolutionType();
        
        if (solutionType == "a1abssuperior") then
            return "|a1| < " .. cond.toStringEQ();
        elseif (solutionType == "a1absinferior") then
            return "|a1| > " .. cond.toStringEQ();
        elseif (solutionType == "b1abssuperior") then
            return "|b1| < " .. cond.toStringEQ();
        elseif (solutionType == "b1absinferior") then
            return "|b1| > " .. cond.toStringEQ();
        elseif (solutionType == "boolean") then
            return tostring( cond.solve() );
        end
        
        return "unknown";
    end
    
    function cond.disambiguate(otherCond)
        local ourSolutionType = cond.getSolutionType();
        local otherSolutionType = otherCond.getSolutionType();
        
        if (ourSolutionType == "a1absinferior") then
            if (otherSolutionType == "a1absinferior") or (otherSolutionType == "a1absmin") then
                local k1b, k2b = cond.solve();
                local k1l, k2l = otherCond.solve();
                
                output_math_debug( "SOLINF: " .. cond.toStringEQ() .. " >= " .. otherCond.toStringEQ() );
                
                return createConditionAbsoluteLinearInequalityLTEQ( 0, k1b - k1l, k2b - k2l );
            elseif (otherSolutionType == "a1absequal") then
                return createConditionBoolean(false);
            end
        elseif (ourSolutionType == "a1abssuperior") then
            if (otherSolutionType == "a1abssuperior") or (otherSolutionType == "a1absmax") then
                local k1l, k2l = cond.solve();
                local k1b, k2b = otherCond.solve();
                
                output_math_debug( "SOLSUP: " .. cond.toStringEQ() .. " <= " .. otherCond.toStringEQ() );
                
                return createConditionAbsoluteLinearInequalityLTEQ( 0, k1b - k1l, k2b - k2l );
            elseif (otherSolutionType == "a1equal") then
                return createConditionBoolean(false);
            end
        elseif (ourSolutionType == "b1absinferior") then
            if (otherSolutionType == "b1absinferior") or (otherSolutionType == "b1absmin") then
                local k1b = cond.solve();
                local k1l = otherCond.solve();
                
                output_math_debug( "INFCHECK: " .. cond.toStringEQ() .. " >= " .. otherCond.toStringEQ() );
                
                return createConditionBoolean( k1b >= k1l );
            elseif (otherSolutionType == "b1absequal") then
                return createConditionBoolean(false);
            end
        elseif (ourSolutionType == "b1abssuperior") then
            if (otherSolutionType == "b1abssuperior") or (otherSolutionType == "b1absmax") then
                local k1l = cond.solve();
                local k1b = otherCond.solve();
                
                output_math_debug( "SUPCHECK: " .. cond.toStringEQ .. " <= " .. otherCond.toStringEQ() );
                
                return createConditionBoolean( k1l <= k1b );
            elseif (otherSolutionType == "b1absequal") then
                return createConditionBoolean(false);
            end
        end
        
        output_math_debug( "DISAMB ERROR: " .. ourSolutionType .. " and " .. otherSolutionType );
        
        return false;
    end
    
    return cond;
end

-- 0 <= |a1|*k1 + |b1|*k2 + k3
function createConditionAbsoluteLinearInequalityLTEQ(k1, k2, k3)
    local cond = {};
    local is_always_true = false;
    
    if (k1 < 0) and (k2 < 0) and (k3 < 0) then
        k1 = 0;
        k2 = 0;
        k3 = 0;
    end
    
    if (k1 >= 0) and (k2 >= 0) and (k3 >= 0) then
        k1 = 0;
        k2 = 0;
        k3 = 0;
        is_always_true = true;
    end
    
    function cond.getSolutionType()
        if (k1 > 0) then
            return "a1absmin";
        elseif (k1 < 0) then
            return "a1absmax";
        elseif (k2 > 0) then
            return "b1absmin";
        elseif (k2 < 0) then
            return "b1absmax";
        else
            return "boolean";
        end
    end
    
    function cond.solve()
        if not (k1 == 0) then
            local c1 = (-k2)/k1;
            local c2 = (-k3)/k1;
            
            -- |a1| </>= c1*|b1| + c2
            return c1, c2;
        elseif not (k2 == 0) then
            local c1 = (-k3)/k2;
            
            -- |b1| </>= c1
            return c1;
        elseif (is_always_true) then
            return true;
        else
            return ( 0 <= k3 );
        end
    end
    
    function cond.toStringEQ()
        local solutionType = cond.getSolutionType();
        local c1, c2 = cond.solve();
        
        if (solutionType == "a1absmax") or (solutionType == "a1absmin") then
            return c1 .. "*|b1| + " .. c2;
        elseif (solutionType == "b1absmax") or (solutionType == "b1absmin") then
            return tostring( c1 );
        elseif (solutionType == "boolean") then
            return tostring( c1 );
        end
        
        return "unknown";
    end

    function cond.toString()
        local solutionType = cond.getSolutionType();
        
        if (solutionType == "a1absmax") then
            return "|a1| <= " .. cond.toStringEQ();
        elseif (solutionType == "a1absmin") then
            return "|a1| >= " .. cond.toStringEQ();
        elseif (solutionType == "b1absmax") then
            return "|b1| <= " .. cond.toStringEQ();
        elseif (solutionType == "b1absmin") then
            return "|b1| >= " .. cond.toStringEQ();
        elseif (solutionType == "boolean") then
            return tostring( cond.solve() );
        end
        
        return "unknown";
    end
    
    -- Returns a condition that is required to be valid exactly-when that condition is valid in comparison
    -- to given other condition.
    function cond.disambiguate(otherCond)
        local ourSolutionType = cond.getSolutionType();
        local otherSolutionType = otherCond.getSolutionType();
        
        if (ourSolutionType == "a1absmin") then
            if (otherSolutionType == "a1absmin") then
                local k1b, k2b = cond.solve();
                local k1l, k2l = otherCond.solve();
                
                output_math_debug( "SOLINF: " .. cond.toStringEQ() .. " >= " .. otherCond.toStringEQ() );
                
                return createConditionAbsoluteLinearInequalityLTEQ( 0, k1b - k1l, k2b - k2l );
            elseif (otherSolutionType == "a1absinferior") then
                local k1rb, k2rb = cond.solve();
                local k1rl, k2rl = otherCond.solve();
                
                output_math_debug( "SOLINF: " .. cond.toStringEQ() .. " > " .. otherCond.toStringEQ() );
                
                return createConditionAbsoluteLinearInequality( 0, k1rb - k1rl, k2rb - k2rl );
            elseif (otherSolutionType == "a1absequal") then
                return createConditionBoolean(false);
            end
        elseif (ourSolutionType == "a1absmax") then
            if (otherSolutionType == "a1absmax") then
                local k1l, k2l = cond.solve();
                local k1b, k2b = otherCond.solve();
                
                output_math_debug( "SOLSUP: " .. cond.toStringEQ() .. " <= " .. otherCond.toStringEQ() );
                
                return createConditionAbsoluteLinearInequalityLTEQ( 0, k1b - k1l, k2b - k2l );
            elseif (otherSolutionType == "a1abssuperior") then
                local k1rl, k2rl = cond.solve();
                local k1rb, k2rb = otherCond.solve();
                
                output_math_debug( "SOLSUP: " .. cond.toStringEQ() .. " < " .. otherCond.toStringEQ() );
                
                return createConditionAbsoluteLinearInequality( 0, k1rb - k1rl, k2rb - k2rl );
            elseif (otherSolutionType == "a1absequal") then
                return createConditionBoolean(false);
            end
        elseif (ourSolutionType == "b1absmin") then
            if (otherSolutionType == "b1absmin") then
                local k1b = cond.solve();
                local k1l = otherCond.solve();
                
                output_math_debug( "INFCHECK: " .. cond.toStringEQ() .. " >= " .. otherCond.toStringEQ() );
                
                return createConditionBoolean( k1b >= k1l );
            elseif (otherSolutionType == "b1absinferior") then
                local k1rb = cond.solve();
                local k1rl = otherCond.solve();
                
                output_math_debug( "INFCHECK: " .. cond.toStringEQ() .. " > " .. otherCond.toStringEQ() );
                
                return createConditionBoolean( k1rb > k1rl );
            elseif (otherSolutionType == "b1absequal") then
                return createConditionBoolean(false);
            end
        elseif (ourSolutionType == "b1absmax") then
            if (otherSolutionType == "b1absmax") then
                local k1l = cond.solve();
                local k1b = otherCond.solve();
                
                output_math_debug( "SUPCHECK: " .. cond.toStringEQ() .. " <= " .. otherCond.toStringEQ() );
                
                return createConditionBoolean( k1l <= k1b );
            elseif (otherSolutionType == "b1abssuperior") then
                local k1rl = cond.solve();
                local k1rb = otherCond.solve();
                
                output_math_debug( "SUPCHECK: " .. cond.toStringEQ() .. " < " .. otherCond.toStringEQ() );
                
                return createConditionBoolean( k1rl < k1rb );
            elseif (otherSolutionType == "b1absequal") then
                return createConditionBoolean(false);
            end
        end
        
        output_math_debug( "DISAMB ERROR: " .. ourSolutionType .. " and " .. otherSolutionType );
        
        return false;
    end
    
    return cond;
end

local function helperCreateConditionAbsoluteLinearInequalityCompareLTEQ( k1l, k2l, k3l, k4l, k1b, k2b, k3b, k4b )
    local c1 = (k4b*k1l - k4l*k1b);
    local c2 = (k4b*k2l - k4l*k2b);
    local c3 = (k4b*k3l - k4l*k3b);
    
    return createConditionAbsoluteLinearInequalityLTEQ( c1, c2, c3 );
end

-- c1 >= k4 / ( k1*|a1| + k2*|b1| + k3 )
function createConditionC1AbsoluteLowerBound(k1, k2, k3, k4)
    local cond = {};
    
    function cond.getSolutionType()
        return "c1min";
    end
    
    function cond.solve()
        return k1, k2, k3, k4;
    end
    
    function cond.toStringEQ()
        return "(" .. k4 .. ") / ( " .. k1 .. "*|a1| + " .. k2 .. "*|b1| + " .. k3 .. " )";
    end
    
    function cond.toString()
        return "c1 >= " .. cond.toStringEQ();
    end
    
    function cond.disambiguate(otherCond)
        local otherSolutionType = otherCond.getSolutionType();
        
        if (otherSolutionType == "c1min") then
            local mink1, mink2, mink3, mink4 = otherCond.solve();
            
            output_math_debug(
                "SOLINF: " .. cond.toStringEQ() .. " >= " .. otherCond.toStringEQ()
            );
            
            local infopt = helperCreateConditionAbsoluteLinearInequalityCompareLTEQ( mink1, mink2, mink3, mink4, k1, k2, k3, k4 );
            
            return infopt;
        elseif (otherSolutionType == "c1equality") then
            return createConditionBoolean(false);
        end
        
        return false;
    end
    
    return cond;
end

function createConditionC1AbsoluteUpperBound(k1, k2, k3, k4)
    local cond = {};
    
    function cond.getSolutionType()
        return "c1max";
    end
    
    function cond.solve()
        return k1, k2, k3, k4;
    end
    
    function cond.toStringEQ()
        return "(" .. k4 .. ") / ( " .. k1 .. "*|a1| + " .. k2 .. "*|b1| + " .. k3 .. " )";
    end
    
    function cond.toString()
        return "c1 <= " .. cond.toStringEQ();
    end
    
    function cond.disambiguate(otherCond)
        local otherSolutionType = otherCond.getSolutionType();
        
        if (otherSolutionType == "c1max") then
            local maxk1, maxk2, maxk3, maxk4 = otherCond.solve();
            
            output_math_debug(
                "SOLSUP: " .. cond.toStringEQ() .. " <= " .. otherCond.toStringEQ()
            );
            
            local supopt = helperCreateConditionAbsoluteLinearInequalityCompareLTEQ( k1, k2, k3, k4, maxk1, maxk2, maxk3, maxk4 );
            
            return supopt;
        elseif (otherSolutionType == "c1equality") then
            return createConditionBoolean(false);
        end
        
        return false;
    end
    
    return cond;
end

-- c1 = k4 / ( k1*|a1| + k2*|b1| + k3 )
function createConditionC1AbsoluteEquality(k1, k2, k3, k4)
    local cond = {};
    
    function cond.getSolutionType()
        return "c1equality";
    end
    
    function cond.solve()
        return k1, k2, k3, k4;
    end
    
    function cond.toStringEQ()
        return "(" .. k4 .. ") / ( " .. k1 .. "*|a1| + " .. k2 .. "*|b1| + " .. k3 .. " )";
    end
    
    function cond.toString()
        return "c1 = " .. cond.toStringEQ();
    end
    
    function cond.disambiguate(otherCond)
        local otherSolutionType = otherCond.getSolutionType();
        
        if (otherSolutionType == "c1min") then
            local mink1, mink2, mink3, mink4 = otherCond.solve();
            
            output_math_debug( "DISAMB: " .. cond.toStringEQ() .. " >= " .. otherCond.toStringEQ() );
            
            return helperCreateConditionAbsoluteLinearInequalityCompareLTEQ( mink1, mink2, mink3, mink4, k1, k2, k3, k4 );
        elseif (otherSolutionType == "c1max") then
            local maxk1, maxk2, maxk3, maxk4 = otherCond.solve();
            
            output_math_debug( "DISAMB: " .. cond.toStringEQ() .. " <= " .. otherCond.toStringEQ() );
            
            return helperCreateConditionAbsoluteLinearInequalityCompareLTEQ( k1, k2, k3, k4, maxk1, maxk2, maxk3, maxk4 );
        elseif (otherSolutionType == "c1equality") then
            -- Any same tight interval is good.
            return createConditionBoolean(true);
        end
        
        return false;
    end
    
    return cond;
end