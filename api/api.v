module api

import os

pub const version = '1.1.0'

// global_data_dir is the path to the folder containing Clockwork's global data
// and configs.
pub const global_data_dir = os.join_path_single(os.config_dir()!, 'clockwork')

// global_plugin_dir is the path to the folder containing Clockwork's plugins.
pub const global_plugin_dir = os.join_path_single(global_data_dir, 'plugins')

// global_config_path is the to the global config file (global.maple).
pub const global_config_path = os.join_path_single(global_data_dir, 'global.maple')

// install_path is the path to the location where Clockwork is installed (aka
// the "git-managed" path)
pub const install_path = os.dir(os.executable())

// installed_plugin_dir is the path to the git-managed plugins.
pub const installed_plugin_dir = os.join_path_single(install_path, 'plugins')

// installed_config_path is the path to the git-managed config file (global.maple).
pub const installed_config_path = os.join_path_single(install_path, 'global.maple')
