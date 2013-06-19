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
package neoart.flod.trackers {
  import flash.utils.*;
  import neoart.flod.core.*;

  public final class GMPlayer extends AmigaPlayer {
    private var
      samples    : Vector.<BaseSample>,
      track      : Vector.<int>,
      trackPos   : int,
      length     : int,
      patterns   : Vector.<BaseRow>,
      patternPos : int,
      voices     : Vector.<ATVoice>;

    public function GMPlayer(amiga:Amiga = null) {
      super(amiga);

      samples = new Vector.<BaseSample>(16, true);

      voices = new Vector.<ATVoice>(4, true);

      voices[0] = new ATVoice(0);
      voices[0].next = voices[1] = new ATVoice(1);
      voices[1].next = voices[2] = new ATVoice(2);
      voices[2].next = voices[3] = new ATVoice(3);

      this.amiga.process = process;
    }

    override protected function initialize():void {
      var voice:ATVoice = voices[0];
      super.initialize();

      trackPos = m_trackPos;
      patternPos = -4;

      do {
        voice.initialize();
        voice.channel = amiga.channels[voice.index];
        voice.sample = null;
      } while (voice = voice.next);
    }

    override protected function loader(stream:ByteArray, extra:ByteArray):void {
      var empty:BaseSample, higher:int, i:int, row:BaseRow, sample:BaseSample, size:int, temp:int, value:int;

      if (stream.length < 1470) return;

      stream.position = 4;

      for (i = 0; i < 15; ++i) {
        temp = stream.readUnsignedShort();

        if (temp) {
          if ((size += (temp << 1)) > stream.length) return;

          value = stream.readUnsignedShort();
          if (value > 64) return;

          stream.position += 4;
          if (stream.readUnsignedShort() > temp) return;
          stream.position += 6;
        } else {
          stream.position += 14;
        }
      }

      stream.position = 240;
      length = stream.readUnsignedInt();
      if ((240 + length) > 444) return;

      track = new Vector.<int>(length, true);

      for (i = 0; i < length; ++i) {
        value = stream.readShort() >> 2;

        if (value < 0) {
          value = 0;
        } else if (value > higher) {
          higher = value;
        }

        track[i] = value;
      }

      if (((higher << 2) + size) > stream.length) return;

      stream.position = 444;
      higher += 256;
      patterns = new Vector.<BaseRow>(higher, true);

      for (i = 0; i < higher; ++i) {
        row = new BaseRow();

        row.note   = stream.readUnsignedShort();
        if (row.note && row.note < 100) return;

        value      = stream.readUnsignedByte();
        row.param  = stream.readUnsignedByte();
        row.effect = value & 0x0f;
        row.sample = value >> 4;

        patterns[i] = row;
      }

      higher = stream.position;
      stream.position = 0;
      size = 0;

      for (i = 1; i < 16; ++i) {
        value = stream.readUnsignedInt();

        if (!value) {
          samples[i] = null;
          stream.position += 12;
          continue;
        }

        sample = new BaseSample();
        sample.length  = stream.readUnsignedShort() << 1;
        sample.pointer = size;
        sample.volume  = stream.readUnsignedShort();
        sample.loopPtr = stream.readUnsignedInt() - value;
        sample.repeat  = stream.readUnsignedShort() << 1;

        stream.position += 2;
        size += sample.length;
        samples[i] = sample;
      }

      stream.position = higher;
      amiga.write(stream, size);

      empty = new BaseSample();
      empty.pointer = empty.loopPtr = amiga.memory.length;
      empty.length  = empty.repeat  = 4;

      for (i = 0; i < 16; ++i) {
        sample = samples[i];

        if (!sample) {
          samples[i] = empty;
          continue;
        }

        if (sample.repeat == 4) {
          sample.loopPtr = amiga.memory.length;
        } else {
          sample.loopPtr += sample.pointer;
        }
      }

      m_version = 1;

      stream.clear();
      stream = null;
    }

    private function process():void {
      var chan:AmigaChannel, row:BaseRow, sample:BaseSample, value:int, voice:ATVoice = voices[0];

      do {
        chan = voice.channel;
        chan.period = voice.slide + voice.last;

        if (voice.enabled) {
          sample = voice.sample;
          voice.enabled = 0;
          voice.sample = null;

          chan.pointer = sample.loopPtr;
          chan.length  = sample.repeat;
        }

        if (voice.sample) {
          chan.enabled = voice.enabled = 1;
        }

        chan.volume = voice.volume;
      } while (voice = voice.next);

      if (++tick == speed) {
        tick = 0;
        patternPos += 4;

        if (patternPos == 256) {
          trackPos++;

          if (trackDone[trackPos]) {
            amiga.complete = 1;
          } else {
            trackDone[trackPos] = 1;
          }

          patternPos = 0;

          if (trackPos == length) {
            trackPos = 0;
            amiga.complete = 1;
          }
        }

        voice = voices[0];
        value = track[trackPos] + patternPos;

        do {
          chan = voice.channel;

          row = patterns[int(value + voice.index)];

          if (row.sample) {
            sample = samples[row.sample];

            if (sample) {
              voice.sample = sample;

              chan.enabled = 0;
              chan.volume  = 0;

              chan.pointer = sample.pointer;
              chan.length  = sample.length;
              chan.period  = row.note;

              voice.last = row.note;
              voice.slide = 0;
              voice.volume = sample.volume;
            }
          }

          switch (row.effect) {
            case 0:
              break;
            case 1:   // slide up
              voice.slide = -row.param;
              break;
            case 2:   // slide down
              voice.slide = row.param;
              break;
            case 3:   // set volume
              voice.volume = row.param;
              break;
            case 5:   // position jump
              trackPos = row.param - 1;
              patternPos = 252;
              break;
            case 4:   // pattern break;
              patternPos = 252;
              break;
            case 8:   // set speed
              speed = row.param;
              break;
            case 6:   // filter on
              amiga.filter = 1;
              break;
            case 7:   // filter off
              amiga.filter = 0;
              break;
          }
        } while (voice = voice.next);
      }

      m_position += amiga.samplesTick;
    }
  }
}