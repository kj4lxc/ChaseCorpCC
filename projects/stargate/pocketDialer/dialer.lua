local modem = peripheral.find("modem")
local DISTANCE_REFRESH_INTERVAL = 10
local DIAL_TIMEOUT = 120
local slaveSend = 54385
local slaveRecieve = 54384
local VERSION = "1.0.0"
local gateDB = {}

local updatePass = "oF94citYqr46iN45J8Z1gQ"
local closestToMe = ""

--------------------------------------------------
-- RANDOM / UUID
--------------------------------------------------

math.randomseed(os.epoch("utc"))
math.random()
math.random()
math.random()


local function uuid()

    local template =
        "xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx"

    return (template:gsub("[xy]", function(c)

        local v

        if c == "x" then
            v = math.random(0, 15)
        else
            v = math.random(8, 11)
        end

        return string.format("%x", v)

    end))

end

local myID = uuid()


--------------------------------------------------
-- MODEM
--------------------------------------------------

modem.open(slaveRecieve)


--------------------------------------------------
-- JSON
--------------------------------------------------

local function SaveJson(path, data)

    local file = fs.open(path, "w")

    if file then

        file.write(
            textutils.serializeJSON(data)
        )

        file.close()

    end

end


--------------------------------------------------
-- FIND CLOSEST GATE
--------------------------------------------------

local function GetClosest(entries)

    local closest = nil

    for _, entry in pairs(entries) do

        if entry.distance <= 100 then

            if closest == nil
                or entry.distance < closest.distance then

                closest = entry

            end

        end

    end

    return closest

end


--------------------------------------------------
-- GET GATE DATABASE
--------------------------------------------------

local function GetGateDB()

    print("getting gates")

    local packet = {}

    packet.type = "update"
    packet.key = updatePass

    modem.transmit(
        slaveSend,
        slaveRecieve,
        packet
    )


    while true do

        local event,
            side,
            channel,
            replyChannel,
            message,
            distance =
            os.pullEvent("modem_message")


        if channel == slaveRecieve then

            if message
                and message.type == "update" then

                gateDB = message.data

                return

            end

        end

    end

end


--------------------------------------------------
-- DISTANCE CHECK
--------------------------------------------------

local function FindClosestGate()

    local tempDB = {}

    local trackClosest = true


    local me = {}

    me.id = myID
    me.type = "distanceCheck"


    modem.transmit(
        slaveRecieve,
        slaveRecieve,
        me
    )


    local timer = os.startTimer(.5)


    while trackClosest do

        local event,
            side,
            channel,
            replyChannel,
            message,
            distance =
            os.pullEvent()


        --------------------------------------------------
        -- DISTANCE RESPONSE
        --------------------------------------------------

        if event == "modem_message"
            and channel == slaveRecieve
            and message
            and message.type == "distanceResponse" then

            if message.to == myID then

                if distance then

                    local gate = {}

                    gate.id = message.id
                    gate.distance = distance

                    table.insert(
                        tempDB,
                        gate
                    )

                end


                -- Reset timeout
                timer = os.startTimer(.25)

            end


        --------------------------------------------------
        -- TIMER
        --------------------------------------------------

        elseif event == "timer"
            and side == timer then

            trackClosest = false

            break

        end

    end


    local closestGate =
        GetClosest(tempDB)

    closestToMe = closestGate


    if not closestGate then

        print(
            "No gates within 100 blocks."
        )

        SaveJson(
            "debugGates",
            tempDB
        )

        return nil

    end


    local gate =
        gateDB[closestGate.id]


    if not gate then

        print(
            "Closest gate is not in gateDB."
        )

        return nil

    end


    print(
        "closestGate is "
        .. gate.name
    )


    SaveJson(
        "debugGates",
        tempDB
    )


    return gate

end


--------------------------------------------------
-- NO CLOSE GATES SCREEN
--------------------------------------------------

local function NoCloseGates()

    local width, height =
        term.getSize()


    term.setBackgroundColor(
        colors.black
    )

    term.setTextColor(
        colors.white
    )

    term.clear()


    local message =
        "NO CLOSE GATES FOUND CLOSING"


    local x =
        math.floor(
            (width - #message) / 2
        ) + 1


    local y =
        math.floor(
            height / 2
        )


    if x < 1 then
        x = 1
    end


    if y < 1 then
        y = 1
    end


    term.setCursorPos(
        x,
        y
    )

    term.write(message)


    sleep(5)

    os.shutdown()

end


--------------------------------------------------
-- BUTTON DATA
--------------------------------------------------

local buttons = {}


--------------------------------------------------
-- BUILD BUTTON LIST
--------------------------------------------------

local function BuildButtons()

    buttons = {}


    for id, gate in pairs(gateDB) do

        if not closestToMe
            or id ~= closestToMe.id then

            local button = {}

            button.id = id

            button.name = gate.name

            button.gate = gate

            table.insert(
                buttons,
                button
            )

        end

    end

end


--------------------------------------------------
-- DRAW GATE BUTTON
--------------------------------------------------

local function DrawButton(
    button,
    x,
    y,
    width,
    height
)

    --------------------------------------------------
    -- Save clickable coordinates
    --------------------------------------------------

    button.x1 = x
    button.x2 = x + width - 1

    button.y1 = y
    button.y2 = y + height - 1


    --------------------------------------------------
    -- Button background
    --------------------------------------------------

    term.setBackgroundColor(
        colors.blue
    )

    term.setTextColor(
        colors.white
    )


    for row = 0, height - 1 do

        term.setCursorPos(
            x,
            y + row
        )

        term.write(
            string.rep(
                " ",
                width
            )
        )

    end


    --------------------------------------------------
    -- Button text
    --------------------------------------------------

    local text =
        button.name


    if #text > width - 2 then

        text =
            text:sub(
                1,
                width - 2
            )

    end


    local textX =
        x
        + math.floor(
            (width - #text) / 2
        )


    local textY =
        y
        + math.floor(
            height / 2
        )


    term.setCursorPos(
        textX,
        textY
    )

    term.write(text)

end


--------------------------------------------------
-- DRAW NAVIGATION BUTTON
--------------------------------------------------

local function DrawNavigationButton(
    name,
    x,
    y,
    width,
    height
)

    local button = {}


    button.action = name

    button.x1 = x
    button.x2 = x + width - 1

    button.y1 = y
    button.y2 = y + height - 1


    --------------------------------------------------
    -- Background
    --------------------------------------------------

    term.setBackgroundColor(
        colors.gray
    )

    term.setTextColor(
        colors.white
    )


    for row = 0, height - 1 do

        term.setCursorPos(
            x,
            y + row
        )

        term.write(
            string.rep(
                " ",
                width
            )
        )

    end


    --------------------------------------------------
    -- Text
    --------------------------------------------------

    local textX =
        x
        + math.floor(
            (width - #name) / 2
        )


    local textY =
        y
        + math.floor(
            height / 2
        )


    term.setCursorPos(
        textX,
        textY
    )

    term.write(name)


    return button

end


--------------------------------------------------
-- FIND BUTTON AT LOCATION
--------------------------------------------------

local function GetButtonAt(
    x,
    y,
    pageStart,
    pageEnd
)

    for i = pageStart, pageEnd do

        local button =
            buttons[i]


        if button
            and button.x1
            and button.x2
            and button.y1
            and button.y2 then


            if x >= button.x1
                and x <= button.x2
                and y >= button.y1
                and y <= button.y2 then

                return button

            end

        end

    end


    return nil

end


--------------------------------------------------
-- DIAL GATE
--------------------------------------------------

local function DialGate(gateID)

    --------------------------------------------------
    -- Get gate using the button's ID/index
    --------------------------------------------------
    local idToDial = gateID
    local gate =
        gateDB[idToDial]


    if not gate then

        print(
            "ERROR: Gate not found: "
            .. tostring(idToDial)
        )

        return false

    end


    --------------------------------------------------
    -- Print selected information
    --------------------------------------------------

    print(
        "Dialing: "
        .. gate.name
    )

    print(
        "Index: "
        .. tostring(idToDial)
    )


    --------------------------------------------------
    -- Get address
    --------------------------------------------------

    local address =
        gate.address


    --------------------------------------------------
    -- Build packet
    --------------------------------------------------

    local dialPacket = {}

    dialPacket.type =
        "remoteDial"

    dialPacket.gateInfo = {}

    dialPacket.gateInfo.from = closestToMe.id

    dialPacket.gateInfo.to = idToDial


    --------------------------------------------------
    -- Send packet
    --------------------------------------------------

    modem.transmit(
        slaveRecieve,
        slaveRecieve,
        dialPacket
    )


    print(
        "Dial request sent for "
        .. gate.name
    )


    return true

end


--------------------------------------------------
-- GATE MENU
--------------------------------------------------

local function GateMenu()

    local currentPage = 1


    --------------------------------------------------
    -- SCREEN SIZE
    --------------------------------------------------

    local screenWidth,
        screenHeight =
        term.getSize()


    --------------------------------------------------
    -- BUTTON SETTINGS
    --------------------------------------------------

    local buttonHeight = 3
    local spacing = 1
    local firstButtonY = 3


    --------------------------------------------------
    -- TWO COLUMN SETTINGS
    --------------------------------------------------

    local columnWidth =
        math.floor(
            (screenWidth - 3) / 2
        )


    local leftColumnX =
        1


    local rightColumnX =
        leftColumnX
        + columnWidth
        + spacing


    --------------------------------------------------
    -- NAVIGATION SETTINGS
    --------------------------------------------------

    local navigationHeight = 3


    --------------------------------------------------
    -- AVAILABLE HEIGHT
    --------------------------------------------------

    local availableHeight =
        screenHeight
        - firstButtonY
        - navigationHeight
        - 1


    --------------------------------------------------
    -- ROWS PER PAGE
    --------------------------------------------------

    local rowsPerPage =
        math.floor(
            (availableHeight + spacing)
            / (buttonHeight + spacing)
        )


    if rowsPerPage < 1 then

        rowsPerPage = 1

    end


    --------------------------------------------------
    -- TWO BUTTONS PER ROW
    --------------------------------------------------

    local buttonsPerPage =
        rowsPerPage * 2


    --------------------------------------------------
    -- DRAW PAGE
    --------------------------------------------------

    local function DrawPage()

        --------------------------------------------------
        -- TOTAL PAGES
        --------------------------------------------------

        local totalPages =
            math.max(
                1,
                math.ceil(
                    #buttons / buttonsPerPage
                )
            )


        --------------------------------------------------
        -- Make sure current page is still valid
        --------------------------------------------------

        if currentPage > totalPages then

            currentPage = totalPages

        end


        if currentPage < 1 then

            currentPage = 1

        end


        --------------------------------------------------
        -- Reset colors
        --------------------------------------------------

        term.setBackgroundColor(
            colors.black
        )

        term.setTextColor(
            colors.white
        )


        term.clear()


        --------------------------------------------------
        -- TITLE
        --------------------------------------------------

        local title =
            "SELECT GATE"


        local titleX =
            math.floor(
                (screenWidth - #title) / 2
            ) + 1


        term.setCursorPos(
            titleX,
            1
        )

        term.write(title)


        --------------------------------------------------
        -- SHOW CURRENT CLOSEST GATE
        --------------------------------------------------

        if closestToMe then

            local closestGate =
                gateDB[closestToMe.id]

            if closestGate then

                local closestText =
                    "Nearest: "
                    .. closestGate.name
                    .. " ("
                    .. string.format(
                        "%.1f",
                        closestToMe.distance
                    )
                    .. ")"


                if #closestText > screenWidth then

                    closestText =
                        closestText:sub(
                            1,
                            screenWidth
                        )

                end


                local closestX =
                    math.floor(
                        (screenWidth - #closestText) / 2
                    ) + 1


                term.setCursorPos(
                    closestX,
                    2
                )

                term.write(
                    closestText
                )

            end

        end


        --------------------------------------------------
        -- PAGE RANGE
        --------------------------------------------------

        local pageStart =
            ((currentPage - 1)
            * buttonsPerPage) + 1


        local pageEnd =
            math.min(
                currentPage * buttonsPerPage,
                #buttons
            )


        --------------------------------------------------
        -- DRAW GATE BUTTONS
        --------------------------------------------------

        for i = pageStart, pageEnd do

            local pageIndex =
                i - pageStart


            local row =
                math.floor(
                    pageIndex / 2
                )


            local column =
                pageIndex % 2


            local x


            if column == 0 then

                x =
                    leftColumnX

            else

                x =
                    rightColumnX

            end


            local y =
                firstButtonY
                + row
                * (
                    buttonHeight
                    + spacing
                )


            DrawButton(
                buttons[i],
                x,
                y,
                columnWidth,
                buttonHeight
            )

        end


        --------------------------------------------------
        -- NAVIGATION
        --------------------------------------------------

        local navY =
            screenHeight
            - navigationHeight
            + 1


        local navWidth =
            math.floor(
                (screenWidth - 3) / 2
            )


        local previousButton =
            nil

        local nextButton =
            nil


        --------------------------------------------------
        -- PREVIOUS
        --------------------------------------------------

        if currentPage > 1 then

            previousButton =
                DrawNavigationButton(
                    "< PREVIOUS",
                    1,
                    navY,
                    navWidth,
                    navigationHeight
                )

        end


        --------------------------------------------------
        -- NEXT
        --------------------------------------------------

        if currentPage < totalPages then

            nextButton =
                DrawNavigationButton(
                    "NEXT >",
                    screenWidth - navWidth,
                    navY,
                    navWidth,
                    navigationHeight
                )

        end


        --------------------------------------------------
        -- PAGE NUMBER
        --------------------------------------------------

        local pageText =
            "Page "
            .. currentPage
            .. " / "
            .. totalPages


        local pageX =
            math.floor(
                (screenWidth - #pageText) / 2
            ) + 1


        term.setBackgroundColor(
            colors.black
        )

        term.setTextColor(
            colors.white
        )


        term.setCursorPos(
            pageX,
            navY + 1
        )


        term.write(
            pageText
        )


        --------------------------------------------------
        -- RETURN CURRENT PAGE DATA
        --------------------------------------------------

        return pageStart,
            pageEnd,
            previousButton,
            nextButton

    end


    --------------------------------------------------
    -- START DISTANCE REFRESH TIMER
    --------------------------------------------------

    local refreshTimer =
        os.startTimer(
            DISTANCE_REFRESH_INTERVAL
        )


    --------------------------------------------------
    -- START 2 MINUTE TIMEOUT
    --------------------------------------------------

    local shutdownTimer =
        os.startTimer(
            DIAL_TIMEOUT
        )


    --------------------------------------------------
    -- MENU LOOP
    --------------------------------------------------

    while true do

        local pageStart,
            pageEnd,
            previousButton,
            nextButton =
            DrawPage()


        --------------------------------------------------
        -- WAIT FOR EVENT
        --------------------------------------------------

        local event,
            p1,
            p2,
            p3 =
            os.pullEvent()


        --------------------------------------------------
        -- PERIODIC DISTANCE CHECK
        --------------------------------------------------

        if event == "timer"
            and p1 == refreshTimer then


            --------------------------------------------------
            -- Save the old closest gate
            --------------------------------------------------

            local oldClosestID =
                closestToMe
                and closestToMe.id
                or nil


            local oldClosestDistance =
                closestToMe
                and closestToMe.distance
                or nil


            --------------------------------------------------
            -- Find the new closest gate
            --------------------------------------------------

            local newClosestGate =
                FindClosestGate()


            --------------------------------------------------
            -- If there is no gate within 100 blocks,
            -- stop drawing the menu and shut down.
            --------------------------------------------------

            if not newClosestGate then

                NoCloseGates()

                return

            end


            --------------------------------------------------
            -- Determine whether anything changed
            --------------------------------------------------

            local newClosestID =
                newClosestGate
                and newClosestGate.id
                or nil


            local newClosestDistance =
                closestToMe
                and closestToMe.distance
                or nil


            local closestChanged = false


            --------------------------------------------------
            -- Gate changed
            --------------------------------------------------

            if oldClosestID ~= newClosestID then

                closestChanged = true

            end


            --------------------------------------------------
            -- Distance changed
            --------------------------------------------------

            if oldClosestDistance ~= newClosestDistance then

                closestChanged = true

            end


            --------------------------------------------------
            -- Update button list / screen
            --------------------------------------------------

            if closestChanged then

                BuildButtons()


                --------------------------------------------------
                -- Keep current page valid
                --------------------------------------------------

                local totalPages =
                    math.max(
                        1,
                        math.ceil(
                            #buttons / buttonsPerPage
                        )
                    )


                if currentPage > totalPages then

                    currentPage = totalPages

                end


                if currentPage < 1 then

                    currentPage = 1

                end

            end


            --------------------------------------------------
            -- Start another refresh timer
            --------------------------------------------------

            refreshTimer =
                os.startTimer(
                    DISTANCE_REFRESH_INTERVAL
                )


        --------------------------------------------------
        -- 2 MINUTE TIMEOUT
        --------------------------------------------------

        elseif event == "timer"
            and p1 == shutdownTimer then

            print(
                "No gate selected for 2 minutes."
            )

            print(
                "Shutting down..."
            )

            os.shutdown()


        --------------------------------------------------
        -- TOUCH EVENT
        --------------------------------------------------

        elseif event == "mouse_click" then


            local x = p2
            local y = p3


            --------------------------------------------------
            -- FIND WHICH GATE BUTTON WAS TOUCHED
            --------------------------------------------------

            local button =
                GetButtonAt(
                    x,
                    y,
                    pageStart,
                    pageEnd
                )


            --------------------------------------------------
            -- GATE BUTTON PRESSED
            --------------------------------------------------

            if button then

                local gateID =
                    button.id


                local gate =
                    gateDB[gateID]


                local address =
                    gate.address


                --------------------------------------------------
                -- SHOW FEEDBACK
                --------------------------------------------------

                term.setBackgroundColor(
                    colors.black
                )

                term.setTextColor(
                    colors.white
                )


                local bottomY =
                    screenHeight


                term.setCursorPos(
                    1,
                    bottomY
                )


                term.clearLine()


                term.write(
                    "Index: "
                    .. tostring(gateID)
                )


                print(
                    "Selected: "
                    .. gate.name
                )


                print(
                    "Index: "
                    .. tostring(gateID)
                )


                print(
                    "Address: "
                    .. textutils.serialize(address)
                )


                --------------------------------------------------
                -- CLEAR SCREEN
                --------------------------------------------------

                term.setBackgroundColor(
                    colors.black
                )

                term.clear()

                term.setCursorPos(
                    1,
                    1
                )


                --------------------------------------------------
                -- DIAL
                --------------------------------------------------

                DialGate(
                    gateID
                )


                return gateID

            end


            --------------------------------------------------
            -- PREVIOUS BUTTON
            --------------------------------------------------

            if previousButton then

                if x >= previousButton.x1
                    and x <= previousButton.x2
                    and y >= previousButton.y1
                    and y <= previousButton.y2 then

                    currentPage =
                        currentPage - 1


                    if currentPage < 1 then

                        currentPage = 1

                    end

                end

            end


            --------------------------------------------------
            -- NEXT BUTTON
            --------------------------------------------------

            if nextButton then

                if x >= nextButton.x1
                    and x <= nextButton.x2
                    and y >= nextButton.y1
                    and y <= nextButton.y2 then

                    currentPage =
                        currentPage + 1


                    local totalPages =
                        math.max(
                            1,
                            math.ceil(
                                #buttons / buttonsPerPage
                            )
                        )


                    if currentPage > totalPages then

                        currentPage =
                            totalPages

                    end

                end

            end

        end

    end

end


--------------------------------------------------
-- MAIN PROGRAM
--------------------------------------------------

GetGateDB()


--------------------------------------------------
-- DISTANCE CHECK
--------------------------------------------------

local closestGate =
    FindClosestGate()


if not closestGate then

    NoCloseGates()

    return

end


--------------------------------------------------
-- BUILD BUTTONS
--------------------------------------------------

BuildButtons()


--------------------------------------------------
-- CHECK FOR GATES
--------------------------------------------------

if #buttons == 0 then

    term.setBackgroundColor(
        colors.black
    )

    term.clear()

    term.setCursorPos(
        1,
        1
    )

    print(
        "No gates available."
    )

    return

end


--------------------------------------------------
-- SHOW MENU
--------------------------------------------------

GateMenu()


local function WriteToTerminal(data)

    local width, height = term.getSize()

    --------------------------------------------------
    -- Convert value to string
    --------------------------------------------------

    local function ValueToString(value)

        if type(value) == "table" then
            return textutils.serialize(value)

        elseif value == nil then
            return "nil"

        else
            return tostring(value)

        end

    end


    --------------------------------------------------
    -- Word-wrap a string
    --------------------------------------------------

    local function WrapText(text)

        local result = {}

        while #text > width do

            -- Look for the last space that fits
            local breakAt = nil

            for i = width, 1, -1 do

                if text:sub(i, i) == " " then
                    breakAt = i
                    break
                end

            end


            --------------------------------------------------
            -- No space found
            -- Force a break at the screen edge
            --------------------------------------------------

            if not breakAt then

                table.insert(
                    result,
                    text:sub(1, width)
                )

                text =
                    text:sub(width + 1)

            else

                table.insert(
                    result,
                    text:sub(1, breakAt - 1)
                )

                -- Remove the space we broke on
                text =
                    text:sub(breakAt + 1)

            end

        end


        table.insert(
            result,
            text
        )

        return result

    end


    --------------------------------------------------
    -- Build lines
    --------------------------------------------------

    local lines = {}


    if type(data) == "table" then

        for key, value in pairs(data) do

            local line =
                tostring(key)
                .. ": "
                .. ValueToString(value)


            local wrapped =
                WrapText(line)


            for _, wrappedLine in ipairs(wrapped) do

                table.insert(
                    lines,
                    wrappedLine
                )

            end

        end

    else

        local wrapped =
            WrapText(
                ValueToString(data)
            )


        for _, line in ipairs(wrapped) do

            table.insert(
                lines,
                line
            )

        end

    end


    --------------------------------------------------
    -- Clear screen
    --------------------------------------------------

    term.setBackgroundColor(
        colors.black
    )

    term.setTextColor(
        colors.white
    )

    term.clear()


    --------------------------------------------------
    -- Vertically center all lines
    --------------------------------------------------

    local startY =
        math.floor(
            (height - #lines) / 2
        ) + 1


    if startY < 1 then
        startY = 1
    end


    --------------------------------------------------
    -- Draw lines
    --------------------------------------------------

    for i, line in ipairs(lines) do

        local y =
            startY + i - 1


        if y > height then
            break
        end


        --------------------------------------------------
        -- Fill the entire row
        --------------------------------------------------

        term.setCursorPos(
            1,
            y
        )

        term.write(
            string.rep(
                " ",
                width
            )
        )


        --------------------------------------------------
        -- Center the text
        --------------------------------------------------

        local textWidth =
            #line


        local x =
            math.floor(
                (width - textWidth) / 2
            ) + 1


        if x < 1 then
            x = 1
        end


        term.setCursorPos(
            x,
            y
        )

        term.write(line)

    end

end


local waitForCallbacks = true
local stuckTimeout = os.startTimer(5)
while waitForCallbacks do

    local event,
        side,
        channel,
        replyChannel,
        message,
        distance =
        os.pullEvent()


    if event == "modem_message" and channel == slaveRecieve
        and message.type then

        if message.type == "dialerCallback" then

            if message.id == closestToMe.id then

              WriteToTerminal(
                message.callbackData
              )
              stuckTimeout = os.startTimer(5)
            end

        elseif message.type == "dialerCallbackTerm" then

            WriteToTerminal(
              message.callbackData
            )

            waitForCallbacks = false
            stuckTimeout = os.startTimer(6)
            sleep(5)

            break
        end

    elseif event == "timer" and side == stuckTimeout then
      WriteToTerminal("Timeout Error")
      break
    end

end

os.shutdown()