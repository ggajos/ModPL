/**
 * User: Grzegorz Gajos
 * Date: 21.05.13
 * Time: 18:18
 */
package modpl {
import flash.events.Event;
import flash.net.URLLoader;
import flash.net.URLLoaderDataFormat;
import flash.net.URLRequest;

import neoart.flod.FileLoader;
import neoart.flod.core.CorePlayer;

public final class ModPlayer {
    private var
        url    : URLLoader,
        loader : FileLoader,
        player : CorePlayer;

    public function ModPlayer() {
        loader = new FileLoader();
    }

    public function play(path: String) {
        url = new URLLoader();
        url.dataFormat = URLLoaderDataFormat.BINARY;
        url.addEventListener(Event.COMPLETE, completeHandler);
        url.load(new URLRequest(path));
    }

    public function stop() {
        if(player) {
            player.stop();
        }
    }

    public function set volume(volume: Number) {
        if(player) {
            player.volume = volume;
        }
    }

    private function completeHandler(e:Event):void {
        url.removeEventListener(Event.COMPLETE, completeHandler);
        player = loader.load(url.data);
        if (player && player.version) player.play();
    }

}

}
