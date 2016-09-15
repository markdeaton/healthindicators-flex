package com.esri.dtc.ago
{
	

	public class OperationalLayer extends Object
	{
		public var id:String;
		public var title:String;
		private var _opacity:Number;
		public var visibility:Boolean = true;
		public var layerDefinition:Object = {};
		public var url:String;
		public var popupInfo:AGOpopupInfo;
		
		//Not needed yet
		//public var featureCollection:Object = {}

		public function OperationalLayer(layerTitle:String, opacity:Number, itemURL:String)
		{
			title = layerTitle;
			id = 'layer' + Math.round(new Date().valueOf()/1000).toString();
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
			return {'opacity' : _opacity, 'url': url, 'visibility' : visibility, 'title':title, 'layerDefinition':layerDefinition, 'popupInfo':popupInfo}; 

		}
		
	}


	
	
}