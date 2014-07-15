/**
 * Created by Mouster on 2014-07-07.
 */
package com.opentangerine {
import hvl.front_panel;

public class HvlModulesPlayer implements IModulesPlayer {
    private var player: front_panel

    public function HvlModulesPlayer(hvlPlayer: front_panel) {
        player = hvlPlayer
        play()
    }

    public function get tracker():String {
        if(player.info_format.substring(0, 2).toLowerCase() == 'hv') {
            return "HivelyTracker";
        } else {
            return "Abyss' Highest Experience";
        }
    }

    public function play():void {
        player.com_play()
    }

    public function stop():void {
        player.com_stop()
    }

    public function pause():void {
        player.com_pause()
    }

    public function set volume(volume:Number):void {
        // not supported
    }

    public function get progressText():String {
        return ConversionUtil.progressText(player.cur_playTime * 1000, player.info_tuneLength * 1000)
    }

    public function get progressSliderPosition():Number {
        var length = player.cur_playTime % player.info_tuneLength
        return player.cur_playTime * 100. / player.info_tuneLength

    }
}
}
