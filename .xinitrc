#!/bin/sh

userresources=$HOME/.Xresources
usermodmap=$HOME/.Xmodmap
sysresources=/etc/X11/xinit/.Xresources
sysmodmap=/etc/X11/xinit/.Xmodmap

# merge in defaults and keymaps

if [ -f $sysresources ]; then
    xrdb -merge $sysresources
fi

if [ -f $sysmodmap ]; then
    xmodmap $sysmodmap
fi

if [ -f "$userresources" ]; then
    xrdb -merge "$userresources"

fi

if [ -f "$usermodmap" ]; then
    xmodmap "$usermodmap"
fi

# start some nice programs

if [ -d /etc/X11/xinit/xinitrc.d ] ; then
 for f in /etc/X11/xinit/xinitrc.d/?*.sh ; do
  [ -x "$f" ] && . "$f"
 done
 unset f
fi

eval `dbus-launch --sh-syntax`
# Gpg agent hangs a lot and wont die, and we need it to be dead before we start
pkill -9 gpg-agent 
eval `gpg-agent --daemon`

setxkbmap se
# autorandr home
# twm&
# xclock -geometry 50x50-1+1&
# xrandr monitor setup
# evolution&
# google-chrome-stable&
# intellij-idea-ultimate-edition&
xscreensaver&
firefox&
slack&
spotify&
# zoom&
pavucontrol&
feh --bg-fill $HOME/pictures/wps/wpbg.jpg || echo "Failed to set background with feh"
# Intellij needs this
export _JAVA_AWT_WM_NONREPARENTING=1
export AWT_TOOLKIT=MToolkit
wmname LG3D
# Run
exec pgwm
