package com.playground_soft.zippicview

import java.io.File
import java.io.IOException
import java.net.URLDecoder
import javax.servlet.ServletException
import javax.servlet.http.HttpServletRequest
import javax.servlet.http.HttpServletResponse
import org.eclipse.jetty.server.Request
import org.eclipse.jetty.server.handler.AbstractHandler
import org.json.JSONStringer

class FileListHandler extends AbstractHandler {

	override handle(String target, Request baseRequest, HttpServletRequest request,
		HttpServletResponse response) throws IOException, ServletException {
		val queries = UrlUtils.parseQueryString(request.queryString)

		val file = if (queries.containsKey("path"))
				new File(URLDecoder.decode(queries.get("path"), "utf-8"))
			else
				File.listRoots.get(0)
				
		val jsonStringer = new JSONStringer
		jsonStringer.object
		jsonStringer.key("path").value(file.absolutePath)
		jsonStringer.key("parent").value(file.absoluteFile.parent)
		
		jsonStringer.key("roots").array()
		for (root : File.listRoots) {
			jsonStringer.object
			jsonStringer.key("path").value(root.absolutePath)
			jsonStringer.endObject
		}
		jsonStringer.endArray()

		jsonStringer.key("children")
		jsonStringer.array

		val fileList = file.listFiles([ File child |
			if(child.directory || child.name.endsWith(".zip")) true else false
		])
		for (child : fileList) {
			jsonStringer.object
			jsonStringer.key("path").value(child.absolutePath)
			jsonStringer.key("name").value(child.name)
			jsonStringer.key("type").value(if(child.directory) "Directory" else "File")
			jsonStringer.endObject
		}
		jsonStringer.endArray
		jsonStringer.endObject

		response.contentType = "application/json"
		response.status = HttpServletResponse.SC_OK

		response.writer.write(jsonStringer.toString)

		baseRequest.handled = true

		return
	}
}