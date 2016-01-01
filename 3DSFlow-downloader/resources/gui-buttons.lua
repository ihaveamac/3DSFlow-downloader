--
-- Created by IntelliJ IDEA.
-- User: ianburgwin
-- Date: 12/30/15
-- Time: 8:10 PM
-- To change this template use File | Settings | File Templates.
--

buttons = {}
--  1: x position
--  2: y position
--  3: width
--  4: height
--  5: text
--  6: text x offset
--  7: text y offset
--  8: screen
--  9: button variable
-- 10: button text
last_btn = false
current_btns = {}

Button = {}

-- screen is kinda pointless since the buttons only work with touch,
-- therefore only working w/ BOTTOM_SCREEN
-- I might add support for selecting buttons with D-Pad though
function Button.new(x, y, w, h, t, txo, tyo, s, bv, bt)
    if not (x and y and w and h and t and txo and tyo and s) then
        error("wrong number of arguments (Button.new)")
    end
    table.insert(buttons, {x, y, w, h, t, txo, tyo, s, bv, bt})
    return #buttons
end

function Button.setButtonList(list)
    for _, v in pairs(list) do
        if not buttons[v] then
            error("invalid button id given")
        end
    end
    current_btns = list
end

function Button.checkClick()
    local pad = Controls.read()
    if Controls.check(pad, KEY_TOUCH) then
        Button.checkTouch()
        return false
    else
        for _, v in pairs(current_btns) do
            if buttons[v][9] then
                if Controls.check(pad, buttons[v][9]) then
                    Button.checkTouch()
                    return false
                end
            end
        end
    end
    if last_btn then
        local tmp_last_btn = last_btn
        last_btn = false
        return tmp_last_btn
    end
    return false
end

function Button.checkTouch()
    local pad = Controls.read()
    --[[if not Controls.check(pad, KEY_TOUCH) then
        return false
    end]]
    local tx, ty = Controls.readTouch()
    for _, v in pairs(current_btns) do
        if Controls.check(pad, KEY_TOUCH) then
            if tx >= buttons[v][1] and tx <= buttons[v][1] + buttons[v][3] and ty >= buttons[v][2] and ty <= buttons[v][2] + buttons[v][4] then
                last_btn = v
                return v
            else
                last_btn = false
            end
        elseif buttons[v][9] then
            if Controls.check(pad, buttons[v][9]) then
                last_btn = v
                return v
            end
        end
    end
    return false
end

function Button.draw()
    for _, v in pairs(current_btns) do
        local t = buttons[v][5]
        if buttons[v][10] then
            t = "("..buttons[v][10]..") "..t
        end
        if Button.checkTouch() == v then
            Screen.fillRect(buttons[v][1],
                buttons[v][1] + buttons[v][3] - 1,
                buttons[v][2] + 1,
                buttons[v][2] + buttons[v][4] - 1,
                c_very_light_grey,
                buttons[v][8])
            Screen.drawLine(buttons[v][1],
                buttons[v][1] + buttons[v][3] - 1,
                buttons[v][2] + buttons[v][4],
                buttons[v][2] + buttons[v][4],
                c_dark_grey,
                buttons[v][8])
            Screen.debugPrint(buttons[v][1] + buttons[v][6],
                buttons[v][2] + buttons[v][7] + 1,
                t,
                c_black,
                buttons[v][8])
            if buttons[v][10] then
                Screen.debugPrint(buttons[v][1] + buttons[v][6],
                    buttons[v][2] + buttons[v][7] + 1,
                    "("..buttons[v][10]..")",
                    c_dark_grey,
                    buttons[v][8])
            end
        else
            Screen.fillRect(buttons[v][1],
                buttons[v][1] + buttons[v][3] - 1,
                buttons[v][2],
                buttons[v][2] + buttons[v][4] - 2,
                c_white,
                buttons[v][8])
            Screen.drawLine(buttons[v][1],
                buttons[v][1] + buttons[v][3] - 1,
                buttons[v][2] + buttons[v][4] - 1,
                buttons[v][2] + buttons[v][4] - 1,
                c_dark_grey,
                buttons[v][8])
            Screen.drawLine(buttons[v][1],
                buttons[v][1] + buttons[v][3] - 1,
                buttons[v][2] + buttons[v][4],
                buttons[v][2] + buttons[v][4],
                c_grey,
                buttons[v][8])
            Screen.debugPrint(buttons[v][1] + buttons[v][6],
                buttons[v][2] + buttons[v][7],
                t,
                c_dark_grey,
                buttons[v][8])
            if buttons[v][10] then
                Screen.debugPrint(buttons[v][1] + buttons[v][6],
                    buttons[v][2] + buttons[v][7],
                    "("..buttons[v][10]..")",
                    c_grey,
                    buttons[v][8])
            end
        end
    end
end

--[[
function Button.draw()
    for _, v in pairs(current_btns) do
        if Button.checkTouch() == v then
            Screen.fillRect(buttons[v][1],
                buttons[v][1] + buttons[v][3] - 1,
                buttons[v][2] + 2,
                buttons[v][2] + buttons[v][4],
                c_light_grey,
                buttons[v][8])
            Screen.debugPrint(buttons[v][1] + buttons[v][6],
                buttons[v][2] + buttons[v][7] + 2,
                buttons[v][5],
                c_black,
                buttons[v][8])
        else
            Screen.fillRect(buttons[v][1],
                buttons[v][1] + buttons[v][3] - 1,
                buttons[v][2],
                buttons[v][2] + buttons[v][4] - 2,
                buttons[v][9],
                buttons[v][8])
            Screen.drawLine(buttons[v][1],
                buttons[v][1] + buttons[v][3] - 1,
                buttons[v][2] + buttons[v][4] - 1,
                buttons[v][2] + buttons[v][4] - 1,
                c_dark_grey,
                buttons[v][8])
            Screen.drawLine(buttons[v][1],
                buttons[v][1] + buttons[v][3] - 1,
                buttons[v][2] + buttons[v][4],
                buttons[v][2] + buttons[v][4],
                c_grey,
                buttons[v][8])
            Screen.debugPrint(buttons[v][1] + buttons[v][6],
                buttons[v][2] + buttons[v][7],
                buttons[v][5],
                c_dark_grey,
                buttons[v][8])
        end
    end
end
]]