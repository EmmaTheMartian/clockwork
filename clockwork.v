module main

import emmathemartian.maple
import log
import flag
import os

pub const version = '1.0.0'
pub const global_data_dir = os.join_path(os.config_dir()!, 'clockwork')
pub const global_plugin_dir = os.join_path(global_data_dir, 'plugins')

pub struct Task {
pub mut:
	depends []string = []
	run []string = []
}

pub struct BuildContext {
pub mut:
	tasks map[string]Task = {}
	variables map[string]string = {}
}

@[inline] pub fn (con BuildContext) format(str string) string {
	mut s := str
	for key, val in con.variables {
		s = s.replace('\${${key}}', val)
	}
	return s
}

pub fn (con BuildContext) run_task(id string) {
	is_metatask := id.all_before(':') == 'metatask'

	// Pre-task task
	if !is_metatask && 'metatask:pre' in con.tasks {
		con.run_task('metatask:pre')
	}

	// Run the task
	task_id := if id.contains_u8(`:`) { id } else { 'task:${id}' }
	log.info('-> ${id}')
	if task_id !in con.tasks {
		panic('No such task: ${task_id}')
	}

	task := con.tasks[task_id]

	for depend in task.depends {
		depend_id := if depend.contains_u8(`:`) { depend } else { 'task:${depend}' }

		if depend_id == task_id {
			panic('Cyclic task dependency detected in task:${task_id}')
		}

		con.run_task(depend_id)
	}

	for cmd in task.run {
		f := con.format(cmd)
		log.info('(${task_id}) -> ${f}')
		os.system(f)
	}

	// Post-task task
	if !is_metatask && 'metatask:post' in con.tasks {
		con.run_task('metatask:post')
	}
}

pub fn (mut con BuildContext) load_config(data map[string]maple.ValueT) {
	// Load plugins
	if 'plugins' in data {
		for plugin in data.get('plugins').to_array() {
			path := plugin.to_str().replace('@', global_plugin_dir) + '.maple'
			con.load_config(maple.load_file(path) or {
				log.error('Could not load plugin `${path}` (error: ${err})')
				exit(1)
			})
		}
	}

	// Load config options and tasks
	for key, val in data {
		if key.starts_with('config:') {
			con.variables[key.all_after_first(':')] = val.to_str()
		} else if key.starts_with('task:') {
			val_map := val.to_map()
			depends := (if 'depends' in val_map { val.get('depends') } else { []maple.ValueT{} }).to_array().map(|it| it.to_str())
			run := if 'run' in val_map {
				r := val.get('run')
				match r {
					string { [r] }
					[]maple.ValueT { r.map(|it| it.to_str()) }
					else {
						log.error('Invalid value for `run` in task `${key}`')
						exit(1)
					}
				}
			} else { []string{} }

			con.tasks[key] = Task{
				depends: depends
				run: run
			}
		}
	}
}

@[version: version]
@[name: 'clockwork']
struct Flags {
	version bool @[short: v; xdoc: 'Show version and exit']
	help bool @[short: h; xdoc: 'Show help and exit']
	no_task_args bool @[xdoc: 'Prevents task arguments from being passed to tasks']
	vars bool @[short: V; xdoc: 'Show variables and exit']
	tasks bool @[short: T; xdoc: 'Show tasks and exit']
	debug_context bool @[short: D; xdoc: 'Print the stringified context for debugging purposes']
}

fn main() {
	mut logger := log.Log{}
	logger.set_custom_time_format('hh:mm:ss')
	logger.set_level(.debug)
	log.set_logger(logger)

	// Make the global config directory if it does not exist
	if !os.exists(global_plugin_dir) {
		os.mkdir_all(global_plugin_dir) or {
			log.error('Failed to create global config directory: ${global_plugin_dir} (error: ${err})')
			exit(1)
		}
	}

	// Get and load the build context
	mut con := BuildContext{}
	con.load_config(maple.load_file('build.maple') or {
		log.error('Could not load build.maple (error: ${err})')
		exit(1)
	})

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

	// Exiting arguments
	if args.help {
		doc := flag.to_doc[Flags]()!
		println(doc)
		exit(0)
	} else if args.version {
		println(version)
		exit(0)
	}
	// Non-exiting arguments
	if !args.no_task_args {
		con.variables['args'] = task_args.map(|it| if it.contains_any(' \r\n\t\f') { '"${it}"' } else { it }).join(' ')
		con.variables['raw_args'] = task_args.join(' ')
	}
	if args.vars {
		for var, val in con.variables {
			println('${var} = `${val}`')
		}
	}
	if args.tasks {
		for name, task in con.tasks {
			// We skip the first 5 characters to get rid of the `task:` prefix
			print('- ${name[5..]}')
			if task.depends.len > 0 {
				print(' (${task.depends.join(', ')})')
			}
			println('')
		}
	}
	if args.debug_context {
		println(con.str())
	}

	// Run :D
	for task in tasks {
		con.run_task(task)
	}
}
