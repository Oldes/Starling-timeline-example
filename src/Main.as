package 
{
	import flash.desktop.NativeApplication;
	import flash.events.Event;
	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.geom.Rectangle;
	import flash.system.Capabilities;
	import flash.ui.Multitouch;
	import flash.ui.MultitouchInputMode;

	import starling.core.Starling;

	
	/**
	 * ...
	 * @author Oldes
	 */
	
    [SWF(width="1024", height="768", frameRate="60", backgroundColor="#000000")]
    public class Main extends Sprite
    {
        private var mStarling:Starling;
		
		public function Main():void 
		{
			stage.align = StageAlign.TOP_LEFT;
			stage.scaleMode = StageScaleMode.NO_SCALE;
			
			
			// touch or gesture?
			Multitouch.inputMode = MultitouchInputMode.TOUCH_POINT;
			
			// entry point
			trace("version: "+NativeApplication.nativeApplication.runtimeVersion +" "+stage.stageHeight);
			Starling.multitouchEnabled = true; // useful on mobile devices
            Starling.handleLostContext = false; // required on Android
			
			var viewPortRectangle:Rectangle = new Rectangle();
			viewPortRectangle.height = stage.stageHeight;
			viewPortRectangle.width = stage.stageWidth;
			
			mStarling = new Starling(Game, stage, viewPortRectangle, null, "auto", "baseline");
            mStarling.simulateMultitouch  = true;
            mStarling.enableErrorChecking = Capabilities.isDebugger;
			mStarling.showStats = true;
			mStarling.antiAliasing = 2;
            //mStarling.start();
			
			stage.addEventListener(Event.RESIZE, resizeStage);
			stage.addEventListener(Event.DEACTIVATE, deactivate);
			stage.addEventListener(Event.ACTIVATE, activate);
		}

		private function deactivate(e:Event):void 
		{
			// auto-close
			log("DEACTIVATE");
			mStarling.stop();
			//mStarling.dispose();
			if(Capabilities.os.indexOf("Linux") >= 0){
				NativeApplication.nativeApplication.exit();
			}
		}
		private function activate(e:Event):void 
		{
			//trace("ACTIVATE");
			mStarling.start();
		}
		protected function resizeStage(event:Event):void
		{
			var viewPortRectangle:Rectangle = new Rectangle();
			viewPortRectangle.height = stage.stageHeight;
			viewPortRectangle.width = stage.stageWidth;
			Starling.current.viewPort = viewPortRectangle;
			mStarling.stage.stageWidth = stage.stageWidth;
			mStarling.stage.stageHeight = stage.stageHeight;
		}
	}
	
}