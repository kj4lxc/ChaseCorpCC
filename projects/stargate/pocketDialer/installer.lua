-- installer.lua

local BASE_URL = "https://raw.githubusercontent.com/kj4lxc/ChaseCorpCC/main/projects/stargate/pocketDialer/"

local files = {
  "dialer.lua",
  "updater.lua"
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
fs.delete("/installer.lua")
shell.run("/stargateDialer/updater.lua")
]])
startup.close()


print("Rebooting in 2 seconds...")
sleep(2)
os.reboot()