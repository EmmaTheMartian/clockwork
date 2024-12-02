module api

import os
import log
import maple

// BuildContext represents loaded data for Clockwork, being tasks and variables.
pub struct BuildContext {
pub mut:
	tasks     map[string]Task
	variables map[string]string
	// allow_plugins toggles if plugins are allowed to load.
	allow_plugins bool = true
	// display contains display settings for Clockwork.
	display struct {
	pub mut:
		// default_task_category is the category to list tasks of when
		// using `clockwork --tasks`. No value means list all tasks.
		default_task_category string
		// list_tasks_mode is how tasks should be listed in
		// `clockwork --tasks`. Values: `verbose`, `slim`
		default_task_list_mode string = 'verbose'
		// task_list_exclude_categories is a list of categories to
		// exclude when using `clockwork --tasks`.
		task_list_exclude_categories []string = []
		// task_list_exclude_categories is a list of tasks to exclude
		// when using `clockwork --tasks`.
		task_list_exclude_tasks []string = []
	}
}

// new creates a new BuildContext with the default values.
@[inline]
pub fn BuildContext.new() BuildContext {
	mut con := BuildContext{}
	con.variables['clockwork:version'] = version
	con.variables['clockwork:global_data_dir'] = global_data_dir
	con.variables['clockwork:global_plugin_dir'] = global_plugin_dir
	con.variables['clockwork:global_config_path'] = global_config_path
	con.variables['clockwork:install_path'] = install_path
	con.variables['clockwork:installed_plugin_dir'] = installed_plugin_dir
	con.variables['clockwork:installed_config_path'] = installed_config_path
	con.variables['clockwork:work_dir'] = os.getwd()
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
	if con.allow_plugins && 'plugins' in data {
		for plugin in data.get('plugins').to_array() {
			mut path := plugin.to_str() + '.maple'

			if !os.exists(path) {
				git_managed := os.join_path_single(installed_plugin_dir, path)
				if os.exists(git_managed) {
					path = git_managed
				} else {
					user_managed := os.join_path_single(global_plugin_dir, path)
					if os.exists(user_managed) {
						path = user_managed
					}
				}
			}

			con.load_config(maple.load_file(path) or {
				log.error('Could not load plugin `${path}` (error: ${err})')
				exit(1)
			})
		}
	}

	// Load display settings
	if 'display' in data {
		for setting, value in data.get('display').to_map() {
			match setting {
				'default_task_category' {
					con.display.default_task_category = value.to_str()
				}
				'default_task_list_mode' {
					con.display.default_task_list_mode = value.to_str()
				}
				'task_list_exclude_categories' {
					con.display.task_list_exclude_categories = value.to_array().map(|it| it.to_str())
				}
				'task_list_exclude_tasks' {
					con.display.task_list_exclude_tasks = value.to_array().map(|it| it.to_str())
				}
				else {
					log.error('Invalid setting in display settings: ${setting}')
					exit(1)
				}
			}
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

// ListTaskOptions represent options for list_tasks_verbose and list_tasks.
@[params]
pub struct ListTaskOptions {
pub:
	// category is the category to list tasks from. Using no value ('') will
	// list all.
	category ?string
	// mode is the mode to list tasks as. `'verbose'` will list tasks with
	// their descriptions and dependencies. `'slim'` will list only task
	// names.
	mode ?string
	// exclude_categories is a list of categories to exclude from the list.
	exclude_categories ?[]string
	// exclude_tasks is a list of tasks to exclude from the list.
	exclude_tasks ?[]string
}

// list_tasks lists all tasks in a context with the given options.
pub fn (con BuildContext) list_tasks(options ListTaskOptions) {
	category := options.category or { con.display.default_task_category }

	exclude_categories := options.exclude_categories or { con.display.task_list_exclude_categories }

	exclude_tasks := options.exclude_tasks or { con.display.task_list_exclude_tasks }

	is_verbose := options.mode or { con.display.default_task_list_mode } == 'verbose'

	for name, task in con.tasks {
		if (category != '' && task.category != category)
			|| task.category in exclude_categories || name in exclude_tasks {
			continue
		}

		println('- ${name}')
		if is_verbose && task.depends.len > 0 {
			println('    \033[1mDepends:\033[0m ${task.depends.join(', ')}')
		}
		if is_verbose && task.category != '' {
			println('    \033[1mCategory:\033[0m ${task.category}')
		}
		if is_verbose && task.help != '' {
			println('    \033[1mHelp:\033[0m ${task.help}')
		}
	}
}
