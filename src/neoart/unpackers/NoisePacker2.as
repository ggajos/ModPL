/*
  Flod Unpack 1.0
  2012/12/24
  Christian Corti
  Neoart Costa Rica

  Last Update: Flod Unpack 1.0 - 2012/12/24

  NoisePacker 1.0/2.0/2.01/2.02/2.03 by Twins of Phenomena

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

  public final class NoisePacker2 extends Packer {

    override public function depack(stream:ByteArray):ByteArray {
      var b1:int, b2:int, b3:int, b4:int, c:int, higher:int, i:int, j:int, length:int, patterns:int, sdata:int, size:int, tdata:int, value:int, x:int, offsets:Vector.<int>, output:ByteArray = new ByteArray();

      if (!identify(stream)) return stream;

      stream.position = 0;
      output.length   = 20;
      output.position = 20;

      b1 = stream.readUnsignedShort();
      b2 = stream.readUnsignedShort();
      b3 = stream.readUnsignedShort();

      length   = (b1 - 0x0c) >> 4;
      patterns = b2 >> 1;
      tdata    = b1 + b2 + b3
      sdata    = tdata + stream.readUnsignedShort();;

      for (i = 0; i < length; ++i) {
        output.length   += 22;
        output.position += 22;
        stream.position += 4;

        b1 = stream.readUnsignedShort();
        output.writeShort(b1);
        size += (b1 << 1);

        output.writeByte(stream.readUnsignedByte());
        output.writeByte(stream.readUnsignedByte());
        stream.position += 4;

        b2 = stream.readUnsignedShort();
        b3 = stream.readUnsignedShort();
        if ((b2 + b3) > b1) b3 >>= 1;

        output.writeShort(b3);
        output.writeShort(b2);
      }

      for (; i < 31; ++i) {
        output.length   += 22;
        output.position += 22;
        output.writeInt(0);
        output.writeShort(0);
        output.writeShort(1);
      }

      stream.position += 2;
      output.writeByte(patterns);
      output.writeByte(stream.readUnsignedShort() >> 1);
      output.length += 128;

      for (i = 0; i < patterns; ++i) {
        value = stream.readUnsignedShort() >> 3;
        if (value > higher) higher = value;
        output.writeByte(value);
      }

      output.position = 1080;
      output.writeUTFBytes(MAGIC);

      offsets = new Vector.<int>((++higher << 2), true);

      for (i = 0; i < higher; ++i) {
        value = (i << 2);
        offsets[int(value + 3)] = tdata + stream.readUnsignedShort();
        offsets[int(value + 2)] = tdata + stream.readUnsignedShort();
        offsets[int(value + 1)] = tdata + stream.readUnsignedShort();
        offsets[int(value)]     = tdata + stream.readUnsignedShort();
      }

      output.length += (higher << 10);

      for (i = 0; i < higher; ++i) {
        value = 1084 + (i << 10);

        for (c = 0; c < 4; ++c) {
          stream.position = offsets[int(c + (i << 2))];
          x = value + (c << 2);

          for (j = 0; j < 64; ++j) {
            b1 = stream.readUnsignedByte();
            b2 = stream.readUnsignedByte();
            b3 = stream.readUnsignedByte();

            b4 = (b1 & 0xfe) >> 1;
            b1 = ((b1 << 4) & 0x10) | NOTES[b4][0];

            output[x++] = b1;
            output[x++] = NOTES[b4][1];

            b4 = b2 & 0x0f;

            switch (b4) {
              case 0x07:
                b2 = (b2 & 0xf0) + 0x0a;
              case 0x05:
              case 0x06:
                b3 = (b3 > 0x80) ? 256 - b3 : (b3 << 4) & 0xf0;
                break;
              case 0x08:
                b2 -= 8;
                break;
              case 0x0b:
                b3 = (b3 + 4) >> 1;
                break;
              case 0x0e:
                b3 >>= 1;
                break;
            }

            output[x++] = b2;
            output[x++] = b3;
            x += 12;
          }
        }
      }

      output.position = output.length;
      output.writeBytes(stream, sdata, size);

      stream.clear();
      output.endian = ORDER;
      return output;
    }

    override public function identify(stream:ByteArray):int {
      var b1:int, b2:int, b3:int, higher:int, i:int, length:int, patterns:int, sdata:int, size:int, tdata:int, value:int, version:int = 2;

      format = "";
      stream.position = 0;

      b1 = stream.readUnsignedShort();
      b2 = stream.readUnsignedShort();
      b3 = stream.readUnsignedShort();

      length   = (b1 - 0x0c) >> 4;
      patterns = b2 >> 1;
      tdata    = b1 + b2 + b3;
      sdata    = tdata + stream.readUnsignedShort();

      if (sdata >= stream.length || patterns > 0x7f) return 0;

      for (i = 0; i < length; ++i) {
        stream.position += 4;
        value = stream.readUnsignedShort();
        size += (value << 1);

        stream.position++;
        if (stream.readUnsignedByte() > 0x40) return 0;
        stream.position += 4;

        b1 = stream.readUnsignedShort();
        b2 = stream.readUnsignedShort();

        if ((b1 + b2) > value) {
          b2 >>= 1;
          if ((b1 + b2) > value) return 0;
          version = 1;
        }
      }

      if ((sdata + size) > stream.length) return 0;

      if ((stream.readUnsignedShort() >> 1) != patterns) return 0;
      stream.position += 2;

      for (i = 0; i < patterns; ++i) {
        value = stream.readUnsignedShort() >> 3;
        if (value > 0x3f) return 0;
        if (value > higher) higher = value;
      }

      higher = (++higher) << 2;

      for (i = 0; i < higher; ++i) {
        value = stream.readUnsignedShort();
        if ((tdata + value) >= sdata) return 0;
      }

      while (stream.position < sdata) {
        b1 = stream.readUnsignedByte();
        b2 = stream.readUnsignedByte();
        b3 = stream.readUnsignedByte();

        if (b1 > 0x49) return 0;
        value = ((b1 & 0x01) << 4) | ((b2 >> 4) & 0x0f);
        if (value > 0x1f) return 0;
      }

      format = "NoisePacker "+ version.toString();
      return 1;
    }
  }
}