-- Created by (c)The_GTA.
local server_texture = false;

addEvent("onServerTransmitImage", true);
addEventHandler("onServerTransmitImage", root, function(imgPixels)
        if ( server_texture ) then
            destroyElement(server_texture);
        end
        
        server_texture = dxCreateTexture(imgPixels, "argb", false, "wrap");
    end
);

addEventHandler( "onClientRender", root, function()
        -- draw a server transmitted image.
        if ( server_texture ) then
            local width, height = dxGetMaterialSize( server_texture );
            dxDrawImage( 0, 0, width, height, server_texture );
        end
    end
);

addCommandHandler("bbcl", function()
        if (server_texture) then
            destroyElement(server_texture);
            
            server_texture = false;
        end
    end
);