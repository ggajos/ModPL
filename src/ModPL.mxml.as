import flash.events.ProgressEvent;
import flash.net.URLLoader;
import flash.net.URLRequest;
import flash.net.navigateToURL;
import flash.system.Security;

import neoart.flod.FileLoader;
import neoart.flod.core.CorePlayer;

private var
        urlLoader : URLLoader,
        player : CorePlayer,
        loader : FileLoader = new FileLoader(),
        modUrl : String = null;

private function init() {
    initExternalInterface()
}

private function play() {
    txtHeader.text = "Please wait"
    txtContent.text = "loading..."
    stop()
    urlLoader = new URLLoader()
    urlLoader.dataFormat = URLLoaderDataFormat.BINARY
    urlLoader.addEventListener(Event.COMPLETE, completeHandler)
    urlLoader.addEventListener(ProgressEvent.PROGRESS, progressHandler)
    urlLoader.load(new URLRequest(modUrl))
}

public function get title():String {
    return player.title
}

private function progressHandler(e:ProgressEvent):void {
    txtContent.text = Math.round(e.bytesLoaded / e.bytesTotal * 100).toString() + "%"
}

private function completeHandler(e:Event):void {
    urlLoader.removeEventListener(ProgressEvent.PROGRESS, progressHandler)
    urlLoader.removeEventListener(Event.COMPLETE, completeHandler)
    player = loader.load(urlLoader.data)
    if (player && player.version) player.play()
    updateVolume()
    txtHeader.text = player.title
    txtContent.text = loader.tracker
}

private function stop() {
    switchButtons()
    if(player) {
        player.stop()
    }
}

private function switchButtons() {
//    btnStop.visible = !btnStop.visible
//    btnPlay.visible = !btnPlay.visible
}

private function updateVolume() {
    player.volume = volumeSlider.value/100.0
}

private function logo() {
    navigateToURL(new URLRequest("http://modules.pl"), "_blank")
}

// -- EXTERNAL INTERFACE

private function initExternalInterface() {
    Security.allowDomain("*")
    Security.allowInsecureDomain("*")
    ExternalInterface.addCallback("play", exPlay)
    ExternalInterface.addCallback("stop", exStop)
    ExternalInterface.addCallback("setVolume", exSetVolume)
}

private function exPlay(path: String) {
    modUrl = path
    play()
}

private function exStop() {
    stop()
}

private function exSetVolume(volume: Number) {
    player.volume = volume
}