package com.esri.dtc.ago
{
	import com.esri.ags.Graphic;

	public class DrawingTemplate
	{
		public function DrawingTemplate()
		{
			public var drawingTool:String;
			public var description:String;
			public var name:String;
			public var prototype:Graphic = new Graphic();
		}
	}
}