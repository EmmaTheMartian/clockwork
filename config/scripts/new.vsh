fn create_and_write(path string, data string) {
	if exists(path) {
		println('${path} already exists. No changes were made to it')
	} else {
		mut f := create(path) or { panic(err) }
		defer { f.close() }
		f.write_string(data) or { panic(err) }
	}
}

name := input('Input your project name: ')
description := input('Input your project description: ')
mut version := input('Input your project version (0.0.0): ')
mut license := input('Input your project version (MIT): ')

if name.trim_space() == '' {
	println('Error: No name set.')
	exit(1)
}

if version.trim_space() == '' {
	version = '0.0.0'
}

if license.trim_space() == '' {
	license = 'MIT'
}

if !exists(name) {
	mkdir(name)!
}

chdir(name)!

if !exists('src') {
	mkdir('src')!
}

create_and_write('v.mod', "Module {
	name: '${name}'
	description: '${description}'
	version: '${version}'
	license: '${license}'
	dependencies: []
}")

create_and_write('.gitignore', '# Binaries for programs and plugins
main
f
*.exe
*.exe~
*.so
*.dylib
*.dll

# Ignore binary output folders
bin/

# Ignore common editor/system specific metadata
.DS_Store
.idea/
.vscode/
*.iml

# ENV
.env

# vweb and database
*.db
*.js
')

create_and_write('.gitattributes', '* text=auto eol=lf
*.bat eol=crlf

*.v linguist-language=V
*.vv linguist-language=V
*.vsh linguist-language=V
v.mod linguist-language=V
.vdocignore linguist-language=ignore
')

create_and_write('editorconfig', '[*]
charset = utf-8
end_of_line = lf
insert_final_newline = true
trim_trailing_whitespace = true

[*.v]
indent_style = tab
')

create_and_write('src/main.v', "module main

fn main() {
	println('Hello World!')
}
")

create_and_write('build.maple', "plugins = [ 'v' ]\n")

// TODO: Expand the initial build.maple

println('Created Clockwork project `${name}`')
