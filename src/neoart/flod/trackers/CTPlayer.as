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

  public final class CTPlayer extends AmigaPlayer {
    private var
      samples    : Vector.<BaseSample>,
      track      : Vector.<BaseStep>,
      trackPos   : int,
      length     : int,
      restart    : int,
      patterns   : Vector.<BaseRow>,
      patternPos : int,
      jumpFlag   : int,
      alternate  : Vector.<int>,
      voices     : Vector.<ATVoice>;

    public function CTPlayer(amiga:Amiga = null) {
      super(amiga);

      PERIODS.fixed = true;
      VIBRATO.fixed = true;

      samples = new Vector.<BaseSample>(32, true);
      track = new Vector.<BaseStep>(512, true);
      alternate = new Vector.<int>(2, true);

      voices = new Vector.<ATVoice>(4, true);

      voices[0] = new ATVoice(0);
      voices[0].next = voices[1] = new ATVoice(1);
      voices[1].next = voices[2] = new ATVoice(2);
      voices[2].next = voices[3] = new ATVoice(3);
    }

    override protected function initialize():void {
      var voice:ATVoice = voices[0];
      super.initialize();

      trackPos   = m_trackPos;
      patternPos = 0;
      jumpFlag   = 0;

      if (m_version == SOUNDTRACKER_26) {
        speed = 0;
        alternate[0] = 6;
        alternate[1] = 6;
      }

      do {
        voice.initialize();
        voice.channel = amiga.channels[voice.index];
        voice.sample = samples[0];
      } while (voice = voice.next);
    }

    override protected function loader(stream:ByteArray, extra:ByteArray):void {
      var higher:int, i:int, j:int, row:BaseRow, sample:BaseSample, size:int, step:BaseStep, value:int;

      if (stream.length < 1728) return;

      stream.position = 952;

      if (stream.readUTFBytes(4) == "KRIS") {
        m_version = CHIPTRACKER;
        amiga.process = chiptracker;

        stream.position = 0;
        m_title = stream.readUTFBytes(22);
        stream.position = 44;
      } else {
        stream.position = 1464;
        if (stream.readUTFBytes(3) != "MTN") return;

        m_version = SOUNDTRACKER_26;
        amiga.process = soundtracker;

        stream.position = 0;
        m_title = stream.readUTFBytes(20);
        stream.position = 42;
      }

      for (i = 1; i < 32; ++i) {
        value = stream.readUnsignedShort();

        if (!value) {
          samples[i] = null;
          stream.position += 28;
          continue;
        }

        stream.position -= 24;

        if (m_version == CHIPTRACKER) {
          higher = stream.readByte();

          if (!higher) {
            samples[i] = null;
            stream.position += 51;
            continue;
          }

          stream.position--;
        }

        sample = new BaseSample();
        sample.name = stream.readUTFBytes(22);
        sample.length = value << 1;

        stream.position += 3;
        sample.volume  = stream.readUnsignedByte();
        sample.loopPtr = stream.readUnsignedShort();
        sample.repeat  = stream.readUnsignedShort() << 1;

        stream.position += 22;
        sample.pointer = size;
        size += sample.length;
        samples[i] = sample;
      }

      if (m_version == CHIPTRACKER) {
        stream.position = 956;
        length  = stream.readUnsignedByte() << 2;
        restart = stream.readUnsignedByte();

        for (i = 0; i < length; ++i) {
          value = stream.readUnsignedByte() << 6;

          if (value > higher) higher = value;

          step = new BaseStep();
          step.pattern = value;
          step.transpose = stream.readByte();

          track[i] = step;
        }

        stream.position = 1982;
        stream.position = 1984 + (stream.readByte() << 6);
        higher += 64;
      } else {
        stream.position = 950;
        length  = stream.readUnsignedByte() << 2;
        restart = 0;

        higher = stream.readUnsignedByte() << 6;

        for (i = 0; i < 512; ++i) {
          step = new BaseStep();
          step.pattern = stream.readUnsignedByte() << 6;
          track[i] = step;
        }

        stream.position = 1468;
      }

      patterns = new Vector.<BaseRow>(higher, true);

      for (i = 0; i < higher; ++i) {
        row = new BaseRow();

        if (m_version == CHIPTRACKER) {
          row.note   = stream.readUnsignedByte() >> 1;
          row.sample = stream.readUnsignedByte();
          row.effect = stream.readUnsignedByte();
          row.param  = stream.readUnsignedByte();
        } else {
          value = stream.readUnsignedInt();

          row.note   = (value >> 16) & 0x0fff;
          row.effect = (value >>  8) & 0x0f;
          row.sample = (value >> 24) & 0xf0 | (value >> 12) & 0x0f;
          row.param  = value & 0xff;
        }

        if (row.sample > 31 || !samples[row.sample]) row.sample = 0;

        patterns[i] = row;
      }

      amiga.write(stream, size);

      for (i = 1; i < 32; ++i) {
        sample = samples[i];
        if (!sample) continue;

        if (m_version == CHIPTRACKER) {
          if (sample.repeat == 2) {
            sample.repeat = 4;
            sample.loopPtr = amiga.memory.length;
          } else {
            sample.loopPtr += sample.pointer;
          }
        } else {
          size = sample.pointer + 4;

          for (j = sample.pointer; j < size; ++j) {
            amiga.memory[j] = 0;
          }

          if (sample.loopPtr || sample.repeat != 2) {
            sample.loopPtr <<= 1;
            sample.length = sample.loopPtr + sample.repeat;
            sample.loopPtr += sample.pointer;
          } else {
            sample.loopPtr = sample.pointer;
          }
        }
      }

      sample = new BaseSample();
      sample.pointer = sample.loopPtr = amiga.memory.length;
      sample.length  = sample.repeat  = 4;
      samples[0] = sample;

      stream.clear();
      stream = null;
    }

    private function chiptracker():void {
      var chan:AmigaChannel, pos:int, row:BaseRow, sample:BaseSample, step:BaseStep, value:int, voice:ATVoice = voices[0];

      if (!tick) {
        pos = trackPos;

        do {
          chan = voice.channel;
          voice.enabled = 0;

          step = track[int(pos + voice.index)];

          row = patterns[int(step.pattern + patternPos)];
          voice.effect = row.effect;
          voice.param  = row.param;

          if (row.sample) {
            sample = voice.sample = samples[row.sample];
            voice.volume = sample.volume;
          } else {
            sample = voice.sample;
          }

          chan.volume = voice.volume;

          if (row.note != 0x54) {
            voice.last = row.note + step.transpose;
            if (voice.last < 0) voice.last += 255;
            voice.last &= 0xff;

            value = PERIODS[voice.last];

            if (row.effect == 3) {
              if (value != voice.period) {
                voice.portaPeriod = value;
                voice.portaDir = 0;
                if (voice.period < value) voice.portaDir = 1;
              } else {
                voice.portaPeriod = 0;
              }
            } else {
              voice.enabled = 1;
              voice.period  = value;
              voice.vibratoPos = 0;

              chan.enabled = 0;
              chan.pointer = sample.pointer;
              chan.length  = sample.length;
              chan.period  = value;
            }
          }

          switch (voice.effect) {
            case 11:  // position jump
              trackPos = (voice.param << 2) - 4;
              jumpFlag = 1;
              break;
            case 12:  // set volume
              chan.volume = voice.volume = voice.param;
              break;
            case 13:  // pattern break
              jumpFlag = 1;
              break;
            case 14:  // set filter
              amiga.filter = voice.param ^ 1;
              break;
            case 15:  // set speed
              if (voice.param) speed = voice.param;
              break;
          }

          if (voice.enabled) chan.enabled = 1;
          chan.pointer = sample.loopPtr;
          chan.length  = sample.repeat;
        } while (voice = voice.next);
      } else {
        do {
          chan = voice.channel;

          switch (voice.effect) {
            case 0:   // arpeggio
              if (!voice.param) continue;

              value = tick % 3;
              if (value) continue;

              if (value == 1) {
                value = voice.param >> 4;
              } else {
                value = voice.param & 0x0f;
              }

              value += voice.last;
              voice.period = PERIODS[value];
              chan.period = voice.period;
              break;
            case 1:   // portamento up
              voice.period -= voice.param;

              if (voice.period < 113) voice.period = 113;

              chan.period = voice.period;
              break;
            case 2:   // portamento down
              voice.period += voice.param;

              if (voice.period > 856) voice.period = 856;

              chan.period = voice.period;
              break;
            case 3:   // tone portamento
              if (voice.param) {
                voice.portaSpeed = voice.param;
                voice.param = 0;
              }

              if (!voice.portaPeriod) break;

              if (voice.portaDir) {
                voice.period -= voice.portaSpeed;

                if (voice.portaPeriod >= voice.period) {
                  voice.period = voice.portaPeriod;
                  voice.portaPeriod = 0;
                }
              } else {
                voice.period += voice.portaSpeed;

                if (voice.portaPeriod <= voice.period) {
                  voice.period = voice.portaPeriod;
                  voice.portaPeriod = 0;
                }
              }

              chan.period = voice.period;
              break;
            case 4:   // vibrato
              if (voice.param) {
                voice.vibratoParam = voice.param;
              }

              value = VIBRATO[int((voice.vibratoPos >> 2) & 31)];
              value = ((voice.vibratoParam & 0x0f) * value) >> 7;

              if (voice.vibratoPos > 127) {
                chan.period = voice.period - value;
              } else {
                chan.period = voice.period + value;
              }

              value = (voice.vibratoParam >> 2) & 60;
              voice.vibratoPos = (voice.vibratoPos + value) & 255;
              break;
            case 10:  // volume slide
              value = voice.param;

              if (value < 16) {
                value = voice.volume - value;
                if (value < 0) value = 0;
              } else {
                value = voice.volume + (value >> 4);
                if (value > 64) value = 64;
              }

              chan.volume = voice.volume = value;
              break;
          }
        } while (voice = voice.next);
      }

      if (++tick == speed) {
        tick = 0;
        patternPos++;

        if (patternPos == 64 || jumpFlag) {
          trackPos += 4;

          if (trackDone[trackPos]) {
            amiga.complete = 1;
          } else {
            trackDone[trackPos] = 1;
          }

          jumpFlag = 0;
          patternPos = 0;

          if (trackPos == length) {
            trackPos = restart;
            amiga.complete = 1;
          }
        }
      }

      m_position += amiga.samplesTick;
    }

    private function soundtracker():void {
      var chan:AmigaChannel, pos:int, row:BaseRow, sample:BaseSample, speed0:int, speed1:int, step:BaseStep, value:int, voice:ATVoice = voices[0];

      if (!tick) {
        pos = trackPos;

        do {
          chan = voice.channel;
          voice.enabled = 0;

          step = track[int(pos + voice.index)];

          row = patterns[int(step.pattern + patternPos)];
          voice.effect = row.effect;
          voice.param  = row.param;

          if (row.sample) {
            sample = voice.sample = samples[row.sample];
            chan.volume = voice.volume = sample.volume;
          } else {
            sample = voice.sample;
          }

          if (row.note) {
            if (row.effect == 3) {
              voice.portaPeriod = row.note;
              voice.portaDir = 0;

              if (voice.portaPeriod == voice.period) {
                voice.portaPeriod = 0;
              } else if (voice.portaPeriod < voice.period) {
                voice.portaDir = 1;
              }
            } else {
              voice.enabled = 1;
              voice.period = row.note;
              voice.vibratoPos = 0;

              chan.enabled = 0;
              chan.pointer = sample.pointer;
              chan.length  = sample.length;
              chan.period  = voice.period;
            }
          }

          switch (row.effect) {
            case 11:  // position jump
              trackPos = (voice.param << 2) - 4;
              jumpFlag = 1;
              break;
            case 12:  // set volume
              chan.volume = voice.param;
              //chan.volume = voice.volume = voice.param;
              break;
            case 13:  // pattern break
              jumpFlag = 1;
              break;
            case 14:  // set filter
              amiga.filter = voice.param & 1;
              break;
            case 15:  // set speed
              if (!voice.param) break;

              speed0 = voice.param & 0x0f;
              speed1 = voice.param >> 4;
              if (!speed1) speed1 = speed0;

              alternate[0] = speed1;
              alternate[1] = speed0;
              //tick = 0;
              break;
          }

          if (voice.enabled) chan.enabled = 1;
          chan.pointer = sample.loopPtr;
          chan.length  = sample.repeat;
        } while (voice = voice.next);
      } else {
        do {
          chan = voice.channel;

          if (!voice.effect && !voice.param) {
            chan.period = voice.period;
            continue;
          }

          switch (voice.effect) {
            case 0:   // arpeggio
              value = tick % 3;

              if (!value) {
                chan.period = voice.period;
                break;
              }

              if (value == 1) {
                value = voice.param >> 4;
              } else {
                value = voice.param & 0x0f;
              }

              speed0 = 36;
              while (voice.period >= PERIODS[speed0]) speed0++;
              value += speed0;

              if (value < PERIODS.length) {
                chan.period = PERIODS[value];
              } else {
                chan.period = 0;
              }
              break;
            case 1:   // portamento up
              voice.period -= voice.param;

              if (voice.period < 113) voice.period = 113;

              chan.period = voice.period;
              break;
            case 2:   // portamento down
              voice.period += voice.param;

              if (voice.period > 856) voice.period = 856;

              chan.period = voice.period;
              break;
            case 3:   // tone portamento
              if (voice.param) {
                voice.portaSpeed = voice.param;
                voice.param = 0;
              }

              if (!voice.portaPeriod) break;

              if (voice.portaDir) {
                voice.period -= voice.portaSpeed;

                if (voice.period <= voice.portaPeriod) {
                  voice.period = voice.portaPeriod;
                  voice.portaPeriod = 0;
                }
              } else {
                voice.period += voice.portaSpeed;

                if (voice.period >= voice.portaPeriod) {
                  voice.period = voice.portaPeriod;
                  voice.portaPeriod = 0;
                }
              }

              chan.period = voice.period;
              break;
            case 4:   // vibrato
              if (voice.param) {
                voice.vibratoParam = voice.param;
              }

              value = VIBRATO[int((voice.vibratoPos >> 2) & 31)];
              value = ((voice.vibratoParam & 0x0f) * value) >> 6;

              if (voice.vibratoPos > 127) {
                chan.period = voice.period - value;
              } else {
                chan.period = voice.period + value;
              }

              value = (voice.vibratoParam >> 2) & 60;
              voice.vibratoPos = (voice.vibratoPos + value) & 255;
              break;
            case 10:  // volume slide
              chan.period = voice.period;
              value = voice.param >> 4;

              if (value) {
                voice.volume += value;
                if (voice.volume > 64) voice.volume = 64;
              } else {
                voice.volume -= (voice.param & 0x0f);
                if (voice.volume < 0) voice.volume = 0;
              }

              chan.volume = voice.volume;
              break;
          }
        } while (voice = voice.next);
      }

      if (++tick == alternate[speed]) {
        tick = 0;
        patternPos++;
        speed ^= 1;

        if (patternPos == 64 || jumpFlag) {
          trackPos += 4;

          if (trackDone[trackPos]) {
            amiga.complete = 1;
          } else {
            trackDone[trackPos] = 1;
          }

          jumpFlag = 0;
          patternPos = 0;
          speed = 0;

          if (trackPos == length) {
            trackPos = 0;
            amiga.complete = 1;
          }
        }
      }

      m_position += amiga.samplesTick;
    }

    private const
      CHIPTRACKER     : int = 1,
      SOUNDTRACKER_26 : int = 2,

      PERIODS : Vector.<int> = Vector.<int>([
        6848,6464,6096,5760,5424,5120,4832,4560,4304,4064,3840,3624,
        3424,3232,3048,2880,2712,2560,2416,2280,2152,2032,1920,1812,
        1712,1616,1524,1440,1356,1280,1208,1140,1076,1016, 960, 906,
         856, 808, 762, 720, 678, 640, 604, 570, 538, 508, 480, 453,
         428, 404, 381, 360, 339, 320, 302, 285, 269, 254, 240, 226,
         214, 202, 190, 180, 170, 160, 151, 143, 135, 127, 120, 113,0,0,0]),

      VIBRATO : Vector.<int> = Vector.<int>([
          0, 24, 49, 74, 97,120,141,161,180,197,212,
        224,235,244,250,253,255,253,250,244,235,224,
        212,197,180,161,141,120, 97, 74, 49, 24]);
  }
}