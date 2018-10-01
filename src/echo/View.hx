package echo;

/**
 * ...
 * @author https://github.com/deepcake
 */
#if !macro
@:genericBuild(echo.macro.ViewMacro.build())
#end
class View<T> extends ViewBase { }

/**
 *
 */
@:noCompletion
class ViewBase {


	var echo:Echo;
	var entitiesMap:Map<Int, Int> = new Map(); // map (id : id) // TODO what keep in value ?

	@:noCompletion public var __id = -1;

	/** Signal that dispatched when this view collects a new id (entity) */
	//public var onAdded(default, null) = new echo.utils.Signal<Int->Void>();
	/** Signal that dispatched when an id (entity) no more matched and will be removed */
	//public var onRemoved(default, null) = new echo.utils.Signal<Int->Void>();

	/** List of matched ids (entities) */
	public var entities(default, null):List<Int> = new List();


	@:allow(echo.Echo) function activate(echo:Echo) {
		this.echo = echo;
		for (e in echo.entities) addIfMatch(e);
	}

	@:allow(echo.Echo) function deactivate() {
		while (entities.length > 0) entitiesMap.remove(entities.pop());
		this.echo = null;
	}


	function isMatch(id:Int):Bool { // macro
		// each required component exists in component map with this id
		return false;
	}

	function isRequire(c:Int):Bool { // macro
		return false;
	}


	@:allow(echo.Echo) function addIfMatch(id:Int) {

	}

	@:allow(echo.Echo) function removeIfMatch(id:Int) {

	}


	public function toString():String return 'ViewBase';

}

interface IView {
	function addIfMatch(id:Int):Void;
	function removeIfMatch(id:Int):Void;
	function activate(echo:Echo):Void;
	function deactivate():Void;
}
