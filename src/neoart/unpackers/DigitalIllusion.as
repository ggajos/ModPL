/*
  Flod Unpack 1.0
  2012/12/24
  Christian Corti
  Neoart Costa Rica

  Last Update: Flod Unpack 1.0 - 2013/03/20

  Digital Illusion Packer by The Silents

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

  public final class DigitalIllusion extends Packer {

    override public function depack(stream:ByteArray):ByteArray {
      var b1:int, b2:int, b3:int, b4:int, higher:int, i:int, j:int, length:int, patterns:int, sdata:int, size:int, tdata:int, offsets:Vector.<int>, output:ByteArray = new ByteArray();

      if (!identify(stream)) return stream;

      stream.position = 0;
      output.length   = 20;
      output.position = 20;

      length   = stream.readUnsignedShort();
      tdata    = stream.readUnsignedInt();
      patterns = stream.readUnsignedInt() - tdata;
      sdata    = stream.readUnsignedInt();

      for (i = 0; i < length; ++i) {
        output.length   += 22;
        output.position += 22;

        b1 = stream.readUnsignedShort();
        output.writeShort(b1);
        size += (b1 << 1);

        output.writeByte(stream.readUnsignedByte());
        output.writeByte(stream.readUnsignedByte());
        output.writeShort(stream.readUnsignedShort());
        output.writeShort(stream.readUnsignedShort());
      }

      for (; i < 31; ++i) {
        output.length   += 22;
        output.position += 22;
        output.writeInt(0);
        output.writeShort(0);
        output.writeShort(1);
      }

      output.writeByte(--patterns);
      output.writeByte(0x7f);
      output.length += 128;

      b1 = stream.position;
      stream.position = tdata;
      b2 = stream.readUnsignedByte();

      do {
        if (b2 > higher) higher = b2;
        output.writeByte(b2);
        b2 = stream.readUnsignedByte();
      } while (b2 != 0xff);

      patterns = higher + 2;
      offsets = new Vector.<int>(patterns, true);
      offsets[++higher] = sdata;
      stream.position = b1;

      for (i = 0; i < higher; ++i) {
        offsets[i] = stream.readUnsignedShort();
      }

      output.position = 1080;
      output.writeUTFBytes(MAGIC);
      output.length += (higher << 10);
      stream.position = offsets[0];

      for (i = 1; i < patterns; ++i) {
        length = offsets[i];

        do {
          b1 = stream.readUnsignedByte();

          if (b1 == 0xff) {
            output.position += 4;
            continue;
          }

          b2 = stream.readUnsignedByte();
          b3 = ((b1 << 4) & 0x30) | ((b2 >> 4) & 0x0f);
          b4 =  (b1 >> 2) & 0x1f;

          output.writeByte(NOTES[b3][0] | (b4 & 0xf0));
          output.writeByte(NOTES[b3][1]);

          b2 &= 0x0f;
          output.writeByte(((b4 << 4) & 0xf0) | b2);

          if (b1 & 0x80) {
            output.writeByte(stream.readUnsignedByte());
          } else {
            output.position++;
          }
        } while (stream.position < length);

        output.position = 1084 + (i << 10);
      }

      stream.position = sdata;
      output.writeBytes(stream, stream.position, size);

      stream.clear();
      output.endian = ORDER;
      return output;
    }

    override public function identify(stream:ByteArray):int {
      var b1:int, b2:int, b3:int, i:int, size:int, samples:int;

      samples = stream.readUnsignedShort();
      if (samples > 31) return 0;

      b1 = stream.readUnsignedInt();
      b2 = stream.readUnsignedInt();
      b3 = stream.readUnsignedInt();

      if (b1 >= b2 || b1 >= b3 || b2 >= b3) return 0;

      if (b1 >= stream.length || b2 >= stream.length || b3 >= stream.length) return 0;

      for (i = 0; i < samples; ++i) {
        size += (stream.readUnsignedShort() << 1);

        if (stream.readUnsignedByte() > 15) return 0;
        if (stream.readUnsignedByte() > 64) return 0;

        stream.position += 4;
      }

      if ((size + b3) > stream.length) return 0;

      format = "Digital Illusion";
      return 1;
    }
  }
}