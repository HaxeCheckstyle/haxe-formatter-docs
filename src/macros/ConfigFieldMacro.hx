package macros;

import codesamples.config.ConfigFieldType;
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

class ConfigFieldMacro {
	macro public static function readConfigFields(fileName:String):ExprOf<Map<String, ConfigFieldType>> {
		var fieldDefs:String = sys.io.File.getContent(fileName);
		return parseFields(fieldDefs);
	}

	#if macro
	static function parseFields(fieldDef:String):ExprOf<Map<String, ConfigFieldType>> {
		var fieldConfigs:Array<Expr> = [];

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

			var keyExpr:Expr = {
				expr: EConst(CString(fieldId)),
				pos: Context.currentPos()
			};
			fieldConfigs.push({
				expr: EBinop(OpArrow, keyExpr, type),
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
