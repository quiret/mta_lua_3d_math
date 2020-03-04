local function task_draw_current_scene(thread, tri_pos_x, tri_pos_y, tri_pos_z, tri_u_x, tri_u_y, tri_u_z, tri_v_x, tri_v_y, tri_v_z,
        frustum_pos_x, frustum_pos_y, frustum_pos_z, frustum_right_x, frustum_right_y, frustum_right_z,
        frustum_up_x, frustum_up_y, frustum_up_z, frustum_front_x, frustum_front_y, frustum_front_z)
    
    -- Write the triangle into a file on the server for debug purposes.
    do
        local trifile = "debug_tri_draw.lua";
        local tricode =
            "local triangle = createPlane(\n" ..
            "    createVector(" .. tri_pos_x .. ", " .. tri_pos_y .. ", " .. tri_pos_z .. "),\n" ..
            "    createVector(" .. tri_u_x .. ", " .. tri_u_y .. ", " .. tri_u_z .. "),\n" ..
            "    createVector(" .. tri_v_x .. ", " .. tri_v_y .. ", " .. tri_v_z .. ")\n" ..
            ");\n" ..
            "local frustum = createViewFrustum(\n" ..
            "    createVector(" .. frustum_pos_x .. ", " .. frustum_pos_y .. ", " .. frustum_pos_z .. "),\n" ..
            "    createVector(" .. frustum_right_x .. ", " .. frustum_right_y .. ", " .. frustum_right_z .. "),\n" ..
            "    createVector(" .. frustum_up_x .. ", " .. frustum_up_y .. ", " .. frustum_up_z .. "),\n" ..
            "    createVector(" .. frustum_front_x .. ", " .. frustum_front_y .. ", " .. frustum_front_z .. ")\n" ..
            ");\n" ..
            "local primType = \"tri\";";
        
        if (fileExists(trifile)) then
            fileDelete(trifile);
        end
        
        local debugFile = fileCreate(trifile);
        
        if (debugFile) then
            fileWrite(debugFile, tricode);
            fileClose(debugFile);
        end
    end
    
    local triangle = createPlane(
        createVector(tri_pos_x, tri_pos_y, tri_pos_z),
        createVector(tri_u_x, tri_u_y, tri_u_z),
        createVector(tri_v_x, tri_v_y, tri_v_z)
    );
    
    local frustum = createViewFrustum(
        createVector(frustum_pos_x, frustum_pos_y, frustum_pos_z),
        createVector(frustum_right_x, frustum_right_y, frustum_right_z),
        createVector(frustum_up_x, frustum_up_y, frustum_up_z),
        createVector(frustum_front_x, frustum_front_y, frustum_front_z)
    );
    
    local bbuf = create_backbuffer(640, 480, 255, 255, 0, 50);
    local dbuf = createDepthBuffer(640, 480, 1);
    
    local time_start = getTickCount();
    
    do
        local gotToDraw, numDrawn, numSkipped = draw_plane_on_bbuf(frustum, bbuf, dbuf, triangle, true, "tri", true);
        
        if ( gotToDraw ) then
            outputDebugString( "drawn " .. numDrawn .. " pixels (skipped " .. numSkipped .. ")" );
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

addEvent("request_drawtri", true);
addEventHandler("request_drawtri", root,
    function(tri_pos_x, tri_pos_y, tri_pos_z, tri_u_x, tri_u_y, tri_u_z, tri_v_x, tri_v_y, tri_v_z,
            frustum_pos_x, frustum_pos_y, frustum_pos_z,
            frustum_right_x, frustum_right_y, frustum_right_z,
            frustum_up_x, frustum_up_y, frustum_up_z,
            frustum_front_x, frustum_front_y, frustum_front_z)
        
        spawnTask(task_draw_current_scene, tri_pos_x, tri_pos_y, tri_pos_z, tri_u_x, tri_u_y, tri_u_z, tri_v_x, tri_v_y, tri_v_z,
            frustum_pos_x, frustum_pos_y, frustum_pos_z,
            frustum_right_x, frustum_right_y, frustum_right_z,
            frustum_up_x, frustum_up_y, frustum_up_z,
            frustum_front_x, frustum_front_y, frustum_front_z
        );
    end
);