hl.config({
    general = {
        col = {
            active_border   = "rgba(a08c8777)",
            inactive_border = "rgba(53433f55)",
        },
    },
    misc = {
        background_color = "rgba(1a110fFF)",
    },
})

hl.window_rule({ -- not sure how to syntax "pin 1"
    match        = { pin = 1 },
    border_color = "rgba(ffb59eAA) rgba(ffb59e77)",
})
