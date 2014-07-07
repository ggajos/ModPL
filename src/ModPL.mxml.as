import com.opentangerine.ModulesPlayer;

import flash.events.Event;
import flash.events.ProgressEvent;
import flash.events.TimerEvent;
import flash.external.ExternalInterface;
import flash.net.URLLoader;
import flash.net.URLLoaderDataFormat;
import flash.net.URLRequest;
import flash.net.navigateToURL;
import flash.system.Security;
import flash.utils.Timer;

private var
        modPlay : ModulesPlayer,
        urlLoader : URLLoader,
        modUrl : String,
        paused : Boolean = false,
        definedHeader: String = "N/A",
        definedContent: String = "N/A",
        secondsTimer : Timer = new Timer(1000)

private function init() {
    uiPaused()
    uiEmpty()
    uiProgressTracker()
    initExternalInterface()
}

private function progressHandler(e:ProgressEvent):void {
    this.txtContent.text = Math.round(e.bytesLoaded / e.bytesTotal * 100).toString() + "%"
}

private function completeHandler(e:Event):void {
    urlLoader.removeEventListener(ProgressEvent.PROGRESS, progressHandler)
    urlLoader.removeEventListener(Event.COMPLETE, completeHandler)
    try {
        modPlay.start(urlLoader.data)
        definedContent = modPlay.tracker
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
        modPlay.play()
        paused = false
        uiPlaying()
    } else {
        uiPleaseWait()
        modPlay.stop()
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
    modPlay.pause()
}

private function viewStop() {
    uiPaused()
    paused = false
    modPlay.stop()
}

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
    modPlay.volume = volume
}

private function exSetHeader(header: String) {
    definedHeader = header
    this.txtHeader.text = header
}

private function exSetContent(content: String) {
    definedContent = content
    this.txtContent.text = content
}

// UI updates =================================================================

private function uiPaused() {
    this.btnPause.visible = false
    this.btnPlay.visible = true
    this.btnStop.visible = true
}

private function uiPlaying() {
    this.btnPause.visible = true
    this.btnPlay.visible = false
    this.btnStop.visible = true
    uiTextDefined()
}

private function uiEmpty() {
    this.txtHeader.text = "INFO"
    this.txtContent.text = "No module loaded"
}

private function uiError(error: String) {
    uiPaused()
    this.txtHeader.text = "ERROR"
    this.txtContent.text = error
}

private function uiPleaseWait() {
    this.txtHeader.text = "Please wait"
    this.txtContent.text = "loading..."
}

private function uiTextDefined() {
    this.txtHeader.text = definedHeader
    this.txtContent.text = definedContent
}

private function uiProgressTracker() {
    secondsTimer.start()
    secondsTimer.addEventListener(TimerEvent.TIMER, function() {
        this.progressSlider.value = modPlay.progressSliderPosition
        this.txtTime.text = modPlay.progressText
    })
}