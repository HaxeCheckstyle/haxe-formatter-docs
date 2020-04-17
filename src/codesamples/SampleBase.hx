package codesamples;

import js.Browser;
import js.jquery.Event;
import js.Lib;
import js.Syntax;
import js.jquery.JQuery;
import formatter.config.Config;
import formatter.Formatter;
import haxe.Json;
import codesamples.config.ConfigField;
import codesamples.config.ConfigFieldValues;

class SampleBase {
	var currentConfig:Null<Config>;
	var currentSampleConfig:Any;
	var currentCodeSample:Null<String>;
	var configFieldValues:Map<String, ConfigFieldValues>;
	var codeWasModified:Bool;

	public function buildDocSamplePage(container:String, codeSampleName:String, docText:String, configText:String, configFields:Array<ConfigField>,
			fieldDef:String, codeSample:String) {
		var content:String = '<h1>${codeSampleName.replace(".", " ")}</h1>\n';

		currentSampleConfig = Json.parse(configText);

		content += '<div id="configWrapper">';
		content += '<div id="docContainer">${Markdown.markdownToHtml(docText)}</div>';
		content += '<div id="configContainer">hxformat.json<br /><pre id="config">${buildConfigHtml(currentSampleConfig, configFields)}</pre></div>';
		content += '</div>';

		currentConfig = new Config();
		currentCodeSample = codeSample;
		codeWasModified = false;

		configFieldValues = new Map<String, ConfigFieldValues>();
		for (field in configFields) {
			configFieldValues.set(field.id, {
				defaultValue: getConfigFieldValue(currentConfig, field.id)
			});
		}

		currentConfig.readConfigFromString(configText, "hxformat.json");
		for (field in configFields) {
			configFieldValues.get(field.id).sampleValue = getConfigFieldValue(currentConfig, field.id);
		}
		var result:Result = Formatter.format(Code(codeSample), currentConfig);
		switch (result) {
			case Success(formattedCode):
				content += '<div id="codeSampleContainer"><textarea id="codeSample">$formattedCode</textarea></div>';
			case Failure(_):
			case Disabled:
		}

		new JQuery(container).html(content);
		new JQuery(".config-field-combo").change(onChangeCombo);
		new JQuery(".config-field-bool").change(onChangeBool);
		new JQuery(".config-field-bool-label").click(onClickBoolLabel);
		new JQuery(".config-field-number").change(onChangeNumber);
		new JQuery(".config-field-text").change(onChangeText);
		new JQuery("#codeSample").change(onChangeCodeSample);
	}

	function onChangeCombo(event:Event) {
		var element:JQuery = new JQuery(event.target);
		var fieldPath:String = element.data("field-path");
		var value:String = element.val();
		applyConfigValue(fieldPath, value);
		updateFormat();
	}

	function onClickBoolLabel(event:Event) {
		var element:JQuery = new JQuery(event.target);
		var fieldPath:String = element.data("field-path");
		element = new JQuery('input[data-field-path="$fieldPath"]');
		element.prop("checked", !element.prop("checked"));
		var value:String = "false";
		if (element.is(":checked")) {
			value = "true";
		}
		new JQuery('label[data-field-path="$fieldPath"]').text(value);
		applyConfigValue(fieldPath, value);
		updateFormat();
	}

	function onChangeBool(event:Event) {
		var element:JQuery = new JQuery(event.target);
		var fieldPath:String = element.data("field-path");

		var value:Bool = false;
		if (element.is(":checked")) {
			value = true;
		}
		new JQuery('label[data-field-path="$fieldPath"]').text(value);
		applyConfigValue(fieldPath, value);
		updateFormat();
	}

	function onChangeNumber(event:Event) {
		var element:JQuery = new JQuery(event.target);
		var fieldPath:String = element.data("field-path");
		var value:String = element.val();
		applyConfigValue(fieldPath, value);
		updateFormat();
	}

	function onChangeText(event:Event) {
		var element:JQuery = new JQuery(event.target);
		var fieldPath:String = element.data("field-path");
		var value:String = element.val();
		applyConfigValue(fieldPath, value);
		updateFormat();
	}

	function onChangeCodeSample(event:Event) {
		codeWasModified = true;
		updateFormat();
	}

	function applyConfigValue(fieldPath:String, value:Dynamic) {
		var parts:Array<String> = fieldPath.split(".");
		var fieldName:String = parts.pop();
		var object:Any = currentConfig;
		for (part in parts) {
			object = Reflect.field(object, part);
		}
		Reflect.setField(object, fieldName, value);
		configFieldValues.get(fieldPath).userValue = value;
		Browser.console.info('setting $fieldPath = $value');
	}

	function getConfigFieldValue(object:Any, fieldPath:String):String {
		var parts:Array<String> = fieldPath.split(".");
		var fieldName:String = parts.pop();

		for (part in parts) {
			object = Reflect.field(object, part);
		}
		return Reflect.field(object, fieldName);
	}

	function updateFormat() {
		var codeElement:JQuery = new JQuery("#codeSample");
		var codeSample:String = codeElement.val();
		if (!codeWasModified) {
			codeSample = currentCodeSample;
		}
		var result:Result = Formatter.format(Code(codeSample), currentConfig);
		switch (result) {
			case Success(formattedCode):
				codeElement.val(formattedCode);
			case Failure(errorMessage):
				Browser.console.info('format failed: $errorMessage');
			case Disabled:
		}
	}

	function buildConfigHtml(config:Any, configFields:Array<ConfigField>):String {
		return "{\n" + buildConfigFields(config, configFields, "    ", "") + "\n}\n";
	}

	function buildConfigFields(config:Any, configFields:Array<ConfigField>, indent:String, fieldPath:String):String {
		var lines:Array<String> = [];
		for (fieldName in Reflect.fields(config)) {
			var field:Any = Reflect.field(config, fieldName);
			var newPath:String = fieldName;
			if (fieldPath.length > 0) {
				newPath = fieldPath + "." + fieldName;
			}
			switch (Lib.typeof(field)) {
				case "string" | "boolean" | "number":
					lines.push(indent + fieldName + ": " + buildFieldValue(field, newPath, configFields) + ",");
				case "object":
					if (Syntax.code('Array.isArray({0})', field)) {
						lines.push(indent + fieldName + ": [");
						var arrayField:Array<Any> = field;
						for (index in 0...arrayField.length) {
							lines.push(buildConfigFields(arrayField[index], configFields, indent + "    ", newPath + '[$index]'));
						}
						lines.push(indent + "],");
						continue;
					}

					lines.push(indent + fieldName + ": {");
					lines.push(buildConfigFields(field, configFields, indent + "    ", newPath));
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

	function buildFieldValue(field:Any, fieldPath:String, configFields:Array<ConfigField>):String {
		for (configField in configFields) {
			if (fieldPath != configField.id) {
				continue;
			}
			return buildInputFieldValue(field, fieldPath, configField);
		}
		return switch (Type.typeof(field)) {
			case TClass(s):
				'"$field"';
			default:
				'$field';
		}
	}

	function buildInputFieldValue(field:Any, fieldPath:String, configField:ConfigField):String {
		switch (configField.type) {
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
