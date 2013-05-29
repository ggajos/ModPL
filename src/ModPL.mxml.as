import com.opentangerine.utils.FlashVars;

import flash.events.ProgressEvent;
import flash.external.ExternalInterface;
import flash.net.URLLoader;
import flash.net.URLRequest;
import flash.net.navigateToURL;
import flash.system.Security;

import neoart.flip.ZipFile;

import neoart.flod.FileLoader;
import neoart.flod.core.CorePlayer;

private var
        urlLoader : URLLoader,
        player : CorePlayer,
        loader : FileLoader = new FileLoader(),
        modUrl : String,
        paused : Boolean = false;

private function init() {
    initExternalInterface()
    initUI();
}

private function initUI() {
    btnPlay.visible = false;
    btnPause.visible = false;
    btnStop.visible = false;
    txtHeader.text = FlashVars.getInstance().getValue("header");
    txtContent.text = FlashVars.getInstance().getValue("content");
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
    var extension: String = modUrl.substr(modUrl.lastIndexOf(".") + 1, modUrl.length)
    if(extension == "zip") {
        txtContent.text = "uncompressing..."
        var zip = new ZipFile(urlLoader.data)
        player = loader.load(zip.uncompress(zip.entries[0]))
    } else {
        player = loader.load(urlLoader.data)
    }
    if (player && player.version) player.play()
    updateVolume()
    txtHeader.text = player.title
    txtContent.text = loader.tracker
    btnPause.visible = true;
    btnStop.visible = true;
}

private function play() {
    if(paused) {
        player.play()
        paused = false;
        btnPause.visible = true;
        btnPlay.visible = false;
    } else {
        txtHeader.text = "Please wait"
        txtContent.text = "loading..."
        stop()
        urlLoader = new URLLoader()
        urlLoader.dataFormat = URLLoaderDataFormat.BINARY
        urlLoader.addEventListener(Event.COMPLETE, completeHandler)
        urlLoader.addEventListener(ProgressEvent.PROGRESS, progressHandler)
        urlLoader.load(new URLRequest(modUrl))
    }
}

private function pause() {
    paused = true;
    btnPlay.visible = true;
    btnPause.visible = false;
    player.pause();
}

private function stop() {
    btnPlay.visible = true;
    btnPause.visible = false;
    paused = false;
    if(player) {
        player.stop()
    }
}

private function updateVolume() {
    player.volume = volumeSlider.value/100.0
}

private function logo() {
    navigateToURL(new URLRequest("http://modules.pl"), "_blank")
}

// -- EXTERNAL INTERFACE

private function initExternalInterface() {
    if(ExternalInterface.available) {
        Security.allowDomain("*")
        Security.allowInsecureDomain("*")
        ExternalInterface.addCallback("play", exPlay)
        ExternalInterface.addCallback("stop", exStop)
        ExternalInterface.addCallback("setVolume", exSetVolume)
    }
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