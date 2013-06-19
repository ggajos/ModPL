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
package neoart.flod.core {
  import flash.events.*;
  import flash.utils.*;

  public final class Amiga extends CoreMixer {
    public var
      channels : Vector.<AmigaChannel>,
      loopPtr  : int,
      loopLen  : int,
      memory   : Vector.<int>;
    internal var
      m_filter : AmigaFilter,
      clock    : Number,
      master   : Number;

    public function Amiga() {
      super();
      m_filter = new AmigaFilter();
      m_filter.model = MODEL_A1200;
    }

    public function get model():int { return m_filter.model; }

    public function set model(value:int):void {
      if (value < MODEL_A500) {
        value = MODEL_A500;
      } else if (value > MODEL_A1200) {
        value = MODEL_A1200;
      }

      m_filter.model = value;
    }

    public function set filter(value:int):void {
      m_filter.state = (player.filterMode & ((value & 1) + 1));
    }

    public function get volume():Number { return master; }

    public function set volume(value:Number):void {
      if (value) {
        if (value > 64) value = 64;

        master = (value / 64) * (0.015625 / channels.length);
      } else {
        master = 0.0;
      }
    }

    public function write(stream:ByteArray, size:int, pointer:int = -1):int {
      var add:int, i:int, pos:int = stream.position, start:int = memory.length, total:int;

      if (pointer > -1) stream.position = pointer;
      total = stream.position + size;

      if (total >= stream.length) {
        add = total - stream.length;
        size = stream.length - stream.position;
      }

      for (i = start, size += start; i < size; ++i) {
        memory[i] = stream.readByte();
      }

      memory.length += add;
      if (pointer > -1) stream.position = pos;
      return start;
    }

    override internal function setup():void {
      var i:int, len:int = player.channels;

      loopPtr = memory.length;
      memory.length += loopLen;
      memory.fixed = true;

      if (!channels || len != channels.length) {
        channels = new Vector.<AmigaChannel>(len, true);
        channels[0] = new AmigaChannel(0);

        for (i = 1; i < len; ++i) {
          channels[i] = channels[int(i - 1)].next = new AmigaChannel(i);
        }
      }
    }

    override internal function initialize():void {
      var chan:AmigaChannel = channels[0];
      super.initialize();

      m_filter.initialize();
      m_filter.state = 0;
      wave.clear();

      master = (player.volume / channels.length) * 0.015625;

      do {
        chan.initialize();
      } while (chan = chan.next);
    }

    override internal function reset():void {
      loopPtr = 0;
      loopLen = 4;
      memory = new Vector.<int>();
    }

    override internal function fast(e:SampleDataEvent):void {
      var chan:AmigaChannel, data:ByteArray = e.data, i:int, lvol:Number, mixed:int, mixLen:int, mixPos:int, rvol:Number, sample:Sample, size:int = buffer.length, speed:Number, toMix:int, value:Number;

      if (m_complete) {
        if (!remains) return;
        size = remains;
      }

      do {
        if (!samplesLeft) {
          process();
          samplesLeft = samplesTick;

          if (m_complete) {
            size = mixed + samplesTick;

            if (size > buffer.length) {
              remains = size - buffer.length;
              size = buffer.length;
            }
          }
        }

        toMix = samplesLeft;
        if ((mixed + toMix) >= size) toMix = size - mixed;
        mixLen = mixPos + toMix;

        chan = channels[0];

        do {
          sample = buffer[mixPos];

          if (chan.audena && chan.audper) {
            speed = chan.audper / clock;

            if (chan.mute) {
              chan.audatl = 0.0;
              chan.audatr = 0.0;
            } else {
              value = chan.audvol * master;
              lvol = value * (1 - chan.level);
              rvol = value * (1 + chan.level);
            }

            for (i = mixPos; i < mixLen; ++i) {
              if (chan.delay) {
                chan.delay--;
              } else if (--chan.timer < 1.0) {
                if (!chan.mute) {
                  value = memory[chan.audloc] * 0.0078125;
                  chan.audatl = value * lvol;
                  chan.audatr = value * rvol;
                }

                chan.audloc++;
                chan.timer += speed;

                if (chan.timer < 0) {
                  chan.timer = speed;
                  chan.audloc++;
                }

                if (chan.audloc >= chan.audlen) {
                  chan.audloc = chan.pointer;
                  chan.audlen = chan.pointer + chan.length;
                }
              }

              sample.l += chan.audatl;
              sample.r += chan.audatr;
              sample = sample.next;
            }
          } else {
            for (i = mixPos; i < mixLen; ++i) {
              sample.l += chan.audatl;
              sample.r += chan.audatr;
              sample = sample.next;
            }
          }
        } while (chan = chan.next);

        mixPos = mixLen;
        mixed += toMix;
        samplesLeft -= toMix;
      } while (mixed < size);

      sample = buffer[0];

      if (player.record) {
        for (i = 0; i < size; ++i) {
          m_filter.process(sample);
          data.writeFloat(sample.l);
          data.writeFloat(sample.r);

          wave.writeShort(sample.l * 32768);
          wave.writeShort(sample.r * 32768);

          sample.l = 0.0;
          sample.r = 0.0;
          sample = sample.next;
        }
      } else {
        for (i = 0; i < size; ++i) {
          m_filter.process(sample);
          data.writeFloat(sample.l);
          data.writeFloat(sample.r);

          sample.l = 0.0;
          sample.r = 0.0;
          sample = sample.next;
        }
      }
    }

    public static const
      MODEL_A500  : int = 0,
      MODEL_A1200 : int = 1;
  }
}