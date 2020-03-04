-- Optimizations.
local math = math;
local mabs = math.abs;
local mfloor = math.floor;
local type = type;
local ipairs = ipairs;
local tostring = tostring;
local _G = _G;

-- There is a long history of CPU's not accurately implementing floating-point mathematics.
-- In the end you could only trust the "<" and ">" operators to be accurate.
-- That is why these functions were used.
local _epsilon = 0.000001;

local function _math_leq(a, b)
    return ( a - _epsilon <= b );
end
_G._math_leq = _math_leq;

local function _math_geq(a, b)
    return ( a + _epsilon >= b );
end
_G._math_geq = _math_geq;

local function _math_eq(a, b)
    if (type(a) == "number") and (type(b) == "number") then    
        local absdiff = mabs(a - b);
        
        return ( absdiff < _epsilon );
    end
    
    return ( a == b );
end
_G._math_eq = _math_eq;

local function mcs_multsum(values, names)
    local multsumstr = "";
    local was_all_zero = true;
    
    for m,n in ipairs(values) do
        local addpart = "";
        
        if not (n == 0) then
            if not ( n == 1 ) and not ( n == -1 ) then
                if ( n < 0 ) or not ( n == mfloor(n) ) then
                    addpart = "(" .. n .. ")";
                else
                    addpart = tostring( n );
                end
            elseif ( n == -1 ) then
                addpart = "-";
            elseif ( n == 1 ) then
                addpart = "";
            end
            
            local theName = names[m];
            
            if (theName) then
                if not ( addpart == "" ) and not ( addpart == "-") then
                    addpart = addpart .. "*";
                end
                
                addpart = addpart .. theName;
            elseif (addpart == "") then
                addpart = "1";
            elseif (addpart == "-") then
                addpart = "(-1)";
            end
        end
        
        if not (addpart == "") then
            was_all_zero = false;
            
            if not (multsumstr == "") then
                multsumstr = multsumstr .. " + ";
            end
            
            multsumstr = multsumstr .. addpart;
        end
    end
    
    if (was_all_zero) then
        return "0";
    end
    
    return multsumstr;
end
_G.mcs_multsum = mcs_multsum;

local cfg_output_trivial_calc = false;

-- MATH DEBUG: create a file where we output all stuff of calculation.
if (fileExists( "math_debug.txt")) then
    fileDelete( "math_debug.txt" );
end

local debug_file = false;

local function stop_handler()
    if (debug_file) then
        fileFlush(debug_file);
        fileClose(debug_file);
    end
end

if ( localplayer ) then
    addEventHandler( "onClientResourceStop", root, stop_handler );
else
    addEventHandler( "onResourceStop", root, stop_handler );
end

local function output_math_debug(str)
    if not (debug_file) then
        debug_file = fileCreate( "math_debug.txt" );
    end
    
    if (debug_file) then
        fileWrite(debug_file, str .. "\n");
        fileFlush(debug_file);
    end
    
    --outputDebugString( str );
    --outputConsole( "#" .. str );
end
_G.output_math_debug = output_math_debug;

local function math_assert(cond, string, error_stack_off)
    if not (cond) then
        output_math_debug(string);
    end
    
    if not (cond) then
        if not (error_stack_off) then
            error_stack_off = 1;
        end
        
        error( string, error_stack_off + 1 )
    end
end
_G.math_assert = math_assert;