/**
 * 
 */

$(function() {
	var currentUri = new URI()
	var currentQueries = currentUri.search(true)
	
	var ajaxUri = new URI("/listfile")
	ajaxUri.search(currentQueries)
	
	$.ajax(ajaxUri.toString()).done(function(data) {
		$("#current").append("Current Path : " + data.path)
		var root_tmpl = $('#root_tmpl').html()
		Mustache.parse(root_tmpl);
		var $location = $("#location")
		for (root in data.roots) {
			var inner_html = 
				Mustache.render(root_tmpl, 
					{
						path: data.roots[root].path,
						encoded: URI.encode(data.roots[root].path)
					});
			$location.append(inner_html)
		}
		if (data.parent == null) {
			$("#parent").addClass("pure-menu-disabled")
		} else {
			$("#parent").attr("href", "/?path=" + URI.encode(data.parent))
		}

		var item_tmpl = $('#item_tmpl').html()
		Mustache.parse(item_tmpl);
		
		var $filelist = $("#filelist")
		for (i in data.children) {
			var child = data.children[i]
			var icon = ""
			var url = ""
			if(child.type == "File") {
				icon = "<i class='fa-li fa fa-file-archive-o'></i>"
				url = '/zip.html?file=' + URI.encode(child.path)
			} else {
				icon = "<i class='fa-li fa fa-folder-o'></i>"
				url = '/?path='	+ URI.encode(child.path)
			}
			
			var inner_html = 
				Mustache.render(item_tmpl, 
					{
						icon: icon,
						url: url,
						name: child.name
					});
			$filelist.append(inner_html)
		}
		$("#loading").css("visibility", "hidden")
	})
})