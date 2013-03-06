package display 
{
	import apparat.memory.MemoryBlock;
	/**
	 * ...
	 * @author Oldes
	 */
	public final class TimelineMemoryBlock 
	{
		private var mHead:int;
		private var mTail:int;
		private var mData:MemoryBlock;
		
		public function TimelineMemoryBlock(data:MemoryBlock, head:int, length:int) 
		{
			mHead = head;
			mTail = head + length;
		}
		public function get data():MemoryBlock { return mData;   }
		public function get head():int   { return mHead; }
		public function get tail():int   { return mTail; }
		public function get length():int { return mTail - mHead; }
	}

}