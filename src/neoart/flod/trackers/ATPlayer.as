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

  public final class ATPlayer extends AmigaPlayer {
    private var
      samples      : Vector.<BaseSample>,
      track        : Vector.<int>,
      trackPos     : int,
      length       : int,
      restart      : int,
      patterns     : Vector.<BaseRow>,
      patternPos   : int,
      patternBreak : int,
      patternDelay : int,
      breakPos     : int,
      jumpFlag     : int,
      voices       : Vector.<ATVoice>,
      minPeriod    : int,
      maxPeriod    : int,
      notes        : Vector.<int>,
      octaves      : int,
      patternLen   : int,
      restartPos   : int,
      vibratoDepth : int;

    public function ATPlayer(amiga:Amiga = null) {
      super(amiga);

      PERIODS_3.fixed = true;
      PERIODS_5.fixed = true;

      VIBRATO.fixed = true;
      FUNKREP.fixed = true;

      samples = new Vector.<BaseSample>(32, true);
      track = new Vector.<int>(128, true);
    }

    override public function set ntsc(value:Boolean):void {
      super.ntsc = value;

      if (m_version == ULTIMATE_SOUNDTRACKER) {
        amiga.samplesTick = int((240 - tempo) * (value ? 7.5152005551 : 7.58437970472));
      }
    }

    override public function set version(value:int):void {
      if (soundPos != 0.0) return;

      if (m_version < SOUNDTRACKER_23) {
        if (value < ULTIMATE_SOUNDTRACKER) {
          value = DOC_SOUNDTRACKER_20;
        } else if (value > DOC_SOUNDTRACKER_20) {
          value = ULTIMATE_SOUNDTRACKER;
        }
      } else {
        if (value < SOUNDTRACKER_23) {
          value = FASTTRACKER;
        } else if (value > FASTTRACKER) {
          value = SOUNDTRACKER_23;
        }
      }

      m_version = value;

      if (value > PROTRACKER_10 && value != PROTRACKER_10C) {
        vibratoDepth = 7;
      } else {
        vibratoDepth = 6;
      }

      if (value == NOISETRACKER_11 || value == NOISETRACKER_20 || value == STARTREKKER) {
        restart = restartPos;
      } else {
        restart = 0;
      }

      if (value == FASTTRACKER) {
        notes = PERIODS_5;
        octaves = 61;
      } else {
        notes = PERIODS_3;
        octaves = 37;
      }

      minPeriod = notes[int(octaves - 2)];
      maxPeriod = notes[0];

      if (value < SOUNDTRACKER_23) {
        amiga.process = soundtracker;
      } else if (value == PROTRACKER_10 || value > STARTREKKER) {
        amiga.process = protracker;
      } else {
        amiga.process = noisetracker;
      }
    }

    override protected function initialize():void {
      var voice:ATVoice = voices[0];
      super.initialize();

      if (m_version >= PROTRACKER_10) {
        tempo = 125;
      }

      ntsc = m_ntsc;

      trackPos     = m_trackPos;
      patternPos   = 0;
      patternBreak = 0;
      patternDelay = 0;
      breakPos     = 0;
      jumpFlag     = 0;

      do {
        voice.initialize();
        voice.channel = amiga.channels[voice.index];
        voice.sample = samples[0];
      } while (voice = voice.next);
    }

    override protected function loader(stream:ByteArray, extra:ByteArray):void {
      var higher:int, i:int, id:String, j:int, keep:int, row:BaseRow, sample:BaseSample, size:int, value:int;

      m_channels = 4;

      if (stream.length < 2106) {
        loader15(stream);
        return;
      }

      stream.position = 1080;
      id = stream.readUTFBytes(4);
      m_version = NOISETRACKER_10;

      if (id != "M.K." && id != "M!K!") {
        if (id == "FLT4") {
          m_version = STARTREKKER;
        } else if (id.indexOf("CH") > 0) {
          value = parseInt(id);

          if (value < 2 || value > 32) return;

          m_channels = value;
          m_version = FASTTRACKER;
        } else {
          m_version = 0;
          loader15(stream);
          return;
        }
      }

      patternLen = m_channels << 6;
      restartPos = 0;

      stream.position = 950;
      length = stream.readUnsignedByte();
        keep = stream.readUnsignedByte();

      if (keep == 0x7f) {
        if (m_version < FASTTRACKER) m_version = PROTRACKER_30;
      } else if (keep != 0x78) {
        if (m_version < STARTREKKER) m_version = NOISETRACKER_11;
        restartPos = keep;
      }

      stream.position = 0;
      m_title = stream.readUTFBytes(20);
      stream.position = 42;

      for (i = 1; i < 32; ++i) {
        value = stream.readUnsignedShort();

        if (!value) {
          samples[i] = null;
          stream.position += 28;
          continue;
        }

        sample = new BaseSample();

        stream.position -= 24;
        sample.name = stream.readUTFBytes(22);
        sample.length = value << 1;

        stream.position += 2;
        sample.finetune = stream.readUnsignedByte();
        sample.volume   = stream.readUnsignedByte();
        sample.loopPtr  = stream.readUnsignedShort() << 1;
        sample.repeat   = stream.readUnsignedShort() << 1;

        if ((sample.loopPtr + sample.repeat) > sample.length) {
          m_version = SOUNDTRACKER_23;
        }

        stream.position += 22;
        sample.pointer = size;
        size += sample.length;
        samples[i] = sample;
      }

      stream.position = 952;

      for (i = 0; i < 128; ++i) {
        value = stream.readUnsignedByte() * patternLen;
        track[i] = value;

        if (value > higher) higher = value;
      }

      stream.position = 1084;
      higher += patternLen;
      patterns = new Vector.<BaseRow>(higher, true);

      for (i = 0; i < higher; ++i) {
        row = new BaseRow();
        value = row.step = stream.readUnsignedInt();

        row.note   = (value >> 16) & 0x0fff;
        row.effect = (value >>  8) & 0x0f;
        row.sample = (value >> 24) & 0xf0 | (value >> 12) & 0x0f;
        row.param  = value & 0xff;

        if (row.sample > 31) row.sample = 0;

        if (m_version < NOISETRACKER_20) {
          if (row.effect == 5 || row.effect == 6) m_version = NOISETRACKER_20;
        }

        if (m_version != STARTREKKER) {
          if (m_version < PROTRACKER_10C) {
            if ((row.effect > 6 && row.effect < 10) || (row.effect == 14 && ((row.param & 0x0f) > 1))) {
              if (keep == 0x78) {
                m_version = PROTRACKER_10;
              } else {
                m_version = PROTRACKER_30;
              }
            }

            if ((row.effect == 15 && row.param > 31) || (row.effect == 13 && row.param != 0)) {
              m_version = PROTRACKER_30;
            }
          }

          if (row.effect == 8) m_version = FASTTRACKER;
        }

        patterns[i] = row;
      }

      amiga.write(stream, size);

      for (i = 1; i < 32; ++i) {
        sample = samples[i];
        if (!sample) continue;

        if (m_version == NOISETRACKER_11) {
          if (sample.name.indexOf("2.0") > -1) {
            m_version = NOISETRACKER_20;
          }
        }

        size = sample.pointer + 4;

        for (j = sample.pointer; j < size; ++j) {
          amiga.memory[j] = 0;
        }

        if (sample.loopPtr || sample.repeat > 2) {
          if (m_version == SOUNDTRACKER_23) {
            sample.pointer += (sample.loopPtr >> 1);
            sample.loopPtr = sample.pointer;
            sample.length  = sample.repeat;
          } else {
            sample.length = sample.loopPtr + sample.repeat;
            sample.loopPtr += sample.pointer;
          }
        } else {
          sample.repeat  = 4;
          sample.loopPtr = amiga.memory.length;
        }
      }

      loaded(stream);
    }

    private function loader15(stream:ByteArray):void {
      var higher:int, i:int, j:int, row:BaseRow, sample:BaseSample, score:int, size:int, value:int;

      if (stream.length < 1628) return;

      stream.position = 60;
      if (stream.readUTFBytes(4) == "SONG") return;

      stream.position = 0;
      m_title = stream.readUTFBytes(20);
      score += isLegal(m_title);

      m_version = ULTIMATE_SOUNDTRACKER;
      stream.position = 42;

      for (i = 1; i < 16; ++i) {
        value = stream.readUnsignedShort();

        if (!value) {
          samples[i] = null;
          stream.position += 28;
          continue;
        }

        sample = new BaseSample();

        stream.position -= 24;
        sample.name = stream.readUTFBytes(22);
        score += isLegal(sample.name);
        sample.length = value << 1;

        stream.position += 3;
        sample.volume  = stream.readUnsignedByte();

        if (sample.volume > 64) {
          m_version = 0;
          return;
        }

        sample.loopPtr = stream.readUnsignedShort();
        sample.repeat  = stream.readUnsignedShort() << 1;

        if (sample.length > 9998) {
          m_version = MASTER_SOUNDTRACKER;
        }

        stream.position += 22;
        sample.pointer = size;
        size += sample.length;
        samples[i] = sample;
      }

      stream.position = 470;
      length = stream.readUnsignedByte();
      tempo  = stream.readUnsignedByte();

      for (i = 0; i < 128; ++i) {
        value = stream.readUnsignedByte() << 8;
        track[i] = value;

        if (value > 16128) score--;

        if (value > higher) higher = value;
      }

      if ((stream.position + (higher * 3)) > stream.length) {
        m_version = 0;
        return;
      }

      stream.position = 600;
      higher += 256;
      patterns = new Vector.<BaseRow>(higher, true);

      for (i = 0; i < higher; ++i) {
        row = new BaseRow();

        row.note   = stream.readUnsignedShort();
        value      = stream.readUnsignedByte();
        row.param  = stream.readUnsignedByte();
        row.effect = value & 0x0f;
        row.sample = value >> 4;

        if (row.effect > 2 && row.effect < 11) score--;

        if (row.note) {
          if (row.note < 113 || row.note > 856) score--;
        }

        if (row.sample > 15) score--;

        if (m_version < TJC_SOUNDTRACKER_2) {
          if (row.param && !row.effect) {
            version = TJC_SOUNDTRACKER_2;
          }
        }

        if (m_version < DOC_SOUNDTRACKER_4 && row.effect > 2) {
          m_version = TJC_SOUNDTRACKER_2;
        }

        if (m_version < MASTER_SOUNDTRACKER && row.effect == 15) {
          m_version = DOC_SOUNDTRACKER_4;
        }

        if (row.effect == 11) m_version = DOC_SOUNDTRACKER_20;

        patterns[i] = row;
      }

      amiga.write(stream, size);

      for (i = 1; i < 32; ++i) {
        if (i > 15) {
          sample = samples[i] = null;
        } else {
          sample = samples[i];
        }

        if (!sample) continue;

        size = sample.pointer + 4;

        for (j = sample.pointer; j < size; ++j) {
          amiga.memory[j] = 0;
        }

        if (sample.loopPtr || sample.repeat != 2) {
          if ((sample.loopPtr + sample.repeat) > sample.length) {
            score--;
            value = sample.length - sample.repeat;

            if (value) {
              sample.loopPtr = value;
            } else {
              sample.repeat -= sample.loopPtr;
            }
          }

          sample.length  = sample.repeat;
          sample.loopPtr += sample.pointer;
          sample.pointer = sample.loopPtr;
        } else {
          sample.repeat = 4;
          sample.loopPtr = amiga.memory.length;
        }
      }

      if (score < 1) {
        m_version = 0;
      } else {
        loaded(stream);
      }
    }

    private function loaded(stream:ByteArray):void {
      var i:int, sample:BaseSample;

      samples[0] = null;

      sample = new BaseSample();
      sample.pointer = sample.loopPtr = amiga.memory.length;
      sample.length  = sample.repeat  = 4;

      for (i = 0; i < 32; ++i) {
        if (!samples[i]) samples[i] = sample;
      }

      if (!voices || voices.length != m_channels) {
        voices = new Vector.<ATVoice>(m_channels, true);
        voices[0] = new ATVoice(0);

        for (i = 1; i < m_channels; ++i) {
          voices[i] = voices[int(i - 1)].next = new ATVoice(i);
        }
      }

      version = m_version;

      stream.clear();
      stream = null;
    }

    private function soundtracker():void {
      var chan:AmigaChannel, row:BaseRow, sample:BaseSample, slide:int, value:int, voice:ATVoice = voices[0];

      if (!tick) {
        value = track[trackPos] + patternPos;

        do {
          chan = voice.channel;
          voice.enabled = 0;

          row = patterns[int(value + voice.index)];
          voice.period = row.note;
          voice.effect = row.effect;
          voice.param  = row.param;

          if (row.sample) {
            sample = samples[row.sample];
            if (!sample) sample = samples[0];

            voice.sample = sample;
            voice.volume = sample.volume;

            if (voice.effect == 12 && ((m_version ^ 4) < 2)) {                      // set volume, MST and DOC9 only
              chan.volume = voice.param;
            } else {
              chan.volume = sample.volume;
            }
          } else {
            sample = voice.sample;
          }

          if (row.note) {
            voice.enabled = 1;
            voice.last = voice.period;

            chan.enabled = 0;
            chan.pointer = sample.pointer;
            chan.length  = sample.length;
            chan.period  = voice.period;
          }

          if (voice.enabled) chan.enabled = 1;

          chan.pointer = sample.loopPtr;
          chan.length  = sample.repeat;

          if ((m_version ^ 2) < 2) {
            if (voice.effect == 14) {                                               // volume auto slide, TJC2 and DOC4 only
              voice.slide = voice.param;
            } else {
              if (voice.effect == 12) {
                chan.volume = voice.param;
              } else if (voice.effect == 15 && m_version == DOC_SOUNDTRACKER_4) {
                voice.param &= 0x0f;
                if (voice.param) speed = voice.param;
              } else if (!voice.param) {
                voice.slide = 0;
              }
            }
          }

          if (m_version < DOC_SOUNDTRACKER_20) continue;

          switch (row.effect) {
            case 11:  // position jump
              trackPos = (voice.param - 1) & 127;
              jumpFlag ^= 1;
              break;
            case 12:  // set volume
              chan.volume = voice.param;
              break;
            case 13:  // pattern break
              jumpFlag ^= 1;
              break;
            case 14:  // set filter
              amiga.filter = voice.param ^ 1;
              break;
            case 15:  // set speed
              voice.param &= 0x0f;
              if (voice.param) speed = voice.param
              break;
          }
        } while (voice = voice.next);
      } else {
        do {
          if (!voice.param) continue;
          chan = voice.channel;

          if (m_version == ULTIMATE_SOUNDTRACKER) {
            if (voice.effect == 1) {
              arpeggio(voice);
            } else if (voice.effect == 2) {
              value = voice.param >> 4;

              if (value) {
                voice.period += value;
              } else {
                voice.period -= (voice.param & 0x0f);
              }

              chan.period = voice.period;
            }
            continue;
          }

          switch (voice.effect) {
            case 0:   // arpeggio
              arpeggio(voice);
              break;
            case 1:   // portamento up
              value = voice.param;
              if ((m_version ^ 4) < 2) value & 0x0f;                                // MST and DOC9 only

              voice.last -= value;

              if (voice.last < 113) voice.last = 113;

              chan.period = voice.last;
              break;
            case 2:   // portamento down
              value = voice.param;
              if ((m_version ^ 4) < 2) value & 0x0f;                                // MST and DOC9 only

              voice.last += value;

              if (voice.last > 856) voice.last = 856;

              chan.period = voice.last;
              break;
          }

          if (m_version == DOC_SOUNDTRACKER_20) continue;

          if (voice.slide && ((m_version ^ 2) < 2)) {                               // volume auto slide, TJC2 and DOC4 only
            slide = voice.slide;
          }

          if (voice.effect == 13 && m_version != DOC_SOUNDTRACKER_9) {              // volume slide, all but DOC9
            slide = voice.param;
          }

          if (slide) {
            value = slide >> 4;

            if (value) {
              voice.volume += value;
            } else {
              voice.volume -= (slide & 0x0f);
            }

            if (voice.volume < 0) {
              voice.volume = 0;
            } else if (voice.volume > 64) {
              voice.volume = 64;
            }

            chan.volume = voice.volume;
            slide = 0;
          }

          if ((m_version ^ 4) >= 2) continue;

          switch (voice.effect) {                                                   // MST and DOC9 only effects
            case 12:  // set volume
              chan.volume = voice.param;
              break;
            case 14:  // set filter
              amiga.filter = voice.param ^ 1;
              break;
            case 15:  // set speed
              voice.param &= 0x0f;

              if (voice.param && voice.param > tick) {
                speed = voice.param;
              }
              break;
          }
        } while (voice = voice.next);
      }

      if (++tick == speed) {
        tick = 0;
        patternPos += 4;

        if (patternPos == 256 || jumpFlag) {
          trackPos = (++trackPos & 127);

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

    private function noisetracker():void {
      var chan:AmigaChannel, i:int, row:BaseRow, sample:BaseSample, slide:int, value:int, voice:ATVoice = voices[0];

      if (!tick) {
        value = track[trackPos] + patternPos;

        do {
          chan = voice.channel;
          voice.enabled = 0;

          row = patterns[int(value + voice.index)];
          voice.effect = row.effect;
          voice.param  = row.param;

          if (row.sample) {
            sample = voice.sample = samples[row.sample];
            chan.volume = voice.volume = sample.volume;
          } else {
            sample = voice.sample;
          }

          if (row.note) {
            if (voice.effect == 3 || voice.effect == 5) {
              if (row.note < voice.period) {
                voice.portaDir = 1;
                voice.portaPeriod = row.note;
              } else if (row.note > voice.period) {
                voice.portaDir = 0;
                voice.portaPeriod = row.note;
              } else {
                voice.portaPeriod = 0;
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

          if (voice.enabled) chan.enabled = 1;

          chan.pointer = sample.loopPtr;
          chan.length  = sample.repeat;

          switch (voice.effect) {
            case 11:  // position jump
              trackPos = (voice.param - 1) & 127;
              jumpFlag ^= 1;
              break;
            case 12:  // set volume
              chan.volume = voice.param;

              if (m_version >= NOISETRACKER_20) {
                voice.volume = voice.param;
              }
              break;
            case 13:  // pattern break
              jumpFlag ^= 1;
              break;
            case 14:  // set filter
              amiga.filter = voice.param ^ 1;
              break;
            case 15:  // set speed
              if (voice.param < 1) {
                speed = 1;
              } else if (voice.param > 31) {
                speed = 31;
              } else {
                speed = voice.param;
              }
              break;
          }
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
                continue;
              }

              if (value == 1) {
                value = voice.param >> 4;
              } else {
                value = voice.param & 0x0f;
              }

              i = 0;
              while (PERIODS_3[i] > voice.period) i++;
              value += i;

              if (value < 37) {
                voice.channel.period = PERIODS_3[value];
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
            case 5:   // tone portamento + volume slide
              if (voice.effect == 5) {
                slide = 1;
              } else if (voice.param) {
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
            case 6:   // vibrato + volume slide
              if (voice.effect == 6) {
                slide = 1;
              } else if (voice.param) {
                voice.vibratoParam = voice.param;
              }

              value = (voice.vibratoPos >> 2) & 31;
              value = ((voice.vibratoParam & 0x0f) * VIBRATO[value]) >> vibratoDepth;

              if (voice.vibratoPos > 127) {
                chan.period = voice.period - value;
              } else {
                chan.period = voice.period + value;
              }

              value = (voice.vibratoParam >> 2) & 60;
              voice.vibratoPos = (voice.vibratoPos + value) & 255;
              break;
            case 10:  // volume slide
              slide = 1;
              break;
          }

          if (slide) {
            value = voice.param >> 4;

            if (value) {
              voice.volume += value;
            } else {
              voice.volume -= (voice.param & 0x0f);
            }

            if (voice.volume < 0) {
              voice.volume = 0;
            } else if (voice.volume > 64) {
              voice.volume = 64;
            }

            chan.volume = voice.volume;
            slide = 0;
          }
        } while (voice = voice.next);
      }

      if (++tick == speed) {
        tick = 0;
        patternPos += 4;

        if (patternPos == 256 || jumpFlag) {
          trackPos = (++trackPos & 127);

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

    private function protracker():void {
      var chan:AmigaChannel, i:int, pos:int, row:BaseRow, sample:BaseSample, value:int, voice:ATVoice = voices[0];

      if (!tick) {
        if (patternDelay) {
          standardFx();
        } else {
          pos = track[trackPos] + patternPos;

          do {
            chan = voice.channel;
            voice.enabled = 0;

            if (!voice.step) chan.period = voice.period;

            row = patterns[int(pos + voice.index)];
            voice.step   = row.step;
            voice.effect = row.effect;
            voice.param  = row.param;

            if (row.sample) {
              sample = voice.sample = samples[row.sample];

              voice.pointer  = sample.pointer;
              voice.length   = sample.length;
              voice.loopPtr  = sample.loopPtr;
              voice.funkWave = sample.loopPtr;
              voice.repeat   = sample.repeat;
              voice.finetune = sample.finetune;
              voice.volume   = sample.volume;

              chan.volume = sample.volume;
            } else {
              sample = voice.sample;
            }

            if (!row.note) {
              moreFx(voice);
              continue;
            } else {
              if ((voice.step & 0x0ff0) == 0x0e50) {
                voice.finetune = voice.param & 0x0f;
              } else if (voice.effect == 3 || voice.effect == 5) {
                if (row.note == voice.period) {
                  voice.portaPeriod = 0;
                } else {
                  i = voice.finetune * octaves;
                  value = i + octaves;

                  for (; i < value; ++i) {
                    if (row.note >= notes[i]) break;
                  }

                  if (i == value) value--;

                  if (i > 0) {
                    value = voice.finetune & 8;
                    if (value) i--;
                  }

                  voice.portaPeriod = notes[i];
                  voice.portaDir = (row.note > voice.period) ? 0 : 1;
                }

                moreFx(voice);
                continue;
              } else if (voice.effect == 9) {
                moreFx(voice);
              }
            }

            for (i = 0; i < octaves; ++i) {
              if (row.note >= notes[i]) break;
            }

            voice.period = notes[int((voice.finetune * octaves) + i)];

            if ((voice.step & 0x0ff0) == 0x0ed0) {
              if (voice.funkSpeed) updateFunk(voice);

              extendedFx(voice);
              continue;
            }

            if (voice.vibratoWave < 4) voice.vibratoPos = 0;
            if (voice.tremoloWave < 4) voice.tremoloPos = 0;

            chan.enabled = 0;
            chan.pointer = voice.pointer;
            chan.length  = voice.length;
            chan.period  = voice.period;

            voice.enabled = 1;
            moreFx(voice);
          } while (voice = voice.next);

          voice = voices[0];

          do {
            chan = voice.channel;

            if (voice.enabled) chan.enabled = 1;

            chan.pointer = voice.loopPtr;
            chan.length  = voice.repeat;
          } while (voice = voice.next);
        }
      } else {
        standardFx();
      }

      if (++tick == speed) {
        tick = 0;
        patternPos += m_channels;

        if (patternDelay) {
          if (--patternDelay) {
            patternPos -= m_channels;
          }
        }

        if (patternBreak) {
          patternBreak = 0;
          patternPos = breakPos;
          breakPos = 0;
        }

        if (patternPos == patternLen || jumpFlag) {
          trackPos = (++trackPos & 127);
          value = breakPos + 1;

          if (trackDone[trackPos] == value) {
            if (breakPos <= patternPos) {
              amiga.complete = 1;
            }
          } else {
            trackDone[trackPos] = value;
          }

          patternPos = breakPos;
          breakPos = 0;
          jumpFlag = 0;

          if (trackPos == length) {
            trackPos = 0;
            amiga.complete = 1;
          }
        }
      }

      m_position += amiga.samplesTick;
    }

    private function standardFx():void {
      var chan:AmigaChannel, i:int, pos:int, slide:int, value:int, voice:ATVoice = voices[0], wave:int;

      do {
        chan = voice.channel;
        if (voice.funkSpeed) updateFunk(voice);

        if (!(voice.step & 0x0fff)) {
          chan.period = voice.period;
          continue;
        }

        switch (voice.effect) {
          case 0:   // arpeggio
            value = tick % 3;

            if (!value) {
              chan.period = voice.period;
              continue;
            }

            if (value == 1) {
              value = voice.param >> 4;
            } else {
              value = voice.param & 0x0f;
            }

            i = voice.finetune * octaves;
            pos = i + octaves;

            for (; i < pos; ++i) {
              if (voice.period >= notes[i]) {
                chan.period = notes[int(i + value)];
                break;
              }
            }
            break;
          case 1:   // portamento up
            voice.period -= voice.param;

            if (voice.period < minPeriod) voice.period = minPeriod;

            chan.period = voice.period;
            break;
          case 2:   // portamento down
            voice.period += voice.param;

            if (voice.period > maxPeriod) voice.period = maxPeriod;

            chan.period = voice.period;
            break;
          case 3:   // tone portamento
          case 5:   // tone portamento + volume slide
            if (voice.effect == 5) {
              slide = 1;
            } else if (voice.param) {
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

            if (voice.glissando) {
              i = voice.finetune * octaves;
              pos = i + octaves;

              for (; i < pos; ++i) {
                if (voice.period >= notes[i]) break;
              }

              if (i == value) i--;
              chan.period = notes[i];
            } else {
              chan.period = voice.period;
            }
            break;
          case 4:   // vibrato
          case 6:   // vibrato + volume slide
            if (voice.effect == 6) {
              slide = 1;
            } else if (voice.param) {
              value = voice.param & 0x0f;

              if (value) {
                voice.vibratoParam = (voice.vibratoParam & 0xf0) | value;
              }

              value = voice.param & 0xf0;

              if (value) {
                voice.vibratoParam = (voice.vibratoParam & 0x0f) | value;
              }
            }

            pos = (voice.vibratoPos >> 2) & 31;
            wave = voice.vibratoWave & 3;

            if (wave) {
              value = 255;
              pos <<= 3;

              if (wave == 1) {
                if (voice.vibratoPos > 127) {
                  value -= pos;
                } else {
                  value = pos;
                }
              }
            } else {
              value = VIBRATO[pos];
            }

            value = ((voice.vibratoParam & 0x0f) * value) >> vibratoDepth;

            if (voice.vibratoPos > 127) {
              chan.period = voice.period - value;
            } else {
              chan.period = voice.period + value;
            }

            value = (voice.vibratoParam >> 2) & 60;
            voice.vibratoPos = (voice.vibratoPos + value) & 255;
            break;
          case 7:   // tremolo
            chan.period = voice.period;

            if (voice.param) {
              value = voice.param & 0x0f;

              if (value) {
                voice.tremoloParam = (voice.tremoloParam & 0xf0) | value;
              }

              value = voice.param & 0xf0;

              if (value) {
                voice.tremoloParam = (voice.tremoloParam & 0x0f) | value;
              }
            }

            pos = (voice.tremoloPos >> 2) & 31;
            wave = voice.tremoloWave & 3;

            if (wave) {
              value = 255;
              pos <<= 3;

              if (wave == 1) {
                if (voice.tremoloPos > 127) {
                  value -= pos;
                } else {
                  value = pos;
                }
              }
            } else {
              value = VIBRATO[pos];
            }

            value = ((voice.tremoloParam & 0x0f) * value) >> 6;

            if (voice.tremoloPos > 127) {
              chan.volume = voice.volume - value;
            } else {
              chan.volume = voice.volume + value;
            }

            value = (voice.tremoloParam >> 2) & 60;
            voice.tremoloPos = (voice.tremoloPos + value) & 255;
            break;
          case 8:   // set panning
            if (m_version == FASTTRACKER) {
              //chan.level = ((2 / 255) * voice.param) - 1;
              trace("Standard effect 8xx experimental.");
            }
            break;
          case 10:  // volume slide
            chan.period = voice.period;
            slide = 1;
            break;
          case 14:  // extended effects
            extendedFx(voice);
            break;
          default:
            chan.period = voice.period;
            break;
        }

        if (slide) {
          value = voice.param >> 4;

          if (value) {
            voice.volume += value;
          } else {
            voice.volume -= (voice.param & 0x0f);
          }

          if (voice.volume < 0) {
            voice.volume = 0;
          } else if (voice.volume > 64) {
            voice.volume = 64;
          }

          chan.volume = voice.volume;
          slide = 0;
        }
      } while (voice = voice.next);
    }

    private function moreFx(voice:ATVoice):void {
      var value:int;

      if (voice.funkSpeed) updateFunk(voice);

      switch (voice.effect) {
        case 9:   // sample offset
          if (voice.param) voice.offset = voice.param;
          value = voice.offset << 8;

          if (m_version > PROTRACKER_20) {
            if (value >= voice.sample.length) {
              voice.length = 4;
            } else {
              voice.pointer = voice.sample.pointer + value;
              voice.length  = voice.sample.length  - value;
            }
          } else {
            if (value >= voice.length) {
              voice.length = 4;
            } else {
              voice.pointer += value;
              voice.length  -= value;
            }
          }
          break;
        case 11:  // position jump
          trackPos = (voice.param - 1) & 127;
          breakPos = 0;
          jumpFlag = 1;
          break;
        case 12:  // set volume
          voice.volume = voice.param;

          if (voice.volume > 64) voice.volume = 64;

          voice.channel.volume = voice.volume;
          break;
        case 13:  // pattern break
          breakPos = ((voice.param >> 4) * 10) + (voice.param & 0x0f);

          if (breakPos > 63) {
            breakPos = 0;
          } else {
            breakPos <<= 2;
          }

          jumpFlag = 1;
          break;
        case 14:  // extended effects
          extendedFx(voice);
          break;
        case 15:  // set speed
          if (!voice.param) {
            amiga.complete = 2;
            return;
          }

          if (voice.param < 32) {
            speed = voice.param;
          } else {
            amiga.samplesTick = 110250 / voice.param;
          }
          break;
        default:
          voice.channel.period = voice.period;
          break;
      }
    }

    private function extendedFx(voice:ATVoice):void {
      var chan:AmigaChannel = voice.channel, effect:int, i:int, len:int, param:int;

      effect = voice.param >> 4;
      param  = voice.param & 0x0f;

      switch (effect) {
        case 0:   // set filter
          amiga.filter = param;
          break;
        case 1:   // fine portamento up
          if (tick) return;
          voice.period -= param;

          if (voice.period < minPeriod) voice.period = minPeriod;

          chan.period = voice.period;
          break;
        case 2:   // fine portamento down
          if (tick) return;
          voice.period += param;

          if (voice.period > maxPeriod) voice.period = maxPeriod;

          chan.period = voice.period;
          break;
        case 3:   // glissando control
          voice.glissando = param;
          break;
        case 4:   // vibrato control
          voice.vibratoWave = param;
          break;
        case 5:   // set finetune
          voice.finetune = param;
          break;
        case 6:   // pattern loop
          if (tick) return;

          if (param) {
            if (voice.loopCtr) {
              voice.loopCtr--;
            } else {
              voice.loopCtr = param;
            }

            if (voice.loopCtr) {
              breakPos = voice.loopPos;
              patternBreak = 1;
            }
          } else {
            voice.loopPos = patternPos;
          }
          break;
        case 7:   // tremolo control
          voice.tremoloWave = param;
          break;
        case 8:   // karplus strong, PT20 only
          if (m_version == PROTRACKER_20) {
            len = voice.length - 2;

            for (i = voice.loopPtr; i < len;) {
              amiga.memory[i] = (amiga.memory[i] + amiga.memory[++i]) >> 1;
            }

            amiga.memory[++i] = (amiga.memory[i] + amiga.memory[0]) >> 1;
          } else if (m_version == FASTTRACKER) {
            //if (tick) return;

            //chan.level = ((2 / 16) * param) - 1;
            trace("Extended effect E8x experimental.");
          }
          break;
        case 9:   // retrig note
          if (tick || !param || !voice.period) return;
          if (tick % param) return;

          chan.enabled = 0;
          chan.delay   = 30;
          chan.pointer = voice.pointer;
          chan.length  = voice.length;

          chan.enabled = 1;
          chan.pointer = voice.loopPtr;
          chan.length  = voice.repeat;
          chan.period  = voice.period;
          break;
        case 10:  // fine volume up
          if (tick) return;
          voice.volume += param;

          if (voice.volume > 64) voice.volume = 64;

          chan.volume = voice.volume;
          break;
        case 11:  // fine volume down
          if (tick) return;
          voice.volume -= param;

          if (voice.volume < 0) voice.volume = 0;

          chan.volume = voice.volume;
          break;
        case 12:  // note cut
          if (tick == param) {
            chan.volume = voice.volume = 0;
          }
          break;
        case 13:  // note delay
          if (tick != param || !voice.period) return;

          chan.enabled = 0;
          chan.delay   = 30;
          chan.pointer = voice.pointer;
          chan.length  = voice.length;

          chan.enabled = 1;
          chan.pointer = voice.loopPtr;
          chan.length  = voice.repeat;
          chan.period  = voice.period;
          break;
        case 14:  // pattern delay
          if (tick || patternDelay) return;
          patternDelay = param + 1;
          break
        case 15:  // funk repeat or invert loop
          if (tick) return;
          voice.funkSpeed = param;

          if (param) updateFunk(voice);
          break;
      }
    }

    private function arpeggio(voice:ATVoice):void {
      var i:int, param:int;

      switch (tick) {
        case 1:
        case 4:
          param = voice.param >> 4;
          break;
        case 2:
        case 5:
          param = voice.param & 0x0f;
          break;
        case 3:
          voice.channel.period = voice.last;
          break;
        default:
          return;
      }

      while (PERIODS_3[i] > voice.last) i++;
      param += i;

      if (param < 37) {
        voice.channel.period = PERIODS_3[param];
      }
    }

    private function updateFunk(voice:ATVoice):void {
      var p1:int, p2:int, value:int;

      if ((voice.funkPos += value) < 128) {
        return;
      }

      voice.funkPos = 0;
      value = FUNKREP[voice.funkSpeed];

      if (m_version == PROTRACKER_10) {
        p1 = voice.pointer + (voice.sample.length - voice.repeat);
        p2 = voice.funkWave + voice.repeat;

        if (p2 > p1) {
          p2 = voice.loopPtr;
          voice.channel.length = voice.repeat;
        }

        voice.channel.pointer = voice.funkWave = p2;
      } else {
        p1 = voice.loopPtr + voice.repeat;
        p2 = voice.funkWave + 1;

        if (p2 >= p1) p2 = voice.loopPtr;

        amiga.memory[p2] = -amiga.memory[p2];
      }
    }

    private function isLegal(text:String):int {
      var code:int, i:int, length:int = text.length;

      if (!length) return 0;

      for (i = 0; i < length; ++i) {
        code = text.charCodeAt(i);

        if (code && (code < 32 || code > 127)) return 0;
      }

      return 1;
    }

    public static const
      ULTIMATE_SOUNDTRACKER : int = 1,
      TJC_SOUNDTRACKER_2    : int = 2,
      DOC_SOUNDTRACKER_4    : int = 3,
      MASTER_SOUNDTRACKER   : int = 4,
      DOC_SOUNDTRACKER_9    : int = 5,
      DOC_SOUNDTRACKER_20   : int = 6,
      SOUNDTRACKER_23       : int = 7,
      NOISETRACKER_10       : int = 8,
      NOISETRACKER_11       : int = 9,
      PROTRACKER_10         : int = 10,
      NOISETRACKER_20       : int = 11,
      STARTREKKER           : int = 12,
      PROTRACKER_10C        : int = 13,
      PROTRACKER_20         : int = 14,
      PROTRACKER_30         : int = 15,
      FASTTRACKER           : int = 16;

    private const
      PERIODS_3 : Vector.<int> = Vector.<int>([
        856,808,762,720,678,640,604,570,538,508,480,453,
        428,404,381,360,339,320,302,285,269,254,240,226,
        214,202,190,180,170,160,151,143,135,127,120,113,0,
        850,802,757,715,674,637,601,567,535,505,477,450,
        425,401,379,357,337,318,300,284,268,253,239,225,
        213,201,189,179,169,159,150,142,134,126,119,113,0,
        844,796,752,709,670,632,597,563,532,502,474,447,
        422,398,376,355,335,316,298,282,266,251,237,224,
        211,199,188,177,167,158,149,141,133,125,118,112,0,
        838,791,746,704,665,628,592,559,528,498,470,444,
        419,395,373,352,332,314,296,280,264,249,235,222,
        209,198,187,176,166,157,148,140,132,125,118,111,0,
        832,785,741,699,660,623,588,555,524,495,467,441,
        416,392,370,350,330,312,294,278,262,247,233,220,
        208,196,185,175,165,156,147,139,131,124,117,110,0,
        826,779,736,694,655,619,584,551,520,491,463,437,
        413,390,368,347,328,309,292,276,260,245,232,219,
        206,195,184,174,164,155,146,138,130,123,116,109,0,
        820,774,730,689,651,614,580,547,516,487,460,434,
        410,387,365,345,325,307,290,274,258,244,230,217,
        205,193,183,172,163,154,145,137,129,122,115,109,0,
        814,768,725,684,646,610,575,543,513,484,457,431,
        407,384,363,342,323,305,288,272,256,242,228,216,
        204,192,181,171,161,152,144,136,128,121,114,108,0,
        907,856,808,762,720,678,640,604,570,538,508,480,
        453,428,404,381,360,339,320,302,285,269,254,240,
        226,214,202,190,180,170,160,151,143,135,127,120,0,
        900,850,802,757,715,675,636,601,567,535,505,477,
        450,425,401,379,357,337,318,300,284,268,253,238,
        225,212,200,189,179,169,159,150,142,134,126,119,0,
        894,844,796,752,709,670,632,597,563,532,502,474,
        447,422,398,376,355,335,316,298,282,266,251,237,
        223,211,199,188,177,167,158,149,141,133,125,118,0,
        887,838,791,746,704,665,628,592,559,528,498,470,
        444,419,395,373,352,332,314,296,280,264,249,235,
        222,209,198,187,176,166,157,148,140,132,125,118,0,
        881,832,785,741,699,660,623,588,555,524,494,467,
        441,416,392,370,350,330,312,294,278,262,247,233,
        220,208,196,185,175,165,156,147,139,131,123,117,0,
        875,826,779,736,694,655,619,584,551,520,491,463,
        437,413,390,368,347,328,309,292,276,260,245,232,
        219,206,195,184,174,164,155,146,138,130,123,116,0,
        868,820,774,730,689,651,614,580,547,516,487,460,
        434,410,387,365,345,325,307,290,274,258,244,230,
        217,205,193,183,172,163,154,145,137,129,122,115,0,
        862,814,768,725,684,646,610,575,543,513,484,457,
        431,407,384,363,342,323,305,288,272,256,242,228,
        216,203,192,181,171,161,152,144,136,128,121,114,0]),

      PERIODS_5 : Vector.<int> = Vector.<int>([
        1712,1616,1524,1440,1356,1280,1208,1140,1076,1016, 960,906,
         856, 808, 762, 720, 678, 640, 604, 570, 538, 508, 480,453,
         428, 404, 381, 360, 339, 320, 302, 285, 269, 254, 240,226,
         214, 202, 190, 180, 170, 160, 151, 143, 135, 127, 120,113,
         107, 101,  95,  90,  85,  80,  75,  71,  67,  63,  60, 56,0,
        1700,1604,1514,1430,1348,1274,1202,1134,1070,1010, 954,900,
         850, 802, 757, 715, 674, 637, 601, 567, 535, 505, 477,450,
         425, 401, 379, 357, 337, 318, 300, 284, 268, 253, 239,225,
         213, 201, 189, 179, 169, 159, 150, 142, 134, 126, 119,113,
         106, 100,  94,  89,  84,  79,  75,  71,  67,  63,  59, 56,0,
        1688,1592,1504,1418,1340,1264,1194,1126,1064,1004, 948,894,
         844, 796, 752, 709, 670, 632, 597, 563, 532, 502, 474,447,
         422, 398, 376, 355, 335, 316, 298, 282, 266, 251, 237,224,
         211, 199, 188, 177, 167, 158, 149, 141, 133, 125, 118,112,
         105,  99,  94,  88,  83,  79,  74,  70,  66,  62,  59, 56,0,
        1676,1582,1492,1408,1330,1256,1184,1118,1056, 996, 940,888,
         838, 791, 746, 704, 665, 628, 592, 559, 528, 498, 470,444,
         419, 395, 373, 352, 332, 314, 296, 280, 264, 249, 235,222,
         209, 198, 187, 176, 166, 157, 148, 140, 132, 125, 118,111,
         104,  99,  93,  88,  83,  78,  74,  70,  66,  62,  59, 55,0,
        1664,1570,1482,1398,1320,1246,1176,1110,1048, 990, 934,882,
         832, 785, 741, 699, 660, 623, 588, 555, 524, 495, 467,441,
         416, 392, 370, 350, 330, 312, 294, 278, 262, 247, 233,220,
         208, 196, 185, 175, 165, 156, 147, 139, 131, 124, 117,110,
         104,  98,  92,  87,  82,  78,  73,  69,  65,  62,  58, 55,0,
        1652,1558,1472,1388,1310,1238,1168,1102,1040, 982, 926,874,
         826, 779, 736, 694, 655, 619, 584, 551, 520, 491, 463,437,
         413, 390, 368, 347, 328, 309, 292, 276, 260, 245, 232,219,
         206, 195, 184, 174, 164, 155, 146, 138, 130, 123, 116,109,
         103,  97,  92,  87,  82,  77,  73,  69,  65,  61,  58, 54,0,
        1640,1548,1460,1378,1302,1228,1160,1094,1032, 974, 920,868,
         820, 774, 730, 689, 651, 614, 580, 547, 516, 487, 460,434,
         410, 387, 365, 345, 325, 307, 290, 274, 258, 244, 230,217,
         205, 193, 183, 172, 163, 154, 145, 137, 129, 122, 115,109,
         102,  96,  91,  86,  81,  77,  72,  68,  64,  61,  57, 54,0,
        1628,1536,1450,1368,1292,1220,1150,1086,1026, 968, 914,862,
         814, 768, 725, 684, 646, 610, 575, 543, 513, 484, 457,431,
         407, 384, 363, 342, 323, 305, 288, 272, 256, 242, 228,216,
         204, 192, 181, 171, 161, 152, 144, 136, 128, 121, 114,108,
         102,  96,  90,  85,  80,  76,  72,  68,  64,  60,  57, 54,0,
        1814,1712,1616,1524,1440,1356,1280,1208,1140,1076,1016,960,
         907, 856, 808, 762, 720, 678, 640, 604, 570, 538, 508,480,
         453, 428, 404, 381, 360, 339, 320, 302, 285, 269, 254,240,
         226, 214, 202, 190, 180, 170, 160, 151, 143, 135, 127,120,
         113, 107, 101,  95,  90,  85,  80,  75,  71,  67,  63, 60,0,
        1800,1700,1604,1514,1430,1350,1272,1202,1134,1070,1010,954,
         900, 850, 802, 757, 715, 675, 636, 601, 567, 535, 505,477,
         450, 425, 401, 379, 357, 337, 318, 300, 284, 268, 253,238,
         225, 212, 200, 189, 179, 169, 159, 150, 142, 134, 126,119,
         112, 106, 100,  94,  89,  84,  79,  75,  71,  67,  63, 59,0,
        1788,1688,1592,1504,1418,1340,1264,1194,1126,1064,1004,948,
         894, 844, 796, 752, 709, 670, 632, 597, 563, 532, 502,474,
         447, 422, 398, 376, 355, 335, 316, 298, 282, 266, 251,237,
         223, 211, 199, 188, 177, 167, 158, 149, 141, 133, 125,118,
         111, 105,  99,  94,  88,  83,  79,  74,  70,  66,  62, 59,0,
        1774,1676,1582,1492,1408,1330,1256,1184,1118,1056, 996,940,
         887, 838, 791, 746, 704, 665, 628, 592, 559, 528, 498,470,
         444, 419, 395, 373, 352, 332, 314, 296, 280, 264, 249,235,
         222, 209, 198, 187, 176, 166, 157, 148, 140, 132, 125,118,
         111, 104,  99,  93,  88,  83,  78,  74,  70,  66,  62, 59,0,
        1762,1664,1570,1482,1398,1320,1246,1176,1110,1048, 988,934,
         881, 832, 785, 741, 699, 660, 623, 588, 555, 524, 494,467,
         441, 416, 392, 370, 350, 330, 312, 294, 278, 262, 247,233,
         220, 208, 196, 185, 175, 165, 156, 147, 139, 131, 123,117,
         110, 104,  98,  92,  87,  82,  78,  73,  69,  65,  61, 58,0,
        1750,1652,1558,1472,1388,1310,1238,1168,1102,1040, 982,926,
         875, 826, 779, 736, 694, 655, 619, 584, 551, 520, 491,463,
         437, 413, 390, 368, 347, 328, 309, 292, 276, 260, 245,232,
         219, 206, 195, 184, 174, 164, 155, 146, 138, 130, 123,116,
         109, 103,  97,  92,  87,  82,  77,  73,  69,  65,  61, 58,0,
        1736,1640,1548,1460,1378,1302,1228,1160,1094,1032, 974,920,
         868, 820, 774, 730, 689, 651, 614, 580, 547, 516, 487,460,
         434, 410, 387, 365, 345, 325, 307, 290, 274, 258, 244,230,
         217, 205, 193, 183, 172, 163, 154, 145, 137, 129, 122,115,
         108, 102,  96,  91,  86,  81,  77,  72,  68,  64,  61, 57,0,
        1724,1628,1536,1450,1368,1292,1220,1150,1086,1026, 968,914,
         862, 814, 768, 725, 684, 646, 610, 575, 543, 513, 484,457,
         431, 407, 384, 363, 342, 323, 305, 288, 272, 256, 242,228,
         216, 203, 192, 181, 171, 161, 152, 144, 136, 128, 121,114,
         108, 101,  96,  90,  85,  80,  76,  72,  68,  64,  60, 57,0]),

      VIBRATO : Vector.<int> = Vector.<int>([
          0, 24, 49, 74, 97,120,141,161,180,197,212,224,
        235,244,250,253,255,253,250,244,235,224,212,197,
        180,161,141,120, 97, 74, 49, 24]),

      FUNKREP : Vector.<int> = Vector.<int>([
        0,5,6,7,8,10,11,13,16,19,22,26,32,43,64,128]);
  }
}