package display
{
	import core.Assets;
	import memory.Memory;
	import flash.geom.Matrix;
	import starling.display.DisplayObject;
	import starling.display.DisplayObjectContainer;
	import starling.filters.ColorMatrixFilter;
    
	//import apparat.memory.Memory;
	//import apparat.memory.MemoryPool;
	
	import avm2.intrinsics.memory.*;

    public class TimelineSprite extends TimelineObject
    {
        private var mPointerHead:int;
		private var mPointerTail:int;
		private var mPointer:int;
		
        public function TimelineSprite(memoryBlock:TimelineMemoryBlock)
        {
			mPointerHead = memoryBlock.head;
			mPointerTail = memoryBlock.tail;
			mPointer = mPointerHead;
			
			super();
			init();
        }
		public function unload():void {
			super.dispose();
		}
		override public function init():void {
			removeChildren();
			var p:int = mPointerHead + 2; //memory pointer - first 2 bytes are used for frame count (always 1 in this case)
			
			var notBreak:Boolean = true;
			var id:uint, depth:uint, opcode:uint, flags:uint;
			var obj:DisplayObject;
			var tmpMatrix:Matrix = new Matrix();
			var multR:Number, multG:Number, multB:Number;
			var clrFilter:ColorMatrixFilter 
			do {
				opcode = li8(p);
				p++;
				//log("spriteOpcode: " +opcode);
				switch(opcode) {
					case cmdPlaceNamed:
						var nameID:String = Memory.readUTF(p);
						p = Memory.buffer.position;
					case cmdPlaceObject:
					case cmdReplaceObject:
						id    = li16(p);
						depth = li16(p + 2);
						flags = li8(p + 4);
						p += 5;
						//trace("Sprite FLAGS: " + flags + " " + (flags & 7));
						switch(flags & 7) { //first 3 bits
							case 0: //placing image
								obj = Assets.getTimelineImageByID(id, touchable);
								break;
							case 1: //placing object
								obj = Assets.getTimelineObjectByID(id, touchable);
								break;
							case 2: //placing shape
								obj = Assets.getTimelineShapeByID(id);
								break;
						}
						if (obj) {
							if (8 == (flags & 8)) {//xy
								tmpMatrix.tx = lf32(p);
								tmpMatrix.ty = lf32(p + 4);
								p += 8;
							} else {
								tmpMatrix.tx = 0;
								tmpMatrix.ty = 0;
							}
							if(16 == (flags & 16)){//scale
								tmpMatrix.a = lf32(p);
								tmpMatrix.d = lf32(p + 4);
								p += 8;
							} else {
								tmpMatrix.a = 
								tmpMatrix.d = 1;
							}
							if(32 == (flags & 32)){//skew
								tmpMatrix.b = lf32(p);
								tmpMatrix.c = lf32(p + 4);
								p += 8;
							} else {
								tmpMatrix.c = 
								tmpMatrix.b = 0;
							}
							/*if (64 == (flags & 64)) {//alpha
								obj.alpha = li8(p) / 255;
								p++;
							} else {
								obj.alpha = 1;
							}
							if (128 == (flags & 128)) {//color multiply
								multR = li8(p) / 255;
								multG = li8(p + 1) / 255;
								multB = li8(p + 2) / 255;
								p += 3;
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
							}*/
							if (64 == (flags & 64)) {//colorMatrix
								clrFilter = Assets.getColorMatrixFilter();
								clrFilter.setShaderColorMatrix(
									lf32(p),
									lf32(p+4),
									lf32(p+8),
									lf32(p+12),
									lf32(p+16),
									lf32(p+20),
									lf32(p+24),
									lf32(p+28)
								);
								obj.filter = clrFilter;
								p += 32;
								
							} else if (128 == (flags & 128)) {
								obj.alpha = li8(p) / 255;
								p++;
							} else {
								obj.alpha = 1;
							}
							obj.transformationMatrix = tmpMatrix;
							switch (opcode) {
								case cmdPlaceObject:
									addChildAt(obj, depth);
									break;
								case cmdPlaceNamed:
									Assets.addNamedObject(obj as TimelineObject, nameID);
									addChildAt(obj, depth);
									break;
								default:
									removeChildAt(depth);
									addChildAt(obj, depth);
									//replaceChildAt(obj, depth); //<-this is not in official Starling framework
							}
							
							if (dispatching && obj is DisplayObjectContainer) {
								DisplayObjectContainer(obj).setDispatching(true);
							}
						}
						break;
						
					case cmdRemoveDepth:
						depth = li16(p);
						p += 2;
						removeChildAt(depth);
						break;
						
					/*case cmdMoveDepth:
						depth = li16(p);
						flags = li8(p + 2);
						p += 3;
						obj = getChildAt(depth);
						if (obj) {
							tmpMatrix.tx = lf32(p);
							tmpMatrix.ty = lf32(p + 4);
							p += 8;
							if(8 == (flags & 8)){//scale
								tmpMatrix.a = lf32(p);
								tmpMatrix.d = lf32(p + 4);
								p += 8;
							} else {
								tmpMatrix.a = 
								tmpMatrix.d = 1;
							}
							if(16 == (flags & 16)){//skew
								tmpMatrix.b = lf32(p);
								tmpMatrix.c = lf32(p + 4);
								p += 8;
							} else {
								tmpMatrix.c = 
								tmpMatrix.b = 0;
							}
							if (32 == (flags & 32)) {//alpha
								obj.alpha = li8(p) / 255;
								p++;
							}
							if (64 == (flags & 64)) {//color multiply
								multR = li8(p) / 255;
								multG = li8(p + 1) / 255;
								multB = li8(p + 2) / 255;
								p += 3;
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
						}*/
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