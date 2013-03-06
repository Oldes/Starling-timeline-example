package scenes 
{
	import scenes.Scene;
	
	import display.ISensor;
	import display.TimelineMovie;
	
	import flash.geom.Point;
	import flash.system.System;
	
	import starling.display.DisplayObject;
	import starling.display.DisplayObjectContainer;
	import starling.events.EnterFrameEvent;
	import starling.events.Event;
	
	import starling.events.Touch;
	import starling.events.TouchEvent;
	import starling.events.TouchPhase;
	
	import flash.utils.getQualifiedClassName;
	
	/**
	 * ...
	 * @author Oldes
	 */
	public class Mlok extends Scene
	{
		private const mPoint:Point = new Point();
		
		public function Mlok() 
		{
			super();
		}
		public override function onInit(e:Event):void {
			super.onInit(e);
			
			addQuadSensor(this, 'BG', 0, 0,  gameWidth, gameHeight);
			
			//For testing purposes I'm adding multiple TimelineMovies with different framerate
			//in real life I'm not using so many animations, but much more longer one.
			//The main purpose of TimelineMovies is not to have many duplicated animations!
			var tmp:DisplayObject;
			for (var i:int = 0; i < 60; i++) {
				var n:Number = Math.random();
				var animName:String;
				if (n < .5) {
					animName = "SopranZpiva";
				} else {
					animName = "SopranSpi";
				}
				tmp = Assets.getTimelineObject(animName);
				tmp.x = 100 + 1420 * Math.random();
				tmp.y = 100 + 780 * Math.random();
				tmp.rotation = Math.random();
				TimelineMovie(tmp).fps = 30 + 0.5 * i;
				TimelineMovie(tmp).onFrameLabel = onAnimLabel;
				addChild(tmp);
			}

			System.pauseForGCIfCollectionImminent(0.5);
			log("Init scene done");
		}
		protected override function startLevel(e:EnterFrameEvent):void {
			log("startLevel: Test");
			this.removeEventListener(EnterFrameEvent.ENTER_FRAME, startLevel);
			this.addEventListener(EnterFrameEvent.ENTER_FRAME, onEnterFrame);
		}
		public override function dispose():void {
			this.removeEventListener(TouchEvent.TOUCH, onTouch);
			this.removeEventListener(EnterFrameEvent.ENTER_FRAME, onEnterFrame);
			super.dispose();
			trace("dispose " +this);
		}
		public override function onResize():void {
			log("Test onResize");
		}
		
		protected override function onEnterFrame(e:EnterFrameEvent):void {
			var pt:Number = e.passedTime;
			
			pivotX += pt * (_focusPivotX - pivotX) / _focusAC
			pivotY += pt * (_focusPivotY - pivotY) / _focusAC
			x += pt * (_focusX - x) / _focusAC;
			y += pt * (_focusY - y) / _focusAC;
			scaleX = scaleY += pt * (_focusScale - scaleX) / _focusAC;
			
			//updateParalax();
			
		}
		
		private function startAnim(animId:String = null):void {
			log("startAnim: " + animId);
			switch(animId) {
			}
		}
		
		public override function onAnimLabel(anim:DisplayObjectContainer, label:String ):void {
			//log(label, getQualifiedClassName(anim));
			switch(label) {
			}
		}
		
		private function onAnimComplete(e:Event):void {
			var animType:String = getQualifiedClassName(e.target);
			log("ANIMComplete: " + e.target+" "+animType);
			switch (animType) {
			}
			System.pauseForGCIfCollectionImminent(0.5);
			
		}
		public override function onTouchSensor(e:TouchEvent):void {
			var q:ISensor = ISensor(e.currentTarget);
			var touches:Vector.<Touch> = e.getTouches(this, TouchPhase.BEGAN);
			if (touches.length > 0 ) {
				log("PRESSED " +q.name, q);
				switch(q.name) {
				
				}
			}
			touches = e.getTouches(this, TouchPhase.ENDED);
			if (touches.length > 0 ) {
				//log("RELEASED " +q.name);
				switch(q.name) {
				
				}
			}
		}
	}
}