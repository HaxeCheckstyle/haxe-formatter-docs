package macros;

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
		if (segments.length != 4) {
			throw 'invalid docsample format for: $fileName';
		}
		var doc:String = segments[0];
		var config:String = segments[1];
		var fieldDef:String = segments[2];
		var codeSample:String = segments[3];
		var codeSampleName:String = new haxe.io.Path(fileName).file;
		var configFields:ExprOf<Array<ConfigField>> = parseFields(fieldDef);

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
		paramExprs.push(configFields);
		paramExprs.push({
			expr: EConst(CString("")),
			pos: Context.currentPos()
		});
		paramExprs.push({
			expr: EConst(CString(codeSample)),
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
					name: "codeSampleName",
					params: [
						{
							expr: EConst(CString(codeSampleName)),
							pos: Context.currentPos()
						}
					],
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
		return files;
	}

	static function parseFields(fieldDef:String):ExprOf<Array<ConfigField>> {
		var fieldConfigs:Array<ExprOf<ConfigField>> = [];

		for (def in fieldDef.split("\n")) {
			var parts:Array<String> = def.split("=");
			if (parts.length != 2) {
				continue;
			}
			var type:Null<ExprOf<ConfigFieldType>> = null;
			var typePart:String = parts[1].trim();
			if (typePart.startsWith("combo")) {
				var comboParts:Array<String> = parts[1].split(",");
				if (comboParts.length != 2) {
					continue;
				}

				type = {
					expr: ECall(makeEFieldExpr("codesamples.config.ConfigFieldType", "Combo"), [getAllEnumValues(comboParts[1].trim())]),
					pos: Context.currentPos()
				}
			}
			if (typePart.startsWith("number")) {
				type = macro codesamples.config.ConfigFieldType.Number;
			}
			if (typePart.startsWith("bool")) {
				type = macro codesamples.config.ConfigFieldType.Bool;
			}
			if (typePart.startsWith("text")) {
				type = macro codesamples.config.ConfigFieldType.Text;
			}

			if (type == null) {
				continue;
			}
			var fieldId:String = parts[0].trim();
			fieldConfigs.push({
				expr: EObjectDecl([
					{
						field: "id",
						expr: {
							expr: EConst(CString(fieldId)),
							pos: Context.currentPos()
						}
					},
					{
						field: "type",
						expr: type
					}
				]),
				pos: Context.currentPos()
			});
		}
		return {
			expr: EArrayDecl(fieldConfigs),
			pos: Context.currentPos()
		};
	}

	static function getAllEnumValues(typePath:String):Expr {
		var type = Context.getType(typePath);
		var stringCP:ComplexType = TPath({pack: [], name: "String"});

		switch (type.follow()) {
			case TAbstract(_.get() => ab, _) if (ab.meta.has(":enum")):
				var valueExprs:Array<Expr> = [];
				for (field in ab.impl.get().statics.get()) {
					if (field.meta.has(":enum") && field.meta.has(":impl")) {
						valueExprs.push({
							expr: ECast(makeEFieldExpr(typePath, field.name), stringCP),
							pos: Context.currentPos()
						});
					}
				}
				return {
					expr: EArrayDecl(valueExprs),
					pos: Context.currentPos()
				};
			default:
				throw new Error(type.toString() + " should be @:enum abstract", null);
		}
		return null;
	}

	static function makeEFieldExpr(enumName:String, fieldName:String):Expr {
		var parts:Array<String> = enumName.split(".");
		var efieldExpr:Null<Expr> = null;
		for (part in parts) {
			if (efieldExpr == null) {
				efieldExpr = {
					expr: EConst(CIdent(part)),
					pos: Context.currentPos()
				};
			} else {
				efieldExpr = {
					expr: EField(efieldExpr, part),
					pos: Context.currentPos()
				};
			}
		}
		efieldExpr = {
			expr: EField(efieldExpr, fieldName),
			pos: Context.currentPos()
		};

		return efieldExpr;
	}
	#end
}
