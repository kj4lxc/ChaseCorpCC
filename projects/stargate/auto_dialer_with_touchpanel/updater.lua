local DIALERURL = "https://raw.githubusercontent.com/kj4lxc/ChaseCorpCC/main/projects/stargate/auto_dialer_with_touchpanel/dialer.lua"
local MONITORURL = "https://raw.githubusercontent.com/kj4lxc/ChaseCorpCC/main/projects/stargate/auto_dialer_with_touchpanel/monitorProgram.lua"

local function getVersion(source)
  return source:match('local%s+VERSION%s*=%s*"([^"]+)"')
end


local function checkForUpdates()
  local dialerResponse = http.get(DIALERURL)
  if not dialerResponse then
    return false, "Unable to contact update server."
  end
  local monitorResponse = http.get(MONITORURL)
  if not monitorResponse then
    return false, "Unable to contact update server."
  end

  local newSourceDialer = dialerResponse.readAll()
  dialerResponse.close()
  local newSourceMonitor = monitorResponse.readAll()
  monitorResponse.close()

  local remoteVersion = getVersion(newSourceDialer)

  if not remoteVersion then
      return false, "Remote version not found."
  end
  
  local currentDialer = fs.open("/stargateDialer/dialer.lua", "r")
  local current = currentDialer.readAll()
  currentDialer.close()

  local currentVer = getVersion(current)

  if remoteVersion == currentVer then
    return false, "Already up to date."
  end

  print(("Updating %s -> %s"):format(currentVer, remoteVersion))

  local dialer = fs.open("/stargateDialer/dialer.lua", "w")
  dialer.write(newSourceDialer)
  dialer.close()

  local monitor = fs.open("/stargateDialer/monitorProgram.lua", "w")
  monitor.write(newSourceMonitor)
  monitor.close()
  print("Update complete.")
  sleep(1)
  os.reboot()
end

print(checkForUpdates())

print("done")
local didUpdate, Output = checkForUpdates()
print(Output)
shell.run("/stargateDialer/dialer.lua")