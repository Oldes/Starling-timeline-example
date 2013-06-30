package memory 
{
	/**
	 * ...
	 * @author Oldes
	 */
	public final class MemoryBlock 
	{
		public var position: uint;
		public var length: uint;
		public var level: String;
		
		public function MemoryBlock(position:uint, length:uint) 
		{
			this.position = position;
			this.length = length;
		}

		public function toString(): String
		{
			return "[MemoryBlock position: " + position +", length: " + length + "]";
		}
	}

}