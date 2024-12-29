import os

// https://github.com/vlang/v/blob/master/cmd/tools/vsymlink/vsymlink_nix.c.v
fn setup_symlink() {
	println('symlinking on nix')

	mut link_path := '/data/data/com.termux/files/usr/bin/clockwork'
	if !os.is_dir('/data/data/com.termux/files') {
		link_dir := os.local_bin_dir()
		if !os.exists(link_dir) {
			os.mkdir_all(link_dir) or { panic(err) }
		}
		link_path = link_dir + '/clockwork'
	}

	os.rm(link_path) or {}

	os.symlink(clockwork_executable, link_path) or {
		eprintln('Failed to create symlink "${link_path}". You may (but probably do not) need sudo.')
		eprintln('Error: ${err}')
		exit(1)
	}
}
