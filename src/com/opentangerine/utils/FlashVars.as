package com.opentangerine.utils {
import mx.core.FlexGlobals;

/**
 * @author Grzegorz Gajos
 * @since 29.05.13 14:46
 */
public class FlashVars {

    private static var instance:FlashVars;
    private var flashvars:Object;

    public static function getInstance():FlashVars {
        if (instance == null) {
            instance = new FlashVars();
            instance.flashvars = FlexGlobals.topLevelApplication.parameters;
        }
        return instance;
    }

    public function getValue(valueId:String):String {
        if (flashvars[valueId] == undefined) {
            return "[" + valueId + "] missing";
        }
        return flashvars[valueId];
    }

    public function addDefault(valueId:String, defaultValue:String):void {
        if (flashvars[valueId] == undefined) {
            flashvars[valueId] = defaultValue;
        }
    }
}
}