/**
 * Converts bitmaps on frame selection into movieClips.
 * @icon	{iconsURI}Design/picture/picture_go.png
 * @author David 'Oldes' Oliva
 * oldes@amanita-design.net
 */
 
(function(){
 	xjsfl.init(this);
	clear();
	var context = Context.create();
	var lay, f, layer, frame;
	var document = fl.getDocumentDOM();
	var timeline = document.getTimeline();
	var selectedFrames = timeline.getSelectedFrames();
	var convertShapes=true;
	
	function safeRename(item, name, prefix){
		var counter, newName;
		if(prefix==undefined) prefix = "";
		var newName = prefix + name;
		while($library.itemExists(newName)){
			counter = (counter==undefined)?1:counter+1;
			newName = prefix + name + "_" + counter;
		}
		item.name = newName;
	}

	if(selectedFrames.length>0){
		
		var layerStart = selectedFrames[0];
		var layerEnd   =(selectedFrames.length>3)?selectedFrames[selectedFrames.length-3]:layerStart;
		var frameStart = selectedFrames[1];
		var frameEnd   = selectedFrames[2];

		for(f=frameStart;f<frameEnd;f++){
			for(lay=layerStart;lay<=layerEnd;lay++){
				layer = timeline.layers[lay];
				timeline.currentLayer = lay;
				frame = layer.frames[f];
				if(frame) {
					timeline.currentFrame = f;
					var shapes = new Array();
					if(convertShapes){
						for(i=0;i<frame.elements.length;i++){
							var element = frame.elements[i];
							if(element.elementType == "shape") {
								shapes.push(element);
							}
						}
						for(i=shapes.length-1;i>=0;i--){
							trace("shape: "+i+" "+shapes[i]);
							fl.getDocumentDOM().selectNone();
							//timeline.currentLayer = lay;
							//timeline.currentFrame = f;
							var timeline = fl.getDocumentDOM().getTimeline();
							timeline.setSelectedLayers(lay);
							timeline.setSelectedFrames(f, f);
							fl.getDocumentDOM().selection = new Array(shapes[i]);
							trace("sel:"+lay+" "+f+" "+shapes.length+" "+shapes+" "+fl.getDocumentDOM().selection);
							//inspect(fl.getDocumentDOM());
							//fl.getDocumentDOM().convertToSymbol('movie clip', '', 'top left');
							//trace(document.selection);
							fl.getDocumentDOM().convertSelectionToBitmap();
						}
					}
					for(i=0;i<frame.elements.length;i++){
						var element = frame.elements[i];
						var item = element.libraryItem;
						document.selectNone();
						if(item && item.itemType == "bitmap"){
							trace("ToMovie: "+item.name)
							var timeline = fl.getDocumentDOM().getTimeline();
							timeline.setSelectedLayers(lay);
							timeline.setSelectedFrames(f, f);
							fl.getDocumentDOM().selection = new Array(element);
							var mov = document.convertToSymbol('movie clip', '', 'top left');
							if(mov){
								safeRename(mov,item.shortName,"_MC_");
							}
						}
					}
				}
			}
		}
	}
	context.goto();

})()