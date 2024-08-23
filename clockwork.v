import emmathemartian.maple
import os

@[inline] fn exec(cmd string, msg string) {
	println('-> (${msg}) ${cmd}')
	os.system(cmd)
}

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

@[inline] fn (con BuildContext) format(str string) string {
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
		exec(con.format(cmd.to_str()), task_id)
	}

	// Post-task task
	if !is_metatask && 'metatask:post' in con.config {
		con.run_task('metatask:post')
	}
}

pub fn (con BuildContext) load_maple(data map[string]maple.ValueT) {
	for key, val in data {
		if key.starts_with('')
	}
}

fn main() {
	mut con := BuildContext{}

	build_config := maple.load_file('build.maple') or {
		println(err)
		panic('Could not load build.maple')
	}

	// Load plugins
	if 'plugins' in build_config.config.to_map() {
		for plugin in build_config.config.get('plugins').to_array() {
			
		}
	}

	// Load config

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

	// Load variables
	mut variables := map[string]string{}
	for key, val in build_config {
		if key.starts_with('config:') {
			variables[key.all_after_first(':')] = val.to_str()
		}
	}

	if '-no-args' !in clockwork_args {
		variables['args'] = task_args.map(|it| if it.contains_any(' \r\n\t\f') { '"${it}"' } else { it }).join(' ')
		variables['raw_args'] = task_args.join(' ')
	}

	if '-list-vars' in clockwork_args {
		println(variables)
	}

	// Run :D
	for task in tasks {
		con.run_task(task)
	}
}
