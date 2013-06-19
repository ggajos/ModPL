/*
  Flod Unpack 1.0
  2012/12/24
  Christian Corti
  Neoart Costa Rica

  Last Update: Flod Unpack 1.0 - 2012/12/24

  ProRunner 1.0 by Cosmos of Sanity

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

  public final class ProRunner1 extends Packer {

    override public function depack(stream:ByteArray):ByteArray {
      var b1:int, b2:int, b3:int, b4:int, higher:int, i:int, size:int, output:ByteArray = new ByteArray();

      if (!identify(stream)) return stream;

      stream.position = 0;
      output.writeBytes(stream, 0, 1080);
      stream.position = 42;

      for (i = 0; i < 31; ++i) {
        size += stream.readUnsignedShort() << 1;
        stream.position += 28;
      }

      output.writeUTFBytes(MAGIC);
      stream.position = 952;

      for (i = 0; i < 128; ++i) {
        b1 = stream.readUnsignedByte();
        if (b1 > higher) higher = b1;
      }

      stream.position += 4;
      higher = (++higher) << 8;

      for (i = 0; i < higher; ++i) {
        b1 = stream.readUnsignedByte();
        b2 = stream.readUnsignedByte();
        b3 = stream.readUnsignedByte();

        b4 = (b1 & 0xf0) | NOTES[b2][0];
        b3 = ((b1 & 0x0f) << 4) | b3;
        b2 = NOTES[b2][1];

        output.writeByte(b4);
        output.writeByte(b2);
        output.writeByte(b3);
        output.writeByte(stream.readUnsignedByte());
      }

      output.writeBytes(stream, stream.position, size);

      stream.clear();
      output.endian = ORDER;
      return output;
    }

    override public function identify(stream:ByteArray):int {
      format = "";
      if (stream.length < 1084) return 0;

      stream.position = 1084;
      if (stream.readUTFBytes(4) != "SNT.") return 0;

      stream.position = 950;
      if (stream.readUnsignedByte() > 0x7f) return 0;

      format = "ProRunner 1";
      return 1;
    }
  }
}