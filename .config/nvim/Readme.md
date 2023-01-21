# Guide for not breaking the CFG
## On update deps
Check that cfg works and save a snap
## On changing plugin cfg
Make sure that the snap with compatible cfg is saved
## On install 
Symlink the files from this directory to `~/.config/nvim` to make risk of local edits not being synced lower. 
