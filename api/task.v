module api

import log
import maple

// Task represents an executable task in the BuildContext.
pub struct Task {
pub:
	depends  []string = []
	run      []string = []
	help     string
	work_dir ?string
	category string
}

// from_map loads a task from a Maple map.
pub fn Task.from_map(data map[string]maple.ValueT, task_name string) Task {
	depends := if 'depends' in data {
		data.get('depends').to_array().map(|it| it.to_str())
	} else {
		[]string{}
	}

	run := if 'run' in data {
		r := data.get('run')
		match r {
			string {
				[r]
			}
			[]maple.ValueT {
				r.map(|it| it.to_str())
			}
			else {
				log.error('Invalid value for `run` in task `${task_name}`')
				exit(1)
			}
		}
	} else {
		[]string{}
	}

	help := if 'help' in data {
		data.get('help').to_str()
	} else {
		''
	}

	work_dir := if 'work_dir' in data {
		?string(data.get('work_dir').to_str())
	} else {
		none
	}

	category := if 'category' in data {
		data.get('category').to_str()
	} else {
		''
	}

	return Task{
		depends:  depends
		run:      run
		help:     help
		work_dir: work_dir
		category: category
	}
}
