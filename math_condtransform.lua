-- Optimizations.
local ipairs = ipairs;
local table = table;
local tinsert = table.insert;
local error = error;

-- Global imports.
local travel_and_line = travel_and_line;
local for_all_cases = for_all_cases;
local createConditionOR = createConditionOR;
local createConditionAND = createConditionAND;
local output_math_debug = output_math_debug;
local resolve_cond = resolve_cond;
local _math_eq = _math_eq;
local _math_geq = _math_geq;
local _math_leq = _math_leq;

if not (travel_and_line) or not (for_all_cases) or not (createConditionOR) or
   not (createConditionAND) or not (output_math_debug) or
   not (resolve_cond) or not (_math_eq) or not (_math_geq) or
   not (_math_leq) then
   
   error("failed global import of dependencies; fatal script error.");
end

local function disect_conditions(container, resconts, othercond, disectors)
    travel_and_line(container,
        function(n)
            local solutionType = n.getSolutionType();
            
            local was_added = false;
            
            for checkidx,checkcb in ipairs(disectors) do
                if (checkcb(solutionType)) then
                    tinsert(resconts[checkidx], resolve_cond(n));
                    
                    was_added = true;
                end
            end
            
            if not (was_added) and (othercond) then
                othercond.establishAND(resolve_cond(n));
            end
        end
    );
end
_G.disect_conditions = disect_conditions;

local function filter_conditions(container, resconts, othercond, obj_disectors)
    travel_and_line(container,
        function(n)
            local was_added = false;
            
            for checkidx,checkcb in ipairs(obj_disectors) do
                if (checkcb(n)) then
                    tinsert(resconts[checkidx], resolve_cond(n));
                    
                    was_added = true;
                end
            end
            
            if not (was_added) and (othercond) then
                othercond.establishAND(resolve_cond(n));
            end
        end
    );
end
_G.filter_conditions = filter_conditions;

local function has_condchain(cond)
    -- Determine if cond is actually a condchain (not what type of chain).
    local solutionType = cond.getSolutionType();
    
    return (solutionType == "and-dynamic") or (solutionType == "or-dynamic");
end
_G.has_condchain = has_condchain;

local for_all_andChains = nil;

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
_G.for_all_andChains = for_all_andChains;

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

local function calculateDisambiguationCondition(condlist, doPrintDebug)
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
            tinsert(disambs, andItem);
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
_G.calculateDisambiguationCondition = calculateDisambiguationCondition;

local function disambiguateBoundaryConditions(_condchain_try, is_lower_bound, is_upper_bound, hint_text, do_full_objcheck)
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
_G.disambiguateBoundaryConditions = disambiguateBoundaryConditions;

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

local function simplify_by_distinguished_condition(_condchain_try, is_cond_distinguished, is_cond_reducible, doPrintDebug)
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
_G.simplify_by_distinguished_condition = simplify_by_distinguished_condition;

local function smart_group_condition(cond, is_relevant_in_orCond, is_relevant_planarCond, hint_text)
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
_G.smart_group_condition = smart_group_condition;