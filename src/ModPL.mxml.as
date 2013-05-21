import modpl.ModPlayer;

private var player:ModPlayer = new ModPlayer();

private function play():void {
    switchButtons();
    player.play("http://mouster.ovh.org/tmp/test-module.xm");
    updateVolume();
}

private function Stop():void {
    switchButtons();
}

private function switchButtons():void {
    btnStop.visible = !btnStop.visible;
    btnPlay.visible = !btnPlay.visible;
}

private function updateVolume():void {
    player.volume = volumeSlider.value/100.0;
}
