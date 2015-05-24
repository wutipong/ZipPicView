package com.playground_soft.zippicview

import org.eclipse.jetty.server.Server
import org.eclipse.jetty.server.handler.ContextHandler
import org.eclipse.jetty.server.handler.ContextHandlerCollection
import org.eclipse.jetty.server.handler.HandlerCollection
import org.eclipse.jetty.server.handler.RequestLogHandler
import org.eclipse.jetty.server.NCSARequestLog
import org.eclipse.jetty.server.handler.ResourceHandler
import org.eclipse.jetty.util.resource.Resource
import java.io.File
import java.awt.Desktop
import java.net.URI

class Main {
	static def main(String[] arg) {
		val logDir = new File("./logs")
		if(!logDir.exists) logDir.mkdir()
		
		val log = new NCSARequestLog("./logs/jetty-yyyy_mm_dd.request.log") => [
			retainDays = 90
			append = true
			extended = false
			logLatency = true
		]

		val server = new Server(4000) => [
			handler = new HandlerCollection => [
				handlers = #[
					new ContextHandlerCollection => [
						handlers = #[
							new ContextHandler("/") => [
								handler = new ResourceHandler => [
									//baseResource = Resource.newResource(new File("public"))
									resourceBase = "./public/"
								]
							],
							new ContextHandler("/listfile/*") => [
								handler = new FileListHandler
							],
							new ContextHandler("/zip/*") => [
								handler = new ZipPicViewHandler
							]
						]
					],
					new RequestLogHandler => [requestLog = log]
				]
			]
		]

		server.start();
		server.dumpStdErr();
		
		if(Desktop.desktopSupported) {
			Desktop.desktop.browse(new URI("http://localhost:4000/"))
		}
		server.join();
		return
	}
}