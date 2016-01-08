--ihaveamac--
-- https://github.com/ihaveamac/3DSFlow-downloader
local version = "dev"
local db_list = "http://www.gametdb.com/3dstdb.txt?LANG=ORIG"
local res     = System.currentDirectory().."/resources"

-- get model and stuff
local sys_t = {"Nintendo 3DS", "Nintendo 3DS XL", "New Nintendo 3DS", "Nintendo 2DS", "New Nintendo 3DS XL" }
-- http://3dbrew.org/wiki/Cfg:GetSystemModel
local model = sys_t[System.getModel() + 1]

local region = "JPN/Other"
local region_num = System.getRegion()
if     region_num == 1 then region = "USA"
elseif region_num == 2 then region = "EUR" end

-- init stuff
Graphics.init()
dofile(res.."/gui-buttons.lua")
System.createDirectory("/gridlauncher")
System.createDirectory("/gridlauncher/titlebanners")

-- local functions, this increases performance
local fprint         = Font.print
local sprint         = Screen.debugPrint
local sclear         = Screen.clear
local sflip          = Screen.flip
local svblank        = Screen.waitVblankStart
local srefresh       = Screen.refresh
local gdrawpartimage = Graphics.drawPartialImage
local ginitblend     = Graphics.initBlend
local gtermblend     = Graphics.termBlend
local gloadimage     = Graphics.loadImage
local gdrawimage     = Graphics.drawImage
local gfreeimage     = Graphics.freeImage
local color          = Color.new
local ccheck         = Controls.check
local cread          = Controls.read
local creadtouch     = Controls.readTouch
local ndownload      = Network.downloadFile
local nstring        = Network.requestString

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

--- Returns HEX representation of num
function num2hex(num)
    local hexstr = '0123456789abcdef'
    local s = ''
    while num > 0 do
        local mod = math.fmod(num, 16)
        s = string.sub(hexstr, mod+1, mod+1) .. s
        num = math.floor(num / 16)
    end
    if s == '' then s = '0' end
    return s
end

-- colors
local c_white           = color(255, 255, 255)
local c_very_light_grey = color(223, 223, 223)
local c_light_grey      = color(191, 191, 191)
local c_grey            = color(127, 127, 127)
local c_dark_grey       = color(63, 63, 63)
local c_black           = color(0, 0, 0)

-- logo
local logo = gloadimage(res.."/logo.png")
local bg   = gloadimage(res.."/bg.png")

-- fonts
local font_title      = Font.load(res.."/font.ttf")
local font_title_bold = Font.load(res.."/font-bold.ttf")
Font.setPixelSizes(font_title, 25)
Font.setPixelSizes(font_title_bold, 25)

-- counter visual glitch
svblank()
srefresh()
sclear(TOP_SCREEN)
sclear(BOTTOM_SCREEN)
sflip()

function print(x, y, t, c, s)
    sprint(x+1, y+1, t, c_light_grey, s)
    sprint(x, y, t, c, s)
end

function doDraw(drawfunc, tid)
    svblank()
    srefresh()
    sclear(TOP_SCREEN)
    sclear(BOTTOM_SCREEN)
    ginitblend(TOP_SCREEN)
    gdrawpartimage(0, 0, 0, 0, 400, 240, bg)
    gdrawpartimage(5, 5, 0, 0, 128, 45, logo)
    -- Graphics.drawLine is doing something weird...
    --Graphics.fillRect(6, 394, 46, 47, c_dark_grey)
    --Graphics.fillRect(6, 394, 47, 48, c_grey)
    gtermblend()
    ginitblend(BOTTOM_SCREEN)
    gdrawpartimage(0, 0, 40, 240, 320, 240, bg)
    if tid then
        local img = gloadimage("/gridlauncher/titlebanners/"..tid.."-banner-fullscreen.png")
        gdrawimage(40, 18, img)
        gfreeimage(img)
    end
    gtermblend()
    fprint(font_title_bold, 140, 3, "Cover", c_black, TOP_SCREEN)
    fprint(font_title_bold, 140, 21, "Downloader", c_black, TOP_SCREEN)
    fprint(font_title, 264, 21, version, c_grey, TOP_SCREEN)
    drawfunc()
    sflip()
    local pad = cread()
    if ccheck(pad, KEY_SELECT) then
        System.takeScreenshot(System.currentDirectory().."/scr-"..getTimeDateFormatted()..".bmp")
    end
end

-- Button.new(x, y, width, height, text, text x offset, text y offset, font, screen[, color])
local get_covers_list_btn = Button.new(20, 20, 280, 30, "Get list of covers", 10, 10, BOTTOM_SCREEN, KEY_A, "A")
local exit_btn            = Button.new(20, 190, 280, 30, "Exit", 10, 10, BOTTOM_SCREEN, KEY_B, "B")

--local title_img_s = Screen.createImage(400, 240, color(0, 0, 0, 0))
local continue = false
Button.setButtonList({get_covers_list_btn, exit_btn})
repeat
    doDraw(function()
        print(6, 50, "Welcome to the 3DSFlow Banner Downloader!", c_black, TOP_SCREEN)
        print(6, 70, "This will let you download cover banners for", c_black, TOP_SCREEN)
        print(6, 85, "your installed games from GameTDB.", c_black, TOP_SCREEN)
        print(6, 105, "This requires you have mashers's grid", c_black, TOP_SCREEN)
        print(6, 120, "launcher beta 132 or higher.", c_black, TOP_SCREEN)
        Button.draw()
    end)
    local state = Button.checkClick()
    if     state == get_covers_list_btn then continue = true
    elseif state == exit_btn            then exit() end
until continue

doDraw(function()
    print(6, 50, "Getting list of title IDs from GameTDB...", c_black, TOP_SCREEN)
end)

local titles = {}
local all    = {}
local all_l  = 0
local needed = {}
local need_l = 0

missing_titles = ""
missing_covers = ""
for v in string.gmatch(nstring(db_list), '([^\n]+)') do
    if v:sub(1, 6) ~= "TITLES" then
        titles[v:sub(1, 4)] = {v:sub(8), "BAD-TITLE-ID"}
    end
end
cialist = System.listCIA()
for _, v in pairs(cialist) do
    if v.category == 0 and (v.product_id:sub(1, 4) == "CTR-" or v.product_id:sub(1, 4) == "KTR-") and #v.product_id == 10 and v.mediatype == 1 then
        -- only Applications
        -- "CTR-X-YYYY" is 10 chars ("CTR-X-YYYY-00" is DLC I think)
        -- "KTR-" is used for New3DS-only titles
        -- only on SDMC (gamecard support will come later)

        -- note that "title_id" is only available in my lpp-3ds mod
        local tid = string.format("%.0f",v.title_id)
        if titles[v.product_id:sub(7)] then
            all_l = all_l + 1
            titles[v.product_id:sub(7)][2] = tid
            titles[v.product_id:sub(7)][3] = num2hex(v.title_id)
            all[v.product_id:sub(7)] = titles[v.product_id:sub(7)]
            if not System.doesFileExist("/gridlauncher/titlebanners/"..tid.."-banner-fullscreen.png") then
                need_l = need_l + 1
                needed[v.product_id:sub(7)] = titles[v.product_id:sub(7)]
            end
        else
            missing_titles = missing_titles.."\n| "..v.product_id.." | "..tid.." | 000"..num2hex(v.title_id)
        end
    end
end

local download_missing_btn = Button.new(20, 20, 280, 30, "Download missing "..need_l, 10, 10, BOTTOM_SCREEN, KEY_A, "A")
local download_all_btn     = Button.new(20, 60, 280, 30, "Download all "..all_l, 10, 10, BOTTOM_SCREEN, KEY_X, "X")

continue = false
local titles_to_download = {}
local total = 0
Button.setButtonList({download_missing_btn, download_all_btn, exit_btn})
repeat
    doDraw(function()
        print(6, 50, "There are "..all_l.." covers you can get.", c_black, TOP_SCREEN)
        print(6, 65, "You are missing "..need_l.." covers.", c_black, TOP_SCREEN)
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

local progress = 0
local downloaded = 0
doDraw(function()
    print(5, 50, "Downloading game covers, sit tight!", c_black, TOP_SCREEN)
    print(5, 70, progress.." / "..total, c_black, TOP_SCREEN)
    print(5, 90, "Game ID:", c_black, TOP_SCREEN)
    print(5, 105, "Title:", c_black, TOP_SCREEN)
    print(5, 120, "TID: ", c_black, TOP_SCREEN)
    print(5, 140, "Hold Y to stop.", c_black, TOP_SCREEN)
end)
for k, v in pairs(titles_to_download) do
    --error(tostring(k)..":"..tostring(v[1])..":"..tostring(v[2]))
    local status, _ = pcall(function()
        ndownload("http://art.gametdb.com/3ds/box/US/"..k..".png", "/gridlauncher/titlebanners/"..v[2].."-banner-fullscreen.png")
        --nstring("http://art.gametdb.com/3ds/box/US/"..k..".png")
    end)
    progress = progress + 1
    if status then
        downloaded = downloaded + 1
        doDraw(function()
            print(5, 50, "Downloading game covers, sit tight!", c_black, TOP_SCREEN)
            print(5, 70, progress.." / "..total, c_black, TOP_SCREEN)
            print(5, 90, "Game ID: "..k, c_black, TOP_SCREEN)
            print(5, 105, "Title: "..v[1], c_black, TOP_SCREEN)
            print(5, 120, "TID: "..v[2], c_black, TOP_SCREEN)
            print(5, 140, "Hold Y to stop.", c_black, TOP_SCREEN)
        end, v[2])
    else
        doDraw(function()
            print(5, 50, "Downloading game covers, sit tight!", c_black, TOP_SCREEN)
            print(5, 70, progress.." / "..total, c_black, TOP_SCREEN)
            print(5, 90, "Game ID: "..k, c_black, TOP_SCREEN)
            print(5, 105, "Title: "..v[1], c_black, TOP_SCREEN)
            print(5, 120, "TID: "..v[2], c_black, TOP_SCREEN)
            print(5, 140, "Hold Y to stop.", c_black, TOP_SCREEN)
            print(5, 160, "No cover exists for this yet :(", c_black, TOP_SCREEN)
        end)
        missing_covers = missing_covers.."\n|  "..k.."  | "..v[2].." | 000"..v[3].." | "..v[1]
    end
    if ccheck(cread(), KEY_Y) then break end
end
local log_file_location = "missing-"..getTimeDateFormatted()..".log"
local log =   "  Missing titles & covers from GameTDB\n"..
        "--------------------------------\n"..
        "- Missing titles\n"..
        "\n"..
        "  NOTE: If you are using Homebrew in .CIA format, some of them might show up in\n"..
        "  this list (for example, CHMM uses \"CTR-P-CHMM\" and BootNTR uses \"CTR-P-BNTR\").\n"..
        "  Please note which ones do this before you report a missing title.\n"..
        "\n".. -- just for organization...
        "| GameID     | TitleID (DEC)    | TitleID (HEX)\n"..
        "|------------|------------------|------------------"..
        missing_titles.."\n"..
        "--------------------------------------------------\n"..
        "- Missing covers\n"..
        "\n"..
        "| GameID | TitleID (DEC)    | TitleID (HEX)    | GameName\n"..
        "|--------|------------------|------------------|----------"..
        missing_covers.."\n"..
        "---------------------------------------------------------\n"..
        "Downloader version: "..version.."\n"..
        "Console model:      "..model.."\n"..
        "Console region:     "..region
local log_file = io.open(System.currentDirectory().."/"..log_file_location, FCREATE)
io.write(log_file, 0, log, #log)
io.close(log_file)
Button.setButtonList({exit_btn})
while true do
    doDraw(function()
        if progress == total then
            print(5, 50, "Done downloading!", c_black, TOP_SCREEN)
        else
            print(5, 50, "Stopped.", c_black, TOP_SCREEN)
        end
        print(5, 70, progress.." / "..total, c_black, TOP_SCREEN)
        print(5, 90, "Downloaded "..downloaded.." covers.", c_black, TOP_SCREEN)
        if #missing_titles > 0 or #missing_covers > 0 then
            print(5, 110, "Some titles didn't exist on GameTDB or didn't", c_black, TOP_SCREEN)
            print(5, 125, "have covers. A log containing what is missing", c_black, TOP_SCREEN)
            print(5, 140, "has been saved to:", c_black, TOP_SCREEN)
            print(5, 160, System.currentDirectory().."/", c_black, TOP_SCREEN)
            print(5, 175, log_file_location, c_black, TOP_SCREEN)
        end
        Button.draw()
    end)
    local state = Button.checkClick()
    if state == exit_btn then exit() end
end