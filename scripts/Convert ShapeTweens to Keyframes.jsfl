/**
 * Convert ShapeTweens to Keyframes
 * @icon	{iconsURI}Design/picture/picture_go.png
 * @author David 'Oldes' Oliva
 * oldes@amanita-design.net
 */
 
(function(){
 	xjsfl.init(this);
	clear();
	
	var bLayerVisible;
	var previousLayer;
	var previousLayerLocked;
	
	var timeline = $dom.getTimeline();
	try {		
		function processItem(item) {
			if(item.itemType=="movie clip" || item.itemType == "graphic"){
				var timeline = item.timeline;
				
				var layerNum=timeline.layers.length;
				trace(item.name+" "+layerNum);
				while(layerNum>0){
					layerNum--;
					var layer = timeline.layers[layerNum];
					//trace(" ---- "+layer.name)
					previousLayerLocked = layer.locked;
					layer.locked = false;
					timeline.currentLayer = layerNum;
					var frames = layer.frames;
					var framesNum = frames.length;
					//trace(framesNum);
					var n = 0;
					while(n < framesNum){
						var frame = frames[n];
						//trace(frame.tweenType)
						//trace(n +" "+ frame.startFrame);
						if(frame.tweenType == "shape") {
							if(n == frame.startFrame){
								var endFrameNum = frame.startFrame+frame.duration;
								trace(n+" "+" "+frame.startFrame+ " "+endFrameNum+" "+framesNum);
								//shapeTweenFrames.push(frame)
								timeline.currentFrame = n;
								if( endFrameNum < framesNum) {
									
									timeline.convertToKeyframes(frame.startFrame, endFrameNum );
								} else {
									trace("!!!!!!!!!!!!!!!!!! "+ endFrameNum+" "+framesNum);
								}
								for(var i=frame.startFrame;i<endFrameNum; i++){
									timeline.currentFrame=i;
									timeline.setFrameProperty('tweenType', 'none');
								}
							} else {
								trace("XXXXXXXXXXXXXXXXX "+n+" "+frame.startFrame);
								timeline.currentFrame=n;
								timeline.setFrameProperty('tweenType', 'none');
							}
						}
						n++;
					}
				}
			}
		}
		$$('*').each(processItem);
		trace("DONE");
	} catch(err){ debug(err);}
})()