local modem = peripheral.find("modem")
local DISTANCE_REFRESH_INTERVAL = 10
local DIAL_TIMEOUT = 120
local slaveSend = 54385
local slaveRecieve = 54384
local VERSION = "1.0.2"
local gateDB = {}
os.setComputerLabel("PocketDialer v."..VERSION)

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


    --------------------------------------------------
    -- MANUAL DIALING IS ALWAYS FIRST
    --------------------------------------------------

    local manualButton = {}

    manualButton.id = "manual"
    manualButton.name = "MANUAL DIALING"
    manualButton.manual = true

    table.insert(
        buttons,
        manualButton
    )


    --------------------------------------------------
    -- ADD GATE BUTTONS
    --------------------------------------------------

    for id, gate in pairs(gateDB) do

        if not closestToMe
            or id ~= closestToMe.id then
            if gate.public then
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

end


--------------------------------------------------
-- DRAW BUTTON
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

    if button.manual then

        term.setBackgroundColor(
            colors.gray
        )

    else

        term.setBackgroundColor(
            colors.blue
        )

    end

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
    -- BUTTON TEXT
    --------------------------------------------------

    local text =
        button.name


    local maxWidth =
        width - 2


    local lines = {}


    --------------------------------------------------
    -- WORD WRAP
    --------------------------------------------------

    while #text > maxWidth do

        local breakAt = nil


        for i = maxWidth, 1, -1 do

            if text:sub(i, i) == " " then

                breakAt = i

                break

            end

        end


        --------------------------------------------------
        -- No space found
        --------------------------------------------------

        if not breakAt then

            table.insert(
                lines,
                text:sub(
                    1,
                    maxWidth
                )
            )

            text =
                text:sub(
                    maxWidth + 1
                )

        else

            table.insert(
                lines,
                text:sub(
                    1,
                    breakAt - 1
                )
            )

            text =
                text:sub(
                    breakAt + 1
                )

        end

    end


    if #text > 0 then

        table.insert(
            lines,
            text
        )

    end


    --------------------------------------------------
    -- Limit lines to button height
    --------------------------------------------------

    if #lines > height then

        lines =
            {
                unpack(
                    lines,
                    1,
                    height
                )
            }

    end


    --------------------------------------------------
    -- Vertical centering
    --------------------------------------------------

    local firstTextY =
        y
        + math.floor(
            (height - #lines) / 2
        )


    --------------------------------------------------
    -- Draw wrapped text
    --------------------------------------------------

    for lineIndex, line in ipairs(lines) do

        local textX =
            x
            + math.floor(
                (width - #line) / 2
            )


        local textY =
            firstTextY
            + lineIndex


        term.setCursorPos(
            textX,
            textY
        )

        term.write(line)

    end

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
    -- MANUAL DIAL
    --------------------------------------------------

    if type(gateID) == "table" then

        local dialPacket = {}

        dialPacket.type =
            "remoteDial"

        dialPacket.gateInfo = {}

        dialPacket.gateInfo.from = closestToMe.id
            

        dialPacket.gateInfo.to = "manual"
        dialPacket.gateInfo.manualAddress = gateID


        modem.transmit(
            slaveRecieve,
            slaveRecieve,
            dialPacket
        )
        return true

    end


    --------------------------------------------------
    -- NORMAL GATE DIAL
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


    print(
        "Dialing: "
        .. gate.name
    )

    print(
        "Index: "
        .. tostring(idToDial)
    )


    local address =
        gate.address


    --------------------------------------------------
    -- Build packet
    --------------------------------------------------

    local dialPacket = {}

    dialPacket.type =
        "remoteDial"

    dialPacket.gateInfo = {}

    dialPacket.gateInfo.from =
        closestToMe.id

    dialPacket.gateInfo.to =
        idToDial


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
-- MANUAL DIALING
--------------------------------------------------

local function ManualDial()

    local screenWidth,
        screenHeight =
        term.getSize()


    --------------------------------------------------
    -- DRAW CHOICE SCREEN
    --------------------------------------------------

    local function DrawChoiceScreen(errorMessage)

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
            "MANUAL DIALING"


        local titleX =
            math.floor(
                (screenWidth - #title) / 2
            ) + 1


        term.setCursorPos(
            titleX,
            2
        )

        term.write(title)


        --------------------------------------------------
        -- TYPE BUTTON
        --------------------------------------------------

        local buttonWidth = 24
        local buttonHeight = 3

        local buttonX =
            math.floor(
                (screenWidth - buttonWidth) / 2
            ) + 1


        local typeButtonY = 5


        term.setBackgroundColor(
            colors.blue
        )

        term.setTextColor(
            colors.white
        )


        for row = 0, buttonHeight - 1 do

            term.setCursorPos(
                buttonX,
                typeButtonY + row
            )

            term.write(
                string.rep(
                    " ",
                    buttonWidth
                )
            )

        end


        local typeText =
            "TYPE ADDRESS"


        local typeTextX =
            buttonX
            + math.floor(
                (buttonWidth - #typeText) / 2
            )


        local typeTextY =
            typeButtonY
            + 1


        term.setCursorPos(
            typeTextX,
            typeTextY
        )

        term.write(typeText)


        --------------------------------------------------
        -- PASTE BUTTON
        --------------------------------------------------

        local pasteButtonY =
            typeButtonY
            + buttonHeight
            + 1


        term.setBackgroundColor(
            colors.green
        )

        term.setTextColor(
            colors.white
        )


        for row = 0, buttonHeight - 1 do

            term.setCursorPos(
                buttonX,
                pasteButtonY + row
            )

            term.write(
                string.rep(
                    " ",
                    buttonWidth
                )
            )

        end


        local pasteText =
            "PASTE ADDRESS"


        local pasteTextX =
            buttonX
            + math.floor(
                (buttonWidth - #pasteText) / 2
            )


        local pasteTextY =
            pasteButtonY
            + 1


        term.setCursorPos(
            pasteTextX,
            pasteTextY
        )

        term.write(pasteText)


        --------------------------------------------------
        -- ERROR
        --------------------------------------------------

        if errorMessage then

            local errorX =
                math.floor(
                    (screenWidth - #errorMessage) / 2
                ) + 1


            if errorX < 1 then
                errorX = 1
            end


            term.setTextColor(
                colors.red
            )


            term.setCursorPos(
                errorX,
                pasteButtonY
                + buttonHeight
                + 2
            )

            term.write(errorMessage)

        end


        --------------------------------------------------
        -- ESC
        --------------------------------------------------

        local cancelText =
            "Press ESC to cancel"


        local cancelX =
            math.floor(
                (screenWidth - #cancelText) / 2
            ) + 1


        term.setTextColor(
            colors.white
        )


        term.setCursorPos(
            cancelX,
            screenHeight - 1
        )

        term.write(cancelText)


        return {
            typeX1 = buttonX,
            typeX2 = buttonX + buttonWidth - 1,

            typeY1 = typeButtonY,
            typeY2 = typeButtonY + buttonHeight - 1,

            pasteX1 = buttonX,
            pasteX2 = buttonX + buttonWidth - 1,

            pasteY1 = pasteButtonY,
            pasteY2 = pasteButtonY + buttonHeight - 1
        }

    end


    --------------------------------------------------
    -- PARSE PASTED ADDRESS
    --------------------------------------------------

    local function ParseAddress(text)

        if type(text) ~= "string" then

            return nil,
                "Invalid pasted address"

        end


        local digits = {}


        for number in text:gmatch("%d+") do

            local value =
                tonumber(number)


            if value == nil then

                return nil,
                    "Invalid number in address"

            end


            if value < 0
                or value > 38 then

                return nil,
                    "Values must be between 0 and 38"

            end


            table.insert(
                digits,
                value
            )

        end


        --------------------------------------------------
        -- Must contain exactly 9 values
        --------------------------------------------------

        if #digits ~= 9 then

            return nil,
                "Address must contain exactly 9 values"

        end


        return digits

    end


    --------------------------------------------------
    -- TYPE ADDRESS
    --------------------------------------------------

    local function TypeAddress()

        local digits = {}

        local currentInput = ""


        --------------------------------------------------
        -- DRAW TYPING SCREEN
        --------------------------------------------------

        local function DrawTypingScreen(errorMessage)

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
                "MANUAL DIALING"


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
            -- ADDRESS
            --------------------------------------------------

            local addressText = ""


            for i = 1, 9 do

                if digits[i] ~= nil then

                    addressText =
                        addressText
                        .. tostring(
                            digits[i]
                        )

                elseif i == #digits + 1 then

                    addressText =
                        addressText
                        .. "["
                        .. currentInput
                        .. "_]"

                else

                    addressText =
                        addressText
                        .. "[ ]"

                end


                if i < 9 then

                    addressText =
                        addressText
                        .. " "

                end

            end


            local addressX =
                math.floor(
                    (screenWidth - #addressText) / 2
                ) + 1


            if addressX < 1 then
                addressX = 1
            end


            term.setCursorPos(
                addressX,
                3
            )

            term.write(addressText)


            --------------------------------------------------
            -- INSTRUCTIONS
            --------------------------------------------------

            local instruction =
                "Type 0-38, then press ENTER"


            local instructionX =
                math.floor(
                    (screenWidth - #instruction) / 2
                ) + 1


            term.setCursorPos(
                instructionX,
                6
            )

            term.write(instruction)


            --------------------------------------------------
            -- PROGRESS
            --------------------------------------------------

            local progress =
                "Address "
                .. tostring(
                    #digits + 1
                )
                .. " / 9"


            if #digits >= 9 then

                progress =
                    "Address complete"

            end


            local progressX =
                math.floor(
                    (screenWidth - #progress) / 2
                ) + 1


            term.setCursorPos(
                progressX,
                8
            )

            term.write(progress)


            --------------------------------------------------
            -- ERROR
            --------------------------------------------------

            if errorMessage then

                local errorX =
                    math.floor(
                        (screenWidth - #errorMessage) / 2
                    ) + 1


                if errorX < 1 then
                    errorX = 1
                end


                term.setTextColor(
                    colors.red
                )


                term.setCursorPos(
                    errorX,
                    10
                )

                term.write(errorMessage)

            end


            --------------------------------------------------
            -- CANCEL
            --------------------------------------------------

            term.setTextColor(
                colors.white
            )


            local cancelText =
                "Press ESC to cancel"


            local cancelX =
                math.floor(
                    (screenWidth - #cancelText) / 2
                ) + 1


            term.setCursorPos(
                cancelX,
                screenHeight - 1
            )

            term.write(cancelText)


            --------------------------------------------------
            -- CURSOR
            --------------------------------------------------

            local cursorX =
                addressX
                + #addressText


            if cursorX > screenWidth then
                cursorX = screenWidth
            end


            term.setCursorPos(
                cursorX,
                3
            )

        end


        --------------------------------------------------
        -- INITIAL DRAW
        --------------------------------------------------

        DrawTypingScreen()


        --------------------------------------------------
        -- INPUT LOOP
        --------------------------------------------------

        while #digits < 9 do

            local event,
                p1,
                p2,
                p3 =
                os.pullEvent()


            --------------------------------------------------
            -- KEYBOARD CHARACTER
            --------------------------------------------------

            if event == "char" then

                local character =
                    p1


                if character:match("%d") then

                    if #currentInput < 2 then

                        currentInput =
                            currentInput
                            .. character


                        local value =
                            tonumber(
                                currentInput
                            )


                        if value > 38 then

                            currentInput =
                                ""


                            DrawTypingScreen(
                                "Value must be between 0 and 38"
                            )

                        else

                            DrawTypingScreen()

                        end

                    end

                end


            --------------------------------------------------
            -- KEY EVENTS
            --------------------------------------------------

            elseif event == "key" then


                --------------------------------------------------
                -- ENTER
                --------------------------------------------------

                if p1 == keys.enter
                    or p1 == keys.numPadEnter then

                    if currentInput == "" then

                        DrawTypingScreen(
                            "Enter a number from 0 to 38"
                        )

                    else

                        local value =
                            tonumber(
                                currentInput
                            )


                        if value
                            and value >= 0
                            and value <= 38 then

                            table.insert(
                                digits,
                                value
                            )


                            currentInput = ""


                            DrawTypingScreen()

                        else

                            currentInput = ""


                            DrawTypingScreen(
                                "Value must be between 0 and 38"
                            )

                        end

                    end


                --------------------------------------------------
                -- BACKSPACE
                --------------------------------------------------

                elseif p1 == keys.backspace then

                    currentInput =
                        currentInput:sub(
                            1,
                            #currentInput - 1
                        )


                    DrawTypingScreen()


                --------------------------------------------------
                -- ESC
                --------------------------------------------------

                elseif p1 == keys.esc then

                    return nil

                end

            end

        end


        --------------------------------------------------
        -- ADDRESS COMPLETE
        --------------------------------------------------

        return digits

    end


    --------------------------------------------------
    -- CHOICE SCREEN
    --------------------------------------------------

    local choiceButtons =
        DrawChoiceScreen()


    --------------------------------------------------
    -- CHOICE LOOP
    --------------------------------------------------

    while true do

        local event,
            p1,
            p2,
            p3 =
            os.pullEvent()


        --------------------------------------------------
        -- ESC
        --------------------------------------------------

        if event == "key"
            and p1 == keys.esc then

            return nil

        end


        --------------------------------------------------
        -- BUTTON CLICK
        --------------------------------------------------

        if event == "mouse_click" then

            local x =
                p2

            local y =
                p3


            --------------------------------------------------
            -- TYPE ADDRESS
            --------------------------------------------------

            if x >= choiceButtons.typeX1
                and x <= choiceButtons.typeX2
                and y >= choiceButtons.typeY1
                and y <= choiceButtons.typeY2 then


                local digits =
                    TypeAddress()


                if digits then

                    term.setBackgroundColor(
                        colors.black
                    )

                    term.setTextColor(
                        colors.white
                    )

                    term.clear()

                    term.setCursorPos(
                        1,
                        1
                    )


                    print(
                        "Manual address:"
                    )

                    print(
                        textutils.serialize(
                            digits
                        )
                    )


                    DialGate(
                        digits
                    )


                    return digits

                else

                    choiceButtons =
                        DrawChoiceScreen()

                end


            --------------------------------------------------
            -- PASTE ADDRESS
            --------------------------------------------------

            elseif x >= choiceButtons.pasteX1
                and x <= choiceButtons.pasteX2
                and y >= choiceButtons.pasteY1
                and y <= choiceButtons.pasteY2 then


                --------------------------------------------------
                -- Show paste instructions
                --------------------------------------------------

                term.setBackgroundColor(
                    colors.black
                )

                term.setTextColor(
                    colors.white
                )

                term.clear()


                local title =
                    "PASTE ADDRESS"


                local titleX =
                    math.floor(
                        (screenWidth - #title) / 2
                    ) + 1


                term.setCursorPos(
                    titleX,
                    2
                )

                term.write(title)


                local instruction =
                    "Paste the address now"


                local instructionX =
                    math.floor(
                        (screenWidth - #instruction) / 2
                    ) + 1


                term.setCursorPos(
                    instructionX,
                    5
                )

                term.write(instruction)

                local instruction =
                    "Example:"


                local instructionX =
                    math.floor(
                        (screenWidth - #instruction) / 2
                    ) + 1


                term.setCursorPos(
                    instructionX,
                    7
                )

                term.write(instruction)


                local example =
                    "-18-21-15-31-5-10-29-7-0-"


                local exampleX =
                    math.floor(
                        (screenWidth - #example) / 2
                    ) + 1


                if exampleX < 1 then
                    exampleX = 1
                end


                term.setCursorPos(
                    exampleX,
                    9
                )

                term.write(example)


                local cancelText =
                    "Press ESC to cancel"


                local cancelX =
                    math.floor(
                        (screenWidth - #cancelText) / 2
                    ) + 1


                term.setCursorPos(
                    cancelX,
                    screenHeight - 1
                )

                term.write(cancelText)


                --------------------------------------------------
                -- WAIT FOR PASTE
                --------------------------------------------------

                while true do

                    local pasteEvent,
                        pasteData =
                        os.pullEvent()


                    --------------------------------------------------
                    -- PASTE
                    --------------------------------------------------

                    if pasteEvent == "paste" then

                        local digits,
                            errorMessage =
                            ParseAddress(
                                pasteData
                            )


                        if digits then

                            --------------------------------------------------
                            -- Valid address
                            --------------------------------------------------

                            term.setBackgroundColor(
                                colors.black
                            )

                            term.setTextColor(
                                colors.white
                            )

                            term.clear()

                            term.setCursorPos(
                                1,
                                1
                            )


--[[                             print(
                                "Pasted address:"
                            )

                            print(
                                textutils.serialize(
                                    digits
                                )
                            )
 ]]

                            DialGate(
                                digits
                            )


                            return digits

                        else

                            --------------------------------------------------
                            -- Invalid address
                            --------------------------------------------------

                            term.setBackgroundColor(
                                colors.black
                            )

                            term.setTextColor(
                                colors.red
                            )

                            term.clear()


                            local errorX =
                                math.floor(
                                    (
                                        screenWidth
                                        - #errorMessage
                                    ) / 2
                                ) + 1


                            if errorX < 1 then
                                errorX = 1
                            end


                            term.setCursorPos(
                                errorX,
                                5
                            )

                            term.write(
                                errorMessage
                            )


                            term.setTextColor(
                                colors.white
                            )


                            local retryText =
                                "Press ESC to cancel"


                            local retryX =
                                math.floor(
                                    (
                                        screenWidth
                                        - #retryText
                                    ) / 2
                                ) + 1


                            term.setCursorPos(
                                retryX,
                                screenHeight - 1
                            )

                            term.write(retryText)

                        end


                    --------------------------------------------------
                    -- ESC
                    --------------------------------------------------

                    elseif pasteEvent == "key"
                        and pasteData == keys.esc then

                        choiceButtons =
                            DrawChoiceScreen()

                        break

                    end

                end

            end

        end

    end

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
        -- CLOSEST GATE
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
        -- DRAW BUTTONS
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


        return pageStart,
            pageEnd,
            previousButton,
            nextButton

    end


    --------------------------------------------------
    -- START REFRESH TIMER
    --------------------------------------------------

    local refreshTimer =
        os.startTimer(
            DISTANCE_REFRESH_INTERVAL
        )


    --------------------------------------------------
    -- START TIMEOUT
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


        local event,
            p1,
            p2,
            p3 =
            os.pullEvent()


        --------------------------------------------------
        -- DISTANCE REFRESH
        --------------------------------------------------

        if event == "timer"
            and p1 == refreshTimer then


            local oldClosestID =
                closestToMe
                and closestToMe.id
                or nil


            local oldClosestDistance =
                closestToMe
                and closestToMe.distance
                or nil


            local newClosestGate =
                FindClosestGate()


            if not newClosestGate then

                NoCloseGates()

                return

            end


            local newClosestID =
                newClosestGate
                and newClosestGate.id
                or nil


            local newClosestDistance =
                closestToMe
                and closestToMe.distance
                or nil


            local closestChanged = false


            if oldClosestID ~= newClosestID then

                closestChanged = true

            end


            if oldClosestDistance ~= newClosestDistance then

                closestChanged = true

            end


            if closestChanged then

                BuildButtons()


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


            refreshTimer =
                os.startTimer(
                    DISTANCE_REFRESH_INTERVAL
                )


        --------------------------------------------------
        -- TIMEOUT
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
        -- TOUCH
        --------------------------------------------------

        elseif event == "mouse_click" then

            local x = p2
            local y = p3


            local button =
                GetButtonAt(
                    x,
                    y,
                    pageStart,
                    pageEnd
                )


            --------------------------------------------------
            -- BUTTON PRESSED
            --------------------------------------------------

            if button then

                --------------------------------------------------
                -- MANUAL DIALING
                --------------------------------------------------

                if button.manual then

                    local result =
                        ManualDial()


                    if result then

                        return result

                    end

                else

                    --------------------------------------------------
                    -- NORMAL GATE
                    --------------------------------------------------

                    local gateID =
                        button.id


                    local gate =
                        gateDB[gateID]


                    local address =
                        gate.address


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


                    term.setBackgroundColor(
                        colors.black
                    )

                    term.clear()

                    term.setCursorPos(
                        1,
                        1
                    )


                    DialGate(
                        gateID
                    )


                    return gateID

                end

            end


            --------------------------------------------------
            -- PREVIOUS
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
            -- NEXT
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
-- SHOW MENU
--------------------------------------------------

GateMenu()


--------------------------------------------------
-- WRITE TO TERMINAL
--------------------------------------------------

local function WriteToTerminal(data)

    local width, height =
        term.getSize()


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
    -- Word-wrap
    --------------------------------------------------

    local function WrapText(text)

        local result = {}


        while #text > width do

            local breakAt = nil


            for i = width, 1, -1 do

                if text:sub(i, i) == " " then

                    breakAt = i

                    break

                end

            end


            if not breakAt then

                table.insert(
                    result,
                    text:sub(
                        1,
                        width
                    )
                )

                text =
                    text:sub(
                        width + 1
                    )

            else

                table.insert(
                    result,
                    text:sub(
                        1,
                        breakAt - 1
                    )
                )

                text =
                    text:sub(
                        breakAt + 1
                    )

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
    -- Clear
    --------------------------------------------------

    term.setBackgroundColor(
        colors.black
    )

    term.setTextColor(
        colors.white
    )

    term.clear()


    --------------------------------------------------
    -- Center vertically
    --------------------------------------------------

    local startY =
        math.floor(
            (height - #lines) / 2
        ) + 1


    if startY < 1 then

        startY = 1

    end


    --------------------------------------------------
    -- Draw
    --------------------------------------------------

    for i, line in ipairs(lines) do

        local y =
            startY + i - 1


        if y > height then

            break

        end


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


--------------------------------------------------
-- WAIT FOR CALLBACKS
--------------------------------------------------

local waitForCallbacks = true

local stuckTimeout =
    os.startTimer(5)


while waitForCallbacks do

    local event,
        side,
        channel,
        replyChannel,
        message,
        distance =
        os.pullEvent()


    if event == "modem_message"
        and channel == slaveRecieve
        and message.type then


        if message.type == "dialerCallback" then

            if message.id == closestToMe.id then

                WriteToTerminal(
                    message.callbackData
                )

                stuckTimeout =
                    os.startTimer(5)

            end


        elseif message.type == "dialerCallbackTerm" then

            WriteToTerminal(
                message.callbackData
            )

            waitForCallbacks = false

            stuckTimeout =
                os.startTimer(6)

            sleep(5)

            break

        end


    elseif event == "timer"
        and side == stuckTimeout then

        WriteToTerminal(
            "Timeout Error"
        )

        break

    end

end


os.shutdown()
