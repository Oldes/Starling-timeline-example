package display 
{
	import starling.text.TextField;
	import starling.text.BitmapFont;
	import starling.utils.VAlign;
	import starling.utils.HAlign;
	
	/**
	 * ...
	 * @author Oldes
	 */
	public class Debug
	{
		private static var debugText:TextField;
		
		public function Debug()
		{
			
		}

		public static function getMainTextInstance():TextField 
		{
			if (debugText == null) {
				debugText = new TextField(400, 60, "", BitmapFont.MINI, BitmapFont.NATIVE_SIZE, 0xff0000);
				debugText.x = 55;
				debugText.hAlign = HAlign.LEFT;
				debugText.vAlign = VAlign.TOP;
				debugText.height = 100;
				debugText.touchable = false;

			}
			return debugText;
		}

		
		private static function logMessage(message:String):void {
			if(debugText) debugText.text = message + "\n"+ debugText.text;
		}
		
		
		public static function clear():void {
			Debug.getMainTextInstance().text = "";
		}

		public static function staticLogMessage(... arguments):void 
		{
			if (arguments.length == 0) {
				clear();
			} else {
				var message:String = "";
				var firstTime:Boolean = true;
				for each (var argument:* in arguments)
				{
					if (firstTime)
					{
						message = argument;
						firstTime = false;
					}
					else
					{
						message += ", " + argument;
					}
				}
				trace(message);
				var debugText:TextField = Debug.getMainTextInstance();
				if (debugText!=null) logMessage(message);
			}
		}
		
	}

}