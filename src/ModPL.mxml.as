import flash.events.ProgressEvent
import flash.external.ExternalInterface
import flash.net.URLLoader
import flash.net.URLRequest
import flash.net.navigateToURL
import flash.system.Security
import flash.utils.ByteArray;
import flash.utils.Timer;

import neoart.flip.ZipFile

import neoart.flod.FileLoader
import neoart.flod.core.AmigaPlayer;
import neoart.flod.core.CorePlayer

private var
        urlLoader : URLLoader,
        player : CorePlayer,
        loader : FileLoader = new FileLoader(),
        modUrl : String,
        paused : Boolean = false,
        definedHeader: String = "N/A",
        definedContent: String = "N/A",
        volume : Number,
        secondsTimer : Timer = new Timer(1000)

private function init() {
    uiPaused()
    uiEmpty()
    uiProgressTracker()
    initExternalInterface()
}

private function progressHandler(e:ProgressEvent):void {
    txtContent.text = Math.round(e.bytesLoaded / e.bytesTotal * 100).toString() + "%"
}

private function completeHandler(e:Event):void {
    urlLoader.removeEventListener(ProgressEvent.PROGRESS, progressHandler)
    urlLoader.removeEventListener(Event.COMPLETE, completeHandler)
    try {
        player = loader.load(urlLoader.data)
        player.stereoSeparation = 0
        player.filterMode = AmigaPlayer.FORCE_OFF
        player.volume = 1
        player.play()
        definedContent = loader.tracker
        uiPlaying()
    } catch(ex: Error) {
        uiError("Unknown file format")
    }
}

// View =======================================================================

private function viewPlay() {
    if(!modUrl) {
        uiEmpty()
        return
    }
    if(paused) {
        player.play()
        paused = false
        uiPlaying()
    } else {
        uiPleaseWait()
        if(player) {
            player.stop()
        }
        urlLoader = new URLLoader()
        urlLoader.dataFormat = URLLoaderDataFormat.BINARY
        urlLoader.addEventListener(Event.COMPLETE, completeHandler)
        urlLoader.addEventListener(ProgressEvent.PROGRESS, progressHandler)
        urlLoader.load(new URLRequest(modUrl))
    }
}

private function viewPause() {
    uiPaused()
    paused = true
    player.pause()
}

private function viewStop() {
    if(!player) {
        return
    }
    uiPaused()
    paused = false
    player.stop()
}

//private function viewUpdateVolume() {
//    volume = volumeSlider.value/100.0
//    if(player) {
//        player.volume = volume
//    }
//}

private function viewLogo() {
    navigateToURL(new URLRequest("http://modules.pl"), "_blank")
}

// External Interface =========================================================

private function initExternalInterface() {
    if(ExternalInterface.available) {
        Security.allowDomain("*")
        Security.allowInsecureDomain("*")
        ExternalInterface.addCallback("play", exPlay)
        ExternalInterface.addCallback("stop", exStop)
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
    definedHeader = header
    txtHeader.text = header
}

private function exSetContent(content: String) {
    definedContent = content
    txtContent.text = content
}

// UI updates =================================================================

private function uiPaused() {
    btnPause.visible = false
    btnPlay.visible = true
    btnStop.visible = true
}

private function uiPlaying() {
    btnPause.visible = true
    btnPlay.visible = false
    btnStop.visible = true
    uiTextDefined()
}

private function uiEmpty() {
    txtHeader.text = "INFO"
    txtContent.text = "No module loaded"
}

private function uiError(error: String) {
    uiPaused()
    txtHeader.text = "ERROR"
    txtContent.text = error
}

private function uiPleaseWait() {
    txtHeader.text = "Please wait"
    txtContent.text = "loading..."
}

private function uiTextDefined() {
    txtHeader.text = definedHeader
    txtContent.text = definedContent
}

private function uiProgressTracker() {
    secondsTimer.start()
    secondsTimer.addEventListener(TimerEvent.TIMER, function() {
        if(player != null) {
            var currentMs = player.position / 1000.0
            var durationMs = player.duration / 1000.0
            currentMs = currentMs % durationMs
            progressSlider.value = currentMs * 100.0 / durationMs
            txtTime.text = convertToMMSS(currentMs) + " / " + convertToMMSS(durationMs)
        }
    })
}

// Utils

function convertToMMSS(seconds:Number): String {
    var s: Number = seconds % 60;
    var m: Number = Math.floor((seconds % 3600 ) / 60);
    return doubleDigitFormat(m) + ":" + doubleDigitFormat(s);
}

function doubleDigitFormat(n :uint): String {
    return (n < 10) ? ("0" + n) : String(n);
}