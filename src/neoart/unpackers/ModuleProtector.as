/*
  Flod Unpack 1.0
  2012/12/24
  Christian Corti
  Neoart Costa Rica

  Last Update: Flod Unpack 1.0 - 2012/12/24

  Module Protector 1.0 by David Counter aka Matrix of LSD

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

  public final class ModuleProtector extends Packer {

    override public function depack(stream:ByteArray):ByteArray {
      var higher:int, i:int, size:int, value:int, output:ByteArray = new ByteArray();

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

      output.writeShort(stream.readUnsignedShort());

      for (i = 0; i < 128; ++i) {
        value = stream.readUnsignedByte();
        if (value > higher) higher = value;
        output.writeByte(value);
      }

      output.writeUTFBytes(MAGIC);

      size += (++higher << 10);
      output.writeBytes(stream, stream.position, size);

      stream.clear();
      output.endian = ORDER;
      return output;
    }

    override public function identify(stream:ByteArray):int {
      var higher:int, i:int, loop:int, repeat:int, size:int, total:int, value:int;

      format = "";
      if (stream.length < 1404) return 0;
      stream.position = 0;

      for (i = 0; i < 31; ++i) {
        size = stream.readUnsignedShort();
        total += (size << 1);

        if (stream.readUnsignedByte() > 0x0f) return 0;
        if (stream.readUnsignedByte() > 0x40) return 0;

        loop   = stream.readUnsignedShort();
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

      for (i = 0; i < 128; ++i) {
        value = stream.readUnsignedByte();
        if (value > 0x3f) return 0;
        if (value > higher) higher = value;
      }

      value = 378 + ((++higher) << 10);
      if (value >= stream.length) return 0;

      total += value;
      if (value > stream.length) return 0;

      higher <<= 8;
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

      format = "ModuleProtector 1.0";
      return 1;
    }
  }
}