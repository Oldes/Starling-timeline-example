package display
{
	import core.Assets;
	import starling.display.DisplayObject;
	import starling.display.DisplayObjectContainer;
	import starling.display.Quad;
	import starling.filters.ColorMatrixFilter;
    
    
    public class TimelineObject extends DisplayObjectContainer
    {
		public var tintR:Number=1;
		public var tintG:Number=1;
		public var tintB:Number=1;
		public var tintRealR:Number=1;
		public var tintRealG:Number=1;
		public var tintRealB:Number=1;
		public var hasTint:Boolean = false;
		
		public var id:String;
		
		public const cmdMoveDepth:int     = 2;
		public const cmdShowFrame:int     = 128;
		public const cmdPlaceObject:int   = 1;
		public const cmdPlaceNamed:int    = 10;
		public const cmdReplaceObject:int = 5;
		public const cmdRemoveDepth:int   = 3;
		public const cmdLabel:int         = 4;
		public const cmdStartSound:int    = 6;
		public const cmdEnd:int           = 0;
		
        
        public function TimelineObject()
        {
			super();
			dispatching = false;
		}
		public function init():void { };
		
		
		override public function replaceChildAt(child:DisplayObject, index:int, dispose:Boolean = false):DisplayObject {
			
			if(index >= 0 && index < numChildren){
				var obj:DisplayObject = getChildAt(index);
				if (obj is TimelineObject) {
					TimelineObject(obj).release();
				} else if(obj is TimelineShape){
					//trace(3)
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
				//trace(2)	
				//TimelineShape(obj).graphics.disposeBuffers();
			}
			return super.removeChildAt(index, dispose);
		}
		override public function dispose():void {
			if (filter != null) {
				if (filter is ColorMatrixFilter) Assets.addColorMatrixFilter(filter as ColorMatrixFilter);
				filter = null;
			}
			if (id) {
				Assets.removeNamedObject(this);
				id = null;
			}
			name = null;
			removeChildren();
			removeEventListeners();
		}

		/* Releases object and it's content back to pools (not dispose) */
		public function release():void
        {
			if (id) Assets.removeNamedObject(this);

			if (hasTint) {
				tintR = tintG = tintB = 1;
				tintRealR = tintRealG = tintRealB = 1;
				hasTint = false;
			}
			if (filter != null) {
				if (filter is ColorMatrixFilter) Assets.addColorMatrixFilter(filter as ColorMatrixFilter);
				filter = null;
			}
			var n:int = numChildren;
			var child:DisplayObject;
			while (n-- > 0) {
				child = getChildAt(n);
				if (child is Quad) {
					Quad(child).color = 0xFFFFFF;
					removeChildAt(n);
				} else if (child is TimelineObject) {
					TimelineObject(child).release()
					removeChildAt(n, true);
				} else if (child is TimelineShape) {
					//todo: release TimelineShape
					trace("---------- release shape ----- v.1");
					//TimelineShape(child).graphics.disposeBuffers();
					removeChildAt(n);
				} else {
					removeChildAt(n);
				}
				
			}
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