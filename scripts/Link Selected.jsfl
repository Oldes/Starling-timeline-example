/**
 * Link Selected
 * @icon	{iconsURI}actions/link/link.png
 */
 
(function()
{
	xjsfl.init(this);
	clear();
	
	function linkItem(item){
		if(item.itemType != "folder") {
			var linkName = item.shortName.replace(/[\/ ]/g,'_');
			trace("Linking: "+item.name+" ==> "+linkName);
			item.linkageExportForAS = true;
			item.linkageExportInFirstFrame = true;
			item.linkageIdentifier = linkName;
		}
	}
	
	$$(':selected').each(linkItem);
	trace("- - - - -\nLinking finished.");

})()