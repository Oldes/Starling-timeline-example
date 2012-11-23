package 
{
	
	import scenes.IntroMenu;

    import flash.ui.Keyboard;
	import flash.system.Capabilities;

	import scenes.Mlok;
	import scenes.Scene;

	import display.Debug;
	import display.ISensor;
    
    import starling.core.Starling;
    import starling.display.Sprite;
    import starling.events.Event;
    import flash.events.KeyboardEvent;

    public final class Game extends Sprite
    {

		public var minScale:Number = 1;
		public var scene:starling.display.Sprite;
		public var currentLevel:String;
		public var currentScene:Scene;
		public var isMobile:Boolean;
		
		private static var sensors:Vector.<ISensor> = new Vector.<ISensor>();
		private static var _instance:Game;

        public function Game()
        {
			var info:Array = Capabilities.os.split(" ");
			isMobile = (info[0] != "Windows");
			
			this.addEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
        }
		
		public static function get instance():Game{
			if(!_instance) _instance = new Game();
			return _instance;
		}
		
		private function onAddedToStage(event:Event):void
        {
			addChild(Debug.getMainTextInstance());
			log(Starling.current.context.driverInfo);
            Starling.current.nativeStage.addEventListener(KeyboardEvent.KEY_DOWN, onKey);
			Starling.current.nativeStage.addEventListener(flash.events.Event.RESIZE, onResize);
			var introMenu:IntroMenu = new IntroMenu(this);
			Starling.current.nativeStage.addChild(introMenu);
        }
				
		public function loadLevel(id:String):void {
			currentLevel = id;
			Starling.current.nativeStage.removeChildren();
			Assets.instance.preloadFiles([id], loadScene);
		}
		private function loadScene(e:Event=null):void {
			//log("loadScene start");
			switch(currentLevel) {
				case "Mlok": scene = new Mlok(); break;
			}
			currentScene = scene as Scene;
			addChildAt(scene, 0);
		}
        private function onRemovedFromStage(event:Event):void
        {
            Starling.current.nativeStage.removeEventListener(KeyboardEvent.KEY_DOWN, onKey);
			Starling.current.nativeStage.removeEventListener(Event.RESIZE, onResize);
        }
        
        private function onKey(event:KeyboardEvent):void
        {
            if (event.keyCode == Keyboard.SPACE) {
                Starling.current.showStats = !Starling.current.showStats;
				Debug.getMainTextInstance().visible = !Debug.getMainTextInstance().visible;
            } else if (event.keyCode == Keyboard.X) {
                Starling.context.dispose();
			}/* else if (event.keyCode == Keyboard.ENTER) {
				var console:Console = Console.getMainConsoleInstance();
				console.isShown = !console.isShown;
			}*/
        }
		 
		private function onResize(e:flash.events.Event):void
		{
			log("STAGE SIZE: " + stage.stageWidth + "x" + stage.stageHeight);
			if (scene) Scene(scene).onResize();
		}
		
		public function addSensor(sensor:ISensor):void {
			sensors.push(sensor);
		}
		public function getSensor(name:String):ISensor {
			var i:int = sensors.length;
			while ( i > 0 ) {
				i--;
				//log("testSensor: " + name + " " + sensors[i]);
				if (sensors[i].name == name) return sensors[i];
			}
			return null;
		}
		public function disableSensor(name:String):void {
			var i:int = sensors.length;
			while ( i > 0 ) {
				i--;
				var sensor:ISensor = sensors[i];
				if (sensor.name == name) {
					sensor.enabled = false;
					break;
				}
			}
		}
		public function enableSensor(name:String):void {
			var i:int = sensors.length;
			while ( i > 0 ) {
				i--;
				var sensor:ISensor = sensors[i];
				if (sensor.name == name) {
					sensor.enabled = true;
					break;
				}
			}
		}
    }
}