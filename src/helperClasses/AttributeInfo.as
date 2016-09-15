/*=============================================================================
* 
* Copyright © 2011 ESRI. All rights reserved. 
* 
* Use subject to ESRI license agreement.
* 
* Unpublished—all rights reserved.
* Use of this ESRI commercial Software, Data, and Documentation is limited to
* the ESRI License Agreement. In no event shall the Government acquire greater
* than Restricted/Limited Rights. At a minimum Government rights to use,
* duplicate, or disclose is subject to restrictions as set for in FAR 12.211,
* FAR 12.212, and FAR 52.227-19 (June 1987), FAR 52.227-14 (ALT I, II, and III)
* (June 1987), DFARS 227.7202, DFARS 252.227-7015 (NOV 1995).
* Contractor/Manufacturer is ESRI, 380 New York Street, Redlands,
* CA 92373-8100, USA.
* 
* SAMPLE CODE IS PROVIDED "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES,
* INCLUDING THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
* PARTICULAR PURPOSE, ARE DISCLAIMED.  IN NO EVENT SHALL ESRI OR CONTRIBUTORS
* BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
* CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
* SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
* INTERRUPTION) SUSTAINED BY YOU OR A THIRD PARTY, HOWEVER CAUSED AND ON ANY
* THEORY OF LIABILITY, WHETHER IN CONTRACT; STRICT LIABILITY; OR TORT ARISING
* IN ANY WAY OUT OF THE USE OF THIS SAMPLE CODE, EVEN IF ADVISED OF THE
* POSSIBILITY OF SUCH DAMAGE TO THE FULL EXTENT ALLOWED BY APPLICABLE LAW.
* 
* =============================================================================*/
package helperClasses
{
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;

	[Bindable]
	public class AttributeInfo
	{
		private var _attrName				: String	= null;
		private var _attrAlias				: String	= null;
		private var _attrType				: String	= null;
		
		public static var DRAGDROPTYPE:String = "DynamicLayersAttributeInfo";
		
		public function AttributeInfo( sAttrName:String, sAttrAlias:String = null, sAttrType:String = null ) 
		{
			attrName = sAttrName;
			attrAlias = sAttrAlias;
			attrType = sAttrType;
		}

		public function get attrType():String
		{
			return _attrType;
		}

		public function set attrType(value:String):void
		{
			_attrType = value;
		}

		public function get attrAlias():String
		{
			return _attrAlias;
		}

		public function set attrAlias(value:String):void
		{
			_attrAlias = value;
		}


		public function get attrName():String
		{
			return _attrName;
		}

		public function set attrName(value:String):void
		{
			_attrName = value;
		}
		
		/**
		 * For a dynamically joined layer, the attribute name is in the format:
		 * &lt;table&gt;.&lt;attribute&gt;
		 * This returns the table portion of the attribute name, or null if none is defined
		 **/
		public function get tableName():String {
			return tableNameFromAttrName(_attrName);
		}

		public static function tableNameFromAttrName(attrName:String):String {
			if ( attrName == null || attrName == "" ) return null;
			var aryAttrParts:Array = attrName.split( "." );
			if ( !(aryAttrParts.length > 1) ) return null;
			return aryAttrParts[ 0 ];
		}

		public static function suggestedPrecision(minVal:Number, maxVal:Number, buckets:int):uint {
			var bucketSize:Number = (maxVal - minVal) / buckets;
			var magnitude:Number = Math.log( bucketSize ) * Math.LOG10E;
			var precisionUntruncated:Number = ( magnitude < 0 ) ? -magnitude : 0;
			var precision:uint = Math.ceil( precisionUntruncated );
			
			return precision;
		}
	}
}