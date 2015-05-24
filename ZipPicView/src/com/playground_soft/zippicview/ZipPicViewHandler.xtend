package com.playground_soft.zippicview

import java.io.IOException
import java.util.Collections
import javax.servlet.ServletException
import javax.servlet.http.HttpServletRequest
import javax.servlet.http.HttpServletResponse
import org.apache.commons.compress.archivers.zip.ZipFile
import org.eclipse.jetty.server.Request
import org.eclipse.jetty.server.handler.AbstractHandler
import org.json.JSONStringer
import java.util.Map
import org.imgscalr.Scalr
import javax.imageio.ImageIO
import java.net.URLDecoder
import org.apache.commons.compress.archivers.zip.ZipArchiveEntry

class ZipPicViewHandler extends AbstractHandler {

	override handle(String target, Request baseRequest, HttpServletRequest request,
		HttpServletResponse response) throws IOException, ServletException {

		val queries = UrlUtils.parseQueryString(request.queryString)
		val file = if(queries.containsKey("file")) URLDecoder.decode(queries.get("file"), "utf-8") else null
		if(file == null) return

		val innerFile = if (queries.containsKey("innerFile"))
				URLDecoder.decode(queries.get("innerFile"), "utf-8")
			else
				""

		val zipFile = new ZipFile(file)

		if (innerFile == "" || zipFile.getEntry(innerFile).directory)
			handleDirectory(file, zipFile, innerFile, queries, target, baseRequest, request, response)
		else
			handleFile(file, zipFile, innerFile, queries, target, baseRequest, request, response)

		zipFile.close
	}

	def handleDirectory(String file, ZipFile zipFile, String innerFile, Map<String, String> queries, String target,
		Request baseRequest, HttpServletRequest request,
		HttpServletResponse response) throws IOException, ServletException  {

			val jsonStringer = new JSONStringer
			jsonStringer.object()
			jsonStringer.key("name").value(file)
			
			if(!innerFile.empty) {
				var parent = innerFile.substring(0, innerFile.length - 1)
				if(parent.lastIndexOf('/') > 0)
					parent = parent.substring(0, parent.lastIndexOf('/') + 1)
				else
					parent = ""
				jsonStringer.key("parent").value(parent)
			}
			
			jsonStringer.key("filelist")
			jsonStringer.array

			val entries = Collections.list(zipFile.entries)
				.filter[ZipArchiveEntry entry|
					if (entry.name.startsWith(innerFile)) {
						val startStripped = entry.name.substring(innerFile.length)

						if (!startStripped.empty && 
							(startStripped.indexOf('/') < 0 || startStripped.indexOf('/') == startStripped.length - 1)) {
							true
						} else {
							false
						}
					} else {
						false
					}
				]
				.sortWith[ZipArchiveEntry entry1, ZipArchiveEntry entry2|
					if(entry1.directory == entry2.directory) {
						return entry1.name.compareTo(entry2.name)
					}
					
					if(entry1.directory && !entry2.directory ){
						return -1
					}
					
					if(entry2.directory && !entry1.directory) {
						return 1
					}
					return 0
				]
				
			for (entry : entries) {
				val name = entry.name
				val type = if(entry.directory) "Directory" else "File"
				if (type == "Directory" || name.endsWith(".png") || name.endsWith(".jpeg") ||
							name.endsWith(".jpg") || name.endsWith(".gif")) {
					jsonStringer.object
					val filename = switch (type) {
						case "File":
							name.substring(name.lastIndexOf("/") + 1)
						case "Directory": {
							val strippedEnd = name.substring(0, name.length - 1)
							strippedEnd.substring(strippedEnd.lastIndexOf("/") + 1)
					}
				}
				jsonStringer.key("name").value(filename)
				jsonStringer.key("file").value(name)
				jsonStringer.key("type").value(type)
				jsonStringer.endObject
			}
		}
		jsonStringer.endArray
		jsonStringer.endObject
		response.contentType = "application/json"
		response.writer.write(jsonStringer.toString)
		baseRequest.handled = true
	}

	def handleFile(String file, ZipFile zipFile, String innerFile, Map<String, String> queries,
		String target, Request baseRequest, HttpServletRequest request,
		HttpServletResponse response) throws IOException, ServletException {
		val entry = zipFile.getEntry(innerFile)
		val inputStream = zipFile.getInputStream(entry)

		val thumbSize = queries.get("size")
		if (thumbSize == null) {
			val buffer = newByteArrayOfSize(512)
			var read = 0

			while ((read = inputStream.read(buffer)) > 0) {
				response.outputStream.write(buffer, 0, read)
			}
			inputStream.close
		} else {
			val srcImg = ImageIO.read(inputStream)
			val destImg = Scalr.resize(srcImg, Scalr.Method.AUTOMATIC, Scalr.Mode.AUTOMATIC,
				Integer.parseInt(thumbSize))
			ImageIO.write(destImg, "jpg", response.outputStream)
		}
		inputStream.close
		baseRequest.handled = true
	}
}