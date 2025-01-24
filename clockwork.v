module main

import api
import api.maple
import log
import os
import flag

@[xdoc: 'usage: clockwork [options] TASKS [task arguments]\n\nTo run multiple tasks, you can separate them by commas (eg: `clockwork fmt,build.prod,test`)']
@[name: 'clockwork']
@[version: version]
struct Flags {
	// Info
	version       bool   @[short: v; xdoc: 'Show version and exit']
	help          bool   @[short: h; xdoc: 'Show help and exit']
	vars          bool   @[short: a; xdoc: 'Show variables and exit']
	tasks         bool   @[short: t; xdoc: 'Show tasks and exit']
	list_mode     string @[long: 'list-mode'; xdoc: 'How to list tasks (`verbose` or `slim`). Defaults to `verbose`']
	list_category string @[long: 'list-category'; xdoc: 'The category to list tasks from. Defaults to \'\' (all)']
	debug_context bool   @[short: d; xdoc: 'Print the stringified context and exit. Intended for debugging purposes']
	// Functionality
	no_task_args bool @[short: T; xdoc: 'Prevents task arguments from being passed to tasks']
	no_global    bool @[short: G; xdoc: 'Disable loading global.maple']
	no_local     bool @[short: L; xdoc: 'Disable loading build.maple']
	no_plugins   bool @[short: P; xdoc: 'Disable loading any plugins']
	update       bool @[long: update; xdoc: 'Shorthand for `clockwork -L clockwork.update`']
	init         bool @[long: init; xdoc: 'Shorthand for `clockwork -L clockwork.init`']
	new          bool @[long: new; xdoc: 'Shorthand for `clockwork -L clockwork.new`']
}

fn main() {
	mut logger := log.Log{}
	logger.set_output_stream(os.stdout())
	logger.set_custom_time_format('hh:mm:ss')
	logger.set_level(.debug)
	log.set_logger(logger)

	// Make the global config directory if it does not exist
	if !os.exists(api.global_data_dir) {
		os.mkdir_all(api.global_data_dir) or {
			log.error('Failed to create global config directory: ${api.global_data_dir} (error: ${err})')
			exit(1)
		}
	}

	// Parse arguments
	mut clockwork_args := []string{}
	mut tasks := []string{}
	mut task_args := []string{}

	for arg in os.args[1..] {
		if tasks.len == 0 && arg.starts_with('-') {
			clockwork_args << arg
		} else if tasks.len == 0 && !arg.starts_with('-') {
			tasks = arg.split(',')
		} else {
			task_args << arg
		}
	}

	// Parse Clockwork arguments
	args, no_matches := flag.to_struct[Flags](clockwork_args) or {
		log.error('Failed to parse arguments (error: ${err})')
		exit(1)
	}
	if no_matches.len > 0 {
		log.error('Invalid flags: ${no_matches}')
		exit(1)
	}

	// If --update, --new, or --init were passed, ignore even loading the
	// build context
	if args.update {
		os.chdir(api.install_path) or {
			log.error('Failed to chdir to ${api.install_path} (error: ${err})')
			exit(1)
		}
		os.system('v run config/scripts/update.vsh')
		exit(0)
	} else if args.init {
		os.system('v run ${api.installed_script_dir}/init.vsh')
		exit(0)
	} else if args.new {
		os.system('v run ${api.installed_script_dir}/new.vsh')
		exit(0)
	}

	// Get and load the build context
	mut con := api.BuildContext.new()
	con.allow_plugins = !args.no_plugins
	if !args.no_global {
		// Load the git-managed config
		con.load_config(maple.load_file(api.installed_config_path) or {
			log.info('Could not load git-managed global.maple (error: ${err})')
			map[string]maple.ValueT{}
		})

		// Load the user global config, if it exists
		if os.exists(api.global_config_path) {
			con.load_config(maple.load_file(api.global_config_path) or {
				log.info('Could not load user-managed global.maple (error: ${err})')
				map[string]maple.ValueT{}
			})
		}
	}
	if !args.no_local {
		con.load_config(maple.load_file('build.maple') or {
			log.error('Could not load build.maple (error: ${err})')

			// If all tasks exist, they are global. In that case, we
			// can still run. Otherwise we will crash.
			for task in tasks {
				if task !in con.tasks {
					exit(1)
				}
			}

			map[string]maple.ValueT{}
		})
	}

	// Exiting arguments
	if args.help {
		doc := flag.to_doc[Flags]()!
		println(doc)
		exit(0)
	} else if args.version {
		println(api.version)
		exit(0)
	} else if args.vars {
		for var, val in con.variables {
			println('${var} = `${val}`')
		}
		exit(0)
	} else if args.tasks {
		con.list_tasks(
			category: if args.list_category == '' { none } else { args.list_category }
			mode:     if args.list_mode == '' { none } else { args.list_mode }
		)
		exit(0)
	} else if args.debug_context {
		println(con.str())
		exit(0)
	}
	// Non-exiting arguments
	if !args.no_task_args {
		con.variables['args'] = task_args.map(|it| if it.contains_any(' \r\n\t\f') {
			'"${it}"'
		} else {
			it
		}).join(' ')
		con.variables['raw_args'] = task_args.join(' ')
	}

	// Run :D
	if tasks.len == 0 {
		log.info('No tasks provided. Use `clockwork --tasks` to list each.')
	} else {
		for task in tasks {
			con.run_task(task)
		}
	}
}
