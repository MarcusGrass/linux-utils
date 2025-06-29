# If not running interactively, don't do anything
[[ $- != *i* ]] && return

export VISUAL=nvim
export EDITOR="$VISUAL"
export TERM=xterm-256color
export COLORTERM=truecolor
export ANDROID_HOME="$HOME/Android/Sdk"
export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$PATH:$HOME/misc/flutter/flutter/bin:$ANDROID_HOME:$ANDROID_HOME/tools:$ANDROID_HOME/tools/bin:$ANDROID_HOME/platform-tools:$HOME/.pub-cache/bin:$HOME/go/bin:$HOME/misc/zig/zig-linux-x86_64-0.11.0"
export XDG_DATA_DIRS="$XDG_DATA_DIRS:$HOME/.local/share/flatpak/exports/share:/var/lib/flatpak/exports/share"
export XDG_CACHE_HOME="$HOME/.cache/"
export XZ_DEFAULTS="-T0"
export HELIX_RUNTIME="$HOME/code/rust/helix/runtime"

### --- History settings ---
export HISTCONTROL=ignoreboth:erasedups
### Unlimited history
export HISTSIZE=
export HISTFILESIZE=
export HISTFILE="$HOME/.bash_hist_unlimited"

# System
alias off='doas /sbin/shutdown -h now'
alias reboot='doas /sbin/reboot'

# Convenience
alias vim='nvim'
alias dirsize='du -hs * | sort -hr'
alias nvim_edit='nvim ~/.config/nvim/init.vim'
alias bash_edit='nvim ~/.bashrc'
alias pacman='sudo pacman'
alias ls='ls -lah --color=auto'
alias lock='xscreensaver-command -lock'
alias xclip='xclip -se c'
alias ss='maim -s -u | xclip -selection clipboard -t image/png -i'
alias flux_night='redshift -x >> /dev/null && redshift -O 2000 >> /dev/null'
alias flux_off='redshift -x >> /dev/null'
alias steam='flatpak run com.valvesoftware.Steam'

# Git
alias git_reset_main='git fetch origin && git reset --hard origin/main'
alias git_rebase_main='git fetch origin && git rebase -i origin/main'
alias git_merge_ff='git merge --ff-only'

# Set up fzf completions
eval "$(fzf --bash)"

# PS1='[\u@\h $PWD]\$ '

export PS1="\[\e[01;32m\][\u@\h\[\e[m\] \[\e[01;34m\]\$PWD]#\[\e[m\] "
