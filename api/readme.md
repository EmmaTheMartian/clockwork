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

> Tasks **must** be prefixed using `task:` and config values **must** be
> prefixed using `config:`, otherwise Clockwork will not read them.

```maple
// Import other maple files, excluding the `.maple` extension. It will always
// search for files in this order:
//   - Local files (./some_plugin.maple)
//   - Global files (~/.config/plugins/some_plugin.maple)
//   - Global install (git-managed) files (~/.local/share/clockwork/config/plugins/some_plugin.maple)
// If all else fails, an error is thrown.
plugins ([]string)

// Allows you to configure how Clockwork displays its data. For the most part
// you should not use this, but some projects do prefer hiding some data or
// changing defaults. These settings are for said projects.
display (map) = {
	// The category to list tasks of when using `clockwork --tasks`.
	// No value means list all tasks.
	default_task_category (string)

	// How tasks should be listed in `clockwork --tasks`.
	// Values: `verbose` (default), `slim`
	default_task_list_mode (string)

	// A list of categories to exclude fron `clockwork --tasks`.
	task_list_exclude_categories ([]string)

	// A list of tasks to exclude fron `clockwork --tasks`.
	task_list_exclude_tasks ([]string)
}

// Declare a variable/configuration option.
config:[name] (string)

// Define a task. All fields within are optional.
task:[name] (map) = {
	// A help message for the task, displayed with `clockwork --tasks`
	help (string)

	// A category for the task, displayed with `clockwork --tasks`
	category (string)

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
	run = 'v scripts/some_complex_task.vsh'
}
```

## Naming Scheme

Tasks and config values should use `snake_case` with periods (`.`) to denote a
"variant" and using colons (`:`) for "namespaces."

Example for a "variant:" `build` vs `build.prod`

Example for a "namespace:" `clockwork:update`

> Neither Maple or Clockwork support actual namespacing, so if you do want to
> separate your tasks or configs, you can prefix them with `something:`.

### Distribution for Projects

Clockwork is licensed very permissively, so if you want to you can just...
include Clockwork with your project's source.

Although for most people, you do not want one Clockwork install per project, so
there are two options for this:

1. Include the install command in the readme for developers to copy and paste:

	`v download -RD https://raw.githubusercontent.com/EmmaTheMartian/clockwork/refs/heads/main/scripts/install.vsh`

2. Include the installation script (`scripts/install.vsh`) in your project.

	I would just throw this script into a `scripts` folder and name it
	`install-clockwork.vsh` or something. Contributors will only need to use
	it once and Clockwork will be installed.
