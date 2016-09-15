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
package
{
	import com.esri.ags.FeatureSet;
	import com.esri.ags.SpatialReference;
	import com.esri.ags.layers.DynamicMapServiceLayer;
	import com.esri.ags.tasks.QueryTask;
	import com.esri.ags.tasks.supportClasses.Query;
	import com.esri.ags.utils.JSON;
	
	import flash.display.Loader;
	import flash.events.Event;
	import flash.net.URLRequest;
	import flash.net.URLRequestMethod;
	import flash.net.URLVariables;
	
	import helperClasses.DistributionBucket;
	
	import mx.collections.ArrayCollection;
	import mx.controls.Alert;
	import mx.rpc.AsyncResponder;
	import mx.rpc.Fault;
	import mx.rpc.events.FaultEvent;
	import mx.rpc.events.ResultEvent;
	import mx.rpc.http.HTTPService;
	import helperClasses.AttributeInfo;
	import helperClasses.SelectedColorInfo;
	
	public class DynamicMappingLayer extends DynamicMapServiceLayer
	{
		private var _renderer:Object;			//
		private var _urlMapSvc:String;			//
		private var _urlMapSvcExport:URLRequest;
		private var _urlGetBreaks:String;
		private var _idOfLayerWithAttrs:int = NaN;	//
		private var _idOfBackgroundLayer:int;
		private var _classBreaksMethod:String;		//
		private var _normalizationField:String; // don't normalize if empty
		private var _colors:SelectedColorInfo;
		private var _attrInfo:AttributeInfo;
		private var _imageFormat:String;// = "png";
		private var _dataDistribution:ArrayCollection;
		private var _dataDistributionBuckets:int;
		private var _layerDefinition:String = null;
		
		public function DynamicMappingLayer()
		{
			super();
			// Need to have renderer ready before it can be loaded
			setLoaded( false );
		}
		
		public function get idOfBackgroundLayer():int
		{
			return _idOfBackgroundLayer;
		}

		public function set idOfBackgroundLayer(value:int):void
		{
			_idOfBackgroundLayer = value;
		}

		public function get layerDefinition():String
		{
			return _layerDefinition;
		}

		public function set layerDefinition(value:String):void
		{
			_layerDefinition = value;
			refresh();
		}

		public function set dataDistributionBuckets(value:int):void
		{
			_dataDistributionBuckets = value;
		}

		/**
		 * Calculated once both mapSvcURL and normalizationField are set; see findDataDistribution()
		 **/
		[Bindable(event="updateDataDist")]
		public function get dataDistribution():ArrayCollection
		{
			return _dataDistribution;
		}

		public function get normalizationField():String
		{
			return _normalizationField;
		}

		public function set normalizationField(value:String):void
		{
			_normalizationField = value;
			
			if ( readyToFindDataDistribution )
				findDataDistribution();
		}

		public function set classBreaksMethod(value:String):void
		{
			_classBreaksMethod = value;
			setNewRenderer();
		}

		private function set urlGetBreaks(value:String):void
		{
			_urlGetBreaks = value;
			setNewRenderer();
		}

		public function set renderer(value:Object):void
		{
			_renderer = value;
			checkSetLoaded();
			refresh();
		}
		
		// Needs to be accessible by external code that builds the blink layer query
		public function get renderer():Object {
			return _renderer;
		}

		public function set idOfLayerWithAttrs(value:int):void
		{
			_idOfLayerWithAttrs = value;
			
			setGetBreaksUrl();
			checkSetLoaded();
		}

		public function set attrInfo(value:AttributeInfo):void
		{
			// When a map is removed, the data provider gets reapplied through binding.
			// Make sure we only recalc the histogram and renderer if the attribute really has changed.
			if ( value != null && value !== _attrInfo ) {
				_attrInfo = value;
				setNewRenderer();
				
				if ( readyToFindDataDistribution )
					findDataDistribution();
			}
		}
		
		// Needs to be accessible by external code that builds the blink layer query
		public function get attrInfo():AttributeInfo {
			return _attrInfo;
		}

		public function set colors(value:SelectedColorInfo):void
		{
			// Databinding somehow can trigger this twice for a single color-choice click.
			// Check to make sure old colors <> new colors before continuing processing.
			if ( _colors != null && 
				 _colors.equals( value ) ) return;
			
			
			_colors = value;
			
			// If new color ramp has same # colors as old renderer, no need to get new
			// class breaks; just replace the renderer's colors.
			var bNeedNewRenderer:Boolean = 
				( _renderer == null ) || 
				( _renderer.classBreakInfos.length != _colors.colors.length );

			// Build renderer or maybe just update it with new (chosen) colors
			if ( bNeedNewRenderer )
				setNewRenderer();
			else
				setExistingRendererColors();
		}

		public function set urlMapSvc( value:String ):void {
			_urlMapSvc = value;
			_urlMapSvcExport = new URLRequest( value + "/export" );
			
			if ( readyToFindDataDistribution )
				findDataDistribution();
			
			// The Esri API has logic to POST when the URL is too long.
			// We're going around the API, so always POST, just to be safe.
			_urlMapSvcExport.method = URLRequestMethod.POST;
			
			setGetBreaksUrl();
			checkSetLoaded();
		}
		
		override public function get spatialReference():SpatialReference {
			if ( map )
				return map.spatialReference;
			else
				return new SpatialReference();
		}
		
		private function checkSetLoaded():void {
			setLoaded(
				   ( _renderer != null ) && ( _urlMapSvcExport != null ) && 
				   ( !isNaN( _idOfLayerWithAttrs ) )
			);
		}
		
		private function setGetBreaksUrl():void {
			if ( !isNaN( _idOfLayerWithAttrs ) && _urlMapSvc != null ) {
				urlGetBreaks = _urlMapSvc + "/" + _idOfLayerWithAttrs.toString() + "/generateDataClasses";
			}
		}
		
		private function setNewRenderer():void {
			if ( _attrInfo == null || _urlGetBreaks == null || 
				 _colors == null || _classBreaksMethod == null ) 
				return;
			
			// Interrogate the dynamic mapping service for class breaks info
			var htsBreaks:HTTPService = new HTTPService();
			htsBreaks.url = _urlGetBreaks;
			htsBreaks.method = URLRequestMethod.POST;
			var oClassDef:Object = {
				"type"					:	"classBreaksDef",
				"classificationField"	:	_attrInfo.attrName,
				"classificationMethod"	:	_classBreaksMethod,
				"breakCount"			:	_colors.colors.length
			};

			// Support normalization if specified
			if ( dataShouldBeNormalized ) {
				oClassDef.normalizationType = "esriNormalizeByField";
				oClassDef.normalizationField = _normalizationField;
			}
				
			var sClassDef:String = JSON.encode( oClassDef );

			var oReq:Object = {
				"classificationDef"	:	sClassDef,
				"f"					:	"json"
			};
			
			htsBreaks.addEventListener( ResultEvent.RESULT, function( event:ResultEvent ):void {
				// Set renderer and substitute default/chosen colors into it
				_renderer = JSON.decode( event.result as String );
				setExistingRendererColors();
			});
			htsBreaks.addEventListener( FaultEvent.FAULT, function( event:FaultEvent ):void {
				Alert.show( "Error requesting class breaks: " + event.fault.message.toString() );
			});
			
			htsBreaks.send( oReq );
		}
		private function setExistingRendererColors():void {
			var rend:Object = _renderer;
			for ( var i:int = 0; i < rend.classBreakInfos.length; i++ ) {
				var info:Object = rend.classBreakInfos[ i ];
				// Set colors in renderer
				info.symbol.color = SelectedColorInfo.color2RGBA( _colors.colors[ i ], 255 ); // need to convert to 4-item array first
				// Also set outline color
				info.symbol.outline.color = SelectedColorInfo.color2RGBA( _colors.outlineColor, _colors.outlineAlpha );
			}
			
			renderer = rend;
		}
		
		override protected function loadMapImage(loader:Loader):void {
			// Build REST request
			
			//*** Dynamic class breaks renderer ***//
			var oDynamicLayer:Object = {	
				"id" : _idOfLayerWithAttrs,
				"source": {
					"type"		: "mapLayer",
					"mapLayerId": _idOfLayerWithAttrs
				},
				"drawingInfo": {
					"transparency"	: 0,
					"labelingInfo"	: null, 
					"renderer"		: _renderer
				}
			};
			
			// If layer definition defined, add that, too
			if ( _layerDefinition ) {
				oDynamicLayer.definitionExpression = _layerDefinition;
			}
			
			// If background layer requested, set it up for display
			var oBackgroundLayer:Object;
			if ( _idOfBackgroundLayer ) {
				oBackgroundLayer = {
					"id" : _idOfBackgroundLayer,
					"source" : {
						"type"		: "mapLayer",
						"mapLayerId": _idOfBackgroundLayer
					}
				};
				
			}
			//*** Class breaks renderer ***/
/*			var oDynamicLayers:Object = [
			{   "id":0,
				"drawingInfo": {
					"transparency": 0,
					"labelingInfo": null, 
					"renderer": { 	
						"type" : "classBreaks", 
						"field" : _attrInfo.attrName, 
						"minValue" : _attrInfo.lowestVal, 
						"classBreakInfos" : [
							{
								"classMaxValue" : _attrInfo.break1, 
								"label" : "", 
								"description" : "", 
								"symbol" : 
								{
									"type" : "esriSFS", 
									"style" : "esriSFSSolid", 
									"color" : color2RGBA( _colors[ 0 ], 255 ), 
									"outline" : 
									{
										"type" : "esriSLS", 
										"style" : "esriSLSSolid", 
										"color" : [110,110,110,255], 
										"width" : 0.4
									}
								}
							}, 
							{
								"classMaxValue" : _attrInfo.break2, 
								"label" : "", 
								"description" : "", 
								"symbol" : 
								{
									"type" : "esriSFS", 
									"style" : "esriSFSSolid", 
									"color" : color2RGBA( _colors[ 1 ], 255 ),
									"outline" : 
									{
										"type" : "esriSLS", 
										"style" : "esriSLSSolid", 
										"color" : [110,110,110,255], 
										"width" : 0.4
									}
								}
							},
							{
								"classMaxValue" : _attrInfo.break3, 
								"label" : "", 
								"description" : "", 
								"symbol" : 
								{
									"type" : "esriSFS", 
									"style" : "esriSFSSolid", 
									"color" : color2RGBA( _colors[ 2 ], 255 ),
									"outline" : 
									{
										"type" : "esriSLS", 
										"style" : "esriSLSSolid", 
										"color" : [110,110,110,255], 
										"width" : 0.4
									}
								}
							},
							{
								"classMaxValue" : _attrInfo.break4, 
								"label" : "", 
								"description" : "", 
								"symbol" : 
								{
									"type" : "esriSFS", 
									"style" : "esriSFSSolid", 
									"color" : color2RGBA( _colors[ 3 ], 255 ), 
									"outline" : 
									{
										"type" : "esriSLS", 
										"style" : "esriSLSSolid", 
										"color" : [110,110,110,255], 
										"width" : 0.4
									}
								}
							},
							{
								"classMaxValue" : _attrInfo.highestVal
								, 
								"label" : "", 
								"description" : "", 
								"symbol" : 
								{
									"type" : "esriSFS", 
									"style" : "esriSFSSolid", 
									"color" : color2RGBA( _colors[ 4 ], 255 ),
									"outline" : 
									{
										"type" : "esriSLS", 
										"style" : "esriSLSSolid", 
										"color" : [110,110,110,255], 
										"width" : 0.4
									}
								}
							}
						]
					}
				}
			}];*/
			
			//*** Simple renderer ***//
//			var oDynamicLayers:Object = [{"id":0,"drawingInfo":{"labelingInfo":null,"renderer":{"type":"classBreaks","minValue":-99999999,"field":"POP00_SQMI","classBreakInfos":[{"classMaxValue":0,"description":"","symbol":{"outline":{"width":0.4,"color":[110,110,110,255],"type":"esriSLS","style":"esriSLSSolid"},"color":[236,252,204,255],"type":"esriSFS","style":"esriSFSSolid"},"label":""},{"classMaxValue":99999999,"description":"","symbol":{"outline":{"width":0.4,"color":[110,110,110,255],"type":"esriSLS","style":"esriSLSSolid"},"color":[218,240,158,255],"type":"esriSFS","style":"esriSFSSolid"},"label":""}]},"transparency":0}}];
/*			var oDynamicLayers:Object = [
				{   "id":0,
					"drawingInfo": {
						"renderer": {
							"type": "simple",
							"symbol": {
								"type": "esriSFS",
								"style": "esriSFSBackwardDiagonal",
								"color": [
									200,
									200,
									100,
									255 
								],
								"outline": {
									"type": "esriSLS",
									"style": "esriSLSSolid",
									"color": [
										0,
										127,
										63,
										255 
									],
									"width": 0.4 
								} 
							},
							"label": "",
							"description": "" 
						},
						"transparency": 0,
						"labelingInfo": null 
					}
				}];*/
			
			var oDynamicLayers:Array = [ oDynamicLayer ];
			if ( oBackgroundLayer )
				oDynamicLayers.push( oBackgroundLayer );
			var sDynamicLayers:String = JSON.encode( oDynamicLayers );
			
			var params:URLVariables = new URLVariables();
			params.dynamicLayers = sDynamicLayers;
			params.bbox = map.extent.xmin + "," + map.extent.ymin + "," + map.extent.xmax + "," + map.extent.ymax;
			params.bboxSR = map.spatialReference.wkid; //"102008";
/*			params.layers = "show:" + _idOfLayerWithAttrs; 
			if ( _idOfBackgroundLayer != null )
				params.layers += "," + _idOfBackgroundLayer;*/
//			params.srs = "EPSG:" + map.spatialReference.wkid;
			params.f = "image";
//			params.srs = "EPSG:102008" /*+ map.spatialReference.wkid*/;
			params.format = _imageFormat;
			params.transparent = true.toString();
//			params.width = map.width;
//			params.height = map.height;
			params.size = map.width.toString() + "," + map.height.toString();
			
			_urlMapSvcExport.data = params;
			loader.load( _urlMapSvcExport );
		}
		
/*		private function classBreaksRenderer():Object {
			var oRend:Object = { 	
				"type" : "classBreaks", 
				"field" : _attrInfo.attrName, 
					"minValue" : _attrInfo.lowestVal, 
					"classBreakInfos" : [
						{
							"classMaxValue" : _attrInfo.break1, 
							"label" : "", 
							"description" : "", 
							"symbol" : 
							{
								"type" : "esriSFS", 
								"style" : "esriSFSSolid", 
								"color" : color2RGBA( _colors[ 0 ], 255 ), 
								"outline" : 
								{
									"type" : "esriSLS", 
									"style" : "esriSLSSolid", 
									"color" : [110,110,110,51], 
									"width" : 0.4
								}
							}
						}, 
						{
							"classMaxValue" : _attrInfo.break2, 
							"label" : "", 
							"description" : "", 
							"symbol" : 
							{
								"type" : "esriSFS", 
								"style" : "esriSFSSolid", 
								"color" : color2RGBA( _colors[ 1 ], 255 ),
								"outline" : 
								{
									"type" : "esriSLS", 
									"style" : "esriSLSSolid", 
									"color" : [110,110,110,51], 
									"width" : 0.4
								}
							}
						},
						{
							"classMaxValue" : _attrInfo.break3, 
							"label" : "", 
							"description" : "", 
							"symbol" : 
							{
								"type" : "esriSFS", 
								"style" : "esriSFSSolid", 
								"color" : color2RGBA( _colors[ 2 ], 255 ),
								"outline" : 
								{
									"type" : "esriSLS", 
									"style" : "esriSLSSolid", 
									"color" : [110,110,110,51], 
									"width" : 0.4
								}
							}
						},
						{
							"classMaxValue" : _attrInfo.break4, 
							"label" : "", 
							"description" : "", 
							"symbol" : 
							{
								"type" : "esriSFS", 
								"style" : "esriSFSSolid", 
								"color" : color2RGBA( _colors[ 3 ], 255 ), 
								"outline" : 
								{
									"type" : "esriSLS", 
									"style" : "esriSLSSolid", 
									"color" : [110,110,110,51], 
									"width" : 0.4
								}
							}
						},
						{
							"classMaxValue" : _attrInfo.highestVal
							, 
							"label" : "", 
							"description" : "", 
							"symbol" : 
							{
								"type" : "esriSFS", 
								"style" : "esriSFSSolid", 
								"color" : color2RGBA( _colors[ 4 ], 255 ),
								"outline" : 
								{
									"type" : "esriSLS", 
									"style" : "esriSLSSolid", 
									"color" : [110,110,110,51], 
									"width" : 0.4
								}
							}
						}
					]
			};
			
			return oRend;
		}*/
		
		public function set imageFormat(value:String):void
		{
			_imageFormat = value;
		}

		private function get readyToFindDataDistribution():Boolean {
			return ( !(_urlMapSvc == null || _normalizationField == null || _attrInfo == null) ); 
		}
		
		private function get dataShouldBeNormalized():Boolean {
			return ( !(_normalizationField == null || _normalizationField == "") );
		}
		
		private function findDataDistribution():void {
			// Set up and run query for attribute of interest, plus normalization attribute
			var sUrl:String = _urlMapSvc + "/" + _idOfLayerWithAttrs.toString() + "/query";
			var mapQueryTask:QueryTask = new QueryTask( sUrl );
			var mapQuery:Query = new Query();
			mapQuery.returnGeometry = false;
			mapQuery.outFields = [ _attrInfo.attrName ];
			if ( dataShouldBeNormalized ) 
				mapQuery.outFields.push( _normalizationField );
			mapQuery.where = _attrInfo.attrName + " is not null"; // Return all non-null records
			mapQueryTask.execute( mapQuery, new AsyncResponder(
				function( result:FeatureSet, token:Object ):void {
					// Sort/count values, removing null values
					var features:Array = result.attributes;
					features.sort( attrSortFunction );
					var lastVal:Number = attrNormalizedValue( features[ features.length - 1 ] );
					var firstVal:Number = attrNormalizedValue( features[ 0 ] );
					var bucketSize:Number = (lastVal - firstVal) / _dataDistributionBuckets;
					// Initialize array
					_dataDistribution = new ArrayCollection();
					for ( var i:int = 0; i < _dataDistributionBuckets; i++ ){
						var minVal:Number = firstVal + (i * bucketSize);
						var maxVal:Number;
						if ( i < _dataDistributionBuckets - 1 )
							maxVal = minVal + bucketSize;
						else
							maxVal = lastVal;
						_dataDistribution.addItem( new DistributionBucket( minVal, maxVal ) );
					}
					// Update bucket counts
					for each ( var g:Object in features ) {
						var bucket:int;
						var val:Number = attrNormalizedValue( g );
						if ( !isNaN( val ) ) {
							// Special handling for boundary case
							if ( val == lastVal ) bucket = _dataDistributionBuckets - 1;
							else {
								var valDistAlongRange:Number = val - firstVal;
								bucket = Math.floor( valDistAlongRange / bucketSize );
							}
							DistributionBucket(_dataDistribution[ bucket ]).count++;
						}
					}
					dispatchEvent(new Event("updateDataDist"));
				},
				function( fault:Fault, token:Object ):void {
					Alert.show( "Error getting attribute distribution: " + "\n" + 
						fault.message.toString(), "Error" );
				}
			));
		}
		
		private function attrSortFunction ( a:Object, b:Object, fields:Array=null ):int {
			var aVal:Number = attrNormalizedValue( a );
			var bVal:Number = attrNormalizedValue( b );
			
			var i:int = 0;
			
			if ( aVal < bVal ) i = -1;
			else if ( aVal > bVal ) i = 1;
			
			return i;
		};
		
		/**
		 * If normalization required, calculates and returns the normalized attribute value.
		 * If normalization not required, returns the un-normalized attribute value.
		 * Null attributes return NaN.
		 **/
		private function attrNormalizedValue( g:Object ):Number {
			var val:Number = 
				g[ _attrInfo.attrName ] == null ? NaN : g[ _attrInfo.attrName] as Number;
			if ( dataShouldBeNormalized )
				val /= g[ _normalizationField ];
			
			return val;
		}
	}
}