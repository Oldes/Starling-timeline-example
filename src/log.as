package  
{
	//import justpinegames.Logi.Console;
	import display.Debug;
	/**
	 * Helper package-level function. Usage is the same as for the trace statemen.
	 * 
	 * For data sent to the log function to be displayed, you need to first create a LogConsole instance, and add it to the Starling stage.
	 * 
	 * @param	... arguments   Variable number of arguments, which will be displayed in the log
	 */
	public function log(... arguments):void 
	{
		Debug.staticLogMessage.apply(this, arguments);
	}
}