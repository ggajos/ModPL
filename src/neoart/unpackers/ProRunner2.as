/*
  Flod Unpack 1.0
  2012/12/24
  Christian Corti
  Neoart Costa Rica

  Last Update: Flod Unpack 1.0 - 2012/12/24

  ProRunner 2.0 by Cosmos of Sanity

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

  public final class ProRunner2 extends Packer {

    override public function depack(stream:ByteArray):ByteArray {
      var c0:int, c1:int, c2:int, c3:int, higher:int, i:int, j:int, row:ByteArray = new ByteArray(), sdata:int, size:int, value:int, output:ByteArray = new ByteArray();

      if (!identify(stream)) return stream;

      stream.position = 4;
      sdata = stream.readUnsignedInt();

      output.length   = 20;
      output.position = 20;

      for (i = 0; i < 31; ++i) {
        output.length   += 22;
        output.position += 22;

        value = stream.readUnsignedShort();
        size += (value << 1);
        output.writeShort(value);

        output.writeByte(stream.readUnsignedByte());
        output.writeByte(stream.readUnsignedByte());
        output.writeShort(stream.readUnsignedShort());
        output.writeShort(stream.readUnsignedShort());
      }

      output.writeShort(stream.readUnsignedShort());

      for (i = 0; i < 128; ++i) {
        value = stream.readUnsignedByte();
        if (value > higher) higher = value;
        output.writeByte(value);
      }

      output.writeUTFBytes(MAGIC);
      stream.position = 770;

      higher = (++higher) << 8;
      row.length = 16;

      for (i = 0; i < higher; ++i) {
        value = stream.readUnsignedByte();

        if (value == 0x80) {
          output.writeInt(0);
        } else if (value == 0xc0) {
          output.writeBytes(row, j, 4);
        } else {
          c1 = stream.readUnsignedByte();

          c3 = value >> 1;
          c0 = ((c1 & 0x80) >> 3) | NOTES[c3][0];
          c2 = ((c1 & 0x70) << 1) | ((value & 0x01) << 4) | (c1 & 0x0f);
          c1 = NOTES[c3][1];

          output.writeByte(c0);
          output.writeByte(c1);
          output.writeByte(c2);

          c3 = stream.readUnsignedByte();
          output.writeByte(c3);

          row[j] = c0;
          row[int(j + 1)] = c1;
          row[int(j + 2)] = c2;
          row[int(j + 3)] = c3;
        }

        j = (j + 4) & 15;
      }

      output.writeBytes(stream, sdata, size);

      stream.clear();
      output.endian = ORDER;
      return output;
    }

    override public function identify(stream:ByteArray):int {
      var i:int, size:int;

      format = "";
      if (stream.length < 770) return 0;

      stream.position = 0;
      if (stream.readUTFBytes(4) != "SNT!") return 0;

      size = stream.readUnsignedInt();
      if (size >= stream.length) return 0;

      stream.position = 256;
      if (stream.readUnsignedByte() > 0x7f) return 0;

      stream.position = 8;

      for (i = 0; i < 31; ++i) {
        size += (stream.readUnsignedShort() << 1);
        if (stream.readUnsignedByte() > 0x0f) return 0;
        if (stream.readUnsignedByte() > 0x40) return 0;

        stream.position += 2;
        if (stream.readUnsignedShort() == 0) return 0;
      }

      if (size == 0 || size > stream.length) return 0;

      format = "ProRunner 2";
      return 1;
    }
  }
}