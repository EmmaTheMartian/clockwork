## Description

After [installing](https://github.com/EmmaTheMartian/clockwork#Installation)
Clockwork, you can use it in a project by first creating a `build.maple` in the
root of your codebase. Then, populate it with your plugins, configs, and tasks.

Here is an example config for a V project:

```maple
plugins = [ 'v' ]

task:doc = {
	help = 'Runs v doc for the API'
	run = 'v doc -m -f html -o doc/ api/'
}

task:clean_build = {
	help = 'Clean-builds the project'
	depends = [ 'clean', 'build' ]
}

task:release = {
	help = 'Bumps the version and builds the project in prod mode'
	run = [
		'v bump --minor v.mod',
		'v -prod build .'
	]
}
```

### Config Specification

Config files are wrote in [Maple](https://github.com/emmathemartian/maple), a
TOML-like config language made to be simple and fast to write in.

> The parenthesis represent the type of the value. Text in \[brackets\]
> represent text to be substituted with something else.

```maple
// Import other maple files, excluding the `.maple` extension. It will always
// search for files in this order:
//   - Local files (./some_plugin.maple)
//   - Global files (~/.config/plugins/some_plugin.maple)
//   - Global install (git-managed) files (~/.local/share/clockwork/config/plugins/some_plugin.maple)
// If all else fails, an error is thrown.
plugins ([]string)

// Declare a variable/configuration option.
config:[name] (string)

// Define a task. All fields within are optional.
task:[name] (map) = {
	// A help message for the task, displayed with `clockwork --tasks`
	help (string)

	// A list of tasks that this one depends on. These are executed in the
	// same order they are defined. Duplicate entries are allowed.
	depends ([]string)

	// Allows you to define a custom working directory for this task.
	work_dir (string)

	// The command(s) to run. These are executed in your shell.
	run (string or []string)
}
```

### Complex Tasks

For a task that may need more complex behaviour, you can use a `.vsh` file in
another folder. For example:

```vsh
// scripts/some_complex_task.vsh

println('Pretend this is really complex')
```

And in your config:

```maple
// build.maple

task:some_complex_task = {
	help = 'A really complex task'
	run = 'v scripts/some_complex_task.vsh`
}
```
