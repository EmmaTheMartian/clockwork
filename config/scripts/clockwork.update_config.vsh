repo_path := '.clockwork-git'

if !exists(repo_path) {
	system('git clone https://github.com/emmathemartian/clockwork ${repo_path}')
} else {
	system('git pull')
}
chdir(repo_path)!

system('v run . install.config')
