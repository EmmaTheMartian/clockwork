module api

import os
import log
import emmathemartian.maple

// BuildContext represents loaded data for Clockwork, being tasks and variables.
pub struct BuildContext {
pub mut:
	tasks     map[string]Task
	variables map[string]string
}

// new creates a new BuildContext with the default values.
@[inline]
pub fn BuildContext.new() BuildContext {
	mut con := BuildContext{}
	con.variables['clockwork:version'] = version
	con.variables['clockwork:global_data_dir'] = global_data_dir
	con.variables['clockwork:global_plugin_dir'] = global_plugin_dir
	con.variables['clockwork:global_config_path'] = global_config_path
	return con
}

// format formats a string to replace ${some_variable} with its corresponding value.
@[inline]
pub fn (con BuildContext) format(str string) string {
	mut s := str
	for key, val in con.variables {
		s = s.replace('\${${key}}', val)
	}
	return s
}

// run_task runs a task with a given ID.
pub fn (con BuildContext) run_task(id string) {
	is_metatask := id.all_before(':') == 'metatask'

	// Pre-task task
	if !is_metatask && 'metatask:pre' in con.tasks {
		con.run_task('metatask:pre')
	}

	// Run the task
	log.info('-> ${id}')
	if id !in con.tasks {
		log.error('No such task: ${id}')
		exit(1)
	}

	task := con.tasks[id]

	for depend in task.depends {
		if depend == id {
			log.error('Cyclic task dependency detected in task:${id}')
			exit(1)
		}
		con.run_task(depend)
	}

	prev_dir := os.getwd()
	if task.work_dir != none {
		wd := con.format(task.work_dir)
		os.chdir(wd) or {
			log.error('Failed to chdir to ${wd}')
			exit(1)
		}
	}

	for cmd in task.run {
		f := con.format(cmd)
		log.info('(${id}) -> ${f}')
		os.system(f)
	}

	if task.work_dir != none {
		os.chdir(prev_dir) or {
			log.error('Failed to chdir to ${prev_dir}')
			exit(1)
		}
	}

	// Post-task task
	if !is_metatask && 'metatask:post' in con.tasks {
		con.run_task('metatask:post')
	}
}

// load_config loads a config file into the BuildContext.
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
			con.tasks[key.all_after_first(':')] = Task.from_map(val.to_map(), key)
		}
	}
}

// list_tasks lists all tasks in a context in a pretty and clean fashion.
pub fn (con BuildContext) list_tasks() {
	for name, task in con.tasks {
		print('- ${name}')
		if task.depends.len > 0 {
			print(' (${task.depends.join(', ')})')
		}
		println('')
		if task.help != '' {
			println('    ${task.help}')
		}
	}
}
