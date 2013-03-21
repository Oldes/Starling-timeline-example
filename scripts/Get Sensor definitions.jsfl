/**
 * Get Sensor definitions
 * @icon	{iconsURI}Design/picture/picture_go.png
 */
 
(function()
{
/*

$dom; // same as fl.getDocumentDOM()

context.layer;        // access the actual Flash layer object
context.frame;        // access the context's frame object
context.keyframes;    // access the keyframes from within the current context's layer
context.elements;     // access the elements within the context's frame

context.setLayer(3);  // update the context layer
context.update();     // update the context to the current IDE context
context.goto();       // force Flash to change the window and timeline to the supplied context
*/

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
	
	var outputNodes = "";
	var outNodes = "";
	var outArcs = "";
	
	var lastFolderName;
	// ----------------------------------------------------------------------------------------------------
	// functions
	var patt = /^Bitmaps\//;
	var pattUseLayer = /^_layer/;
	
	
	// set up the callback functions
    function layerCallback(layer, index) {
		if(!layer.visible) return false;
		//trace("LAYER: "+layer.name + " "+bLayerVisible);
	}
    function frameCallback(element) {  }
    function elementCallback(element) {
	    try {
		//if(bLayerVisible){
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
						
						var re1 = /^P\d+_(.*)/;
						var tmp = re1.exec(element.name);
						if(tmp!=null){
							var connectToNodes = tmp[1].split("_");
							var re2 = /^P(\d+)/;
							var tmp = re2.exec(element.name);
							var fromNode = tmp[1];
							trace(connectToNodes+" "+fromNode);
							outNodes+=","+fromNode;
							for(var i=0;i<connectToNodes.length;i++){
								outArcs += ",["+fromNode+","+connectToNodes[i]+"]";
							}
						}
						var re1 = /^(P\d+)(.*)/;
						var tmp = re1.exec(element.name);
						if(tmp!=null && tmp[1]){
							outputQuadSensors+="addQuadSensor("+target+", '"+ tmp[1] +"', "+Math.round(element.x)+", "+Math.round(element.y)+",  "+Math.round(element.width)+", "+Math.round(element.height)+");\n";
						} else {
							outputQuadSensors+="addQuadSensor("+target+", '"+ element.name +"', "+Math.round(element.x)+", "+Math.round(element.y)+",  "+Math.round(element.width)+", "+Math.round(element.height)+");\n";
						}
						break;
					case "_ZoomRegion_":
						outputZoomRegions+="zoomToRegion("+Math.round(element.x)+", "+Math.round(element.y)+",  "+Math.round(element.width)+", "+Math.round(element.height)+"); //"+element.name+"\n";
						
						break;
				}

			//}
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
	
	trace(outNodes.slice(1));
	trace(outArcs.slice(1));
    context.goto(); 
   // var temp = xjsfl.uri + 'user/temp/';
	//var file = new File(temp + 'test.bat', 'echo hello').open();

})()