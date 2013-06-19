/*
  Flod Unpack 1.0
  2012/12/24
  Christian Corti
  Neoart Costa Rica

  Last Update: Flod Unpack 1.0 - 2012/12/24

  PhaPacker by Azatoth of Phenomena

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

  public final class PhaPacker extends Packer {

    override public function depack(stream:ByteArray):ByteArray {
      var b1:int, b2:int, b3:int, b4:int, c:int, i:int, j:int, length:int, patterns:int, size:int, skip:int, value:int, counters:Vector.<int>, offsets:Vector.<int>, previous:Vector.<int>, output:ByteArray = new ByteArray();

      if (!identify(stream)) return stream;

      stream.position = 0;
      stream.length  += 1;

      output.length   = 20;
      output.position = 20;

      for (i = 0; i < 31; ++i) {
        output.length   += 22;
        output.position += 22;

        value = stream.readUnsignedShort();
        size += (value << 1);
        output.writeShort(value);

        stream.position += 10;
        output.writeByte(stream.readUnsignedShort() / 72);

        stream.position -= 11;
        output.writeByte(stream.readUnsignedByte());
        output.writeShort(stream.readUnsignedShort());
        output.writeShort(stream.readUnsignedShort());

        stream.position += 6;
      }

      stream.position = 436;
      patterns = stream.readUnsignedShort() >> 2;

      stream.position = 448;
      output.writeByte(patterns);
      output.writeByte(0x7f);
      offsets = new Vector.<int>();

      for (i = 0; i < 128; ++i) {
        value = stream.readUnsignedInt();
        length = offsets.length;

        for (j = 0; j < length; ++j) {
          if (value == offsets[j]) {
            skip = 1;
            break;
          }
        }

        if (skip) {
          skip = 0;
        } else {
          offsets[length] = value;
        }
      }

      offsets.fixed = true;
      offsets.sort(16);
      length = offsets.length;
      stream.position = 448;

      for (i = 0; i < 128; ++i) {
        value = stream.readUnsignedInt();

        for (j = 0; j < length; ++j) {
          if (value == offsets[j]) {
            output.writeByte(j);
          }
        }
      }

      output.writeUTFBytes(MAGIC);
      previous = new Vector.<int>(16, true);
      counters = new Vector.<int>( 4, true);

      for (i = 0; i < length; ++i) {
        stream.position = offsets[i];
        c = 0;

        for (j = 0; j < 256; ++j) {
          if (counters[c]) {
            counters[c]--;
            b1 = c << 2;

            output.writeByte(previous[b1++]);
            output.writeByte(previous[b1++]);
            output.writeByte(previous[b1++]);
            output.writeByte(previous[b1]);
          } else {
            value = stream.readUnsignedByte();

            b2 = stream.readUnsignedByte() >> 1;
            b1 = (value & 0xf0) | NOTES[b2][0];
            b2 = NOTES[b2][1];
            b3 = ((value << 4) & 0xf0) | stream.readUnsignedByte();
            b4 = stream.readUnsignedByte();

            output.writeByte(b1);
            output.writeByte(b2);
            output.writeByte(b3);
            output.writeByte(b4);

            value = c << 2;
            previous[value++] = b1;
            previous[value++] = b2;
            previous[value++] = b3;
            previous[value]   = b4;

            value = stream.readUnsignedByte();

            if (value == 0xff) {
              counters[c] = 255 - stream.readUnsignedByte();
            } else {
              stream.position--;
            }
          }
          c = (++c) & 3;
        }
      }

      output.writeBytes(stream, 960, size);

      stream.clear();
      output.endian = ORDER;
      return output;
    }

    override public function identify(stream:ByteArray):int {
      var b1:int, b2:int, i:int, length:int, lower:int, size:int, value:int;

      format = "";
      if (stream.length < 964) return 0;
      stream.position = 0;

      for (i = 0; i < 31; ++i) {
        value = stream.readUnsignedShort();
        size += (value << 1);

        stream.position++;
        if (stream.readUnsignedByte() > 0x40) return 0;

        if ((stream.readUnsignedShort() + stream.readUnsignedShort()) > ++value) return 0;
        if ((stream.readUnsignedInt() + value) > stream.length) return 0;
        stream.position += 2;
      }

      size += 960;
      if (size > stream.length) return 0;

      stream.position += 2;
      length = stream.readUnsignedShort() >> 2;
      if (length > 0x7f) return 0;

      stream.position += 10;
      size -= 2;
      lower = 0xffffffffff;

      for (i = 0; i < length; ++i) {
        value = stream.readUnsignedInt();
        if (value < size || value > stream.length) return 0;
        if (value < lower) lower = value;
      }

      stream.position = lower;

      while (stream.bytesAvailable) {
        b1 = stream.readUnsignedByte();

        if (b1 == 0xff) {
          stream.position++;
          continue;
        }

        if (b1 > 0x1f) return 0;
        if (stream.readUnsignedByte() > 0x92) return 0;
        stream.position += 2;
      }

      format = "PhaPacker";
      return 1;
    }
  }
}