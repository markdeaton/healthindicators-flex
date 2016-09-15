package components.importDataset
{
	import flash.events.Event;
	/**
	 * Used to signal that a user-provided data file has been successfully uploaded and imported
	 * into a dynamic layer workspace.
	 **/
	public class FileImportEvent extends Event
	{
		public static const FILE_IMPORTED		: String = "fileImported";
		private var _importedTableName			: String;
		private var _importedTableJoinFieldname	: String;
		
		public function FileImportEvent(type:String, importedTableName:String=null, importedTableJoinFieldname:String=null, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);
			switch ( type ) {
				case FILE_IMPORTED:
					if ( importedTableName ) this.importedTableName = importedTableName;
					if ( importedTableJoinFieldname ) this.importedTableJoinFieldname = importedTableJoinFieldname;
					break;
				default:
					// No default action
			}
		}
		override public function clone():Event {
			return new FileImportEvent( type, importedTableName, importedTableJoinFieldname, bubbles, cancelable );				 
		}
		
		public function get importedTableJoinFieldname():String
		{
			return _importedTableJoinFieldname;
		}

		public function set importedTableJoinFieldname(value:String):void
		{
			_importedTableJoinFieldname = value;
		}

		public function get importedTableName():String
		{
			return _importedTableName;
		}

		public function set importedTableName(value:String):void
		{
			_importedTableName = value;
		}

	}
}