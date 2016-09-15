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
	import mx.collections.ArrayCollection;

	[Bindable]
	public class SelectedColorInfo
	{
		public function SelectedColorInfo( colors:*, outlineColor:uint, outlineAlpha:Number )
		{
			this.colors = colors;
			this.outlineColor = outlineColor;
			this.outlineAlpha = outlineAlpha;
		}
/*		public function SelectedColorInfo( colorInfo:XML ) {
			this.colors = colorInfo.color.@hex;
			this.outlineColor = colorInfo.@outlineColor;
			this.outlineAlpha = colorInfo.@outlineAlpha;
		}*/
		
		private var _colors:ArrayCollection;
		private var _outlineColor:uint;
		private var _outlineAlpha:Number;
		
		public function get colors():ArrayCollection
		{
			return _colors;
		}

		public function set colors(value:*):void
		{
			if ( value is ArrayCollection )
				_colors = value;
			else if ( value is XMLList ) {
				_colors = new ArrayCollection();
				for each ( var sColor:String in value ) {
					_colors.addItem( uint(sColor) );
				}
			}
			else throw new TypeError( "SelectedColorInfo constructor requires ArrayCollection or XMLList for color parameter" ); 
		}

		public function get outlineAlpha():Number
		{
			return _outlineAlpha;
		}

		public function set outlineAlpha(value:Number):void
		{
			_outlineAlpha = value;
		}

		public function get outlineColor():uint
		{
			return _outlineColor;
		}

		public function set outlineColor(value:uint):void
		{
			_outlineColor = value;
		}

		public function equals(value:SelectedColorInfo):Boolean {
			// Check to see if the current color set is equivalent to a specified color set
			if ( this.outlineAlpha != value.outlineAlpha ) return false;
			if ( this.outlineColor != value.outlineColor ) return false;
			if ( this.colors.length != value.colors.length ) return false;
			for ( var i:int = 0; i < this.colors.length; i++ )
				if ( this.colors[ i ] != value.colors[ i ] ) return false;
			
			
			// All tests passed; return true
			return true;
		}
		
		public static function color2RGBA( c:uint, a:uint ):Array {
			// a should be no greater than 255
			var r:int, g:int, b:int;
			
			r = c>>16; g = ( c>>8 ) & 0x0000FF; b = c & 0x0000FF;
			return [ r, g, b, a ];
		}
		

	}
}