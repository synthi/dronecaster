-- k1: exit/alt  e1: drone
--
--
--       e2: hz          e3: amp
--
--    k2: record      k3: cast
--
--

-- engines & includes
--------------------------------------------------------------------------------
engine.name = "Dronecaster"
draw = include "lib/draw"

local MusicUtil=require "musicutil"

-- variables
--------------------------------------------------------------------------------
local initital_monitor_level
local initital_reverb_onoff

-- midi
local midi_enabled
local midi_devices
local midi_device
local midi_channel
local midi_amp_control
local midi_transport
local midi_amp_cc
local midi_drone_cc

version_major = 1
version_minor = 0
version_patch = 0
filename_prefix = "dronecaster_"
save_path = _path.audio .. "dronecaster/"
amp_default = .4
hz_default = 55
hz_base = 55
crow_cv = 1
drone_default = 1
drones = {}
drones_loaded=false
recording = false
playing = false
counter = metro.init()
alt = false
recording_time = 0
playing_frame = 1
recording_frame = 1
messages = {}
messages["empty"] = "..."
messages["start_recording"] = "Recording..."
messages["stop_recording"] = "...saved."
messages["start_casting"] = "Casting drone..."
messages["start_casting_after_load"] = "Wait 5 sec..."
messages["stop_casting"] = "Cast halted."
alert = {}
alert["casting_message"] = messages["empty"]
alert["casting"] = false
alert["casting_frame"] = 0
alert["recording_message"] = messages["empty"]
alert["recording"] = false
alert["recording_frame"] = 0

done_init = false

-- init & core
--------------------------------------------------------------------------------

-- midi
function build_midi_device_list()
  midi_devices = {}
  for i = 1,#midi.vports do
    local long_name = midi.vports[i].name
    table.insert(midi_devices,i..": "..long_name)
  end
end

function midi_event(data)
  -- global midi setting
  if midi_enabled == 0 then
    return
  end
  msg = midi.to_msg(data)
  -- filter channel
  if msg.ch == midi_channel then
    --msg debug print
    --if msg.type ~= "clock" then tab.print(msg) end
    --note message
    if msg.type == "note_on" then
      params:set("note",msg.note)
      -- amp control
      print(midi_amp_control)
      if midi_amp_control == 2 then
        amp = math.min(msg.vel/100, 1)
      end
      if midi_amp_control == 3 then
        amp = math.min(msg.key_pressure/100, 1)
      end
      if midi_amp_control ~= 0 then
        params:set("amp",amp)
      end
    end
    --cc message
    if msg.type == "cc" then
      if msg.cc == midi_amp_cc then
        params:set("amp", (msg.val/127))
      end
      if msg.cc == midi_drone_cc then
        minval = math.min(msg.val, #drones)
        params:set("drone", minval)
      end
    end
    -- program change message
    if msg.type == "program_change" then
      minval = math.min(msg.val, #drones)
      params:set("drone", minval)
    end
  end
  -- transport
  if midi_transport == 3 then
    return
  end
  if msg.type == "start" then
    play_drone()
  end
  if msg.type == "stop" and midi_transport ~= 2 then
    engine.stop(1)
  end
end
  
  

function init()

   list_drone_names(
      function(names)
	 drones = names
	 tab.print(drones)
	 
	 audio:pitch_off()

	 initital_monitor_level = params:get('monitor_level')
	 params:set('monitor_level', -math.huge)
	 initital_reverb_onoff = params:get('reverb')
	 params:set('reverb', 1) -- 1 is OFF

	 draw.init()
	 if util.file_exists(save_path) == false then
	    util.make_dir(save_path)
	 end
	 
	 crow.input[1].mode("stream", .01)
	 crow.input[1].stream = process_crow_cv_a
	 
	 counter.time = 1
	 counter.count = -1
	 counter.play = 1
	 counter.event = the_sands_of_time
	 counter:start()
	 params:add_control("amp", "amp", controlspec.new(0, 1, "amp", 0, amp_default, "amp"))
	 params:set_action("amp", engine.amp)
	 params:add_control("hz", "hz", controlspec.new(0, 20000, "lin", 0, hz_default, "hz"))
	 params:set_action("hz", hz_base_update)
	 params:add{type="number",id="note",name="note",min=0,max=127,default=24,formatter=function(param) return MusicUtil.note_num_to_name(param:get(),true) end}
	 params:set_action("note",function(v)
			      params:set("hz",math.pow(2,(v-69)/12)*440)
	 end)

	 --params:add_control("drone","drone", controlspec.new(1, #drones, "lin", 0, drone_default, "drone", 1/(#drones-1)))
	 params:add_option("drone", "drone", drones)
	 params:set_action("drone", function()
      if playing then 
         play_drone()
      end
	 end)
  
  -- init midi params
  
  build_midi_device_list()
  params:add_separator("midi")
  params:add_binary("midi_enabled", "enable midi", "toggle", 1)
  params:set_action("midi_enabled",function(x)
    if x == 0 then
      midi_enabled = 0
      params:hide("midi_device")
      params:hide("midi_in_channel")
      params:hide("midi_amp_control")
      params:hide("midi_transport")
      params:hide("midi_amp_cc")
      params:hide("midi_drone_cc")
    elseif x == 1 then
      midi_enabled = 1
      params:show("midi_device")
      params:show("midi_in_channel")
      params:show("midi_amp_control")
      params:show("midi_transport")
      params:show("midi_amp_cc")
      params:show("midi_drone_cc")
    end
    _menu.rebuild_params()
  end)
  params:add{type = "option", id = "midi_device", name = "device",
    options = midi_devices, default = 1,
    action = function(value) 
      midi_device = midi.connect(value)
      midi_device.event = midi_event
      end}
  params:add{type = "number", id = "midi_in_channel", name = "channel",
    min = 1, max = 16, default = 1,
    action = function(value)
      midi_channel = value
    end}
  params:add{type = "option", id = "midi_amp_control", name = "amp note ctrl",
    options = {"none","velocity","key pressure"}, default = 1,
    action = function(value) 
      midi_amp_control = value
    end}
  params:add{type = "option", id = "midi_transport", name = "transport",
    options = {"all","ignore stop","none"}, default = 1,
    action = function(value) 
      midi_transport = value
    end} 
  params:add_number("midi_amp_cc", "amp cc", 0, 127, 76)
  params:set_action("midi_amp_cc",function(v)
			      midi_amp_cc = v
	end)
	params:add_number("midi_drone_cc", "drone cc", 0, 127, 75)
  params:set_action("midi_drone_cc",function(v)
			      midi_drone_cc = v
	end)
	 
	params:bang()
    
    
    
  engine.initialize(hz_default,amp_default)
	 
	 done_init = true
      end
   )

   clock.run(function()
      while true do
         clock.sleep(1/5)
         redraw()
      end
   end)
end

function the_sands_of_time()
   if playing then
      playing_frame = playing_frame + 1  
   end
   if recording then
      recording_frame = recording_frame + 1
      recording_time = recording_time + 1
   end
end

function redraw()
   if (not done_init) then return end
   screen.clear()
   screen.aa(0)
   screen.font_face(0)
   screen.font_size(8)
   pf = playing_frame
   rf = recording_time
   d = drones[round(params:get("drone"))]
   h = round(params:get("hz")) .. " hz"
   a = round(params:get("amp"), 2) .. " amp"
   hud = d .. " " .. h .. " " .. a
   p = playing
   draw.birds(pf)
   draw.wind(pf)
   draw.lights(pf)
   draw.uap(pf)
   draw.landscape()
   draw.top_menu(hud)
   draw.clock(rf)
   draw.play_stop(p)
   if (alert["recording"]) then
      alert = draw.alert_recording(alert, messages)
   end
   if (alert["casting"]) then
      alert = draw.alert_casting(alert, messages)
   end
   screen.update()
end

-- encs & keys
--------------------------------------------------------------------------------
function enc(n,d)
   local mult
   if n == 1 then
      params:set("drone", util.clamp(params:get("drone") + d, 1, #drones))
   elseif n == 2 then
      mult = alt and .1 or .001
      params:delta("hz", d * mult)
   elseif n == 3 then
      mult = alt and 10 or .1
      params:delta("amp", d * mult)
   end
end

function key(n, z)
   if n == 1 and z == 1 then
      alt = true
   elseif z == 0 then
      if n == 1 then
	 alt = false
      end
      if n == 2 then
	 recording = not recording
	 alert["recording"] = true
	 alert["recording_frame"] = 1
	 if recording == true then
	    local record_path = make_filename()
	    recording_time = 0
	    alert["recording_message"] = messages["start_recording"]
	    print("recording to file " .. record_path)
	    engine.record_start(record_path)
	 else
	    alert["recording_message"] = messages["stop_recording"]
	    engine.record_stop(1)
	 end
      elseif n == 3 then
	 playing = not playing
    if playing==nil then 
      playing=false
   end
	 alert["casting"] = true
	 alert["casting_frame"] = 1
	 if playing == true then
	    play_drone()
       if drones_loaded then 
   	    alert["casting_message"] = messages["start_casting"]
       else 
          alert["casting_message"] = messages["start_casting_after_load"]
       end
	 else
	    engine.stop(1)
	    alert["casting_message"] = messages["stop_casting"]
	 end
      end
   end
end

function play_drone()
   local droneIndex = params:get("drone")
   playing = true
   if droneIndex > 0 and droneIndex <= #drones then
      engine.start(drones[droneIndex])
   end
end

-- utils
--------------------------------------------------------------------------------
function make_filename()
   return save_path .. filename_prefix .. os.date("%Y_%m_%d_%H_%M_%S") .. ".aiff"
end

function round(num, places)
   if places and places > 0 then
      mult = 10 ^ places
      return math.floor(num * mult + 0.5) / mult
   end
   return math.floor(num + 0.5)
end


function osc_in(path, msg)
   if path == "/add_drone" then
      print("adding drone: " .. msg[1])
   elseif path == "/drones_loaded" then 
      drones_loaded=true
   end
end


function cleanup()
   -- Put user's audio settings back where they were
   params:set('monitor_level', initital_monitor_level)
   params:set('reverb', initital_reverb_onoff)
   engine.stop(1)
   engine.record_stop(1)
end

function hz_base_update(n)
   hz_base = n
   engine.hz(hz_base * crow_cv)
end

function process_crow_cv_a(v)
   -- print("input stream: "..v)
   -- print(v)
   crow_cv = 2 ^ ((v + 1) - 1)
   engine.hz(hz_base * crow_cv)
end

function rerun()
   norns.script.load(norns.state.script)
end

function r() rerun() end

function list_drone_names(callback)
   local cb = function(text)
      local names = {}
      for line in string.gmatch(text, "/[%a%d%.%s]-%.scd") do
	 name = string.sub(line, 2, -5)
	 table.insert(names, name)
      end
      table.sort(names)
      callback(names)
   end
   norns.system_cmd('find '.. _path.code .. 'dronecaster/engine/drones -name *.scd', cb)
end

osc.event = osc_in -- should probably go in init? race conditions tho?
