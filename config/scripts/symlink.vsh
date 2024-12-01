const clockwork_executable := join_path_single(getwd(), 'build/clockwork')

// https://github.com/vlang/v/blob/master/cmd/tools/vsymlink/vsymlink_nix.c.v
mut link_path := '/data/data/com.termux/files/usr/bin/clockwork'
if !is_dir('/data/data/com.termux/files') {
	link_dir := local_bin_dir()
	if !exists(link_dir) {
		mkdir_all(link_dir) or { panic(err) }
	}
	link_path = link_dir + '/clockwork'
}

rm(link_path) or {}

symlink(clockwork_executable, link_path) or {
	eprintln('Failed to create symlink "${link_path}". You may (but probably do not) need sudo.')
	eprintln('Error: ${err}')
	exit(1)
}
