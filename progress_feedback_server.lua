-- Created by (c)The_GTA.
local currently_running_task = false;
local completion_percentage = 0;
local status_msg = "";

function spawnTask(routine, ...)
    if (currently_running_task) then return false; end;
    
    completion_percentage = 0;
    status_msg = "";
    
    local args = { ... };
    
    triggerClientEvent("onServerProgressStart", root, status_msg);
    
    currently_running_task = createThread(
        function(thread)
            routine(thread, unpack(args));
            
            -- Tell the client that we finished.
            triggerClientEvent("onServerProgressEnd", root);
            
            -- We finished running.
            currently_running_task = false;
        end
    );
    
    currently_running_task.sustime(50);
    
    return true;
end

function taskUpdate(percentage, message, fastUpdateClient)
    if (currently_running_task) then
        if (percentage) then
            completion_percentage = percentage;
        end
        
        if (message) then
            status_msg = message;
        end
        
        local doSendToClient = true;
        
        if (fastUpdateClient == false) then
            doSendToClient = currently_running_task.yield();
        end
        
        if (doSendToClient) then
            -- Send an update to the client.
            triggerClientEvent("onServerProgressUpdate", root, completion_percentage, status_msg);
        end
        
        if not (fastUpdateClient == false) then
            currently_running_task.yield();
        end
    end
end