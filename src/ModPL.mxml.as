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
        paused : Boolean = false,
        definedHeader: String = "N/A",
        definedContent: String = "N/A",
        volume : Number;

private function init() {
    initExternalInterface()
    uiPaused();
    txtHeader.text = definedHeader;
    txtContent.text = definedContent;
    modUrl = "../test.zip"
    viewPlay()
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
        try {
            player = loader.load(urlLoader.data)
        } catch(ex: Error) {
            uiError("Unknown file format");
        }
    }
    if (player) {
        player.play()
    }
    viewUpdateVolume()
    uiPlaying();
}

// View =======================================================================

private function viewPlay() {
    if(!modUrl) {
        return
    }
    if(paused) {
        player.play()
        paused = false;
        uiPaused();
    } else {
        uiPleaseWait();
        if(player) {
            player.stop();
        }
        urlLoader = new URLLoader()
        urlLoader.dataFormat = URLLoaderDataFormat.BINARY
        urlLoader.addEventListener(Event.COMPLETE, completeHandler)
        urlLoader.addEventListener(ProgressEvent.PROGRESS, progressHandler)
        urlLoader.load(new URLRequest(modUrl))
    }
}

private function viewPause() {
    uiPaused();
    paused = true;
    player.pause();
}

private function viewStop() {
    if(!player) {
        return
    }
    uiPaused();
    paused = false;
    player.stop()
}

private function viewUpdateVolume() {
    volume = volumeSlider.value/100.0
    if(player) {
        player.volume = volume;
    }
}

private function viewLogo() {
    navigateToURL(new URLRequest("http://modules.pl"), "_blank")
}

// External Interface =========================================================

private function initExternalInterface() {
    if(ExternalInterface.available) {
        Security.allowDomain("*")
        Security.allowInsecureDomain("*")
        ExternalInterface.addCallback("viewPlay", exPlay)
        ExternalInterface.addCallback("viewStop", exStop)
        ExternalInterface.addCallback("setVolume", exSetVolume)
        ExternalInterface.addCallback("setHeader", exSetHeader)
        ExternalInterface.addCallback("setContent", exSetContent)
    }
}

private function exPlay(path: String) {
    modUrl = path
    viewPlay()
}

private function exStop() {
    viewStop()
}

private function exSetVolume(volume: Number) {
    player.volume = volume
}

private function exSetHeader(header: String) {
    txtHeader.text = header;
}

private function exSetContent(content: String) {
    txtContent.text = content;
}

// UI updates =================================================================

private function uiPaused() {
    btnPause.visible = false;
    btnPlay.visible = true;
    btnStop.visible = true;
}

private function uiPlaying() {
    btnPause.visible = true;
    btnPlay.visible = false;
    btnStop.visible = true;
    uiTextDefined();
}

private function uiError(error: String) {
    uiPaused();
    txtHeader.text = "ERROR";
    txtContent.text = error;
}

private function uiPleaseWait() {
    txtHeader.text = "Please wait";
    txtContent.text = "loading...";
}

private function uiTextDefined() {
    txtHeader.text = definedHeader;
    txtContent.text = definedContent;
}