--ihaveamac--
-- https://github.com/ihaveamac/3DSFlow-downloader
version       = "dev6"
db_list       = "http://www.gametdb.com/3dstdb.txt?LANG=ORIG"
res           = "romfs:/resources"
settings_path = System.currentDirectory().."/settings.cfg"

-- get model and stuff
sys_t = {"Nintendo 3DS", "Nintendo 3DS XL", "New Nintendo 3DS", "Nintendo 2DS", "New Nintendo 3DS XL"}
-- http://3dbrew.org/wiki/Cfg:GetSystemModel
model = sys_t[System.getModel() + 1]

-- console region (not the same as country)
region = "JPN/Other"
region_num = System.getRegion()
if     region_num == 1 then region = "USA"
elseif region_num == 2 then region = "EUR" end

-- cover regions
-- USA is "US", JPN is "JP", and these two probably won't change
eur_cover_regions = {
    -- if it's set up like ["AA"] = "AA" then the order will be randomized
    {"EN", "England"},
    {"FR", "France"},
    {"DE", "Germany"},
    {"ES", "Spain"},
    {"IT", "Italy"},
    {"PT", "Portugal"},
    {"NL", "Netherlands"},
    {"SE", "Sweden"},
    {"DK", "Denmark"},
    {"FI", "Finland"},
    {"NO", "Norway"},
    {"AU", "Australia"},
    {"RU", "Russia"}
    --{"TR", "Turkey"} -- not seen on the 3DS so far
}
--[[
    I noticed that game product codes (CTR-X-XXXX) end in something that determines the region:
    - "E" is USA (so "US")
    - "J" is JPN (so "JP")
    - "P" are EUR (so any of the above)
    - "A" is region-free, which might only apply to eShop content (e.g. ORAS special demo, or digital Pokémon XYORAS?)
      in this case, determine cover based on console region + preferred region if EUR
    - "Z" appears mostly with EUR, but I was told it also appears with some USA games, so treating it as "A"
    - "W" is Taiwan (so "ZH")
    - "R" is Russia, which is odd, apparently some games have a Russia-specific code separate from EUR

      these are the only ones I found. but if there's more, I'm going to assume EUR for now
 ]]

eur_cover_region_option = 1 -- default
local settings_file
if System.doesFileExist(settings_path) then
    dofile(System.currentDirectory().."/settings.cfg")
    settings_file = io.open(settings_path, FWRITE)
else
    settings_file = io.open(settings_path, FCREATE)
end
local settings_file_d = "eur_cover_region_option = "..eur_cover_region_option
io.write(settings_file, 0, settings_file_d, settings_file_d:len() + 1)
io.close(settings_file)

-- ignored product codes. these should only be homebrew. not complete but it's a start
-- use the four-letter code (YYYY) in CTR-X-YYYY
ignored_codes = {
    "CTAP", -- generic code for system content, also 3DS Quick Reboot
    "STDN", -- 3DS Quick Shutdown
    "CHMM", -- CHMM/CHMM2
    "BNTR", -- BootNTR
    "CTRX", -- CTRXplorer
    "3FTP", -- ftbrony
    "NASA", -- NASA
    "SSHL", -- Sunshell
    "MGBA", -- mGBA
    "CFBI", -- FBI
    "EDIT",
    "3DSC",
    "DEVM", -- Dev Menu?
    "SAVE",
    "COIN", -- Play Coin Setter?
    ""
}
function isIgnored(key)
    for _, v in pairs(ignored_codes) do
        if v == key:sub(7) then return true end
    end
    return false
end

-- init stuff
Graphics.init()
dofile(res.."/gui-buttons.lua")
System.createDirectory("/gridlauncher")
System.createDirectory("/gridlauncher/titlebanners")
System.createDirectory(System.currentDirectory().."/logs")

-- local functions, this increases performance
local fload          = Font.load
local funload        = Font.unload
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
    gfreeimage(logo)
    gfreeimage(bg)
    funload(font_title)
    funload(font_title_bold)
    System.exit()
    while true do end
end

function getTimeDateFormatted()
    local hr, mi, sc = System.getTime()
    if hr < 10 then hr = "0"..hr end
    if mi < 10 then mi = "0"..mi end
    if sc < 10 then sc = "0"..sc end
    local _, dy, mo, yr = System.getDate()
    if mo < 10 then mo = "0"..mo end
    if dy < 10 then dy = "0"..dy end
    return yr.."-"..mo.."-"..dy.."_"..hr.."-"..mi.."-"..sc
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
c_white           = color(255, 255, 255)
c_very_light_grey = color(223, 223, 223)
c_light_grey      = color(191, 191, 191)
c_grey            = color(127, 127, 127)
c_dark_grey       = color(63, 63, 63)
c_black           = color(0, 0, 0)

-- logo
logo = gloadimage(res.."/logo.png")
bg   = gloadimage(res.."/bg.png")

-- fonts
font_title      = fload(res.."/font.ttf")
font_title_bold = fload(res.."/font-bold.ttf")
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
    if tid and System.doesFileExist("/gridlauncher/titlebanners/"..tid.."-banner-fullscreen.png") then
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

-- settings for cover region
region_buttons_code = {}
region_buttons = {}
yoffset = 0
btn = 0
for k, v in pairs(eur_cover_regions) do
    if (k % 2 == 0) then -- even
        btn = Button.new(165, 10 + (yoffset * 32), 145, 30, v[2], 10, 10, BOTTOM_SCREEN)
        yoffset = yoffset + 1 -- even ones appear on the right and that means the next one should be on the next line
    else -- odd
        btn = Button.new(10, 10 + (yoffset * 32), 145, 30, v[2], 10, 10, BOTTOM_SCREEN)
    end
    table.insert(region_buttons, btn)
    region_buttons_code[btn] = k
end
function showSettings()
    Button.setButtonList(region_buttons)
    repeat
        doDraw(function()
            print(6, 50, "For European-region games, pick your", c_black, TOP_SCREEN)
            print(6, 65, "preferred region.", c_black, TOP_SCREEN)
            print(6, 80, "This primarily changes the rating system on", c_black, TOP_SCREEN)
            print(6, 95, "the game cover.", c_black, TOP_SCREEN)
            --[[if region_choice then
                print(6, 115, tostring(region_choice)..": "..region_buttons_code[region_choice], c_black, TOP_SCREEN)
            end]]
            Button.draw()
        end)
        region_choice = Button.checkClick()
    until region_choice -- until it's not "false"
    local settings_file = io.open(settings_path, FWRITE)
    eur_cover_region_option = region_buttons_code[region_choice]
    local settings_file_d = "eur_cover_region_option = "..eur_cover_region_option
    io.write(settings_file, 0, settings_file_d, settings_file_d:len() + 1)
    io.close(settings_file)
    --exit()
end

-- Button.new(x, y, width, height, text, text x offset, text y offset, font, screen[, color])
get_covers_list_btn = Button.new(20, 20, 280, 30, "Get list of covers", 10, 10, BOTTOM_SCREEN, KEY_A, "A")
settings_btn        = Button.new(20, 60, 280, 30, "Europe cover region settings", 10, 10, BOTTOM_SCREEN)
exit_btn            = Button.new(20, 190, 280, 30, "Exit", 10, 10, BOTTOM_SCREEN, KEY_B, "B")

--local title_img_s = Screen.createImage(400, 240, color(0, 0, 0, 0))
local continue = false
Button.setButtonList({get_covers_list_btn, settings_btn, exit_btn})
repeat
    doDraw(function()
        print(6, 50, "Welcome to the 3DSFlow Banner Downloader!", c_black, TOP_SCREEN)
        print(6, 70, "This will let you download cover banners for", c_black, TOP_SCREEN)
        print(6, 85, "your installed games from GameTDB.", c_black, TOP_SCREEN)
        print(6, 105, "This requires you have mashers's grid", c_black, TOP_SCREEN)
        print(6, 120, "launcher beta 132 or higher.", c_black, TOP_SCREEN)
        print(30, 100, "Current preference:", c_dark_grey, BOTTOM_SCREEN)
        print(30, 115, eur_cover_regions[eur_cover_region_option][2], c_dark_grey, BOTTOM_SCREEN)
        Button.draw()
    end)
    local state = Button.checkClick()
    if     state == get_covers_list_btn then continue = true
    elseif state == settings_btn        then
        showSettings()
        Button.setButtonList({get_covers_list_btn, settings_btn, exit_btn})
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

missing_titles = ""
missing_covers = ""
for v in string.gmatch(nstring(db_list), '([^\n]+)') do
    if v:sub(1, 6) ~= "TITLES" then
        titles[v:sub(1, 4)] = {v:sub(8), "BAD-TITLE-ID"}
    end
end
cialist = System.listCIA()
for k, v in pairs(cialist) do
    if v.category == 0 and (v.product_id:sub(1, 4) == "CTR-" or v.product_id:sub(1, 4) == "KTR-") and #v.product_id == 10 and v.mediatype == 1 and not isIgnored(v.product_id) then
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

download_missing_btn = Button.new(20, 20, 280, 30, "Download missing "..need_l, 10, 10, BOTTOM_SCREEN, KEY_A, "A")
download_all_btn     = Button.new(20, 60, 280, 30, "Download all "..all_l, 10, 10, BOTTOM_SCREEN, KEY_X, "X")

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

progress = 0
downloaded = 0
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
    local cover_region
    if k:sub(4) == "E" then
        cover_region = "US"
    elseif k:sub(4) == "J" then
        cover_region = "JP"
    elseif k:sub(4) == "K" then
        cover_region = "KO"
    elseif k:sub(4) == "W" then
        cover_region = "ZH"
    elseif k:sub(4) == "R" then
        cover_region = "RU"
    elseif k:sub(4) == "A" or k:sub(4) == "Z" then
        -- apparently Z is used for some non-EUR games as well
        if region_num == 1 then -- USA console
            cover_region = "US"
        elseif region_num == 2 then
            cover_region = eur_cover_regions[eur_cover_region_option][1]
        else
            cover_region = "JP"
        end
    else
        cover_region = eur_cover_regions[eur_cover_region_option][1]
    end
    local try_en_on_fail = (cover_region ~= "US" and cover_region ~= "JP" and cover_region ~= "EN")
    -- this contains "EN" so it won't try it twice if it fails
    System.deleteFile("/gridlauncher/titlebanners/"..v[2].."-banner-fullscreen.png")
    local status
    status = pcall(function()
        local code = ndownload("http://art.gametdb.com/3ds/box/"..cover_region.."/"..k..".png", "/gridlauncher/titlebanners/"..v[2].."-banner-fullscreen.png")
        if code ~= 200 then error() end
    end)
    if try_en_on_fail and not status then
        -- try England (EN) if region preference boxart fails
        status = pcall(function()
            local code = ndownload("http://art.gametdb.com/3ds/box/EN/"..k..".png", "/gridlauncher/titlebanners/"..v[2].."-banner-fullscreen.png")
            if code ~= 200 then error() end
        end)
    end
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
local log =
        "  Missing titles & covers from GameTDB\n"..
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
        "Downloader version:       "..version.."\n"..
        "Europe cover region pref: "..eur_cover_regions[eur_cover_region_option][1].."/"..eur_cover_regions[eur_cover_region_option][2].."\n"..
        "Console model:            "..model.."\n"..
        "Console region:           "..region
log_file = io.open(System.currentDirectory().."/logs/"..log_file_location, FCREATE)
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
            print(5, 160, System.currentDirectory().."/logs/", c_black, TOP_SCREEN)
            print(5, 175, log_file_location, c_black, TOP_SCREEN)
        end
        Button.draw()
    end)
    local state = Button.checkClick()
    if state == exit_btn then exit() end
end