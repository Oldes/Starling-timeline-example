package display 
{
	/**
	 * ...
	 * @author Oldes
	 */
	public interface ISensor 
	{
		function get name():String;
		function set enabled(value:Boolean):void;
		function get enabled():Boolean;
	}

}