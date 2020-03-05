-- Created by (c)The_GTA.
local output_debug_of_compare = false;

local function fpe(a, b)
    -- After all, the FPU is not made to be accurate.
    return math.abs(a - b) < 0.001;
end

local function fpe_quot4(a1, a2, a3, a4, b1, b2, b3, b4)
    if ( _math_eq(a4, 0) ) then
        return _math_eq(b4, 0);
    elseif ( _math_eq(b4, 0) ) then
        return _math_eq(a4, 0);
    end
    
    local d1a = a1/a4;
    local d2a = a2/a4;
    local d3a = a3/a4;
    
    local d1b = b1/b4;
    local d2b = b2/b4;
    local d3b = b3/b4;
    
    return fpe(d1a, d1b) and fpe(d2a, d2b) and fpe(d3a, d3b);
end

local function find_inter_result(
        inter,
        b1lower, b1upper,
        a1lowerk1, a1lowerk2, a1upperk1, a1upperk2,
        c1lowerk1, c1lowerk2, c1lowerk3, c1lowerk4, c1upperk1, c1upperk2, c1upperk3, c1upperk4
    )
    
    local found = false;
    
    for m,n in ipairs(inter) do
        if (output_debug_of_compare) then
            print(
                "(" .. b1lower .. ", " .. b1upper .. ") = (" .. n.b1lower .. ", " .. n.b1upper .. "), " ..
                "(" .. a1lowerk1 .. ", " .. a1lowerk2 .. ", " .. a1upperk1 .. ", " .. a1upperk2 .. ") = (" .. n.a1lower[1] .. ", " .. n.a1lower[2] .. ", " .. n.a1upper[1] .. ", " .. n.a1upper[2] .. "), " ..
                "(" .. c1lowerk1 .. ", " .. c1lowerk2 .. ", " .. c1lowerk3 .. ", " .. c1lowerk4 .. ", " .. c1upperk1 .. ", " .. c1upperk2 .. ", " .. c1upperk3 .. ", " .. c1upperk4 .. ") = (" .. 
                n.c1lower[1] .. ", " .. n.c1lower[2] .. ", " .. n.c1lower[3] .. ", " .. n.c1lower[4] .. ", " .. n.c1upper[1] .. ", " .. n.c1upper[2] .. ", " .. n.c1upper[3] .. ", " .. n.c1upper[4] .. ")"
            );
        end
        
        if (fpe(n.b1lower, b1lower)) and (fpe(n.b1upper, b1upper)) and
          (fpe(n.a1lower[1], a1lowerk1)) and (fpe(n.a1lower[2], a1lowerk2)) and
          (fpe(n.a1upper[1], a1upperk1)) and (fpe(n.a1upper[2], a1upperk2)) and
          (fpe_quot4( n.c1lower[1], n.c1lower[2], n.c1lower[3], n.c1lower[4], c1lowerk1, c1lowerk2, c1lowerk3, c1lowerk4 )) and
          (fpe_quot4( n.c1upper[1], n.c1upper[2], n.c1upper[3], n.c1upper[4], c1upperk1, c1upperk2, c1upperk3, c1upperk4 )) then
        
            found = true;
            break;
        end
    end
    
    if not ( found ) then
        error( "unit test fail", 2 );
    end

    if (output_debug_of_compare) then
        outputConsole("found");
    end
end

local function frustum_unit_test()
    -- All those unit tests are verified math on paper.
    if (true) then
        -- 3D frustum-plane non-linear intersection - example #6
        -- https://1drv.ms/u/s!Ao_bx9imD7B8hJ4U2BiAV2LY5lnkxA?e=cgvN1R
        local plane = createPlane(
            createVector( -2, 0, 2 ),
            createVector( 4, 0, 0 ),
            createVector( 0, 6, 0 )
        );
        
        local frustum = createViewFrustum(
            createVector( 0, 0, 0 ),
            createVector( 4, 0, 0 ),
            createVector( 0, 0, 4 ),
            createVector( 0, 8, 0 )
        );
        
        local inter = frustum.intersectWithPlane( plane, false );
        
        assert( #inter >= 3 );
        
        find_inter_result(
            inter,
            2/3, 1,
            0, 0, 0, 0,
            0, 4, 0, 2, 0, 4, 0, 2
        );
        find_inter_result(
            inter,
            2/3, 1,
            0, 0, 1, 0,
            0, 4, 0, 2, 0, 4, 0, 2
        );
        find_inter_result(
            inter,
            2/3, 1,
            -1, 0, 0, 0,
            0, 4, 0, 2, 0, 4, 0, 2
        );
    end
    
    if (true) then
        -- 3D frustum plane non-linear intersection - example #7
        -- https://1drv.ms/u/s!Ao_bx9imD7B8hJ4V1XdLo8fGTa5MXw?e=FEezxh
        local plane = createPlane(
            createVector(-3, 2, -3),
            createVector(4, 0, 0),
            createVector(0, 1, 4)
        );
        
        local frustum = createViewFrustum(
            createVector(0, 0, 0),
            createVector(4, 0, 0),
            createVector(0, 0, 5),
            createVector(0, 10, 0)
        );
        
        local inter = frustum.intersectWithPlane( plane, false );
        
        assert( #inter >= 4 );
        
        find_inter_result(
            inter,
            -1, 2/3,
            0, 0, 0, 0,
            0, 5/4, -10, -11/4, 0, 5/4, -10, -11/4
        );
        find_inter_result(
            inter,
            -1, -4/5,
            0, 0, 0, 1,
            0, 5/4, -10, -11/4, 0, 5/4, -10, -11/4
        );
        find_inter_result(
            inter,
            -4/5, 2/3,
            0, 0, -5/44, 10/11,
            0, 5/4, -10, -11/4, 0, 5/4, -10, -11/4
        );
        find_inter_result(
            inter,
            -1, 2/3,
            0, -1, 0, 0,
            0, 5/4, -10, -11/4, 0, 5/4, -10, -11/4
        );
    end
    
    if (true) then
        -- 3D frustum-plane non-linear intersection - example #8
        -- https://1drv.ms/u/s!Ao_bx9imD7B8hJ4WfvqXobUac3GoGA?e=fytPRS
        local plane = createPlane(
            createVector(-2, 8, -2),
            createVector(1, 1, 0),
            createVector(0, 1, 1)
        );
        
        local frustum = createViewFrustum(
            createVector(0, 0, 0),
            createVector(6, 0, 0),
            createVector(0, 0, 8),
            createVector(0, 10, 0)
        );
        
        local inter = frustum.intersectWithPlane( plane );
        
        find_inter_result(
            inter,
            -15/54, -15/108,
            8/30, -1/3, 4/33, -5/33,
            6, 8, -10, -12, 6, 8, -10, -12
        );
        find_inter_result(
            inter,
            -15/48, -15/54,
            8/30, -1/3, 20/3, 5/3,
            6, 8, -10, -12, 6, 8, -10, -12
        );
        find_inter_result(
            inter,
            -1/8, -1/8,
            44/3, 5/3, -4/3, -1/3,
            6, 8, -10, -12, 6, 8, -10, -12
        );
        find_inter_result(
            inter,
            -15/108, -1/8,
            44/3, 5/3, 4/33, -5/33,
            6, 8, -10, -12, 6, 8, -10, -12
        );
        
        -- Performance test.
        if (false) then
            for n=1,100 do
                frustum.intersectWithPlane( plane, false );
            end
        end
    end
    
    if (true) then
        -- 3D frustum-triangle non-linear intersection - example #1
        -- https://1drv.ms/u/s!Ao_bx9imD7B8hJ4TCbQ49eP2IDD7Sw?e=WYWd3t
        local plane = createPlane(
            createVector(-2, 6, -1),
            createVector(4, 0, 0),
            createVector(0, 0, 2)
        );
        
        local frustum = createViewFrustum(
            createVector(0, 0, 0),
            createVector(6, 0, 0),
            createVector(0, 0, 5),
            createVector(0, 15, 0)
        );
        
        local inter = frustum.intersectWithTrianglePlane(plane);
        
        find_inter_result(
            inter,
            -1/2, 0,
            0, 0, -5/3, 0,
            0, 0, 15, 6, 0, 0, 15, 6
        );
        find_inter_result(
            inter,
            -1/2, 0,
            0, -5/6, 0, 0,
            0, 0, 15, 6, 0, 0, 15, 6
        );
        find_inter_result(
            inter,
            0, 1/2,
            0, -5/6, -5/3, 0,
           0, 0, 15, 6, 0, 0, 15, 6
        );
    end
    
    if (true) then
        -- 3D frustum-plane non-linear intesection - example #9
        -- https://1drv.ms/u/s!Ao_bx9imD7B8hJ4SjRRGgkCfvrTfPg?e=Uw36JF
        local plane = createPlane(
            createVector(3, 4, 3),
            createVector(1, 0, 0),
            createVector(0, 0, 1)
        );
        
        local frustum = createViewFrustum(
            createVector(0, 0, 0),
            createVector(4, 0, 0),
            createVector(0, 0, 3),
            createVector(0, 8, 0)
        );
        
        local inter = frustum.intersectWithPlane(plane);
        
        assert( inter == false );
    end
end

frustum_unit_test();

local function output_unit_test(str)
    outputDebugString(str);
end

local function tools_unit_test()
    local function is_relevant_a1_cond(solutionType)
        return ( solutionType == "a1equal" ) or
                  ( solutionType == "a1min" ) or
                  ( solutionType == "a1inferior" ) or 
                  ( solutionType == "a1max" ) or
                  ( solutionType == "a1superior" );
    end    

    do
        local chain = createConditionAND();
        
        chain.addVar(createCondition2DLinearInequalityLTEQ(1, 0, 1));
        chain.addVar(createCondition2DLinearInequalityLTEQ(-1, 0, 1));
        
        local sub_or1 = createConditionOR();
        
        sub_or1.addVar(createCondition2DLinearInequalityLTEQ(1, 0, 2));
        sub_or1.addVar(createCondition2DLinearInequalityLTEQ(-1, 0, 2));
        
        chain.addVar(sub_or1);
        
        local sub_or2 = createConditionOR();
        
        sub_or2.addVar(createCondition2DLinearInequalityLTEQ(1, 0, 3));
        sub_or2.addVar(createCondition2DLinearInequalityLTEQ(-1, 0, 3));
        
        chain.addVar(sub_or2);
        
        chain = smart_group_condition(chain, is_relevant_a1_cond, is_relevant_a1_cond);
        
        assert( chain.toString() == "( ( a1 >= (-3) AND a1 >= (-2) AND a1 >= (-1) AND a1 <= 1 ) OR ( a1 >= (-3) AND a1 <= 2 AND a1 >= (-1) AND a1 <= 1 ) OR ( a1 <= 3 AND a1 >= (-2) AND a1 >= (-1) AND a1 <= 1 ) OR ( a1 <= 3 AND a1 <= 2 AND a1 >= (-1) AND a1 <= 1 ) )" );
    end
    
    do
        local chain = createConditionAND();
        
        chain.addVar(createCondition2DLinearInequalityLTEQ(1, 0, 1));
        chain.addVar(createCondition2DLinearInequalityLTEQ(-1, 0, 1));
        
        local sub_or = createConditionOR();
        
        do
            local first_cond = createConditionAND();
            
            first_cond.addVar(createCondition2DLinearInequalityLTEQ(1, 0, 2));
            first_cond.addVar(createCondition2DLinearInequalityLTEQ(-1, 0, 2));
            
            local subsub_or = createConditionOR();
            
            subsub_or.addVar(createCondition2DLinearInequalityLTEQ(1, 0, 3));
            subsub_or.addVar(createCondition2DLinearInequalityLTEQ(-1, 0, 3));
            
            first_cond.addVar(subsub_or);
            sub_or.addVar(first_cond);
        end
        
        do
            local second_cond = createConditionAND();
            
            second_cond.addVar(createCondition2DLinearInequalityLTEQ(1, 0, 4));
            second_cond.addVar(createCondition2DLinearInequalityLTEQ(-1, 0, 5));
            
            sub_or.addVar(second_cond);
        end
        
        chain.addVar(sub_or);
        
        chain = smart_group_condition(chain, is_relevant_a1_cond, is_relevant_a1_cond);
        
        -- assert...
    end
    
    do
        local chain = createConditionAND();
        
        chain.addVar(createCondition2DLinearInequalityLTEQ(1, 0, 1));
        chain.addVar(createCondition2DLinearInequalityLTEQ(-1, 0, 1));
        chain.addVar(createCondition2DLinearInequalityLTEQ(0, 1, 1));
        chain.addVar(createCondition2DLinearInequalityLTEQ(0, -1, 1));
        
        do
            local orCond = createConditionOR();
            
            do
                local andCond = createConditionAND();
                
                andCond.addVar(createConditionC13DLowerBoundNonNeg(0, 0, 1, 0, "pos"));
                andCond.addVar(createConditionC13DUpperBoundNonNeg(0, 0, 1, 1, "pos"));
                andCond.addVar(createCondition2DLinearEquality(1, 0, 0));
                andCond.addVar(createCondition2DLinearEquality(0, -1, 2/3));
                
                orCond.addVar(andCond);
            end
            
            do
                local andCond = createConditionAND();
                
                andCond.addVar(createCondition2DLinearEquality(1, 0, 0));
                andCond.addVar(createConditionC13DEqualityNonNeg(0, 0, 1, 0));
                
                orCond.addVar(andCond);
            end
            
            do
                local sub_andCond = createConditionAND();
                
                do
                    local sub_orCond = createConditionOR();
                
                    do
                        local subsub_andCond = createConditionAND();
                        
                        subsub_andCond.addVar(createConditionC13DLowerBoundNonNeg(0, 0, 1, 0, "pos"));
                        subsub_andCond.addVar(createConditionC13DUpperBoundNonNeg(3/2, 0, 0, 1/2, "pos"));
                        subsub_andCond.addVar(createCondition2DLinearInequalityLTEQ(1, 0, -1/3));
                        
                        sub_orCond.addVar(subsub_andCond);
                    end
                    
                    do
                        local subsub_andCond = createConditionAND();
                        
                        subsub_andCond.addVar(createConditionC13DLowerBoundNonNeg(0, 0, 1, 0, "pos"));
                        subsub_andCond.addVar(createConditionC13DUpperBoundNonNeg(0, 0, 1, 1, "pos"));
                        subsub_andCond.addVar(createCondition2DLinearInequalityLTEQ(-1, 0, 1/3));
                        
                        sub_orCond.addVar(subsub_andCond);
                    end
                    
                    sub_andCond.addVar(sub_orCond);
                end
                
                sub_andCond.addVar(createCondition2DLinearInequalityLT(1, 0, 0));
                sub_andCond.addVar(createCondition2DLinearEquality(0, -1, 2/3));
                
                orCond.addVar(sub_andCond);
            end
            
            do
                local sub_andCond = createConditionAND();
                
                sub_andCond.addVar(createCondition2DLinearInequalityLT(1, 0, 0));
                sub_andCond.addVar(createConditionC13DEqualityNonNeg(0, 0, 1, 0));
                
                orCond.addVar(sub_andCond);
            end
            
            do
                local sub_andCond = createConditionAND();
                
                do
                    local sub_orCond = createConditionOR();
                    
                    do
                        local subsub_andCond = createConditionAND();
                        
                        subsub_andCond.addVar(createConditionC13DLowerBoundNonNeg(0, 0, 1, 0, "pos"));
                        subsub_andCond.addVar(createConditionC13DUpperBoundNonNeg(3/2, 0, 0, -1/2, "neg"));
                        subsub_andCond.addVar(createCondition2DLinearInequalityLTEQ(-1, 0, -1/3));
                        
                        sub_orCond.addVar(subsub_andCond);
                    end
                    
                    do
                        local subsub_andCond = createConditionAND();
                        
                        subsub_andCond.addVar(createConditionC13DLowerBoundNonNeg(0, 0, 1, 0, "pos"));
                        subsub_andCond.addVar(createConditionC13DUpperBoundNonNeg(0, 0, 1, 1, "pos"));
                        subsub_andCond.addVar(createCondition2DLinearInequalityLTEQ(1, 0, 1/3));
                        
                        sub_orCond.addVar(subsub_andCond);
                    end
                    
                    sub_andCond.addVar(sub_orCond);
                end
                
                sub_andCond.addVar(createCondition2DLinearInequalityLT(-1, 0, 0));
                sub_andCond.addVar(createCondition2DLinearEquality(0, 1, -2/3));
                
                orCond.addVar(sub_andCond);
            end
            
            do
                local sub_andCond = createConditionAND();
                
                sub_andCond.addVar(createCondition2DLinearInequalityLT(-1, 0, 0));
                sub_andCond.addVar(createConditionC13DEqualityNonNeg(0, 0, 1, 0));
                
                orCond.addVar(sub_andCond);
            end
            
            chain.addVar(orCond);
        end
        
        chain = smart_group_condition(chain, is_relevant_a1_cond, is_relevant_a1_cond);
        
        -- assert...
    end
end

tools_unit_test();