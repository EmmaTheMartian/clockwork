repo_path := '.clockwork-git'

if !exists(repo_path) {
	system('git clone https://github.com/emmathemartian/clockwork ${repo_path}')
} else {
	system('git pull')
}
chdir(repo_path)!

system('v run . install.noconfig')

println('Note: Clockwork update does NOT update default configs. To do that, use `clockwork.update.configs`. Please know that this will override any changes you have made to default configs.')
