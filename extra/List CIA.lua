-- Don't include http://
url = "www.gametdb.com/3dstdb.txt?LANG=ORIG"

c_white = Color.new(255, 255, 255)
sys_t = {"Nintendo 3DS", "Nintendo 3DS XL", "New Nintendo 3DS", "Nintendo 2DS", "New Nintendo 3DS XL"}

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

Screen.waitVblankStart()
Screen.refresh()
Screen.clear(TOP_SCREEN)
Screen.debugPrint(5, 5, "Downloading Nintendo 3DS titles", c_white, TOP_SCREEN)
Screen.flip()

titles_str = Network.requestString("http://"..url)

Screen.waitVblankStart()
Screen.refresh()
Screen.clear(TOP_SCREEN)
Screen.debugPrint(5, 5, "Separating IDs and titles in 3dstdb.txt", c_white, TOP_SCREEN)
Screen.flip()

titles = {}
for v in string.gmatch(titles_str, '([^\n]+)') do
    if v:sub(1, 6) ~= "TITLES" then
        titles[v:sub(1, 4)] = v:sub(8)
    end
end

Screen.waitVblankStart()
Screen.refresh()
Screen.clear(TOP_SCREEN)
Screen.debugPrint(5, 5, "Listing installed CIAs", c_white, TOP_SCREEN)
Screen.flip()

thing = System.listCIA()
-- each table consists of: unique_id, mediatype, platform, product_id, access_id, category
-- categories: 0 = Application, 1 = System, 2 = Demo, 3 = Patch, 4 = TWL (Nintendo DS[i])
-- my lpp-3ds mod adds title_id

Screen.waitVblankStart()
Screen.refresh()
Screen.clear(TOP_SCREEN)
Screen.debugPrint(5, 5, "Writing to file", c_white, TOP_SCREEN)
Screen.flip()

System.deleteFile(System.currentDirectory().."/Installed CIAs.txt")
f = io.open(System.currentDirectory().."/Installed CIAs.txt", FCREATE)
to_write = ""
listed = 0
for _, v in pairs(thing) do
    if v.category == 0 and v.product_id:sub(1, 4) == "CTR-" and #v.product_id == 10 and v.mediatype == 1 then
        -- only Applications
        -- "CTR-X-YYYY" is 10 chars ("CTR-X-YYYY-00" is DLC I think)
        -- only on SDMC
        listed = listed + 1
        local title = "(name unavailable)"
        if titles[v.product_id:sub(7)] then
            title = titles[v.product_id:sub(7)]
        end
        to_write = to_write.."\n"..v.product_id.." - "..string.format("%.0f",v.title_id).." - "..title
    end
end
to_write = "\t\t\t\t-- Installed games --"..
        "\nUsing "..url..
        "\n\nTotal listed:              "..listed..
        "\nTotal, including unlisted: "..#thing..
        "\nSystem type:               "..sys_t[System.getModel()+1]..
        "\n------------------------------"..to_write..
        "\n------------------------------"..
        "\n\n\t\t\t\t--       END       --"
io.write(f, 0, to_write, #to_write)
io.close(f)

Screen.waitVblankStart()
Screen.refresh()
Screen.clear(TOP_SCREEN)
Screen.debugPrint(5, 5, "Done! Look for \"Installed CIAs.txt\" at:", c_white, TOP_SCREEN)
Screen.debugPrint(5, 20, System.currentDirectory(), c_white, TOP_SCREEN)
Screen.debugPrint(5, 40, "B: Exit", c_white, TOP_SCREEN)
Screen.flip()

repeat until Controls.check(Controls.read(), KEY_B)
System.exit()
