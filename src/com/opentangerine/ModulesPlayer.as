package com.opentangerine {
import flash.utils.ByteArray;

import hvl.front_panel;

import neoart.flod.FileLoader;
import neoart.flod.core.AmigaPlayer;
import neoart.flod.core.CorePlayer;

public class ModulesPlayer {
    private var
            neoartPlayer : CorePlayer,
            neoartLoader : FileLoader = new FileLoader(),
            hvlPlayer : front_panel;

    public function ModulesPlayer() {
    }

    public function get tracker():String {
        return neoartLoader.tracker
    }

    public function start(stream: ByteArray) {
        neoartPlayer = neoartLoader.load(stream)
        neoartPlayer.stereoSeparation = 0
        neoartPlayer.filterMode = AmigaPlayer.FORCE_OFF
        neoartPlayer.volume = 1
        neoartPlayer.play()
    }

    public function play():void {
        neoartPlayer.play()
    }

    public function stop():void {
        if(neoartPlayer) {
            neoartPlayer.stop()
        }
    }

    public function pause():void {
        neoartPlayer.pause()
    }

    public function set volume(volume:Number):void {
        neoartPlayer.volume = volume
    }

    public function get progressText():String {
        if(neoartPlayer != null) {
            var currentMs = neoartPlayer.position / 1000.0
            var durationMs = neoartPlayer.duration / 1000.0
            currentMs = currentMs % durationMs
            return convertToMMSS(currentMs) + " / " + convertToMMSS(durationMs)
        } else {
            return ""
        }
    }

    public function get progressSliderPosition():Number {
        if(neoartPlayer != null) {
            var currentMs = neoartPlayer.position / 1000.0
            var durationMs = neoartPlayer.duration / 1000.0
            currentMs = currentMs % durationMs
            return currentMs * 100.0 / durationMs
        } else {
            return 0
        }
    }

    function convertToMMSS(seconds:Number): String {
        var s: Number = seconds % 60;
        var m: Number = Math.floor((seconds % 3600 ) / 60);
        return doubleDigitFormat(m) + ":" + doubleDigitFormat(s);
    }

    function doubleDigitFormat(n :uint): String {
        return (n < 10) ? ("0" + n) : String(n);
    }
}

}
