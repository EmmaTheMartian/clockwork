module api

import os

pub const version = '1.0.0'

// global_data_dir is the path to the folder containing Clockwork's global data
// and configs.
pub const global_data_dir = os.join_path(os.config_dir()!, 'clockwork')

// global_plugin_dir is the path to the folder containing Clockwork's plugins.
pub const global_plugin_dir = os.join_path(global_data_dir, 'plugins')

// global_config_path is the to the global config file (global.maple).
pub const global_config_path = os.join_path(global_data_dir, 'global.maple')
