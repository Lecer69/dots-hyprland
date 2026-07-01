hl.env("qsConfig", "lis")

-- Apps
terminal = "~/.config/hypr/hyprland/scripts/launch_first_available.sh 'kitty -1' 'foot' 'alacritty' 'wezterm' 'konsole' 'kgx' 'uxterm' 'xterm'"
fileManager = "~/.config/hypr/hyprland/scripts/launch_first_available.sh 'dolphin' 'nautilus' 'nemo' 'thunar' 'kitty -1 fish -c yazi'"
browser = "~/.config/hypr/hyprland/scripts/launch_first_available.sh 'zen-browser' 'brave-origin' 'brave' 'google-chrome-stable' 'firefox' 'chromium' 'microsoft-edge-stable' 'opera' 'librewolf'"
codeEditor = "~/.config/hypr/hyprland/scripts/launch_first_available.sh 'code' 'windsurf' 'antigravity' 'codium' 'cursor' 'zed' 'zedit' 'zeditor' 'kate' 'gnome-text-editor' 'emacs' 'command -v nvim && kitty -1 nvim' 'command -v micro && kitty -1 micro'"
textEditor = "~/.config/hypr/hyprland/scripts/launch_first_available.sh 'command -v nvim && kitty -1 nvim' 'gnome-text-editor' 'emacs' 'kate'"
volumeMixer = "~/.config/hypr/hyprland/scripts/launch_first_available.sh 'pavucontrol-qt' 'pavucontrol'"
taskManager = "~/.config/hypr/hyprland/scripts/launch_first_available.sh 'command -v btop && kitty -1 fish -c btop' 'gnome-system-monitor' 'plasma-systemmonitor --page-name Processes'"

workspaceGroupSize = 10
