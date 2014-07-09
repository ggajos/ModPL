/**
 * Created by Mouster on 2014-07-07.
 */
package com.opentangerine {
import flash.utils.ByteArray;

public interface IModulesPlayer {
    function get tracker():String;

    function play():void;

    function stop():void;

    function pause():void;

    function set volume(volume:Number):void;

    function get progressText():String;

    function get progressSliderPosition():Number;
}
}
