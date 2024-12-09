import api
import api.maple
import os

const v_run = api.Task{
	help:     'Run v_main. Extra arguments get passed to the program'
	category: 'run'
	run:      ['\${v} \${v_args} run \${v_main} \${args}']
}

const v_deps = api.Task{
	help:     'Download project dependencies'
	category: 'misc'
	run:      ['\${v} install']
}

const v_build = api.Task{
	help:     'Build the project'
	category: 'build'
	run:      [
		'mkdir -p \${v_build_dir}',
		'\${v} -o \${v_build_dir}/\${v_build_filename} \${v_args} \${v_main}',
	]
}

const v_build_prod = api.Task{
	help:     'Build the project with optimizations enabled'
	category: 'build'
	run:      [
		'mkdir -p \${v_build_dir}',
		'\${v} -prod -o \${v_build_dir}/\${v_build_filename} \${v_args} \${v_main}',
	]
}

const v_test = api.Task{
	help:     'Test the project. Extra arguments get passed to the program'
	category: 'test'
	run:      ['\${v} \${v_args} test \${v_main} \${args}']
}

const v_watch = api.Task{
	help:     'Watch/run the project. Extra arguments get passed to the program'
	category: 'run'
	run:      ['\${v} \${v_args} watch run \${v_main} \${args}']
}

const v_clean = api.Task{
	help:     'Delete v_build_dir'
	category: 'misc'
	run:      ['rm -rf \${v_build_dir}']
}

const v_fmt = api.Task{
	help:     'Run v fmt on the whole project'
	category: 'misc'
	run:      ['\${v} -w fmt .']
}

fn test_load() {
	mut con := api.BuildContext.new()

	con.load_config(maple.load_file('build.maple') or {
		panic('Failed to load build.maple in test directory. This error should never occur.')
	})

	// Validate built-ins
	assert con.variables['clockwork:version'] == api.version
	assert con.variables['clockwork:global_data_dir'] == api.global_data_dir
	assert con.variables['clockwork:global_plugin_dir'] == api.global_plugin_dir
	assert con.variables['clockwork:global_config_path'] == api.global_config_path
	assert con.variables['clockwork:install_path'] == api.install_path
	assert con.variables['clockwork:installed_plugin_dir'] == api.installed_plugin_dir
	assert con.variables['clockwork:installed_script_dir'] == api.installed_script_dir
	assert con.variables['clockwork:installed_config_path'] == api.installed_config_path
	assert con.variables['clockwork:work_dir'] == os.getwd()

	// Validate V plugin
	assert con.variables['v'] == 'v'
	assert con.variables['v_main'] == '.'
	assert con.variables['v_build_dir'] == 'build'
	assert con.variables['v_build_filename'] == 'main'
	assert con.variables['v_args'] == ''
	assert con.variables['v_program_args'] == ''

	assert con.tasks['run'] == v_run
	assert con.tasks['deps'] == v_deps
	assert con.tasks['build'] == v_build
	assert con.tasks['build.prod'] == v_build_prod
	assert con.tasks['test'] == v_test
	assert con.tasks['watch'] == v_watch
	assert con.tasks['clean'] == v_clean
	assert con.tasks['fmt'] == v_fmt

	// Validate `plugin.maple`
	assert con.variables['greeting'] == 'Hola'
	assert con.variables['subject'] == 'mundo'
	assert con.variables['message'] == '\${greeting}, \${subject}'

	assert con.tasks['greet'] == api.Task{
		help:     'Greet the configured subject with the configured greeting'
		category: 'misc'
		run:      ['echo "\${message}"']
	}

	// Validate `build.maple`
	assert con.tasks['doublegreet'] == api.Task{
		help:     'Double the greetings, double the fun!'
		category: 'misc'
		depends:  ['greet', 'greet']
	}
}
