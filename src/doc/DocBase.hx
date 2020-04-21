package doc;

import js.jquery.JQuery;

@:keepSub
class DocBase {
	public function buildDocPage(container:String, docName:String, docText:String) {
		var content:String = '<h1>${docName.replace(".", " ")}</h1>\n';

		content += '<div id="markdownContainer">${Markdown.markdownToHtml(docText)}</div>';

		new JQuery(container).html(content);
	}
}
