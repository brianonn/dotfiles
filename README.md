# Dotfiles

These are my dotfiles.

I've seen so many different ways people try to manage their dotfiles.
Some people like to use python scripts, or a Rakefile and ruby, and
some people are even using unbelievably complex toolsets they (or someone else) has created.

But all you really need is a shell script like this one. This is the
most portable solution, and you can only expect to have a shell
anyways.

## Fast Install

~~~ sh
$ curl -fsSL \ https://raw.githubusercontent.com/brianonn/dotfiles/bootstrap.sh | /bin/sh
~~~

## Install via git clone

~~~ sh
$ cd
$ git clone https://github.com/brianonn/dotfiles.git dotfiles
$ make
~~~

## Features of my dev environment

* templates
* gpg encrypted files for sensitive data
These are
