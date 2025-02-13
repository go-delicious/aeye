___

Lua is a tiny and extensible scripting language that’s designed to be power efficient and quick to learn. Frame features a complete Lua virtual machine based on the latest public release of Lua. Dedicated hardware APIs allow direct access to all of Frame’s peripherals at a high level so that developers can start building apps quickly and easily.

Note that the Lua virtual machine on the Frame has a subset of the standard library, so some guides on the internet about Lua may contain code that won’t work on Frame without modification. Specifically, Lua’s standard `io` and `os` libraries are not present on Frame.

There’s no special cables or setup needed. Lua on Frame is accessed solely over Bluetooth, such that any user created host app can easily execute scripts by simply pushing Lua strings to the device. To learn more how the underlying Bluetooth communication with Frame works, check out the Talking to the Frame over Bluetooth page.

___

## Library reference

This page describes all of the Frame specific Lua APIs available to the developer along with some helpful examples. Certain libraries allow for more low level access that can be used for debugging and hacking the various subsystems of Frame.

The API specification is still undergoing heavy development. Some of them may change over time.

1.  Display
2.  Camera
3.  Microphone
4.  Motion sensor (IMU)
5.  Bluetooth
6.  File system
7.  Compression
    1.  Compressing data
    2.  Frameutils example
8.  Time functions
9.  System functions

___

### Display

The display engine allows drawing of text, sprites and vectors. These elements can be layered atop one another simply in the order they are called, and then be displayed in one go using the `show()` function.

The Frame display is capable of rendering up to 16 colors at one time. These colors are preset by default, however each color can be overridden.

The vector command is not yet implemented.

| API                                                                                                           | Description |
| --- | --- |
| `frame.display.text(string, x, y, {color='WHITE', spacing=4})` | Prints the given `string` to the display at `x` and `y`. A `color` can optionally be provided to print the text in one of the 16 palette colors. `spacing` can optionally be provided to adjust the character spacing of the printed text. Details below |
| `frame.display.bitmap(x, y, width, color_format, palette_offset, data)` | Prints raw bitmap data to the display at coordinates `x` and `y`. `width` should be the width of the bitmap. `color_format` should be either `2`, `4`, or `16`. `palette_offset` offsets the colors indexed from the palette. `data` should be a string containing the bitmap data. Details below |
| `frame.display.vector()` | _Coming soon_ |
| `frame.display.show()` | Shows the drawn objects on the display. See below for more details on how buffering works. |

#### Buffering

The Frame display has 2 buffers. All writing to the display via `frame.display.text()`, `frame.display.bitmap()`, etc write to an off-screen buffer and are not visible. This allows you to write multiple actions at once. When you have completed drawing and want to show it to the user, call `frame.display.show()` which will display the buffered graphics and clear a new off-screen buffer for whatever you want to draw next.

#### Displaying Text

`frame.display.text(string, x, y, {color='WHITE', spacing=4})` prints the given `string` to the display with its upper-left at position `x, y`. All positions are 1-indexed, so possible values for `x` are between 1 and 640, and possible values for `y` are between 1 and 400. Text is variable width, not fixed-width. Currently it is not possible to modify the font or font size. There is no word-wrapping performed automatically.

A `color` can optionally be provided to print the text in one of the 16 palette colors. `spacing` can optionally be provided to adjust the character spacing of the printed text. The final argument may be omitted, in which case the default color of `WHITE` and spacing of 4 is used.

```
<span>-- Display 'Hello world' at x = 50 and y = 100</span>
<span>frame</span><span>.</span><span>display</span><span>.</span><span>text</span><span>(</span><span>'Hello world'</span><span>,</span> <span>50</span><span>,</span> <span>100</span><span>)</span>
<span>-- Display 'Goodbye world' in red and with more spacing</span>
<span>frame</span><span>.</span><span>display</span><span>.</span><span>text</span><span>(</span><span>'Goodbye world'</span><span>,</span> <span>50</span><span>,</span> <span>200</span><span>,</span> <span>{</span><span>color</span><span>=</span><span>'RED'</span><span>,</span> <span>spacing</span><span>=</span><span>16</span><span>})</span>
<span>-- Show the buffered text</span>
<span>frame</span><span>.</span><span>display</span><span>.</span><span>show</span><span>()</span>
```

#### Sprite Engine

`frame.display.bitmap(x, y, width, color_format, palette_offset, data)` allows manually drawing to the screen. The bitmap is positioned with its upper-left at `x, y` with width `width` and the height automatically determined by the length of the data. `color_format` can be one of 2, 4, or 16. By including less colors in your bitmap, you can fit more pixels into a smaller data string. `palette_offset` is a number between 0 and 15, where 0 means no offset.

The sprite engine in Frame is capable of quickly rendering bitmap data to anywhere on the screen. Sprite data can be stored in one of three different color formats. 2 color, 4 color, and 16 color. 2 color mode will only use the first two colors in the color palette, but allows storing 8 pixels per byte of sprite data. 4 color will use the first four colors in the palette, but requires twice as much data per pixel. Finally, 16 color mode allows accessing the entire color palette, but requires 4 bits per pixel. Pixel data in Lua is simply represented as a long string of all the pixels. The `width` parameter tells the sprite engine when to move to the next line when rendering out each pixel from the string.

Each pixel represented by the pixel data simply indexes one of the colors from the color palette. For 2 color mode, a bit (pixel) value of `1` will print a pixel of color `WHITE`. The internal font glyphs used by the `text()` function are essentially all 2 color sprites.

Palette Offset Example

To achieve different color drawings, the `palette_offset` feature is used. This value offsets how the colors are indexed during the render. Using the same 2 color example as above, but combined with a `palette_offset` value of 3, now indexes `PINK` instead of `WHITE` for all pixel values of `1`. The same works for all the other color modes. Note that the `VOID` color is never shifted. A pixel value of `0` will always index `VOID`, no matter the `palette_offset`.

The example below shows how a single sprite can be shown in different colors using the `palette_offset` feature. Note how the color palette has been adjusted to repeat the same colors after index 5, but with red changed to green.

The `data` is a lua string which is just an array of bytes, but with multiple pixels packed in each byte based on the number of colors. When drawing, the `palette_offset` is added to palette index (wrapping around at 16).

Data String Detailed Examples

```
Data as Lua string:
"\x01\xFE"

Data as bits:
00000001 11111110

If num_color = 16, then this maps to 4 pixels:
as bits:        0000 0001  1111 1110
palette index:     0    1    15   14

If num_color = 4, then this maps to 8 pixels:
as bits:        00 00 00 01  11 11 11 10
palette index:   0  0  0  1   3  3  3  2

If num_color = 2, then this maps to 16 pixels:
as bits:        0 0 0 0 0 0 0 1  1 1 1 1 1 1 1 0
palette index:  0 0 0 0 0 0 0 1  1 1 1 1 1 1 1 0
```

For example, to draw a red rectangle at position x = 100, y = 50, with width = 32 and height = 15:

```
<span>frame</span><span>.</span><span>display</span><span>.</span><span>bitmap</span><span>(</span><span>100</span><span>,</span> <span>50</span><span>,</span> <span>32</span><span>,</span> <span>2</span><span>,</span> <span>3</span><span>,</span> <span>string.rep</span><span>(</span><span>"\xFF"</span><span>,</span> <span>32</span> <span>/</span> <span>8</span> <span>*</span> <span>16</span><span>))</span>
                     <span>|</span>    <span>|</span>   <span>|</span>   <span>|</span>  <span>|</span>   <span>|</span><span>"Since each byte maps to 8 pixels, we divide the width 32 by 8"</span>
                     <span>|</span>    <span>|</span>   <span>|</span>   <span>|</span>  <span>|</span>   <span>\</span><span>"and multiply by the height of 16 to get the total data length."</span>
                     <span>|</span>    <span>|</span>   <span>|</span>   <span>|</span>  <span>|</span>    <span>"We fill that data with "</span><span>\</span><span>xFF</span><span>" (aka 255), to fill all pixels."</span>
                     <span>|</span>    <span>|</span>   <span>|</span>   <span>|</span>  <span>\</span><span>"the 3rd color in the standard palette is red"</span>
                     <span>|</span>    <span>|</span>   <span>|</span>   <span>\</span><span>"we only need 2 color options, to pack 8 pixels per byte"</span>
                     <span>|</span>    <span>|</span>   <span>\</span><span>"the width is 32, after which it rolls onto the next line"</span>
                     <span>|</span>    <span>\</span><span>"top at 50px"</span>
                     <span>\</span><span>"left at 100px"</span>
```

#### Color Palette

The Frame display is capable of rendering up to 16 colors at a time. Each color is indexed 0-15, and are named in the following order: `VOID`, `WHITE` ,`GREY` ,`RED` ,`PINK` ,`DARKBROWN` ,`BROWN` ,`ORANGE` ,`YELLOW` ,`DARKGREEN` ,`GREEN` ,`LIGHTGREEN` ,`NIGHTBLUE` ,`SEABLUE` ,`SKYBLUE` or `CLOUDBLUE`. `VOID` represents the background (normally black) color. Each color can be overridden per frame to any 10bit YCbCr color from the colorspace shown below. This space contains a total of 1024 possible colors.

Frame display YCbCr colorspace

The `assign_color()` function simplifies color selection by allowing the user to enter regular 24bit RGB values which are internally converted to the YCbCr colorspace. Note however that the color actually rendered will be rounded to one of the above colors.

Here’s the default palette, as names and indices:

<table><tbody><tr><td data-darkreader-inline-bgcolor=""><span color="White" data-darkreader-inline-color="">#0<br>VOID</span></td><td data-darkreader-inline-bgcolor=""><span color="Black" data-darkreader-inline-color="">#1<br>WHITE</span></td><td data-darkreader-inline-bgcolor=""><span color="Black" data-darkreader-inline-color="">#2<br>GRAY</span></td><td data-darkreader-inline-bgcolor=""><span color="Black" data-darkreader-inline-color="">#3<br>RED</span></td><td data-darkreader-inline-bgcolor=""><span color="Black" data-darkreader-inline-color="">#4<br>PINK</span></td><td data-darkreader-inline-bgcolor=""><span color="White" data-darkreader-inline-color="">#5<br>DARKBROWN</span></td><td data-darkreader-inline-bgcolor=""><span color="Black" data-darkreader-inline-color="">#6<br>BROWN</span></td><td data-darkreader-inline-bgcolor=""><span color="Black" data-darkreader-inline-color="">#7<br>ORANGE</span></td></tr><tr><td data-darkreader-inline-bgcolor=""><span color="Black" data-darkreader-inline-color="">#8<br>YELLOW</span></td><td data-darkreader-inline-bgcolor=""><span color="White" data-darkreader-inline-color="">#9<br>DARKGREEN</span></td><td data-darkreader-inline-bgcolor=""><span color="Black" data-darkreader-inline-color="">#10<br>GREEN</span></td><td data-darkreader-inline-bgcolor=""><span color="Black" data-darkreader-inline-color="">#11<br>LIGHTGREEN</span></td><td data-darkreader-inline-bgcolor=""><span color="White" data-darkreader-inline-color="">#12<br>NIGHTBLUE</span></td><td data-darkreader-inline-bgcolor=""><span color="White" data-darkreader-inline-color="">#13<br>SEABLUE</span></td><td data-darkreader-inline-bgcolor=""><span color="Black" data-darkreader-inline-color="">#14<br>SKYBLUE</span></td><td data-darkreader-inline-bgcolor=""><span color="Black" data-darkreader-inline-color="">#15<br>CLOUDBLUE</span></td></tr></tbody></table>

#### Low-Level Display Commands

| Low level functions                                                         | Description |
| --- | --- |
| `frame.display.assign_color(color, r, g, b)` | Changes the rendered color in slot `color` with a new color given by the components `r`, `g,` and `b`. Valid options for `color` are: `VOID`, `WHITE` ,`GREY` ,`RED` ,`PINK` ,`DARKBROWN` ,`BROWN` ,`ORANGE` ,`YELLOW` ,`DARKGREEN` ,`GREEN` ,`LIGHTGREEN` ,`NIGHTBLUE` ,`SEABLUE` ,`SKYBLUE` or `CLOUDBLUE`. Note that changing the `VOID` color will change the rendered background color of the display. The RGB components are internally converted to a 10bit YCbCr value that represents the true colorspace of the display. There may therefore be rounding errors for certain RGB combinations |
| `frame.display.assign_color_ycbcr(color, y, cb, cr)` | Same as above, however the `y`, `cb`, and `cr` represent the true 10bit colorspace of the display. Each component has a range of 4, 3, and 3 bits respectively |
| `frame.display.set_brightness(brightness)` | Sets the brightness of the display. Valid options for `brightness` are `-2`, `-1`, `0`, `1`, or `2`. Note that higher brightness levels increase the likelihood of burn-in if static pixels are shown for long periods of time on the display |
| `frame.display.write_register(register, value)` | Allows hacking of the display registers. `register` and `value` should both be 8bit values |
| `frame.display.power_save(enable)` | When `enable` is set to `true`, the display will enter power saving mode and turn off. This feature may be used to save battery life when the display is not needed. Graphics rendering commands may still be issued and will be shown as normal when `enable` is set back to false. Note that the display will sleep and wake up automatically when using `frame.sleep()` so this function isn’t needed in most cases |

___

### Camera

The camera capability of Frame allows for capturing and downloading single JPEG images over Bluetooth. The sensor’s full resolution is 1280x720 pixels in portrait orientation, however only square images up to 720x720 pixels can be captured at a time. The user can select which portion of the sensor’s 1280 length is captured using the `pan` control. Additionally, the resolution of the capture can be cropped down to 100x100 pixels by using the `resolution` function. To control file size and download speed, the `quality` option can be used to adjust the JPEG compression quality.

| API                                                                        | Description |
| --- | --- |
| `frame.camera.capture{resolution=512, quality='VERY_HIGH', pan=0}` | Captures a single image from the camera. The `resolution` option may be any even number between 100 and 720. The `pan` option can be any number between -140 and 140, where 0 represents a centered image. `quality` can be either `VERY_LOW`, `LOW`, `MEDIUM`, `HIGH`, or `VERY_HIGH`. Higher quality and resolution images will increase the image file size. |
| `frame.camera.image_ready()` | Following a capture, polling `image_ready()` will return `false` while the image is being captured. Once `image_ready()` returns true, the image can be safely read out |
| `frame.camera.read(num_bytes)` | Reads out a number of bytes from the camera capture memory as a byte string. Once all bytes have been read, `nil` will be returned. Note that reading data out too quickly following a capture may return corrupted data. The `image_ready()` function should be used to ensure the image is ready before reading anything out |
| `frame.camera.read_raw(num_bytes)` | The same as `camera.read()` however skips the JPEG header data and only returns the image data and final JPEG footer. This function can be used to speed up data transfer since the JPEG header between images is the same if the `resolution` and `quality` values remain unchanged. It’s first recommended to read an image normally using `camera.read()` and then extract the JPEG header (always the first 623 bytes) so that it can be used for subsequent `camera.read_raw()` operations |
| `frame.camera.auto{metering='AVERAGE', exposure=0.18, exposure_speed=0.5, shutter_limit=800, analog_gain_limit=248, white_balance_speed=0.5}` | Runs the automatic exposure, gain and white balance algorithm. This function must be called every 100ms for the best performance. `metering` can be one of three modes, `SPOT`, `CENTER_WEIGHTED`, or `AVERAGE`. `exposure` can be a value between `0.0` and `1.0` where lower values will return darker images, and higher values will return brighter images. `exposure_speed` and `white_balance_speed` control how aggressively the algorithm will attempt to correct for the exposure and white balance respectively. Higher values will result in a faster convergence, but may create additional overshoot or oscillation of the image brightness or color balance. `shutter_limit` and `analog_gain_limit` will cap the maximum shutter and gain values. Reducing these values may be used to reduce motion blur and image noise respectively. Shutter is always prioritized over gain. When going into darker scenes, the shutter will first increase, and once it has reached the `shutter_limit`, the gain will then begin to increase. Likewise, when going into brighter scenes, the gain will decrease to zero first, and only then will the shutter decrease. This function returns a table of statistics related to the scene and current algorithm state. Many aspects of shutter, gain and white balance may be monitored by reading the table. |

#### Example

```
<span>local</span> <span>mtu</span> <span>=</span> <span>frame</span><span>.</span><span>bluetooth</span><span>.</span><span>max_length</span><span>()</span>

<span>-- Auto expose for 3 seconds</span>
<span>for</span> <span>_</span><span>=</span><span>1</span><span>,</span> <span>30</span> <span>do</span>
    <span>frame</span><span>.</span><span>camera</span><span>.</span><span>auto</span><span>{}</span>
    <span>frame</span><span>.</span><span>sleep</span><span>(</span><span>0</span><span>.</span><span>1</span><span>)</span>
<span>end</span>

<span>-- Capture an image using default settings</span>
<span>frame</span><span>.</span><span>camera</span><span>.</span><span>capture</span><span>{}</span>

<span>-- Wait for the image to be ready</span>
<span>while</span> <span>frame</span><span>.</span><span>camera</span><span>.</span><span>image_ready</span><span>()</span> <span>==</span> <span>false</span> <span>do</span>
    <span>-- do nothing</span>
<span>end</span>

<span>while</span> <span>true</span> <span>do</span>
    <span>local</span> <span>data</span> <span>=</span> <span>frame</span><span>.</span><span>camera</span><span>.</span><span>read</span><span>(</span><span>mtu</span><span>)</span>
    <span>if</span> <span>data</span> <span>==</span> <span>nil</span> <span>then</span>
        <span>break</span>
    <span>end</span>
    <span>frame</span><span>.</span><span>bluetooth</span><span>.</span><span>send</span><span>(</span><span>data</span><span>)</span>
<span>end</span>
```

#### Low-Level Camera Commands

| Low level functions                                        | Description |
| --- | --- |
| `frame.camera.set_exposure(shutter)` | Sets the shutter value manually. Note that `camera.auto{}` will override this value. `shutter` can be a value between `4` and `16383` |
| `frame.camera.set_gain(gain)` | Sets the gain value manually. Note that `camera.auto{}` will override this value. `gain` can be a value between `1` and `248` |
| `frame.camera.set_white_balance(r, g, b)` | Sets the digital gains of the R, G and B channels for fine tuning white balance. `r`, `g` and `b` can be values between `0` and `1023` |
| `frame.camera.write_register(address, value)` | Allows for hacking the camera’s internal registers. `address` can be any 16-bit register address of the camera, and `value` any 8-bit value to write to that address |
| `frame.camera.read_register(address, value)` | Reads back a value from the camera’s internal registers. `address` can be any 16-bit register address of the camera. The 8bit value of the register will be returned |
| `frame.camera.power_save(enable)` | When `enable` is set to `true`, the camera will enter power saving mode and turn off. This feature may be used to save battery life when the camera is not needed. When this mode is enabled, the only available camera functions will be `camera.read()` and `camera.read_raw()`. Note that the camera will sleep and wake up automatically when using `frame.sleep()` so this function isn’t needed in most cases |

___

### Microphone

The microphone on Frame allows for streaming audio to a host device in real-time. Transfers are limited by the Bluetooth bandwidth which is typically around 40kBps under good signal conditions. The audio bitrate for a given `sample_rate` and `bit_depth` is: `sample_rate * bit_depth / 8` bytes per second. An internal 32k buffer automatically compensates for additional tasks that might otherwise briefly block Bluetooth transfers. If this buffer limit is exceeded however, then discontinuities in audio might occur.

| API                                                                                             | Description |
| --- | --- |
| `frame.microphone.start{sample_rate=8000, bit_depth=8}` | Starts streaming mic data into the internal 32k buffer. `sample_rate` may be either `8000`, or `16000`, and `bit_depth` may be either `8`, `16` |
| `frame.microphone.stop()` | Stops the stream |
| `frame.microphone.read(num_bytes)` | Reads out a number of bytes from the buffer. If all bytes have been read, but streaming is still active, an empty string will be returned. Once the stream has been stopped and all bytes have been read, then `nil` will be returned |

#### Example

```
<span>local</span> <span>mtu</span> <span>=</span> <span>frame</span><span>.</span><span>bluetooth</span><span>.</span><span>max_length</span><span>()</span>

<span>frame</span><span>.</span><span>microphone</span><span>.</span><span>start</span><span>{</span><span>sample_rate</span><span>=</span><span>16000</span><span>}</span> <span>-- Start streaming at 16kHz 8bit</span>

<span>-- Streams forever</span>
<span>while</span> <span>true</span> <span>do</span>
    <span>data</span> <span>=</span> <span>frame</span><span>.</span><span>microphone</span><span>.</span><span>read</span><span>(</span><span>mtu</span><span>)</span>

    <span>-- Calling frame.microphone.stop() will allow this to break the loop</span>
    <span>if</span> <span>data</span> <span>==</span> <span>nil</span> <span>then</span>
        <span>break</span>
    <span>end</span>

    <span>-- If there's data to send then ... </span>
    <span>if</span> <span>data</span> <span>~=</span> <span>''</span> <span>then</span>
        <span>-- Try to send the data as fast as possible</span>
        <span>while</span> <span>true</span> <span>do</span>
            <span>-- If the Bluetooth is busy, this simply tries again until it gets through</span>
            <span>if</span> <span>(</span><span>pcall</span><span>(</span><span>frame</span><span>.</span><span>bluetooth</span><span>.</span><span>send</span><span>,</span> <span>data</span><span>))</span> <span>then</span>
                <span>break</span>
            <span>end</span>
        <span>end</span>
    <span>end</span>
<span>end</span>
```

___

### Motion sensor (IMU)

The IMU API allows reading both accelerometer and compass data, as well as assigning a callback function for tap gestures.

The tap gesture will always wake up Frame from `frame.sleep()`.

| API | Description |
| --- | --- |
| `frame.imu.direction()` | Returns a table containing the `roll`, `pitch` and `heading` angles of the wearer’s head position |
| `frame.imu.tap_callback(handler)` | Assigns a callback to the tap gesture. `handler` must be a function, or can be `nil` to deactivate the callback |

| Low level functions | Description |
| --- | --- |
| `frame.imu.raw()` | Returns a table of the raw `accelerometer` and `compass` measurements. Each containing a table with `x`, `y`, and `z` values |

#### Example

```
<span>print</span><span>(</span><span>frame</span><span>.</span><span>imu</span><span>.</span><span>direction</span><span>()[</span><span>'pitch'</span><span>])</span> <span>-- Prints the angle of the wearer's head (up or down)</span>

<span>function</span> <span>tapped</span><span>()</span> <span>-- Prints 'tapped' whenever the user taps the side of their Frame</span>
    <span>print</span><span>(</span><span>'tapped'</span><span>)</span>
<span>end</span>

<span>frame</span><span>.</span><span>imu</span><span>.</span><span>tap_callback</span><span>(</span><span>tapped</span><span>)</span>
```

___

### Bluetooth

The Bluetooth API allows for sending and receiving raw byte data over Bluetooth. For a full description of how this can be used, check out the Talking to the Frame over Bluetooth page.

| API | Description |
| --- | --- |
| `frame.bluetooth.address()` | Returns the device MAC address as a 17 character string. E.g. `4E:87:B5:0C:64:0F` |
| `frame.bluetooth.receive_callback(handler)` | Assigns a callback to handle received Bluetooth data. `handler` must be a function, or can be `nil` to deactivate the callback |
| `frame.bluetooth.max_length()` | Returns the maximum length of data that can be sent or received in a single transfer |
| `frame.bluetooth.send(data)` | Sends data to the host device. `data` must be a string, but can contain byte values including 0x00 values anywhere in the string. The total length of the string must be less than or equal to `frame.bluetooth.max_length()` |

#### Example

```
<span>function</span> <span>get_data</span><span>(</span><span>data</span><span>)</span> <span>-- Called every time byte data arrives to Frame</span>
    <span>print</span><span>(</span><span>data</span><span>)</span>
<span>end</span>

<span>frame</span><span>.</span><span>bluetooth</span><span>.</span><span>receive_callback</span><span>(</span><span>get_data</span><span>)</span>

<span>frame</span><span>.</span><span>bluetooth</span><span>.</span><span>send</span><span>(</span><span>'\x10\x12\x00\xFF'</span><span>)</span> <span>-- Sends the bytes: 0x10, 0x12, 0x00, 0xFF to the host</span>
```

___

### File system

The file system API allows for writing and reading files to Frame’s non-volatile storage. These can include executable Lua scripts, or other user files.

| API                                                        | Description |
| --- | --- |
| `frame.file.open(filename, mode)` | Opens a file and returns a file object. `filename` can be any name, and `mode` can be either `'read'`, `'write'`, or `'append'` |
| `frame.file.remove(name)` | Removes a file or directory of given `name` |
| `frame.file.rename(name, new_name)` | Renames a file or directory of given `name` to `new_name` |
| `frame.file.listdir(directory)` | Lists all files in the directory path given. E.g. `'/'` for the filesystem root directory. The list is returned as a table with `name`, `size`, and `type` |
| `frame.file.mkdir(pathname)` | Creates a new directory with the given `pathname` |
| `f:read(*num_bytes)` | Reads a number of bytes from a file. If no argument is given, the whole line is returned |
| `f:write(data)` | Writes data to the file. `data` must be a string and can contain any byte data |
| `f:close()` | Closes the file. It is important to close files once done writing, otherwise they may become corrupted |

#### Tips

-   On many online Lua guides, the examples allow `'r'`, `'w'`, or `'a'` as shorthand for `'read'`, `'write'`, or `'append'`, however Frame does not support that. You need to spell out the whole word.
-   GitHub Copilot and ChatGPT will always generate incorrect code like `file.read()` rather than the correct `f:read()`. Keep a close eye on the syntax.
-   `f:read()` reads until the end of the line, so you need to call it multiple times to get through the whole file. It will return `nil` when it has reached the end of the file.
-   There is no function to check if a file exists. Instead you can try to open the file for reading and see if it fails.

There is an open bug where `f:read(*num_bytes)` will not always respect the num\_bytes limit. Until that is resolved, your code should handle receiving up to 512 bytes at a time.

#### Example

```
<span>frame</span><span>.</span><span>file</span><span>.</span><span>mkdir</span><span>(</span><span>'/my_files'</span><span>)</span> <span>-- Make a new directory</span>

<span>f</span> <span>=</span> <span>frame</span><span>.</span><span>file</span><span>.</span><span>open</span><span>(</span><span>'/my_files/log.txt'</span><span>,</span> <span>'write'</span><span>)</span> <span>-- Create a new file (or overwrite if it exists)</span>
<span>f</span><span>:</span><span>write</span><span>(</span><span>'Log:\n'</span><span>)</span>
<span>f</span><span>:</span><span>close</span><span>()</span>

<span>f</span> <span>=</span> <span>frame</span><span>.</span><span>file</span><span>.</span><span>open</span><span>(</span><span>'/my_files/log.txt'</span><span>,</span> <span>'append'</span><span>)</span> <span>-- Append two lines to the file</span>
<span>f</span><span>:</span><span>write</span><span>(</span><span>'Logged a new line\n'</span><span>)</span>
<span>f</span><span>:</span><span>close</span><span>()</span>

<span>f</span> <span>=</span> <span>frame</span><span>.</span><span>file</span><span>.</span><span>open</span><span>(</span><span>'/my_files/log.txt'</span><span>,</span> <span>'append'</span><span>)</span>
<span>f</span><span>:</span><span>write</span><span>(</span><span>'Logged another line\n'</span><span>)</span>
<span>f</span><span>:</span><span>close</span><span>()</span>

<span>-- Print the file contents (this simple version will fail if a line is longer than the MTU limit)</span>
<span>f</span> <span>=</span> <span>frame</span><span>.</span><span>file</span><span>.</span><span>open</span><span>(</span><span>'/my_files/log.txt'</span><span>,</span> <span>'read'</span><span>)</span>
<span>while</span> <span>true</span> <span>do</span>
    <span>local</span> <span>line</span> <span>=</span> <span>f</span><span>:</span><span>read</span><span>()</span>
    <span>if</span> <span>line</span> <span>==</span> <span>nil</span> <span>then</span>
        <span>break</span>
    <span>end</span>
    <span>print</span><span>(</span><span>line</span><span>)</span>
<span>end</span>
<span>f</span><span>:</span><span>close</span><span>()</span>

<span>-- Print all the files in the directory</span>
<span>local</span> <span>files</span> <span>=</span> <span>frame</span><span>.</span><span>file</span><span>.</span><span>listdir</span><span>(</span><span>'/my_files'</span><span>)</span>

<span>for</span> <span>index</span><span>,</span> <span>data</span> <span>in</span> <span>ipairs</span><span>(</span><span>files</span><span>)</span> <span>do</span>
    <span>print</span><span>(</span><span>index</span><span>)</span>

    <span>for</span> <span>key</span><span>,</span> <span>value</span> <span>in</span> <span>pairs</span><span>(</span><span>data</span><span>)</span> <span>do</span>
        <span>print</span><span>(</span><span>'</span><span>\t</span><span>'</span><span>,</span> <span>key</span><span>,</span> <span>value</span><span>)</span>
    <span>end</span>
<span>end</span>
```

___

### Compression

The compression library allows for working with LZ4 compressed data. Currently, only decompression is supported.

| API                                                                                     | Description |
| --- | --- |
| `frame.compression.decompress(data, block_size)` | Decompresses the given LZ4 compressed data in `data`. `block_size` is the block size value that was chosen when compressing the data |
| `frame.compression.process_function(function)` | Assigns a callback to handle the decompressed data. `function` must be a function, or can be `nil` to deactivate the callback. The function will receive the decompressed data with a length of `block_size` and will be called several times until all the data has been decompressed |

#### Example

```
<span>-- Decompression function</span>
<span>function</span> <span>decomp_func</span><span>(</span><span>data</span><span>)</span>
    <span>print</span><span>(</span><span>data</span><span>)</span> <span>-- Print the decompressed data</span>
<span>end</span>

<span>-- Register the decompression function</span>
<span>frame</span><span>.</span><span>compression</span><span>.</span><span>process_function</span><span>(</span><span>decomp_func</span><span>)</span>

<span>-- Function to handle the compressed data received from Bluetooth</span>
<span>function</span> <span>ble_func</span><span>(</span><span>data</span><span>)</span>    
    <span>frame</span><span>.</span><span>compression</span><span>.</span><span>decompress</span><span>(</span><span>data</span><span>,</span> <span>1024</span><span>)</span>
<span>end</span>

<span>-- Register the Bluetooth receive callback</span>
<span>frame</span><span>.</span><span>bluetooth</span><span>.</span><span>receive_callback</span><span>(</span><span>ble_func</span><span>)</span>
```

#### Compressing data

The LZ4 utility on the host machine can be used to compress data for sending to Frame.

```
lz4 <span>-9</span> <span>-B1024</span> input.txt output.lz4
```

The `-9` flag sets the compression level to 9, and the `-B1024` flag sets the block size to 1024 bytes. Some experimentation may be needed to find the optimal compression level and block size for a given use case.

The bytes in output.lz4 can be sent to Frame over the data channel, or saved to a file on Frame’s filesystem for use later. Note that decompressing from the filesystem is currently not supported. The data must be loaded into a Lua string variable first before decompressing.

#### Frameutils example

The following example demonstrates how to decompress data using `frameutils`

```
<span>import</span> <span>asyncio</span>
<span>from</span> <span>frameutils</span> <span>import</span> <span>Bluetooth</span>


<span>async</span> <span>def</span> <span>main</span><span>():</span>

    <span>b</span> <span>=</span> <span>Bluetooth</span><span>()</span>

    <span>await</span> <span>b</span><span>.</span><span>connect</span><span>(</span><span>print_response_handler</span><span>=</span><span>lambda</span> <span>s</span><span>:</span> <span>print</span><span>(</span><span>s</span><span>))</span>

    <span># Upload the Lua script
</span>    <span>lua_script</span> <span>=</span> <span>"""
        function decomp_func(data)
            print(data)
        end

        frame.compression.process_function(decomp_func)

        function ble_func(data)    
            frame.compression.decompress(data, 1024)
        end

        frame.bluetooth.receive_callback(ble_func)
    """</span>

    <span>await</span> <span>b</span><span>.</span><span>upload_file</span><span>(</span><span>lua_script</span><span>,</span> <span>"main.lua"</span><span>)</span>
    <span>await</span> <span>b</span><span>.</span><span>send_reset_signal</span><span>()</span>

    <span>await</span> <span>asyncio</span><span>.</span><span>sleep</span><span>(</span><span>1</span><span>)</span>

    <span># Send the compressed data. Here the total size of the data is is pretty small,
</span>    <span># but usually you would want to split the data into MTU sized chunks and stitch
</span>    <span># them together on the device side before decompressing.
</span>    <span>compressed_data</span> <span>=</span> <span>bytearray</span><span>(</span>
        <span>b</span><span>"</span><span>\x04\x22\x4d\x18\x64\x40\xa7\x6f\x00\x00\x00\xf5\x3d\x48\x65\x6c\x6c\x6f\x21\x20\x49\x20\x77\x61\x73\x20\x73\x6f\x6d\x65\x20\x63\x6f\x6d\x70\x72\x65\x73\x73\x65\x64\x20\x64\x61\x74\x61\x2e\x20\x49\x6e\x20\x74\x68\x69\x73\x20\x63\x61\x73\x65\x2c\x20\x73\x74\x72\x69\x6e\x67\x73\x20\x61\x72\x65\x6e\x27\x74\x20\x70\x61\x72\x74\x69\x63\x75\x6c\x61\x72\x6c\x79\x3b\x00\xf1\x01\x69\x62\x6c\x65\x2c\x20\x62\x75\x74\x20\x73\x70\x72\x69\x74\x65\x49\x00\xa0\x20\x77\x6f\x75\x6c\x64\x20\x62\x65\x2e\x00\x00\x00\x00\x5f\xd0\xa3\x47</span><span>"</span>
    <span>)</span>

    <span>await</span> <span>b</span><span>.</span><span>send_data</span><span>(</span><span>compressed_data</span><span>)</span>

    <span>await</span> <span>b</span><span>.</span><span>send_break_signal</span><span>()</span>
    <span>await</span> <span>b</span><span>.</span><span>disconnect</span><span>()</span>


<span>asyncio</span><span>.</span><span>run</span><span>(</span><span>main</span><span>())</span>
```

___

### Time functions

The time functions allow for accurate timekeeping on Frame. The `utc()` function can be used to set the time on Frame using a UTC timestamp. Frame will then keep the time until it’s put back onto charge, or placed into deep sleep using `frame.sleep()`. The `date()` function can be used to return a human readable time and date.

| API | Description |
| --- | --- |
| `frame.time.utc(*timestamp)` | Sets or gets the current time. `timestamp` can be provided as a UTC timestamp to set the internal real-time clock. If no argument is given, Frame’s current time is returned as a UTC timestamp. If no timestamp was initially set, this number will simply represent the powered on time of Frame in seconds. |
| `frame.time.zone(*offset)` | Sets or gets the timezone offset. If `offset` is given, the timezone will be set, otherwise the currently set timezone is returned. The format of the timezone should be a string, e.g. ‘-7:00’, or ‘5:30’. |
| `frame.time.date(*timestamp)` | Returns a table containing `second`, `minute`, `hour`, `day`, `month`, `year`, `weekday`, `day of year`, and `is daylight saving`. If the optional `timestamp` argument is given, that timestamp will be used to calculate the corresponding date. |

#### Example

```
<span>frame</span><span>.</span><span>time</span><span>.</span><span>utc</span><span>(</span><span>1708551112</span><span>)</span> <span>-- Set the current time to Wed Feb 21 2024 21:31:52 UTC</span>
<span>frame</span><span>.</span><span>time</span><span>.</span><span>zone</span><span>(</span><span>'-7:00'</span><span>)</span> <span>-- Set the timezone to pacific time</span>

<span>local</span> <span>time_now</span> <span>=</span> <span>frame</span><span>.</span><span>time</span><span>.</span><span>date</span><span>()</span>

<span>-- print the local time and date</span>
<span>print</span><span>(</span><span>time_now</span><span>[</span><span>'hour'</span><span>])</span>
<span>print</span><span>(</span><span>time_now</span><span>[</span><span>'minute'</span><span>])</span>
<span>print</span><span>(</span><span>time_now</span><span>[</span><span>'month'</span><span>])</span>
<span>print</span><span>(</span><span>time_now</span><span>[</span><span>'day'</span><span>])</span>
```

___

### System functions

The system API provides miscellaneous functions such as `sleep` and `update`. It also contains some low level functions which are handy for developing apps and custom FPGA images.

| API | Description |
| --- | --- |
| `frame.HARDWARE_VERSION` | Returns the current hardware version as a string. E.g. `'Frame'` |
| `frame.FIRMWARE_VERSION` | Returns the current firmware version as a 12 character string. E.g. `'v24.046.1546'` |
| `frame.GIT_TAG` | Returns the current firmware git tag as a 7 character string. E.g. `'4a6ea0b'` |
| `frame.battery_level()` | Returns the battery level as a percentage between `1` and `100` |
| `frame.sleep(*seconds)` | Sleeps for a given number of seconds. `seconds` can be a decimal number such as `1.25`. If no argument is given, Frame will go to sleep until a tap gesture wakes it up |
| `frame.update()` | Reboots Frame into the firmware bootloader. Check the firmware updates section of the Building Apps page to see how this is used |

| Low level functions                             | Description |
| --- | --- |
| `frame.stay_awake(enable)` | Prevents Frame from going to sleep while it’s docked onto the charging cradle. This can help during development where continuous power is needed, however may degrade the display or cause burn-in if used for extended periods of time |
| `frame.fpga_read(address, num_bytes)` | Reads a number of bytes from the FPGA at the given address |
| `frame.fpga_write(address, data)` | Writes data to the FPGA at a given address. `data` can be a string containing any byte values |

___

## AR Studio

While the main way you’ll use Lua on Frame is via host apps that send it over Bluetooth, it can be helpful while learning to directly write and execute Lua code on Frame using the AR Studio extension for VSCode.

AR studio is an extension for VSCode designed for both Frame and Monocle. It lets you quickly start writing apps and testing them on your device. Download it here, or simply search for Brilliant AR Studio from within the VSCode extensions tab.

Once you have AR Studio installed, you can try an example using the following steps:

1.  Open the Command Palette using **Ctrl-Shift-P** (or **Cmd-Shift-P** on Mac)
    
2.  Type and select **Brilliant AR Studio: Initialize new project folder**
    
3.  Select Frame, and give your project a name
    
4.  Copy the following example code into `main.lua`:
    
    ```
     <span>function</span> <span>change_text</span><span>()</span>
         <span>frame</span><span>.</span><span>display</span><span>.</span><span>clear</span><span>()</span>
         <span>frame</span><span>.</span><span>display</span><span>.</span><span>text</span><span>(</span><span>'Frame tapped!'</span><span>,</span> <span>50</span><span>,</span> <span>100</span><span>)</span>
         <span>frame</span><span>.</span><span>display</span><span>.</span><span>show</span><span>()</span>
     <span>end</span>
    
     <span>frame</span><span>.</span><span>imu</span><span>.</span><span>tap_callback</span><span>(</span><span>change_text</span><span>)</span>
     <span>frame</span><span>.</span><span>display</span><span>.</span><span>clear</span><span>()</span>
     <span>frame</span><span>.</span><span>display</span><span>.</span><span>text</span><span>(</span><span>'Tap the side of Frame'</span><span>,</span> <span>50</span><span>,</span> <span>100</span><span>)</span>
     <span>frame</span><span>.</span><span>display</span><span>.</span><span>show</span><span>()</span>
    ```
    
5.  Save the file, and press the **Connect** button
    
6.  VSCode will then connect to your Frame (You may need to accept pairing if you aren’t already paired)
    
7.  Right click on `main.lua` and select **Upload to device**
    
8.  Your app should now be running on Frame
    

___