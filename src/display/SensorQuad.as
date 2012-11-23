package display 
{
	import starling.display.Quad;
	
	/**
	 * ...
	 * @author Oldes
	 */
	public class SensorQuad extends Quad implements ISensor
	{
		private var mEnabled:Boolean;
		
		public function SensorQuad(name:String, x:Number, y:Number, width:Number, height:Number, enabled:Boolean = true, color:uint = 0xffff00) 
		{
			super(width, height, color);
			this.x = x;
			this.y = y;
			this.name = name;
			this.enabled = enabled;
			
			useHandCursor = true;
		}
		
		public function set enabled(value:Boolean):void {
			mEnabled = value;
			visible = value;
		}
		public function get enabled():Boolean {
			return mEnabled;
		}
	}

}