# Clockwork

A language-agnostic build tool wrote to be efficient, easy, and extensible.

> Clockwork is still in beta and is unstable!

View the documentation [here](https://emmathemartian.github.io/clockwork/).

## Installation

### Automatically

There is a script to install Clockwork which we can use here.

`v download -RD https://raw.githubusercontent.com/EmmaTheMartian/clockwork/refs/heads/main/scripts/install.vsh`

This script will install Clockwork for your user. It will be cloned to
`~/.local/share/clockwork/`.

### Manually

```sh
$ git clone --recurse-submodules https://github.com/emmathemartian/clockwork ~/.local/share/clockwork
$ cd clockwork
$ v -prod -o build/clockwork .
$ ln -s ./build/clockwork ~/.local/bin/clockwork
```

## Uninstallation

Remove the `~/.local/bin/clockwork` symlink and `~/.local/share/clockwork`

## Updating

To update just the Clockwork executable: `clockwork --update`

## Basic Rundown

Make a file called `build.maple` in your project's root. Populate it with the
following:

```maple
config:msg = 'Hello, World!'

task:hello = {
	run = 'echo "${msg}"'
}
```

Then run `clockwork hello` to see `Hello, World!` in the terminal.

> For a proper example, see the `example/` directory.

> You can also view the documentation [here](https://emmathemartian.github.io/clockwork/).

## License

Clockwork is a tiny little project, so I have decided to license it under both
MIT and the Unlicense. If you want to use the Clockwork source for your own
purposes, utilize whichever license works best for you :D
