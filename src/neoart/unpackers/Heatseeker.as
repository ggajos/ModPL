/*
  Flod Unpack 1.0
  2012/12/24
  Christian Corti
  Neoart Costa Rica

  Last Update: Flod Unpack 1.0 - 2012/12/24

  Heatseeker MC1.0 by Ivar Just Olsen aka Heatseeker of Cryptoburners

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

  public final class Heatseeker extends Packer {

    override public function depack(stream:ByteArray):ByteArray {
      var b1:int, c:int, higher:int, i:int, j:int, patterns:int, size:int, value:int, x:int, offsets:Vector.<int>, data:ByteArray = new ByteArray(), output:ByteArray = new ByteArray();

      if (!identify(stream)) return stream;

      stream.position = 0;
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

      patterns = stream.readUnsignedByte();
      output.writeByte(patterns);
      output.writeByte(stream.readUnsignedByte());
      output.length += 128;

      for (i = 0; i < patterns; ++i) {
        value = stream.readUnsignedByte();
        if (value > higher) higher = value;
        output.writeByte(value);
      }

      output.position = 1080;
      output.writeUTFBytes(MAGIC);

      stream.position = 378;
      offsets  = new Vector.<int>((++higher << 2), true);
      patterns = value = 0;

      for (i = 0; i < higher; ++i) {
        data.clear();
        data.length = 1024;

        for (c = 0; c < 4; ++c) {
          offsets[patterns++] = stream.position;

          for (j = 0; j < 64; ++j) {
            b1 = stream.readUnsignedByte();

            if (b1 == 0x80) {
              stream.position += 2;
              j += stream.readUnsignedByte();
              continue;
            }

            x = (c << 2) + (j << 4);

            if (b1 == 0xc0) {
              j = 0;
              stream.position++;
              b1 = stream.readUnsignedShort() >> 2;
              value = stream.position;

              stream.position = offsets[b1];
              b1 = stream.readUnsignedByte();
            }

            data[x] = b1;
            data[++x] = stream.readUnsignedByte();
            data[++x] = stream.readUnsignedByte();
            data[++x] = stream.readUnsignedByte();
          }

          if (value) {
            stream.position = value;
            value = 0;
          }
        }

        output.writeBytes(data, 0, 1024);
      }

      output.writeBytes(stream, stream.position, size);

      data.clear();
      stream.clear();
      output.endian = ORDER;
      return output;
    }

    override public function identify(stream:ByteArray):int {
      var b1:int, b2:int, i:int, size:int, value:int;

      format = "";
      if (stream.length < 378) return 0;
      stream.position = 0;

      for (i = 0; i < 31; ++i) {
        value = stream.readUnsignedShort();
        size += (value << 1);

        if (stream.readUnsignedByte() > 0x0f) return 0;
        if (stream.readUnsignedByte() > 0x40) return 0;

        if (value) {
          b1 = stream.readUnsignedShort();
          b2 = stream.readUnsignedShort();
          if ((b1 + b2) > value) return 0;
        } else {
          stream.position += 4;
        }
      }

      if (size > stream.length || stream.readUnsignedByte() > 0x7f) return 0;
      stream.position++;

      for (i = 0; i < 128; ++i) {
        if (stream.readUnsignedByte() > 0x3f) return 0;
      }

      value = stream.length - size;

      while (stream.position < value) {
        b1 = stream.readUnsignedByte();

        if (b1 == 0x80 || b1 == 0xc0) {
          stream.position += 3;
          continue;
        }

        b2 = ((b1 & 0x0f) << 8) | stream.readUnsignedByte();
        if (b2 > 856 || (b2 && b2 < 113)) return 0;

        b1 = (b1 & 0xf0) | ((stream.readUnsignedByte() >> 4) & 0x0f);
        if (b1 > 0x1f) return 0;

        stream.position++;
      }

      format = "Heatseeker MC1.0";
      return 1;
    }
  }
}