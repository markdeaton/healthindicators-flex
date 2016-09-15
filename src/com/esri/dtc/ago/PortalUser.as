package com.esri.dtc.ago
{
	import com.esri.ags.SpatialReference;
	import com.esri.ags.geometry.Extent;
	import com.esri.ags.utils.JSONUtil;
	
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.net.URLRequestMethod;
	import flash.net.URLVariables;
	
	import mx.rpc.events.FaultEvent;

	[Bindable]
	public class PortalUser extends EventDispatcher
	{
		public var portal:String;
		private var _username:String;
		private var _password:String;
		public var token:String;
		public var groups:Array = new Array();
		public var folders:Object = new Array();
		public var items:Object = new Object();
		public var lastItemID:String = ""
		
		private var _loader:URLLoader = new URLLoader();
		
		public function PortalUser(user:String = null, pwd:String = null, url:String = 'http://www.arcgis.com', target:IEventDispatcher=null)
		{
			this.username = user;
			this.password = pwd;
			this.portal = url;

			super(target);
		}
		
		public function get password():String
		{
			return _password;
		}

		public function set password(value:String):void
		{
			_password = value;
		}

		public function get username():String
		{
			return _username;
		}

		public function set username(value:String):void
		{
			_username = value;
		}

		private function readyToLogin():Boolean {
			return _username && _password;
		}
		public function login(tokenLength:Number = 60):void {
			var requestData:URLVariables = new URLVariables();
			//'username':username, 'password':password, 'client':client, 'expiration':expiration, 'f':f
			requestData.username = this.username;
			requestData.password = this.password;
			requestData.client = 'requestip';
			requestData.expiration = tokenLength;
			requestData.f = 'json';
			var request:URLRequest = new URLRequest(this.portal + '/sharing/generateToken');
			request.data = requestData;
			request.method = URLRequestMethod.GET;
			_loader.addEventListener(Event.COMPLETE, processToken);
			_loader.load(request);
			
			function processToken(e:Event):void {
				_loader.removeEventListener(Event.COMPLETE, processToken);
				var response:Object = JSONUtil.decode(_loader.data as String);
				if (response['token']) {
					token = response['token'];
					dispatchEvent(new Event(Event.COMPLETE));
				} else {
					dispatchEvent(new FaultEvent(FaultEvent.FAULT));
				}				
			}
		}
		
/*		protected function getGroups():void {
			
			getFolders();
		}
		
		protected function getFolders():void {
			this.dispatchEvent(new Event(Event.COMPLETE));
		}
*/
		public function addMap(webMap:WebMap, title:String, snippet:String, tags:String, description:String="", extent:Extent=null ):void {
			var params:URLVariables = new URLVariables();
			params.f = 'json';
			params.token = token;
			params.type = "Web Map";
			params.typeKeywords='Web Map, Explorer Web Map, Map, Online Map, ArcGIS Online';
			
			//User Variables
			var epoch:Number = Math.round(new Date().valueOf()/1000);
			params.accessInformation = '';
			params.description = description;
			params.item = 'smartMapSearchResults_' + epoch.toString();
			params.title = title;
			params.snippet = snippet;
			params.tags = tags;
			
			//Derived from map
			if (extent == null) {
				extent = new Extent(-136.074505, 15.087546, -53.808880, 54.146053, new SpatialReference(4326));
			}
			
			var extentString:String = [extent.xmin, extent.ymin, extent.xmax, extent.ymax].join(',');
			params.extent = extentString;
			//params.spatialreference = extent.spatialReference.wkt;
			
			//This is a generic thumbnail; need to modify for our map 
			params.thumbnailURL = 'http://www.arcgis.com/sharing/tools/print?json=' +
				'{"format":"png","nbbox":"-18611259.232,-169440.889,1621927.903,8479561.736",' +
				'"bbox":"-18611259.232,-169440.889,1621927.903,8479561.736","size":"200,133","sr":"102100","cm":0,"services":[' +
				'{"service":"http://services.arcgisonline.com/ArcGIS/rest/services/Canvas/World_Light_Gray_Base/MapServer","extra":"","wrap":true,"opacity":1},' +
				'{"opacity":0.7,"service":"http://services.arcgisonline.com/ArcGIS/rest/services/Demographics/USA_Population_Density/MapServer/4","extra":"&transparent=true","wrap":true}]}';
			
			//Map Spec
			params.text = webMap.toWMString();

			var request:URLRequest = new URLRequest(portal + '/sharing/content/users/' + username + '/addItem');
			request.method = URLRequestMethod.POST;
			request.data = params;
			_loader.addEventListener(Event.COMPLETE, addComplete);
			_loader.load(request);
			
			function addComplete(e:Event):void {
				_loader.removeEventListener(Event.COMPLETE, addComplete);
				trace(_loader.data as String);
				var response:Object = JSONUtil.decode(_loader.data as String);
				if(response['success'] == true) {
					lastItemID = response['id'];
					dispatchEvent(new Event(Event.COMPLETE));
				} else {
					dispatchEvent(new FaultEvent(FaultEvent.FAULT));
				}
				
				
			}
		}		
	}
}