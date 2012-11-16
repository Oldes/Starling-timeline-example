package display
{
    import flash.errors.IllegalOperationError;
	import flash.geom.Matrix;
	import flash.geom.Rectangle;
    import flash.media.Sound;
	import flash.system.System;
	import flash.utils.ByteArray;
	import starling.display.DisplayObject;
	import starling.display.DisplayObjectContainer;
	import starling.display.Image;
	import starling.display.Quad;
	import starling.display.Sprite;
	import starling.filters.ColorMatrixFilter;
    
    import starling.textures.Texture;
    
    
    public class TimelineObject extends DisplayObjectContainer
    {
		private var mControlTags:ByteArray;
		public var tintR:Number=1;
		public var tintG:Number=1;
		public var tintB:Number=1;
		public var tintRealR:Number=1;
		public var tintRealG:Number=1;
		public var tintRealB:Number=1;
		public var cxFormMatrix:Vector.<Number>;
		public var cxFilter:ColorMatrixFilter;
		public var hasTint:Boolean = false;
		
		public const cmdMoveDepth:int     = 2;
		public const cmdShowFrame:int     = 128;
		public const cmdPlaceObject:int   = 1;
		public const cmdReplaceObject:int = 5;
		public const cmdRemoveDepth:int   = 3;
		public const cmdLabel:int         = 4;
		public const cmdStartSound:int    = 6;
		public const cmdEnd:int           = 0;
		
        
        public function TimelineObject()
        {
			super();
		}
		public function init():void { };
		
		override public function replaceChildAt(child:DisplayObject, index:int, dispose:Boolean = false):DisplayObject {
			
			if(index >= 0 && index < numChildren){
				var obj:DisplayObject = getChildAt(index);
				if (obj is TimelineObject) {
					TimelineObject(obj).release();
				} else if(obj is TimelineShape){
					trace(3)
					//TimelineShape(obj).graphics.disposeBuffers();
				}
			}
			return super.replaceChildAt(child, index, dispose)
		}
		override public function removeChildAt(index:int, dispose:Boolean = false):DisplayObject {
			var obj:DisplayObject = getChildAt(index);
			if (obj is TimelineObject) {
				TimelineObject(obj).release();
			} else if (obj is TimelineShape) {
			trace(2)	
				//TimelineShape(obj).graphics.disposeBuffers();
			}
			return super.removeChildAt(index, dispose);
		}
		public function release():void
        {
			/*if (cxFormMatrix) {
				cxFormMatrix.length = 0;
				cxFormMatrix = null;
				filter = null;
			}*/
			tintR = tintG = tintB = 1;
			tintRealR = tintRealG = tintRealB = 1;
			hasTint = false;
			if (this is TimelineMovie) TimelineMovie(this).stop();
			var n:int = numChildren;
			var child:DisplayObject;
			while (n > 0) {
				n--;
				child = getChildAt(n);
				if (child is TimelineObject) {
					TimelineObject(child).release()
					removeChildAt(n, true);
				} else if (child is TimelineShape) {
					trace(1);
					//TimelineShape(child).graphics.disposeBuffers();
					removeChildAt(n);
				} else if (child is Quad) {
					Quad(child).color = 0xFFFFFF;
					removeChildAt(n);
				} else {
					
					removeChildAt(n);
				}
				
			}
			System.pauseForGCIfCollectionImminent();
			//log("release finished");
        }
		public function removeTint():void {
			//log("removing tint")
			
			if (hasTint) {
				updateTint(1, 1, 1)
			} else {
				tintR = tintG = tintB = 1;
				tintRealR = tintRealG = tintRealB = 1;
			}
			hasTint = false;
		}
		public function updateTint(r:Number, g:Number, b:Number):void {
			var n:int = numChildren;
			tintRealR *= r;
			tintRealG *= g;
			tintRealB *= b;
			var child:DisplayObject;
			while (n > 0) {
				n--;
				child = getChildAt(n);
				if (child is TimelineObject) {
					TimelineObject(child).updateTint(tintRealR, tintRealG, tintRealB);
				} else if (child is Quad) {
					Quad(child).color = (int((255 * tintRealR))<<16) + (int(255 * tintRealG)<<8) + (int(255 * tintRealB));
					//log("WWW:" + tintRealR, tintRealG, tintRealB,Quad(child).color);
					//Quad(child).color = (4228250625 * tintRealR) + (16581375 * tintRealG) + (65025 * tintRealB);
				}				
			}
		}
		public function setColorTransform(r:Number, g:Number, b:Number):void {
			/*
			if (cxFormMatrix == null) {
				cxFormMatrix = Vector.<Number>([
					r, 0, 0, 0, 0, // red
					0, g, 0, 0, 0, // green
					0, 0, b, 0, 0, // blue
					0, 0, 0, 1, 0]); // alpha
				filter = new ColorMatrixFilter();
			} else {
				cxFormMatrix[0]  = r;
				cxFormMatrix[6]  = g;
				cxFormMatrix[12] = b;
			}
			ColorMatrixFilter(filter).matrix = Vector.<Number>([
					r, 0, 0, 0, 0, // red
					0, g, 0, 0, 0, // green
					0, 0, b, 0, 0, // blue
					0, 0, 0, 1, 0]); // alpha;
			*/
			tintR = tintRealR = r;
			tintG = tintRealG = g;
			tintB = tintRealB = b;
			hasTint = true;
			if (parent) {
				var p:TimelineObject = TimelineObject(parent);
				if(p && p.hasTint) {
					tintRealR *= p.tintRealR;
					tintRealG *= p.tintRealG;
					tintRealB *= p.tintRealB;
				}
			}
			updateTint(tintRealR, tintRealG, tintRealB);
		}
	}
}