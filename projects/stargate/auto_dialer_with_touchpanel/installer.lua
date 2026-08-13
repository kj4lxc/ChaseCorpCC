-- installer.lua

local BASE_URL = "https://raw.githubusercontent.com/kj4lxc/ChaseCorpCC/main/projects/stargate/auto_dialer_with_panel/"

local files = {
  "dialer.lua",
  "monitorProgram.lua"
}

local installDir = "/stargateDialer"

if not http then
  error("HTTP API is disabled.")
end

-- Create install directory
if not fs.exists(installDir) then
  fs.makeDir(installDir)
end

-- Download files
for _, file in ipairs(files) do
  print("Downloading " .. file)
  print("heychase look here")
  print(BASE_URL..file)
  local h = http.get(BASE_URL .. file)
  if not h then
    error("Failed to download " .. file)
  end

  local f = fs.open(fs.combine(installDir, file), "w")
  f.write(h.readAll())
  f.close()
  h.close()
end

print("Creating startup.lua")

local startup = fs.open("/startup.lua", "w")
startup.write([[
shell.run("/myProgram/main.lua")
]])
startup.close()

-- Delete installer
local me = shell.getRunningProgram()

print("Removing installer...")
fs.delete(me)

print("Rebooting in 2 seconds...")
sleep(2)
os.reboot()