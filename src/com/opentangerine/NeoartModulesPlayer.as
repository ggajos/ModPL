package com.opentangerine {
import neoart.flod.FileLoader;
import neoart.flod.core.AmigaPlayer;
import neoart.flod.core.CorePlayer;

public class NeoartModulesPlayer implements IModulesPlayer {
    private var
            player : CorePlayer,
            loader : FileLoader;

    public function NeoartModulesPlayer(neoartPlayer: CorePlayer, neoartLoader : FileLoader) {
        player = neoartPlayer
        loader = neoartLoader
        start()
    }

    public function get tracker():String {
        return loader.tracker
    }

    private function start() {
        player.stereoSeparation = 0
        player.filterMode = AmigaPlayer.FORCE_OFF
        player.volume = 1
        play()
    }

    public function play():void {
        player.play()
    }

    public function stop():void {
        if (player) {
            player.stop()
        }
    }

    public function pause():void {
        player.pause()
    }

    public function set volume(volume:Number):void {
        player.volume = volume
    }

    public function get progressText():String {
        if (player != null) {
            return ConversionUtil.progressText(player.position, player.duration)
        } else {
            return ""
        }
    }

    public function get progressSliderPosition():Number {
        if (player != null) {
            var currentMs = player.position / 1000.0
            var durationMs = player.duration / 1000.0
            currentMs = currentMs % durationMs
            return currentMs * 100.0 / durationMs
        } else {
            return 0
        }
    }


}

}
