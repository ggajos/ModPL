/*
  Flod Unpack 1.0
  2012/12/24
  Christian Corti
  Neoart Costa Rica

  Last Update: Flod Unpack 1.0 - 2012/12/24

  The Player 4.0a/4.0b/4.1a by Jarno Paananen aka Guru of Complex and Parallax

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

  public final class ThePlayer4 extends Packer {

    override public function depack(stream:ByteArray):ByteArray {
      var b1:int, b2:int, b3:int, b4:int, c:int, i:int, id:String, j:int, l:int, length:int, patterns:int, r:int, rows:int, sdata:int, skip:int, tdata:int, temp:Object, track:int, value:int, x:int, offsets:Vector.<int>, samples:Vector.<Object>, data:ByteArray = new ByteArray(), output:ByteArray = new ByteArray();

      if (!identify(stream)) return stream;

      stream.position = 0;
      output.length   = 20;
      output.position = 20;

      id = stream.readUTFBytes(4);
      stream.position++;

      patterns = stream.readUnsignedByte();
      length   = stream.readUnsignedByte();

      if (length > 31) length = 31;
      stream.position++;

      tdata = stream.readUnsignedInt() + 4;
      track = stream.readUnsignedInt() + 4;
      sdata = stream.readUnsignedInt() + 4;

      samples = new Vector.<Object>(length);

      for (i = 0; i < length; ++i) {
        temp = {};
        temp.offset = stream.readUnsignedInt();

        if ((sdata + temp.offset) >= stream.length) {
          samples.length = i;
          break;
        }

        temp.size   = stream.readUnsignedShort();
        temp.loop   = stream.readUnsignedInt();
        temp.repeat = stream.readUnsignedShort();

        if (id == ID2) {
          temp.volume = stream.readUnsignedShort();
          temp.fine   = stream.readUnsignedShort();
        } else {
          temp.fine   = stream.readUnsignedShort();
          temp.volume = stream.readUnsignedShort();
        }

        if (temp.fine > 0x456) temp.fine = 0;

        output.length   += 22;
        output.position += 22;
        output.writeShort(temp.size);
        output.writeByte(temp.fine / 74);
        output.writeByte(temp.volume);
        output.writeShort((temp.loop - temp.offset) >> 1);
        output.writeShort(temp.repeat);

        temp.offset += sdata;
        temp.size <<= 1;
        samples[i] = temp;
      }

      for (; i < 31; ++i) {
        output.length   += 22;
        output.position += 22;
        output.writeInt(0);
        output.writeShort(0);
        output.writeShort(1);
      }

      output.writeByte(patterns);
      output.writeByte(0x7f);
      output.length += 128;

      offsets = new Vector.<int>();
      stream.position = track;

      for (i = 0; i < patterns; ++i) {
        value  = stream.readUnsignedShort();
        length = offsets.length;

        for (j = 0; j < length; j += 4) {
          if (value == offsets[j]) {
            skip = 1;
            break;
          }
        }

        if (skip) {
          skip = 0;
          stream.position += 6;
          output.writeByte(j >> 2);
        } else {
          offsets[length] = value;
          offsets[++length] = stream.readUnsignedShort();
          offsets[++length] = stream.readUnsignedShort();
          offsets[++length] = stream.readUnsignedShort();
          output.writeByte(r++);
        }
      }

      offsets.fixed = true;
      patterns = offsets.length >> 2;
      skip = value = 0;

      output.position = 1080;
      output.writeUTFBytes(MAGIC);
      output.length += (patterns << 10);

      for (i = 0; i < patterns; ++i) {
        data.clear();
        data.length = 1024;
        rows = 64;

        for (c = 0; c < 4; ++c) {
          stream.position = tdata + offsets[int(c + (i << 2))];

          for (j = 0; j < rows;) {
            x = (c << 2) + (j << 4);
            l = 1;

            do {
              if (stream.position >= sdata) {
                j = 64;
                break;
              }

              length = 1;
              b1 = stream.readUnsignedByte();
              b2 = stream.readUnsignedByte();
              b3 = stream.readUnsignedByte();
              b4 = stream.readUnsignedByte();

              if (b1 & 0x80) {
                l = b2 + 2;
                value = stream.position;
                stream.position = tdata + ((b3 << 8) + b4);
                continue;
              }

              if (b4 > 0x7f) {
                length = 257 - b4;
              } else if (b4) {
                skip = b4;
              }

              b4 = b2 & 0x0f;

              if (b4 == 0x05 || b4 == 0x06 || b4 == 0x0a) {
                if (b3 > 0x7f) b3 = ((256 - b3) << 4) & 0xf0;
              } else if (b4 == 0x08) {
                b2 -= 8;
              } else if (b4 == 0x0b || b4 == 0x0d) {
                rows   = j + 1;
                length = l = 1;
              } else if (b4 == 0x0e) {
                if (b3 == 2) b3 = 1;
              }

              b4 = b1 >> 1;
              b1 = ((b1 << 4) & 0x10) | NOTES[b4][0];
              b4 = NOTES[b4][1];

              for (r = 0; r < length; ++r, ++j) {
                data[x++] = b1;
                data[x++] = b4;
                data[x++] = b2;
                data[x++] = b3;
                x += 12;
              }

              if (skip) {
                j += skip;
                x += (skip << 4);
                skip = 0;
              }
            } while (--l);

            if (value) {
              stream.position = value;
              value = 0;
            }
          }
        }

        output.position = 1084 + (i << 10);
        output.writeBytes(data, 0, (rows << 4));
      }

      length = samples.length;
      output.position = output.length;

      for (i = 0; i < length; ++i) {
        temp = samples[i];
        if (stream.length <= temp.offset || stream.bytesAvailable < temp.size) break;
        output.writeBytes(stream, temp.offset, temp.size);
      }

      output.position = 0;
      output.writeUTFBytes(format);
      output.position = 890;
      output.writeUTFBytes(format);
      output.position = 920;
      output.writeUTFBytes("(C) 1992-93 Guru/S2");

      data.clear();
      stream.clear();
      output.endian = ORDER;
      return output;
    }

    override public function identify(stream:ByteArray):int {
      var b1:int, b2:int, b3:int, b4:int, i:int, id:String, patterns:int, samples:int, sdata:int, size:int, tdata:int, track:int;

      format = "";
      stream.position = 0;
      id = stream.readUTFBytes(4);
      if (id != ID0 && id != ID1 && id != ID2) return 0;

      track    = stream.readUnsignedByte();
      patterns = stream.readUnsignedByte() << 2;
      samples  = stream.readUnsignedByte();

      if (track > 0x3f     ||
          patterns == 0    ||
          patterns > 0x1fc ||
          samples == 0     ||
          samples > 0x20) return 0;

      stream.position++;
      tdata = stream.readUnsignedInt() + 4;
      track = stream.readUnsignedInt() + 4;
      sdata = stream.readUnsignedInt() + 4;

      if (tdata > stream.length ||
          track > stream.length ||
          sdata > stream.length ||
          tdata >= sdata ||
          track >= sdata) return 0;

      for (i = 0; i < samples; ++i) {
        b1 = stream.readUnsignedInt();

        if (b1 != size) {
          stream.position += 12;
          continue;
        }

        if ((sdata + b1) == stream.length) break;

        b2 = stream.readUnsignedShort();
        size += (b2 << 1);

        b2 = stream.readUnsignedInt();
        b3 = stream.readUnsignedShort();
        if (b3 == 1 && ((b2 - b1) != 0)) return 0;

        if (id == ID2) {
          if (stream.readUnsignedShort() > 0x40 ) return 0;
          if (stream.readUnsignedShort() > 0x4ea) return 0;
        } else {
          if (stream.readUnsignedShort() > 0x4ea) return 0;
          if (stream.readUnsignedShort() > 0x40 ) return 0;
        }
      }

      if ((sdata + size) > stream.length) return 0;

      stream.position = track;

      for (i = 0; i < patterns; ++i) {
        if (tdata + stream.readUnsignedShort() >= sdata) return 0;
      }

      if (stream.readUnsignedShort() != 0xffff) return 0;

      stream.position = tdata;

      do {
        b1 = stream.readUnsignedByte();
        b2 = stream.readUnsignedByte();
        b3 = stream.readUnsignedByte();
        b4 = stream.readUnsignedByte();

        if (b1 & 0x80) {
          if ((tdata + ((b3 << 8) + b4)) < tdata) return 0;
          continue;
        }

        if (b1 > 0x49) return 0;
        b3 = ((b1 << 4) & 0x10) | ((b2 >> 4) & 0x0f);
        if (b3 > samples) return 0;
      } while (stream.position < sdata);

      if (id == ID0) {
        format = "4.0a";
      } else if (id == ID1) {
        format = "4.0b";
      } else {
        format = "4.1a";
      }

      format = "The Player "+ format;
      return 1;
    }

    private const
      ID0 : String = "P40A",
      ID1 : String = "P40B",
      ID2 : String = "P41A";
  }
}