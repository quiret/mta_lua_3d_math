-- Possibly paste code from "debug_tri_draw.lua" here.
-- PASTE BEGIN.
local triangle = createPlane(
    createVector(0, 0, 5),
    createVector(25, 0, 0),
    createVector(0, 0, 15)
);
local frustum = createViewFrustum(
    createVector(3, -26, 3),
    createVector(34, 559, 0),
    createVector(124, -7, 327),
    createVector(-746, 45, 285)
);
local primType = "tri";
-- PASTE END.

local function task_draw_test_scene(thread)
    local bbuf = create_backbuffer(640, 480, 255, 255, 0, 50);
    local dbuf = createDepthBuffer(640, 480, 1);
    
    local time_start = getTickCount();
    
    do
        local gotToDraw, numDrawn, numSkipped, maxPixels = draw_plane_on_bbuf(frustum, bbuf, dbuf, triangle, true, primType, true);
        
        if ( gotToDraw ) then
            outputDebugString( "intersection successful (drawcnt: " .. numDrawn .. ", skipcnt: " .. numSkipped .. ", max: " .. maxPixels .. ")" );
        else
            outputDebugString( "failed intersection" );
        end
    end
    
    local time_end = getTickCount();
    local ms_diff = ( time_end - time_start );
    
    outputDebugString( "render time: " .. ms_diff .. "ms" );
    
    taskUpdate( 1, "creating backbuffer color composition string" );
    
    local bbuf_width_ushort = num_to_ushort_bytes( bbuf.width );
    local bbuf_height_ushort = num_to_ushort_bytes( bbuf.height );
    
    local pixels_str = table.concat(bbuf.items);
    
    local bbuf_string =
        pixels_str ..
        ( bbuf_width_ushort ..
        bbuf_height_ushort );
        
    taskUpdate( false, "sending backbuffer to clients (render time: " .. ms_diff .. "ms)" );
        
    local players = getElementsByType("player");
    
    for m,n in ipairs(players) do
        triggerClientEvent(n, "onServerTransmitImage", root, bbuf_string);
    end
    
    outputDebugString("sent backbuffer to clients");
end

addCommandHandler("debugdraw",
    function()
        spawnTask(task_draw_test_scene);
    end
);