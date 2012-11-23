package display 
{
	import flash.utils.ByteArray;
	import starling.display.DisplayObjectContainer;
	import starling.display.Graphics;
	
	/**
	 * ...
	 * @author Oldes
	 */
	public class TimelineShape extends DisplayObjectContainer 
	{
		private var mGraphics:Graphics;
		private var mDefinition:ByteArray;
		
		private static const cmdLineStyle:int = 1;
		private static const cmdMoveTo:int =    2;
		private static const cmdCurve:int =     3;
		private static const cmdLine:int =      4;
		
		public function TimelineShape(definition:ByteArray) 
		{
			super();
			mGraphics = new Graphics(this);
			mDefinition = definition;
			init();
			touchable = false;
			//log(numChildren);
		}
		public function get graphics():Graphics
		{
			return mGraphics;
		}
		public function init():void {
			var spec:ByteArray = mDefinition;
			var graphics:Graphics = mGraphics;
			var px:Number, py:Number;
			var cx:Number, cy:Number;
			var ax:Number, ay:Number;
			var count:uint;
			var opcode:uint;
			
			spec.position = 0;
			while((opcode = spec.readUnsignedByte()) > 0){
				//log("shapeOpcode: " +opcode);
				switch(opcode) {
					case cmdLineStyle:
						var thickness:Number = 2 * spec.readUnsignedShort() * .05;
						
						var b:int = spec.readUnsignedByte();
						//var b2:int = spec.readUnsignedShort();
						var color:int = (b * 65536) + (spec.readUnsignedByte()* 256) + spec.readUnsignedByte()//b2;
						var alpha:Number = spec.readUnsignedByte() / 255;
						//var material:StandardMaterial = Assets.getLineMaterial(color, alpha);
						graphics.lineStyle(thickness, color, alpha);
						//graphics.lineMaterial(thickness, material);
						break;
					case cmdMoveTo:
						px = spec.readShort() * .05;
						py = spec.readShort() * .05;
						graphics.moveTo(px, py);
						break;
					case cmdCurve:
						count = spec.readUnsignedShort();
						while (count > 0) {
							cx = px + spec.readShort() * .05;
							cy = py + spec.readShort() * .05;
							px = cx + spec.readShort() * .05;
							py = cy + spec.readShort() * .05;
							graphics.curveTo(cx, cy, px, py, .2);
							count--;
						}
						break;
					case cmdLine:
						count = spec.readUnsignedShort();
						while (count > 0) {
							px += spec.readShort() * .05;
							py += spec.readShort() * .05;
							graphics.lineTo(px, py);
							count--;
						}
						break;
				}
			}
		}
	}
}