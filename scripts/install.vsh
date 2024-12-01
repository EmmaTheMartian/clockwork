#!/usr/bin/env -S v

path := join_path_single(data_dir(), 'clockwork')
system('git clone --recurse-submodules https://github.com/emmathemartian/clockwork ${path}')
chdir(path)!
system('v run . install')
