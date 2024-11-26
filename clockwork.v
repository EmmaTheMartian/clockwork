module main

import api
import log
import os
import flag
import emmathemartian.maple

@[name: 'clockwork']
@[version: version]
@[xdoc: 'usage: clockwork [options] TASKS [task arguments]\n\nTo run multiple tasks, you can separate them by commas (eg: `clockwork fmt,build.prod,test`)']
struct Flags {
	// Info
	version       bool @[short: v; xdoc: 'Show version and exit']
	help          bool @[short: h; xdoc: 'Show help and exit']
	vars          bool @[short: a; xdoc: 'Show variables and exit']
	tasks         bool @[short: t; xdoc: 'Show tasks and exit']
	debug_context bool @[short: d; xdoc: 'Print the stringified context for debugging purposes']
	// Functionality
	no_task_args bool @[short: T; xdoc: 'Prevents task arguments from being passed to tasks']
	no_global    bool @[short: G; xdoc: 'Disable loading global.maple']
	no_local     bool @[short: L; xdoc: 'Disable loading build.maple']
	no_plugins   bool @[short: P; xdoc: 'Disable loading any plugins']
}

fn main() {
	mut logger := log.Log{}
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

	// Get and load the build context
	mut con := api.BuildContext.new()
	con.allow_plugins = !args.no_plugins
	if !args.no_global {
		con.load_config(maple.load_file(api.global_config_path) or {
			log.error('Could not load global.maple (error: ${err})')
			exit(1)
		})
	}
	if !args.no_local {
		con.load_config(maple.load_file('build.maple') or {
			log.error('Could not load build.maple (error: ${err})')
			exit(1)
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
	if args.vars {
		for var, val in con.variables {
			println('${var} = `${val}`')
		}
	}
	if args.tasks {
		con.list_tasks()
	}
	if args.debug_context {
		println(con.str())
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
