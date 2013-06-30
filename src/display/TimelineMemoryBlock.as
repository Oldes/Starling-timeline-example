package display 
{
	//import apparat.memory.MemoryBlock;
	//import apparat.memory.MemoryPool;
	/**
	 * ...
	 * @author Oldes
	 */
	public final class TimelineMemoryBlock 
	{
		private var mHead:int;
		private var mTail:int;
		
		public function TimelineMemoryBlock(head:int, length:int) 
		{
			mHead = head;
			mTail = head + length;
		}
		public function get head():int   { return mHead; }
		public function get tail():int   { return mTail; }
		public function get length():int { return mTail - mHead; }
	}

}