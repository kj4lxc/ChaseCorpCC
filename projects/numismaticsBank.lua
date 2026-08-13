local bankterm = peripheral.find("numismatics_bank_terminal")
local monitor = peripheral.wrap("back")
local atmMon = peripheral.wrap("monitor_4")
local secuitiesMon = peripheral.wrap("monitor_5")
local curSym = string.char(164)
monitor.clear()
local monX = 0
local monY = 0
local playerlist = {}
local corplist = {}
local lineCount = 1

local function InitMon(mon)
  mon.clear()
  monX, monY = mon.getSize()
  mon.setCursorPos(1,1)
end

InitMon(monitor)

local list = bankterm.getAccounts()
local divider = "----------------------------------------"

local function Wait(time)
  local timeToWait = (time/1000)
  sleep(timeToWait)
  return
end

local function GetAccounts()
  local list = bankterm.getAccounts()
  return list
end

local function getLabel(account)
  local label = bankterm.getAccountLabel(account)
  return label
end

local function getBal(account)
  local balance = bankterm.getBalance(account)
  return balance
end

local function isCorp(account)
  local isCorp = bankterm.isPlayerOwned(account)
  return not isCorp
end

local function accountPacket(account)
  local account = {
    label = getLabel(account),
    balance = getBal(account),
    isCorp = isCorp(account)
  }
  return account
end

local function centerText(text, width)
    local padding = math.floor((width - #text) / 2)
    return string.rep(" ", padding) .. text
end

local function twoColumns(left, right, width)
    local columnWidth = math.floor((width - 1) / 2)

    local leftPadding = math.floor((columnWidth - #left) / 2)
    local rightPadding = math.floor((columnWidth - #right) / 2)

    return string.rep(" ", leftPadding) .. left
        .. string.rep(" ", columnWidth - leftPadding - #left)
        .. "|"
        .. string.rep(" ", rightPadding) .. right
        .. string.rep(" ", columnWidth - rightPadding - #right)
end

local function leaderboardLine(position, leftName, rightName, width)
    local number = tostring(position) .. "- "
    local rightPadding = width - #number - #leftName - #rightName

    return number
        .. leftName
        .. string.rep(" ", math.max(1, rightPadding))
        .. rightName
end

local function sortByBalance(players)
    table.sort(players, function(a, b)
        return a.balance > b.balance
    end)

    return players
end

local function getDivider(width)
  local divider = ""
  for i=1, width do
    divider = divider.."-"
  end
  return divider
end

local function monWrite(str)
  monitor.setCursorPos(1, lineCount)
  monitor.write(str)
  lineCount = lineCount + 1
end
InitMon(monitor)


--ATM Monitor
atmMon.clear()
atmMon.setCursorPos(1,1)
atmMon.setTextScale(1.9)
local atmX, atmY = atmMon.getSize()
local atmTitle = centerText("ATM Self-Serve", atmX)
local atmString = twoColumns("ATM #1", "ATM #2", atmX)
atmMon.setCursorPos(1,1)
atmMon.write(atmTitle)
atmMon.setCursorPos(1,2)
atmMon.write(getDivider(atmX))
atmMon.setCursorPos(1,3)
atmMon.write(atmString)


--Securities Monitor
secuitiesMon.clear()
secuitiesMon.setCursorPos(1,1)
secuitiesMon.setTextScale(1.95)
local secX, secY = secuitiesMon.getSize()
local secTitle = centerText("Securities Exchange", secX)
local secStringLower = centerText("v Single Quantities v", secX)
local secStringUpper = centerText("^ Bulk Quantities ^", secX)
secuitiesMon.write(secStringUpper)
secuitiesMon.setCursorPos(1,3)
secuitiesMon.write(secTitle)
secuitiesMon.setCursorPos(1,4)
secuitiesMon.write(centerText("-------------------", secX))
secuitiesMon.setCursorPos(1,5)
secuitiesMon.write(centerText("Exchange items for", secX))
secuitiesMon.setCursorPos(1,6)
secuitiesMon.write(centerText("server currency", secX))
secuitiesMon.setCursorPos(1,8)
secuitiesMon.write(secStringLower)


--Leaderboard
count = 1
local monDivider = ""
for i=1, monX do
  monDivider = monDivider.."-"
end
local numTimes = 0
while true do
  lineCount = 1
  local accountList = GetAccounts()
  local corplist = {}
  local playerlist = {}
  for i, account in pairs(accountList) do
    local accData = accountPacket(account)
    if accData.isCorp then
      table.insert(corplist, {label = accData.label, balance = accData.balance})
    else
      table.insert(playerlist, {label = accData.label, balance = accData.balance})
    end
  end
  local sortedCorp = sortByBalance(corplist)
  local sortedPlayer = sortByBalance(playerlist)
  monWrite(centerText("~Account Leaderboard~", monX))
  monWrite(monDivider)
  if #sortedPlayer < 3 then
    while #sortedPlayer < 3 do
      table.insert(sortedPlayer, {label = "", balance = ""})
    end
  end
  for l, list in pairs(sortedPlayer) do
    if l > 3 then
      break
    end
    if list.balance == "" then
      list.balance = ""
    else
      list.balance = list.balance..curSym
    end
    if list.label == "" then
      list.label = ""
    else
      list.label = list.label.." - Player"
    end
    monWrite(leaderboardLine(l,list.label, list.balance, monX))
  end
  monWrite(monDivider)
  if #sortedCorp < 3 then
    while #sortedCorp < 3 do
      table.insert(sortedCorp, {label = "", balance = ""})
    end
  end
  for l, list in pairs(sortedCorp) do
    if l > 3 then
      break
    end
    if list.balance == "" then
      list.balance = ""
    else
      list.balance = list.balance..curSym
    end
    if list.label == "" then
      list.label = ""
    else
      list.label = list.label.." - Corp"
    end
    monWrite(leaderboardLine(l,list.label, list.balance, monX))
  end
  Wait(10000)
  monitor.clear()
  print("Refreshed leaderboard... "..numTimes.." times")
  numTimes = numTimes + 1
end