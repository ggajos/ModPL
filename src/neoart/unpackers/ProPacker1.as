/*
  Flod Unpack 1.0
  2012/12/24
  Christian Corti
  Neoart Costa Rica

  Last Update: Flod Unpack 1.0 - 2012/12/24

  ProPacker 1.0 by Estrup of Static Bytes

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

  public final class ProPacker1 extends Packer {

    override public function depack(stream:ByteArray):ByteArray {
      var b1:int, b2:int, b3:int, b4:int, c:int, higher:int, i:int, j:int, length:int, patterns:int, size:int, skip:int, offsets:Vector.<int>, output:ByteArray = new ByteArray();

      if (!identify(stream)) return stream;

      stream.position = 0;
      output.length   = 20;
      output.position = 20;

      for (i = 0; i < 31; ++i) {
        output.length   += 22;
        output.position += 22;

        j = stream.readUnsignedShort();
        size += (j << 1);
        output.writeShort(j);

        output.writeByte(stream.readUnsignedByte());
        output.writeByte(stream.readUnsignedByte());
        output.writeShort(stream.readUnsignedShort());
        output.writeShort(stream.readUnsignedShort());
      }

      patterns = stream.readUnsignedByte();
      output.writeByte(patterns);
      output.writeByte(stream.readUnsignedByte());
      output.length += 128;

      offsets = new Vector.<int>();
      c = stream.position;

      for (i = 0; i < patterns; ++i) {
        b1 = stream[c++];
        b2 = stream[int(c + 127)];
        b3 = stream[int(c + 255)];
        b4 = stream[int(c + 383)];

        length = offsets.length;

        for (j = 0; j < length;) {
          if (b1 == offsets[j++] &&
              b2 == offsets[j++] &&
              b3 == offsets[j++] &&
              b4 == offsets[j++]) {
            skip = 1;
            break;
          }
        }

        if (skip) {
          skip = 0;
          output.writeByte((j - 4) >> 2);
        } else {
          offsets[length]   = b1;
          offsets[++length] = b2;
          offsets[++length] = b3;
          offsets[++length] = b4;
          output.writeByte(higher++);
        }
      }

      output.position = 1080;
      output.writeUTFBytes(MAGIC);
      output.length += (higher << 10);

      offsets.fixed = true;
      skip = 0;

      for (i = 0; i < higher; ++i) {
        for (c = 0; c < 4; ++c) {
          output.position = 1084 + (i << 10) + (c << 2);

          b1 = offsets[int(c + (i << 2))];
          if (b1 > skip) skip = b1;
          stream.position = 762 + (b1 << 8);

          for (j = 0; j < 64; ++j) {
            output.writeInt(stream.readUnsignedInt());
            output.position += 12;
          }
        }
      }

      output.position -= 12;
      stream.position = 762 + (++skip << 8);
      output.writeBytes(stream, stream.position, size);

      stream.clear();
      output.endian = ORDER;
      return output;
    }

    override public function identify(stream:ByteArray):int {
      var higher:int, i:int, loop:int, repeat:int, size:int, total:int, value:int;

      format = "";
      if (stream.length < 1020) return 0;
      stream.position = 0;

      for (i = 0; i < 31; ++i) {
        size = stream.readUnsignedShort();
        total += (size << 1);

        if (stream.readUnsignedByte() > 0x0f) return 0;
        if (stream.readUnsignedByte() > 0x40) return 0;

        loop = stream.readUnsignedShort();
        repeat = stream.readUnsignedShort();
        if (!size) size = 2;

        if (repeat == 0              ||
           (loop != 0 && repeat < 1) ||
            loop >= size             ||
           (loop + repeat) > size) return 0;
      }

      if (total < 2) return 0;
      value = stream.readUnsignedByte();

      if (value == 0 || value > 0x7f || stream.readUnsignedByte() > 0x7f) return 0;

      for (i = 0; i < 512; ++i) {
        value = stream.readUnsignedByte();
        if (value > higher) higher = value;
      }

      value = 762 + ((++higher) << 8);
      if (value >= stream.length) return 0;

      total += value;
      if (total > stream.length) return 0;

      higher <<= 6;
      size = 0;

      for (i = 0; i < higher; ++i) {
        value = stream.readUnsignedInt();
        if (value) size++;

        loop = (value >> 16) & 0x0fff;
        if (loop > 0x358 || (loop != 0 && loop < 0x71)) return 0;

        value = (value >> 24) & 0xf0;
        if (value > 0x10) return 0;
      }

      if (!size) return 0;

      format = "ProPacker 1";
      return 1;
    }
  }
}