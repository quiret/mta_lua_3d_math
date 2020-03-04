local do_debug_triangle = false;

local triangle = createPlane(
    createVector(0, 0, 5),
    createVector(25, 0, 0),
    createVector(0, 0, 15)
);

local frustum_pos = createVector(0, 0, 0);
local frustum_right = createVector(0, 0, 0);
local frustum_up = createVector(0, 0, 0);
local frustum_front = createVector(0, 0, 0);

local frustum = createViewFrustum(
    frustum_pos,
    frustum_right,
    frustum_up,
    frustum_front
);

addEventHandler("onClientRender", root,
    function()
        if not (do_debug_triangle) then return; end;
    
        local triPos = triangle.getPos();
        local triU = triangle.getU();
        local triV = triangle.getV();
        
        local vert1 = {
            triPos.getX(),
            triPos.getY(),
            triPos.getZ(),
            tocolor(255, 255, 255)
        };
        
        local vert2 = {
            triPos.getX() + triU.getX(),
            triPos.getY() + triU.getY(),
            triPos.getZ() + triU.getZ(),
            tocolor(255, 255, 255)
        };
        
        local vert3 = {
            triPos.getX() + triV.getX(),
            triPos.getY() + triV.getY(),
            triPos.getZ() + triV.getZ(),
            tocolor(255, 255, 255)
        };
        
        dxDrawPrimitive3D("trianglelist", false, vert1, vert2, vert3);
        
        -- Check whether the triangle is on screen.
        local camMat = getElementMatrix(getCamera());
        local camPos = camMat[4];
        local camRight = camMat[1];
        local camFront = camMat[2];
        local camUp = camMat[3];
        local farClip = getFarClipDistance();
        
        local cam_frontX = camFront[1] * farClip;
        local cam_frontY = camFront[2] * farClip;
        local cam_frontZ = camFront[3] * farClip;
        
        local sW, sH = guiGetScreenSize();
        
        local s_ratio = sW / sH;
        
        local _, _, _, _, _, _, _, fov = getCameraMatrix();
        local fovRad = math.rad(fov/2);
    
        local cam_side_dist = farClip * math.tan(fovRad);
        local cam_up_dist = cam_side_dist / s_ratio;
    
        local cam_rightX = camRight[1] * cam_side_dist;
        local cam_rightY = camRight[2] * cam_side_dist;
        local cam_rightZ = camRight[3] * cam_side_dist;
        
        local cam_upX = camUp[1] * cam_up_dist;
        local cam_upY = camUp[2] * cam_up_dist;
        local cam_upZ = camUp[3] * cam_up_dist;
        
        frustum_pos.setX(camPos[1]);
        frustum_pos.setY(camPos[2]);
        frustum_pos.setZ(camPos[3]);
        
        frustum_right.setX(cam_rightX);
        frustum_right.setY(cam_rightY);
        frustum_right.setZ(cam_rightZ);
        
        frustum_up.setX(cam_upX);
        frustum_up.setY(cam_upY);
        frustum_up.setZ(cam_upZ);
        
        frustum_front.setX(cam_frontX);
        frustum_front.setY(cam_frontY);
        frustum_front.setZ(cam_frontZ);
        
        local inter = frustum.intersectWithTrianglePlane(triangle);
    
        dxDrawText("is intersecting: " .. tostring(not (inter == false)), 100, 300);
        
        dxDrawText("side_dist: " .. cam_side_dist, 100, 320);
        dxDrawText("up_dist: " .. cam_up_dist, 100, 340);
        dxDrawText("far_clip: " .. farClip, 100, 360);
        dxDrawText("FOV: " .. fov, 100, 380);
        dxDrawText("aspect ratio: " .. s_ratio, 100, 400);
        dxDrawText("camPos: " .. camPos[1] .. ", " .. camPos[2] .. ", " .. camPos[3], 100, 420);
        dxDrawText("camRight: " .. cam_rightX .. ", " .. cam_rightY .. ", " .. cam_rightZ, 100, 440);
        dxDrawText("camUp: " .. cam_upX .. ", " .. cam_upY .. ", " .. cam_upZ, 100, 460);
        dxDrawText("camFront: " .. cam_frontX .. ", " .. cam_frontY .. ", " .. cam_frontZ, 100, 480);
    end
);

local function draw_triangle_on_server(frustum, triangle)
    triggerServerEvent("request_drawtri", root,
        triangle.getPos().getX(),
        triangle.getPos().getY(),
        triangle.getPos().getZ(),
        triangle.getU().getX(),
        triangle.getU().getY(),
        triangle.getU().getZ(),
        triangle.getV().getX(),
        triangle.getV().getY(),
        triangle.getV().getZ(),
        frustum_pos.getX(),
        frustum_pos.getY(),
        frustum_pos.getZ(),
        frustum_right.getX(),
        frustum_right.getY(),
        frustum_right.getZ(),
        frustum_up.getX(),
        frustum_up.getY(),
        frustum_up.getZ(),
        frustum_front.getX(),
        frustum_front.getY(),
        frustum_front.getZ()
    );
end

addCommandHandler("tridraw",
    function()
        do_debug_triangle = not do_debug_triangle;
    end
);

addCommandHandler("draw_curscene",
    function()
        draw_triangle_on_server(frustum, triangle);
    end
);