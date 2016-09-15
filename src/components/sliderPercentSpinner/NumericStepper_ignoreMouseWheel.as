package components.sliderPercentSpinner
{
	import flash.events.MouseEvent;
	
	import spark.components.NumericStepper;
	
	public class NumericStepper_ignoreMouseWheel extends NumericStepper
	{
		override protected function system_mouseWheelHandler(event:MouseEvent):void {
			// Do nothing; ignore mouse wheel events
		}
	}
}