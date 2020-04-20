package codesamples.config;

import haxe.Json;
import formatter.config.Config;
import js.Syntax;
import js.Lib;
import macros.ConfigFieldMacro;

class ConfigFieldRegistry {
	final configFields:Map<String, ConfigFieldType> = ConfigFieldMacro.readConfigFields("docs/config/fieldDefs.txt");

	var configFieldValues:Map<String, ConfigFieldValues>;

	var sampleConfig:Any;
	var sampleConfigText:String;

	public var currentConfig(default, null):Config;

	public function new() {
		currentConfig = new Config();

		configFieldValues = new Map<String, ConfigFieldValues>();
		for (fieldPath => _ in configFields) {
			configFieldValues.set(fieldPath, {
				defaultValue: getConfigFieldValue(currentConfig, fieldPath)
			});
		}
	}

	public function setCurrentSampleConfig(text:String) {
		if ((text == null) || (text.length <= 0)) {
			text = "{}";
		}
		sampleConfigText = text;
		sampleConfig = Json.parse(text);

		currentConfig.readConfigFromString(sampleConfigText, "hxformat.json");
		for (fieldPath => _ in configFields) {
			configFieldValues.get(fieldPath).sampleValue = getConfigFieldValue(currentConfig, fieldPath);
		}
	}

	public function setFieldValue(fieldPath:String, value:Any) {
		setConfigFieldValue(currentConfig, fieldPath, value);
	}

	function setConfigFieldValue(object:Any, fieldPath:String, value:Any) {
		var parts:Array<String> = fieldPath.split(".");
		var fieldName:String = parts.pop();
		for (part in parts) {
			object = Reflect.field(object, part);
		}
		if (object == null) {
			return;
		}
		Reflect.setField(object, fieldName, value);
		configFieldValues.get(fieldPath).userValue = value;
	}

	public function getFieldValue(fieldPath:String):String {
		return getConfigFieldValue(currentConfig, fieldPath);
	}

	function getConfigFieldValue(object:Any, fieldPath:String):String {
		var parts:Array<String> = fieldPath.split(".");
		var fieldName:String = parts.pop();

		for (part in parts) {
			object = Reflect.field(object, part);
		}
		return Reflect.field(object, fieldName);
	}

	public function makeCustomConfig():String {
		var copyConfig:Any = Json.parse(Json.stringify(sampleConfig));

		for (fieldPath => values in configFieldValues) {
			if (values.userValue == null) {
				continue;
			}
			setConfigFieldValue(copyConfig, fieldPath, values.userValue);
		}
		return Json.stringify(copyConfig, "  ");
	}

	public function buildConfigHtml():String {
		return "{\n" + buildConfigFields(sampleConfig, "    ", "") + "\n}\n";
	}

	function buildConfigFields(config:Any, indent:String, fieldPath:String):String {
		var lines:Array<String> = [];
		for (fieldName in Reflect.fields(config)) {
			var field:Any = Reflect.field(config, fieldName);
			var newPath:String = fieldName;
			if (fieldPath.length > 0) {
				newPath = fieldPath + "." + fieldName;
			}
			switch (Lib.typeof(field)) {
				case "string" | "boolean" | "number":
					lines.push(indent + fieldName + ": " + buildFieldValue(field, newPath) + ",");
				case "object":
					if (Syntax.code('Array.isArray({0})', field)) {
						lines.push(indent + fieldName + ": [");
						var arrayField:Array<Any> = field;
						for (index in 0...arrayField.length) {
							lines.push(buildConfigFields(arrayField[index], indent + "    ", newPath + '[$index]'));
						}
						lines.push(indent + "],");
						continue;
					}

					lines.push(indent + fieldName + ": {");
					lines.push(buildConfigFields(field, indent + "    ", newPath));
					lines.push(indent + "},");
				default:
					trace("unhandled" + Lib.typeof(field));
			}
		}
		if (lines.length > 0) {
			var lastEntry:String = lines[lines.length - 1];
			if (lastEntry.endsWith(",")) {
				lines[lines.length - 1] = lastEntry.substr(0, lastEntry.length - 1);
			}
		}
		return lines.join("\n");
	}

	function buildFieldValue(field:Any, fieldPath:String):String {
		if (configFields.exists(fieldPath)) {
			return buildInputFieldValue(field, fieldPath);
		}
		return switch (Type.typeof(field)) {
			case TClass(s):
				'"$field"';
			default:
				'$field';
		}
	}

	function buildInputFieldValue(field:Any, fieldPath:String):String {
		switch (configFields.get(fieldPath)) {
			case Combo(abstractValues):
				var combo:String = '<select class="config-field-combo" data-field-path="$fieldPath">';
				for (option in abstractValues) {
					var selected:String = "";
					if (option == '$field') {
						selected = " selected";
					}
					combo += '<option value="$option"$selected>$option</option>';
				}
				combo += "</select>";
				return combo;
			case Bool:
				var checked:String = "";
				var label:String = "false";
				if ('$field' == "true") {
					checked = "checked";
					label = "true";
				}
				return '<input type="checkbox" value="1" class="config-field-bool" data-field-path="$fieldPath" $checked/>'
					+ '<label class="config-field-bool-label" data-field-path="$fieldPath">$label</label>';
			case Number:
				return '<input type="number" value="$field" class="config-field-number" data-field-path="$fieldPath" />';
			case Text:
				return '<input type="text" value="$field" class="config-field-text" data-field-path="$fieldPath" />';
		}
		return "";
	}
}
