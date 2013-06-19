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

  public class SBPlayer extends CorePlayer {
    public var
      blaster : SoundBlaster,
      track   : Vector.<int>,
      length  : int,
      restart : int;
    protected var
      master  : int,
      timer   : int;

    public function SBPlayer(mixer:SoundBlaster = null) {
      blaster = mixer || new SoundBlaster();
      super(blaster);

      endian  = "littleEndian";
      quality = true;
    }

    override public function set volume(value:Number):void {
      if (value < 0.0) {
        value = 0.0;
      } else if (value > 1.0) {
        value = 1.0;
      }

      master = value * 64;
    }

    override public function mute(index:int = -1):void {
      var i:int;

      if (index >= 0 && index < m_channels) {
        blaster.channels[index].mute ^= 1;
        flags ^= (1 << index);
      } else {
        m_mute ^= 1;

        for (i = 0; i < m_channels; ++i) {
          blaster.channels[i].mute = m_mute | (flags & (1 << i));
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
        blaster.process();
      } while (position > m_position);

      play();
      return m_position;
    }

    override protected function calc():void {
      var store:Boolean = loop;
      initialize();

      do {
        blaster.process();
      } while (!blaster.complete);

      m_duration = m_position / 44.1;
      m_position = 0;
      loop = store;
    }

    override protected function initialize():void {
      super.initialize();
      master = 64;
      timer  = speed;
      mixer.samplesTick = 110250 / tempo;
    }
  }
}