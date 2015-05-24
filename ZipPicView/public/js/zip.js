$(function() {
	var currentUri = new URI()
	var currentQueries = currentUri.search(true)
	
	var ajaxUri = new URI("/zip")
	ajaxUri.search(currentQueries)
	
	$.ajax(ajaxUri.toString()).done(function(data) {
		$("#current").append(data.name)
		
		if(data.parent == null){
			$("#parent").addClass("pure-menu-disabled")
		} else {
			$("#parent").attr("href", "/zip.html?file=" + URI.encode(data.name) + "&innerFile=" + URI.encode(data.parent))
		}
		
		var path = URI.decode(data.name)
		var pathSepPos = path.lastIndexOf('/')
		if(pathSepPos < 0)
			pathSepPos = path.lastIndexOf('\\')
		
		path = path.substring(0, pathSepPos + 1)
		
		$("#close").attr("href", "/?path=" + URI.encode(path));		
		
		var $filelist = $("#filelist")
		var $menu_list = $("#menu_list")
		var menu_tmpl = $('#menu_tmpl').html()
		var item_image_tmpl = $('#item_image_tmpl').html()
		Mustache.parse(item_image_tmpl);
		Mustache.parse(menu_tmpl)
		for(i in data.filelist){
			
			if(data.filelist[i].type == "File") {
				var inner_html = 
					Mustache.render(item_image_tmpl, 
						{
							file: URI.encode(data.name),
							innerFile: URI.encode(data.filelist[i].file),
							name: data.filelist[i].name
						});
				$filelist.append(inner_html)
			} else {
				var inner_html = 
					Mustache.render(menu_tmpl, 
						{
							icon: "<i class='fa fa-folder-o'></i>",
							url: "/zip.html?file=" + URI.encode(data.name) + "&innerFile=" + URI.encode(data.filelist[i].file),
							name: data.filelist[i].name
						});
				$menu_list.append(inner_html)
			}
		}
		
		$("#loading").css("visibility", "hidden")
	})
})
