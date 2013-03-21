/**
 * Link Bitmaps
 * @icon	{iconsURI}actions/link/link.png
 */
 
(function()
{
	xjsfl.init(this);
	clear();
	
	function linkItem(item){
		if(item.itemType != "folder") {
			trace(item+" "+item.itemType+" "+item.linkageClassName+" "+item.name);
			
			if(item.linkageExportForAS){
				item.linkageClassName=""; 
				item.linkageExportForAS = false;
			}
			
			var linkName = item.name.replace(/[\/ ]/g,'_');
			trace(linkName);
			item.linkageExportForAS = true;
			item.linkageIdentifier = linkName;
			
		}
	}

	var collection = $$(':selected'); //$$(':bitmap');
	collection.each(linkItem);

})()