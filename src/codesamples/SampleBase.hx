package codesamples;

import js.Browser;
import js.html.Blob;
import js.html.URL;
import js.jquery.Event;
import js.jquery.JQuery;
import formatter.Formatter;
import codesamples.config.ConfigFieldRegistry;

@:keepSub
class SampleBase {
	static inline var DATA_FIELD_PATH = "field-path";

	var currentCodeSample:Null<String>;
	var codeWasModified:Bool;
	var configFieldRegistry:ConfigFieldRegistry;

	public function buildDocSamplePage(container:String, codeSampleName:String, docText:String, configText:String, fieldDef:String, codeSample:String,
			registry:ConfigFieldRegistry) {
		var content:String = '<h1>${codeSampleName.replace(".", " ")}</h1>\n';

		configFieldRegistry = registry;
		configFieldRegistry.setCurrentSampleConfig(configText);

		content += '<div id="configWrapper">';
		content += '<div id="docContainer">${Markdown.markdownToHtml(docText)}</div>';
		content += '<div id="configContainer"><div id="configHeader">hxformat.json'
			+ '<div id="configButtons"><button id="btnApply">Apply</button>'
			+ '<button id="btnEdit">Edit</button><button id="btnDownload">Download</button></div></div>'
			+ '<pre id="config">${this.configFieldRegistry.buildConfigHtml()}</pre>'
			+ '<textarea id="configText">${this.configFieldRegistry.makeCustomConfig()}</textarea></div>';
		content += "</div>";

		currentCodeSample = codeSample;
		codeWasModified = false;

		var result:Result = Formatter.format(Code(codeSample), configFieldRegistry.currentConfig);
		switch (result) {
			case Success(formattedCode):
				content += '<div id="codeSampleContainer"><textarea id="codeSample">$formattedCode</textarea></div>';
			case Failure(_):
			case Disabled:
		}

		new JQuery(container).html(content);
		installConfigEventHandler();
		new JQuery("#codeSample").change(onChangeCodeSample);
		new JQuery("#btnDownload").click(onDownloadConfig);
		new JQuery("#btnApply").click(onApplyConfig);
		new JQuery("#btnEdit").click(onEditConfig);
		new JQuery("#configText").change(onChangeConfig);
	}

	function installConfigEventHandler() {
		new JQuery(".config-field-combo").change(onChangeCombo);
		new JQuery(".config-field-bool").change(onChangeBool);
		new JQuery(".config-field-bool-label").click(onClickBoolLabel);
		new JQuery(".config-field-number").change(onChangeNumber);
		new JQuery(".config-field-text").change(onChangeText);
	}

	function onChangeCombo(event:Event) {
		var element:JQuery = new JQuery(event.target);
		var fieldPath:String = element.data(DATA_FIELD_PATH);
		var value:String = element.val();
		applyConfigValue(fieldPath, value);
		updateFormat();
	}

	function onClickBoolLabel(event:Event) {
		var element:JQuery = new JQuery(event.target);
		var fieldPath:String = element.data(DATA_FIELD_PATH);
		element = new JQuery('input[data-field-path="$fieldPath"]');
		element.prop("checked", !element.prop("checked"));
		var value:Bool = false;
		if (element.is(":checked")) {
			value = true;
		}
		new JQuery('label[data-field-path="$fieldPath"]').text(value);
		applyConfigValue(fieldPath, value);
		updateFormat();
	}

	function onChangeBool(event:Event) {
		var element:JQuery = new JQuery(event.target);
		var fieldPath:String = element.data(DATA_FIELD_PATH);

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
		var fieldPath:String = element.data(DATA_FIELD_PATH);
		var value:String = element.val();
		applyConfigValue(fieldPath, value);
		updateFormat();
	}

	function onChangeText(event:Event) {
		var element:JQuery = new JQuery(event.target);
		var fieldPath:String = element.data(DATA_FIELD_PATH);
		var value:String = element.val();
		applyConfigValue(fieldPath, value);
		updateFormat();
	}

	function onChangeCodeSample(event:Event) {
		codeWasModified = true;
		updateFormat();
	}

	function onDownloadConfig(event:Event) {
		var jsonText:String = configFieldRegistry.makeCustomConfig();
		var blob:Any = new Blob([jsonText], {
			type: "application/json;charset=utf-8"
		});
		var hxformatUrl:Any = URL.createObjectURL(blob);
		new JQuery("#downloadLink").attr({
			"download": "hxformat.json",
			"href": hxformatUrl
		})[0].click();
		URL.revokeObjectURL(hxformatUrl);
	}

	function onEditConfig(event:Event) {
		new JQuery("#config").hide();
		var textElement:JQuery = new JQuery("#configText");
		textElement.show();
		textElement.val(configFieldRegistry.makeCustomConfig());
		new JQuery("#btnEdit").hide();
		new JQuery("#btnApply").show();
	}

	function onApplyConfig(event:Event) {
		new JQuery("#config").show();
		new JQuery("#configText").hide();
		onChangeConfig(event);
		new JQuery("#config").html(this.configFieldRegistry.buildConfigHtml());
		new JQuery("#btnEdit").show();
		new JQuery("#btnApply").hide();
		updateFormat();
		installConfigEventHandler();
	}

	function onChangeConfig(event:Event) {
		var textElement:JQuery = new JQuery("#configText");
		var newConfigText:String = textElement.val();
		try {
			configFieldRegistry.setCurrentSampleConfig(newConfigText);
		} catch (e:Any) {}
		updateFormat();
		textElement.val(configFieldRegistry.makeCustomConfig());
	}

	function applyConfigValue(fieldPath:String, value:Any) {
		configFieldRegistry.setFieldValue(fieldPath, value);
		Browser.console.info('setting $fieldPath = $value');
	}

	function updateFormat() {
		var codeElement:JQuery = new JQuery("#codeSample");
		var codeSample:String = codeElement.val();
		if (!codeWasModified) {
			codeSample = currentCodeSample;
		}
		var result:Result = Formatter.format(Code(codeSample), configFieldRegistry.currentConfig);
		switch (result) {
			case Success(formattedCode):
				codeElement.val(formattedCode);
			case Failure(errorMessage):
				Browser.console.info('format failed: $errorMessage');
			case Disabled:
		}
	}
}
