-- put former exec-once commands inside the func and former exec commands outside
hl.on("hyprland.start", function ()

    -- Bar, wallpaper
    hl.exec_cmd("ON_HYPRSTART=true qs -c lis")
    hl.exec_cmd("hyprpaper")

    hl.exec_cmd("dbus-update-activation-environment --all")
    hl.exec_cmd("sleep 1 && dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP") -- Some fix idk

    -- Clipboard: history
    hl.exec_cmd("wl-paste --watch cliphist store")
    hl.exec_cmd("wl-paste --type text --watch bash -c 'cliphist store'")
    hl.exec_cmd("wl-paste --type image --watch bash -c 'cliphist store'")

    -- Cursor
    hl.exec_cmd("hyprctl setcursor Bibata-Modern-Classic 24")
end)
