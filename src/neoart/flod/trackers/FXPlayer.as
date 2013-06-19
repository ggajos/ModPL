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

  public final class FXPlayer extends AmigaPlayer {
    private var
      samples    : Vector.<BaseSample>,
      track      : Vector.<int>,
      trackPos   : int,
      length     : int,
      patterns   : Vector.<BaseRow>,
      patternPos : int,
      jumpFlag   : int,
      voices     : Vector.<FXVoice>,
      delphine   : int;

    public function FXPlayer(amiga:Amiga = null) {
      super(amiga);

      PERIODS.fixed = true;

      track = new Vector.<int>(128, true);

      voices = new Vector.<FXVoice>(4, true);

      voices[0] = new FXVoice(0);
      voices[0].next = voices[1] = new FXVoice(1);
      voices[1].next = voices[2] = new FXVoice(2);
      voices[2].next = voices[3] = new FXVoice(3);

      this.amiga.process = process;
    }

    override public function set ntsc(value:Boolean):void {
      super.ntsc = value;

      amiga.samplesTick = int((tempo / 122) * (value ? 7.5152005551 : 7.58437970472));
    }

    override public function set version(value:int):void {
      if (soundPos != 0.0) return;

      if (value < SOUNDFX_10) {
        value = SOUNDFX_20;
      } else if (value > SOUNDFX_20) {
        value = SOUNDFX_10;
      }

      m_version = value;
    }

    override protected function initialize():void {
      var voice:FXVoice = voices[0];
      super.initialize();

      ntsc = m_ntsc;

      trackPos   = m_trackPos;
      patternPos = 0;
      jumpFlag   = 0;

      do {
        voice.initialize();
        voice.channel = amiga.channels[voice.index];
        voice.sample = samples[0];
      } while (voice = voice.next);
    }

    override protected function loader(stream:ByteArray, extra:ByteArray):void {
      var base:int, empty:BaseSample, higher:int, i:int, id:String, j:int, len:int, row:BaseRow, sample:BaseSample, size:int, value:int;

      if (stream.length < 1686) return;

      stream.position = 60;
      id = stream.readUTFBytes(4);

      if (id != "SONG") {
        stream.position = 124;
        id = stream.readUTFBytes(4);
        if (id != "SO31" || stream.length < 2350) return;

        base = 544;
        len  = 32;
        m_version = SOUNDFX_20;
      } else {
        base = 0;
        len  = 16;
        m_version = SOUNDFX_10;
      }

      tempo = stream.readUnsignedShort();
      stream.position = 0;

      samples = new Vector.<BaseSample>(len, true);

      for (i = 1; i < len; ++i) {
        value = stream.readUnsignedInt();

        if (value) {
          sample = new BaseSample();
          sample.pointer = size;
          size += value;
          samples[i] = sample;
        }
      }

      stream.position += 20;

      for (i = 1; i < len; ++i) {
        sample = samples[i];

        if (!sample) {
          stream.position += 30;
          continue;
        }

        sample.name    = stream.readUTFBytes(22);
        sample.length  = stream.readUnsignedShort() << 1;
        sample.volume  = stream.readUnsignedShort();
        sample.loopPtr = stream.readUnsignedShort();
        sample.repeat  = stream.readUnsignedShort() << 1;
      }

      stream.position = base + 530;
      length = len = stream.readUnsignedByte();
      stream.position++;

      for (i = 0; i < len; ++i) {
        value = stream.readUnsignedByte() << 8;
        track[i] = value;

        if (value > higher) higher = value;
      }

      if (base) base += 4;
      stream.position = base + 660;
      higher += 256;
      patterns = new Vector.<BaseRow>(higher, true);

      len = samples.length;

      for (i = 0; i < higher; ++i) {
        row = new BaseRow();

        row.note   = stream.readShort();
        value      = stream.readUnsignedByte();
        row.param  = stream.readUnsignedByte();
        row.effect = value & 0x0f;
        row.sample = value >> 4;

        if (m_version == SOUNDFX_20) {
          if (row.note & 0x1000) {
            row.sample += 16;
            if (row.note > 0) row.note &= 0xefff;
          }
        } else {
          if (row.effect == 9 || row.note > 856) m_version = SOUNDFX_18;

          if (row.note < -3) m_version = SOUNDFX_19;
        }

        if (row.sample >= len) row.sample = 0;

        patterns[i] = row;
      }

      amiga.write(stream, size);

      empty = new BaseSample();
      empty.pointer = empty.loopPtr = amiga.memory.length;
      empty.length  = empty.repeat  = 4;

      for (i = 0; i < len; ++i) {
        sample = samples[i];

        if (!sample) {
          samples[i] = empty;
          continue;
        }

        size = sample.pointer + 4;

        for (j = sample.pointer; j < size; ++j) {
          amiga.memory[j] = 0;
        }

        sample.loopPtr += sample.pointer;
      }

      stream.position = higher = delphine = 0;

      for (i = 0; i < 265; ++i) {
        higher += stream.readUnsignedShort();
      }

      switch (higher) {
        case 172662:
        case 1391423:
        case 1458300:
        case 1706977:
        case 1920077:
        case 1920694:
        case 1677853:
        case 1931956:
        case 1926836:
        case 1385071:
        case 1720635:
        case 1714491:
        case 1731874:
        case 1437490:
          delphine = 1;
          break;
      }

      stream.clear();
      stream = null;
    }

    private function process():void {
      var chan:AmigaChannel, index:int, period:int, row:BaseRow, sample:BaseSample, value:int, voice:FXVoice = voices[0];

      if (!tick) {
        value = track[trackPos] + patternPos;

        do {
          chan = voice.channel;

          row = patterns[int(value + voice.index)];
          voice.period = row.note;
          voice.effect = row.effect;
          voice.param  = row.param;

          if (row.note == -3) {
            voice.effect = 0;
            continue;
          }

          if (row.sample) {
            sample = voice.sample = samples[row.sample];
            voice.volume = sample.volume;

            if (voice.effect == 5) {
              voice.volume += voice.param;
            } else if (voice.effect == 6) {
              voice.volume -= voice.param;
            }

            chan.volume = voice.volume;
          } else {
            sample = voice.sample;
          }

          if (row.note) {
            voice.last = row.note;
            voice.slideSpeed = 0;
            voice.stepSpeed  = 0;

            chan.enabled = 0;

            switch (row.note) {
              case -2:
                chan.volume = 0;
                break;
              case -4:
                jumpFlag = 1;
                break;
              case -5:
                break;
              default:
                chan.pointer = sample.pointer;
                chan.length  = sample.length;

                if (delphine) {
                  chan.period = voice.period << 1;
                } else {
                  chan.period = voice.period;
                }
                break;
            }

            if (row.sample) {
              chan.enabled = 1;
              chan.pointer = sample.loopPtr;
              chan.length  = sample.repeat;
            }
          }
        } while (voice = voice.next);
      } else {
        do {
          chan = voice.channel;

          if (m_version == SOUNDFX_18 && voice.period == -3) continue;

          if (voice.stepSpeed) {
            voice.stepPeriod += voice.stepSpeed;

            if (voice.stepSpeed < 0) {
              if (voice.stepPeriod < voice.stepWanted) {
                voice.stepPeriod = voice.stepWanted;
                if (m_version > SOUNDFX_18) voice.stepSpeed = 0;
              }
            } else {
              if (voice.stepPeriod > voice.stepWanted) {
                voice.stepPeriod = voice.stepWanted;
                if (m_version > SOUNDFX_18) voice.stepSpeed = 0;
              }
            }

            if (m_version > SOUNDFX_18) voice.last = voice.stepPeriod;
            chan.period = voice.stepPeriod;
          } else {
            if (voice.slideSpeed) {
              value = voice.slideParam & 0x0f;

              if (value) {
                if (++voice.slideCtr == value) {
                  voice.slideCtr = 0;
                  value = (voice.slideParam << 4) << 3;

                  if (voice.slideDir) {
                    voice.slidePeriod -= 8;
                    value -= voice.slideSpeed;
                  } else {
                    voice.slidePeriod += 8;
                    value += voice.slideSpeed;
                  }

                  if (value == voice.slidePeriod) voice.slideDir ^= 1;
                  chan.period = voice.slidePeriod;
                } else {
                  continue;
                }
              }
            }

            value = 0;

            switch (voice.effect) {
              case 0:
                break;
              case 1:   // arpeggio
                value = tick % 3;
                index = 0;

                if (value == 2) {
                  chan.period = voice.last;
                  continue;
                }

                if (value == 1) {
                  value = voice.param & 0x0f;
                } else {
                  value = voice.param >> 4;
                }

                while (voice.last != PERIODS[index]) index++;
                chan.period = PERIODS[int(index + value)];
                break;
              case 2:   // pitchbend
                value = voice.param >> 4;

                if (value) {
                  voice.period += value;
                } else {
                  voice.period -= (voice.param & 0x0f);
                }

                chan.period = voice.period;
                break;
              case 3:   // filter on
                amiga.filter = 1;
                break;
              case 4:   // filter off
                amiga.filter = 0;
                break;
              case 8:   // step down
                value = -1;
              case 7:   // step up
                voice.stepSpeed = voice.param & 0x0f;
                voice.stepPeriod = (m_version > SOUNDFX_18) ? voice.last : voice.period;
                if (value < 0) voice.stepSpeed = -voice.stepSpeed;
                index = 0;

                while (true) {
                  period = PERIODS[index];
                  if (period == voice.stepPeriod) break;

                  if (period < 0) {
                    index = -1;
                    break;
                  } else {
                    index++;
                  }
                }

                if (index > -1) {
                  period = voice.param >> 4;
                  if (value > -1) period = -period;
                  index += period;
                  if (index < 0) index = 0;
                  voice.stepWanted = PERIODS[index];
                } else {
                  voice.stepWanted = voice.period;
                }
                break;
              case 9:   // auto slide
                voice.slideSpeed = voice.slidePeriod = voice.period;
                voice.slideParam = voice.param;
                voice.slideDir = 0;
                voice.slideCtr = 0;
                break;
            }
          }
        } while (voice = voice.next);
      }

      if (++tick == speed) {
        tick = 0;
        patternPos += 4;

        if (patternPos == 256 || jumpFlag) {
          trackPos++;

          if (trackDone[trackPos]) {
            amiga.complete = 1;
          } else {
            trackDone[trackPos] = 1;
          }

          jumpFlag = 0;
          patternPos = 0;

          if (trackPos == length) {
            trackPos = 0;
            amiga.complete = 1;
          }
        }
      }

      m_position += amiga.samplesTick;
    }

    public static const
      SOUNDFX_10 : int = 1,
      SOUNDFX_18 : int = 2,
      SOUNDFX_19 : int = 3,
      SOUNDFX_20 : int = 4;

    private const
      PERIODS : Vector.<int> = Vector.<int>([
        1076,1016,960,906,856,808,762,720,678,640,604,570,
         538, 508,480,453,428,404,381,360,339,320,302,285,
         269, 254,240,226,214,202,190,180,170,160,151,143,
         135, 127,120,113,113,113,113,113,113,113,113,113,
         113, 113,113,113,113,113,113,113,113,113,113,113,
         113, 113,113,113,113,113,-1]);
  }
}