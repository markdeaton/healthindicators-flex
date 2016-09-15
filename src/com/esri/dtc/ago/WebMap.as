package com.esri.dtc.ago
{
	import com.esri.ags.utils.JSONUtil;
	
	public class WebMap
	{
		public var version:String = '1.5';
		public var operationalLayers:Array = new Array();
		public var baseMap:BaseMap = new BaseMap();
		
		
		//Not needed yet
		//public var widgets:Object = {};
		//public var bookmarks:Array = new Array();
		//public var presentation:Object = {};

		public function WebMap()
		{

		}
		
		public function toWMString():String {
			var outString:String = JSONUtil.encode(this);
			return outString;
		}
	}	
}