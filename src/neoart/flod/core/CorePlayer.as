/*
  Flod 5.0
  2013/08/15
  Christian Corti
  Neoart Costa Rica

  Last Update: Flod 5.0 - 2013/08/15

  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
  OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
  LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR
  IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

  This work is licensed under the Creative Commons Attribution-Noncommercial-Share Alike 3.0 Unported License.
  To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-sa/3.0/ or send a letter to
  Creative Commons, 171 Second Street, Suite 300, San Francisco, California, 94105, USA.
*/
package neoart.flod.core {
  import flash.events.*;
  import flash.media.*;
  import flash.utils.*;

  public class CorePlayer extends EventDispatcher {
    public var
      loop    : Boolean,
      quality : Boolean,
      record  : Boolean;
    protected var
      m_channels   : int,
      m_currSong   : int,
      m_duration   : int,
      m_filter     : int,
      m_mute       : int,
      m_ntsc       : Boolean,
      m_position   : int,
      m_separation : Number = 1.0,
      m_skip       : Boolean,
      m_title      : String = "",
      m_totalSongs : int,
      m_trackPos   : int,
      m_variant    : int,
      m_version    : int,
      m_volume     : Number = 1.0,
      endian       : String,
      flags        : int,
      speed        : int,
      tempo        : int,
      tick         : int,
      mixer        : CoreMixer,
      sound        : Sound,
      soundChannel : SoundChannel,
      soundPos     : Number = 0.0,
      trackDone    : Array;

    public function CorePlayer(mixer:CoreMixer) {
      mixer.player = this;
      this.mixer = mixer;

      trackDone = [];
    }

    public function get channels():int { return m_channels; }

    public function get currentSong():int { return m_currSong; }

    public function set currentSong(value:int):void {
      if (value >= m_totalSongs) value = 0;
      m_currSong = value;
    }

    public function get duration():int { return m_duration; }

    public function get filterMode():int { return m_filter; }

    public function set filterMode(value:int):void { }

    public function get ntsc():Boolean { return m_ntsc; }

    public function set ntsc(value:Boolean):void { }

    public function get position():int { return m_position / 44.1; }

    public function get skipDuration():Boolean { return m_skip; }

    public function set skipDuration(value:Boolean):void {
      if (value == m_skip) return
      m_skip = value;
      if (value && !m_duration) calc();
    }

    public function get stereoSeparation():Number { return m_separation; }

    public function set stereoSeparation(value:Number):void { }

    public function get title():String { return m_title; }

    public function get totalSongs():int { return m_totalSongs; }

    public function get trackPosition():int { return m_trackPos; }

    public function set trackPosition(value:int):void {
      m_trackPos = value;
    }

    public function get variant():int { return m_variant; }

    public function set variant(value:int):void { }

    public function get version():int { return m_version; }

    public function set version(value:int):void { }

    public function get volume():Number { return m_volume; }

    public function set volume(value:Number):void { }

    public function get waveform():ByteArray { return mixer.waveform(); }

    public function load(stream:ByteArray, extra:ByteArray = null):int {
      m_currSong   = 0;
      m_duration   = 0;
      m_version    = 0;
      m_variant    = 0;
      m_totalSongs = 0;

      mixer.reset();

      if (extra) {
        extra.endian = endian;
        extra.position = 0;
      }

      stream.endian = endian;
      stream.position = 0;

      loader(stream, extra);

      if (m_version) {
        mixer.setup();
        if (!m_skip) calc();
      }

      return m_version;
    }

    public function mute(index:int = -1):void { }

    public function fast():void { }

    public function accurate():void { }

    public function play(processor:Sound = null):Boolean {
      if (!m_version) return false;

      if (soundPos == 0.0) initialize();

      sound = processor || new Sound();

      if (quality) {
        sound.addEventListener(SampleDataEvent.SAMPLE_DATA, mixer.accurate);
      } else {
        sound.addEventListener(SampleDataEvent.SAMPLE_DATA, mixer.fast);
      }

      soundChannel = sound.play(soundPos);
      soundChannel.addEventListener(Event.SOUND_COMPLETE, completeHandler);
      soundPos = 0.0;

      return true;
    }

    public function pause():void {
      if (!m_version || !soundChannel) return;

      soundPos = soundChannel.position;
      removeListeners();
    }

    public function seek(position:int):int {
      return 0;
    }

    public function stop():void {
      if (!m_version) return;

      if (soundChannel) removeListeners();

      soundPos = 0.0;
      reset();
    }

    protected function initialize():void {
      tick  = 0;
      speed = 6;

      trackDone.length = 0;
      trackDone[0] = 1;

      m_position = 0;
      mixer.initialize();
    }

    protected function calc():void {}

    protected function loader(stream:ByteArray, extra:ByteArray):void { }

    protected function reset():void { }

    private function completeHandler(e:Event):void {
      stop();
      dispatchEvent(e);
    }

    private function removeListeners():void {
      soundChannel.stop();
      soundChannel.removeEventListener(Event.SOUND_COMPLETE, completeHandler);
      soundChannel.dispatchEvent(new Event(Event.SOUND_COMPLETE));

      if (quality) {
        sound.removeEventListener(SampleDataEvent.SAMPLE_DATA, mixer.accurate);
      } else {
        sound.removeEventListener(SampleDataEvent.SAMPLE_DATA, mixer.fast);
      }
    }
  }
}