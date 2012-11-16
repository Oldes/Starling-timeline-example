/**
 * Camelize names in the library
 * @icon {iconsURI}Design/style/style.png
 */
(function()
{
	// setup
		xjsfl.init(this);
		var path = "";
		var oldName = "";
		var newName = "";

	// callback
		function camelize(str) {
		  return str.replace(/^layer\s+/i,'')
		    .replace(/^Bitmap\s+/,'')
		    .replace(/\.psd Assets$/,'')
		  	.replace(/_/g, ' ')
			.replace(/(?:^\w|[A-Z]|\b\w|\s+)/g, function(match, index) {
				if (/\s+/.test(match)) return ""; // or if (/\s+/.test(match)) for white spaces
				return match.toUpperCase()//index == 0 ? match.toLowerCase() : match.toUpperCase();
		  	});
		}
		function removePNGExtension(str) {
			return str.replace(/\.png$/, '');
		}
		function onCamelize(element, index, elements) {
			//if(element.itemType == "folder") return;
			var path = element.name.split('/');
			var oldName = path.pop();
			path = path.join('/');
			var newName = camelize(removePNGExtension(oldName));
			trace(path+"/"+oldName+" => "+newName);
			element.name = newName;
		}
		
	// =============
	var context = Context.create();
		var collection = $$(':selected');
		collection.reach(onCamelize);
	context.goto();
})()
