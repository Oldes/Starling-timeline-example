/**
 * Convert Symbols to bitmaps
 * @icon	{iconsURI}Design/picture/picture_go.png
 */
 
(function()
{
	xjsfl.init(this);
	clear();
	
	//var FlaURI = new URI($dom.path);
	//var BitmapsDir = FlaURI.folder +"../Bitmaps/"
	//trace("OUTPUT DIR: "+BitmapsDir);
	
	var rHasPngExt = /\.png$/i;
	var rInBitmapsFolder = /^Bitmaps/;
	// ----------------------------------------------------------------------------------------------------
	// functions
	
    function symbolToBitmap(item) {
			$library.editItem(item.name);
			var id = item.name.substr(9);
			//trace(id);
			var timeline = item.timeline;
			//timeline.currentLayer = 0;
			//timeline.currentFrame = 0;
			document.selectAll();
			
			//if(document.convertSelectionToBitmap() == true){
				timeline.layers[0].frames[0].elements[0].libraryItem.name = "BMP"+id;
			//}
	}

	// ----------------------------------------------------------------------------------------------------
	// code
	fl.showIdleMessage(false); 
	var items = $$('__symbol_*:graphic').elements;
	try {
		for each(var item in items)
		{
			
			$library.editItem(item.name);
			var id = item.name.substr(9);
			trace(id);
			var timeline = item.timeline;
			//timeline.currentLayer = 0;
			//timeline.currentFrame = 0;
			document.selectAll();
			document.convertSelectionToBitmap()
			//if(document.convertSelectionToBitmap() == true){
				timeline.layers[0].frames[0].elements[0].libraryItem.name = "BMP"+id;
			//}
		}
	}catch(error){
			debug(error);
		}
	/*
	var items = $$('__symbol_*:graphic').elements; // note the use of multiple selectors rather than an if() statement
	for each(var item in items)
	{
		$library.addItemToDocument({x:0, y:0}, item.name);
		$dom.selectAll();
		$dom.convertSelectionToBitmap();
		// rename item
		$dom.deleteSelection();
	}
	*/
	
	fl.showIdleMessage(true);  
	//$$(':bitmap').each(exportBitmap);
})()