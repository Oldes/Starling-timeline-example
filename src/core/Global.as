package core
{
	import display.ISensor;
	import flash.geom.Point;
	import starling.animation.Transitions;
	import starling.animation.Tween;
	import starling.display.DisplayObject;
	import flash.system.Capabilities;
	import scenes.Scene;
	import starling.display.Quad;
	import starling.events.TouchEvent;
	import starling.core.Starling;
	/**
	 * ...
	 * @author Oldes
	 */
	public final class Global 
	{
		private static var _instance:Global;
		private static var mSensors:Vector.<ISensor> = new Vector.<ISensor>();
		public var gameRoot:Game;
		public var currentLevel:String;
		public var currentScene:Scene;
		public var isMobile:Boolean;
		public var lastScenePosition:String;
		public var qZatmivacka:Quad;
		
		public function Global() 
		{
			var info:Array = Capabilities.os.split(" ");
			isMobile = (info[0] != "Windows");
		}
		public static function get instance():Global{
			return _instance || (_instance = new Global());
		}
		
		public function loadScene(name:String):void {
			unloadScene();
			gameRoot.loadLevel(name);
		}
		public function unloadScene():void {
			if(currentScene!=null){
				log("UNLOAD SCENE: " + currentScene);
				var i:int = mSensors.length;
				while ( i > 0 ) {
					i--;
					var sensor:DisplayObject = mSensors[i] as DisplayObject;
					sensor.removeEventListener(TouchEvent.TOUCH, onTouchSensor);
				}

				currentScene.dispose();
				currentScene = null;
				
				Assets.unloadLevel(currentLevel);
				//Starling.juggler.purge();
				log("UNLOAD FINISHED?");
			}
		}
		public function onTouchSensor(e:TouchEvent):void {
			currentScene.onTouchSensor(e);
		};
		
		public function addSensor(sensor:ISensor):void {
			mSensors.push(sensor);
			(sensor as DisplayObject).addEventListener(TouchEvent.TOUCH, onTouchSensor);
		}
		public function getSensor(name:String):ISensor {
			var i:int = mSensors.length;
			while ( i > 0 ) {
				i--;
				var sensor:ISensor = mSensors[i];
				if (sensor.name == name) return sensor;
			}
			return null;
		}
		public function hitTestSensor(globalPoint:Point):ISensor {
			var i:int = mSensors.length;
			var localPoint:Point;
			while ( i > 0 ) {
				i--;
				var sensor:ISensor = mSensors[i];
				localPoint = DisplayObject(sensor).globalToLocal(globalPoint);
				//log("hitTestSensor: " + sensor.name, localPoint, DisplayObject(sensor).hitTest(localPoint));
				if (sensor.enabled && DisplayObject(sensor).hitTest(localPoint)) return sensor;
			}
			return null;
		}

		public function disableSensor(name:String):void {
			var i:int = mSensors.length;
			while ( i > 0 ) {
				i--;
				var sensor:ISensor = mSensors[i];
				if (sensor.name == name) {
					sensor.enabled = false;
					break;
				}
			}
		}
		public function enableSensor(name:String):void {
			var i:int = mSensors.length;
			while ( i > 0 ) {
				i--;
				var sensor:ISensor = mSensors[i];
				if (sensor.name == name) {
					sensor.enabled = true;
					break;
				}
			}
		}
	}

}