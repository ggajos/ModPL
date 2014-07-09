import com.opentangerine.IModulesPlayer;
import com.opentangerine.ModulesPlayerFactory;

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
        modPlay : IModulesPlayer = new ModulesPlayerFactory().initial(),
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
    txtContent.text = Math.round(e.bytesLoaded / e.bytesTotal * 100).toString() + "%"
}

private function completeHandler(e:Event):void {
    urlLoader.removeEventListener(ProgressEvent.PROGRESS, progressHandler)
    urlLoader.removeEventListener(Event.COMPLETE, completeHandler)
    try {
        modPlay = new ModulesPlayerFactory().load(urlLoader.data)
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
        progressSlider.value = modPlay.progressSliderPosition
        txtTime.text = modPlay.progressText
    })
}