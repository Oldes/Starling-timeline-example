/**
 * Export bitmaps
 * @icon	{iconsURI}Design/picture/picture_go.png
 */
 
(function()
{
	xjsfl.init(this);
	clear();
	
	var FlaURI = new URI($dom.path);
	var BitmapsDir = FlaURI.folder +"../Bitmaps/"
	trace("OUTPUT DIR: "+BitmapsDir);
	
	var rHasPngExt = /\.png$/i;
	var rInBitmapsFolder = /^Bitmaps/;
	// ----------------------------------------------------------------------------------------------------
	// functions
	
    function exportBitmap(item) {
	    try {
			if(item.itemType == "bitmap"){
				var bitmapName = item.name;
				//Exporting only bitmaps which are inside /Bitmaps folder
				if(rInBitmapsFolder.test(bitmapName)){
					bitmapName = bitmapName.substr(8); //removes the 'Bitmaps/' part
					if(!rHasPngExt.test(bitmapName)) bitmapName+=".png";
					//trace("BITMAP "+bitmapName);
					var uri = URI.asURI(BitmapsDir + bitmapName); 
					var folderURI = URI.getFolder(uri);
					var folder = new Folder(folderURI, true);
					if(item.exportToFile(uri, 100)){
						trace("BITMAP EXPORTED: " + bitmapName);
					} else {
						throw new Error("Unable to export bitmap: "+bitmapName);
					}
				}
			}
		}catch(error){
			debug(error);
		}
	}

	// ----------------------------------------------------------------------------------------------------
	// code
	
	$$(':selected').each(exportBitmap);
	//$$(':bitmap').each(exportBitmap);
})()