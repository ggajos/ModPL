package com.opentangerine {
import flash.utils.ByteArray;

import hvl.front_panel;

import neoart.flod.FileLoader;

import neoart.flod.FileLoader;
import neoart.flod.core.AmigaPlayer;
import neoart.flod.core.CorePlayer;

public class ModulesPlayerFactory {
    private var
            neoartLoader : FileLoader = new FileLoader(),
            hvlPlayer : front_panel = new front_panel();

    public function load(stream:ByteArray): IModulesPlayer {
        try {
            var neoartPlayer: CorePlayer = neoartLoader.load(stream)
            return new NeoartModulesPlayer(neoartPlayer, neoartLoader)
        } catch(ex: Error) {
        }
        hvlPlayer.com_loadTune(stream)
        return new HvlModulesPlayer(hvlPlayer)
    }

    public function initial(): IModulesPlayer {
        return new InitialModulesPlayer()
    }

}

}
