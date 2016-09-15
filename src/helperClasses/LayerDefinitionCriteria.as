package helperClasses
{
	import spark.formatters.NumberFormatter;

	public class LayerDefinitionCriteria
	{
		private var criteria	: Array = new Array();
		
		public function addCriterion(
			attrInfo:AttributeInfo, operator:String, value:Number, displayPrecision:uint=NaN):void {
			criteria.push( {
				"attrInfo"			: attrInfo,
				"operator"			: operator,
				"value"				: value,
				"displayPrecision"	: displayPrecision
			});
		}
		
		public function layerDefinition():String {
			// Creates a definition string for a single definition object
			var defs:Array = criteria.map( function( oDef:Object, i:int, a:Array ):String {
				var sDef:String = "(" 
					+ (oDef.attrInfo as AttributeInfo).attrName
					+ oDef.operator + oDef.value.toString()
					+ ")";
				return sDef;
			});
			return defs.join( " AND " );
		}
		
		public function layerDefinitionDescriptions():Array {
			// Creates a description string for a single definition object
			var descs:Array = criteria.map( function( oDef:Object, i:int, a:Array ):String {
				var sValue:String = oDef.value.toString();
				if ( !isNaN( oDef.displayPrecision ) ) {
					var nf:NumberFormatter = new NumberFormatter();
					var prec:uint = oDef.displayPrecision;
					nf.fractionalDigits = prec; nf.trailingZeros = true;
					sValue = nf.format( oDef.value );
				}
				var sDesc:String = (oDef.attrInfo as AttributeInfo).attrAlias
					+ " " + oDef.operator + " "
					+ sValue;
				return sDesc;
			});
			return descs;
		}
		
		public function layerDefnDescsXmlSafe():Array {
			return layerDefinitionDescriptions().map( function (def:String, i:int, a:Array):String {
				return def..replace( "<", "&lt;" ).replace( ">", "&gt;" );
			});
		}
	}
}