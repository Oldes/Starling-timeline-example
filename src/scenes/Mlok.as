package scenes 
{
	import display.TextureAnim;
	import flash.display.MovieClip;
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
			dispatching = false;
			addQuadSensor(this, 'BG', 0, 0,  gameWidth, gameHeight);
			
			//For testing purposes I'm adding multiple TimelineMovies with different framerate
			//in real life I'm not using so many animations, but much more longer one.
			//The main purpose of TimelineMovies is not to have many duplicated animations!
			var tmp:DisplayObject;
			
			for (var i:int = 0; i < 100; i++) {
				var n:Number = Math.random();
				var animName:String;
				//if (n < .5) {
					animName = "SopranZpiva";
				//} else {
				//	animName = "SopranSpi";
				//}
				tmp = Assets.getTimelineObject(animName);
				tmp.x = 100 + 1420 * Math.random();
				tmp.y = 100 + 780 * Math.random();
				tmp.rotation = Math.random();
				TimelineMovie(tmp).fps = 30 + 0.5 * i;
				TimelineMovie(tmp).onFrameLabel = onAnimLabel;
				
				addChild(tmp);
				
				tmp = Assets.getStarlingMovie("Mlok/Mlok/Sekac") as DisplayObject;
				tmp.x = 100 + 1420 * Math.random();
				tmp.y = 100 + 780 * Math.random();
				TextureAnim(tmp).fps = 30 + 0.5 * i;
				TextureAnim(tmp).play();
				addChild(tmp);
			}
			
			/*Just to show how to include Starlin's animation.
			  Note, that TextureAnim is not Starling's Movie and it's not functionaly complete.
			  But you can see that although the animation is smaler than "Mlok", it's using same texture size!
			  I would use this type only in special cases where performance is the main goal (as it's just switching subtextures)
			*/
			var vodnik:TextureAnim = Assets.getStarlingMovie("Vodnik");
			vodnik.x = 500;
			vodnik.y = 20;
			vodnik.scaleX = -1;
			vodnik.fps = 40;
			vodnik.play();
			vodnik.onFrameLabel = function(anim:TextureAnim, label:String):void {
				log("Vodnik frame: " + label);
			}
			addChild(vodnik);
			
			/*And this is to show, how to get MovieClip from included SWF
			  SWFs should not contain any ActionScript and or linkage!
			  Movies must be in the first frame and have name which is used to locate it.
			  In this case I just use simple sound loop, but flash movie can be used with various other cases,
			  like using drawWithQuality to get images from it or use it as native overlay over Starling's layer.
			  
			  Sorry, don't have better sound which source would not be too big for this simple example purpose.
			*/
			var mov:MovieClip = Assets.getFlashMovie("BGMusic");
			mov.gotoAndStop(2);

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