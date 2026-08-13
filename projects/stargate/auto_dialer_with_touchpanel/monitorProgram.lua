local DATA_FILE = "gates.json"
local RELOAD_INTERVAL = 5

--------------------------------------------------
-- Button settings
--------------------------------------------------

local BUTTON_WIDTH = 15
local BUTTON_HEIGHT = 3

local BUTTON_SPACING_X = 2
local BUTTON_SPACING_Y = 1

local NORMAL_TEXT_SCALE = 0.5

--------------------------------------------------
-- Title settings
--------------------------------------------------

local TITLE_HEIGHT = 5

--------------------------------------------------
-- Navigation settings
--------------------------------------------------

-- Navigation occupies the LAST 3 rows
--
-- Example:
--
-- PAGE 1 / 2
-- [ < PREVIOUS ] [ NEXT > ]
--
local NAV_HEIGHT = 3

--------------------------------------------------
-- Monitor
--------------------------------------------------

local monitor = peripheral.find("monitor")

if not monitor then
    error("No monitor found")
end

local monitorName =
    peripheral.getName(monitor)

--------------------------------------------------
-- State
--------------------------------------------------

local gates = {}
local pages = {}
local currentPage = 1

local displayMode = false

--------------------------------------------------
-- STARGATES bitmap
--------------------------------------------------

local TITLE_FONT = {

    S = {
        "11111",
        "10000",
        "11111",
        "00001",
        "11111"
    },

    T = {
        "11111",
        "00100",
        "00100",
        "00100",
        "00100"
    },

    A = {
        "01110",
        "10001",
        "11111",
        "10001",
        "10001"
    },

    R = {
        "11110",
        "10001",
        "11110",
        "10100",
        "10010"
    },

    G = {
        "01111",
        "10000",
        "10111",
        "10001",
        "01111"
    },

    E = {
        "11111",
        "10000",
        "11110",
        "10000",
        "11111"
    }
}

--------------------------------------------------
-- Build title bitmap
--------------------------------------------------

local function buildTitleBitmap()

    local text = "STARGATES"

    local rows = {
        "",
        "",
        "",
        "",
        ""
    }

    for characterIndex = 1, #text do

        local character =
            string.sub(
                text,
                characterIndex,
                characterIndex
            )

        local glyph =
            TITLE_FONT[character]

        if glyph then

            for row = 1, 5 do

                rows[row] =
                    rows[row] ..
                    glyph[row]

                if characterIndex < #text then

                    rows[row] =
                        rows[row] ..
                        "0"
                end
            end
        end
    end

    return rows
end

--------------------------------------------------
-- Draw title
--------------------------------------------------

local function drawTitle()

    local width =
        monitor.getSize()

    local bitmap =
        buildTitleBitmap()

    local titleWidth =
        #bitmap[1]

    --------------------------------------------------
    -- Center title
    --------------------------------------------------

    local startX =
        math.floor(
            (width - titleWidth) / 2
        ) + 1

    local startY = 1

    --------------------------------------------------
    -- Draw bitmap
    --------------------------------------------------

    for row = 1, #bitmap do

        local line =
            bitmap[row]

        local x =
            startX

        for column = 1, #line do

            local pixel =
                string.sub(
                    line,
                    column,
                    column
                )

            monitor.setCursorPos(
                x,
                startY + row - 1
            )

            if pixel == "1" then

                monitor.setBackgroundColor(
                    colors.white
                )

            else

                monitor.setBackgroundColor(
                    colors.black
                )
            end

            monitor.write(" ")

            x = x + 1
        end
    end

    --------------------------------------------------
    -- Reset colors
    --------------------------------------------------

    monitor.setBackgroundColor(
        colors.black
    )

    monitor.setTextColor(
        colors.white
    )
end

--------------------------------------------------
-- Load gate data
--------------------------------------------------

local function loadGates()

--[[     if not fs.exists(DATA_FILE) then

        printError(
            "Missing " ..
            DATA_FILE
        )

        return false
    end

    local file =
        fs.open(
            DATA_FILE,
            "r"
        )

    if not file then

        printError(
            "Unable to open " ..
            DATA_FILE
        )

        return false
    end

    local contents =
        file.readAll()

    file.close()

    if not contents
        or contents == "" then

        printError(
            "Gate file is empty"
        )

        return false
    end

    local data =
        textutils.unserializeJSON(
            contents
        )

    if type(data) ~= "table" then

        printError(
            "Invalid JSON in " ..
            DATA_FILE
        )

        return false
    end 

    gates = data]]

    gates = _G.gateDB

    return true
end

--------------------------------------------------
-- Build sorted gate list
--------------------------------------------------

local function buildGateList()

    local list = {}

    for uuid, gate in pairs(gates) do
      if gate.public then
        table.insert(
            list,
            {
                uuid = uuid,
                name = gate.name or uuid,
                address = gate.address
            }
        )
      end
        
    end

    --------------------------------------------------
    -- Sort:
    --
    -- Abydos first
    -- Testgate 1 second
    -- Everything else naturally sorted
    --------------------------------------------------

    table.sort(
        list,
        function(a, b)

            local aName =
                tostring(a.name)

            local bName =
                tostring(b.name)

            local aLower =
                string.lower(aName)

            local bLower =
                string.lower(bName)

            --------------------------------------------------
            -- Priority
            --------------------------------------------------

            local function getPriority(name)

                if name == "abydos" then
                    return 1
                end

                if name == "testgate 1" then
                    return 2
                end

                return 3
            end

            local aPriority =
                getPriority(aLower)

            local bPriority =
                getPriority(bLower)

            if aPriority ~= bPriority then

                return aPriority <
                    bPriority
            end

            --------------------------------------------------
            -- Natural numerical sorting
            --------------------------------------------------

            local aNum =
                tonumber(
                    string.match(
                        aLower,
                        "(%d+)"
                    )
                )

            local bNum =
                tonumber(
                    string.match(
                        bLower,
                        "(%d+)"
                    )
                )

            if aNum and bNum then

                if aNum ~= bNum then
                    return aNum < bNum
                end
            end

            return aLower < bLower
        end
    )

    return list
end

--------------------------------------------------
-- Build pages
--------------------------------------------------

local function buildPages()

    monitor.setTextScale(
        NORMAL_TEXT_SCALE
    )

    pages = {}

    local width, height =
        monitor.getSize()

    --------------------------------------------------
    -- Button area
    --
    -- Title:
    -- rows 1-5
    --
    -- Buttons:
    -- row 7 onward
    --
    -- Navigation:
    -- LAST 3 rows
    --------------------------------------------------

    local startY = 7

    local navigationStartY =
        height - NAV_HEIGHT + 1

    --------------------------------------------------
    -- Calculate available button height
    --------------------------------------------------

    local buttonAreaHeight =
        navigationStartY -
        startY

    --------------------------------------------------
    -- Calculate columns
    --------------------------------------------------

    local columns =
        math.floor(
            (
                width +
                BUTTON_SPACING_X
            ) /
            (
                BUTTON_WIDTH +
                BUTTON_SPACING_X
            )
        )

    if columns < 1 then
        columns = 1
    end

    --------------------------------------------------
    -- Calculate rows
    --------------------------------------------------

    local rows =
        math.floor(
            (
                buttonAreaHeight +
                BUTTON_SPACING_Y
            ) /
            (
                BUTTON_HEIGHT +
                BUTTON_SPACING_Y
            )
        )

    if rows < 1 then
        rows = 1
    end

    local buttonsPerPage =
        columns * rows

    --------------------------------------------------
    -- Build sorted gate list
    --------------------------------------------------

    local gateList =
        buildGateList()

    --------------------------------------------------
    -- Build pages
    --------------------------------------------------

    local page = {}

    for count, gate in ipairs(gateList) do

        --------------------------------------------------
        -- IMPORTANT:
        --
        -- This index is LOCAL TO THE CURRENT PAGE.
        --
        -- This fixes the second-page bug.
        --------------------------------------------------

        local pageIndex =
            #page

        local column =
            pageIndex % columns

        local row =
            math.floor(
                pageIndex / columns
            )

        local button = {

            uuid = gate.uuid,

            name =
                gate.name,

            address =
                gate.address,

            x =
                1 +
                column *
                (
                    BUTTON_WIDTH +
                    BUTTON_SPACING_X
                ),

            y =
                startY +
                row *
                (
                    BUTTON_HEIGHT +
                    BUTTON_SPACING_Y
                )
        }

        table.insert(
            page,
            button
        )

        --------------------------------------------------
        -- Page full
        --------------------------------------------------

        if #page >= buttonsPerPage then

            table.insert(
                pages,
                page
            )

            page = {}
        end
    end

    --------------------------------------------------
    -- Remaining buttons
    --------------------------------------------------

    if #page > 0 then

        table.insert(
            pages,
            page
        )
    end

    --------------------------------------------------
    -- Always have at least one page
    --------------------------------------------------

    if #pages == 0 then

        pages = {
            {}
        }
    end

    --------------------------------------------------
    -- Keep page valid
    --------------------------------------------------

    if currentPage > #pages then
        currentPage = #pages
    end

    if currentPage < 1 then
        currentPage = 1
    end
end

--------------------------------------------------
-- Draw button
--------------------------------------------------

local function drawButton(
    button,
    pressed
)

    if pressed then

        monitor.setBackgroundColor(
            colors.lightGray
        )

        monitor.setTextColor(
            colors.black
        )

    else

        monitor.setBackgroundColor(
            colors.gray
        )

        monitor.setTextColor(
            colors.white
        )
    end

    --------------------------------------------------
    -- Background
    --------------------------------------------------

    for row = 0, BUTTON_HEIGHT - 1 do

        monitor.setCursorPos(
            button.x,
            button.y + row
        )

        monitor.write(
            string.rep(
                " ",
                BUTTON_WIDTH
            )
        )
    end

    --------------------------------------------------
    -- Text
    --------------------------------------------------

    local text =
        tostring(
            button.name or button.uuid
        )

    if #text > BUTTON_WIDTH then

        text =
            string.sub(
                text,
                1,
                BUTTON_WIDTH
            )
    end

    local textX =
        button.x +
        math.floor(
            (
                BUTTON_WIDTH -
                #text
            ) / 2
        )

    local textY =
        button.y +
        math.floor(
            BUTTON_HEIGHT / 2
        )

    monitor.setCursorPos(
        textX,
        textY
    )

    monitor.write(text)
end

--------------------------------------------------
-- Draw navigation
--------------------------------------------------

local function drawNavigation()

    local width, height =
        monitor.getSize()

    --------------------------------------------------
    -- Navigation is at the BOTTOM
    --------------------------------------------------

    local pageInfoY =
        height - 2

    local buttonY =
        height - 1

    --------------------------------------------------
    -- Clear navigation area
    --------------------------------------------------

    monitor.setBackgroundColor(
        colors.black
    )

    monitor.setTextColor(
        colors.white
    )

    for y = height - NAV_HEIGHT + 1, height do

        monitor.setCursorPos(
            1,
            y
        )

        monitor.write(
            string.rep(
                " ",
                width
            )
        )
    end

    --------------------------------------------------
    -- Page indicator
    --------------------------------------------------

    if #pages > 1 then

        local pageText =
            "PAGE " ..
            currentPage ..
            " / " ..
            #pages

        local pageX =
            math.floor(
                (width - #pageText) / 2
            ) + 1

        monitor.setCursorPos(
            pageX,
            pageInfoY
        )

        monitor.setBackgroundColor(
            colors.black
        )

        monitor.setTextColor(
            colors.white
        )

        monitor.write(
            pageText
        )
    end

    --------------------------------------------------
    -- Navigation button width
    --------------------------------------------------

    local buttonWidth =
        math.floor(
            (width - 5) / 2
        )

    --------------------------------------------------
    -- Previous
    --------------------------------------------------

    local previousX = 2

    if #pages > 1
        and currentPage > 1 then

        monitor.setBackgroundColor(
            colors.blue
        )

        monitor.setTextColor(
            colors.white
        )

    else

        monitor.setBackgroundColor(
            colors.gray
        )

        monitor.setTextColor(
            colors.lightGray
        )
    end

    monitor.setCursorPos(
        previousX,
        buttonY
    )

    monitor.write(
        string.rep(
            " ",
            buttonWidth
        )
    )

    local previousText =
        "<  PREVIOUS"

    local previousTextX =
        previousX +
        math.floor(
            (
                buttonWidth -
                #previousText
            ) / 2
        )

    monitor.setCursorPos(
        previousTextX,
        buttonY
    )

    monitor.write(
        previousText
    )

    --------------------------------------------------
    -- Next
    --------------------------------------------------

    local nextX =
        width -
        buttonWidth -
        1

    if #pages > 1
        and currentPage < #pages then

        monitor.setBackgroundColor(
            colors.blue
        )

        monitor.setTextColor(
            colors.white
        )

    else

        monitor.setBackgroundColor(
            colors.gray
        )

        monitor.setTextColor(
            colors.lightGray
        )
    end

    monitor.setCursorPos(
        nextX,
        buttonY
    )

    monitor.write(
        string.rep(
            " ",
            buttonWidth
        )
    )

    local nextText =
        "NEXT  >"

    local nextTextX =
        nextX +
        math.floor(
            (
                buttonWidth -
                #nextText
            ) / 2
        )

    monitor.setCursorPos(
        nextTextX,
        buttonY
    )

    monitor.write(
        nextText
    )

    --------------------------------------------------
    -- Reset
    --------------------------------------------------

    monitor.setBackgroundColor(
        colors.black
    )

    monitor.setTextColor(
        colors.white
    )
end

--------------------------------------------------
-- Draw normal page
--------------------------------------------------

local function drawPage()

    monitor.setTextScale(
        NORMAL_TEXT_SCALE
    )

    monitor.setBackgroundColor(
        colors.black
    )

    monitor.setTextColor(
        colors.white
    )

    monitor.clear()

    --------------------------------------------------
    -- Title
    --------------------------------------------------

    drawTitle()

    --------------------------------------------------
    -- Gate buttons
    --------------------------------------------------

    local page =
        pages[currentPage]

    if page then

        for _, button in ipairs(page) do

            drawButton(
                button,
                false
            )
        end
    end

    --------------------------------------------------
    -- Navigation
    --------------------------------------------------

    drawNavigation()

    --------------------------------------------------
    -- Reset
    --------------------------------------------------

    monitor.setBackgroundColor(
        colors.black
    )

    monitor.setTextColor(
        colors.white
    )
end

--------------------------------------------------
-- Display wormhole data
--------------------------------------------------

local function displayWormholeData(data)

  displayMode = true

  --------------------------------------------------
  -- Convert data to lines
  --------------------------------------------------

  local rawLines = {}

  if type(data) == "table" then

      for key, value in pairs(data) do

          table.insert(
              rawLines,
              tostring(key) ..
              ": " ..
              tostring(value)
          )
      end

  else

    table.insert(
      rawLines,
      tostring(data)
    )
  end

  --------------------------------------------------
  -- Possible scales
  --------------------------------------------------

  local scales = {
    2.5,
    2,
    1.5,
    1
  }

  local bestScale = 1
  local bestLines = rawLines

  --------------------------------------------------
  -- Find largest scale that fits
  --------------------------------------------------

  for _, scale in ipairs(scales) do

      monitor.setTextScale(
          scale
      )

      local width, height =
          monitor.getSize()

      local usableWidth =
          width - 2

      local usableHeight =
          height - 2

      local lines = {}

      --------------------------------------------------
      -- Wrap text
      --------------------------------------------------

      for _, originalText in ipairs(
          rawLines
      ) do

          local text =
              tostring(
                  originalText
              )

          if text == "" then

              table.insert(
                  lines,
                  ""
              )

          else

              while #text > usableWidth do

                  local breakAt =
                      usableWidth

                  --------------------------------------------------
                  -- Prefer spaces
                  --------------------------------------------------

                  for i =
                      usableWidth,
                      1,
                      -1 do

                      if string.sub(
                          text,
                          i,
                          i
                      ) == " " then

                          breakAt =
                              i - 1

                          break
                      end
                  end

                  if breakAt <= 0 then
                      breakAt =
                          usableWidth
                  end

                  table.insert(
                      lines,
                      string.sub(
                          text,
                          1,
                          breakAt
                      )
                  )

                  text =
                      string.sub(
                          text,
                          breakAt + 1
                      )

                  text =
                      string.gsub(
                          text,
                          "^%s+",
                          ""
                      )
              end

              table.insert(
                  lines,
                  text
              )
          end
      end

      --------------------------------------------------
      -- Check height
      --------------------------------------------------

      if #lines <= usableHeight then

          bestScale = scale
          bestLines = lines

          break
      end
  end

  --------------------------------------------------
  -- Apply selected scale
  --------------------------------------------------

  monitor.setTextScale(
      bestScale
  )

  local width, height =
      monitor.getSize()

  monitor.setBackgroundColor(
      colors.black
  )

  monitor.setTextColor(
      colors.white
  )

  monitor.clear()

  --------------------------------------------------
  -- Center vertically
  --------------------------------------------------

  local startY =
      math.floor(
          (
              height -
              #bestLines
          ) / 2
      ) + 1

  --------------------------------------------------
  -- Draw lines
  --------------------------------------------------

  for i, line in ipairs(
      bestLines
  ) do

      local x =
          math.floor(
              (
                  width -
                  #line
              ) / 2
          ) + 1

      local y =
          startY + i - 1

      monitor.setCursorPos(
          x,
          y
      )

      monitor.write(line)
  end
end

--------------------------------------------------
-- Find button
--------------------------------------------------

local function getButtonAt(x, y)

  local page =
    pages[currentPage]

  if not page then
    return nil
  end

  for _, button in ipairs(page) do
    if x >= button.x
      and x <
        button.x +
        BUTTON_WIDTH

      and y >= button.y
      and y <
        button.y +
        BUTTON_HEIGHT then

      return button
    end
  end

  return nil
end

--------------------------------------------------
-- Handle touch
--------------------------------------------------

local function handleTouch(x, y)

    local width, height =
      monitor.getSize()

    --------------------------------------------------
    -- Navigation
    --------------------------------------------------

    local buttonY =
      height - 1

    local buttonWidth =
      math.floor(
        (width - 5) / 2
      )

    local previousX = 2

    local nextX =
      width -
      buttonWidth -
      1

    --------------------------------------------------
    -- Previous
    --------------------------------------------------

    if #pages > 1
      and currentPage > 1
      and x >= previousX
      and x <
        previousX +
        buttonWidth
      and y == buttonY then

      currentPage =
        currentPage - 1

      drawPage()

      return
    end

    --------------------------------------------------
    -- Next
    --------------------------------------------------

    if #pages > 1
      and currentPage < #pages
      and x >= nextX
      and x <
        nextX +
        buttonWidth
      and y == buttonY then

      currentPage =
        currentPage + 1

      drawPage()

      return
    end

    --------------------------------------------------
    -- Gate button
    --------------------------------------------------

    local button = getButtonAt(x, y)
    if not button then
      return
    end

    --------------------------------------------------
    -- Pressed state
    --------------------------------------------------

    drawButton(
      button,
      true
    )

    --------------------------------------------------
    -- Send UUID
    --------------------------------------------------

    os.queueEvent(
      "gate_selected",
      button.uuid
    )

    sleep(0.1)

    --------------------------------------------------
    -- Don't redraw if another display took over
    --------------------------------------------------

    if not displayMode then
      drawPage()
    end
end

--------------------------------------------------
-- UI event loop
--------------------------------------------------

local function touchLoop()

  while true do

    local event, a, b, c =
      os.pullEvent()
    --------------------------------------------------
    -- Monitor touch
    --------------------------------------------------

    if event ==
      "monitor_touch" then

      if not displayMode
        and a == monitorName then

        handleTouch(
          b,
          c
        )
      end

    --------------------------------------------------
    -- Wormhole data
    --------------------------------------------------

    elseif event ==
      "wormhole data" then
      print("WORMHOLE EVENT")
      print(textutils.serialize(a))
      displayWormholeData(a)
      --displayWormholeData(a)

    --------------------------------------------------
    -- Done
    --------------------------------------------------

    elseif event == "done" then

      displayMode = false

      --------------------------------------------------
      -- Restore normal scale
      --------------------------------------------------

      monitor.setTextScale(
          NORMAL_TEXT_SCALE
      )

      --------------------------------------------------
      -- Rebuild because monitor dimensions
      -- depend on text scale.
      --------------------------------------------------

      buildPages()

      drawPage()
    end
  end
end

--------------------------------------------------
-- Reload gate configuration
--------------------------------------------------

local function reloadLoop()

  while true do
    sleep(
      RELOAD_INTERVAL
    )
    if loadGates() then
      if not displayMode then
        buildPages()
        drawPage()
      end
    end
  end
end

--------------------------------------------------
-- Initial setup
--------------------------------------------------

monitor.setTextScale(
  NORMAL_TEXT_SCALE
)

if not loadGates() then
  error(
    "Unable to load " ..
    DATA_FILE
  )
end

buildPages()

drawPage()

--------------------------------------------------
-- Run
--------------------------------------------------

parallel.waitForAll(
  touchLoop,
  reloadLoop
)