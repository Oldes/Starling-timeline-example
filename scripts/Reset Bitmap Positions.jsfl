/**
 * Reset Bitmap Positions to 0x0 
 * @icon	{iconsURI}UI/icon/icon_update.png
 */
(function()
{
	
	 


	// -----------------------------------------------------------------------------------------------------------------------------------------
	// functions
	
	function resetPosition(element, index, elements){
		trace(element);
		//inspect(element);
		var item = element.libraryItem;
		var timeline = item.timeline;
		if(
		   timeline.layerCount == 1
		   && timeline.frameCount == 1
		   && timeline.layers[0].frameCount == 1
		){
			trace("AAAAAAAAA");
			var frame = timeline.layers[0].frames[0];
			if (frame.elements.length == 1){
				var e = frame.elements[0];
				trace(e.x+ " "+e.y);
				element.x += e.x;
				element.y += e.y;
				e.x = 0;
				e.y = 0;
			}
		}
		//element.setTransformationPoint({x:0, y:0});
	}
	

	xjsfl.init(this);
	clear();
	if(UI.selection)
	{
		var collection	= $(':selected');
		collection.each(resetPosition, []);
	}
	
})()