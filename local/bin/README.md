## local/bin

This file contains source for simple shell scripts, python scripts or even go scripts :)

This directory is the ultimate source of truth for my ~/.local/bin directory and each of these files will be symlinked
into my ~/.local/bin

Since other 3rd partys, and github installers, etc often install directly into ~/.local/bin, I must not just copy this
entire directory over or symlink at the top-level (i.e. ~/.local/bin -> this/path/bin )

Instead, the setup script at the root of this dotfiles repo will symlink all files from there to here.
