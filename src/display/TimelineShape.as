package display 
{
	import starling.display.DisplayObjectContainer;
	import starling.display.Graphics;
	import avm2.intrinsics.memory.li8;
	import avm2.intrinsics.memory.li16;
	import avm2.intrinsics.memory.sxi16;
	/**
	 * ...
	 * @author Oldes
	 */
	public class TimelineShape extends DisplayObjectContainer 
	{
		private var mGraphics:Graphics;
		private var mDefinition:TimelineMemoryBlock;
		
		private static const cmdLineStyle:int = 1;
		private static const cmdMoveTo:int =    2;
		private static const cmdCurve:int =     3;
		private static const cmdLine:int =      4;
		
		public function TimelineShape(definition:TimelineMemoryBlock) 
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
			var graphics:Graphics = mGraphics;
			var px:Number = 0;
			var py:Number = 0;
			var cx:Number, cy:Number;
			var ax:Number, ay:Number;
			var count:uint;
			var opcode:uint;
			
			var p:int = mDefinition.head; //actuall memory pointer position
			while ((opcode = li8(p++)) > 0) {
				//log("shapeOpcode: " +opcode);
				switch(opcode) {
					case cmdLineStyle:
						var thickness:Number = li16(p) * .05; p += 2;
						var b:int = li8(p++);
						//var b2:int = spec.readUnsignedShort();
						var color:int = (b * 65536) + (li8(p++)* 256) + li8(p++)//b2;
						var alpha:Number = li8(p++) / 255;
						//var material:StandardMaterial = Assets.getLineMaterial(color, alpha);
						graphics.lineStyle(thickness, color, alpha);
						//graphics.lineMaterial(thickness, material);
						break;
					case cmdMoveTo:
						px = sxi16(li16(p)) * .05;
						py = sxi16(li16(p + 2)) * .05;
						p += 4;
						graphics.moveTo(px, py);
						break;
					case cmdCurve:
						count = li16(p); p += 2;
						while (count > 0) {
							cx = px + sxi16(li16(p)) * .05;
							cy = py + sxi16(li16(p + 2)) * .05;
							px = cx + sxi16(li16(p + 4)) * .05;
							py = cy + sxi16(li16(p + 6)) * .05;
							p += 8;
							//trace("curve: "+cx+" "+cy+" "+px+" "+py)
							graphics.curveTo(cx, cy, px, py, .2);
							count--;
						}
						break;
					case cmdLine:
						count = li16(p); p += 2;
						while (count > 0) {
							px += sxi16(li16(p)) * .05;
							py += sxi16(li16(p + 2)) * .05;
							p += 4;
							//trace("lineTo: " + px + " " + py);
							graphics.lineTo(px, py);
							count--;
						}
						break;
				}
			}
		}
	}
}