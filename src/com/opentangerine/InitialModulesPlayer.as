package com.opentangerine {
import flash.utils.ByteArray;

import hvl.front_panel;

import neoart.flod.FileLoader;
import neoart.flod.core.AmigaPlayer;
import neoart.flod.core.CorePlayer;

public class InitialModulesPlayer implements IModulesPlayer {

    public function get tracker():String {
        return "N/A";
    }

    public function play():void {
    }

    public function stop():void {
    }

    public function pause():void {
    }

    public function set volume(volume:Number):void {
    }

    public function get progressText():String {
        return "0:00 / 0:00";
    }

    public function get progressSliderPosition():Number {
        return 0;
    }

}

}
