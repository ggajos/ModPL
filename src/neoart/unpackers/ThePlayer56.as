/*
  Flod Unpack 1.0
  2012/12/24
  Christian Corti
  Neoart Costa Rica

  Last Update: Flod Unpack 1.0 - 2012/12/24

  The Player 5.0a/6.0a by Jarno Paananen aka Guru of Sahara Surfers

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

  public final class ThePlayer56 extends Packer {
    private var
      version : int;

    override public function depack(stream:ByteArray):ByteArray {
      var b1:int, b2:int, b3:int, b4:int, c:int, delta:int, i:int, id:String, j:int, l:int, length:int, packed:int, patterns:int, r:int, rows:int, sdata:int, skip:int, tdata:int, temp:Object, value:int, x:int, offsets:Vector.<int>, samples:Vector.<Object>, data:ByteArray = new ByteArray(), output:ByteArray = new ByteArray();

      if (!identify(stream)) return stream;

      stream.position = 0;
      output.length   = 20;
      output.position = 20;

      id = stream.readUTFBytes(4);
      if (id != ID0 && id != ID1) stream.position = 0;

      sdata    = stream.position + stream.readUnsignedShort();
      patterns = stream.readUnsignedByte();
      length   = stream.readUnsignedByte();

      if (length & 0x40) packed = 1;
        else if (length & 0x80) delta = 1;

      length &= 0x1f;
      samples = new Vector.<Object>(length, true);
      if (packed) stream.position += 4;

      for (i = 0; i < length; ++i) {
        output.length   += 22;
        output.position += 22;
        temp = {};

        value = stream.readUnsignedShort();
        temp.length = value;
        temp.size = value << 1;

        value = stream.readUnsignedByte();
        temp.packed = value & 0x80;

        if (temp.length > 0xff00) {
          temp = samples[int(0xffff - temp.length)];
        } else {
          temp.offset = sdata + tdata;
          tdata += temp.packed ? temp.length : temp.size;
        }

        output.writeShort(temp.length);
        output.writeByte(value & 0x0f);
        output.writeByte(stream.readUnsignedByte());
        value = stream.readUnsignedShort();

        if (value == 0xffff) {
          output.writeShort(0);
          output.writeShort(1);
        } else {
          output.writeShort(value);
          output.writeShort(temp.length - value);
        }

        samples[i] = temp;
      }

      for (; i < 31; ++i) {
        output.length   += 22;
        output.position += 22;
        output.writeInt(0);
        output.writeShort(0);
        output.writeShort(1);
      }

      output.length += 130;
      output.position += 2;

      length = patterns << 2;
      offsets = new Vector.<int>(length, true);

      for (i = 0; i < length; ++i) {
        offsets[i] = stream.readUnsignedShort();
      }

      for (i = 0; i < 128; ++i) {
        value = stream.readUnsignedByte();
        if (value == 0xff) break;
        if (version == 5) value >>= 1;
        output.writeByte(value);
      }

      output[950] = i;
      output[951] = 0x7f;
      output.position = 1080;
      output.writeUTFBytes(MAGIC);

      tdata = stream.position;
      value = 0;
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

              if (b1 == 0x80) {
                l = b2 + 2;
                b4 = stream.readUnsignedByte();
                value = stream.position;
                stream.position -= ((b3 << 8) + b4);
                continue;
              }

              if (b1 > 0x7f) {
                b1 = 255 - b1;
                b4 = stream.readUnsignedByte();

                if (b4 > 0x7f) {
                  length = 257 - b4;
                } else {
                  skip = b4;
                }
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

      if (delta) {
        for (i = 0; i < length; ++i) {
          temp = samples[i];
          stream.position = temp.offset;
          tdata = temp.size;

          delta = stream.readUnsignedByte();
          output.writeByte(delta);

          for (j = 1; j < tdata; ++j) {
            value = stream.readUnsignedByte();
            delta -= value;
            output.writeByte(delta);
          }
        }
      } else if (packed) {
        for (i = 0; i < length; ++i) {
          temp = samples[i];

          if (temp.packed) {
            stream.position = temp.offset;
            tdata = temp.length;
            delta = 0;

            for (j = 0; j < tdata; ++j) {
              packed = stream.readUnsignedByte();
              delta -= TABLE[int(packed >> 4)];
              output.writeByte(delta);
              delta -= TABLE[int(packed & 0x0f)];
              output.writeByte(delta);
            }
          } else {
            output.writeBytes(stream, temp.offset, temp.size);
          }
        }
      } else {
        for (i = 0; i < length; ++i) {
          temp = samples[i];
          output.writeBytes(stream, temp.offset, temp.size);
        }
      }

      output.position = 0;
      output.writeUTFBytes(format);
      output.position = 890;
      output.writeUTFBytes(format);
      output.position = 920;
      output.writeUTFBytes("(C) 1992-94 Guru/S2");

      data.clear();
      stream.clear();
      output.endian = ORDER;
      return output;
    }

    override public function identify(stream:ByteArray):int {
      var b1:int, b2:int, b3:int, b4:int, i:int, id:String, j:int, length:int, patterns:int, samples:int, sdata:int, size:int, tdata:int, value:int;

      format = "";
      stream.position = 0;
      id = stream.readUTFBytes(4);

      if (id != ID0 && id != ID1) {
        id = "";
        stream.position = 0;
      }

      sdata    = stream.position + stream.readUnsignedShort();
      patterns = stream.readUnsignedByte();
      samples  = stream.readUnsignedByte();

      if (id == "") {
        id = ID0;
        stream.position += (((samples & 0x3f) - 1) * 6);

        if (stream.readUnsignedShort() == 1 &&
            stream.readUnsignedShort() == 0 &&
            stream.readUnsignedShort() == 0xffff) id = ID1;

        stream.position = 4;
      }

      if (samples & 0x40) stream.position += 4;
      samples &= 0x3f;

      if (sdata >= stream.length ||
          patterns == 0          ||
          patterns > 0x63        ||
          samples == 0           ||
          samples > 0x1f) return 0;

      for (i = 0; i < samples; ++i) {
        j = stream.readUnsignedShort();
        value = stream.readUnsignedByte();

        if (j < 0xff00) {
          size += j;
          if (!(value & 0x80)) size += j
        }

        if ((value & 0x3f) > 0x0f) return 0;
        if (stream.readUnsignedByte() > 0x40) return 0;

        value = stream.readUnsignedShort();

        if (value != 0xffff) {
          if (value > j) return 0;
        }
      }

      if ((sdata + size) > stream.length) return 0;

      tdata = stream.position;
      stream.position += (patterns << 3);

      for (i = 0; i < 128; ++i) {
        value = stream.readUnsignedByte();
        if (value == 0xff) break;

        if (id == ID0) {
          if (value & 1) {
            id = ID1;
          } else {
            value >>= 1;
          }
        }

        if (value > 0x63) return 0;
      }

      value = stream.position;
      stream.position = tdata;
      length = (patterns << 2);

      for (i = 0; i < length; ++i) {
        if ((tdata + stream.readUnsignedShort()) >= sdata) return 0;
      }

      stream.position = value;

      while (stream.position < sdata) {
        b1 = stream.readUnsignedByte();
        b2 = stream.readUnsignedByte();
        b3 = stream.readUnsignedByte();

        if (b1 > 0x7f) {
          b4 = stream.readUnsignedByte();

          if (b1 == 0x80) {
            if ((stream.position - ((b3 << 8) + b4)) < value) return 0;
          }
          continue;
        }

        if (b1 > 0x49) return 0;
        b3 = ((b1 << 4) & 0x10) | ((b2 >> 4) & 0x0f);
        if (b3 > samples) return 0;
      }

      if (id == ID0) {
        format  = "5.0a";
        version = 5;
      } else {
        format  = "6.0a";
        version = 6;
      }

      format = "The Player "+ format;
      return 1;
    }

    private const
      ID0 : String = "P50A",
      ID1 : String = "P60A",

      TABLE : Vector.<int> = Vector.<int>([
        0,1,2,4,8,16,32,64,128,-64,-32,-16,-8,-4,-2,-1
      ]);
  }
}