package components.navigation
{
	import com.esri.ags.Map;
	import com.esri.ags.components.Navigation;
	import com.esri.ags.geometry.Extent;
	
	import flash.events.MouseEvent;
	
	import spark.components.Button;
	
	public class ZoomInOut extends Navigation
	{
		[SkinPart(required="false")]
		public var originalExtentButton	: Button;
		
		override protected function partAdded(partName:String, instance:Object):void
		{
			super.partAdded(partName, instance);
			// Get the original extent from the hosting map
			// Add original-extent button click event listener
			if (partName == "originalExtentButton") {
				originalExtentButton.addEventListener(MouseEvent.CLICK, onZoomOriginalExtentClick);
			}
		}
		
		override protected function partRemoved(partName:String, instance:Object):void
		{
			// Remove original-extent button click event listener
			if (partName == "originalExtentButton") {
				originalExtentButton.removeEventListener(MouseEvent.CLICK, onZoomOriginalExtentClick);
			}
			
			super.partRemoved(partName, instance);
		}
		
		protected function onZoomOriginalExtentClick(event:MouseEvent):void {
			map.zoomToInitialExtent();
		}
	}
}