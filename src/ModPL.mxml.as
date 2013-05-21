import modpl.ModPlayer

private var player:ModPlayer = new ModPlayer()
private var modUrl:String = "http://localhost/web/mods/test-module.xm"

private function init() {
    initExternalInterface()
}

private function play() {
    stop()
    player.play(modUrl)
    updateVolume()
}

private function stop() {
    switchButtons()
    player.stop()
}

private function switchButtons() {
    btnStop.visible = !btnStop.visible
    btnPlay.visible = !btnPlay.visible
}

private function updateVolume() {
    player.volume = volumeSlider.value/100.0
}

// -- EXTERNAL INTERFACE

private function initExternalInterface() {
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