fn create_and_write(path string, data string) {
	println('Writing data to ${path}')
	if exists(path) {
		println('${path} already exists. No changes were made to it')
	} else {
		mut f := create(path) or { panic(err) }
		defer { f.close() }
		f.write_string(data) or { panic(err) }
	}
}

create_and_write('build.maple', "plugins = [ 'v' ]\n")

// TODO: Expand the initial build.maple

println('Initialized Clockwork project')
