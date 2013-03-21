/**
 * Reset all transformation points to 0x0 
 * @icon	{iconsURI}UI/icon/icon_update.png
 */
(function()
{
	
	xjsfl.init(this);

	function elementCallback(element) {
		element.setTransformationPoint({x:0, y:0});
	}
	Iterators.layers($dom.getTimeline(), null, null, elementCallback);
	
})()