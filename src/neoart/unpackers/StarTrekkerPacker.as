/*
  Flod Unpack 1.0
  2012/12/24
  Christian Corti
  Neoart Costa Rica

  Last Update: Flod Unpack 1.0 - 2012/12/24

  StarTrekker Packer by Mr. Spiv of Cave

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

  public final class StarTrekkerPacker extends Packer {

    override public function depack(stream:ByteArray):ByteArray {
      var b1:int, b2:int, b3:int, b4:int, i:int, j:int, length:int, patterns:int, sdata:int, size:int, skip:int, value:int, offsets:Vector.<int>, output:ByteArray = new ByteArray();

      if (!identify(stream)) return stream;

      stream.position = 0;
      output.writeBytes(stream, 0, 20);
      stream.position = 20;

      for (i = 0; i < 31; ++i) {
        output.length   += 22;
        output.position += 22;

        value = stream.readUnsignedShort();
        output.writeShort(value);
        size += (value << 1);

        output.writeByte(stream.readUnsignedByte());
        output.writeByte(stream.readUnsignedByte());
        output.writeShort(stream.readUnsignedShort());
        output.writeShort(stream.readUnsignedShort());
      }

      patterns = stream.readUnsignedShort() >> 2;
      output.writeByte(patterns);
      stream.position += 2;

      offsets = new Vector.<int>();

      for (i = 0; i < patterns; ++i) {
        value  = stream.readUnsignedInt();
        length = offsets.length;

        for (j = 0; j < length; ++j) {
          if (value == offsets[j]) {
            skip = 1;
            break;
          }
        }

        if (!skip) offsets.push(value);
          else skip = 0;
      }

      offsets.fixed = true;
      offsets.sort(16);

      stream.position = 272;
      output.length  += 128;

      for (i = 0; i < patterns; ++i) {
        value = stream.readUnsignedInt();

        for (j = 0; j < patterns; ++j) {
          if (value == offsets[j]) break;
        }

        output.writeByte(j);
      }

      stream.position = 270;
      value = stream.readUnsignedShort() >> 2;
      output[951] = value;

      output.position = 1080;
      output.writeUTFBytes((value == 0x7f) ? MAGIC : "FLT4");

      stream.position = 784;
      sdata  = stream.readUnsignedInt() + stream.position;
      length = (offsets.length << 8);

      for (i = 0; i < length; ++i) {
        value = stream.readUnsignedByte();

        if (value != 0x80) {
          b2 = stream.readUnsignedByte();
          b3 = stream.readUnsignedByte();
          b4 = stream.readUnsignedByte();

          b1 = ((value & 0xf0) | ((b3 >> 4) & 0x0f)) >> 2;

          output.writeByte((b1 & 0xf0) | (value & 0x0f));
          output.writeByte(b2);
          output.writeByte(((b1 << 4) & 0xf0) | (b3 & 0x0f));
          output.writeByte(b4);
        } else {
          output.writeInt(0);
        }
      }

      output.writeBytes(stream, sdata, size);

      stream.clear();
      output.endian = ORDER;
      return output;
    }

    override public function identify(stream:ByteArray):int {
      var b1:int, b2:int, b3:int, i:int, length:int, size:int, total:int, value:int;

      format = "";
      if (stream.length < 1046) return 0;
      stream.position = 20;

      for (i = 0; i < 31; ++i) {
        size = stream.readUnsignedShort();
        total += (size << 1);

        stream.position++;
        if (stream.readUnsignedByte() > 0x40) return 0;

        b1 = stream.readUnsignedShort();
        b2 = stream.readUnsignedShort();
        if (!b1 && (b2 == 0)) return 0;

        if (size && ((b1 + b2) > size)) return 0;
      }

      if ((stream.readUnsignedShort() >> 2) > 0x7f) return 0;
      stream.position += 2;

      for (i = 0; i < 128; ++i) {
        value = stream.readUnsignedInt();
        if ((788 + value + size) > stream.length) return 0;
      }

      length = stream.readUnsignedInt();
      if ((stream.position + length + size) > stream.length) return 0;
      length >>= 2;

      for (i = 0; i < length; ++i) {
        value = stream.readUnsignedByte();
        if (value == 0x80) continue;

        b2 = stream.readUnsignedByte();
        b3 = stream.readUnsignedByte();
        stream.position++;

        b1 = ((value & 0x0f) << 8) | b2;
        if (b1 > 856 || (b1 && b1 < 113)) return 0;

        b1 = ((value & 0xf0) | ((b3 >> 4) & 0x0f)) >> 2;
        if (b1 > 0x1f) return 0;
      }

      format = "StarTrekker Packer";
      return 1;
    }
  }
}