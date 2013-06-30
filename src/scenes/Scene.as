package scenes
{
	import core.Assets;
	import core.Global;
	import display.SensorQuad;
	import display.TimelineObject;
	import display.TimelineMovie;
	import display.ISensor;
	import flash.geom.Rectangle;
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
				public var _focusAC:Number = .4 //.07;
		public var startLevelHorizontalPosition:int;
		
		protected var mCanDetectWalkChange:Boolean = true;
		protected var mOnPressedX:Number;
		protected var mOnPressedY:Number;
		protected var mTouches:Vector.<Touch> = new Vector.<Touch>;

		protected const mGlobal:Global = Global.instance;
		
		public function Scene() 
		{
			this.addEventListener(Event.ADDED_TO_STAGE, onInit);
		}
		public function onInit(e:Event):void {
			addEventListener(Event.REMOVED_FROM_STAGE, onRemovedFromStage);
			stageWidth = stage.stageWidth;
			stageHeight = stage.stageHeight;























			var serverString:String = unescape(Capabilities.serverString);
			var reportedDpi:Number = Number(serverString.split("&DP=", 2)[1]);
			log("DPI:" + Capabilities.screenDPI, reportedDpi);
			startLevelHorizontalPosition = 0;
			zoomEnabled = true;
			this.addEventListener(EnterFrameEvent.ENTER_FRAME, startLevel);
		}
		private function onRemovedFromStage(e:Event):void {
			removeEventListener(Event.REMOVED_FROM_STAGE, onRemovedFromStage);
		}
		public override function dispose():void {
			trace("-->scene dispose " +this);			
			Starling.juggler.removeTweens(this);
			this.removeEventListener(EnterFrameEvent.ENTER_FRAME, onEnterFrame);
			if (parent) parent.removeEventListener(TouchEvent.TOUCH, onTouch);
			Starling.current.nativeStage.removeEventListener(MouseEvent.MOUSE_WHEEL, onMouseWheelEvent);
			if (stageTween) {
				Starling.juggler.remove(stageTween);
				stageTween = null;
			}
			super.dispose();
			if(parent) removeFromParent();
			removeChildren();
			trace("<--scene dispose " +this);
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
			enabled:Boolean = true, touchable:Boolean = true
		):ISensor {
			var sensor:SensorQuad = new SensorQuad(name, x, y, width, height, enabled);
			sensor.touchable = touchable;
			sensor.alpha = 0.0;
			//tmp.blendMode = "add";
			//tmp.addEventListener(TouchEvent.TOUCH, onTouchSensor);
			Global.instance.addSensor(sensor);
			target.addChild(sensor);
			return sensor;
		}
		public function removeQuadSensor(name:String):void {
			var sensor:SensorQuad = Global.instance.getSensor(name) as SensorQuad;
			if (sensor) {
				sensor.removeFromParent(true);
			}
		}
		
		public function enableSensor(name:String):void {
			mGlobal.enableSensor(name);
		}
		public function disableSensor(name:String):void {
			mGlobal.disableSensor(name);
		}
		
		public function addZoomRegion(name:String, x:Number, y:Number, width:Number, height:Number):void {
			new Rectangle(x, y, width, height);
		}
		public function zoomToRegion(x:Number, y:Number, width:Number, height:Number, acceleration:Number=0.2):void {
			var dx:Number = stageWidth - width;
			var dy:Number = stageHeight - height;
			_focusX = stageWidth / 2
			_focusY = stageHeight / 2;
			_focusPivotX = x + (width / 2);
			_focusPivotY = y + (height / 2);
			_focusAC = acceleration;
			log("zooToRegion: "+_focusX, _focusY, "pivot:" +_focusPivotX, _focusPivotY);
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
		
		public function onTouchSensor(e:TouchEvent):void {};
		public function onAddNamedObject(object:TimelineObject):void { };

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
		
		protected function initFocus():void {
			
			minScale = Math.max(stage.stageHeight / (1080 - 0), stage.stageWidth / (1920 - 40));
			maxScale = (stage.stageWidth < 1920) ? 1.0: minScale + 0.5;
			log("minScale: " + minScale +" max: " + maxScale);
			
			_focusPivotX = pivotX = 1920  / 2;
			_focusPivotY = pivotY = 1080 / 2;
			
			_focusScale = scaleX = scaleY = minScale;//1 //
			
			scalePercent = scaleX - minScale;
			
			//pivotX = (1920 * scaleX)  / 2;
			//pivotY = (1080 * scaleY) / 2;

			maxGameWidth  = 1920 * maxScale;
			maxGameHeight = 1080 * maxScale;
			maxStageWidthOffset = stage.stageWidth - maxGameWidth;
			maxStageHeightOffset = stage.stageHeight - maxGameHeight;
			
			
			maxx = stage.stageWidth  - (((1920 * scaleX) - pivotX)) ;
			maxy = stage.stageHeight - (((1080 * scaleY) - pivotY))
			
			if(startLevelHorizontalPosition == 0){
				_focusX = x = stage.stageWidth / 2 //(stage.stageWidth - maxGameWidth)  / 2
			} else if (startLevelHorizontalPosition < 0) {
				_focusX = x = scaleX * (1920 - _focusPivotX);
			} else {
				_focusX = x = stage.stageWidth - (scaleX * (1920 - _focusPivotX)) ;
			}
			
			_focusY = y = stage.stageHeight / 2 ;
		}
		protected function onMouseWheelEvent(e:MouseEvent):void {
			_focusScale += (e.delta / 60);
			if (_focusScale < minScale) {
				_focusScale = minScale;
			} else if (_focusScale > maxScale) {
				_focusScale = maxScale;
			}
			//_focusScale = (e.delta < 0)?minScale:maxScale;
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