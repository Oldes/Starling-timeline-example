/**
 * Move bitmaps
 * @icon	{iconsURI}Design/picture/picture_go.png
 */
 
(function()
{
	xjsfl.init(this);
	clear();
	
	var levelName = "Klicnice";
	var bitmapPackage = "KlicniceNormal";
	
	var targetFolder = "Bitmaps/"+levelName+"/"+bitmapPackage;
	
	if(!$library.itemExists("Bitmaps")) $library.newFolder("Bitmaps");
	if(!$library.itemExists("Bitmaps/"+levelName)) $library.newFolder("Bitmaps/"+levelName);
	if(!$library.itemExists(targetFolder)) $library.newFolder(targetFolder);
	
	//var FlaURI = new URI($dom.path);
	//var BitmapsDir = FlaURI.folder +"../Bitmaps/"
	//trace("OUTPUT DIR: "+BitmapsDir);
	
	var rHasPngExt = /\.png$/i;
	var rInBitmapsFolder = /^Bitmaps/;

	// ----------------------------------------------------------------------------------------------------
	// code
	
	var items = $$(':selected:bitmap').elements;
	for each(var item in items){
		trace("Moving: "+item.name +" -> "+ $library.moveToFolder(targetFolder, item.name));
	}

})()