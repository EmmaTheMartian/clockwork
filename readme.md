# clockwork

A language-agnostic build tool wrote to be efficient, easy, and extensible.

## Installation

### Linux

On Linux there is a Clockwork task to install itself which we can use here.

1. `v run . install`
2. Add `~/.local/bin` to your `$PATH` if it is not already there.
3. Yeah that's it.

### Other OSes

I am not familiar with other operating systems and their CLIs, so I do not have
installation tasks for them (yet). Here are the commands on Unix based systems
to build and install Clockwork manually.

```sh
$ v -prod -o build/main .
$ mkdir -p ~/.local/bin/
$ cp ./build/main ~/.local/bin/
$ mkdir -p ~/.config/clockwork/
$ cp -r ./plugins ~/.config/clockwork/

# Or in one line:
$ v -prod -o build/main . && mkdir -p ~/.local/bin/ && cp ./build/main ~/.local/bin/ && mkdir -p ~/.config/clockwork/ && cp -r ./plugins ~/.config/clockwork/
```

The commands should be mostly the same on Windows

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

## License

Clockwork is a tiny little project, so I have decided to license it under both
MIT and the Unlicense. If you want to use the Clockwork source for your own
purposes, utilize whichever license works best for you :D
