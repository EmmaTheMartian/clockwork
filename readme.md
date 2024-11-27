# Clockwork

A language-agnostic build tool wrote to be efficient, easy, and extensible.

> Clockwork is still in beta and is unstable!

View the documentation [here](https://emmathemartian.github.io/clockwork/api.html).

## Installation

### Automatically

There is a Clockwork task to install itself which we can use here. It is
designed for Linux but should work on macOS and WSL.

1. `git clone https://github.com/emmathemartian/clockwork && cd clockwork`
2. `v run . install`
3. Add `~/.local/bin` to your `$PATH` if it is not already there.

### Manually

```sh
$ git clone https://github.com/emmathemartian/clockwork
$ cd clockwork
$ v -prod -o build/main .
# You may already have this folder. You can also forego this and copy the built
# file to another place.
$ mkdir -p ~/.local/bin/
$ cp ./build/main ~/.local/bin/clockwork
# Make Clockwork's global config directory and copy the default config there.
$ mkdir -p ~/.config/clockwork/
$ cp -r ./config/* ~/.config/clockwork/

# Or in one line:
$ git clone https://github.com/emmathemartian/clockwork && cd clockwork && v -prod -o build/main . && mkdir -p ~/.local/bin/ && cp ./build/main ~/.local/bin/ && mkdir -p ~/.config/clockwork/ && cp -r ./plugins ~/.config/clockwork/
```

## Uninstallation

Remove the `~/.local/bin/clockwork` executable and `~/.config/clockwork`

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

> You can also view the documentation [here](https://emmathemartian.github.io/clockwork/api.html).

## License

Clockwork is a tiny little project, so I have decided to license it under both
MIT and the Unlicense. If you want to use the Clockwork source for your own
purposes, utilize whichever license works best for you :D
