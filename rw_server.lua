-- Created by (c)The_GTA.
-- TEST:
local dffname = "gfriend.dff";
local clumpStream = fileOpen(dffname);

if not (clumpStream) then
    outputDebugString( "failed to open " .. dffname );
    return;
end

local dff, err = rwReadClump(clumpStream);

fileClose(clumpStream);

if not (dff) then
    if (err) then
        outputDebugString( "DFF LOAD ERROR: " .. err );
    else
        outputDebugString( "unknown DFF load error" );
    end
elseif (false) then
    local num_frames = #dff.framelist.frames;
    
    outputDebugString( "num frames: " .. num_frames );
    
    local geom = dff.geomlist[1];
    local mt = geom.morphTargets[1];
    
    outputDebugString( "radius: " .. geom.morphTargets[1].sphere.r );
    outputDebugString( "x: " .. mt.sphere.x .. ", y: " .. mt.sphere.y .. ", z: " .. mt.sphere.z );
end