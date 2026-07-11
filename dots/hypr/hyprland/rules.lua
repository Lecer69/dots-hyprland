-- ######## Window rules ########

-- Disable blur for xwayland context menus
hl.window_rule({match = {class = "^()$", title = "^()$" }, no_blur = true })

-- Disable blur for every window
hl.window_rule({match = {class = ".*" }, no_blur = true })

-- Shadow
-- uncomment this for applying opacity on every window
-- hl.window_rule({match = {class = ".*" }, opacity = 0.92 })
hl.window_rule({match = {class = "^(org.kde.gwenview|wpsoffice|zen|brave-browser|brave-origin|firefox|chromium|vlc|com.obsproject.Studio|steam|org.gnome.SystemMonitor)$" }, opacity = 1.0 })
hl.window_rule({match = {fullscreen = true }, opacity = 1.0})
hl.window_rule({match = {title = ".*\\.exe" }, opacity = 1.0})

-- Floating
hl.window_rule({match = {title = "^(Open File)(.*)$" },                       center = true})
hl.window_rule({match = {title = "^(Open File)(.*)$" },                       float = true})
hl.window_rule({match = {title = "^(Select a File)(.*)$" },                   center = true})
hl.window_rule({match = {title = "^(Select a File)(.*)$" },                   float = true})
hl.window_rule({match = {title = "^(Choose wallpaper)(.*)$" },                center = true})
hl.window_rule({match = {title = "^(Choose wallpaper)(.*)$" },                float = true})
hl.window_rule({match = {title = "^(Choose wallpaper)(.*)$" },                size = {"(monitor_w*0.60)", "(monitor_h*0.65)"} })
hl.window_rule({match = {title = "^(Open Folder)(.*)$" },                     center = true})
hl.window_rule({match = {title = "^(Open Folder)(.*)$" },                     float = true})
hl.window_rule({match = {title = "^(Save As)(.*)$" },                         center = true})
hl.window_rule({match = {title = "^(Save As)(.*)$" },                         float = true})
hl.window_rule({match = {title = "^(Library)(.*)$" },                         center = true})
hl.window_rule({match = {title = "^(Library)(.*)$" },                         float = true})
hl.window_rule({match = {title = "^(File Upload)(.*)$" },                     center = true})
hl.window_rule({match = {title = "^(File Upload)(.*)$" },                     float = true})
hl.window_rule({match = {title = "^(.*)(wants to save)$" },                   center = true})
hl.window_rule({match = {title = "^(.*)(wants to save)$" },                   float = true})
hl.window_rule({match = {title = "^(.*)(wants to open)$" },                   center = true})
hl.window_rule({match = {title = "^(.*)(wants to open)$" },                   float = true})
hl.window_rule({match = {class = "^(blueberry\\.py)$" },                      float = true})
hl.window_rule({match = {class = "^(guifetch)$" },                            float = true}) -- FlafyDev/guifetch
hl.window_rule({match = {class = "^(pavucontrol)$" },                         float = true})
hl.window_rule({match = {class = "^(pavucontrol)$" },                         size = {"(monitor_w*0.45)", "(monitor_h*0.45)"} })
hl.window_rule({match = {class = "^(pavucontrol)$" },                         center = true})
hl.window_rule({match = {class = "^(org.pulseaudio.pavucontrol)$" },          float = true})
hl.window_rule({match = {class = "^(org.pulseaudio.pavucontrol)$" },          size = {"(monitor_w*0.45)", "(monitor_h*0.45)"} })
hl.window_rule({match = {class = "^(org.pulseaudio.pavucontrol)$" },          center = true})
hl.window_rule({match = {class = "^(nm-connection-editor)$" },                float = true})
hl.window_rule({match = {class = "^(nm-connection-editor)$" },                size = {"(monitor_w*0.45)", "(monitor_h*0.45)"} })
hl.window_rule({match = {class = "^(nm-connection-editor)$" },                center = true})
hl.window_rule({match = {class = ".*plasmawindowed.*" },                      float = true})
hl.window_rule({match = {class = "kcm_.*" },                                  float = true})
hl.window_rule({match = {class = "^(org.kde.gwenview)$" },                    float = true})
hl.window_rule({match = {class = "^(org.kde.gwenview)$" },                    size = {"(monitor_w*0.60)", "(monitor_h*0.65)"}})
hl.window_rule({match = {class = "^(pavucontrol-qt)$" },                      float = true})
hl.window_rule({match = {class = ".*bluedevilwizard" },                       float = true})
hl.window_rule({match = {title = ".*Welcome" },                               float = true})
hl.window_rule({match = {title = "^(illogical-impulse Settings)$" },          float = true})
hl.window_rule({match = {title = ".*Shell conflicts.*" },                     float = true})
hl.window_rule({match = {class = "org.kde.ksecretd" },                        float = true})
hl.window_rule({match = {class = "org.gnome.SystemMonitor" },                 float = true})
hl.window_rule({match = {class = "org.freedesktop.impl.portal.desktop.kde" }, float = true})
hl.window_rule({match = {class = "org.freedesktop.impl.portal.desktop.kde" }, size = {"(monitor_w*0.60)", "(monitor_h*0.65)"} })
hl.window_rule({match = {class = "^(Zotero)$" },                              float = true})
hl.window_rule({match = {class = "^(Zotero)$" },                              size = {"(monitor_w*0.45)", "(monitor_h*0.45)"} })

-- Move
hl.window_rule({match = {class = "^(plasma-changeicons)$" }, float = true})
hl.window_rule({match = {class = "^(plasma-changeicons)$" }, no_initial_focus = true})
hl.window_rule({match = {class = "^(plasma-changeicons)$" }, move = {999999, 999999}})

-- Dolphin copy
hl.window_rule({match = {title = "^(Copying — Dolphin)$" }, move = {40, 80}})

-- Tiling
hl.window_rule({match = {class = "^dev\\.warp\\.Warp$" }, tile = true})
hl.window_rule({match = {class = "^Minecraft.*$" }, tile = true})

-- Picture-in-Picture
hl.window_rule({match = {title = "^([Pp]icture[-\\s]?[Ii]n[-\\s]?[Pp]icture)(.*)$" }, float = true})
hl.window_rule({match = {title = "^([Pp]icture[-\\s]?[Ii]n[-\\s]?[Pp]icture)(.*)$" }, keep_aspect_ratio = true})
hl.window_rule({match = {title = "^([Pp]icture[-\\s]?[Ii]n[-\\s]?[Pp]icture)(.*)$" }, move = {"(monitor_w*0.73)", "(monitor_h*0.72)"} })
hl.window_rule({match = {title = "^([Pp]icture[-\\s]?[Ii]n[-\\s]?[Pp]icture)(.*)$" }, size = {"(monitor_w*0.25)", "(monitor_h*0.25)"} })
hl.window_rule({match = {title = "^([Pp]icture[-\\s]?[Ii]n[-\\s]?[Pp]icture)(.*)$" }, float = true})
hl.window_rule({match = {title = "^([Pp]icture[-\\s]?[Ii]n[-\\s]?[Pp]icture)(.*)$" }, pin = true})

-- Screen sharing
hl.window_rule({match = {title = ".*is sharing (a window|your screen).*" }, float = true})
hl.window_rule({match = {title = ".*is sharing (a window|your screen).*" }, pin = true})
hl.window_rule({match = {title = ".*is sharing (a window|your screen).*" }, no_blur = true})
hl.window_rule({match = {title = ".*is sharing (a window|your screen).*" }, move = {"(monitor_w*.5-window_w*.5)", "(monitor_h-window_h-12)"} })

-- Steam
hl.window_rule({match = {title = "^(Add Non-Steam Game)(.*)$" }, center = true})
hl.window_rule({match = {title = "^(Add Non-Steam Game)(.*)$" }, float = true})

-- Tearing
hl.window_rule({match = {title = ".*\\.exe" }, immediate = true})
hl.window_rule({match = {title = ".*minecraft.*" }, immediate = true})
hl.window_rule({match = {class = "^(steam_app).*" }, immediate = true})

-- Special window
hl.workspace_rule({ workspace = "special:special", gaps_out = 24 })

-- ######## Layer rules ########
hl.layer_rule({ match = { namespace = "hyprpicker" }, no_anim = true})
hl.layer_rule({ match = { namespace = "hyprpaper" }, no_anim = true})
hl.layer_rule({ match = { namespace = "gtk4-layer-shell" }, no_anim = true})
hl.layer_rule({ match = { namespace = "quickshell:polkitagent" }, no_anim = true})
hl.layer_rule({ match = { namespace = "quickshell:osubackdrop" }, no_anim = true})
hl.layer_rule({ match = { namespace = "quickshell:media" }, no_anim = true})
