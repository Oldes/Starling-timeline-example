package memory 
{
	/**
	 * ...
	 * @author Oldes
	 */
	import flash.errors.MemoryError;
	import flash.utils.ByteArray;
	import memory.MemoryBlock;
	import flash.system.ApplicationDomain;

	public final class Memory 
	{
		
		public  static var   buffer:ByteArray;
		public  static const mMemoryBlocks:Vector.<MemoryBlock> = new Vector.<MemoryBlock>;
		private static const mFreeAreaLengths:Vector.<uint> = new Vector.<uint>;
		private static const mFreeAreaPositions:Vector.<uint> = new Vector.<uint>;
		/**
		 * The current application domain.
		 * @private
		 */
		private static const applicationDomain: ApplicationDomain = ApplicationDomain.currentDomain

		public static function getMemoryBlock(position:uint = 0, length:uint = 0):MemoryBlock {
			//TODO: do better allocation, this is just temporaly for hadrcoded positions
			
			trace("[MEMORY] GET MEMORY BLOCK: " + position + "/" + length);
			var block:MemoryBlock;
			var n:int = mMemoryBlocks.length;
			while (n-- > 0) {
				block = mMemoryBlocks[n];
				if (block.length == 0) {
					block.position = position;
					block.length = length;
					return block;
				}
			}
			return new MemoryBlock(position, length);
		}
		
		public static function allocate(requiredLength:uint):MemoryBlock {
			trace("[MEMORY] ALLOCATE: " + requiredLength);
			var len:int = mFreeAreaLengths.length;
			var i:int = 0;
			while (i < len) {
				var blockLength:uint = mFreeAreaLengths[i];
				if (blockLength >= requiredLength) {
					var position:uint = mFreeAreaPositions[i];
					mFreeAreaLengths[i]   -= requiredLength;
					mFreeAreaPositions[i] += requiredLength;
					return getMemoryBlock(position, requiredLength);
				}
				i++;
			}
			throw new MemoryError();
		}
		
		public static function free(block:MemoryBlock):void {
			trace("[MEMORY] FREE: " + block);
			trace(mFreeAreaPositions);
			trace(mFreeAreaLengths);
			trace("----------------");
			var bPosition:uint = block.position;
			var bLength:uint = block.length;
			var tail:uint = bPosition + bLength;
			
			var len:int = mFreeAreaPositions.length;
			var i:int;
			while (i < len) {
				var position:uint = mFreeAreaPositions[i];
				if (tail == position) {
					if (i > 0 && mFreeAreaPositions[i-1]+mFreeAreaLengths[i-1]== bPosition) {
						mFreeAreaPositions[i] = mFreeAreaPositions[i-1];
						mFreeAreaLengths[i]  += mFreeAreaLengths[i - 1];
						mFreeAreaLengths.splice(i - 1, 1);
						mFreeAreaPositions.splice(i - 1, 1);
					} else {
						mFreeAreaPositions[i] = bPosition;
						mFreeAreaLengths[i]  += bLength;
					}
					block.position = block.length = 0;
					return;
				} else if (tail < position) {
					mFreeAreaPositions.splice(i, 0, bPosition);
					mFreeAreaLengths.splice(i, 0, bLength);
					block.position = block.length = 0;
					return;
				}
				i++;
			}
		}
		
		/**
		 * Selects a ByteArray object as the current memory.
		 *
		 * @param byteArray The ByteArray object to work with.
		 */
		public static function select(byteArray: ByteArray): void {
			applicationDomain.domainMemory = buffer = byteArray;
			mFreeAreaLengths.length = 0;
			mFreeAreaPositions.length = 0;
			mFreeAreaLengths[0] = byteArray.length - 1024; //length
			mFreeAreaPositions[0] = 1024;                    //position
			
		}
		public static function get position():uint {
			return Memory.buffer.position;
		}
		
		
		
		public static function readUTF(position:uint):String {
			buffer.position = position;
			return buffer.readUTF();
		}
		public function Memory() {
			throw new Error( 'Can not instantiate Memory object.' );
		}
	}

}