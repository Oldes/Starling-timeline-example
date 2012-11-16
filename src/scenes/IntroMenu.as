package scenes 
{
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.text.TextField;
	import flash.text.TextFormat;
	
	/**
	 * ...
	 * @author Oldes
	 */
	public class IntroMenu extends Sprite 
	{
		private static const textFormat:TextFormat = new TextFormat("_sans", 24, 0xffffffff, true);
		private var mMaster:Game;
		public var levelIds:Array = new Array("Mlok");
		
		public function IntroMenu(master:Game) 
		{
			mMaster = master;
			addEventListener(Event.ADDED_TO_STAGE, onAdded);
		}
		private function onAdded(e:Event):void {
			removeEventListener(Event.ADDED_TO_STAGE, onAdded);
			var tf:TextField;
			var tfY:int = 0;
			
			textFormat.align = "center";
			
			for (var i:int; i < levelIds.length; i++) {
				tf = new TextField();
				tf.width = 200;
				tf.height = 35;
				tf.defaultTextFormat = textFormat;
				tf.background = true;
				tf.backgroundColor = 0x221111;
				tf.selectable = false;
				tf.name = tf.text = levelIds[i];
				tf.y = tfY;
				addChild(tf);
				tfY += 65;
			}
			addEventListener(MouseEvent.MOUSE_DOWN, onButton);
			this.x = (stage.stageWidth - width) / 2;
			this.y = (stage.stageHeight - height) / 2;
		}
		private function onButton(e:MouseEvent):void {
			trace(e.target.name);
			removeEventListener(MouseEvent.MOUSE_DOWN, onButton);
			mMaster.loadLevel(e.target.name);
		}
		
	}

}