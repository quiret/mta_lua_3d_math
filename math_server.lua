-- Created by (c)The_GTA.
-- TODO: draw some image and send it to the requesting client.
local do_print_math_debug = false;

local viewFrustum = createViewFrustum(
    createVector(0, 0, 3),
    createVector(5, 0, 0),
    createVector(0, 0, 5),
    createVector(0, 20, 0)
);

local test_planes = {
    createPlane(
        createVector(-2, 0, -2),
        createVector(4, 0, 0),
        createVector(0, 20, 4)
    ),
    createPlane(
        createVector(-2, 25, -2),
        createVector(4, 0, 0),
        createVector(0, -14, 10)
    ),
    createPlane(
        createVector(-2, 0, -6),
        createVector(0, 20, 0),
        createVector(0, 0, 20)
    ),
    createPlane(
        createVector(2, 0, -6),
        createVector(0, 20, 0),
        createVector(0, 0, 20)
    )
};

-- Created by The_GTA. If you use this please mention my name somewhere.
-- Script to create a render buffer out of a scene.
local string = string;

local function clamp_color(val)
    val = math.floor(val);
    
    if (val >= 255) then
        return 255;
    end
    
    if (val <= 0) then
        return 0;
    end
    
    return val;
end

local function to_color_item(a, r, g, b)
    return string.char(clamp_color(b)) .. string.char(clamp_color(g)) .. string.char(clamp_color(r)) .. string.char(clamp_color(a));
end

local function color_idx(x, y, width)
    return ( ( y * width ) + x ) + 1;
end

-- Creates a backbuffer which is a string of bytes that can have certain dimensions.
-- Can be merged using table.concat to be fed to texture engines.
local function create_backbuffer( width, height, alphaClear, redClear, greenClear, blueClear )
    local bbuf = {};
    local items = {};
    
    local clear_color = to_color_item(alphaClear, redClear, greenClear, blueClear);
    
    for y=0,height-1,1 do
        for x=0,width-1,1 do
            local color_idx = color_idx(x, y, width);
        
            items[color_idx] = clear_color;
        end
    end
    
    bbuf.width = width;
    bbuf.height = height;
    bbuf.items = items;
    
    return bbuf;
end
_G.create_backbuffer = create_backbuffer;

-- Create a depth buffer, storing depth values of screen pixels.
local function createDepthBuffer( width, height, clearValue )
    local dbuf = {};
    local items = {};
    
    for y=0,height-1,1 do
        for x=0,width-1,1 do
            local color_idx = color_idx(x, y, width);
        
            items[color_idx] = clearValue;
        end
    end
    
    dbuf.width = width;
    dbuf.height = height;
    dbuf.items = items;
    
    return dbuf;
end
_G.createDepthBuffer = createDepthBuffer;

-- Sets the color of a single pixel on the backbuffer, if possible.
local function set_pixel_on_bbuf(bbuf, xpos, ypos, alpha, red, green, blue)
    local width = bbuf.width;
    local height = bbuf.height;
    
    local ypos_int = math.floor(ypos);
    
    if ( ypos_int < 0 ) or ( ypos_int >= height ) then
        return false;
    end
    
    local xpos_int = math.floor(xpos);
    
    if ( xpos_int < 0 ) or ( xpos_int >= width ) then
        return false;
    end
    
    local cidx = color_idx(xpos_int, ypos_int, width);
    
    bbuf.items[cidx] = to_color_item(alpha, red, green, blue);
    return true;
end

local function browse_depth(dbuf, xpos, ypos)
    local width = dbuf.width;
    local height = dbuf.height;
    
    local ypos_int = math.floor(ypos);
    
    if ( ypos_int < 0 ) or ( ypos_int >= height ) then
        return 1;
    end
    
    local xpos_int = math.floor(xpos);
    
    if ( xpos_int < 0 ) or ( xpos_int >= width ) then
        return 1;
    end
    
    local cidx = color_idx(xpos_int, ypos_int, width);
    
    return dbuf.items[cidx];
end

local function update_depth(dbuf, xpos, ypos, newDepth)
    local width = dbuf.width;
    local height = dbuf.height;
    
    local ypos_int = math.floor(ypos);
    
    if ( ypos_int < 0 ) or ( ypos_int >= height ) then
        return false;
    end
    
    local xpos_int = math.floor(xpos);
    
    if ( xpos_int < 0 ) or ( xpos_int >= width ) then
        return false;
    end
    
    local cidx = color_idx(xpos_int, ypos_int, width);
    
    dbuf.items[cidx] = newDepth;
    return true;
end

local function to_real_coord(val)
    return ( val/2 + 0.5 );
end

local function to_frustum_coord(val)
    return ( val - 0.5 ) * 2;
end

local function calc_depth(c1k1, c1k2, c1k3, c1k4, b1, a1)
    local divisor = ( c1k1 * a1 + c1k2 * b1 + c1k3 );
    
    if (divisor == 0) then
        return 0;
    end
    
    return ( c1k4 / divisor );
end

local function rasterize_intersection(inter, bbuf, cb)
    local function eval_a1_interval(a1k1, a1k2, pt)
        return ( a1k1 * pt + a1k2 );
    end
    
    local function min_a1_interval(a1k1, a1k2, b1min, b1max)
        assert(b1min <= b1max);
    
        if (_math_eq(a1k1, 0)) then
            return a1k2;
        elseif (a1k1 > 0) then
            return ( a1k1 * b1min + a1k2 );
        else
            return ( a1k1 * b1max + a1k2 );
        end
    end
    
    local function max_a1_interval(a1k1, a1k2, b1min, b1max)
        assert(b1min <= b1max);
    
        if (_math_eq(a1k1, 0)) then
            return a1k2;
        elseif (a1k1 > 0) then
            return ( a1k1 * b1max + a1k2 );
        else
            return ( a1k1 * b1min + a1k2 );
        end
    end
    
    local taskUpdate = taskUpdate;
    
    for m,n in ipairs(inter) do
        local min_v = n.b1lower;
        local max_v = n.b1upper;
        local min_u = min_a1_interval(n.a1lower[1], n.a1lower[2], min_v, max_v);
        local max_u = max_a1_interval(n.a1upper[1], n.a1upper[2], min_v, max_v);
        
        -- Transform to real coordinates.
        min_v = to_real_coord( min_v );
        max_v = to_real_coord( max_v );
        min_u = to_real_coord( min_u );
        max_u = to_real_coord( max_u );
        
        local diff_v = ( max_v - min_v );
        
        local diff_v_pixels = math.ceil(diff_v * bbuf.height);
        
        local start_y = min_v * bbuf.height;
        start_y = math.floor(start_y);
        
        for y=0,diff_v_pixels-1,1 do
            local abs_y = ( start_y + y );
            local abs_v = math.max(math.min( abs_y / bbuf.height, max_v), min_v);

            -- Since we know the dimensions of the to-be-drawn surface we can process by scan-lines.
            local frustum_v = to_frustum_coord(abs_v);
            local block_min_u = eval_a1_interval(n.a1lower[1], n.a1lower[2], frustum_v);
            local block_max_u = eval_a1_interval(n.a1upper[1], n.a1upper[2], frustum_v);
            
            -- Transform to real coordinates.
            block_min_u = to_real_coord( block_min_u );
            block_max_u = to_real_coord( block_max_u );
            
            local block_diff_u = math.min( block_max_u - block_min_u, max_u - min_u );
            
            local block_diff_u_pixels = math.ceil( block_diff_u * bbuf.width );
            
            local block_start_x = math.floor( block_min_u * bbuf.width );
        
            cb( n, block_start_x, abs_y, frustum_v, block_diff_u_pixels );
        end
    end
end

local function draw_plane_on_bbuf(viewFrustum, bbuf, dbuf, plane, is_task, prim_type)
    -- our screen is represented by viewFrustum, defined at the top.
    
    if (is_task) then
        taskUpdate(false, "calculating intersection");
    end

    local inter = false;
    
    if not (prim_type) or (prim_type == "plane") then
        inter = viewFrustum.intersectWithPlane(plane, do_print_math_debug);
    elseif (prim_type == "tri") then
        inter = viewFrustum.intersectWithTrianglePlane(plane, do_print_math_debug);
    end
    
    if not ( inter ) then
        return false;
    end
    
    -- Calculate the real amount of pixels.
    local max_pixels = 0;
    
    local function count_pixels(segment, row_off_x, row_y, frustum_v, row_width)
        max_pixels = max_pixels + row_width;
    end
    
    rasterize_intersection(inter, bbuf, count_pixels);
    
    -- Go through each valid u coordinate and draw all the associated v coordinates.
    local num_drawn_pixels = 0;
    local num_skipped_pixels = 0;
    
    local function draw_row(segment, row_off_x, row_y, frustum_v, row_width)
        for x=0,row_width-1,1 do
            local abs_x = ( row_off_x + x );
            
            local abs_u = ( abs_x / bbuf.width );
            
            -- Calculate the u coord in frustum space.
            local frustum_u = to_frustum_coord(abs_u);
            
            local depth = calc_depth( segment.c1lower[1], segment.c1lower[2], segment.c1lower[3], segment.c1lower[4], frustum_v, frustum_u );
            
            local real_x = abs_x;
            local real_y = bbuf.height - row_y - 1;
            
            local invdepth = (1 - depth);
            
            local old_depth = browse_depth(dbuf, real_x, real_y);
            
            local has_drawn = false;
            
            if (depth < old_depth) then
                has_drawn = set_pixel_on_bbuf(bbuf, real_x, real_y, 255, 150 * invdepth, 150 * invdepth, 150 * invdepth);
                
                update_depth(dbuf, real_x, real_y, depth);
            end
            
            if (has_drawn) then
                num_drawn_pixels = num_drawn_pixels + 1;
            else
                num_skipped_pixels = num_skipped_pixels + 1;
            end
        end
        
        if (is_task) then
            --Update the running task.
            taskUpdate((num_drawn_pixels + num_skipped_pixels) / max_pixels, "rendering pixel " .. num_drawn_pixels .. " and skipped " .. num_skipped_pixels);
        end
    end
    
    if (is_task) then
        taskUpdate(0, "preparing loop");
    end
    
    if (max_pixels >= 1) then
        rasterize_intersection(inter, bbuf, draw_row);
    end
    
    return true, num_drawn_pixels, num_skipped_pixels;
end
_G.draw_plane_on_bbuf = draw_plane_on_bbuf;

-- It is actually undocumented, but plain pixels have two unsigned shorts that define the
-- size of the image at the tail.

local function num_to_ushort_bytes(num)
    local integer = math.floor(num);
    local lower = ( integer % 256 );
    local upper = math.floor( integer / 256 ) % 256;
    
    return string.char(lower, upper);
end
_G.num_to_ushort_bytes = num_to_ushort_bytes;

-- Draws a backbuffer and sends it in "plain" format to all clients.
local function task_draw_scene(thread)
    local bbuf = create_backbuffer(640, 480, 255, 255, 0, 50);
    local dbuf = createDepthBuffer(640, 480, 1);
    
    local time_start = getTickCount();
    
    for m,n in ipairs(test_planes) do
        local gotToDraw, numDrawn, numSkipped = draw_plane_on_bbuf(viewFrustum, bbuf, dbuf, n, true);
        
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

local modelToDraw = false;

do
    local modelFile = fileOpen("gfriend.dff");
    
    if (modelFile) then
        modelToDraw = rwReadClump(modelFile);
        fileClose(modelFile);
    end
end

local function task_draw_model(thread)
    local bbuf = create_backbuffer(640, 480, 255, 255, 0, 50);
    local dbuf = createDepthBuffer(640, 480, 1);
    
    local time_start = getTickCount();
    
    local num_triangles_drawn = 0;
    
    if (modelToDraw) then
        -- Setup the camera.
        local geom = modelToDraw.geomlist[1];
        local mt = geom.morphTargets[1];
        local centerSphere = mt.sphere;
        
        local camPos = viewFrustum.getPos();
        camPos.setX(centerSphere.x);
        camPos.setY(centerSphere.y - 3.8);
        camPos.setZ(centerSphere.z);
        
        local camFront = viewFrustum.getFront();
        camFront.setX(0);
        camFront.setY(5 + centerSphere.r * 2);
        camFront.setZ(0);
        
        local camRight = viewFrustum.getRight();
        camRight.setX(centerSphere.r * 2);
        camRight.setY(0);
        camRight.getZ(0);
        
        local camUp = viewFrustum.getUp();
        camUp.setX(0);
        camUp.setY(0);
        camUp.setZ(centerSphere.r * 2);
    
        local triPlane = createPlane(
            createVector(0, 0, 0),
            createVector(0, 0, 0),
            createVector(0, 0, 0)
        );
        
        local vertices = modelToDraw.geomlist[1].morphTargets[1].vertices;
        local triangles = modelToDraw.geomlist[1].triangles;
        
        local tpos = triPlane.getPos();
        local tu = triPlane.getU();
        local tv = triPlane.getV();
        
        for m,n in ipairs(triangles) do
            taskUpdate( m / #triangles, "drawing triangle #" .. m );
            
            local vert1 = vertices[n.vertex1 + 1];
            local vert2 = vertices[n.vertex2 + 1];
            local vert3 = vertices[n.vertex3 + 1];

            tpos.setX(vert1.x);
            tpos.setY(vert1.y);
            tpos.setZ(vert1.z);
            
            tu.setX(vert2.x - vert1.x);
            tu.setY(vert2.y - vert1.y);
            tu.setZ(vert2.z - vert1.z);
            
            tv.setX(vert3.x - vert1.x);
            tv.setY(vert3.y - vert1.y);
            tv.setZ(vert3.z - vert1.z);
            
            local gotToDraw, numDrawn, numSkipped = draw_plane_on_bbuf(viewFrustum, bbuf, dbuf, triPlane, false, "tri");
            
            if (gotToDraw) and (numDrawn >= 1) then
                num_triangles_drawn = num_triangles_drawn + 1;
            end
        end
    end
        
    local time_end = getTickCount();
    local ms_diff = ( time_end - time_start );
    
    outputDebugString( "render time: " .. ms_diff .. "ms, num drawn triangles: " .. num_triangles_drawn );
    
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

addCommandHandler( "send_bbuf", function(player)
        spawnTask(task_draw_scene);
    end
);

addCommandHandler( "draw_model", function(player)
        spawnTask(task_draw_model);
    end
);

setTimer(
    function()
        threads_pulse();
    end, 50, 0
);