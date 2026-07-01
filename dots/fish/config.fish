fish_add_path $HOME/.local/bin

function fish_prompt -d "Write out the prompt"
    printf '%s@%s %s%s%s > ' $USER $hostname \
        (set_color $fish_color_cwd) (prompt_pwd) (set_color normal)
end

if status is-interactive

    set fish_greeting
    starship init fish | source

    alias ls 'eza --icons'
    alias lls 'eza -lah --icons --group-directories-first'
    alias h 'sudo ncdu /'
    alias u 'sudo pacman -Syu'
    alias c 'clear & fish'

end