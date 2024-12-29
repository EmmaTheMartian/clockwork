import os

const clockwork_executable = os.join_path_single(os.getwd(), 'build/clockwork')

fn main() {
	setup_symlink()
}
