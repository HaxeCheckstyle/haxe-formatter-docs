import Keywords.SearchResult;
import haxe.rtti.Meta;
import js.Browser;
import js.jquery.Event;
import js.jquery.JQuery;
import codesamples.CommonSamples;
import codesamples.EmptylinesSamples;
import codesamples.IndentationSamples;
import codesamples.LineendsSamples;
import codesamples.SamelineSamples;
import codesamples.WhitespaceSamples;
import codesamples.WrappingSamples;
import codesamples.config.ConfigFieldRegistry;
import doc.Docs;

class Navigation {
	static inline var CONTENT_ID = "#content";

	var configFieldRegistry:ConfigFieldRegistry;
	var keywords:Keywords;

	public function new() {
		configFieldRegistry = new ConfigFieldRegistry();
		keywords = new Keywords();
		buildNavigation();
	}

	function buildNavigation() {
		var content:String = "";

		content += '<div id="searchContainer"><input type="text" placeholder="search" id="searchBox" /><button id="searchBtn">Go</button></div>\n';

		content += '<ul class="sections">\n';
		content += buildNavigationsection(Docs);
		content += buildNavigationsection(CommonSamples);
		content += buildNavigationsection(EmptylinesSamples);
		content += buildNavigationsection(IndentationSamples);
		content += buildNavigationsection(LineendsSamples);
		content += buildNavigationsection(SamelineSamples);
		content += buildNavigationsection(WhitespaceSamples);
		content += buildNavigationsection(WrappingSamples);
		content += "</ul>\n";
		new JQuery("#navigation").html(content);
		new JQuery(Browser.window).on("hashchange", onHashChange);

		untyped new JQuery("#searchBox").autocomplete({
			source: keywords.getKeywordList()
		});
		new JQuery("#searchBtn").click(onClickSearch);

		if (Browser.window.location.hash.length > 1) {
			onHashChange(null);
		}
	}

	function buildNavigationsection(c:Any):String {
		var sectioName:String = Meta.getType(c).sectionName[0];

		var className:String = Type.getClassName(c);
		var content:String = '<li class="section">$sectioName\n<ul class="sectionEntries">\n';
		for (field in Type.getInstanceFields(c)) {
			var fieldMeta = Reflect.field(Meta.getFields(c), field);
			if (fieldMeta == null) {
				continue;
			}
			var name:Null<Array<String>> = Reflect.field(fieldMeta, "codeSampleName");
			if (name == null) {
				name = Reflect.field(fieldMeta, "docName");
			}
			if (name == null) {
				continue;
			}
			var words:Null<Array<Array<String>>> = Reflect.field(fieldMeta, "keywords");
			if (words.length > 0) {
				keywords.addKeywords('$className.$field', name[0], words[0]);
			}

			content += '<li data-class-name="$className" data-field-name="$field">'
				+ '<a href="#$className.$field" data-class-name="$className" data-field-name="$field">${name[0].replace(".", " ")}</a></li>';
		}
		content += "</ul>\n</li>\n";
		return content;
	}

	function onHashChange(event:Event) {
		var name:String = Browser.window.location.hash;
		if (name.startsWith("#")) {
			name = name.substr(1);
		}
		if (name.startsWith("search=")) {
			showSearchResults(name.substr(7));
			return;
		}

		var parts:Array<String> = name.split(".");
		var fieldName:String = parts.pop();
		var className:String = parts.join(".");

		var instance:Null<Class<Any>> = Type.createInstance(Type.resolveClass(className), []);
		if (instance == null) {
			new JQuery(CONTENT_ID).html("");
			return;
		}
		var field:Null<Any> = Reflect.field(instance, fieldName);
		if (field == null) {
			new JQuery(CONTENT_ID).html("");
			return;
		}
		Reflect.callMethod(instance, field, [CONTENT_ID, configFieldRegistry]);

		new JQuery(".sectionEntries li").removeClass("active");
		new JQuery(".sectionEntries li").filter('[data-class-name="$className"]').filter('[data-field-name="$fieldName"]').addClass("active");
	}

	function onClickSearch(event:Event) {
		Browser.window.location.hash = "#search=" + new JQuery("#searchBox").val();
	}

	function showSearchResults(search:String) {
		var content:String = "<h1>search results</h1>\n";

		var results:Array<SearchResult> = keywords.getSearchResults(search);
		if (results.length <= 0) {
			return;
		}
		content += '<ul id="searchResultContainer">\n';
		for (result in results) {
			content += '<li><a href="#${result.hash}">${result.name.replace(".", " ")}</a></li>\n';
		}
		content += "</ul>\n";

		new JQuery("#content").html(content);
	}
}
