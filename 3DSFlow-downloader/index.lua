--ihaveamac--
-- https://github.com/ihaveamac/3DSFlow-downloader
version = "dev"
db_list = "http://www.gametdb.com/3dstdb.txt?LANG=ORIG"
res     = System.currentDirectory().."/resources"

-- init stuff
Graphics.init()
dofile(res.."/gui-buttons.lua")

function exit()
    System.exit()
    while true do end
end

function getTimeDateFormatted()
    local hr, mi, sc = System.getTime()
    --noinspection UnusedDef
    local dw, dy, mp, yr = System.getDate()
    return yr.."-"..mp.."-"..dy.."_"..hr.."-"..mi.."-"..sc
end

-- colors
c_white           = Color.new(255, 255, 255)
c_very_light_grey = Color.new(223, 223, 223)
c_light_grey      = Color.new(191, 191, 191)
c_grey            = Color.new(127, 127, 127)
c_dark_grey       = Color.new(63, 63, 63)
c_black           = Color.new(0, 0, 0)

-- logo
logo = Graphics.loadImage(res.."/logo.png")
bg   = Graphics.loadImage(res.."/bg.png")

-- fonts
font_title      = Font.load(res.."/font.ttf")
font_title_bold = Font.load(res.."/font-bold.ttf")
Font.setPixelSizes(font_title, 25)
Font.setPixelSizes(font_title_bold, 25)

-- counter visual glitch
Screen.waitVblankStart()
Screen.refresh()
Screen.clear(TOP_SCREEN)
Screen.clear(BOTTOM_SCREEN)
Screen.flip()

function print(x, y, t, c, s)
    Screen.debugPrint(x+1, y+1, t, c_light_grey, s)
    Screen.debugPrint(x, y, t, c, s)
end

function doDraw(drawfunc, tid)
    Screen.waitVblankStart()
    Screen.refresh()
    Screen.clear(TOP_SCREEN)
    Screen.clear(BOTTOM_SCREEN)
    Graphics.initBlend(TOP_SCREEN)
    Graphics.drawPartialImage(0, 0, 0, 0, 400, 240, bg)
    Graphics.drawPartialImage(5, 5, 0, 0, 128, 45, logo)
    -- Graphics.drawLine is doing something weird...
    --Graphics.fillRect(6, 394, 46, 47, c_dark_grey)
    --Graphics.fillRect(6, 394, 47, 48, c_grey)
    Graphics.termBlend()
    Graphics.initBlend(BOTTOM_SCREEN)
    Graphics.drawPartialImage(0, 0, 40, 240, 320, 240, bg)
    if tid then
        local img = Graphics.loadImage("/gridlauncher/titlebanners/"..tid.."-banner-fullscreen.png")
        Graphics.drawImage(40, 18, img)
        Graphics.freeImage(img)
    end
    Graphics.termBlend()
    Font.print(font_title_bold, 140, 3, "Cover", c_black, TOP_SCREEN)
    Font.print(font_title_bold, 140, 21, "Downloader", c_black, TOP_SCREEN)
    Font.print(font_title, 264, 21, version, c_grey, TOP_SCREEN)
    drawfunc()
    Screen.flip()
    local pad = Controls.read()
    if Controls.check(pad, KEY_SELECT) or tid then
        System.takeScreenshot(System.currentDirectory().."/scr-"..getTimeDateFormatted()..".bmp")
    end
end

-- Button.new(x, y, width, height, text, text x offset, text y offset, font, screen[, color])
get_covers_list_btn = Button.new(20, 20, 280, 30, "Get list of covers", 10, 10, BOTTOM_SCREEN, KEY_A, "A")
exit_btn            = Button.new(20, 190, 280, 30, "Exit", 10, 10, BOTTOM_SCREEN, KEY_B, "B")

--local title_img_s = Screen.createImage(400, 240, Color.new(0, 0, 0, 0))
continue = false
Button.setButtonList({get_covers_list_btn, exit_btn})
repeat
    doDraw(function()
        print(6, 50, "Welcome to the 3DSFlow Banner Downloader!", c_black, TOP_SCREEN)
        print(6, 70, "This will let you download cover banners for", c_black, TOP_SCREEN)
        print(6, 85, "your installed games from GameTDB.", c_black, TOP_SCREEN)
        print(6, 105, "This requires you have mashers's grid", c_black, TOP_SCREEN)
        print(6, 120, "launcher beta 132 or higher.", c_black, TOP_SCREEN)
        print(6, 160, "last_btn: "..tostring(last_btn), c_black, TOP_SCREEN)
        print(6, 175, "Button.checkTouch(): "..tostring(Button.checkTouch()), c_black, TOP_SCREEN)
        Button.draw()
    end)
    local state = Button.checkClick()
    if     state == get_covers_list_btn then continue = true
    elseif state == exit_btn            then exit() end
until continue

doDraw(function()
    print(6, 50, "Getting list of title IDs from GameTDB...", c_black, TOP_SCREEN)
end)

titles = {}
all    = {}
all_l  = 0
needed = {}
need_l = 0
for v in string.gmatch(Network.requestString(db_list), '([^\n]+)') do
    if v:sub(1, 6) ~= "TITLES" then
        titles[v:sub(1, 4)] = {v:sub(8), "BAD-TITLE-ID"}
    end
end
cialist = System.listCIA()
for _, v in pairs(cialist) do
    if v.category == 0 and (v.product_id:sub(1, 4) == "CTR-" or v.product_id:sub(1, 4) == "KTR-") and #v.product_id == 10 and v.mediatype == 1 and titles[v.product_id:sub(7)] then
        -- only Applications
        -- "CTR-X-YYYY" is 10 chars ("CTR-X-YYYY-00" is DLC I think)
        -- "KTR-" is used for New3DS-only titles
        -- only on SDMC (gamecard support will come later)

        -- note that "title_id" is only available in my lpp-3ds mod
        local tid = string.format("%.0f",v.title_id)
        all_l = all_l + 1
        titles[v.product_id:sub(7)][2] = tid
        all[v.product_id:sub(7)] = titles[v.product_id:sub(7)]
        if not System.doesFileExist("/gridlauncher/titlebanners/"..tid.."-banner-fullscreen.png") then
            need_l = need_l + 1
            needed[v.product_id:sub(7)] = titles[v.product_id:sub(7)]
        end
    end
end

download_missing_btn = Button.new(20, 20, 280, 30, "Download missing "..need_l, 10, 10, BOTTOM_SCREEN, KEY_A, "A")
download_all_btn     = Button.new(20, 60, 280, 30, "Download all "..all_l, 10, 10, BOTTOM_SCREEN, KEY_X, "X")

continue = false
titles_to_download = {}
total = 0
Button.setButtonList({download_missing_btn, download_all_btn, exit_btn})
repeat
    doDraw(function()
        print(6, 50, "You are missing "..need_l.." covers.", c_black, TOP_SCREEN)
        print(6, 50, "You are missing "..need_l.." covers.", c_black, TOP_SCREEN)
        Button.draw()
    end)
    local state = Button.checkClick()
    if state == download_missing_btn then
        titles_to_download = needed
        total = need_l
        continue = true
    elseif state == download_all_btn then
        titles_to_download = all
        total = all_l
        continue = true
    elseif state == exit_btn then exit() end
until continue

doDraw(function()
    print(5, 50, "Downloading game covers, sit tight!", c_black, TOP_SCREEN)
    print(5, 70, "0 / "..total, c_black, TOP_SCREEN)
    print(5, 105, "Hold Y to stop.", c_black, TOP_SCREEN)
end)
progress = 0
for k, v in pairs(titles_to_download) do
    --error(tostring(k)..":"..tostring(v[1])..":"..tostring(v[2]))
    local status, _ = pcall(function()
        Network.downloadFile("http://art.gametdb.com/3ds/box/US/"..k..".png", "/gridlauncher/titlebanners/"..v[2].."-banner-fullscreen.png")
        --Network.requestString("http://art.gametdb.com/3ds/box/US/"..k..".png")
    end)
    progress = progress + 1
    if status then
        doDraw(function()
            print(5, 50, "Downloading game covers, sit tight!", c_black, TOP_SCREEN)
            print(5, 70, progress.." / "..total, c_black, TOP_SCREEN)
            print(5, 85, k.." - "..v[1], c_black, TOP_SCREEN)
            print(5, 105, "Hold Y to stop.", c_black, TOP_SCREEN)
        end, v[2])
    else
        doDraw(function()
            print(5, 50, "Downloading game covers, sit tight!", c_black, TOP_SCREEN)
            print(5, 70, progress.." / "..total, c_black, TOP_SCREEN)
            print(5, 85, k.." - "..v[1], c_black, TOP_SCREEN)
            print(5, 105, "Hold Y to stop.", c_black, TOP_SCREEN)
            print(5, 125, "No cover exists for this yet :(", c_black, TOP_SCREEN)
        end)
    end
    if Controls.check(Controls.read(), KEY_Y) then break end
end

Button.setButtonList({exit_btn})
while true do
    doDraw(function()
        if progress == total then
            print(5, 50, "Done downloading!", c_black, TOP_SCREEN)
        else
            print(5, 50, "Stopped.", c_black, TOP_SCREEN)
        end
        print(5, 70, total.." / "..total, c_black, TOP_SCREEN)
        Button.draw()
    end)
    local state = Button.checkClick()
    if state == exit_btn then exit() end
end