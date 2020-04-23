package macros;

import haxe.Json;
import haxe.ds.ArraySort;
#if macro
import haxe.io.Path;
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;
import sys.FileSystem;
import codesamples.config.ConfigField;
import codesamples.config.ConfigFieldType;

using haxe.macro.Tools;
#end

class DocMacro {
	#if macro
	public macro static function build(folder:String):Array<Field> {
		var fields:Array<Field> = Context.getBuildFields();
		var testCases:Array<String> = collectAllFileNames(folder);
		for (testCase in testCases) {
			var field:Field = buildDocField(testCase);
			if (field == null) {
				continue;
			}
			fields.push(field);
		}
		return fields;
	}

	static function buildDocField(fileName:String):Field {
		var doc:String = sys.io.File.getContent(fileName);
		var docName:String = new haxe.io.Path(fileName).file;

		var r:EReg = ~/[^_a-zA-Z0-9]/g;
		var fieldName:String = r.replace(docName, "_");
		r = ~/^[^_a-zA-Z]/;
		fieldName = r.replace(fieldName, "_");

		var paramExprs:Array<Expr> = [];

		paramExprs.push({
			expr: EConst(CIdent("container")),
			pos: Context.currentPos()
		});
		paramExprs.push({
			expr: EConst(CString(docName)),
			pos: Context.currentPos()
		});
		paramExprs.push({
			expr: EConst(CString(doc)),
			pos: Context.currentPos()
		});

		var bodyExpr:Expr = {
			expr: EBlock([
				{
					expr: ECall({
						expr: EConst(CIdent("buildDocPage")),
						pos: Context.currentPos()
					}, paramExprs),
					pos: Context.currentPos()
				}
			]),
			pos: Context.currentPos()
		};

		var stringCP:ComplexType = TPath({pack: [], name: "String"});

		var functionExpr:Function = {
			ret: null,
			expr: bodyExpr,
			args: [
				{
					type: stringCP,
					name: "container"
				}
			]
		};

		var fieldExpr:Field = {
			pos: Context.currentPos(),
			name: fieldName,
			kind: FFun(functionExpr),
			access: [APublic],
			meta: [
				{
					name: "docName",
					params: [
						{
							expr: EConst(CString(docName)),
							pos: Context.currentPos()
						}
					],
					pos: Context.currentPos()
				},
				{
					name: "keywords",
					params: [KeywordHelper.makeKeywords(docName + " " + doc)],
					pos: Context.currentPos()
				}
			]
		};

		return fieldExpr;
	}

	static function collectAllFileNames(path:String):Array<String> {
		#if display
		return [];
		#end
		var items:Array<String> = FileSystem.readDirectory(path);
		var files:Array<String> = [];
		for (item in items) {
			if (item == "." || item == "..") {
				continue;
			}
			var fileName = Path.join([path, item]);
			if (FileSystem.isDirectory(fileName)) {
				files = files.concat(collectAllFileNames(fileName));
				continue;
			}
			if (!item.endsWith(".md")) {
				continue;
			}
			files.push(Path.join([path, item]));
		}
		ArraySort.sort(files, (s1, s2) -> (s1 == s2) ? 0 : ((s1 < s2) ? -1 : 1));
		return files;
	}
	#end
}
