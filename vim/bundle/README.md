## Pathogen Bundles for vim

There are pathogen bundles.

When you want to install a new bundle, use

```shell
$ git submodule add <path to github>
$ git commit -m 'added pathogen module <name>'
```

This will reference it in the file `.gitmodules` and then it can be recursively cloned from the top-level dotfiles clone command, using the ` git clone --recursive` command.  Aternatively, all the vim pathogen submodules can be installed using the `git submodule init` and `git submodule update` commands.
