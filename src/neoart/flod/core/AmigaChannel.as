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

  public final class AmigaChannel {
    public var
      next    : AmigaChannel,
      master  : Number = 1.0,
      mute    : int,
      panning : Number = 1.0,
      delay   : int,
      pointer : int,
      length  : int;
    internal var
      timer  : Number,
      level  : Number,
      audena : int,
      audloc : int,
      audlen : int,
      audper : int,
      audvol : int,
      audatl : Number,
      audatr : Number;

    public function AmigaChannel(index:int) {
      if ((++index & 2) == 0) panning = -panning;
      level = panning;
    }

    public function set enabled(value:int):void {
      if (value == audena) return;

      audena = value;
      audloc = pointer;
      audlen = pointer + length;

      timer = 1.0;
      if (value) delay += 2;
    }

    public function set period(value:int):void {
      if (value < 0 || value > 65535) value = 0;

      audper = value;
    }

    public function set volume(value:int):void {
      if (value < 0) {
        value = 0;
      } else if (value > 64) {
        value = 64;
      }

      audvol = int(value * master);
    }

    public function reset():void {
      audatl = 0.0;
      audatr = 0.0;
    }

    internal function initialize():void {
      delay   = 0;
      pointer = 0;
      length  = 0;
      timer   = 0.0;

      audena = 0;
      audloc = 0;
      audlen = 0;
      audper = 0;
      audvol = 0;
      audatl = 0.0;
      audatr = 0.0;
    }
  }
}