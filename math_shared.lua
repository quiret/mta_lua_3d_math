-- Created by (c)The_GTA.
-- Optimizations.
local type = type;

-- We need math plane and a frustum.
-- Those are typically using vectors.
function createVector(x, y, z)
    local vec ={};
    
    function vec.getX()
        return x;
    end
    
    function vec.getY()
        return y;
    end
    
    function vec.getZ()
        return z;
    end
    
    function vec.setX(new_x)
        x = new_x;
    end
    
    function vec.setY(new_y)
        y = new_y;
    end
    
    function vec.setZ(new_z)
        z = new_z;
    end
    
    return vec;
end

function createPlane(pos, u, v)
    local plane = {};
    
    function plane.getPos()
        return pos;
    end
    
    function plane.getU()
        return u;
    end
    
    function plane.getV()
        return v;
    end
    
    function plane.setPos(new_pos)
        pos = new_pos;
    end
    
    function plane.setU(new_u)
        u = new_u;
    end
    
    function plane.setV(new_v)
        v = new_v;
    end
    
    return plane;
end

local function _helper_solveZero3DLinearInequalityCompareLTEQ( k1, k2, k3, k4, param )
    if (param == "pos") then
        return createConditionBoolean( k4 > 0 );
    elseif (param == "neg") then
        return createConditionBoolean( k4 < 0 );
    elseif (param == "unk") then
        if (k4 > 0) then
            return createCondition2DLinearInequalityLT( k1, k2, k3 );
        elseif (k4 < 0) then
            return createCondition2DLinearInequalityLT( -k1, -k2, -k3 );
        else
            math_assert( false, "unhandled case (" .. k4 .. ")", 2 );
        end
    end
    
    math_assert( false, "unknown param: " .. param );
    
    return false;
end

local function _helperCreateCondition3DLinearInequalityCompareLTEQ_pospos( k1l, k2l, k3l, k4l, k1b, k2b, k3b, k4b )
    local c1 = (k4b*k1l - k4l*k1b);
    local c2 = (k4b*k2l - k4l*k2b);
    local c3 = (k4b*k3l - k4l*k3b);
    
    return createCondition2DLinearInequalityLTEQ( c1, c2, c3 );
end

local function _helperCreateCondition3DLinearInequalityCompareLTEQ_posneg( k1l, k2l, k3l, k4l, k1b, k2b, k3b, k4b )
    local c1 = (k4l*k1b - k4b*k1l);
    local c2 = (k4l*k2b - k4b*k2l);
    local c3 = (k4l*k3b - k4b*k3l);
    
    return createCondition2DLinearInequalityLTEQ( c1, c2, c3 );
end

local function helperCreateCondition3DLinearInequalityCompareLTEQ( k1l, k2l, k3l, k4l, lparam, k1b, k2b, k3b, k4b, bparam )
    local k4l_zero = _math_eq(k4l, 0);
    local k4b_zero = _math_eq(k4b, 0);

    if (k4l_zero) and (k4b_zero) then
        return createConditionBoolean(true);
    elseif (k4l_zero) then
        return _helper_solveZero3DLinearInequalityCompareLTEQ( k1b, k2b, k3b, k4b, bparam );
    elseif (k4b_zero) then
        return _helper_solveZero3DLinearInequalityCompareLTEQ( k1l, k2l, k3l, -k4l, lparam );
    end

    if ((lparam == "pos") and (bparam == "pos")) or ((lparam == "neg") and (bparam == "neg")) then
        return _helperCreateCondition3DLinearInequalityCompareLTEQ_pospos( k1l, k2l, k3l, k4l, k1b, k2b, k3b, k4b );
    elseif ((lparam == "neg") and (bparam == "pos")) or ((lparam == "pos") and (bparam == "neg")) then
        return _helperCreateCondition3DLinearInequalityCompareLTEQ_posneg( k1l, k2l, k3l, k4l, k1b, k2b, k3b, k4b );
    elseif (lparam == "unk") then
        if (bparam == "pos") then
            local orCond = createConditionOR();
            
            local firstCase = createConditionAND();
            firstCase.addVar( createCondition2DLinearInequalityLT( k1l, k2l, k3l ) );
            firstCase.addVar( _helperCreateCondition3DLinearInequalityCompareLTEQ_pospos( k1l, k2l, k3l, k4l, k1b, k2b, k3b, k4b ) );
            
            local secondCase = createConditionAND();
            secondCase.addVar( createCondition2DLinearInequalityLT( -k1l, -k2l, -k3l ) );
            secondCase.addVar( _helperCreateCondition3DLinearInequalityCompareLTEQ_posneg( k1l, k2l, k3l, k4l, k1b, k2b, k3b, k4b ) );
            
            orCond.addVar( firstCase );
            orCond.addVar( secondCase );
            
            return orCond;
        elseif (bparam == "neg") then
            local orCond = createConditionOR();
            
            local firstCase = createConditionAND();
            firstCase.addVar( createCondition2DLinearInequalityLT( -k1l, -k2l, -k3l ) );
            firstCase.addVar( _helperCreateCondition3DLinearInequalityCompareLTEQ_pospos( k1l, k2l, k3l, k4l, k1b, k2b, k3b, k4b ) );
            
            local secondCase = createConditionAND();
            secondCase.addVar( createCondition2DLinearInequalityLT( k1l, k2l, k3l ) );
            secondCase.addVar( _helperCreateCondition3DLinearInequalityCompareLTEQ_posneg( k1l, k2l, k3l, k4l, k1b, k2b, k3b, k4b ) );
            
            orCond.addVar( firstCase );
            orCond.addVar( secondCase );
            
            return orCond;
        else
            math_assert( false, "unsupported bparam case: " .. bparam );
        end
    elseif (bparam == "unk") then
        if (lparam == "pos") then
            local orCond = createConditionOR();
            
            local firstCase = createConditionAND();
            firstCase.addVar( createCondition2DLinearInequalityLT( k1b, k2b, k3b ) );
            firstCase.addVar( _helperCreateCondition3DLinearInequalityCompareLTEQ_pospos( k1l, k2l, k3l, k4l, k1b, k2b, k3b, k4b ) );
            
            local secondCase = createConditionAND();
            secondCase.addVar( createCondition2DLinearInequalityLT( -k1b, -k2b, -k3b ) );
            secondCase.addVar( _helperCreateCondition3DLinearInequalityCompareLTEQ_posneg( k1l, k2l, k3l, k4l, k1b, k2b, k3b, k4b ) );
            
            orCond.addVar( firstCase );
            orCond.addVar( secondCase );
            
            return orCond;
        elseif (lparam == "neg") then
            local orCond = createConditionOR();
            
            local firstCase = createConditionAND();
            firstCase.addVar( createCondition2DLinearInequalityLT( -k1b, -k2b, -k3b ) );
            firstCase.addVar( _helperCreateCondition3DLinearInequalityCompareLTEQ_pospos( k1l, k2l, k3l, k4l, k1b, k2b, k3b, k4b ) );
            
            local secondCase = createConditionAND();
            secondCase.addVar( createCondition2DLinearInequalityLT( k1b, k2b, k3b ) );
            secondCase.addVar( _helperCreateCondition3DLinearInequalityCompareLTEQ_posneg( k1l, k2l, k3l, k4l, k1b, k2b, k3b, k4b ) );
            
            orCond.addVar( firstCase );
            orCond.addVar( secondCase );
            
            return orCond;
        else
            math_assert( false, "unsupported lparam case: " .. lparam );
        end
    else
        math_assert( false, "unsupported (lparam, bparam) combination: " .. lparam .. " and " .. bparam );
    end
end

-- c1 >= k4 / ( k1*a1 + k2*b1 + k3 )
function createConditionC13DLowerBound(k1, k2, k3, k4, parameter)
    assert( not (parameter == nil), "parameter is nil" );
    
    local cond = {};
    
    function cond.getSolutionType()
        return "c1min";
    end
    
    function cond.solve()
        return k1, k2, k3, k4, parameter;
    end
    
    function cond.toStringEQ()
        if (_math_eq(k4, 0)) then
            return "0";
        elseif (_math_eq(k1, 0)) and (_math_eq(k2, 0)) and (_math_eq(k3, 1)) then
            return tostring( k4 );
        end
        
        return "(" .. k4 .. ") / ( " .. mcs_multsum({k1, k2, k3}, {"a1", "b1"}) .. " ) [" .. tostring(parameter) .. "]";
    end
    
    function cond.toString()
        return "c1 >= " .. cond.toStringEQ();
    end
    
    function cond.disambiguate(otherCond, doPrintDebug)
        local otherSolutionType = otherCond.getSolutionType();
        
        if (otherSolutionType == "c1min") then
            local mink1, mink2, mink3, mink4, minparam = otherCond.solve();
            
            if (doPrintDebug) then
                output_math_debug(
                    "SOLINF: " .. cond.toStringEQ() .. " >= " .. otherCond.toStringEQ()
                );
            end
            
            local infopt = helperCreateCondition3DLinearInequalityCompareLTEQ( mink1, mink2, mink3, mink4, minparam, k1, k2, k3, k4, parameter );
            
            return infopt;
        elseif (otherSolutionType == "c1equality") then
            return createConditionBoolean(false);
        end
        
        math_assert( false, "DISAMB ERROR: c1min and " .. otherSolutionType );
        
        return false;
    end
    
    function cond.calcValidityUpper(otherCond, doPrintDebug)
        local otherSolutionType = otherCond.getSolutionType();
        
        if (otherSolutionType == "c1max") then
            local maxk1, maxk2, maxk3, maxk4, maxparam = otherCond.solve();
            
            if (doPrintDebug) then
                output_math_debug( "CALCVAL: " .. cond.toStringEQ() .. " <= " .. otherCond.toStringEQ() );
            end
            
            return helperCreateCondition3DLinearInequalityCompareLTEQ( k1, k2, k3, k4, parameter, maxk1, maxk2, maxk3, maxk4, maxparam );
        end
        
        math_assert( false, "CALCVAL ERROR: c1min and " .. otherSolutionType );
        
        return false;
    end
    
    return cond;
end

function createConditionC13DUpperBound(k1, k2, k3, k4, parameter)
    assert( not (parameter == nil), "parameter is nil" );
    
    local cond = {};
    
    function cond.getSolutionType()
        return "c1max";
    end
    
    function cond.solve()
        return k1, k2, k3, k4, parameter;
    end
    
    function cond.toStringEQ()
        if (_math_eq(k4, 0)) then
            return "0";
        elseif (_math_eq(k1, 0)) and (_math_eq(k2, 0)) and (_math_eq(k3, 1)) then
            return tostring( k4 );
        end
        
        return "(" .. k4 .. ") / ( " .. mcs_multsum({k1, k2, k3}, {"a1", "b1"}) .. " ) [" .. tostring(parameter) .. "]";
    end
    
    function cond.toString()
        return "c1 <= " .. cond.toStringEQ();
    end
    
    function cond.disambiguate(otherCond, doPrintDebug)
        local otherSolutionType = otherCond.getSolutionType();
        
        if (otherSolutionType == "c1max") then
            local maxk1, maxk2, maxk3, maxk4, maxparam = otherCond.solve();
            
            if (doPrintDebug) then
                output_math_debug(
                    "SOLSUP: " .. cond.toStringEQ() .. " <= " .. otherCond.toStringEQ()
                );
            end
            
            local supopt = helperCreateCondition3DLinearInequalityCompareLTEQ( k1, k2, k3, k4, parameter, maxk1, maxk2, maxk3, maxk4, maxparam );
            
            return supopt;
        elseif (otherSolutionType == "c1equality") then
            return createConditionBoolean(false);
        end
        
        math_assert( false, "DISAMB ERROR: c1max and " .. otherSolutionType );
        
        return false;
    end
    
    return cond;
end

-- c1 = k4 / ( k1*a1 + k2*b1 + k3 )
-- while c1 >= 0
function createConditionC13DEqualityNonNeg(k1, k2, k3, k4)
    local cond = {};
    local signtype_of_divisor = "unk";
    
    -- Optimization.
    if not (_math_eq(k4, 0)) then
        if (k4 > 0) then
            signtype_of_divisor = "pos";
        elseif (k4 < 0) then
            signtype_of_divisor = "neg";
        end
    end
    
    function cond.getSolutionType()
        return "c1equality";
    end
    
    function cond.solve()
        return k1, k2, k3, k4, signtype_of_divisor;
    end
    
    function cond.toStringEQ()
        if (_math_eq(k4, 0)) then
            return "0";
        elseif (_math_eq(k1, 0)) and (_math_eq(k2, 0)) and (_math_eq(k3, 1)) then
            return tostring( k4 );
        end
        
        return "(" .. k4 .. ") / ( " .. mcs_multsum({k1, k2, k3}, {"a1", "b1"}) .. " ) [" .. signtype_of_divisor .. "]";
    end
    
    function cond.toString()
        return "c1 = " .. cond.toStringEQ();
    end
    
    function cond.disambiguate(otherCond, doPrintDebug)
        local otherSolutionType = otherCond.getSolutionType();
        
        if (otherSolutionType == "c1min") then
            local mink1, mink2, mink3, mink4, minparam = otherCond.solve();
            
            if (doPrintDebug) then
                output_math_debug( "DISAMB: " .. cond.toStringEQ() .. " >= " .. otherCond.toStringEQ() );
            end
            
            return helperCreateCondition3DLinearInequalityCompareLTEQ( mink1, mink2, mink3, mink4, minparam, k1, k2, k3, k4, signtype_of_divisor );
        elseif (otherSolutionType == "c1max") then
            local maxk1, maxk2, maxk3, maxk4, maxparam = otherCond.solve();
            
            if (doPrintDebug) then
                output_math_debug( "DISAMB: " .. cond.toStringEQ() .. " <= " .. otherCond.toStringEQ() );
            end
            
            return helperCreateCondition3DLinearInequalityCompareLTEQ( k1, k2, k3, k4, signtype_of_divisor, maxk1, maxk2, maxk3, maxk4, maxparam );
        elseif (otherSolutionType == "c1equality") then
            local c1osk1, c1osk2, c1osk3, c1osk4 = otherCond.solve();
            
            local ak1 = (c1osk4*k1 - k4*c1osk1);
            local ak2 = (c1osk4*k2 - k4*c1osk2);
            local ak3 = (c1osk4*k3 - k4*c1osk3);
            
            if (doPrintDebug) then
                output_math_debug( "REDUCE: " .. cond.toStringEQ() .. " == " .. otherCond.toStringEQ() );
            end
            
            return createCondition2DLinearEquality( ak1, ak2, ak3 );
        end
        
        math_assert( false, "DISAMB ERROR: c1equality and " .. otherSolutionType );
        
        return false;
    end
    
    return cond;
end

-- Matrix is always useful.
local function det2(ux, uy, vx, vy)
    return (ux*vy - uy*vx);
end

local function matrix2inverse(det, px, py, ux, uy, vx, vy)
    if (det == 0) then
        outputDebugString("fatal error: determinant of inverse matrix cannot be 0");
        return false;
    end
    
    -- Expected: det == det2(ux, uy, vx, vy)
    
    -- Returns the equations:
    -- a1 = x * (vy/det) + y *(vx/(-det)) + det(p,v)/(-det)
    -- b1 = x * (uy/(-det)) + y * (ux/det) + det(p,u)/det
    
    local c1 = (vy/det);
    local c2 = (vx/(-det));
    local c3 = (det2(px,py,vx,vy)/(-det));
    local c4 = (uy/(-det));
    local c5 = (ux/det);
    local c6 = (det2(px,py,ux,uy)/det);
    
    return c1, c2, c3, c4, c5, c6;
end

local function disect_conditions(container, resconts, othercond, disectors)
    travel_and_line(container,
        function(n)
            local solutionType = n.getSolutionType();
            
            local was_added = false;
            
            for checkidx,checkcb in ipairs(disectors) do
                if (checkcb(solutionType)) then
                    table.insert(resconts[checkidx], resolve_cond(n));
                    
                    was_added = true;
                end
            end
            
            if not (was_added) and (othercond) then
                othercond.establishAND(resolve_cond(n));
            end
        end
    );
end

local function filter_conditions(container, resconts, othercond, obj_disectors)
    travel_and_line(container,
        function(n)
            local was_added = false;
            
            for checkidx,checkcb in ipairs(obj_disectors) do
                if (checkcb(n)) then
                    table.insert(resconts[checkidx], resolve_cond(n));
                    
                    was_added = true;
                end
            end
            
            if not (was_added) and (othercond) then
                othercond.establishAND(resolve_cond(n));
            end
        end
    );
end

local function has_condchain(cond)
    -- Determine if cond is actually a condchain (not what type of chain).
    local solutionType = cond.getSolutionType();
    
    return (solutionType == "and-dynamic") or (solutionType == "or-dynamic");
end

function for_all_andChains(condchain, cb, parent, parentIdx)
    local ourSolutionType = condchain.getSolutionType();
    
    local trav_children = false;
    
    local ret_strat = nil;
    
    if (ourSolutionType == "or-dynamic") then
        -- Just treat all the sub cases.
        trav_children = true;
        condchain = resolve_cond( condchain );
    elseif (ourSolutionType == "and-dynamic") then
        condchain = resolve_cond( condchain );
        
        local travType, userdata = cb(condchain, parent, parentIdx);
        
        if (travType == "continue") then
            trav_children = true;
        elseif (travType == "update-current") or (travType == "update-current-and-continue") then
            condchain = resolve_cond( userdata );
            
            if (parent) then
                parent.replaceVar(parentIdx, condchain);
                ret_strat = "parent-update";
            end
            
            if (travType == "update-current-and-continue") then
                trav_children = true;
            end
        end
    elseif (ourSolutionType == "boolean") then
        -- Just shorten out.
        return condchain;
    else
        math_assert( false, "invalid reduction chain type: " .. ourSolutionType .. " (" .. condchain.toString() .. ")", 2 );
    end
    
    if (trav_children) and (has_condchain(condchain)) then
        local idx = 1;
        local vars = condchain.getVars();
        
        while (idx <= #vars) do
            local var = vars[idx];
            local advance = true;
            
            if (has_condchain(var)) then
                local newVal, strat = for_all_andChains(var, cb, condchain, idx);
                
                if (strat == "parent-update") then
                    if (parent) then
                        parent.replaceVar(parentIdx, condchain);
                    end
                    
                    ret_strat = "parent-update";
                    
                    if (condchain.getChainType() == "none") then
                        condchain = resolve_cond(condchain);
                        break;
                    end
                end
                
                if (newVal.getSolutionType() == "boolean") then
                    advance = false;
                end
            end
            
            if (advance) then
                idx = idx + 1;
            end
        end
    end
    
    return condchain, ret_strat;
end
local for_all_andChains = for_all_andChains;

local function is_condobj_solvewise_same(left, right)
    if not (left.getSolutionType() == right.getSolutionType()) then
        return false;
    end
    
    local left_solve = { left.solve() };
    local right_solve = { right.solve() };
    
    if not (#left_solve == #right_solve) then
        return false;
    end
    
    for m,n in ipairs(left_solve) do
        if not (_math_eq(n, right_solve[m])) then
            return false;
        end
    end
    
    return true;
end

function calculateDisambiguationCondition(condlist, doPrintDebug)
    local disambs = {};
    
    for infsupidx,infsup in ipairs(condlist) do
        local has_left_double = false;
        
        for checkidx=1,infsupidx-1 do
            local checkitem = condlist[checkidx];
            
            if (is_condobj_solvewise_same(infsup, checkitem)) then
                has_left_double = true;
            end
        end
        
        if not (has_left_double) then
            local andItem = {};
            andItem.infsup = infsup;
            andItem.cond = createConditionAND(true);
            table.insert(disambs, andItem);
        else
            if (doPrintDebug) then
                output_math_debug( "terminated solvewise-double of " .. infsup.toString() );
            end
        end
    end
    
    if (#disambs > 1) then
        for _,infsup_and in ipairs(disambs) do
            local infsup = infsup_and.infsup;
            
            if (doPrintDebug) then
                output_math_debug( "CTX: " .. infsup.toString() );
            end
            
            for _,othercond_and in ipairs(disambs) do                        
                if not (infsup_and == othercond_and) then
                    local othercond = othercond_and.infsup;
                    local cond = infsup.disambiguate(othercond, doPrintDebug);
                    
                    if (doPrintDebug) then
                        output_math_debug( cond.toString() );
                    end
                    
                    infsup_and.cond.addVar(cond);
                end
            end
        end
    end
    
    return disambs;
end
local calculateDisambiguationCondition = calculateDisambiguationCondition;

function disambiguateBoundaryConditions(_condchain_try, is_lower_bound, is_upper_bound, hint_text, do_full_objcheck)
    return for_all_andChains(_condchain_try,
        function(condchain, parent, parentIdx)
            local lowers = {};
            local uppers = {};
            local otherconds = createConditionAND(true);

            if (do_full_objcheck) then
                filter_conditions( condchain, { lowers, uppers }, otherconds, { is_lower_bound, is_upper_bound } );
            else
                disect_conditions( condchain, { lowers, uppers }, otherconds, { is_lower_bound, is_upper_bound } );
            end
            
            if (#lowers > 1) or (#uppers > 1) then
               -- First simplify any other conditions that are below us.
                if (has_condchain(otherconds)) then
                    otherconds = disambiguateBoundaryConditions(otherconds, is_lower_bound, is_upper_bound, hint_text, do_full_objcheck);
                end
                
                if (hint_text) then
                    output_math_debug( "TARGET: " .. condchain.toString() );
                end
                
                local lowers_cond = false;
                
                local function debug_disamb_createCond(disamb)
                    local orCond = createConditionOR();
                    
                    for m,n in ipairs(disamb) do
                        local andItem = createConditionAND();
                        andItem.addVar(n.infsup);
                        andItem.establishAND(n.cond);
                        orCond.addVar(andItem);
                    end
                    
                    return orCond;
                end
                
                if (#lowers > 0) then
                    if (hint_text) and (#lowers > 1) then
                        output_math_debug( "CALCULATING " .. hint_text .. " LOWER BOUNDARIES (" .. #lowers .. "):" );
                    end
                    
                    lowers_cond = calculateDisambiguationCondition( lowers, hint_text );
                    
                    if (hint_text) and (#lowers > 1) then
                        output_math_debug( "RESULT: " .. debug_disamb_createCond(lowers_cond).toString() );
                    end
                end
                
                local uppers_cond = false;
                
                if (#uppers > 0) then
                    if (hint_text) and (#uppers > 1) then
                        output_math_debug( "CALCULATING " .. hint_text .. " UPPER BOUNDARIES (" .. #uppers .. "):" );
                    end
                    
                    uppers_cond = calculateDisambiguationCondition( uppers, hint_text );
                    
                    if (hint_text) and (#uppers > 1) then
                        output_math_debug( "RESULT: " .. debug_disamb_createCond(uppers_cond).toString() );
                    end
                end
                
                -- TODO: fix condition chain assignment by cloning the condition chain if it is inside a condition tree (and not the root).
                -- then replace the item instead of resetting the existing node (we pass a result).
                
                if (parent) then
                    condchain = createConditionAND();
                else
                    condchain.reset();
                end
                
                if (lowers_cond) and (uppers_cond) then
                    if (hint_text) then
                        output_math_debug( "COMBINING LOWERS AND UPPERS:" );
                    end
                    
                    local combinedCond = createConditionOR();
                    
                    for _,lower_info in ipairs(lowers_cond) do
                        for _,upper_info in ipairs(uppers_cond) do
                            local combItem = createConditionAND();
                            combItem.addVar(lower_info.infsup);
                            combItem.addVar(upper_info.infsup);
                            combItem.addVar(lower_info.cond);
                            combItem.addVar(upper_info.cond);
                            
                            if not (combItem.getSolutionType() == "boolean") then
                                local valCond = lower_info.infsup.calcValidityUpper(upper_info.infsup, hint_text);
                                
                                if (hint_text) then
                                    output_math_debug( valCond.toString() );
                                end
                                
                                combItem.addVar(valCond);
                            end
                            
                            combinedCond.addVar(combItem);
                        end
                    end
                    
                    if (hint_text) then
                        output_math_debug( "COMBINATION RESULT: " .. combinedCond.toString() );
                    end
                    
                    condchain.establishAND( combinedCond );
                else
                    local function subject_normal_disambSwitch(cond)
                        local orChain = createConditionOR();
                        
                        for m,n in ipairs(cond) do
                            n.cond.addVar(n.infsup);
                            orChain.addVar(n.cond);
                        end
                        
                        return orChain;
                    end
                    
                    if (lowers_cond) then
                        condchain.addVar( subject_normal_disambSwitch( lowers_cond ) );
                    end
                    
                    if (uppers_cond) then
                        condchain.addVar( subject_normal_disambSwitch( uppers_cond ) );
                    end
                    
                    if (hint_text) then
                        output_math_debug( "TO BE INSERTED: " .. condchain.toString() );
                    end
                end
                
                condchain.establishAND(otherconds);
                
                return "update-current", condchain;
            else
                return "continue";
            end
        end
    );
end
local disambiguateBoundaryConditions = disambiguateBoundaryConditions;

local function reduceConditions(condchain, is_reducible_cb, reduce_by, doPrintDebug, parent, parentIdx)
    -- TODO: tighten up the solidity of this runtime by actually going about the way it traverses the tree.
    
    condchain = resolve_cond(condchain);
    
    local condvars = condchain.getVars();
    
    local n = 1;
    
    local ret_strat = nil;
    
    local has_unique_chain = false;
    
    while ( n <= #condvars ) do
        local var = condvars[n];
        
        local solutionType = var.getSolutionType();
        
        if (solutionType == "and-dynamic") or (solutionType == "or-dynamic") then
            var = resolve_cond(var);
        
            local strat;
            var, strat = reduceConditions(var, is_reducible_cb, reduce_by, doPrintDebug, condchain, n);
            
            if (strat == "parent-update") then
                if (parent) then
                    parent.replaceVar(parentIdx, condchain);
                end
                
                ret_strat = "parent-update";
                
                if (condchain.getChainType() == "none") then
                    break;
                end
            end
            
            solutionType = var.getSolutionType();
        end
        
        local advance = true;
        
        var = resolve_cond(var);
        
        if (solutionType == "boolean") then
            advance = false;
        elseif not (var == reduce_by) and (is_reducible_cb(solutionType)) then
            local reduced = reduce_by.disambiguate(var, doPrintDebug);
            
            if (doPrintDebug) then
                output_math_debug( reduced.toString() );
            end
            
            if (parent) and not (has_unique_chain) then
                condchain = condchain.clone();
                condvars = condchain.getVars();
                
                has_unique_chain = true;
            end
            
            local resReplace = condchain.replaceVar( n, reduced );
            
            if (parent) then
                parent.replaceVar( parentIdx, condchain );
                ret_strat = "parent-update";
            end
            
            if (condchain.getChainType() == "none") then
                if (doPrintDebug) then
                    output_math_debug( "shortened out because simplification" );
                end
                
                break;
            end
            
            advance = ( resReplace == "ok" );
        end
        
        if ( advance ) then
            n = n + 1;
        end
    end
    
    return condchain, ret_strat;
end

function simplify_by_distinguished_condition(_condchain_try, is_cond_distinguished, is_cond_reducible, doPrintDebug)
    return for_all_andChains(_condchain_try,
        function(condchain, parent, parentIdx)
            local solution = false;
            local num_solutions = 0;
            
            travel_and_line(condchain,
                function(conditem)
                    local solutionType = conditem.getSolutionType();
                    
                    if (is_cond_distinguished(solutionType)) then
                        if not (solution) then
                            solution = resolve_cond( conditem );
                        end
                        
                        num_solutions = num_solutions + 1;
                    end
                end
            );
    
            if (solution) then
                if (doPrintDebug) then
                    output_math_debug( "found " .. num_solutions .. " distinguished conditions" );
                    output_math_debug( "TARGET: " .. condchain.toString() );
                end
                
                if (condchain.getSolutionType() == "and-dynamic") then
                    if (doPrintDebug) then
                        output_math_debug( "simplifying conditions by distinguished solution" );
                    end
                    
                    local strat;
                    condchain, strat = reduceConditions( condchain, is_cond_reducible, solution, doPrintDebug );
                    
                    if (doPrintDebug) then
                        output_math_debug( "simplified result: " .. condchain.toString() );
                    end
                else
                    if (doPrintDebug) then
                        output_math_debug( "shortened out because boolean-state" );
                    end
                end
                
                return "update-current", condchain;
            else
                return "continue";
            end
        end
    );
end
local simplify_by_distinguished_condition = simplify_by_distinguished_condition;

function smart_group_condition(cond, is_relevant_in_orCond, is_relevant_planarCond, hint_text)
    -- TODO: for each and-dynamic disect into relevant conditions (is_lower_bound, is_upper_bound combined) and 
    -- group them into a shared condition bubble; then look into this group to find the last and most-caseful or-dynamic.
    -- Execute establishAND on said last and most-caseful or-dynamic. If executed from the deepest
    -- or-dynamic leaves then all relevant or-dynamic items in the tree are fully laid out.
    return for_all_andChains(cond,
        function(condchain, parent, parentIdx)
            local orConds = {};
            local relevantConds = {};
            local otherconds = createConditionAND(true);
            
            local function is_relevant_condobj(subcond)
                return is_relevant_planarCond(subcond.getSolutionType());
            end
            
            local function is_relevant_or_dynamic(subcond)
                if not (subcond.getSolutionType() == "or-dynamic") then return false; end;
                
                subcond = resolve_cond(subcond);
                
                local is_whole_relevant = false;
                
                for_all_cases(subcond,
                    function(case)
                        travel_and_line(case,
                            function(caseitem)
                                local subSolutionType = caseitem.getSolutionType();
                                
                                local is_relevant_case = false;
                                
                                if (subSolutionType == "or-dynamic") then
                                    is_relevant_case = is_relevant_or_dynamic(caseitem);
                                else
                                    is_relevant_case = is_relevant_in_orCond(subSolutionType);
                                end
                                
                                if (is_relevant_case) then
                                    is_whole_relevant = true;
                                end
                            end
                        );
                    end
                );
                
                return is_whole_relevant;
            end
            
            filter_conditions(condchain, { orConds, relevantConds }, otherconds, { is_relevant_or_dynamic, is_relevant_condobj } );
            
            -- TODO: properly handle the local calculation result by pushing it down.
            
            if ( #orConds >= 1 ) then
                -- First we solve the problem for all sub-or-chains.
                -- NOTE that we group AND solve, while in the original idea we just grouped on sub-chains
                -- and did a complete solve on the resulting normal layout. It stands to be decided
                -- what the better approach is.
                
                -- Add all the normal conditions.
                local first_rel_orCond = orConds[1].clone();
                
                for m,n in ipairs(relevantConds) do
                    first_rel_orCond.establishAND(n);
                end
                
                orConds[1] = first_rel_orCond;
                
                for m,subcases in ipairs(orConds) do
                    orConds[m] = resolve_cond( smart_group_condition(subcases, is_relevant_in_orCond, is_relevant_planarCond, hint_text) );
                end
                
                if (hint_text) and (#orConds > 1) then
                    output_math_debug( "found multiple relevant cases in or-dynamic; smart-grouping..." );
                    output_math_debug( "TARGET: " .. condchain.toString() );
                end
                
                -- Now we assume that each child or-dynamic is layed out fully, by relevance.
                local most_caseful_and_last = false;
                local case_count;
                
                for m,n in ipairs(orConds) do
                    local vars = n.getVars();
                    
                    if (most_caseful_and_last == false) or (case_count <= #vars) then
                        most_caseful_and_last = n;
                        case_count = #vars;
                    end
                end
                
                -- Execute establishAND on it.
                local target_cond = most_caseful_and_last.clone();
                
                for m,n in ipairs(orConds) do
                    if not (n == most_caseful_and_last) then
                        if (hint_text) then
                            output_math_debug( "conjuncting [ " .. n.toString() .. " ] with [ " .. most_caseful_and_last.toString() .. " ]" );
                        end
                        target_cond.distributeAND(n);
                    end
                end
                
                if (hint_text) and (#orConds > 1) then
                    output_math_debug( "conjunction result: " .. target_cond.toString() );
                end
                
                -- Make the replacement condchain.
                if not (parent) then
                    condchain.reset();
                else
                    condchain = createConditionAND();
                end
                
                condchain.addVar(otherconds);
                condchain.establishAND(target_cond);
                
                if (hint_text) then
                    output_math_debug( "RESULT: " .. condchain.toString() );
                end
                
                return "update-current", condchain;
            else
                return "next";
            end
        end
    );
end
local smart_group_condition = smart_group_condition;

function createViewFrustum(pos, right, up, front)
    local frustum = {};
    
    function frustum.getPos()
        return pos;
    end
    
    function frustum.getRight()
        return right;
    end
    
    function frustum.getUp()
        return up;
    end
    
    function frustum.getFront()
        return front;
    end
    
    local function solveUniqueBoundaries(globalconds, doPrintDebug)
        if (doPrintDebug) then
            output_math_debug( "STEP 4: simplify the cut condition by finding equalities" );
            
            output_math_debug( "CUT CONDITION: " .. globalconds.toString() );
        end
        
        -- Let's first try to apply global simplifications.
        local function is_c1equality(solutionType)
            return solutionType == "c1equality";
        end
        
        -- Simplify by finding a global c1solution.
        if (doPrintDebug) then
            output_math_debug( "simplifying by c1equality" );
        end
        
        local function is_c1_equality(solutionType)
            return ( solutionType == "c1equality" );
        end
        
        local function is_c1_reducible(solutionType)
            return is_c1_equality(solutionType) or ( solutionType == "c1min" or solutionType == "c1max" );
        end
        
        globalconds = simplify_by_distinguished_condition( globalconds, is_c1_equality, is_c1_reducible, doPrintDebug );
        
        if (doPrintDebug) then
            output_math_debug( "simplifying by a1equal" );
        end
        
        local function is_a1_equality(solutionType)
            return ( solutionType == "a1equal" );
        end
        
        local function is_a1_reducible(solutionType)
            return is_a1_equality(solutionType) or ( solutionType == "a1min" ) or ( solutionType == "a1inferior" ) or ( solutionType == "a1max" ) or ( solutionType == "a1superior" );
        end
        
        globalconds = simplify_by_distinguished_condition( globalconds, is_a1_equality, is_a1_reducible, doPrintDebug );
        
        if (doPrintDebug) then
            output_math_debug( "simplifying by b1equal" );
        end
        
        local function is_b1_equality(solutionType)
            return ( solutionType == "b1equal" );
        end
        
        local function is_b1_reducible(solutionType)
            return is_b1_equality(solutionType) or ( solutionType == "b1min" ) or ( solutionType == "b1inferior" ) or ( solutionType == "b1max" ) or ( solutionType == "b1superior" );
        end
        
        globalconds = simplify_by_distinguished_condition( globalconds, is_b1_equality, is_b1_reducible, doPrintDebug );
        
        if (doPrintDebug) then
            output_math_debug( "STEP 5: calculate infima and suprema in the cut condition" );
        end
        
        -- The special plane condition handling is folded into the embedded "speciality" of c1min and c1max boundaries.
        -- Thus we can invoke a general dismbiguation algorithm based on upper and lower boundaries (inclusive and exclusive).
        local function is_b1_lower(solutionType)
            return ( solutionType == "b1min" ) or ( solutionType == "b1inferior" );
        end
        
        local function is_b1_upper(solutionType)
            return ( solutionType == "b1max" ) or ( solutionType == "b1superior" );
        end
        
        if (doPrintDebug) then
            output_math_debug( "simplifying condition by b1" );
        end
        
        globalconds = disambiguateBoundaryConditions(globalconds, is_b1_lower, is_b1_upper);
        
        if (doPrintDebug) then
            output_math_debug( "RESULT: " .. globalconds.toString() );
        end
        
        local function is_a1_const_lower(condobj)
            local solutionType = condobj.getSolutionType();
            
            if not (solutionType == "a1min") and not (solutionType == "a1inferior") then
                return false;
            end
            
            local c1, c2 = condobj.solve();
            
            if not (_math_eq(c1, 0)) then
                return false;
            end
            
            return true;
        end
        
        local function is_a1_const_upper(condobj)
            local solutionType = condobj.getSolutionType();
            
            if not (solutionType == "a1max") and not (solutionType == "a1superior") then
                return false;
            end
            
            local c1, c2 = condobj.solve();
            
            if not (_math_eq(c1, 0)) then
                return false;
            end
            
            return true;
        end
        
        if (doPrintDebug) then
            output_math_debug( "simplifying condition by const a1" );
        end
        
        globalconds = disambiguateBoundaryConditions(globalconds, is_a1_const_lower, is_a1_const_upper, nil, true);
        
        if (doPrintDebug) then
            output_math_debug( "RESULT: " .. globalconds.toString() );
        end
        
        local function is_c1_lower(solutionType)
            return ( solutionType == "c1min" );
        end
        
        local function is_c1_upper(solutionType)
            return ( solutionType == "c1max" );
        end
        
        local function is_a1_lower(solutionType)
            return ( solutionType == "a1min" ) or ( solutionType == "a1inferior" );
        end
        
        local function is_a1_upper(solutionType)
            return ( solutionType == "a1max" ) or ( solutionType == "a1superior" );
        end
        
        local function is_c1_bound_condition(solutionType)
            return is_c1_lower(solutionType) or is_c1_upper(solutionType);
        end
        
        local function is_c1_condition(solutionType)
            return is_c1_bound_condition(solutionType) or is_c1_equality(solutionType);
        end
        
        local function ternary(a, b, c)
            if (a) then
                return b;
            else
                return c;
            end
        end
        
        globalconds = smart_group_condition(globalconds, is_c1_condition, is_c1_bound_condition, ternary(doPrintDebug, "c1", false ));
        
        if (doPrintDebug) then
            output_math_debug( "GROUPED (c1): " .. globalconds.toString() );

            output_math_debug( "simplifying by c1equality" );
        end
        
        globalconds = simplify_by_distinguished_condition( globalconds, is_c1_equality, is_c1_reducible, doPrintDebug );
        
        if (doPrintDebug) then
            output_math_debug( "c1equality RESULT: " .. globalconds.toString() );
        end
        
        globalconds = disambiguateBoundaryConditions(globalconds, is_c1_lower, is_c1_upper, ternary(doPrintDebug, "c1", false ));
        
        if (doPrintDebug) then
            output_math_debug( "C1 RESULT: " .. globalconds.toString() );
        end
        
        local function is_a1_bound_condition(solutionType)
            return is_a1_lower(solutionType) or is_a1_upper(solutionType);
        end
        
        local function is_a1_condition(solutionType)
            return is_a1_bound_condition(solutionType) or is_a1_equality(solutionType);
        end
        
        globalconds = smart_group_condition(globalconds, is_a1_condition, is_a1_bound_condition, ternary(doPrintDebug, "a1", false));
        
        if (doPrintDebug) then
            output_math_debug( "GROUPED (a1): " .. globalconds.toString() );
        end
        
        if (doPrintDebug) then
            output_math_debug( "simplifying by a1equal" );
        end
        
        globalconds = simplify_by_distinguished_condition( globalconds, is_a1_equality, is_a1_reducible, doPrintDebug );
        
        if (doPrintDebug) then
            output_math_debug( "a1equal RESULT: " .. globalconds.toString() );
        end
        
        globalconds = disambiguateBoundaryConditions(globalconds, is_a1_lower, is_a1_upper, ternary(doPrintDebug, "a1", false));
        
        if (doPrintDebug) then
            output_math_debug( "A1 RESULT: " .. globalconds.toString() );
        end
        
        local function is_b1_bound_condition(solutionType)
            return is_b1_lower(solutionType) or is_b1_upper(solutionType);
        end
        
        local function is_b1_condition(solutionType)
            return is_b1_bound_condition(solutionType) or is_b1_equality(solutionType);
        end
        
        globalconds = smart_group_condition(globalconds, is_b1_condition, is_b1_bound_condition, ternary(doPrintDebug, "b1", false));
        
        if (doPrintDebug) then
            output_math_debug( "GROUPED (b1): " .. globalconds.toString() );

            output_math_debug( "simplifying by b1equal" );
        end
        
        globalconds = simplify_by_distinguished_condition( globalconds, is_b1_equality, is_b1_reducible, doPrintDebug );
        
        if (doPrintDebug) then
            output_math_debug( "b1equal RESULT: " .. globalconds.toString() );
        
            output_math_debug( "calculating b1 tight intervals" );
        end
        
        globalconds = disambiguateBoundaryConditions(globalconds, is_b1_lower, is_b1_upper);
        
        if (doPrintDebug) then
            output_math_debug( "B1 RESULT: " .. globalconds.toString() );
        end
        
        -- TODO: implement a removeVar method for and-dynamic and or-dynamic so that we can safely pick conditions
        -- out of a tree to later put it into a special transformed object.
        
        local function layout_all_cases(_condchain_try)
            return for_all_andChains(_condchain_try,
                function(condchain, parent, parentIdx)
                    local orConds = {};
                    local otherconds = createConditionAND(true);
                    
                    local function is_or_dynamic(solutionType)
                        return ( solutionType == "or-dynamic" );
                    end
                    
                    disect_conditions(condchain, { orConds }, otherconds, { is_or_dynamic } );
                    
                    if ( #orConds >= 1 ) then
                        -- First we update all child or-dynamics.
                        for _,orChild in ipairs(orConds) do
                            for m,n in ipairs(orChild.getVars()) do
                                if (has_condchain(n)) then
                                    local layed_out = layout_all_cases(n);
                                    orChild.replaceVar(m, layed_out);
                                end
                            end
                        end
                        
                        -- We just want to clobber together.
                        target_or = orConds[1].clone();
                        
                        for m=2,#orConds do
                            target_or.distributeAND(orConds[m]);
                        end
                        
                        target_or.distributeAND(otherconds);
                        
                        return "update-current", target_or;
                    else
                        return "next";
                    end
                end
            );
        end
        
        if (globalconds.getSolutionType() == "boolean") then
            if (doPrintDebug) then
                output_math_debug( "no intersection." );
            end
        
            -- If there is a boolean result then we failed to intersect.
            return false;
        end
        
        globalconds = layout_all_cases(globalconds);
        
        if (doPrintDebug) then
            output_math_debug( "NORMAL: " .. globalconds.toString() );
        
            output_math_debug( "returning math result in machine structure" );
        end
        
        -- We expect cut_cond to come in OR normal-form.
        local cut_cond = globalconds;
        
        -- Create the final intersection information struct.
        local inter = {};
        
        for_all_cases(cut_cond,
            function(cutcase)
                local c1lower = false;
                local c1upper = false;
                local a1lower = false;
                local a1upper = false;
                local b1lower = false;
                local b1upper = false;
                
                if (doPrintDebug) then
                    output_math_debug( "CASE: " .. cutcase.toString() );
                end
                
                travel_and_line(cutcase,
                    function(cutitem)
                        cutitem = resolve_cond(cutitem);
                        
                        local solutionType = cutitem.getSolutionType();
                        
                        if (doPrintDebug) then
                            output_math_debug( "CTX: " .. cutitem.toString() .. " [" .. solutionType .. "]" );
                        end
                        
                        if (is_c1_lower(solutionType)) then
                            math_assert( c1lower == false, "ambiguous c1lower" );
                            
                            c1lower = cutitem;
                        elseif (is_c1_upper(solutionType)) then
                            math_assert( c1upper == false, "ambiguous c1upper" );
                            
                            c1upper = cutitem;
                        elseif (is_c1_equality(solutionType)) then
                            math_assert( (c1lower == false) and (c1upper == false), "ambiguous c1equality" );
        
                            c1lower = cutitem;
                            c1upper = cutitem;
                        elseif (is_a1_lower(solutionType)) then
                            math_assert( a1lower == false, "ambiguous a1lower" );
                            
                            a1lower = cutitem;
                        elseif (is_a1_upper(solutionType)) then
                            math_assert( a1upper == false, "ambiguous a1upper" );
                            
                            a1upper = cutitem;
                        elseif (is_a1_equality(solutionType)) then
                            math_assert( (a1lower == false) and (a1upper == false), "ambiguous a1equal" );
                            
                            a1lower = cutitem;
                            a1upper = cutitem;
                        elseif (is_b1_lower(solutionType)) then
                            math_assert( b1lower == false, "ambiguous b1lower" );
                            
                            b1lower = cutitem;
                        elseif (is_b1_upper(solutionType)) then
                            math_assert( b1upper == false, "ambiguous b1upper" );
                            
                            b1upper = cutitem;
                        elseif (is_b1_equality(solutionType)) then
                            math_assert( (b1lower == false) and (b1upper == false), "ambiguous b1equal" );
                            
                            b1lower = cutitem;
                            b1upper = cutitem;
                        end
                    end
                );
                
                math_assert( c1upper, "no c1upper" );
                math_assert( c1lower, "no c1lower" );
                math_assert( a1upper, "no a1upper" );
                math_assert( a1lower, "no a1lower" );
                math_assert( b1upper, "no b1upper" );
                math_assert( b1lower, "no b1lower" );
                
                local item = {};
                item.c1lower = { c1lower.solve() };
                item.c1upper = { c1upper.solve() };
                item.a1lower = { a1lower.solve() };
                item.a1upper = { a1upper.solve() };
                item.b1lower = b1lower.solve();
                item.b1upper = b1upper.solve();
                table.insert( inter, item );
            end
        );
        
        return inter;
    end
    
    local function solveLinearFrustumPlaneTranslation(plane, globalconds, doPrintDebug)
        -- Cache parameters.
        local p2 = plane.getPos();
        local u2 = plane.getU();
        local v2 = plane.getV();
        
        local p2x = p2.getX();
        local p2y = p2.getY();
        local p2z = p2.getZ();
        
        local u2x = u2.getX();
        local u2y = u2.getY();
        local u2z = u2.getZ();
        
        local v2x = v2.getX();
        local v2y = v2.getY();
        local v2z = v2.getZ();
        
        local p1x = pos.getX();
        local p1y = pos.getY();
        local p1z = pos.getZ();
        
        local u1x = right.getX();
        local u1y = right.getY();
        local u1z = right.getZ();
        
        local v1x = up.getX();
        local v1y = up.getY();
        local v1z = up.getZ();
        
        local w1x = front.getX();
        local w1y = front.getY();
        local w1z = front.getZ();
        
        -- TODO: improve the structure of this solver by specializing for the structure of frustum solutions more.
        
        local function make_frustum_cond_string(k1, k2, k3, k4)
            return mcs_multsum({k1, k2, k3, k4}, {false, "a1*c1", "b1*c1", "c1"});
        end
        
        -- First all cross conditions.
        local a2solutions = {};
        local b2solutions = {};
        
        local function solveCrossCondition(p2a, p2b, u2a, u2b, v2a, v2b, p1a, p1b, u1a, u1b, v1a, v1b, w1a, w1b)
            local det = det2(u2a, u2b, v2a, v2b);
            
            if not (det == 0) then
                local c1, c2, c3, c4, c5, c6 = matrix2inverse( det, p2a, p2b, u2a, u2b, v2a, v2b );
                
                local a2c1 = (c1*p1a + c2*p1b + c3);
                local a2c2 = (c1*u1a + c2*u1b);
                local a2c3 = (c1*v1a + c2*v1b);
                local a2c4 = (c1*w1a + c2*w1b);
                
                local b2c1 = (c4*p1a + c5*p1b + c6);
                local b2c2 = (c4*u1a + c5*u1b);
                local b2c3 = (c4*v1a + c5*v1b);
                local b2c4 = (c4*w1a + c5*w1b);
                
                if (doPrintDebug) then
                    output_math_debug( "a2 = " .. make_frustum_cond_string( a2c1, a2c2, a2c3, a2c4 ) );
                    output_math_debug( "b2 = " .. make_frustum_cond_string( b2c1, b2c2, b2c3, b2c4 ) );
                end
                
                local a2solution = {};
                a2solution.c1 = a2c1;
                a2solution.c2 = a2c2;
                a2solution.c3 = a2c3;
                a2solution.c4 = a2c4;
                
                table.insert( a2solutions, a2solution );
                
                local b2solution = {};
                b2solution.c1 = b2c1;
                b2solution.c2 = b2c2;
                b2solution.c3 = b2c3;
                b2solution.c4 = b2c4;
                
                table.insert( b2solutions, b2solution );
                
                if (doPrintDebug) then
                    output_math_debug( "is a cross condition for (a2, b2)" );
                end
            end
        end
        
        solveCrossCondition(p2x, p2y, u2x, u2y, v2x, v2y, p1x, p1y, u1x, u1y, v1x, v1y, w1x, w1y);
        solveCrossCondition(p2x, p2z, u2x, u2z, v2x, v2z, p1x, p1z, u1x, u1z, v1x, v1z, w1x, w1z);
        solveCrossCondition(p2y, p2z, u2y, u2z, v2y, v2z, p1y, p1z, u1y, u1z, v1y, v1z, w1y, w1z);
        
        -- 0 = k1*a1*c1 + k2*b1*c1 + k3*c1 + k4
        local function solveNonLinearDepthConditionEQ(k1, k2, k3, k4)
            local orCond = createConditionOR();
            
            if (_math_eq(k4, 0)) then
                orCond.addVar( createCondition2DLinearEquality( k1, k2, k3 ) );
            end

            do
                local sub_andCond = createConditionAND();
                
                --sub_andCond.addVar( createCondition2DLinearInequalityNEQ( k1, k2, k3 ) ); encapsulation of != 0
                sub_andCond.addVar( createConditionC13DEqualityNonNeg( k1, k2, k3, -k4 ) );
                
                orCond.addVar( sub_andCond );
            end
            
            if (doPrintDebug) then
                output_math_debug( orCond.toString() );
            end
            
            globalconds.addVar( orCond );
            
            if (doPrintDebug) then
                output_math_debug( "found direct condition" );
            end
        end
        
        local function solveDirectFrustumCondition(p2a, u2a, v2a, p1a, u1a, v1a, w1a)
            if (_math_eq(u2a, 0)) and (_math_eq(v2a, 0)) then
                solveNonLinearDepthConditionEQ(u1a, v1a, w1a, p1a - p2a);
            end
        end
        
        solveDirectFrustumCondition(p2x, u2x, v2x, p1x, u1x, v1x, w1x);
        solveDirectFrustumCondition(p2y, u2y, v2y, p1y, u1y, v1y, w1y);
        solveDirectFrustumCondition(p2z, u2z, v2z, p1z, u1z, v1z, w1z);
        
        if (doPrintDebug) then
            output_math_debug( "STEP 2: disambiguate the plane coordinate solutions" );
        end
        
        if (#a2solutions == 0) then return false; end;
        if (#b2solutions == 0) then return false; end;
        
        local function reduceFrustumSolutions(sk1, sk2, sk3, sk4, osk1, osk2, osk3, osk4)
            local k1 = (osk1 - sk1);
            local k2 = (osk2 - sk2);
            local k3 = (osk3 - sk3);
            local k4 = (osk4 - sk4);
            
            solveNonLinearDepthConditionEQ( k1, k2, k3, k4 );
        end
        
        local a2solution = a2solutions[1];
        
        if (#a2solutions > 1) then
            if (doPrintDebug) then
                output_math_debug( "disambiguing a2" );
            end
            
            for n=2,#a2solutions do
                local a2othersolution = a2solutions[n];
                
                reduceFrustumSolutions( a2solution.c2, a2solution.c3, a2solution.c4, a2solution.c1, a2othersolution.c2, a2othersolution.c3, a2othersolution.c4, a2othersolution.c1 );
            end
        end
        
        local b2solution = b2solutions[1];
        
        if (#b2solutions > 1) then
            if (doPrintDebug) then
                output_math_debug( "disambiguing b2" );
            end
            
            for n=2,#b2solutions do
                local b2othersolution = b2solutions[n];
                
                reduceFrustumSolutions( b2solution.c2, b2solution.c3, b2solution.c4, b2solution.c1, b2othersolution.c2, b2othersolution.c3, b2othersolution.c4, b2othersolution.c1 );
            end
        end
        
        if (doPrintDebug) then
            output_math_debug( "STEP 3: generate all frustum conditions stemming from the two plane conditions" );
        end
        
        return a2solution, b2solution;
    end
    
    function frustum.intersectWithPlane(plane, doPrintDebug)
        if (doPrintDebug) then
            output_math_debug( "STEP 1: find all plane equations in frustum coordinates, as well as any direct frustum conditions" );
        end
        
        local globalconds = createConditionAND();

        do
            local a2solution, b2solution = solveLinearFrustumPlaneTranslation(plane, globalconds, doPrintDebug);
            
            if not (a2solution) then
                return false;
            end
            
            -- SPECIALIZED SOLUTION FOR PLANE-CUT.
            local function solveNonLinearDepthConditionInterval(k1, k2, k3, k4)
                local orCond = createConditionOR();
                
                if (_math_geq(k4, 0)) and (_math_geq(1 - k4, 0)) then
                    orCond.addVar( createCondition2DLinearEquality( k1, k2, k3 ) );
                end
                
                do
                    local sub_andCond = createConditionAND();
                    
                    sub_andCond.addVar( createCondition2DLinearInequalityLT( k1, k2, k3 ) );
                    sub_andCond.addVar( createConditionC13DLowerBound( k1, k2, k3, -k4, "pos" ) );
                    sub_andCond.addVar( createConditionC13DUpperBound( k1, k2, k3, 1 - k4, "pos" ) );
                    
                    orCond.addVar( sub_andCond );
                end
                
                do
                    local sub_andCond = createConditionAND();
                    
                    sub_andCond.addVar( createCondition2DLinearInequalityLT( -k1, -k2, -k3 ) );
                    sub_andCond.addVar( createConditionC13DLowerBound( k1, k2, k3, 1 - k4, "neg" ) );
                    sub_andCond.addVar( createConditionC13DUpperBound( k1, k2, k3, - k4, "neg" ) );
                    
                    orCond.addVar( sub_andCond );
                end
                
                if (doPrintDebug) then
                    output_math_debug( orCond.toString() );
                end
                
                globalconds.addVar( orCond );
            end
            
            -- 0 <= a2 <= 1:
            solveNonLinearDepthConditionInterval( a2solution.c2, a2solution.c3, a2solution.c4, a2solution.c1 );
            
            -- 0 <= b2 <= 1:
            solveNonLinearDepthConditionInterval( b2solution.c2, b2solution.c3, b2solution.c4, b2solution.c1 );
        end
        
        -- Collection of the default frustum bounds.
        -- c1 >= 0
        globalconds.establishAND(createConditionC13DLowerBound( 0, 0, 1, 0, "pos" ));
        -- c1 <= 1
        globalconds.establishAND( createConditionC13DUpperBound( 0, 0, 1, 1, "pos" ) );
        -- a1 >= -1
        globalconds.establishAND( createCondition2DLinearInequalityLTEQ( 1, 0, 1 ) );
        -- a1 <= 1
        globalconds.establishAND( createCondition2DLinearInequalityLTEQ( -1, 0, 1 ) );
        -- b1 >= -1
        globalconds.establishAND( createCondition2DLinearInequalityLTEQ( 0, 1, 1 ) );
        -- b1 <= 1
        globalconds.establishAND( createCondition2DLinearInequalityLTEQ( 0, -1, 1 ) );
        
        return solveUniqueBoundaries(globalconds, doPrintDebug);
    end
    
    function frustum.intersectWithTrianglePlane(plane, doPrintDebug)
        if (doPrintDebug) then
            output_math_debug( "STEP 1: find all plane equations in frustum coordinates, as well as any direct frustum conditions" );
        end
        
        local globalconds = createConditionAND();

        do
            local a2solution, b2solution = solveLinearFrustumPlaneTranslation(plane, globalconds, doPrintDebug);
            
            if not (a2solution) then
                return false;
            end
            
            -- SPECIALIZED SOLUTION FOR TRIANGLE-CUT.
            local function solveNonLinearDepthConditionLTEQ(k1, k2, k3, k4)
                local orCond = createConditionOR();
                
                if (_math_eq(k4, 0)) then
                    orCond.addVar(createConditionC13DEqualityNonNeg(0, 0, 1, 0));
                    orCond.addVar(createCondition2DLinearInequalityLTEQ(k1, k2, k3));
                else
                    if (k4 > 0) then
                        orCond.addVar(createCondition2DLinearEquality(k1, k2, k3));
                    end
                
                    do
                        local sub_cond = createConditionAND();
                        
                        sub_cond.addVar(createCondition2DLinearInequalityLT(k1, k2, k3));
                        sub_cond.addVar(createConditionC13DLowerBound(k1, k2, k3, -k4, "pos"));
                        
                        orCond.addVar(sub_cond);
                    end
                    
                    do
                        local sub_cond = createConditionAND();
                        
                        sub_cond.addVar(createCondition2DLinearInequalityLT(-k1, -k2, -k3));
                        sub_cond.addVar(createConditionC13DUpperBound(k1, k2, k3, -k4, "neg"));
                        
                        orCond.addVar(sub_cond);
                    end
                end
                    
                if (doPrintDebug) then
                    output_math_debug(orCond.toString());
                end
                
                globalconds.establishAND(orCond);
                
                return orCond;
            end
            
            -- 0 <= a2:
            solveNonLinearDepthConditionLTEQ( a2solution.c2, a2solution.c3, a2solution.c4, a2solution.c1 );
            
            -- 0 <= b2:
            solveNonLinearDepthConditionLTEQ( b2solution.c2, b2solution.c3, b2solution.c4, b2solution.c1 );
            
            -- a2 + b2 <= 1:
            solveNonLinearDepthConditionLTEQ(
                -a2solution.c2 - b2solution.c2,
                -a2solution.c3 - b2solution.c3,
                -a2solution.c4 - b2solution.c4,
                -a2solution.c1 - b2solution.c1 + 1
            );
        end
        
        -- Collection of the default frustum bounds.
        -- c1 >= 0
        globalconds.establishAND(createConditionC13DLowerBound( 0, 0, 1, 0, "pos" ));
        -- c1 <= 1
        globalconds.establishAND( createConditionC13DUpperBound( 0, 0, 1, 1, "pos" ) );
        -- a1 >= -1
        globalconds.establishAND( createCondition2DLinearInequalityLTEQ( 1, 0, 1 ) );
        -- a1 <= 1
        globalconds.establishAND( createCondition2DLinearInequalityLTEQ( -1, 0, 1 ) );
        -- b1 >= -1
        globalconds.establishAND( createCondition2DLinearInequalityLTEQ( 0, 1, 1 ) );
        -- b1 <= 1
        globalconds.establishAND( createCondition2DLinearInequalityLTEQ( 0, -1, 1 ) );
        
        return solveUniqueBoundaries(globalconds, doPrintDebug);
    end
    
    return frustum;
end