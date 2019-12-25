package echoes.core;

interface ISystem {

    function __activate__():Void;

    function __update__(dt:Float):Void;

    function __deactivate__():Void;


    function info(indent:String = ''):String;

}
