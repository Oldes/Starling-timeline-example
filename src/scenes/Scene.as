package scenes
{
	import display.SensorQuad;
	import display.TimelineObject;
	import display.TimelineMovie;
	import starling.display.DisplayObject;
	import starling.animation.Tween;
	import starling.display.DisplayObjectContainer;
	import starling.display.Sprite;
	import starling.core.Starling;
	import starling.events.Event;
	import starling.events.Touch;
	import starling.events.TouchPhase;
	import starling.events.TouchEvent;
	import starling.events.EnterFrameEvent;
	
	import flash.geom.Point;
	
	import flash.system.Capabilities;
	import flash.utils.getQualifiedClassName;
	
	import flash.events.MouseEvent;
	/**
	 * ...
	 * @author Oldes
	 */
	public class Scene extends Sprite 
	{
		public var minScale:Number = 1;
		public var maxScale:Number = 1.4;
		public var stageTween:Tween;
		public var isTweening:Boolean = false;
		
		public const gameWidth:Number = 1920;
		public const gameHeight:Number = 1080;
		public var stageWidth:Number;
		public var stageHeight:Number;
		public var maxGameWidth:Number;
		public var maxGameHeight:Number;
		public var maxStageWidthOffset:Number;
		public var maxStageHeightOffset:Number;
		
		public var maxx:Number;
		public var maxy:Number;
		public var scalePercent:Number;
		
		public var _focusX:Number;
		public var _focusY:Number;
		public var _focusPivotX:Number;
		public var _focusPivotY:Number;
		public var _focusScale:Number;
		public var _focusAC:Number = .2;
		
		
		public function Scene() 
		{
			this.addEventListener(Event.ADDED_TO_STAGE, onInit);
		}
		public function onInit(e:Event):void {
			stageWidth = stage.stageWidth;
			stageHeight = stage.stageHeight;
			
			minScale = Math.max(stageHeight / (gameHeight), stageWidth / (gameWidth - 80));
			maxScale = minScale + 0.3;
			
			_focusPivotX = pivotX = gameWidth / 2;
			_focusPivotY = pivotY = gameHeight / 2;
			_focusScale = scaleX = scaleY = minScale;//1 //
			
			scalePercent = scaleX - minScale;
			
			maxGameWidth  = gameWidth  * maxScale;
			maxGameHeight = gameHeight * maxScale;
			
			maxStageWidthOffset  = stageWidth  - maxGameWidth;
			maxStageHeightOffset = stageHeight - maxGameHeight;
			
			maxx = stageWidth  - (((gameWidth  * scaleX) - pivotX));
			maxy = stageHeight - (((gameHeight * scaleY) - pivotY));
			
			//trace("minScale: " + minScale + " maxGameWidth: " + maxGameWidth);
			_focusX = x = stageWidth  / 2;
			_focusY = y = stageHeight / 2;
			
			var serverString:String = unescape(Capabilities.serverString);
			var reportedDpi:Number = Number(serverString.split("&DP=", 2)[1]);
			log("DPI:" + Capabilities.screenDPI, reportedDpi);
			
			zoomEnabled = true;
			this.addEventListener(EnterFrameEvent.ENTER_FRAME, startLevel);
		}
		public override function dispose():void {
			this.removeEventListener(EnterFrameEvent.ENTER_FRAME, onEnterFrame);
			zoomEnabled = false;
			if (stageTween) {
				Starling.juggler.remove(stageTween);
				stageTween = null;
			}
			super.dispose();
			trace("dispose " +this);
		}
		public function set zoomEnabled(value:Boolean):void {
			log("zoomEnabled:" + value);
			if (value) {
				parent.addEventListener(TouchEvent.TOUCH, onTouch);
				Starling.current.nativeStage.addEventListener(MouseEvent.MOUSE_WHEEL, onMouseWheelEvent);
				if(_focusScale > maxScale) _focusScale = maxScale;
			} else {
				parent.removeEventListener(TouchEvent.TOUCH, onTouch);
				Starling.current.nativeStage.removeEventListener(MouseEvent.MOUSE_WHEEL, onMouseWheelEvent);
			}
		}
		protected function startLevel(e:EnterFrameEvent):void {
			log("startLevel: "+getQualifiedClassName(this));
			this.removeEventListener(EnterFrameEvent.ENTER_FRAME, startLevel);
			this.addEventListener(EnterFrameEvent.ENTER_FRAME, onEnterFrame);
		}
		
		public function onResize():void {
			log("scene onResize");
		}
		
		public function onAnimLabel(anim:DisplayObjectContainer, label:String ):void {
			log(label, anim);
		}
		
		public function addQuadSensor(
			target:DisplayObjectContainer, name:String,
			x:Number, y:Number, width:Number, height:Number,
			enabled:Boolean = true
		):void {
			var tmp:SensorQuad = new SensorQuad(name, x, y, width, height, enabled);
			tmp.alpha = 0;
			tmp.addEventListener(TouchEvent.TOUCH, onTouchSensor);
			Game.instance.addSensor(tmp);
			target.addChild(tmp);
		}
		
		public function zoomToRegion(x:Number, y:Number, width:Number, height:Number):void {
			var dx:Number = stageWidth - width;
			var dy:Number = stageHeight - height;
			_focusX = stageWidth / 2
			_focusY = stageHeight / 2;
			_focusPivotX = x + (width / 2);
			_focusPivotY = y + (height / 2);
			log(_focusX, _focusY, "pivot:" +_focusPivotX, _focusPivotY);
			//_focusX = - stage.stageWidth + width; 
			//_focusY = - stage.stageHeight + height; 
			if (dy < dx) {
				//log("zoom y", dy, stageHeight / dy, stageWidth / dx);
				_focusScale = stageHeight / height;
				
			} else {
				//log("zoom x");
				_focusScale = stageWidth / width;
			}
			if (_focusScale > maxScale) _focusScale = maxScale;
			zoomEnabled = false;
			//log(dx, dy, stageHeight-dy);
		}
		
		public function onTouchSensor(e:TouchEvent):void { };
		protected function onEnterFrame(e:EnterFrameEvent):void { };
		
		public function updateParalax():void{};
		
		protected function onTouch(event:TouchEvent):void {
			var touchA:Touch;
			var touchB:Touch
			
			var changed:Boolean = false;

			/*touchA = event.getTouch(this, TouchPhase.BEGAN);
			if (touchA) {
				touchA.getLocation(this, mPoint);
				changed = true;
			}*/
            
			var touches:Vector.<Touch> = event.getTouches(this, TouchPhase.MOVED);
			var numTouches:int = touches.length;
			
            if (numTouches == 1)
            {
				touchA = touches[0];
                // one finger touching -> move
                var delta:Point = touchA.getMovement(parent);
                //x += delta.x;
                //y += delta.y;
				_focusX += delta.x;
				_focusY += delta.y;
					
				changed = true;
				
            } else if (numTouches == 2)
            {
                // two fingers touching -> rotate and scale
				touchA = touches[0];
                touchB = touches[1];
                
                var currentPosA:Point  = touchA.getLocation(parent);
                var previousPosA:Point = touchA.getPreviousLocation(parent);
                var currentPosB:Point  = touchB.getLocation(parent);
                var previousPosB:Point = touchB.getPreviousLocation(parent);
                
                var currentVector:Point  = currentPosA.subtract(currentPosB);
                var previousVector:Point = previousPosA.subtract(previousPosB);
                
				var previousLocalA:Point  = touchA.getPreviousLocation(this);
				var previousLocalB:Point  = touchB.getPreviousLocation(this);


				_focusPivotX = (previousLocalA.x + previousLocalB.x) * 0.5;
				_focusPivotY = (previousLocalA.y + previousLocalB.y) * 0.5;
				_focusX = (currentPosA.x + currentPosB.x)* 0.5;
				_focusY = (currentPosA.y + currentPosB.y) * 0.5;

                // scale
                var sizeDiff:Number = 0.2 * ((currentVector.length / previousVector.length)-1);
				//log(sizeDiff, currentVector.length / previousVector.length);
                _focusScale += sizeDiff;
				if (_focusScale < minScale) {
					_focusScale = minScale;
				} else if (_focusScale > maxScale+.2) {
					_focusScale = maxScale+.2;
				}
				scalePercent = _focusScale - minScale;
				changed = true;
						
            }
			touchA = event.getTouch(this, TouchPhase.ENDED);
				
			if (touchA) {
				if(touchA.tapCount == 2) {
					//trace("DOUBLE TAP");
					var p:Point = touchA.getLocation(this);
					_focusPivotX = p.x;
					_focusPivotY = p.y;
				
					_focusScale = (_focusScale == maxScale)?minScale:maxScale;
					changed = true;
				}
				//trace("ENDED " + numTouches);
				
				if (numTouches == 0 && !isTweening) {
					//trace("Konec tahani");
					if (Math.abs(_focusScale - maxScale) < Math.abs(_focusScale - minScale)) {
						_focusScale = maxScale;
					} else {
						_focusScale = minScale;
					}
					changed = true;
				}
			}
				
			if (changed) {
				//var maxx:Number;
				//var maxy:Number;
				var px:Number;
				var py:Number;
				var dx:Number;
				
				maxx = stage.stageWidth - (_focusScale * (1920 - _focusPivotX)) ;
				px = _focusScale * _focusPivotX;
				maxy = stage.stageHeight - (_focusScale * (1080 - _focusPivotY))
				py = _focusScale * _focusPivotY;
						
				if (_focusX > px) {
					_focusX = px;
				} else if (_focusX < maxx) {
					_focusX = maxx;
				}
						
				if(_focusY > py) {
					_focusY = py;
				} else if(_focusY < maxy) {
					_focusY = maxy;
				}
				
				//log()
				updateParalax();
			}
        }
		
		protected function onMouseWheelEvent(e:MouseEvent):void {
			_focusScale = (e.delta < 0)?minScale:maxScale;
			scalePercent = _focusScale - minScale;
			
			var px:Number;
			var py:Number;
			
			maxx = stage.stageWidth - (_focusScale * (1920 - _focusPivotX)) ;
			px = _focusScale * _focusPivotX;
			maxy = stage.stageHeight - (_focusScale * (1080 - _focusPivotY))
			py = _focusScale * _focusPivotY;
			
			
			if (_focusX > px) {
				_focusX = px;
			} else if (_focusX < maxx) {
				_focusX = maxx;
			}
					
			if(_focusY > py) {
				_focusY = py;
			} else if(_focusY < maxy) {
				_focusY = maxy;
			}
					
					
		}
		public function replaceAnim(AnimHolder:Sprite, newAnimID:String):void {
			var oldAnim:TimelineObject = AnimHolder.getChildAt(0) as TimelineObject;
			oldAnim.release();
			var newAnim:DisplayObject = Assets.getTimelineObject(newAnimID);
			TimelineMovie(newAnim).onFrameLabel = onAnimLabel;
			AnimHolder.replaceChildAt(newAnim, 0);
		}
	}

}