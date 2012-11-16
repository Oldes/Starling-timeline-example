package display
{
    import flash.errors.IllegalOperationError;
	import flash.geom.Matrix;
	import flash.geom.Rectangle;
    import flash.media.Sound;
	import flash.utils.ByteArray;
	import starling.display.DisplayObject;
	import starling.display.DisplayObjectContainer;
	import starling.display.Image;
	import starling.display.Quad;
	import starling.display.Sprite;
    
    import starling.textures.Texture;
    
    
    public class TimelineSprite extends TimelineObject
    {
		private var mControlTags:ByteArray;
        
        public function TimelineSprite(controlTags:ByteArray)
        {
			super();
			var spec:ByteArray = mControlTags = controlTags;
			init();
        }
		override public function init():void {
			removeChildren();
			var spec:ByteArray = mControlTags;
			spec.position = 2; //first 2 bytes are used for frame count
			
			var notBreak:Boolean = true;
			var id:uint, depth:uint, opcode:uint, flags:uint;
			var obj:DisplayObject;
			var tmpMatrix:Matrix = new Matrix();
			var multR:Number, multG:Number, multB:Number;
			do {
				opcode = spec.readUnsignedByte();
				//log("spriteOpcode: " +opcode);
				switch(opcode) {
					
					case cmdPlaceObject:
					case cmdReplaceObject:
						id    = spec.readUnsignedShort();
						depth = spec.readUnsignedShort();
						flags = spec.readUnsignedByte();
						switch(flags & 7) { //first 3 bits
							case 0: //placing image
								obj = Assets.getTimelineObjectByID(id);
								break;
							case 1: //placing object
								obj = Assets.getTimelineObjectByID(id);
								break;
							case 2: //placing shape
								obj = Assets.getTimelineShapeByID(id);
								break;
						}
						if (obj) {
							tmpMatrix.tx = spec.readFloat();
							tmpMatrix.ty = spec.readFloat();
							if(8 == (flags & 8)){//scale
								tmpMatrix.a = spec.readFloat();
								tmpMatrix.d = spec.readFloat();
							} else {
								tmpMatrix.a = 
								tmpMatrix.d = 1;
							}
							if(16 == (flags & 16)){//skew
								tmpMatrix.b = spec.readFloat();
								tmpMatrix.c = spec.readFloat();
							} else {
								tmpMatrix.c = 
								tmpMatrix.b = 0;
							}
							if (32 == (flags & 32)) {//alpha
								obj.alpha = spec.readUnsignedByte() / 255;
							} else {
								obj.alpha = 1;
							}
							if (64 == (flags & 64)) {//color multiply
								multR = spec.readUnsignedByte() / 255;
								multG = spec.readUnsignedByte() / 255;
								multB = spec.readUnsignedByte() / 255;
								//log("Tint (SPRITE): ", multR, multG, multB);
								if (obj is TimelineObject) {
									TimelineObject(obj).setColorTransform(multR, multG, multB);
								} else if (obj is Quad) {
									//log("SETTING QUAD COLOR");
									Quad(obj).color = (int((255 * tintRealR * multR))<<16) + (int(255 * tintRealG * multG)<<8) + (int(255 * tintRealB * multB));
								}
							} else {
								if (obj is TimelineObject) {
									//TimelineObject(obj).removeTint();
								}  else if (obj is Quad) {
									//Quad(obj).color = 0xFFFFFF;
								}
							}
							obj.transformationMatrix = tmpMatrix;
							if (opcode == 1) {
								addChildAt(obj, depth);
							} else {
								replaceChildAt(obj, depth);
							}
						}
						break;
						
					case cmdRemoveDepth:
						depth = spec.readUnsignedShort();
						removeChildAt(depth);
						break;
						
					case cmdMoveDepth:
						depth = spec.readUnsignedShort();
						flags = spec.readUnsignedByte();
						obj = getChildAt(depth);
						if (obj) {
							tmpMatrix.tx = spec.readFloat();
							tmpMatrix.ty = spec.readFloat();
							if(8 == (flags & 8)){//scale
								tmpMatrix.a = spec.readFloat();
								tmpMatrix.d = spec.readFloat();
							} else {
								tmpMatrix.a = 
								tmpMatrix.d = 1;
							}
							if(16 == (flags & 16)){//skew
								tmpMatrix.b = spec.readFloat();
								tmpMatrix.c = spec.readFloat();
							} else {
								tmpMatrix.c = 
								tmpMatrix.b = 0;
							}
							if (32 == (flags & 32)) {//alpha
								obj.alpha = spec.readUnsignedByte() / 255;
							}
							if (64 == (flags & 64)) {//color multiply
								multR = spec.readUnsignedByte() / 255;
								multG = spec.readUnsignedByte() / 255;
								multB = spec.readUnsignedByte() / 255;
								//log("Tint (Movie): ", multR, multG, multB);
								if (obj is TimelineObject) {
									TimelineObject(obj).setColorTransform(multR, multG, multB);
								} else if (obj is Quad) {
									Quad(obj).color = (
										int((255 * tintRealR * multR)) << 16)
										+ (int(255 * tintRealG * multG) << 8)
										+ (int(255 * tintRealB * multB));
								}
							}
							obj.transformationMatrix = tmpMatrix;
						}
						break;
						
					case cmdShowFrame:
						notBreak = false;
						break;
				}
			} while (notBreak);	
		}
		override public function replaceChildAt(child:DisplayObject, index:int, dispose:Boolean = false):DisplayObject {
			
			if(index >= 0 && index < numChildren){
				var obj:DisplayObject = getChildAt(index);
				if (obj is TimelineMovie) {
					TimelineMovie(obj).release();
				} else if (obj is TimelineSprite) TimelineSprite(obj).release();
			}
			return super.replaceChildAt(child, index, dispose)
		}
		override public function removeChildAt(index:int, dispose:Boolean = false):DisplayObject {
			var obj:DisplayObject = getChildAt(index);
			if (obj is TimelineMovie) {
				TimelineMovie(obj).release();
			} else if (obj is TimelineSprite) TimelineSprite(obj).release();
			return super.removeChildAt(index, dispose);
		}

	}
}