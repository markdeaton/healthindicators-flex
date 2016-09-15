package
{
	import com.esri.ags.FeatureSet;
	import com.esri.ags.layers.ArcGISDynamicMapServiceLayer;
	import com.esri.ags.layers.supportClasses.DynamicLayerInfo;
	import com.esri.ags.layers.supportClasses.ImageParameters;
	import com.esri.ags.layers.supportClasses.LayerDefinition;
	import com.esri.ags.layers.supportClasses.LayerDrawingOptions;
	import com.esri.ags.renderers.ClassBreaksRenderer;
	import com.esri.ags.symbols.FillSymbol;
	import com.esri.ags.tasks.GenerateRendererTask;
	import com.esri.ags.tasks.QueryTask;
	import com.esri.ags.tasks.supportClasses.ClassBreaksDefinition;
	import com.esri.ags.tasks.supportClasses.GenerateRendererParameters;
	import com.esri.ags.tasks.supportClasses.Query;
	
	import flash.events.Event;
	
	import helperClasses.AttributeInfo;
	import helperClasses.SelectedColorInfo;
	
	import mx.collections.ArrayCollection;
	import mx.controls.Alert;
	import mx.rpc.AsyncResponder;
	import mx.rpc.AsyncToken;
	import mx.rpc.Fault;
	import mx.rpc.IResponder;
	
	public class HealthIndicatorsDynMapLyr extends ArcGISDynamicMapServiceLayer
	{
		private var _attrInfo				: AttributeInfo;
		private var _idOfLayerWithAttrs		: int = NaN;
		private var _urlOfLayerWithAttrs	: String;
		private var _normalizationField		: String;
		private var _classBreaksMethod		: String;
		private var _colors					: SelectedColorInfo;
		private var _noDataSymbol			: FillSymbol;
		private var _renderer				: ClassBreaksRenderer;
		private var _dataDistribution		: ArrayCollection;
		
		private var _layerDefinitionMinVal	: Number = NaN;
		private var _layerDefinitionMaxVal	: Number = NaN;

		public function HealthIndicatorsDynMapLyr(url:String=null, proxyURL:String=null, token:String=null)
		{
			super(url, proxyURL, token);
		}
		
		//////////////////// Properties ////////////////////
		
		override public function set url(value:String):void
		{
			super.url = value;
			setUrlOfLayerWithAttrs();
		}
		
		
		public function get renderer():ClassBreaksRenderer
		{
			return _renderer;
		}

		public function set renderer(value:ClassBreaksRenderer):void
		{
			_renderer = value;
		}

		/**
		 * The (non-null) features behind this map; used to calculate the data distribution histogram
		 **/
		[Bindable(event="dataDistributionUpdated")]
		public function get dataDistribution():ArrayCollection
		{
			return _dataDistribution;
		}

		/**
		 * Symbol for rendering features that have a null value for the attribute of interest.
		 **/
		public function get noDataSymbol():FillSymbol
		{
			return _noDataSymbol;
		}

		public function set noDataSymbol(value:FillSymbol):void
		{
			_noDataSymbol = value;
			setNewRenderer();
		}

		/**
		 * The user-selected colors to be used to render the data.
		 **/
		public function get colors():SelectedColorInfo
		{
			return _colors;
		}

		public function set colors(value:SelectedColorInfo):void
		{
			// Databinding somehow can trigger this twice for a single color-choice click.
			// Check to make sure old colors <> new colors before continuing processing.
			if ( _colors != null && _colors.equals( value ) ) return;

			_colors = value;

			// If new color ramp has same # colors as old renderer, no need to get new
			// class breaks; just replace the renderer's colors.
			var bNeedNewRenderer:Boolean = 
				_renderer == null || (_renderer.infos.length != _colors.colors.length);
			
			// Build renderer or maybe just update it with new (chosen) colors
			if ( bNeedNewRenderer )
				setNewRenderer();
			else
				setExistingRendererColors();
}

		/**
		 * The user-selected algorithm for calculating the rendering class break values.
		 **/
		public function get classBreaksMethod():String
		{
			return _classBreaksMethod;
		}

		public function set classBreaksMethod(value:String):void
		{
			_classBreaksMethod = value;
			setNewRenderer();
		}

		/**
		 * The attribute field (if any) that should be used to normalize the rendered data.
		 **/
		public function get normalizationField():String
		{
			return _normalizationField;
		}

		public function set normalizationField(value:String):void
		{
			_normalizationField = value;
			setNewRenderer();
		}

		/** 
		 * Which layer has feature and attributes we're interested in seeing
		 **/
		public function get idOfLayerWithAttrs():int
		{
			return _idOfLayerWithAttrs;
		}

		public function set idOfLayerWithAttrs(value:int):void
		{
			_idOfLayerWithAttrs = value;
			setUrlOfLayerWithAttrs();
		}

		/**
		 * Which attribute we're interested in seeing rendered.
		 **/
		public function get attrInfo():AttributeInfo
		{
			return _attrInfo;
		}

		public function set attrInfo(value:AttributeInfo):void
		{
			if ( value != null && value !== _attrInfo ) {
				_attrInfo = value;
				setNewRenderer();
				getDataDistribution();
			}
		}

		private function get dataShouldBeNormalized():Boolean {
			return ( !(_normalizationField == null || _normalizationField == "") );
		}
		
		/**
		 * Sets or returns the minimum range value of the definition expression.
		 * If no definition value has been set, this will return NaN.
		 **/
//		[Bindable(event="updateLayerDefinitionMinVal")]
		public function get layerDefinitionMinVal():Number {
			return _layerDefinitionMinVal;
		}
		public function set layerDefinitionMinVal(value:Number):void {
			_layerDefinitionMinVal = value;
			updateLayerDefinition();
//			dispatchEvent( new Event( "updateLayerDefinitionMinVal" ) );
		}
		
/*		[Bindable(event="updateLayerDefinitionMinVal")]
		public function get layerDefinitionMinPercent():Number {
			return percentAlongDatasetForDataValue( _layerDefinitionMinVal );
		}*/
		
		/**
		 * Sets or returns the minimum value of the definition expression, calculated from
		 * a percentage (0 - 100) of the desired minimum position through the
		 * range of valid data values.<p/>
		 * <b>NOTE: </b>A given value's percent along the (sorted) dataset is calculated by finding the
		 * first instance of that value in the array. If there are many identical values in the array,
		 * that value may represent a big percent of all values; the percent returned will represent
		 * the starting location of that set of values along the dataset.
		 **/
		public function set layerDefinitionMinPct(value:Number):void {
			// Calculate where the given percentage falls within the existing range
			// of valid data values
			if ( value < 0 || value > 100 ) {
				throw new RangeError( "A definition expression percentage value must fall between zero and one hundred." );
				return;
			}
			
			layerDefinitionMinVal = valueForPercentAlongDataset( value );			
		}
		
		/**
		 * Sets or returns the maximum range value of the definition expression.
		 * If no definition value has been set, this will return NaN.
		 **/
//		[Bindable(event="updateLayerDefinitionMaxVal")]
		public function get layerDefinitionMaxVal():Number {
			return _layerDefinitionMaxVal;
		}
		public function set layerDefinitionMaxVal(value:Number):void {
			_layerDefinitionMaxVal = value;
			updateLayerDefinition();
//			dispatchEvent( new Event( "updateLayerDefinitionMaxVal" ) );
		}
		
		/**
		 * Sets or returns the maximum value of the definition expression, calculated from
		 * a percentage (0 - 100) of the desired maximum position through the
		 * range of valid data values.<p/>
		 * <b>NOTE: </b>A given value's percent along the (sorted) dataset is calculated by finding the
		 * first instance of that value in the array. If there are many identical values in the array,
		 * that value may represent a big percent of all values; the percent returned will represent
		 * the starting location of that set of values along the dataset.
		 **/
		public function set layerDefinitionMaxPct(value:Number):void {
			// Calculate where the given percentage falls within the existing range
			// of valid data values
			if ( value < 0 || value > 100 ) {
				throw new RangeError( "A definition expression percentage value must fall between zero and one hundred." );
				return;
			}
			
			layerDefinitionMaxVal = valueForPercentAlongDataset( value );			
		}
		
		/**
		 * The minimum value in the dataset backing this layer
		 **/
		public function get layerMinVal():Number {
			return _dataDistribution[ 0 ];
		}
		
		/**
		 * The maximum value in the dataset backing this layer
		 **/
		public function get layerMaxVal():Number {
			return _dataDistribution[ _dataDistribution.length - 1 ];
		}
		
		/**
		 * Have dynamicLayerInfos been applied to this service to change or rearrange
		 * the way the map appears? (This is not the same as having dynamic drawing or 
		 * rendering in effect.)
		 **/
		private function get hasDynamicLayerInfos():Boolean {
			return this.dynamicLayerInfos && this.dynamicLayerInfos[0] && this.dynamicLayerInfos[0].source;
		}
		//////////////////// Methods ////////////////////
		
		/**
		 * When the map service url or the layer of interest changes, this should be called.
		 * It will also call for a new renderer and a new data distribution calculation, since those
		 * functions depend on the layer of interest.
		 * This really shouldn't change and should only be called once.
		 **/
		private function setUrlOfLayerWithAttrs():void {
			if ( url == null || isNaN( _idOfLayerWithAttrs ) ) return;
			
			_urlOfLayerWithAttrs = url + "/" + _idOfLayerWithAttrs.toString();
			setNewRenderer();
			getDataDistribution();
		}
		
		/**
		 * A whole new renderer is called for when either the number of colors changes
		 * or the class breaks algorithm changes. That's when the data histogram needs to
		 * be recalculated.
		 * If only the colors in the ramp change, then the class breaks aren't changing--
		 * we can more simply just update the colors in the existing renderer.
		 **/
		private function setNewRenderer():void {			
			if (	_attrInfo == null		|| _urlOfLayerWithAttrs == null	|| 
					_colors == null			|| _classBreaksMethod == null	||
					_noDataSymbol == null	|| url == null					
					
			)
				return;
			
			var classDef:ClassBreaksDefinition = new ClassBreaksDefinition();
			classDef.classificationMethod = _classBreaksMethod;
			classDef.classificationField = _attrInfo.attrName;
			classDef.breakCount = _colors.colors.length;
			if ( dataShouldBeNormalized ) {
				classDef.normalizationType = ClassBreaksDefinition.NORMALIZE_BY_FIELD;
				classDef.normalizationField = _normalizationField;
			}
			var params:GenerateRendererParameters = new GenerateRendererParameters();
			params.classificationDefinition = classDef;
			
			var tskGenRenderer:GenerateRendererTask = new GenerateRendererTask( _urlOfLayerWithAttrs );
			if ( hasDynamicLayerInfos ) {
				tskGenRenderer.source = this.dynamicLayerInfos[0].source;
				tskGenRenderer.url = url + "/dynamicLayer";
			}
			tskGenRenderer.execute( params, new AsyncResponder(
				function( result:ClassBreaksRenderer, token:Object = null ):void {
					_renderer = result;
					setExistingRendererColors();
				},
				function( fault:Fault, token:Object = null ):void {
					Alert.show( "Error generating class breaks:\n" + fault.message.toString() );
				})
			);
		}
		
		
		/**
		 * If only the chosen colors have changed, but not the algorithm or 
		 * number of classes, then don't generate a new renderer. Just apply
		 * the color set to the existing renderer.
		 **/
		private function setExistingRendererColors():void {
			for ( var i:int = 0; i < _renderer.infos.length; i++ ) {
				var info:Object = _renderer.infos[ i ];
				info.symbol.color = _colors.colors[ i ];
				// Also set outline color
				info.symbol.outline.color = _colors.outlineColor;
				info.symbol.outline.alpha = _colors.outlineAlpha;
			}
			// Set noData color
			if ( _noDataSymbol ) _renderer.defaultSymbol = _noDataSymbol;
			
			// Everything's ready; apply the renderer
			var ldo:LayerDrawingOptions = new LayerDrawingOptions();
			ldo.alpha = 1; ldo.renderer = _renderer; ldo.layerId = _idOfLayerWithAttrs;
			this.layerDrawingOptions = [ ldo ];
		}
		
		/**
		 * Sort attribute values into buckets for use by the histogram control.
		 **/
		private function getDataDistribution():void {
			if ( _urlOfLayerWithAttrs == null || _attrInfo == null )
				return;
			
			var mapQueryTask:QueryTask = new QueryTask( _urlOfLayerWithAttrs );
			mapQueryTask.useAMF = false;
			if ( hasDynamicLayerInfos ) {
				mapQueryTask.source = this.dynamicLayerInfos[0].source;
				mapQueryTask.url = url + "/dynamicLayer";
			}
			var mapQuery:Query = new Query();			
			mapQuery.returnGeometry = false;
			mapQuery.outFields = [ _attrInfo.attrName ];
			if ( dataShouldBeNormalized ) 
				mapQuery.outFields.push( _normalizationField );
			mapQuery.where = _attrInfo.attrName + " is not null"; // Return all non-null records
			try {
				mapQueryTask.execute( mapQuery, new AsyncResponder(
					function( result:FeatureSet, token:Object ):void {
						// Sort/count values, removing null values
						var features:Array = result.attributes;
						// Initialize array
						var data:Array = features.map( function( o:Object, i:int, a:Array ):Number {
							return attrNormalizedValue( o );
						});
						data.sort( Array.NUMERIC );
						_dataDistribution = new ArrayCollection( data );
						dispatchEvent(new Event("dataDistributionUpdated"));
					},
					function( fault:Fault, token:Object ):void {
						Alert.show( "Error getting attribute distribution:\n" + fault.message.toString() );
					}
				));
			}
			catch (err:Error) {
				Alert.show("Error getting attribute distribution:\n" + err.message);
			}
		}

		/**
		 * If normalization required, calculates and returns the normalized attribute value.
		 * If normalization not required, returns the un-normalized attribute value.
		 * Null attributes return NaN.
		 **/
		private function attrNormalizedValue( g:Object ):Number {
			var val:Number = 
				g[ _attrInfo.attrName ] == null ? NaN : g[ _attrInfo.attrName ] as Number;
			if ( dataShouldBeNormalized )
				val /= g[ _normalizationField ];
			
			return val;
		}
		
		/**
		 * Deletes any current definition expression values applied to this layer.
		 **/
		public function clearLayerDefinition():void {
			_layerDefinitionMinVal = _layerDefinitionMaxVal = NaN;
			updateLayerDefinition();
		}
		
		/**
		 * Recalculate and apply the definition "where" clause for this layer, based on
		 * min and max values set by the user via various user controls.
		 **/
		private function updateLayerDefinition():void {
			var aDefs:Array = new Array();
			if ( !isNaN( _layerDefinitionMinVal ) ) {
				aDefs.push( _attrInfo.attrName + ">=" + _layerDefinitionMinVal );
			}
			if ( !isNaN( _layerDefinitionMaxVal ) ) {
				aDefs.push( _attrInfo.attrName + "<=" + _layerDefinitionMaxVal );
			}
			
			var ld:LayerDefinition = new LayerDefinition();
			ld.layerId = _idOfLayerWithAttrs;
			ld.definition = ( aDefs.length > 0 ) ? aDefs.join( " AND " ) : null;
			this.layerDefinitions = [ ld ];
		}
		
		/**
		 * @param percent The given percentage along the set of valid values in the dataset
		 * @return The numeric value at that point along the data array
		 **/
		private function valueForPercentAlongDataset( percent:Number ):Number {
			var idx:uint = Math.floor( (_dataDistribution.length - 1) * (percent/100) );
			var nTargetVal:Number = _dataDistribution[ idx ];
			return nTargetVal;
		}
		/**
		 * @param value A value in the current layer's dataset of attribute values
		 * @return The percentage of the given value along the set of all valid data values
		 **/
		private function percentAlongDatasetForDataValue( value:Number):Number {
			// Find the index in the data array that matches the given percent
			var idx:uint;
			for ( idx = 0; idx < _dataDistribution.source.length - 1; idx++ ) {
				var nThisVal:Number = _dataDistribution.source[ idx ]; 
				var nNextVal:Number = _dataDistribution.source[ idx + 1 ];
				if ( Math.abs( nThisVal - value ) < Math.abs( nNextVal - value ) )
					break;				
			}
			// Determine that index's percentage along the array
			return ( idx == _dataDistribution.source.length - 1 ) ?
				100 :
				Math.round( idx / (_dataDistribution.source.length - 1) * 100 );
		}
		
	}
}