import emmathemartian.maple
import os
import log

struct Task {
pub mut:
	depends []string = []
	run []string = []
}

struct BuildContext {
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
			con.load_config(maple.load_file('${plugin.to_str()}.maple') or {
				log.error(err.str())
				panic('Could not load plugin `${plugin}.maple`')
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
						panic('Invalid value for `run` in task `${key}`')
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

fn main() {
	mut logger := log.Log{}
	logger.set_custom_time_format('hh:mm:ss')
	logger.set_level(.debug)
	log.set_logger(logger)

	mut con := BuildContext{}

	con.load_config(maple.load_file('build.maple') or {
		log.error(err.str())
		panic('Could not load build.maple')
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

	// Do argument things
	if '-no-args' !in clockwork_args {
		con.variables['args'] = task_args.map(|it| if it.contains_any(' \r\n\t\f') { '"${it}"' } else { it }).join(' ')
		con.variables['raw_args'] = task_args.join(' ')
	}

	for arg in clockwork_args {
		match arg {
			'-list-vars' {
				logger.debug(con.variables.str())
			}
			'-list-tasks' {
				logger.debug(con.tasks.keys().str())
			}
			'-debug-context' {
				logger.debug(con.str())
			}
			else {
				log.error('Unknown argument: ${arg}')
			}
		}
	}

	// Run :D
	for task in tasks {
		con.run_task(task)
	}
}
