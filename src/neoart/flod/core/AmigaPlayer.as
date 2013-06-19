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

  public class AmigaPlayer extends CorePlayer {
    public var
      amiga : Amiga;

    public function AmigaPlayer(amiga:Amiga = null) {
      this.amiga = amiga || new Amiga();
      super(this.amiga);

      m_channels = 4;
      ntsc = false;
      endian = "bigEndian";
    }

    override public function set filterMode(value:int):void {
      switch (value) {
        case 3:
          amiga.filter = 1;
          m_filter = 3;
          break;
        case 6:
          m_filter = 6;
          break;
        default:
          amiga.filter = 0;
          m_filter = 0;
          break;
      }
    }

    override public function set ntsc(value:Boolean):void {
      m_ntsc = value;

      if (value) {
        amiga.clock = 81.1688208;
        amiga.samplesTick = 735;
      } else {
        amiga.clock = 80.4284580;
        amiga.samplesTick = 882;
      }
    }

    override public function set stereoSeparation(value:Number):void {
      var chan:AmigaChannel = amiga.channels[0];

      if (value < 0.0) {
        value = 0.0
      } else if (value > 1.0) {
        value = 1.0;
      }

      do {
        chan.level = value * chan.panning;
      } while (chan = chan.next);
    }

    override public function set volume(value:Number):void {
      if (value < 0.0) {
        value = 0.0;
      } else if (value > 1.0) {
        value = 1.0;
      }

      amiga.master = (value / m_channels) * 0.015625;
    }

    override public function mute(index:int = -1):void {
      var i:int;

      if (index >= 0 && index < m_channels) {
        amiga.channels[index].mute ^= 1;
        flags ^= (1 << index);
      } else {
        m_mute ^= 1;

        for (i = 0; i < m_channels; ++i) {
          amiga.channels[i].mute = m_mute | (flags & (1 << i));
        }
      }
    }

    override public function seek(position:int):int {
      var current:int = m_position;

      stop();
      position *= 44100;

      if (position < current) {
        initialize();
      } else {
        m_position = current;
      }

      do {
        amiga.process();
      } while (position > m_position);

      play();
      return m_position;
    }

    override protected function calc():void {
      var store:Boolean = loop;
      initialize();

      do {
        amiga.process();
      } while (!amiga.complete);

      m_duration = m_position / 44.1;
      m_position = 0;
      loop = store;
    }

    public static const
      FORCE_OFF : int = 0,
      FORCE_ON  : int = 3,
      AUTOMATIC : int = 6;
  }
}