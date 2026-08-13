local interface = peripheral.find("advanced_crystal_interface") or peripheral.find("crystal_interface") or peripheral.find("basic_interface")
local modem = peripheral.find("modem")
local slaveSend = 54385
local slaveRecieve = 54384
local updateKey = "oF94citYqr46iN45J8Z1gQ"
local connectedName = ""
local connectedAddress = ""
local feedback = {
    [0] = {
        name = "NONE",
        type = "INFO",
        text = "none"
    },

    [-1] = {
        name = "UNKNOWN_ERROR",
        type = "ERROR",
        text = "unknown"
    },

    -- Chevron/Symbol
    [1] = {
        name = "SYMBOL_ENCODED",
        type = "INFO",
        text = "symbol_encoded"
    },

    [-2] = {
        name = "SYMBOL_IN_ADDRESS",
        type = "ERROR",
        text = "symbol_in_address"
    },

    [-3] = {
        name = "SYMBOL_OUT_OF_BOUNDS",
        type = "ERROR",
        text = "symbol_out_of_bounds"
    },

    [-4] = {
        name = "ENCODE_WHEN_CONNECTED",
        type = "ERROR",
        text = "encode_when_connected"
    },

    -- Establishing Connection
    [2] = {
        name = "CONNECTION_ESTABLISHED_SYSTEM_WIDE",
        type = "INFO",
        text = "connection_established.system_wide"
    },

    [3] = {
        name = "CONNECTION_ESTABLISHED_INTERSTELLAR",
        type = "INFO",
        text = "connection_established.interstellar"
    },

    [4] = {
        name = "CONNECTION_ESTABLISHED_INTERGALACTIC",
        type = "INFO",
        text = "connection_established.intergalactic"
    },

    [-5] = {
        name = "INCOMPLETE_ADDRESS",
        type = "MAJOR_ERROR",
        text = "incomplete_address"
    },

    [-6] = {
        name = "INVALID_ADDRESS",
        type = "MAJOR_ERROR",
        text = "invalid_address"
    },

    [-7] = {
        name = "NOT_ENOUGH_POWER",
        type = "MAJOR_ERROR",
        text = "not_enough_power"
    },

    [-8] = {
        name = "SELF_OBSTRUCTED",
        type = "MAJOR_ERROR",
        text = "self_obstructed"
    },

    [-9] = {
        name = "TARGET_OBSTRUCTED",
        type = "SKIPPABLE_ERROR",
        text = "target_obstructed"
    },

    [-10] = {
        name = "SELF_DIAL",
        type = "MAJOR_ERROR",
        text = "self_dial"
    },

    [-11] = {
        name = "SAME_SYSTEM_DIAL",
        type = "MAJOR_ERROR",
        text = "same_system_dial"
    },

    [-12] = {
        name = "ALREADY_CONNECTED",
        type = "MAJOR_ERROR",
        text = "already_connected"
    },

    [-13] = {
        name = "NO_GALAXY",
        type = "MAJOR_ERROR",
        text = "no_galaxy"
    },

    [-14] = {
        name = "NO_DIMENSIONS",
        type = "MAJOR_ERROR",
        text = "no_dimensions"
    },

    [-15] = {
        name = "NO_STARGATES",
        type = "MAJOR_ERROR",
        text = "no_stargates"
    },

    [-16] = {
        name = "SELF_RESTRICTED",
        type = "SKIPPABLE_ERROR",
        text = "self_restricted"
    },

    [-17] = {
        name = "TARGET_RESTRICTED",
        type = "SKIPPABLE_ERROR",
        text = "target_restricted"
    },

    [-18] = {
        name = "INVALID_8_CHEVRON_ADDRESS",
        type = "MAJOR_ERROR",
        text = "invalid_8_chevron_address"
    },

    [-19] = {
        name = "INVALID_SYSTEM_WIDE_CONNECTION",
        type = "MAJOR_ERROR",
        text = "invalid_system_wide_connection"
    },

    [-20] = {
        name = "TARGET_NOT_WHITELISTED",
        type = "MAJOR_ERROR",
        text = "target_not_whitelisted"
    },

    [-21] = {
        name = "NOT_WHITELISTED_BY_TARGET",
        type = "SKIPPABLE_ERROR",
        text = "not_whitelisted_by_target"
    },

    [-22] = {
        name = "TARGET_BLACKLISTED",
        type = "MAJOR_ERROR",
        text = "target_blacklisted"
    },

    [-23] = {
        name = "BLACKLISTED_BY_TARGET",
        type = "SKIPPABLE_ERROR",
        text = "blacklisted_by_target"
    },

    -- End Connection
    [7] = {
        name = "CONNECTION_ENDED_BY_DISCONNECT",
        type = "INFO",
        text = "Wormhole Closed"
    },

    [8] = {
        name = "CONNECTION_ENDED_BY_POINT_OF_ORIGIN",
        type = "INFO",
        text = "Wormhole Closed From Destination"
    },

    [9] = {
        name = "CONNECTION_ENDED_BY_NETWORK",
        type = "INFO",
        text = "connection_ended.stargate_network"
    },

    [10] = {
        name = "CONNECTION_ENDED_BY_AUTOCLOSE",
        type = "INFO",
        text = "Wormhole Closed"
    },

    [-24] = {
        name = "EXCEEDED_CONNECTION_TIME",
        type = "ERROR",
        text = "Wormhole Timed Out"
    },

    [-25] = {
        name = "RAN_OUT_OF_POWER",
        type = "ERROR",
        text = "ran_out_of_power"
    },

    [-26] = {
        name = "CONNECTION_REROUTED",
        type = "ERROR",
        text = "connection_rerouted"
    },

    [-27] = {
        name = "WRONG_DISCONNECT_SIDE",
        type = "ERROR",
        text = "wrong_disconnect_side"
    },

    [-28] = {
        name = "CONNECTION_FORMING",
        type = "ERROR",
        text = "connection_forming"
    },

    [-29] = {
        name = "STARGATE_DESTROYED",
        type = "ERROR",
        text = "stargate_destroyed"
    },

    [-30] = {
        name = "COULD_NOT_REACH_TARGET_STARGATE",
        type = "MAJOR_ERROR",
        text = "could_not_reach_target_stargate"
    },

    [-31] = {
        name = "INTERRUPTED_BY_INCOMING_CONNECTION",
        type = "ERROR",
        text = "INCOMING WORMHOLE"
    },

    -- Milky Way
    [11] = {
        name = "CHEVRON_OPENED",
        type = "INFO",
        text = "chevron_opened"
    },

    -- Rotating
    [12] = {
        name = "ROTATING",
        type = "INFO",
        text = "rotating"
    },

    [-32] = {
        name = "ROTATION_BLOCKED",
        type = "INFO",
        text = "rotation_blocked"
    },

    [-33] = {
        name = "NOT_ROTATING",
        type = "INFO",
        text = "not_rotating"
    },

    [13] = {
        name = "ROTATION_STOPPED",
        type = "INFO",
        text = "rotation_stopped"
    },

    -- Milky Way
    [-34] = {
        name = "CHEVRON_ALREADY_OPENED",
        type = "ERROR",
        text = "chevron_already_opened"
    },

    [-35] = {
        name = "CHEVRON_ALREADY_CLOSED",
        type = "ERROR",
        text = "chevron_already_closed"
    },

    [-36] = {
        name = "CHEVRON_NOT_OPEN",
        type = "ERROR",
        text = "chevron_not_open"
    },

    -- Other
    [-37] = {
        name = "TARGET_NOT_LOADED",
        type = "ERROR",
        text = "target_not_loaded"
    },

    [-38] = {
        name = "SELF_OUTSIDE_STARGATE_NETWORK",
        type = "MAJOR_ERROR",
        text = "self_outside_stargate_network"
    },

    [-39] = {
        name = "TARGET_OUTSIDE_STARGATE_NETWORK",
        type = "MAJOR_ERROR",
        text = "target_outside_stargate_network"
    }
}
local gateDB = {}
local VERSION = "1.0.0"

local function dialMilky(address)
  local addressLength = #address    
  local start = interface.getChevronsEngaged() + 1
  for chevron = start,addressLength,1 do
    local symbol = address[chevron] 
      if chevron % 2 == 0 then
        interface.rotateClockwise(symbol)
      else
        interface.rotateAntiClockwise(symbol)
      end

      while(not interface.isCurrentSymbol(symbol)) do
        sleep(0)
      end
      
      sleep(.25)
      interface.openChevron() --This raises the chevron
      sleep(.25)
      interface.closeChevron() -- and this lowers it
      sleep(.25)
    end 

end

local function dialOther(address)
    local addressLength = #address    
    local start = interface.getChevronsEngaged() + 1
    
    for chevron = start,addressLength,1 do
      local symbol = address[chevron]
      interface.engageSymbol(symbol)
      local code, message = interface.getRecentFeedback()
      print(feedback[code].text)    
    end 
end

local function gateHandler(address)
  local timer = os.startTimer(60)
  local addressLength = #address 
  local statusUpdate = true
  while statusUpdate do

    local event, side, channel, replyChannel, message, distance = os.pullEvent()
    if event == "stargate_chevron_engaged" then
      local numEngaged = interface.getChevronsEngaged()
      if numEngaged == addressLength then
        local data = "Chevron "..numEngaged.." LOCKED!"
        print(data)
        os.queueEvent("wormhole data", data)
      else
        local data = "Chevron "..numEngaged.." encoded."
        print(data)
        os.queueEvent("wormhole data", data)
      end
      timer = os.startTimer(60)
    elseif event == "stargate_disconnected" then
      local data = feedback[channel].text
      print(data)
      os.queueEvent("wormhole data", data)
      sleep(5)
      os.queueEvent("done")
      break
    elseif event == "stargate_reset" then
      local data = "stargate_reset: "..replyChannel
      print(data)
      os.queueEvent("wormhole data", data)
      sleep(5)
      os.queueEvent("done")
      break
    elseif event == "stargate_deconstructing_entity" then
      local data = "Outbound Traveler: "..replyChannel
      print(data)
      os.queueEvent("wormhole data", data)
      timer = os.startTimer(60)
    elseif event == "stargate_reconstructing_entity" then
      timer = os.startTimer(60)
      local data = "Incoming traveler: "..replyChannel
      print(data)
      os.queueEvent("wormhole data", data)
    elseif event == "stargate_outgoing_wormhole" then
      sleep(2)
      os.queueEvent(
          "wormhole data",
          {
              ["Status"] = "Wormhole Established",
              ["Destination"] = connectedName,
              ["Address"] = connectedAddress
          }
      )
    elseif event == "timer" then
      if side == timer then
        local stargateStatus = interface.isStargateConnected()
        if stargateStatus then
          timer = os.startTimer(60)
          local data = "timer event but wormhole still active... waiting..."
          print(data)
          os.queueEvent("wormhole data", data)
          sleep(5)
        else
          print("no activity detected from gate and gate does not show active breaking loop...")
          os.queueEvent("done")
          break
        end
      end
    end
  end
end

local function dial(address)
  interface.disconnectStargate()
  local gateType = tostring(interface.getStargateType())
  print(gateType)
  if gateType == "sgjourney:classic_stargate" or gateType == "sgjourney:milky_way_stargate" then
    print("i am taking milky way")
    parallel.waitForAll(
      function()
        dialMilky(address)
      end,
      function()
        gateHandler(address)
      end
    )
  else
    print("i am dialing other")
    parallel.waitForAll(
      function()
        dialOther(address)
      end,
      function()
        gateHandler(address)
      end
    )
  end
end

local function LoadJson(path)
  local file = ""
  local content = ""
  if not fs.exists(path) then
    local file = fs.open(path, "w")
    file.write("{}")
    file.close()
    return {}
  else
    file = fs.open(path, "r")
    content = file.readAll()
    file.close()
  end
  return textutils.unserializeJSON(content) or {}
end

local function SaveJson(path, data)
  local file = fs.open(path, "w")
  file.write(textutils.serializeJSON(data))
  file.close()
end

local function CompareTables(a, b)
    if a == b then
        return true
    end

    if type(a) ~= "table" or type(b) ~= "table" then
        return false
    end

    for key, value in pairs(a) do
        if not CompareTables(value, b[key]) then
            return false
        end
    end

    for key, value in pairs(b) do
        if not CompareTables(value, a[key]) then
            return false
        end
    end

    return true
end


local function Onboard()
 write("Gate name: ")
  local name = read()

  local public
  while true do
    write("Should this gate be public? (Y/n): ")
    local answer = read():lower()
    if answer == "y" or answer == "yes" then
      public = true
      break
    elseif answer == "n" or answer == "no" then
      public = false
      break
    elseif answer == "" then
      public = true
    else
      print("Please enter y or n.")
    end
  end
  local packet = {}
  packet.name = name
  packet.public = public
  packet.address = interface.getLocalAddress()
  packet.uuid = ""
  packet.irisPass = -1
  return packet

end
modem.open(slaveRecieve)
local config = {}
local configPath = "config.json"
config = LoadJson(configPath)
if not config.uuid then
  config = Onboard()
  local packet = {}
  packet.type = "register"
  packet.key = updateKey
  packet.gateInfo = {}
  packet.gateInfo.name = config.name
  packet.gateInfo.address = config.address
  packet.gateInfo.public = config.public
  modem.transmit(slaveSend, slaveRecieve, packet)
  local waitForCallback = true
  while waitForCallback do
    local event, side, channel, replyChannel, message, distance = os.pullEvent()
    if event == "modem_message" and channel == slaveRecieve then
      local msg = message
      if msg.type == "update" and msg.key == updateKey then
        local tempGateDB = msg.data
        for g, gate in pairs(tempGateDB) do
          if CompareTables(gate.address, config.address) then
            config.uuid = g
            waitForCallback = false
            break
          end
        end
      end
    end
  end
  SaveJson(configPath, config)
end


local file = fs.open("gates.json", "r")
local contents = file.readAll()
file.close()
gateDB = textutils.unserializeJSON(contents)
os.queueEvent("done")

local packet = {}
packet.type = "update"
packet.key = updateKey
modem.transmit(slaveSend, slaveRecieve, packet)
local startup = true
while true do
  local event, side, channel, replyChannel, message, distance = os.pullEvent()
  if event == "gate_selected" then
    local gate = gateDB[side]
    local address = gate.address
    connectedName = gate.name
    connectedAddress = ""
    for i, index in pairs(address) do
      if i == #address then
        break
      end
      if i < #address-1 then
        connectedAddress = connectedAddress..index.."-"
      else
        connectedAddress = connectedAddress..index
      end
      
    end
    sleep(.2)
    os.queueEvent(
          "wormhole data",
          {
              ["Status"] = "Dialing Sequence",
              ["Destination"] = connectedName,
              ["Address"] = connectedAddress
          }
      )
    print(side)
    print(name)
    dial(address)
  elseif event == "stargate_chevron_engaged" then
    if not message then
      local data = "Chevron "..channel.." encoded."
      print(data)
      os.queueEvent("wormhole data", data)
    end
  elseif event == "stargate_outgoing_wormhole" then
    gateHandler(channel )
  elseif event == "stargate_incoming_connection" then
    os.queueEvent(
        "wormhole data", "INCOMING WORMHOLE"
    )
  elseif event == "stargate_incoming_wormhole" then
    gateHandler(channel)
    print(channel)
  elseif event == "modem_message" then
    print(channel, textutils.serializeJSON(message))
    if channel == slaveRecieve and message.key == updateKey and message.type == "update" then
      print("recieved gate update...")
      gateDB = message.data
      SaveJson("debugGateData.json", gateDB)
      local tempGates = gateDB
      tempGates[config.uuid] = nil
      _G.gateDB = tempGates
      if startup then
        checkForUpdates()
        shell.run("bg monitorProgram.lua")
      end
      startup = false
    end
  end
end
