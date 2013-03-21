/**
 * TEST Sprite definitions for Starling
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
	var hasPngExt = /\.png$/i;
	var assetIndex = 0;
	var container = "";
	
	var lastFolderName;
	// ----------------------------------------------------------------------------------------------------
	// functions
	var patt = /^Bitmaps\//;
	var pattUseLayer = /^_layer/;
	
	
	
	

	function outputBitmap(bmp, element){
		var bitmapName = bmp.libraryItem.name;
		//if(!hasPngExt.test(bitmapName)) bitmapName+=".png";
		bitmapName.replace(/\.png$/, '');
		//trace("ImgSprite('"+bitmapName+"', "+element.x+", "+element.y+")");
		var layer = element.layer;
		var parentLayer = layer.parentLayer;
		if(parentLayer && parentLayer.layerType == "folder" && pattUseLayer.test(parentLayer.name)){
			container = parentLayer.name+".";
			if(lastFolderName != parentLayer.name) {
				lastFolderName = parentLayer.name;
				outputDefinitions += "		static public const "+lastFolderName+":Sprite = new Sprite();\n";
			}
		} else {
			container = "";
		}
		
		outputEmbeding += "		[Embed(source = '/../bin/"+bitmapName+"')] //"+element.width+"x"+element.height+"\n"
						+ "		public static const BMPAsset"+assetIndex+":Class;\n";
		
		outputTmp       = "		img = Assets.getImage('"+bitmapName.replace(patt,"")+"');\n"
		//"		img = new Image(Texture.fromBitmap(new BMPAsset"+assetIndex+"() as Bitmap, false));\n"
		                + "		img.x = "+element.x+"; img.y = "+element.y+";\n";
		if(element.colorMode == 'alpha'){
			 outputTmp += "		img.alpha = "+element.colorAlphaPercent/100+";\n";
		}
		if(element.scaleX != 1){
			 outputTmp += "		img.scaleX = "+element.scaleX+";\n";
		}
		if(element.scaleY != 1){
			 outputTmp += "		img.scaleY = "+element.scaleY+";\n";
		}
		if(element.rotation){
			 outputTmp += "		img.rotation = "+(element.rotation * 1.74532925199433E-2) +";\n";
		}
		outputTmp      += "		"+ container +"addChild(img);\n";
		outputImages = outputTmp + outputImages;
		assetIndex++;	
	}
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
				if("_QuadSensor_" == element.libraryItem.name){
					var layer = element.layer;
					var parentLayer = layer.parentLayer;
					var target = "this";
					if(parentLayer && parentLayer.layerType == "folder" && pattUseLayer.test(parentLayer.name)){
						target = parentLayer.name;
					}
					outputQuadSensors+="addQuadSensor("+target+", '"+ element.name +"', "+Math.round(element.x)+", "+Math.round(element.y)+",  "+Math.round(element.width)+", "+Math.round(element.height)+");\n";
				} else {
					$library.selectItem(element.libraryItem.name);
					$library.editItem();
					var tmpCollection = $('*');
					if(tmpCollection.elements.length==1){
						var bmp = tmpCollection.elements[0];
						if(bmp.instanceType == "bitmap"){
							outputBitmap(bmp, element);
						}	
					}
					//Iterators.layers(element, layerCallback, frameCallback, elementCallback);
				}

			}else if(element.instanceType == "bitmap"){
				outputBitmap(element, element);
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
    
	trace(outputDefinitions);
    //trace(outputEmbeding);
    trace(outputImages);
	trace(outputQuadSensors);
    context.goto(); 
   // var temp = xjsfl.uri + 'user/temp/';
	//var file = new File(temp + 'test.bat', 'echo hello').open();

})()