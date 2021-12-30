#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

export VISUAL=nvim
export EDITOR="$VISUAL"
export PATH="$HOME/.local/bin:$PATH"
shopt -s cdspell
# System
alias off='shutdown -h now'

# Convenience
alias sudo='doas'
alias em='doas emerge -a'
alias syu='doas emerge --sync && doas emerge --quiet -avDN @world'
alias ls='ls --color=auto'
alias xclip='xclip -se c'
# alias ssh='. code/arch_config/bash/ssh.sh'
alias ss='maim -s -u | xclip -selection clipboard -t image/png -i'
alias sstatus='doas systemctl status'
alias srestart='doas systemctl restart'

# Bluetooth
alias bt='doas bluetoothctl'
alias bt_re='doas /bin/bash /home/gramar/code/arch_config/bash/bt_clear.sh'
alias bt_con='doas bluetoothctl -- connect 4C:87:5D:2C:57:6A'
alias bt_dc='doas bluetoothctl -- disconnect 4C:87:5D:2C:57:6A'

# Git
alias git_reset_main='git fetch origin && git reset --hard origin/main'
alias git_rebase_main='git fetch origin && git rebase -i origin/main'
alias git_merge_ff='git merge --ff-only'

PS1='[\u@\h \W]\$ '
