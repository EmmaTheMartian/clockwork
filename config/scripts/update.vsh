repo_path := join_path_single(data_dir(), 'clockwork')

if !exists(repo_path) {
	system('git clone --recursive https://github.com/emmathemartian/clockwork ${repo_path}')
	chdir(repo_path)!
} else {
	chdir(repo_path)!
	system('git pull --recurse-submodules')
}

system('v run . install')
