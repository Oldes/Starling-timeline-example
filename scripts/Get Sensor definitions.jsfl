/**
 * Get Sensor definitions
 * @icon	{iconsURI}Design/picture/picture_go.png
 */
 
(function()
{
	// ----------------------------------------------------------------------------------------------------
	// variables
	
	var bLayerVisible;
	var outputEmbeding = "";
	var outputImages = "";
	var outputTmp = "";
	var outputDefinitions = "";
	var outputQuadSensors = "";
	var outputZoomRegions = "";
	var hasPngExt = /\.png$/i;
	var assetIndex = 0;
	var container = "";
	
	var lastFolderName;
	// ----------------------------------------------------------------------------------------------------
	// functions
	var patt = /^Bitmaps\//;
	var pattUseLayer = /^_layer/;
	
	
	// set up the callback functions
    function layerCallback(layer, index) {
		bLayerVisible = layer.visible;
		//trace("LAYER: "+layer.name + " "+bLayerVisible);
	}
    function frameCallback(element) {  }
    function elementCallback(element) {
	    try {
		if(bLayerVisible){
			//trace("ELEMENT: "+element.name + " "+element.elementType +" "+element.instanceType);
			if(element.instanceType == "symbol"){
				switch(element.libraryItem.name){
					case "_QuadSensor_":
						var layer = element.layer;
						var parentLayer = layer.parentLayer;
						var target = "this";
						if(parentLayer && parentLayer.layerType == "folder" && pattUseLayer.test(parentLayer.name)){
							target = parentLayer.name;
						}
						outputQuadSensors+="addQuadSensor("+target+", '"+ element.name +"', "+Math.round(element.x)+", "+Math.round(element.y)+",  "+Math.round(element.width)+", "+Math.round(element.height)+");\n";
						break;
					case "_ZoomRegion_":
						outputZoomRegions+="zoomToRegion("+Math.round(element.x)+", "+Math.round(element.y)+",  "+Math.round(element.width)+", "+Math.round(element.height)+"); //"+element.name+"\n";
						
						break;
				}

			}
		}
		}catch(error){
			debug(error);
		}
	}

	// ----------------------------------------------------------------------------------------------------
	// code
	xjsfl.init(this);
	clear();
	var context = Context.create();
	
    Iterators.layers($dom.getTimeline(), layerCallback, frameCallback, elementCallback);

	trace(outputQuadSensors);
	trace(outputZoomRegions);
    context.goto(); 
   // var temp = xjsfl.uri + 'user/temp/';
	//var file = new File(temp + 'test.bat', 'echo hello').open();

})()