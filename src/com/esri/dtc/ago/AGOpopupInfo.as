package com.esri.dtc.ago
{
	
	
	public class AGOpopupInfo extends Object
	{
		//The existing PopUpInfo class uses variable names not compatible with addItem 
		public var description:String = "";
		public var fieldInfos:Array = [];
		public var mediaInfos:Array = [];
		public var showAttachments:Boolean = false;
		public var title:String = "";

		public function AGOpopupInfo()
		{
			super();
		}
		
	}
}