package com.playground_soft.zippicview

import java.util.HashMap
import java.util.Map

class UrlUtils {
	static def parseQueryString(String queryString) {
		val output = new HashMap<String, String>
		if(queryString == null) return output
		
		val splittedQuery = queryString.split("&")

		for (keyval : splittedQuery) {
			val keyvalSplitted = keyval.split("=")
			val key = keyvalSplitted.get(0)
			val value = if(keyvalSplitted.length > 1) keyvalSplitted.get(1) else ""

			output.put(key, value)
		}
		return output as Map<String, String>
	}
}