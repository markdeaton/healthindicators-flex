package com.esri.dtc.ago
{
	public class BaseMapLayer extends Object
	{
		public static var LIGHT_GREY:BaseMapLayer = new BaseMapLayer("World_Light_Gray_Base_6205", 1, "http://services.arcgisonline.com/ArcGIS/rest/services/Canvas/World_Light_Gray_Base/MapServer");
		public static var TOPO:BaseMapLayer = new BaseMapLayer("World_Topo_Map_80", 1, "http://services.arcgisonline.com/ArcGIS/rest/services/World_Topo_Map/MapServer");
	
		public var id:String;
		private var _opacity:Number;
		public var url:String;
		public var visibility:Boolean = true;
			
		public function BaseMapLayer(itemID:String, opacity:Number, itemURL:String)
		{
			id = itemID;
			_opacity = (opacity <= 1 && opacity >= 0) ? opacity : (opacity >1) ? 1 : 0;
			url = itemURL;
			super();

		}
			
		public function set opacity(opacity:Number):void {
			_opacity = (opacity <= 1 && opacity >= 0) ? opacity : (opacity >1) ? 1 : 0; 
		}
		public function get opacity():Number { return _opacity}
			
		public function toString():String {
			return '{"id" : ' + id + ', "opacity" : ' + _opacity + ', "url": ' + url + ', "visibility" : ' + visibility + '}';
		}
			
		public function valueOf():Object {
			return {'id' : id, 'opacity' : _opacity, 'url': url, 'visibility' : visibility};
		}
	}
}