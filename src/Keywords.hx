import haxe.ds.ArraySort;

class Keywords {
	var words:Map<String, Array<String>>;
	var pageKeywords:Map<String, Array<String>>;
	var names:Map<String, String>;

	public function new() {
		words = new Map<String, Array<String>>();
		names = new Map<String, String>();
		pageKeywords = new Map<String, Array<String>>();
	}

	public function addKeywords(hash:String, name:String, keywords:Array<String>) {
		pageKeywords.set(hash, keywords);
		names.set(hash, name);
		for (word in keywords) {
			var pageList:Null<Array<String>> = words.get(word);
			if (pageList == null) {
				pageList = [];
				words.set(word, pageList);
			}
			pageList.push(hash);
		}
	}

	public function getKeywordList():Array<String> {
		var keywords:Array<String> = [];
		for (word in words.keys()) {
			keywords.push(word);
		}
		ArraySort.sort(keywords, (s1, s2) -> (s1 == s2) ? 0 : ((s1 < s2) ? -1 : 1));
		return keywords;
	}

	public function getSearchResults(keyword:String):Array<SearchResult> {
		var results:Array<SearchResult> = [];
		keyword = keyword.toLowerCase();

		var pageList:Null<Array<String>> = words.get(keyword);
		if (pageList == null) {
			pageList = [];
		}
		var pages:Array<String> = [];
		for (word in words.keys()) {
			if (!word.contains(keyword)) {
				continue;
			}
			pages = pages.concat(words.get(word));
		}
		for (page in pages) {
			if (pageList.indexOf(page) >= 0) {
				continue;
			}
			pageList.push(page);
		}

		for (page in pageList) {
			var name:String = names.get(page);
			results.push({
				name: name,
				hash: page
			});
		}
		return results;
	}
}

typedef SearchResult = {
	var name:String;
	var hash:String;
}
