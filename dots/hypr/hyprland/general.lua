hl.gesture({
    fingers = 3,
    direction = "swipe",
    action = "move"
})
hl.gesture({
    fingers = 3,
    direction = "pinch",
    action = "fullscreen"
})
hl.gesture({
    fingers = 4,
    direction = "horizontal",
    action = "workspace"
})
hl.gesture({
    fingers = 4,
    direction = "up",
    action = function()
        hl.dispatch(hl.dsp.global("quickshell:launcherToggle"))
    end
})
hl.gesture({
    fingers = 4,
    direction = "down",
    action = function()
        hl.dispatch(hl.dsp.global("quickshell:launcherToggle"))
    end
})

hl.config({
    gestures = {
        workspace_swipe_distance = 700,
        workspace_swipe_cancel_ratio = 0.2,
        workspace_swipe_min_speed_to_force = 5,
        workspace_swipe_direction_lock = true,
        workspace_swipe_direction_lock_threshold = 10,
        workspace_swipe_create_new = true
    },
    general = {
        -- Gaps and border
        gaps_in = 4,
        gaps_out = 8,
        gaps_workspaces = 4,

        border_size = 0,
        resize_on_border = true,
        no_focus_fallback = true,
        allow_tearing = true,

        col = {
            active_border = "rgba(0DB7D455)",
            inactive_border = "rgba(31313600)"
        },

        snap = {
            enabled = true,
            window_gap = 4,
            monitor_gap = 5,
            respect_gaps = true
        }
    },
    decoration = {
        rounding_power = 3,
        rounding = 12,

        blur = {
            enabled = false,
            -- xray = true,
            -- special = false,
            -- new_optimizations = true,
            -- size = 10,
            -- passes = 3,
            -- brightness = 1,
            -- noise = 0.05,
            -- contrast = 0.89,
            -- vibrancy = 0.5,
            -- vibrancy_darkness = 0.5,
            -- popups = false,
            -- popups_ignorealpha = 0.6,
            -- input_methods = true,
            -- input_methods_ignorealpha = 0.8
        },
        shadow = {
            enabled = true,
            range = 12,
            offset = {0, 2},
            render_power = 5,
            color = "rgba(10, 10, 10, 0.5)"

        },
        -- Dim
        dim_inactive = true,
        dim_strength = 0.08,
        dim_special = 0.8,
        dim_around = 0
    },
    animations = {
        enabled = true
    },
    dwindle = {
        preserve_split = true,
        smart_split = false,
        smart_resizing = true,
        precise_mouse_move = true
    },
})

-- Curves
hl.curve("expressiveFastSpatial", {
  type = "bezier",
  points = { { 0.42, 1.4 }, { 0.21, 0.90 } }
})
hl.curve("expressiveDefaultSpatial", {
  type = "bezier",
  points = { { 0.38, 1.15 }, { 0.22, 1.00 } }
})

-- Snappy decel/accel pair
hl.curve("emphasizedDecel", {
  type = "bezier",
  points = { { 0.05, 0.7 }, { 0.1, 1 } }
})
hl.curve("emphasizedAccel", {
  type = "bezier",
  points = { { 0.3, 0 }, { 0.8, 0.15 } }
})

-- Linear-ish
hl.curve("quick", {
  type = "bezier",
  points = { { 0.33, 0 }, { 0.67, 1 } }
})
hl.curve("standardDecel", {
  type = "bezier",
  points = { { 0, 0 }, { 0, 1 } }
})
hl.curve("silky", {
  type = "bezier",
  points = { { 0.65, 0 }, { 0.35, 1 } }
})

-- Menu in/out pair
hl.curve("menuDecel", {
  type = "bezier",
  points = { { 0.1, 1 }, { 0.3, 1 } }
})
hl.curve("menuAccel", {
  type = "bezier",
  points = { { 0.5, 0.02 }, { 0.7, 0.06 } }
})

-- Global
hl.animation({
  leaf = "global",
  enabled = true,
  speed = 6,
  bezier = "emphasizedDecel"
})

-- Windows
hl.animation({
  leaf = "windowsIn",
  enabled = true,
  speed = 3.2,
  bezier = "emphasizedDecel",
  style = "popin 90%"
})
hl.animation({
  leaf = "windowsOut",
  enabled = true,
  speed = 2.2,
  bezier = "emphasizedAccel",
  style = "popin 90%"
})
hl.animation({
  leaf = "windowsMove",
  enabled = true,
  speed = 3.2,
  bezier = "silky",
  style = "slide"
})
hl.animation({
  leaf = "fadeIn",
  enabled = true,
  speed = 2.4,
  bezier = "quick"
})
hl.animation({
  leaf = "fadeOut",
  enabled = true,
  speed = 1.8,
  bezier = "quick"
})
hl.animation({
  leaf = "border",
  enabled = true,
  speed = 3,
  bezier = "emphasizedDecel"
})

-- Layers
hl.animation({
  leaf = "layersIn",
  enabled = true,
  speed = 2.6,
  bezier = "emphasizedDecel",
  style = "popin 92%"
})
hl.animation({
  leaf = "layersOut",
  enabled = true,
  speed = 1.6,
  bezier = "menuAccel",
  style = "popin 92%"
})
hl.animation({
  leaf = "fadeLayersIn",
  enabled = true,
  speed = 2.2,
  bezier = "menuDecel"
})
hl.animation({
  leaf = "fadeLayersOut",
  enabled = true,
  speed = 1.4,
  bezier = "menuAccel"
})

-- Workspaces
hl.animation({
  leaf = "workspaces",
  enabled = true,
  speed = 3,
  bezier = "menu_decel",
  style = "slidefade 50%"
})

-- special
hl.animation({
  leaf = "specialWorkspaceIn",
  enabled = true,
  speed = 3,
  bezier = "emphasizedDecel",
  style = "slidevert"
})
hl.animation({
  leaf = "specialWorkspaceOut",
  enabled = true,
  speed = 2,
  bezier = "emphasizedAccel",
  style = "slidevert"
})

-- Misc
hl.animation({
  leaf = "zoomFactor",
  enabled = true,
  speed = 2.4,
  bezier = "standardDecel"
})

hl.config({
    input = {
        kb_layout = "us",
        numlock_by_default = true,
        repeat_delay = 200,
        repeat_rate = 35,

        follow_mouse = 1,
        off_window_axis_events = 2,
        accel_profile = flat,

        touchpad = {
            natural_scroll = true,
            disable_while_typing = false,
            clickfinger_behavior = true,
            scroll_factor = 1
        }
    },

    misc = {
        disable_hyprland_logo = true,
        disable_splash_rendering = true,
        vrr = 0,
        mouse_move_enables_dpms = true,
        key_press_enables_dpms = true,
        animate_manual_resizes = false,
        animate_mouse_windowdragging = false,
        enable_swallow = false,
        swallow_regex = "(foot|kitty|allacritty|Alacritty)",
        on_focus_under_fullscreen = 2,
        allow_session_lock_restore = true,
        session_lock_xray = true,
        initial_workspace_tracking = false,
        focus_on_activate = true,
        render_unfocused_fps = 5
    },

    binds = {
        scroll_event_delay = 0,
        hide_special_on_workspace_change = true
    },

    cursor = {
        zoom_factor = 1,
        zoom_rigid = false,
        zoom_disable_aa = true,
        no_hardware_cursors = 0,
        hotspot_padding = 1
    },

    ecosystem = {
        no_donation_nag = true
    },

    render = {
        direct_scanout = true
    },

    xwayland = {
        force_zero_scaling = true
    }
})

hl.device({
    name = "opentabletdriver-virtual-artist",
    output = "HDMI-A-1" -- Your main monitor for tablet driver
})