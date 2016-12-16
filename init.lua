print("Autostart in 5 seconds")

tmr.alarm(6, 5000, 0, function()
    tmr.stop(6)
    if (file.open("main.lua")) then    
        dofile("main.lua")
    else
        print("No Main file found")
    end
end)
