function openPlayer() {
    modulesPlayer.withPlayer(function() {})
}

function play() {
    modulesPlayer.play(document.getElementById('targetUrl').value)
}

function header() {
    modulesPlayer.setHeader(document.getElementById('header').value)
}

function content() {
    modulesPlayer.setContent(document.getElementById('content').value)
}

function stop() {
    modulesPlayer.stop()
}

modulesPlayer = (function() {
    var windowname = "modules.pl";
    var waitDelay = 100
    var windowOptions = 'directories=0,location=0,menubar=0,resizable=0,scrollbars=0,titlebar=0,toolbar=0,width=400,height=100'
    var windowHtml = "window.html"

    function setHeader(text) {
        withPlayer(function(player) {
            player.setHeader(text)
        })
    }

    function setContent(text) {
        withPlayer(function(player) {
            player.setContent(text)
        })
    }

    function play(url) {
        withPlayer(function(player) {
            player.play(url)
        })
    }

    function stop() {
        withPlayer(function(player) {
            player.stop()
        })
    }

    function withPlayer(callback) {
        if(!window.playerWindow) {
            window.playerWindow = getPlayerWindow()
        }
        if(!window.playerWindow.ModPL) {
            window.playerWindow = createPlayerWindow()
        }
        waitForPlayer(function() {
            callback(window.playerWindow.ModPL)
        })
    }

    function getPlayerWindow() {
        return window.open("", windowname, windowOptions, true)
    }

    function createPlayerWindow() {
        return window.open(windowHtml, windowname, windowOptions, true)
    }

    function waitForPlayer(callback) {
        setTimeout(function() {
            if(window.playerWindow.ModPL) {
                waitForInterface(callback)
            } else {
                waitForPlayer(callback)
            }
        }, waitDelay)
    }

    function waitForInterface(callback) {
        setTimeout(function() {
            if(window.playerWindow.ModPL.play) {
                callback()
            } else {
                waitForInterface(callback)
            }
        }, waitDelay)
    }

    return {
        play: play,
        stop: stop,
        setHeader: setHeader,
        setContent: setContent,
        withPlayer: withPlayer
    }
}())