/*
  Flod Unpack 1.0
  2012/12/24
  Christian Corti
  Neoart Costa Rica

  Last Update: Flod Unpack 1.0 - 2012/12/24

  This work is partially based on original findings by Nicolas Franck (Pro-Wizard by Gryzor), Sylvain Chipaux (Asle) and Claudio Matsuoka.

  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
  OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
  LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR
  IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

  This work is licensed under the Creative Commons Attribution-Noncommercial-Share Alike 3.0 Unported License.
  To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-sa/3.0/ or send a letter to
  Creative Commons, 171 Second Street, Suite 300, San Francisco, California, 94105, USA.
*/
package neoart.unpackers {
  import flash.utils.*;

  public class Packer {
    public var
      format : String = "";

    public function depack(stream:ByteArray):ByteArray {
      return stream;
    }

    public function identify(stream:ByteArray):int {
      return 0;
    }

    protected static const
      MAGIC : String = "M.K.",
      ORDER : String = "bigEndian",

      NOTES : Vector.<Vector.<int>> = Vector.<Vector.<int>>([
        Vector.<int>([0x00,0x00]),
        Vector.<int>([0x03,0x58]),
        Vector.<int>([0x03,0x28]),
        Vector.<int>([0x02,0xfa]),
        Vector.<int>([0x02,0xd0]),
        Vector.<int>([0x02,0xa6]),
        Vector.<int>([0x02,0x80]),
        Vector.<int>([0x02,0x5c]),
        Vector.<int>([0x02,0x3a]),
        Vector.<int>([0x02,0x1a]),
        Vector.<int>([0x01,0xfc]),
        Vector.<int>([0x01,0xe0]),
        Vector.<int>([0x01,0xc5]),
        Vector.<int>([0x01,0xac]),
        Vector.<int>([0x01,0x94]),
        Vector.<int>([0x01,0x7d]),
        Vector.<int>([0x01,0x68]),
        Vector.<int>([0x01,0x53]),
        Vector.<int>([0x01,0x40]),
        Vector.<int>([0x01,0x2e]),
        Vector.<int>([0x01,0x1d]),
        Vector.<int>([0x01,0x0d]),
        Vector.<int>([0x00,0xfe]),
        Vector.<int>([0x00,0xf0]),
        Vector.<int>([0x00,0xe2]),
        Vector.<int>([0x00,0xd6]),
        Vector.<int>([0x00,0xca]),
        Vector.<int>([0x00,0xbe]),
        Vector.<int>([0x00,0xb4]),
        Vector.<int>([0x00,0xaa]),
        Vector.<int>([0x00,0xa0]),
        Vector.<int>([0x00,0x97]),
        Vector.<int>([0x00,0x8f]),
        Vector.<int>([0x00,0x87]),
        Vector.<int>([0x00,0x7f]),
        Vector.<int>([0x00,0x78]),
        Vector.<int>([0x00,0x71])
      ]);
  }
}