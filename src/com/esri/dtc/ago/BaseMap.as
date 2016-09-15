package com.esri.dtc.ago
{
	public class BaseMap
	{
		public var baseMapLayers:Array = new Array();
		public var title:String;
		public function BaseMap()
		{
			
		}
		
		public function toString():String
		{
			var outString:String = '"basemap": {[';
			for (var i:int = 0; i < baseMapLayers.length; i++) {
				outString += (baseMapLayers[i] as BaseMapLayer).toString() + ',';
			}
			outString = outString.substring(0,outString.length - 2);
			outString += ']}';
			
			return outString;
		}
		
	}

}