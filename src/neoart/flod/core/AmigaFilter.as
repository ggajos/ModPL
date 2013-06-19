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

  public final class AmigaFilter {
    internal var
      model : int,
      state : int;
    private var
      l0 : Number,
      l1 : Number,
      l2 : Number,
      l3 : Number,
      l4 : Number,
      r0 : Number,
      r1 : Number,
      r2 : Number,
      r3 : Number,
      r4 : Number;

    internal function initialize():void {
      l0 = l1 = l2 = l3 = l4 = 0.0;
      r0 = r1 = r2 = r3 = r4 = 0.0;
    }

    internal function process(sample:Sample):void {
      var d:Number;

      if (!model) {
        d = 1.0 - P0;
        l0 = P0 * sample.l + d * l0;
        r0 = P0 * sample.r + d * r0;

        d = 1.0 - P1;
        sample.l = l1 = P1 * l0 + d * l1;
        sample.r = r1 = P1 * r0 + d * r1;
      }

      if (state) {
        d = 1.0 - FL;
        l2 = FL * sample.l + d * l2;
        r2 = FL * sample.r + d * r2;
        l3 = FL * l2 + d * l3;
        r3 = FL * r2 + d * r3;

        sample.l = l4 = FL * l3 + d * l4;
        sample.r = r4 = FL * r3 + d * r4;
      }

      if (sample.l < -1.0) {
        sample.l = -1.0;
      } else if (sample.l > 1.0) {
        sample.l = 1.0;
      }

      if (sample.r < -1.0) {
        sample.r = -1.0;
      } else if (sample.r > 1.0) {
        sample.r = 1.0;
      }
    }

    private const
      FL : Number = 0.5213345843532200,
      P0 : Number = 0.4860348337215757,
      P1 : Number = 0.9314955486749749;
  }
}