/**
 * Unlink Selected
 * @icon	{iconsURI}actions/link/link_delete.png
 */
 
(function()
{
	xjsfl.init(this);
	clear();
	
	function unlinkItem(item){
		if(item.itemType != "folder" && item.linkageExportForAS) {
			trace("unlinking: "+item.name);
			item.linkageClassName=""; 
			item.linkageExportForAS = false;
		}
	}

	$$(':selected').each(unlinkItem);
	trace("- - - - -\nUnlinking finished.");
})()