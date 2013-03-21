/**
 * Prefix names in the library
 * @icon {iconsURI}Design/image/image.png
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
			//return str.replace(/^Symbol\s+/i,'BroukFrame')
			return str.replace(/Layer /,'S')
		  	//return "K2"+str
		}
		function onCamelize(element, index, elements) {
			if(element.itemType == "folder") return;
			var path = element.name.split('/');
			var oldName = path.pop();
			path = path.join('/');
			var newName = camelize(oldName);
			trace(path+"/"+oldName+" => "+newName);
			element.name = newName;
		}
		
	// =============
	var context = Context.create();
		var collection = $$(':selected');
		collection.reach(onCamelize);
	context.goto();
})()
