/**
 * Created by Mouster on 2014-07-07.
 */
package com.opentangerine {
public class ConversionUtil {

    public static function progressText(positionInSeconds:Number, durationInSeconds:Number):String {
        var currentMs = positionInSeconds / 1000.0
        var durationMs = durationInSeconds / 1000.0
        currentMs = currentMs % durationMs
        return ConversionUtil.convertToMMSS(currentMs) + " / " + ConversionUtil.convertToMMSS(durationMs)
    }

    public static function convertToMMSS(seconds:Number): String {
        var s: Number = seconds % 60;
        var m: Number = Math.floor((seconds % 3600 ) / 60);
        return doubleDigitFormat(m) + ":" + doubleDigitFormat(s);
    }

    public static function doubleDigitFormat(n :uint): String {
        return (n < 10) ? ("0" + n) : String(n);
    }

}
}
