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

class CodeSampleMacro {
	#if macro
	public macro static function build(folder:String):Array<Field> {
		var fields:Array<Field> = Context.getBuildFields();
		var testCases:Array<String> = collectAllFileNames(folder);
		for (testCase in testCases) {
			var field:Field = buildDocSampleField(testCase);
			if (field == null) {
				continue;
			}
			fields.push(field);
		}
		return fields;
	}

	static function buildDocSampleField(fileName:String):Field {
		var content:String = sys.io.File.getContent(fileName);
		var nl = "\r?\n";
		var reg = new EReg('$nl$nl---$nl$nl', "g");
		var segments = reg.split(content);
		if (segments.length != 3) {
			throw 'invalid docsample format for: $fileName';
		}
		var doc:String = segments[0];
		var config:String = segments[1];
		var codeSample:String = segments[2];
		var codeSampleName:String = new haxe.io.Path(fileName).file;

		// test JSON parse, to make sure samples have no syntax errors
		Json.parse(config);

		var r:EReg = ~/[^_a-zA-Z0-9]/g;
		var fieldName:String = r.replace(codeSampleName, "_");
		r = ~/^[^_a-zA-Z]/;
		fieldName = r.replace(fieldName, "_");

		var paramExprs:Array<Expr> = [];

		paramExprs.push({
			expr: EConst(CIdent("container")),
			pos: Context.currentPos()
		});
		paramExprs.push({
			expr: EConst(CString(codeSampleName)),
			pos: Context.currentPos()
		});
		paramExprs.push({
			expr: EConst(CString(doc)),
			pos: Context.currentPos()
		});
		paramExprs.push({
			expr: EConst(CString(config)),
			pos: Context.currentPos()
		});
		paramExprs.push({
			expr: EConst(CString("")),
			pos: Context.currentPos()
		});
		paramExprs.push({
			expr: EConst(CString(codeSample)),
			pos: Context.currentPos()
		});
		paramExprs.push({
			expr: EConst(CIdent("configFieldRegistry")),
			pos: Context.currentPos()
		});

		var bodyExpr:Expr = {
			expr: EBlock([
				{
					expr: ECall({
						expr: EConst(CIdent("buildDocSamplePage")),
						pos: Context.currentPos()
					}, paramExprs),
					pos: Context.currentPos()
				}
			]),
			pos: Context.currentPos()
		};

		var stringCP:ComplexType = TPath({pack: [], name: "String"});
		var registryCP:ComplexType = TPath({
			pack: ["codesamples", "config"],
			name: "ConfigFieldRegistry"
		});

		var functionExpr:Function = {
			ret: null,
			expr: bodyExpr,
			args: [
				{
					type: stringCP,
					name: "container"
				},
				{
					type: registryCP,
					name: "configFieldRegistry"
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
					name: "codeSampleName",
					params: [
						{
							expr: EConst(CString(codeSampleName)),
							pos: Context.currentPos()
						}
					],
					pos: Context.currentPos()
				},
				{
					name: "keywords",
					params: [KeywordHelper.makeKeywords(codeSampleName + " " + doc + " " + config)],
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
			if (!item.endsWith(".codesample")) {
				continue;
			}
			files.push(Path.join([path, item]));
		}
		ArraySort.sort(files, (s1, s2) -> (s1 == s2) ? 0 : ((s1 < s2) ? -1 : 1));
		return files;
	}
	#end
}
