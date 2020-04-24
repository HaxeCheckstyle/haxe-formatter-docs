package macros;

import haxe.macro.Context;
import haxe.macro.Expr;

class KeywordHelper {
	#if macro
	public static function makeKeywords(text:String):ExprOf<Array<String>> {
		text = text.replace("\r", "");
		text = text.replace("\n", " ");
		text = text.toLowerCase();
		text = ~/[^a-zA-Z0-9_]/g.replace(text, " ");

		var uniqueWords:Array<String> = [];
		for (word in text.split(" ")) {
			if (uniqueWords.indexOf(word) < 0) {
				uniqueWords.push(word);
			}
		}
		var keywords:Array<ExprOf<String>> = [];
		for (word in uniqueWords) {
			if (word.length <= 3) {
				continue;
			}
			keywords.push({expr: EConst(CString(word.trim())), pos: Context.currentPos()});
		}
		return macro $a{keywords};
	}
	#end
}
