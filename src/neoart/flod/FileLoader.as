/*
  Flod 5.0
  2013/08/15
  Christian Corti
  Neoart Costa Rica

  Last Update: Flod 5.0 - 2013/08/15

  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
  OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
  LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR
  IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

  This work is licensed under the Creative Commons Attribution-Noncommercial-Share Alike 3.0 Unported License.
  To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-sa/3.0/ or send a letter to
  Creative Commons, 171 Second Street, Suite 300, San Francisco, California, 94105, USA.
*/
package neoart.flod {
  import flash.net.*;
  import flash.utils.*;
  import neoart.flip.*;
  import neoart.flod.core.*;
  import neoart.flod.fasttracker.*;
  import neoart.flod.trackers.*;
  import neoart.unpackers.*;

  public final class FileLoader {
    private var
      index  : int,
      player : CorePlayer,
      amiga  : Amiga,
      mixer  : SoundBlaster;

    public function FileLoader() {
      amiga = new Amiga();
      mixer = new SoundBlaster();

      registerAliases();
    }

    public function get tracker():String {
      var index = this.index;
      if (player) index += player.version;
      return TRACKERS[index];
    }

    public function load(stream:ByteArray):CorePlayer {
      var archive:ZipFile, i:int, output:ByteArray, packer:Packer, type:Class;

      stream.endian = "littleEndian";
      stream.position = 0;

      if (stream.readUnsignedInt() == 67324752) {
        archive = new ZipFile(stream);
        stream = archive.uncompress(archive.entries[0]);
      }

      if (!stream) return null;

      if (player) {
        player.load(stream);
        if (player.version) return player;
      }

      // Players
      for (i = 0; i < 6; ++i) {
        type = getClassByAlias(PLAYERS[i]);

        if (i == 5) {
          player = new type(mixer);
        } else {
          player = new type(amiga);
        }

        player.load(stream);

        if (player.version) {
          index = OFFSETS[i];
          return player;
        }
      }

      // Unpackers
      stream.endian = "bigEndian";

      for (i = 0; i < 15; ++i) {
        stream.position = 0;
        type = getClassByAlias(PACKERS[i]);

        packer = new type();
        output = packer.depack(stream);

        if (packer.format) {
          player = new ATPlayer(amiga);
          player.load(output);

          if (player.version) {
            index = 0;
            return player;
          }
        }
      }

      stream.clear();
      stream = null;

      index = 0;
      return null;
    }

    private function registerAliases():void {
      registerClassAlias(PLAYERS[0], ATPlayer);
      registerClassAlias(PLAYERS[1], CTPlayer);
      registerClassAlias(PLAYERS[2], FXPlayer);
      registerClassAlias(PLAYERS[3], GMPlayer);
      registerClassAlias(PLAYERS[4], HMPlayer);
      registerClassAlias(PLAYERS[5], F2Player);

      registerClassAlias(PACKERS[0], DigitalIllusion);
      registerClassAlias(PACKERS[1], Heatseeker);
      registerClassAlias(PACKERS[2], ModuleProtector);
      registerClassAlias(PACKERS[3], NoisePacker2);
      registerClassAlias(PACKERS[4], NoisePacker3);
      registerClassAlias(PACKERS[5], PhaPacker);
      registerClassAlias(PACKERS[6], ProPacker1);
      registerClassAlias(PACKERS[7], ProPacker2);
      registerClassAlias(PACKERS[8], ProRunner1);
      registerClassAlias(PACKERS[9], ProRunner2);
      registerClassAlias(PACKERS[10], StarTrekkerPacker);
      registerClassAlias(PACKERS[11], ThePlayer4);
      registerClassAlias(PACKERS[12], ThePlayer56);
      registerClassAlias(PACKERS[13], ThePlayer61);
    }

    private const
      PLAYERS : Vector.<String> = Vector.<String>([
        "ATPlayer",
        "CTPlayer",
        "FXPlayer",
        "GMPlayer",
        "HMPlayer",
        "F2Player"
      ]),

      PACKERS : Vector.<String> = Vector.<String>([
        "DigitalIllusion",
        "Heatseeker",
        "ModuleProtector",
        "NoisePacker2",
        "NoisePacker3",
        "PhaPacker",
        "ProPacker1",
        "ProPacker2",
        "ProRunner1",
        "ProRunner2",
        "StarTrekkerPacker",
        "ThePlayer4",
        "ThePlayer56",
        "ThePlayer61"
      ]),

      OFFSETS : Vector.<int> = Vector.<int>([
        0,16,20,18,19,24
      ]),

      TRACKERS : Vector.<String> = Vector.<String>([
        "Unknown Format",
        "Ultimate Soundtracker",
        "TJC Soundtracker 2",
        "DOC Soundtracker 4",
        "Master Soundtracker",
        "DOC Soundtracker 9",
        "DOC Soundtracker 2.0",
        "Soundtracker 2.3",
        "NoiseTracker 1.0",
        "NoiseTracker 1.1",
        "ProTracker 1.0",
        "NoiseTracker 2.0",
        "StarTrekker",
        "ProTracker 1.0c",
        "ProTracker 2.0",
        "ProTracker 3.0",
        "FastTracker",
        "ChipTracker",
        "Soundtracker 2.6",
        "Game Music Creator",
        "His Master's NoiseTracker",
        "SoundFX 1.3",
        "SoundFX 1.8",
        "SoundFX 1.945",
        "SoundFX 2.0",
        "FastTracker II",
        "Sk@leTracker",
        "MadTracker 2.0",
        "MilkyTracker",
        "DigiBooster Pro 2.18",
        "OpenMPT"
      ]);
  }
}