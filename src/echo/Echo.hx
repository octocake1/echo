package echo;
#if macro
import echo.macro.MacroBuilder;
import haxe.macro.Expr;
using haxe.macro.Context;
using echo.macro.Macro;
using Lambda;
#end

/**
 * ...
 * @author https://github.com/wimcake
 */
class Echo {


	@:noCompletion static var __echoSequence = -1;
	@:noCompletion public var __id = 0;

	@:noCompletion public var __componentSequence = -1;

	@:noCompletion public var entitiesMap:Map<Int, Int> = new Map(); // map (id : id)
	@:noCompletion public var viewsMap:Map<Int, View.ViewBase> = new Map();
	@:noCompletion public var systemsMap:Map<Int, System> = new Map();

	/** List of added ids (entities) */
	public var entities(default, null):List<Int> = new List();
	/** List of added views */
	public var views(default, null):List<View.ViewBase> = new List();
	/** List of added systems */
	public var systems(default, null):List<System> = new List();


	public function new() {
		//trace(haxe.rtti.Meta.getType(Echo).components);
		__id = ++__echoSequence;
	}


	#if echo_debug
	var times:Map<Int, Float> = new Map();
	#end
	inline public function toString():String {
		var ret = 'Echo ( ${systems.length} ) { ${views.length} } [ ${entities.length} ]'; // TODO version or something

		#if echo_debug
		ret += ' : ${ times.get(-100) } ms';
		for (s in systems) {
			ret += '\n        ($s) : ${ times.get(s.__id) } ms';
		}
		for (v in views) {
			ret += '\n    {$v} [${v.entities.length}]';
		}
		#end

		return ret;
	}


	/**
	 * Update
	 * @param dt - delta time
	 */
	public function update(dt:Float) {
		#if echo_debug
		var engineUpdateStartTimestamp = haxe.Timer.stamp();
		#end

		for (s in systems) {
			#if echo_debug
			var systemUpdateStartTimestamp = haxe.Timer.stamp();
			#end

			s.update(dt);

			#if echo_debug
			times.set(s.__id, Std.int((haxe.Timer.stamp() - systemUpdateStartTimestamp) * 1000));
			#end
		}

		#if echo_debug
		times.set(-100, Std.int((haxe.Timer.stamp() - engineUpdateStartTimestamp) * 1000));
		#end
	}

	/**
	* Removes all views, systems and ids (entities)
	 */
	public function dispose() {
		for (v in views) removeView(v);
		for (s in systems) removeSystem(s);
		for (e in entities) remove(e);
	}


	// System

	/**
	 * Adds system to the workflow
	 * @param s `System` instance
	 */
	public function addSystem(s:System) {
		if (!systemsMap.exists(s.__id)) {
			systemsMap[s.__id] = s;
			systems.add(s);
			s.activate(this);
		}
	}

	/**
	 * Removes system from the workflow
	 * @param s `System` instance
	 */
	public function removeSystem(s:System) {
		if (systemsMap.exists(s.__id)) {
			s.deactivate();
			systemsMap.remove(s.__id);
			systems.remove(s);
		}
	}

	/**
	 * Returns `true` if system with passed `type` was been added to the workflow, otherwise returns `false`
	 * @param type `Class<T>` system type
	 * @return `Bool`
	 */
	macro public function hasSystem<T:System>(self:Expr, type:ExprOf<Class<T>>):ExprOf<Bool> {
		var cls = type.identName().getType().follow().toComplexType();
		return macro $self.systemsMap.exists($v{ MacroBuilder.systemIdsMap[cls.followName()] });
	}

	/**
	 * Retrives a system from the workflow by its type. If system with passed type will be not founded, `null` will be returned
	 * @param type `Class<T>` system type
	 * @return `System`
	 */
	macro public function getSystem<T:System>(self:Expr, type:ExprOf<Class<T>>):ExprOf<Null<System>> {
		var cls = type.identName().getType().follow().toComplexType();
		return macro $self.systemsMap[$v{ MacroBuilder.systemIdsMap[cls.followName()] }];
	}


	// View

	/**
	 * Adds view to the workflow
	 * @param v `View<T>` instance
	 */
	public function addView(v:View.ViewBase) {
		if (!viewsMap.exists(v.__id)) {
			viewsMap[v.__id] = v;
			views.add(v);
			v.activate(this);
		}
	}

	/**
	 * Removes view to the workflow
	 * @param v `View<T>` instance
	 */
	public function removeView(v:View.ViewBase) {
		if (viewsMap.exists(v.__id)) {
			v.deactivate();
			viewsMap.remove(v.__id);
			views.remove(v);
		}
	}

	/**
	 * Returns `true` if view with passed `type` was been added to the workflow, otherwise returns `false`
	 * @param type `Class<T>` view type
	 * @return `Bool`
	 */
	macro public function hasView<T:View.ViewBase>(self:Expr, type:ExprOf<Class<T>>):ExprOf<Bool> {
		var cls = type.identName().getType().follow().toComplexType();
		return macro $self.viewsMap.exists($v{ MacroBuilder.viewIdsMap[cls.followName()] });
	}

	/**
	 * Retrives a view from the workflow by its type. If view with passed type will be not found, `null` will be returned
	 * @param type `Class<T>` view type
	 * @return `View<T>`
	 */
	macro public function getView<T:View.ViewBase>(self:Expr, type:ExprOf<Class<T>>):ExprOf<Null<View.ViewBase>> {
		var cls = type.identName().getType().follow().toComplexType();
		return macro $self.viewsMap[$v{ MacroBuilder.viewIdsMap[cls.followName()] }];
	}

	macro public function getViewByTypes(self:Expr, types:Array<ExprOf<Class<Any>>>):ExprOf<Null<View.ViewBase>> {
		var viewCls = MacroBuilder.getViewClsByTypes(types.map(function(type) return type.identName().getType().follow().toComplexType()));
		return macro $self.viewsMap[$v{ MacroBuilder.viewIdsMap[viewCls.followName()] }];
	}

	macro public function hasViewByTypes(self:Expr, types:Array<ExprOf<Class<Any>>>):ExprOf<Bool> {
		var viewCls = MacroBuilder.getViewClsByTypes(types.map(function(type) return type.identName().getType().follow().toComplexType()));
		return macro $self.viewsMap.exists($v{ MacroBuilder.viewIdsMap[viewCls.followName()] });
	}


	// Entity

	/**
	 * Creates a new id (entity)
	 * @param add - immediate adds created id to the workflow if `true`, otherwise not. Default `true`
	 * @return created `Int` id
	 */
	public function id(add:Bool = true):Int {
		var id = ++__componentSequence;
		if (add) {
			entitiesMap.set(id, id);
			entities.add(id);
		}
		return id;
	}

	/**
	 * Retrives last added id
	 * @return `Int`
	 */
	public inline function last():Int {
		return __componentSequence;
	}

	/**
	 * Returns `true` if the id (entity) is added to the workflow, otherwise returns `false`
	 * @param id - `Int` id (entity)
	 * @return `Bool`
	 */
	public inline function has(id:Int):Bool {
		return entitiesMap.exists(id);
	}

	/**
	 * Adds the id (entity) to the workflow
	 * @param id - `Int` id (entity)
	 */
	public inline function push(id:Int) {
		if (!this.has(id)) {
			entitiesMap.set(id, id);
			entities.add(id);
			for (v in views) v.addIfMatch(id);
		}
	}

	/**
	 * Removes the id (entity) from the workflow with saving all it's components. 
	 * The id can be pushed back to the workflow
	 * @param id - `Int` id (entity)
	 */
	public inline function poll(id:Int) {
		if (this.has(id)) {
			for (v in views) v.removeIfMatch(id);
			entitiesMap.remove(id);
			entities.remove(id);
		}
	}

	/**
	 * Removes the id (entity) from the workflow and removes all it components
	 * @param id - `Int` id (entity)
	 */
	public function remove(id:Int) {
		poll(id);
		for (c in haxe.rtti.Meta.getType(Echo).components) {
			var cls = Type.resolveClass(c);

			#if js
			untyped cls.get(__id).remove(id);
			#else
			var map:Map<Int, Dynamic> = Reflect.callMethod(cls, Reflect.field(cls, 'get'), [ __id ]);
			map.remove(id);
			#end
		}
	}


	// Component

	/**
	 * Adds specified components to the id (entity).
	 * If component with same type is already added to the id, it will be replaced.
	 * @param id - `Int` id (entity)
	 * @param components - comma separated list of components of `Any` type
	 * @return `Int` id
	 */
	macro public function addComponent(self:Expr, id:ExprOf<Int>, components:Array<ExprOf<Any>>):ExprOf<Int> {
		var argExpr = macro $id;

		var componentExprs = new List<Expr>()
			.concat(
				components
					.map(function(c){
						var ct = echo.macro.MacroBuilder.getComponentHolder(c.typeof().follow().toComplexType());
						return macro ${ ct.expr(Context.currentPos()) }.get($self.__id)[id] = $c;
					})
			)
			.array();

		var exprs = new List<Expr>()
			.concat(componentExprs)
			.concat([ macro if ($self.has(id)) for (v in $self.views) v.addIfMatch(id) ])
			.concat([ macro return id ])
			.array();

		var ret = macro ( function(id:Int) $b{exprs} )($argExpr);

		#if echo_verbose
		trace(new haxe.macro.Printer().printExpr(ret), @:pos Context.currentPos());
		#end

		return ret;
	}

	/**
	 * Removes a components from the id (entity) by its type
	 * @param id - `Int` id (entity)
	 * @param types - comma separated `Class<Any>` types of components to be removed
	 * @return `Int` id
	 */
	macro public function removeComponent(self:Expr, id:ExprOf<Int>, types:Array<ExprOf<Class<Any>>>):ExprOf<Int> {
		var argExpr = macro $id;

		var componentExprs = new List<Expr>()
			.concat(
				types
					.map(function(t){
						var ct = echo.macro.MacroBuilder.getComponentHolder(t.identName().getType().follow().toComplexType());
						return macro ${ ct.expr(Context.currentPos()) }.get($self.__id).remove(id);
					})
			)
			.array();

		var requireExprs = new List<Expr>()
			.concat(
				types
					.map(function(t){
						return echo.macro.MacroBuilder.getComponentId(t.identName().getType().follow().toComplexType());
					})
					.map(function(i){
						return macro v.isRequire($v{i});
					})
			)
			.array();

		var requireCond = requireExprs.slice(1)
			.fold(function(e:Expr, r:Expr){
				return macro $r || $e;
			}, requireExprs.length > 0 ? requireExprs[0] : null);

		var exprs = new List<Expr>()
			.concat(requireCond == null ? [] : [ macro if ($self.has(id)) for (v in $self.views) if ($requireCond) v.removeIfMatch(id) ])
			.concat(componentExprs)
			.concat([ macro return id ])
			.array();

		var ret = macro ( function(id:Int) $b{exprs} )($argExpr);

		#if echo_verbose
		trace(new haxe.macro.Printer().printExpr(ret), @:pos Context.currentPos());
		#end

		return ret;
	}

	/**
	 * Retrives a component from the id (entity) by its type.
	 * If component with passed type is not added to the id, `null` will be returned.
	 * @param id - `Int` id (entity)
	 * @param type - `Class<T>` type of component to be retrieved
	 * @return `T`
	 */
	macro public function getComponent<T>(self:Expr, id:ExprOf<Int>, type:ExprOf<Class<T>>):ExprOf<T> {
		var ct = echo.macro.MacroBuilder.getComponentHolder(type.identName().getType().follow().toComplexType());
		return macro ${ ct.expr(Context.currentPos()) }.get($self.__id)[$id];
	}

	/**
	 * Returns `true` if the id (entity) has a component with passed type, otherwise returns false
	 * @param id - `Int` id (entity)
	 * @param type - `Class<T>` type of component
	 * @return `Bool`
	 */
	macro public function hasComponent(self:Expr, id:ExprOf<Int>, type:ExprOf<Class<Any>>):ExprOf<Bool> {
		var ct = echo.macro.MacroBuilder.getComponentHolder(type.identName().getType().follow().toComplexType());
		return macro ${ ct.expr(Context.currentPos()) }.get($self.__id)[$id] != null;
	}

}
