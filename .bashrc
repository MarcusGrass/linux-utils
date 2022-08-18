#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

export VISUAL=nvim
export EDITOR="$VISUAL"
export TERM=xterm-256color
export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$PATH"
export XDG_CONFIG_HOME="$HOME/.config"
shopt -s cdspell
# System
alias off='shutdown -h now'
alias hibernate='systemctl hibernate'

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

# Git
alias git_reset_main='git fetch origin && git reset --hard origin/main'
alias git_rebase_main='git fetch origin && git rebase -i origin/main'
alias git_merge_ff='git merge --ff-only'

# Java
alias j15='sudo archlinux-java set java-15-openjdk'
alias j11='sudo archlinux-java set java-11-openjdk'
alias j8='sudo archlinux-java set java-8-openjdk'
alias mci='mvn clean install'
alias mcc='mvn clean compile'
alias mgs='mvn generate-sources'

# Idk what this is, probably shouldn't remove
PS1='[\u@\h \W]\$ '
