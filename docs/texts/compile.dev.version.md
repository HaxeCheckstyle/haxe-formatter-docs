### compile command line version (Haxe 4)

- `git clone https://github.com/HaxeCheckstyle/haxe-formatter.git`
- `cd haxe-formatter`
- `npm install`
- `npx lix download`
- `npx haxe buildAll.hxml` - for Neko, NodeJS and Java version + JSON schema
- `npx haxe buildCpp.hxml` - for C++ version

### compile command line version (Haxe 3)

- `git clone https://github.com/HaxeCheckstyle/haxe-formatter.git`
- `cd haxe-formatter`
- `npm install`
- `mv haxe_libraries haxe4_libraries`
- `mv haxe3_libraries haxe_libraries`
- `npx lix install haxe 3.4.7`
- `npx lix download`
- `npx haxe buildAll.hxml` - for Neko, NodeJS and Java version + JSON schema
- `npx haxe buildCpp.hxml` - for C++ version

### compile haxe-language server

- `git clone https://github.com/vshaxe/haxe-languageserver.git`
- `cd haxe-languageserver`
- `npm install`
- `npx lix download`
- `npx lix install gh:HaxeCheckstyle/tokentree`
- `npx lix install gh:HaxeCheckstyle/haxe-formatter`
- `npx lix run vshaxe-build --target language-server`
- `cp bin/server.js ~/.vscode/extensions/nadako.vshaxe-$VSHAXE_VERSION/server/bin`
- restart Haxe language server or restart VSCode
