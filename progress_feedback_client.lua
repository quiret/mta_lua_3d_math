-- Created by (c)The_GTA.
local is_currently_processing = false;
local server_status_percentage = 0;
local server_status_msg = false;

addEventHandler( "onClientRender", root, function()
        -- Draw the progress UI if the server is doing something.
        if not (is_currently_processing) then return false; end;
        
        local screenWidth, screenHeight = guiGetScreenSize();
        
        local box_start_x = screenWidth * 0.25;
        local box_start_y = screenHeight - 200;
        
        local box_width = ( screenWidth * 0.5 );
        local box_height = 150;
        
        dxDrawRectangle( box_start_x, box_start_y, box_width, box_height, 0x80000000 );
        
        local status_text = "Status: ";
        
        if (server_status_msg) then
            status_text = status_text .. server_status_msg;
        else
            status_text = status_text .. "undefined";
        end
        
        dxDrawText( status_text, box_start_x + 5, box_start_y + 5 );
        
        local bar_bg_x = box_start_x + 10;
        local bar_bg_y = box_start_y + 35;
        local bar_bg_width = box_width - 20;
        local bar_bg_height = box_height - 60;
        dxDrawRectangle( box_start_x + 10, box_start_y + 35, box_width - 20, box_height - 60, 0xFFFFFFFF );
        
        local cur_perc = math.min(math.max(server_status_percentage, 0), 1);
        
        local width_of_perc = ( bar_bg_width - 6 ) * cur_perc;
        
        dxDrawRectangle( bar_bg_x + 3, bar_bg_y + 3, width_of_perc, bar_bg_height - 6, 0xFF0000FF );
        
        local mid_bar_x = ( bar_bg_x + bar_bg_width / 2 );
        local mid_bar_y = ( bar_bg_y + bar_bg_height / 2 );
        
        local use_font = "default";
        
        local perc_text = tostring(math.floor(server_status_percentage * 100)) .. " %";
        
        local text_scale = 3;
        local text_height = dxGetFontHeight(text_scale, use_font);
        
        local text_width = dxGetTextWidth(perc_text, text_scale);
        
        local center_text_x = ( mid_bar_x - text_width / 2 );
        local center_text_y = ( mid_bar_y - text_height / 2 );
        
        dxDrawText( perc_text, center_text_x, center_text_y, center_text_x, center_text_y, 0xFF00FF00, text_scale );
    end
);

addEvent("onServerProgressStart", true);
addEventHandler("onServerProgressStart", root, function(msg)
        server_status_msg = msg;
        server_status_percentage = 0;
        
        is_currently_processing = true;
    end
);

addEvent("onServerProgressUpdate", true);
addEventHandler("onServerProgressUpdate", root, function(perc, msg)
        server_status_msg = msg;
        server_status_percentage = perc;
    end
);

addEvent("onServerProgressEnd", true);
addEventHandler("onServerProgressEnd", root, function()
        is_currently_processing = false;
    end
);