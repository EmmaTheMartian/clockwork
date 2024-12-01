name := input('Input your project name: ')
description := input('Input your project description: ')
version := input('Input your project version (0.0.0): ')
license := input('Input your project version (MIT): ')

mkdir(name)!
chdir(name)!

mkdir('src')!

vmod := create('v.mod')!
vmod.write_string('Module {
	name: \'${name}\'
	description: \'${description}\'
	version: \'${version}\'
	license: \'${license}\'
	dependencies: []
}
')

gitignore := create('.gitignore')!
gitignore.write_string('# Binaries for programs and plugins
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

gitattributes := create('.gitattributes')!
gitattributes.write_string('* text=auto eol=lf
*.bat eol=crlf

*.v linguist-language=V
*.vv linguist-language=V
*.vsh linguist-language=V
v.mod linguist-language=V
.vdocignore linguist-language=ignore
')

editorconfig := create('editorconfig')!
editorconfig.write_string('[*]
charset = utf-8
end_of_line = lf
insert_final_newline = true
trim_trailing_whitespace = true

[*.v]
indent_style = tab
')

mainv := create('src/main.v')!
mainv.write_string('module main

fn main() {
	println(\'Hello World!\')
}
')

buildmaple := create('build.maple')!
buildmaple.write_string('plugins = [ \'@/v\' ]')

// TODO: Expand the initial build.maple

println('Created Clockwork project `${name}`')
