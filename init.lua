dofile("wlancfg.lua")
print("Initialize Hardware")
gpio.mode(0, gpio.OUTPUT)
gpio.mode(5, gpio.OUTPUT)
gpio.mode(6, gpio.OUTPUT)

-- Alles aus machen
gpio.write(0, gpio.LOW)        
gpio.write(5, gpio.LOW)        
gpio.write(6, gpio.LOW)        

mqttIPserver="10.23.42.10"

-- The Mqtt logic
m = mqtt.Client("trafficlight", 120, "user", "pass")

global_c=nil
function startTcpServer()
    s=net.createServer(net.TCP, 180)
    s:listen(2323,function(c)
    global_c=c
    function s_output(str)
      if(global_c~=nil)
         then global_c:send(str)
      end
    end
    node.output(s_output, 0)
    c:on("receive",function(c,l)
      node.input(l)
    end)
    c:on("disconnection",function(c)
      node.output(nil)
      global_c=nil
    end)
    print("Welcome to the Trafficlight")
    end)
end

function mqttsubscribe()
 tmr.stop(0) -- stop the reconnection
 tmr.alarm(1,50,0,function() 
        m:subscribe("/room/trafficlight/+/command",0, function(conn) 
            print("subscribed") 
            m:publish("/room/trafficlight/ip",wifi.sta.getip(),0,0)
        end) 
    end)
end
m:on("connect", mqttsubscribe)
m:on("offline", function(con) 
    print ("offline")
    tmr.alarm(0, 5000, 1, function()
        print("Reconnecting...")
        m:connect(mqttIPserver,1883,0)
    end)
end)
m:on("message", function(conn, topic, data)
   -- skipp emtpy messages
   if (data == nil) then
    return
   end
   if topic=="/room/trafficlight/green/command" then
      if (data == "on") then
        tmr.stop(4)
        gpio.write(0, gpio.HIGH)
        m:publish("/room/trafficlight/green/state","on",0,1)
      elseif ( data == "off") then
        tmr.stop(4)
        gpio.write(0, gpio.LOW)        
        m:publish("/room/trafficlight/green/state","off",0,1)
      else
       for k, v in string.gmatch(data, "(%w+) ([0-9]+)") do
        if (k == "blink") then
          tmr.alarm(4,tonumber(v),1,function()
            -- Toggle the Lamp
            gpio.write(0, ( gpio.read(0) + 1) % 2)
          end)
        end
       end
      end
   elseif topic=="/room/trafficlight/yellow/command" then
      if (data == "on") then
        tmr.stop(5)
        gpio.write(5, gpio.HIGH)
        m:publish("/room/trafficlight/yellow/state","on",0,1)
      elseif ( data == "off") then
        tmr.stop(5)
        gpio.write(5, gpio.LOW)
        m:publish("/room/trafficlight/yellow/state","off",0,1)
      else
        for k, v in string.gmatch(data, "(%w+) ([0-9]+)") do
        if (k == "blink") then
          tmr.alarm(5,tonumber(v),1,function()
            -- Toggle the Lamp
            gpio.write(5, ( gpio.read(5) + 1) % 2)
          end)
        end
       end  
      end
    elseif topic=="/room/trafficlight/red/command" then
      if (data == "on") then
        tmr.stop(6)
        gpio.write(6, gpio.HIGH)
        m:publish("/room/trafficlight/red/state","on",0,1)
      elseif (data == "off") then
        tmr.stop(6)
        gpio.write(6, gpio.LOW)
        m:publish("/room/trafficlight/red/state","off",0,1)
      else
        for k, v in string.gmatch(data, "(%w+) ([0-9]+)") do
        if (k == "blink") then
          tmr.alarm(6,tonumber(v),1,function()
            -- Toggle the Lamp
            gpio.write(6, ( gpio.read(6) + 1) % 2)
          end)
        end
       end
      end
   end
end)

-- Wait to be connect to the WiFi access point. 
tmr.alarm(0, 100, 1, function()
  if wifi.sta.status() ~= 5 then
     print("Connecting to AP...")
     gpio.write(5, ( gpio.read(5) + 1) % 2)
  else
     tmr.stop(0)
     -- Switch of the booting lamp
     gpio.write(5, gpio.LOW)
     print('IP: ',wifi.sta.getip())
     m:connect(mqttIPserver,1883,0)
     startTcpServer()
  end
end)
