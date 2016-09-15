package helperClasses
{
	public class DistributionBucket
	{
		public function DistributionBucket( minValue:Number, maxValue:Number )
		{
			_minValue = minValue;
			_maxValue = maxValue;
			_count = 0;
		}
		
		private var _count:int;
		
		private var _minValue:Number;
		private var _maxValue:Number;

		public function get count():int
		{
			return _count;
		}

		public function set count(value:int):void
		{
			_count = value;
		}

		public function get maxValue():Number
		{
			return _maxValue;
		}

		public function get minValue():Number
		{
			return _minValue;
		}

	}
}