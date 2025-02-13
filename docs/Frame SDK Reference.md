___

The most common structure is to build an iOS or Android mobile app which uses our SDKs to communicate with the Frame over Bluetooth. Your app is in control and uses Frame as an accessory, with the Lua and BTLE details mostly abstracted away for you.

## Supported Platforms

-   Python from a Mac, Linux, or Windows computer
-   Swift from a Mac or iOS device
-   Kotlin from Android
-   Flutter for mobile (iOS and Android)
-   React Native for mobile (and computer?)

For each section below, you may expand the platform you are targeting to see details specific to that platform, including function signatures and examples.

### Status

The Python SDK is feature-complete, but will be updated continuously as the underlying platform capabilities change.

The Flutter SDK is an early preview and may be incomplete or unstable. Please report any issues to us on discord and we will fix them ASAP.

___

-   Installation
    -   Python
    -   Flutter
-   Basic Communication
    -   Python SDK Basics
    -   Flutter SDK Basics
    -   Sending Lua to the Frame
    -   Evaluating a Lua expression on the Frame
-   System Functions
    -   Get Battery Level
    -   Delay
    -   Sleep
    -   Stay Awake
    -   Send Break Signal
    -   Send Reset Signal
    -   Run On Wake
    -   Set Print Debugging (Python)
    -   Wait For Data
-   Filesystem
    -   Write File
    -   Read File
    -   Delete File
    -   File Exists?
-   Camera
    -   Take Photo
    -   Save Photo
-   Display
    -   Write Text
    -   Show Text
    -   Scroll Text
    -   Draw Rectangle
    -   Draw Rectangle Filled
    -   Additional Display Helpers
-   Microphone
    -   Record Audio
    -   Save Audio File
    -   Play Audio
    -   Sample Rate and Bit Depth
    -   Silence Threshold
-   Motion
    -   Get Direction
    -   Run On Tap
    -   Wait For Tap
-   Putting It All Together
    -   Python
    -   Flutter

___

## Installation

Installation of the SDK depends on the platform you are targeting. For this section and all sections below, expand the platform you are targeting to see details specific to that platform.

### Python

The `frame-sdk` library is available on PyPI.

Using \`frameutils\` for Direct Bluetooth Communication

#### Using `frameutils` for Direct Bluetooth Communication

The `frame-utilities-for-python` package is for low-level communication with both Frame and Monocle devices and is a thin wrapper around the bluetooth connection (making use of Bleak under the hood), plus some internal tools that are used in the firmware preparation process. The `frame-sdk` package is a higher-level SDK that provides a more convenient way for developers to build apps for Frame.

While this page mainly documents the high-level SDK functionality in `frame-sdk`, you can also use the `frameutils` library as a lower-level interface to directly communicate with Frame over Bluetooth.

```
<span>import</span> <span>asyncio</span>
<span>from</span> <span>frameutils</span> <span>import</span> <span>Bluetooth</span>

<span>async</span> <span>def</span> <span>main</span><span>():</span>
    <span>bluetooth</span> <span>=</span> <span>Bluetooth</span><span>()</span>
    <span>await</span> <span>bluetooth</span><span>.</span><span>connect</span><span>()</span>

    <span>print</span><span>(</span><span>await</span> <span>bluetooth</span><span>.</span><span>send_lua</span><span>(</span><span>"print('hello world')"</span><span>,</span> <span>await_print</span><span>=</span><span>True</span><span>))</span>
    <span>print</span><span>(</span><span>await</span> <span>bluetooth</span><span>.</span><span>send_lua</span><span>(</span><span>'print(1 + 2)'</span><span>,</span> <span>await_print</span><span>=</span><span>True</span><span>))</span>

    <span>await</span> <span>bluetooth</span><span>.</span><span>disconnect</span><span>()</span>

<span>asyncio</span><span>.</span><span>run</span><span>(</span><span>main</span><span>())</span>
```

### Flutter

The `frame_sdk` library is available on pub.dev.

```
flutter pub add frame_sdk
```

## Basic Communication

Where available, most Frame communication happens via async functions.

### Python SDK Basics

Make sure to `import asyncio` and only use Frame in async functions. The Frame class handles the connection for you, all you have to do is wrap any code in `async with Frame() as frame:` and then use that `frame` object to call any of the functions. Once that `frame` object goes out of scope (after the `with` statement or on an exception), the connection is automatically closed.

```
<span>import</span> <span>asyncio</span>
<span>from</span> <span>frame_sdk</span> <span>import</span> <span>Frame</span>


<span>async</span> <span>def</span> <span>main</span><span>():</span>
    <span># the with statement handles the connection and disconnection to Frame
</span>    <span>async</span> <span>with</span> <span>Frame</span><span>()</span> <span>as</span> <span>frame</span><span>:</span>
        <span>print</span><span>(</span><span>"connected"</span><span>)</span>
        <span># f is a connected Frame device, so you can call await f.&lt;whatever&gt;
</span>        <span># for example, let's get the current battery level
</span>        <span>print</span><span>(</span><span>f</span><span>"Frame battery: </span><span>{</span><span>await</span> <span>frame</span><span>.</span><span>get_battery_level</span><span>()</span><span>}</span><span>%"</span><span>)</span>

    <span># outside of the with statement, the connection is automatically closed
</span>    <span>print</span><span>(</span><span>"disconnected"</span><span>)</span>

<span># make sure you run it asynchronously
</span><span>asyncio</span><span>.</span><span>run</span><span>(</span><span>main</span><span>())</span>
```

### Flutter SDK Basics

Make sure to `import 'package:frame_sdk/frame_sdk.dart';`. You may also need to import `package:frame_sdk/bluetooth.dart`, `package:frame_sdk/display.dart`, `package:frame_sdk/camera.dart`, or `package:frame_sdk/motion.dart` to access types, enums, and constants.

At some point early in your app’s execution, you should call `BrilliantBluetooth.requestPermission();` to prompt the user to provide Bluetooth permission.

You can see an example Flutter usage in the package’s example page. Here’s a very simplified example:

```
<span>// other imports</span>
<span>import</span> <span>'package:frame_sdk/frame_sdk.dart'</span><span>;</span>

<span>void</span> <span>main</span><span>()</span> <span>{</span>
  <span>// Request bluetooth permission</span>
  <span>BrilliantBluetooth</span><span>.</span><span>requestPermission</span><span>();</span>
  <span>runApp</span><span>(</span><span>const</span> <span>MyApp</span><span>());</span>
<span>}</span>

<span>class</span> <span>MyApp</span> <span>extends</span> <span>StatefulWidget</span> <span>{</span>
  <span>const</span> <span>MyApp</span><span>({</span><span>super</span><span>.</span><span>key</span><span>});</span>

  <span>@override</span>
  <span>State</span><span>&lt;</span><span>MyApp</span><span>&gt;</span> <span>createState</span><span>()</span> <span>=</span><span>&gt;</span> <span>_MyAppState</span><span>();</span>
<span>}</span>

<span>class</span> <span>_MyAppState</span> <span>extends</span> <span>State</span><span>&lt;</span><span>MyApp</span><span>&gt;</span> <span>{</span>
  <span>late</span> <span>final</span> <span>Frame</span> <span>frame</span><span>;</span>

  <span>@override</span>
  <span>void</span> <span>initState</span><span>()</span> <span>{</span>
    <span>super</span><span>.</span><span>initState</span><span>();</span>
    <span>initPlatformState</span><span>();</span>
    <span>frame</span> <span>=</span> <span>Frame</span><span>();</span>

    <span>runExample</span><span>();</span>
  <span>}</span>

  <span>Future</span><span>&lt;</span><span>void</span><span>&gt;</span> <span>runExample</span><span>()</span> <span>async</span> <span>{</span>
    <span>// connect</span>
    <span>await</span> <span>frame</span><span>.</span><span>connect</span><span>();</span>
    <span>// Check if connected</span>
    <span>print</span><span>(</span><span>"Connected: </span><span>${frame.isConnected}</span><span>"</span><span>);</span>
    <span>// Get battery level</span>
    <span>int</span> <span>batteryLevel</span> <span>=</span> <span>await</span> <span>frame</span><span>.</span><span>getBatteryLevel</span><span>();</span>
    <span>print</span><span>(</span><span>"Frame battery: </span><span>$batteryLevel</span><span>%"</span><span>);</span>

    <span>// ... continue here ...</span>
  <span>}</span>

  <span>// Future&lt;void&gt; initPlatformState() and other boilerplate flutter here</span>
<span>}</span>
```

### Sending Lua to the Frame

```
<span>async</span> <span>frame</span><span>.</span><span>run_lua</span><span>(</span><span>lua_string</span><span>:</span> <span>str</span><span>,</span> <span>await_print</span><span>:</span> <span>bool</span> <span>=</span> <span>False</span><span>,</span> <span>checked</span><span>:</span> <span>bool</span> <span>=</span> <span>False</span><span>,</span> <span>timeout</span><span>:</span> <span>Optional</span><span>[</span><span>float</span><span>]</span> <span>=</span> <span>10</span><span>)</span> <span>-&gt;</span> <span>Optional</span><span>[</span><span>str</span><span>]</span>
```

You can send Lua code to run on your Frame. You do not need to worry about the MTU length, the SDK will handle breaking up the code for you if needed. By default this returns immediately, but you can opt to wait until a response is printed back from the frame (up to a timeout limit). This function also patches any Lua calls to `print()` so that you can return strings that are longer than the MTU limit.

-   `lua_string` _(string)_: The code to execute, as a string. For string literals, don’t forget to escape quotes as needed. There is no length limit, and multiple lines are supported. If you want to return a value to your app via `await_print`, then make sure this code includes a `print()` statement.
-   `await_print` _(boolean)_: Whether or not to wait until the Lua code executing on the Frame returns a value via a `print()` statement. If `true`, then the code will block at this point up to `timeout` seconds.
-   `checked` _(boolean)_: If the lua code is not expected to return a value, but you still want to block until completion to ensure it ran successfully, then set `checked`. If `True`, then then the code will block at this point up to `timeout` seconds waiting for the Lua code to complete executing on the Frame. If any errors are thrown on the Frame, an exception will be raised by the SDK. If `False` (and also `await_print` is `False`), then this function returns immediately and your code continues running while the Lua code runs in parallel on the Frame. However if there are any errors on the Frame (or if your Lua code contains syntax errors), you will not know about them.
-   `timeout` _(None/null or float)_: If `None`/`null`, then the default timeout will be used. If specified and either `await_print` or `checked` is `True`, then waits for a maximum of `timeout` seconds before raising a timeout error.

Python

#### Python

```
<span>async</span> <span>def</span> <span>run_lua</span><span>(</span><span>self</span><span>,</span> <span>lua_string</span><span>:</span> <span>str</span><span>,</span> <span>await_print</span><span>:</span> <span>bool</span> <span>=</span> <span>False</span><span>,</span> <span>checked</span><span>:</span> <span>bool</span> <span>=</span> <span>False</span><span>,</span> <span>timeout</span><span>:</span> <span>Optional</span><span>[</span><span>float</span><span>]</span> <span>=</span> <span>10</span><span>)</span> <span>-&gt;</span> <span>Optional</span><span>[</span><span>str</span><span>]</span>
```

Examples:

```
<span># basic usage
</span><span>await</span> <span>frame</span><span>.</span><span>run_lua</span><span>(</span><span>"frame.display.text('Hello world', 50, 100);frame.display.show()"</span><span>)</span>

<span># return data via print()
</span><span>time_since_reboot</span> <span>=</span> <span>await</span> <span>frame</span><span>.</span><span>run_lua</span><span>(</span><span>"print(frame.time.utc() .. </span><span>\"</span><span> seconds</span><span>\"</span><span>)"</span><span>,</span> <span>await_print</span> <span>=</span> <span>True</span><span>)</span>
<span>print</span><span>(</span><span>f</span><span>"Frame has been on for </span><span>{</span><span>time_since_reboot</span><span>}</span><span>."</span><span>)</span>

<span># both the lua code you send and any replies sent back via print() can be of any length
</span><span>print</span><span>(</span><span>await</span> <span>frame</span><span>.</span><span>run_lua</span><span>(</span><span>"text = 'Look ma, no MTU limit! ';text=text..text;text=text..text;text=text..text;text=text..text;print(text)"</span><span>,</span> <span>await_print</span> <span>=</span> <span>True</span><span>))</span>

<span># let long running commands run in parallel
</span><span>await</span> <span>frame</span><span>.</span><span>run_lua</span><span>(</span><span>"spinning_my_wheels = 0;while true do;spinning_my_wheels=spinning_my_wheels+1;end"</span><span>,</span> <span>checked</span><span>=</span><span>False</span><span>)</span>
<span>print</span><span>(</span><span>"Frame is currently spinning its wheels, but python keeps going"</span><span>)</span>

<span># raises a timeout exception after 10 seconds
</span><span>await</span> <span>frame</span><span>.</span><span>run_lua</span><span>(</span><span>"spinning_my_wheels = 0;while true do;spinning_my_wheels=spinning_my_wheels+1;end"</span><span>,</span> <span>checked</span><span>=</span><span>True</span><span>,</span> <span>timeout</span><span>=</span><span>10</span><span>)</span>

<span># raises an exception with the Lua syntax error
</span><span>await</span> <span>frame</span><span>.</span><span>run_lua</span><span>(</span><span>"Syntax?:Who$needs!syntax?"</span><span>,</span> <span>checked</span><span>=</span><span>True</span><span>)</span>
```
Flutter

#### Flutter

```
<span>Future</span><span>&lt;</span><span>String</span><span>?</span><span>&gt;</span> <span>runLua</span><span>(</span><span>String</span> <span>luaString</span><span>,</span>
      <span>{</span><span>bool</span> <span>awaitPrint</span> <span>=</span> <span>false</span><span>,</span>
      <span>bool</span> <span>checked</span> <span>=</span> <span>false</span><span>,</span>
      <span>Duration</span><span>?</span> <span>timeout</span><span>,</span>
      <span>bool</span> <span>withoutHelpers</span> <span>=</span> <span>false</span><span>})</span> <span>async</span>
```

Examples:

```
<span>// basic usage</span>
<span>await</span> <span>frame</span><span>.</span><span>runLua</span><span>(</span><span>"frame.display.text('Hello world', 50, 100);frame.display.show()"</span><span>);</span>

<span>// return data via print()</span>
<span>String</span> <span>curTime</span> <span>=</span> <span>await</span> <span>frame</span><span>.</span><span>runLua</span><span>(</span><span>"print(frame.time.utc())"</span><span>,</span> <span>awaitPrint:</span> <span>true</span><span>);</span>
<span>print</span><span>(</span><span>"Frame epoch time is </span><span>$curTime</span><span>."</span><span>);</span>

<span>// both the lua code you send and any replies sent back via print() can be of any length</span>
<span>print</span><span>(</span><span>await</span> <span>frame</span><span>.</span><span>runLua</span><span>(</span><span>"text = 'Look ma, no MTU limit! ';text=text..text;text=text..text;text=text..text;text=text..text;print(text)"</span><span>,</span> <span>awaitPrint:</span> <span>true</span><span>));</span>

<span>// let long running commands run in parallel</span>
<span>await</span> <span>frame</span><span>.</span><span>runLua</span><span>(</span><span>"spinning_my_wheels = 0;while true do;spinning_my_wheels=spinning_my_wheels+1;end"</span><span>,</span> <span>checked:</span> <span>false</span><span>);</span>
<span>print</span><span>(</span><span>"Frame is currently spinning its wheels, but Dart keeps going"</span><span>);</span>

<span>// raises a timeout exception after 10 seconds</span>
<span>await</span> <span>frame</span><span>.</span><span>runLua</span><span>(</span><span>"spinning_my_wheels = 0;while true do;spinning_my_wheels=spinning_my_wheels+1;end"</span><span>,</span> <span>checked:</span> <span>true</span><span>,</span> <span>timeout:</span> <span>Duration</span><span>(</span><span>seconds:</span> <span>10</span><span>));</span>

<span>// raises an exception with a Lua syntax error</span>
<span>await</span> <span>frame</span><span>.</span><span>runLua</span><span>(</span><span>"Syntax?:Who</span><span>\</span><span>$needs</span><span>!syntax?"</span><span>,</span> <span>checked:</span> <span>true</span><span>);</span>
```

### Evaluating a Lua expression on the Frame

```
<span>async</span> <span>frame</span><span>.</span><span>evaluate</span><span>(</span><span>lua_expression</span><span>:</span> <span>str</span><span>,</span> <span>timeout</span><span>:</span> <span>Optional</span><span>[</span><span>float</span><span>]</span> <span>=</span> <span>10</span><span>)</span> <span>-&gt;</span> <span>str</span>
```

Evaluates a single Lua expression on the Frame and returns the answer. Equivalent to calling `run_lua(f"print(tostring({lua_expression}))",await_print=true)`.

As with `run_lua()`, you do not need to worry about the MTU limit in either direction.

-   `lua_expression` _(string)_: The lua expression to evaluate. This should not contain multiple statements, any control structures, calls to `print()`, etc. Just an expression to evaluate and return.
-   `timeout` _(None/null or float)_: If `None`/`null`, then the default timeout will be used. Waits for a maximum of `timeout` seconds before raising a timeout error.

Python

#### Python

```
<span>async</span> <span>def</span> <span>evaluate</span><span>(</span><span>self</span><span>,</span> <span>lua_expression</span><span>:</span> <span>str</span><span>,</span> <span>timeout</span><span>:</span> <span>Optional</span><span>[</span><span>float</span><span>]</span> <span>=</span> <span>10</span><span>)</span> <span>-&gt;</span> <span>str</span>
```

Examples:

```
<span>print</span><span>(</span><span>await</span> <span>frame</span><span>.</span><span>evaluate</span><span>(</span><span>"1+2"</span><span>))</span>
<span># prints 3
</span>
<span>print</span><span>(</span><span>await</span> <span>frame</span><span>.</span><span>evaluate</span><span>(</span><span>"frame.battery_level() &gt; 50"</span><span>))</span>
<span># prints True or False
</span>
<span>print</span><span>(</span><span>await</span> <span>frame</span><span>.</span><span>evaluate</span><span>(</span><span>"'w00t'"</span><span>))</span>
<span># prints w00t
</span>
<span># will throw an exception if there is no value returned or if there is a syntax error
</span><span>print</span><span>(</span><span>await</span> <span>frame</span><span>.</span><span>evaluate</span><span>(</span><span>"not_defined"</span><span>))</span>
```
Flutter

#### Flutter

```
<span>Future</span><span>&lt;</span><span>String</span><span>&gt;</span> <span>evaluate</span><span>(</span><span>String</span> <span>luaExpression</span><span>)</span> <span>async</span>
```

Examples:

```
<span>print</span><span>(</span><span>await</span> <span>frame</span><span>.</span><span>evaluate</span><span>(</span><span>"1+2"</span><span>));</span>
<span>// prints 3</span>

<span>print</span><span>(</span><span>await</span> <span>frame</span><span>.</span><span>evaluate</span><span>(</span><span>"frame.battery_level() &gt; 50"</span><span>));</span>
<span>// prints True or False</span>

<span>print</span><span>(</span><span>await</span> <span>frame</span><span>.</span><span>evaluate</span><span>(</span><span>"'w00t'"</span><span>));</span>
<span>// prints w00t</span>

<span>// will throw an exception if there is no value returned or if there is a syntax error</span>
<span>print</span><span>(</span><span>await</span> <span>frame</span><span>.</span><span>evaluate</span><span>(</span><span>"not_defined"</span><span>));</span>
```

___

## System Functions

### Get Battery Level

```
<span>async</span> <span>frame</span><span>.</span><span>get_battery_level</span><span>()</span> <span>-&gt;</span> <span>int</span>
```

Gets the Frame battery level as an integer from 0 to 100. Equivalent to `await self.evaluate("frame.battery_level()")`.

Python

#### Python

```
<span>async</span> <span>def</span> <span>get_battery_level</span><span>(</span><span>self</span><span>)</span> <span>-&gt;</span> <span>int</span>
```

Example:

```
<span>print</span><span>(</span><span>f</span><span>"Frame battery: </span><span>{</span><span>await</span> <span>frame</span><span>.</span><span>get_battery_level</span><span>()</span><span>}</span><span>%"</span><span>)</span>
```
Flutter

#### Flutter

```
<span>Future</span><span>&lt;</span><span>int</span><span>&gt;</span> <span>getBatteryLevel</span><span>()</span>
```

Example:

```
<span>int</span> <span>batteryLevel</span> <span>=</span> <span>await</span> <span>frame</span><span>.</span><span>getBatteryLevel</span><span>();</span>
<span>print</span><span>(</span><span>"Frame battery: </span><span>$batteryLevel</span><span>%"</span><span>);</span>
```

### Delay

```
<span>async</span> <span>frame</span><span>.</span><span>delay</span><span>(</span><span>seconds</span><span>:</span> <span>float</span><span>)</span>
```

Delays execution on Frame for a given number of seconds. Technically this sends a sleep command, but it doesn’t actually change the power mode. This function does not block, returning immediately.

-   `seconds` _(float)_: Seconds to delay.

Python

#### Python

```
<span>async</span> <span>def</span> <span>delay</span><span>(</span><span>self</span><span>,</span> <span>seconds</span><span>:</span> <span>float</span><span>)</span>
```

Examples:

```
<span># wait for 5 seconds
</span><span>await</span> <span>frame</span><span>.</span><span>delay</span><span>(</span><span>5</span><span>)</span>
<span>print</span><span>(</span><span>"Frame is paused, but python is still running"</span><span>)</span>
```
Flutter

#### Flutter

```
<span>Future</span><span>&lt;</span><span>void</span><span>&gt;</span> <span>delay</span><span>(</span><span>double</span> <span>seconds</span><span>)</span>
```

Examples:

```
<span>// wait for 5 seconds</span>
<span>await</span> <span>frame</span><span>.</span><span>delay</span><span>(</span><span>5</span><span>);</span>
<span>print</span><span>(</span><span>"Frame is paused, but Dart is still running"</span><span>);</span>
```

### Sleep

```
<span>async</span> <span>frame</span><span>.</span><span>sleep</span><span>(</span><span>deep_sleep</span><span>:</span> <span>bool</span> <span>=</span> <span>False</span><span>)</span> <span>-&gt;</span> <span>None</span>
```

Puts the Frame into sleep mode. There are two modes: normal and deep.

Normal sleep mode can still receive bluetooth data, and is essentially the same as clearing the display and putting the camera in low power mode. The Frame will retain the time and date, and any functions and variables will stay in memory.

Deep sleep mode saves additional power, but has more limitations. The Frame will not retain the time and date, and any functions and variables will not stay in memory. Blue data will not be received. The only way to wake the Frame from deep sleep is to tap it.

The difference in power usage is fairly low, so it’s often best to use normal sleep mode unless you need the extra power savings.

-   `deep_sleep` _(boolean)_: `True` for deep sleep, `False` for normal sleep. Defaults to `False`.

Python

#### Python

```
<span>async</span> <span>def</span> <span>sleep</span><span>(</span><span>self</span><span>,</span> <span>deep_sleep</span><span>:</span> <span>bool</span> <span>=</span> <span>False</span><span>)</span> <span>-&gt;</span> <span>None</span>
```

Examples:

```
<span># put the Frame into normal sleep mode
</span><span>await</span> <span>frame</span><span>.</span><span>sleep</span><span>()</span>

<span># put the Frame into deep sleep mode
</span><span>await</span> <span>frame</span><span>.</span><span>sleep</span><span>(</span><span>True</span><span>)</span>
```
Flutter

#### Flutter

```
<span>Future</span><span>&lt;</span><span>void</span><span>&gt;</span> <span>sleep</span><span>({</span><span>bool</span> <span>deepSleep</span> <span>=</span> <span>false</span><span>})</span>
```

Examples:

```
<span>// put the Frame into normal sleep mode</span>
<span>await</span> <span>frame</span><span>.</span><span>sleep</span><span>();</span>

<span>// put the Frame into deep sleep mode</span>
<span>await</span> <span>frame</span><span>.</span><span>sleep</span><span>(</span><span>deepSleep:</span> <span>true</span><span>);</span>
```

### Stay Awake

```
<span>async</span> <span>frame</span><span>.</span><span>stay_awake</span><span>(</span><span>value</span><span>:</span> <span>bool</span><span>)</span>
```

Prevents Frame from going to sleep while it’s docked onto the charging cradle. This can help during development where continuous power is needed, however may degrade the display or cause burn-in if used for extended periods of time.

There is no way to read the current value, only to set a new value.

-   `value` _(boolean)_: `True` for Frame to stay awake while charging, `False` to reset to normal operation so Frame turns off while charging.

Python

#### Python

```
<span>async</span> <span>def</span> <span>stay_awake</span><span>(</span><span>self</span><span>,</span> <span>value</span><span>:</span> <span>bool</span><span>)</span>
```

Example:

```
<span>await</span> <span>frame</span><span>.</span><span>stay_awake</span><span>(</span><span>True</span><span>)</span>
<span># don't forget to turn this back off or you may damage your Frame
</span>
```
Flutter

#### Flutter

```
<span>Future</span><span>&lt;</span><span>void</span><span>&gt;</span> <span>stayAwake</span><span>(</span><span>bool</span> <span>value</span><span>)</span>
```

Example:

```
<span>await</span> <span>frame</span><span>.</span><span>stayAwake</span><span>(</span><span>true</span><span>);</span>
<span>// don't forget to turn this back off or you may damage your Frame</span>
```

### Send Break Signal

```
<span>async</span> <span>frame</span><span>.</span><span>bluetooth</span><span>.</span><span>send_break_signal</span><span>()</span>
```

Sends a break signal to the device which will break any currently executing Lua script.

Python

#### Python

```
<span>async</span> <span>def</span> <span>send_break_signal</span><span>(</span><span>self</span><span>)</span>
```

Example:

```
<span>await</span> <span>frame</span><span>.</span><span>run_lua</span><span>(</span><span>"spinning_my_wheels = 0;while true do;spinning_my_wheels=spinning_my_wheels+1;end"</span><span>,</span> <span>checked</span><span>=</span><span>False</span><span>)</span>
<span>print</span><span>(</span><span>"Frame is currently spinning its wheels, but python keeps going"</span><span>)</span>

<span>await</span> <span>frame</span><span>.</span><span>bluetooth</span><span>.</span><span>send_break_signal</span><span>()</span>
<span>print</span><span>(</span><span>"Now Frame has been broken out of its loop and we can talk to it again"</span><span>)</span>

<span>print</span><span>(</span><span>await</span> <span>frame</span><span>.</span><span>evaluate</span><span>(</span><span>"'I</span><span>\\</span><span>m back!'"</span><span>))</span>
<span># prints I'm back!
</span>
```
Flutter

#### Flutter

```
<span>Future</span><span>&lt;</span><span>void</span><span>&gt;</span> <span>sendBreakSignal</span><span>()</span>
```

Example:

```
<span>await</span> <span>frame</span><span>.</span><span>runLua</span><span>(</span><span>"spinning_my_wheels = 0;while true do;spinning_my_wheels=spinning_my_wheels+1;end"</span><span>,</span> <span>checked:</span> <span>false</span><span>);</span>
<span>print</span><span>(</span><span>"Frame is currently spinning its wheels, but Dart keeps going"</span><span>);</span>

<span>await</span> <span>frame</span><span>.</span><span>bluetooth</span><span>.</span><span>sendBreakSignal</span><span>();</span>
<span>print</span><span>(</span><span>"Now Frame has been broken out of its loop and we can talk to it again"</span><span>);</span>

<span>print</span><span>(</span><span>await</span> <span>frame</span><span>.</span><span>evaluate</span><span>(</span><span>"'I</span><span>\\</span><span>'m back!'"</span><span>));</span>
<span>// prints I'm back!</span>
```

### Send Reset Signal

```
<span>async</span> <span>frame</span><span>.</span><span>bluetooth</span><span>.</span><span>send_reset_signal</span><span>()</span>
```

Sends a reset signal to the device which will reset the Lua virtual machine. This clears all variables and functions, and resets the stack. It does not clear the filesystem.

Python

#### Python

```
<span>async</span> <span>def</span> <span>send_reset_signal</span><span>(</span><span>self</span><span>)</span>
```

Example:

```
<span>await</span> <span>frame</span><span>.</span><span>run_lua</span><span>(</span><span>"data = 1"</span><span>,</span> <span>checked</span><span>=</span><span>True</span><span>)</span>
<span>print</span><span>(</span><span>await</span> <span>frame</span><span>.</span><span>evaluate</span><span>(</span><span>"data"</span><span>))</span>
<span># prints 1
</span>

<span>await</span> <span>frame</span><span>.</span><span>bluetooth</span><span>.</span><span>send_reset_signal</span><span>()</span>
<span>print</span><span>(</span><span>"Frame has been reset"</span><span>)</span>

<span>print</span><span>(</span><span>await</span> <span>frame</span><span>.</span><span>evaluate</span><span>(</span><span>"data"</span><span>))</span>
<span># raises an exception
# TODO: (or returns nil? not actually sure)
</span>
```
Flutter

#### Flutter

```
<span>Future</span><span>&lt;</span><span>void</span><span>&gt;</span> <span>sendResetSignal</span><span>()</span>
```

Example:

```
<span>await</span> <span>frame</span><span>.</span><span>runLua</span><span>(</span><span>"data = 1"</span><span>,</span> <span>checked:</span> <span>true</span><span>);</span>
<span>print</span><span>(</span><span>await</span> <span>frame</span><span>.</span><span>evaluate</span><span>(</span><span>"data"</span><span>));</span>
<span>// prints 1</span>


<span>await</span> <span>frame</span><span>.</span><span>bluetooth</span><span>.</span><span>sendResetSignal</span><span>();</span>
<span>print</span><span>(</span><span>"Frame has been reset"</span><span>);</span>

<span>print</span><span>(</span><span>await</span> <span>frame</span><span>.</span><span>evaluate</span><span>(</span><span>"data"</span><span>));</span>
<span>// raises an exception</span>
<span>// TODO: (or returns nil? not actually sure)</span>
```

### Run On Wake

```
<span>async</span> <span>frame</span><span>.</span><span>run_on_wake</span><span>(</span><span>lua_script</span><span>:</span> <span>Optional</span><span>[</span><span>str</span><span>]</span> <span>=</span> <span>None</span><span>,</span> <span>callback</span><span>:</span> <span>Optional</span><span>[</span><span>Callable</span><span>[[],</span> <span>None</span> <span>]]</span> <span>=</span> <span>None</span><span>)</span> <span>-&gt;</span> <span>None</span>
```

Runs the specified lua\_script and/or callback when the Frame wakes up from sleep (via a tap gesture). This allows your to define the “home “screen”, for example by displaying the battery or time when the frame is woken. In the Noa app, this is where you see the “Tap me in…” message.

Any `lua_script` or `callback` will clear any previously set run on wake commands. To remove all run on wake commands, pass `None`/`null` for both `lua_script` and `callback`.

-   `lua_script` _(string)_: The lua script to run on the Frame when the Frame wakes up. This runs even if the Frame is not connected via bluetooth at the time of the wakeup.
-   `callback` _(callable)_: A callback function locally to run when the Frame wakes up. This will only run if the Frame is connected via bluetooth at the time of the wakeup.

Python

#### Python

```
<span>async</span> <span>def</span> <span>run_on_wake</span><span>(</span><span>self</span><span>,</span> <span>lua_script</span><span>:</span> <span>Optional</span><span>[</span><span>str</span><span>]</span> <span>=</span> <span>None</span><span>,</span> <span>callback</span><span>:</span> <span>Optional</span><span>[</span><span>Callable</span><span>[[],</span> <span>None</span> <span>]]</span> <span>=</span> <span>None</span><span>)</span> <span>-&gt;</span> <span>None</span>
```

Example:

```
<span># set a wake screen via script, so when you tap to wake the frame, it shows the battery level and then goes back to sleep after 10 seconds of inactivity
</span><span>await</span> <span>f</span><span>.</span><span>run_on_wake</span><span>(</span><span>lua_script</span><span>=</span><span>"""frame.display.text('Battery: ' .. frame.battery_level() ..  '%', 10, 10);
                    frame.display.show();
                    frame.sleep(10);
                    frame.display.text(' ',1,1);
                    frame.display.show();
                    frame.sleep()"""</span><span>)</span>
```
Flutter

#### Flutter

```
<span>Future</span><span>&lt;</span><span>void</span><span>&gt;</span> <span>runOnWake</span><span>({</span><span>String</span><span>?</span> <span>luaScript</span><span>,</span> <span>void</span> <span>Function</span><span>()</span><span>?</span> <span>callback</span><span>})</span>
```

Example:

```
<span>// set a wake screen via script, so when you tap to wake the frame, it shows the battery level and then goes back to sleep after 10 seconds of inactivity</span>
<span>await</span> <span>frame</span><span>.</span><span>runOnWake</span><span>(</span>
  <span>luaScript:</span> <span>"""frame.display.text('Battery: ' .. frame.battery_level() ..  '%', 10, 10);
                    frame.display.show();
                    frame.sleep(10);
                    frame.display.text(' ',1,1);
                    frame.display.show();
                    frame.sleep()"""</span><span>,</span>
<span>);</span>
```

### Set Print Debugging (Python)

```
<span>frame</span><span>.</span><span>bluetooth</span><span>.</span><span>set_print_debugging</span><span>(</span><span>value</span><span>:</span> <span>bool</span><span>)</span>
```

In Python, sometimes it’s useful for debugging to see all raw data that is transmitted to Frame, as well as the raw data received from Frame. This function allows you to turn that on or off.

For Flutter, debug info is logged to the Logger, so set the log level or subscribe to the logger to see logging instead.

-   `value` _(boolean)_: `True` to enable, `False` to disable.

Python

#### Python

```
<span>def</span> <span>set_print_debugging</span><span>(</span><span>self</span><span>,</span> <span>value</span><span>:</span> <span>bool</span><span>)</span>
```

Example:

```
<span>frame</span><span>.</span><span>bluetooth</span><span>.</span><span>set_print_debugging</span><span>(</span><span>True</span><span>)</span>
<span>print</span><span>(</span><span>await</span> <span>frame</span><span>.</span><span>evaluate</span><span>(</span><span>"'Hello world!'"</span><span>))</span>
<span># prints:
# b'print(\'Hello world!\')'
# Hello world!
</span>
```

### Wait For Data

```
<span>async</span> <span>frame</span><span>.</span><span>bluetooth</span><span>.</span><span>wait_for_data</span><span>(</span><span>timeout</span><span>:</span> <span>float</span> <span>=</span> <span>30.0</span><span>)</span> <span>-&gt;</span> <span>bytes</span>
```

Blocks until data has been received from Frame via `frame.bluetooth.send()`. This is used for example when waiting for Frame to transmit data from a photo or audio.

This waits for bluetooth send data, not `print()` statements. If you want to send data beyond what fits in the MTU, then you can send data in multiple chunks by prepending each chunk with `\001` (0x01) and sending a final chunk with `\002` (0x02). You can optionally include the total chunk count in the final message for reliability checking (for example, if you send 3 chunks, then the final message should be `\0023`).

-   `timeout` _(float)_: The maximum number of seconds to wait for data. Defaults to 30 seconds.

Python

#### Python

```
<span>async</span> <span>def</span> <span>wait_for_data</span><span>(</span><span>self</span><span>,</span> <span>timeout</span><span>:</span> <span>float</span> <span>=</span> <span>30.0</span><span>)</span> <span>-&gt;</span> <span>bytes</span>
```

Examples:

```
<span>await</span> <span>frame</span><span>.</span><span>run_lua</span><span>(</span><span>"""
local mtu = frame.bluetooth.max_length()
local f = frame.file.open("example_file.txt", "read")
local chunkIndex = 0
while true do
    local this_chunk = f:read(mtu-1)
    if this_chunk == nil then
        break
    end
    frame.bluetooth.send('</span><span>\\</span><span>001' .. this_chunk)
    chunkIndex = chunkIndex + 1
end
frame.bluetooth.send('</span><span>\\</span><span>002' .. chunkIndex)
"""</span><span>,</span> <span>checked</span><span>=</span><span>False</span><span>)</span>

<span>full_file_data</span> <span>=</span> <span>await</span> <span>frame</span><span>.</span><span>bluetooth</span><span>.</span><span>wait_for_data</span><span>()</span>
<span>print</span><span>(</span><span>full_file_data</span><span>.</span><span>decode</span><span>())</span>
```
Flutter

#### Flutter

```
<span>Future</span><span>&lt;</span><span>Uint8List</span><span>&gt;</span> <span>waitForData</span><span>({</span><span>Duration</span> <span>timeout</span> <span>=</span> <span>const</span> <span>Duration</span><span>(</span><span>seconds:</span> <span>30</span><span>)})</span>
```

Examples:

```
<span>await</span> <span>frame</span><span>.</span><span>runLua</span><span>(</span><span>"""
local mtu = frame.bluetooth.max_length()
local f = frame.file.open("</span><span>example_file</span><span>.</span><span>txt</span><span>", "</span><span>read</span><span>")
local chunkIndex = 0
while true do
    local this_chunk = f:read(mtu-1)
    if this_chunk == nil then
        break
    end
    frame.bluetooth.send('</span><span>\\</span><span>001' .. this_chunk)
    chunkIndex = chunkIndex + 1
end
frame.bluetooth.send('</span><span>\\</span><span>002' .. chunkIndex)
"""</span><span>,</span> <span>checked:</span> <span>false</span><span>);</span>

<span>Uint8List</span> <span>full_file_data</span> <span>=</span> <span>await</span> <span>frame</span><span>.</span><span>bluetooth</span><span>.</span><span>waitForData</span><span>();</span>
<span>print</span><span>(</span><span>utf8</span><span>.</span><span>decode</span><span>(</span><span>full_file_data</span><span>));</span>
```

___

## Filesystem

Filesystem functions are available via `Frame.files`.

### Write File

```
<span>async</span> <span>frame</span><span>.</span><span>files</span><span>.</span><span>write_file</span><span>(</span><span>path</span><span>:</span> <span>str</span><span>,</span> <span>data</span><span>:</span> <span>bytes</span><span>,</span> <span>checked</span><span>:</span> <span>bool</span> <span>=</span> <span>False</span><span>)</span>
```

Write a file to the device’s storage. If the file already exists, it will be overwritten. There are no length limits to the file, as it will be transferred reliably over multiple bluetooth transmissions.

-   `path` _(string)_: The full filename to write on the Frame. Even if no leading ‘/’ is included, the path is relative to the root of the filesystem.
-   `data` _(bytes)_: The data to write to the file. If specifying as a string literal, don’t forget to escape quotes as needed, and also to encode the string to bytes.
-   `checked` _(boolean)_: If `True`, then each step of writing with wait for acknowledgement from the Frame before continuing. This is more reliable but slower. If `False`, then the file will be written fully asynchronously and without error checking.

Python

#### Python

```
<span>async</span> <span>def</span> <span>write_file</span><span>(</span><span>self</span><span>,</span> <span>path</span><span>:</span> <span>str</span><span>,</span> <span>data</span><span>:</span> <span>bytes</span><span>,</span> <span>checked</span><span>:</span> <span>bool</span> <span>=</span> <span>False</span><span>)</span>
```

Examples:

```
<span>await</span> <span>frame</span><span>.</span><span>files</span><span>.</span><span>write_file</span><span>(</span><span>"example_file.txt"</span><span>,</span> <span>b</span><span>"Hello </span><span>\"</span><span>real</span><span>\"</span><span> world"</span><span>,</span> <span>checked</span><span>=</span><span>True</span><span>)</span>

<span>lyrics</span> <span>=</span> <span>"Never gonna give you up</span><span>\n</span><span>Never gonna let you down</span><span>\n</span><span>Never gonna run around and desert you</span><span>\n</span><span>Never gonna make you cry</span><span>\n</span><span>Never gonna say goodbye</span><span>\n</span><span>Never gonna tell a lie and hurt you"</span>
<span>await</span> <span>frame</span><span>.</span><span>files</span><span>.</span><span>write_file</span><span>(</span><span>"/music/rick_roll.txt"</span><span>,</span> <span>lyrics</span><span>.</span><span>encode</span><span>(),</span> <span>checked</span><span>=</span><span>True</span><span>)</span>

<span>with</span> <span>open</span><span>(</span><span>"icons.dat"</span><span>,</span> <span>"rb"</span><span>)</span> <span>as</span> <span>f</span><span>:</span>
    <span>await</span> <span>frame</span><span>.</span><span>files</span><span>.</span><span>write_file</span><span>(</span><span>"/sprites/icons.dat"</span><span>,</span> <span>f</span><span>.</span><span>read</span><span>())</span>
```
Flutter

#### Flutter

```
<span>Future</span><span>&lt;</span><span>void</span><span>&gt;</span> <span>writeFile</span><span>(</span><span>String</span> <span>path</span><span>,</span> <span>Uint8List</span> <span>data</span><span>,</span> <span>{</span><span>bool</span> <span>checked</span> <span>=</span> <span>false</span><span>})</span>
```

Example:

```
<span>await</span> <span>frame</span><span>.</span><span>files</span><span>.</span><span>writeFile</span><span>(</span><span>"example_file.txt"</span><span>,</span> <span>utf8</span><span>.</span><span>encode</span><span>(</span><span>'Hello "real" world'</span><span>),</span> <span>checked:</span> <span>true</span><span>);</span>

<span>String</span> <span>lyrics</span> <span>=</span> <span>"Never gonna give you up</span><span>\n</span><span>Never gonna let you down</span><span>\n</span><span>Never gonna run around and desert you</span><span>\n</span><span>Never gonna make you cry</span><span>\n</span><span>Never gonna say goodbye</span><span>\n</span><span>Never gonna tell a lie and hurt you"</span><span>;</span>
<span>await</span> <span>frame</span><span>.</span><span>files</span><span>.</span><span>writeFile</span><span>(</span><span>"/music/rick_roll.txt"</span><span>,</span> <span>utf8</span><span>.</span><span>encode</span><span>(</span><span>lyrics</span><span>),</span> <span>checked:</span> <span>true</span><span>);</span>

<span>ByteData</span> <span>data</span> <span>=</span> <span>await</span> <span>rootBundle</span><span>.</span><span>load</span><span>(</span><span>'assets/icons.dat'</span><span>);</span>
<span>await</span> <span>frame</span><span>.</span><span>files</span><span>.</span><span>writeFile</span><span>(</span><span>"/sprites/icons.dat"</span><span>,</span> <span>data</span><span>.</span><span>buffer</span><span>.</span><span>asUint8List</span><span>());</span>
```

### Read File

```
<span>async</span> <span>frame</span><span>.</span><span>files</span><span>.</span><span>read_file</span><span>(</span><span>path</span><span>:</span> <span>str</span><span>)</span> <span>-&gt;</span> <span>bytes</span>
```

Reads a file from the device in full. There are no length limits to the file, as it will be transferred reliably over multiple bluetooth transmissions. Returns raw byte data. If you want it as a string, then use `.decode()`.

Raises an exception if the file does not exist.

-   `path` _(string)_: The full filename to read on the Frame. Even if no leading ‘/’ is included, the path is relative to the root of the filesystem.

Python

#### Python

```
<span>async</span> <span>def</span> <span>read_file</span><span>(</span><span>self</span><span>,</span> <span>path</span><span>:</span> <span>str</span><span>)</span> <span>-&gt;</span> <span>bytes</span>
```

Examples:

```
<span># print a text file
</span><span>print</span><span>(</span><span>await</span> <span>frame</span><span>.</span><span>files</span><span>.</span><span>read_file</span><span>(</span><span>"example_file.txt"</span><span>).</span><span>decode</span><span>())</span>

<span># save a raw file locally
</span><span>with</span> <span>open</span><span>(</span><span>"~/blob.bin"</span><span>,</span> <span>"wb"</span><span>)</span> <span>as</span> <span>f</span><span>:</span>
    <span>f</span><span>.</span><span>write</span><span>(</span><span>await</span> <span>frame</span><span>.</span><span>files</span><span>.</span><span>read_file</span><span>(</span><span>"blob_on_frame.bin"</span><span>))</span>
```
Flutter

#### Flutter

```
<span>Future</span><span>&lt;</span><span>Uint8List</span><span>&gt;</span> <span>readFile</span><span>(</span><span>String</span> <span>path</span><span>)</span>
```

Example:

```
<span>String</span> <span>fileContent</span> <span>=</span> <span>utf8</span><span>.</span><span>decode</span><span>(</span><span>await</span> <span>frame</span><span>.</span><span>files</span><span>.</span><span>readFile</span><span>(</span><span>"greeting.txt"</span><span>));</span>
<span>print</span><span>(</span><span>fileContent</span><span>);</span>
```

### Delete File

```
<span>async</span> <span>frame</span><span>.</span><span>files</span><span>.</span><span>delete_file</span><span>(</span><span>path</span><span>:</span> <span>str</span><span>)</span> <span>-&gt;</span> <span>bool</span>
```

Delete a file on the device. Returns `True` if the file was deleted, `False` if it didn’t exist or failed to delete.

-   `path` _(string)_: The full path to the file to delete. Even if no leading ‘/’ is included, the path is relative to the root of the filesystem.

Python

#### Python

```
<span>async</span> <span>def</span> <span>delete_file</span><span>(</span><span>self</span><span>,</span> <span>path</span><span>:</span> <span>str</span><span>)</span> <span>-&gt;</span> <span>bool</span>
```

Examples:

```
<span>did_delete</span> <span>=</span> <span>await</span> <span>frame</span><span>.</span><span>files</span><span>.</span><span>delete_file</span><span>(</span><span>"main.lua"</span><span>)</span>
<span>print</span><span>(</span><span>f</span><span>"Deleted? </span><span>{</span><span>did_delete</span><span>}</span><span>"</span><span>)</span>
```
Flutter

#### Flutter

```
<span>Future</span><span>&lt;</span><span>bool</span><span>&gt;</span> <span>deleteFile</span><span>(</span><span>String</span> <span>path</span><span>)</span>
```

Example:

```
<span>bool</span> <span>didDelete</span> <span>=</span> <span>await</span> <span>frame</span><span>.</span><span>files</span><span>.</span><span>deleteFile</span><span>(</span><span>"main.lua"</span><span>);</span>
<span>print</span><span>(</span><span>"Deleted? </span><span>$didDelete</span><span>"</span><span>);</span>
```

### File Exists?

```
<span>async</span> <span>frame</span><span>.</span><span>files</span><span>.</span><span>file_exists</span><span>(</span><span>path</span><span>:</span> <span>str</span><span>)</span> <span>-&gt;</span> <span>bool</span>
```

Check if a file exists on the device. Returns `True` if the file exists, `False` if it does not. Does not work on directories, only files.

-   `path` _(string)_: The full path to the file to check. Even if no leading ‘/’ is included, the path is relative to the root of the filesystem.

Python

#### Python

```
<span>async</span> <span>def</span> <span>file_exists</span><span>(</span><span>self</span><span>,</span> <span>path</span><span>:</span> <span>str</span><span>)</span> <span>-&gt;</span> <span>bool</span>
```

Example:

```
<span>exists</span> <span>=</span> <span>await</span> <span>frame</span><span>.</span><span>files</span><span>.</span><span>file_exists</span><span>(</span><span>"main.lua"</span><span>)</span>
<span>print</span><span>(</span><span>f</span><span>"Main.lua </span><span>{</span><span>'exists'</span> <span>if</span> <span>exists</span> <span>else</span> <span>'does not exist'</span><span>}</span><span>"</span><span>)</span>
```
Flutter

#### Flutter

```
<span>Future</span><span>&lt;</span><span>bool</span><span>&gt;</span> <span>fileExists</span><span>(</span><span>String</span> <span>path</span><span>)</span>
```

Example:

```
<span>bool</span> <span>exists</span> <span>=</span> <span>await</span> <span>frame</span><span>.</span><span>files</span><span>.</span><span>fileExists</span><span>(</span><span>"main.lua"</span><span>);</span>
<span>print</span><span>(</span><span>"Main.lua </span><span>${exists ? 'exists' : 'does not exist'}</span><span>"</span><span>);</span>
```

___

## Camera

Filesystem functions are available via `frame.camera`.

The `frame.camera.auto_sleep` function is currently ignored pending further testing, and may be removed in a future version.

### Take Photo

```
<span>async</span> <span>frame</span><span>.</span><span>camera</span><span>.</span><span>take_photo</span><span>(</span><span>autofocus_seconds</span><span>:</span> <span>Optional</span><span>[</span><span>int</span><span>]</span> <span>=</span> <span>3</span><span>,</span> <span>quality</span><span>:</span> <span>Quality</span> <span>=</span> <span>Quality</span><span>.</span><span>MEDIUM</span><span>,</span> <span>autofocus_type</span><span>:</span> <span>AutofocusType</span> <span>=</span> <span>AutofocusType</span><span>.</span><span>AVERAGE</span><span>)</span> <span>-&gt;</span> <span>bytes</span><span>:</span>
```

Take a photo with the camera and return the photo data in jpeg format as bytes.

By default, the image is rotated to the correct orientation and some metadata is added. If you want to skip these, then set `frame.camera.auto_process_photo` to `False`. This will result in a photo that is rotated 90 degrees clockwise and has no metadata.

You’ll need to import `Quality` and `AutofocusType` from `frame.camera` to use these.

-   `autofocus_seconds` _(optional int)_: If `autofocus_seconds` is provided, the camera will attempt to set exposure and other setting automatically for the specified number of seconds before taking a photo. Defaults to 3 seconds. If you want to skip autofocus altogether, then set this to `None`/`null`.
-   `quality` _(Quality)_: The quality of the photo to take. Defaults to `Quality.MEDIUM`. Values are `Quality.LOW` (10), `Quality.MEDIUM` (25), `Quality.HIGH` (50), and `Quality.FULL` (100).
-   `autofocus_type` _(AutofocusType)_: The type of autofocus to use. Defaults to `AutofocusType.AVERAGE`. Values are `AutofocusType.AVERAGE` (“AVERAGE”), `AutofocusType.SPOT` (“SPOT”), and `AutofocusType.CENTER_WEIGHTED` (“CENTER\_WEIGHTED”).

Python

#### Python

```
<span>async</span> <span>def</span> <span>take_photo</span><span>(</span><span>self</span><span>,</span> <span>autofocus_seconds</span><span>:</span> <span>Optional</span><span>[</span><span>int</span><span>]</span> <span>=</span> <span>3</span><span>,</span> <span>quality</span><span>:</span> <span>Quality</span> <span>=</span> <span>Quality</span><span>.</span><span>MEDIUM</span><span>,</span> <span>autofocus_type</span><span>:</span> <span>AutofocusType</span> <span>=</span> <span>AutofocusType</span><span>.</span><span>AVERAGE</span><span>)</span> <span>-&gt;</span> <span>bytes</span>
```

Examples:

```
<span>from</span> <span>frame_sdk.camera</span> <span>import</span> <span>Quality</span><span>,</span> <span>AutofocusType</span>

<span># take a photo
</span><span>photo_bytes</span> <span>=</span> <span>await</span> <span>frame</span><span>.</span><span>camera</span><span>.</span><span>take_photo</span><span>()</span>

<span># take a photo with more control and save to disk
</span><span>photo_bytes</span> <span>=</span> <span>await</span> <span>frame</span><span>.</span><span>camera</span><span>.</span><span>take_photo</span><span>(</span><span>autofocus_seconds</span><span>=</span><span>2</span><span>,</span> <span>quality</span><span>=</span><span>Quality</span><span>.</span><span>HIGH</span><span>,</span> <span>autofocus_type</span><span>=</span><span>AutofocusType</span><span>.</span><span>CENTER_WEIGHTED</span><span>)</span>
<span>with</span> <span>open</span><span>(</span><span>"photo.jpg"</span><span>,</span> <span>"wb"</span><span>)</span> <span>as</span> <span>file</span><span>:</span>
    <span>file</span><span>.</span><span>write</span><span>(</span><span>photo_bytes</span><span>)</span>

<span># turn off auto-rotation and metadata
</span><span>frame</span><span>.</span><span>camera</span><span>.</span><span>auto_process_photo</span> <span>=</span> <span>False</span>
<span># take a very fast photo
</span><span>photo_bytes</span> <span>=</span> <span>await</span> <span>frame</span><span>.</span><span>camera</span><span>.</span><span>take_photo</span><span>(</span><span>autofocus_seconds</span><span>=</span><span>None</span><span>,</span> <span>quality</span><span>=</span><span>Quality</span><span>.</span><span>LOW</span><span>)</span>
<span>print</span><span>(</span><span>len</span><span>(</span><span>photo_bytes</span><span>))</span>
```
Flutter

#### Flutter

```
<span>Future</span><span>&lt;</span><span>Uint8List</span><span>&gt;</span> <span>takePhoto</span><span>({</span><span>int</span><span>?</span> <span>autofocusSeconds</span> <span>=</span> <span>3</span><span>,</span> <span>PhotoQuality</span> <span>quality</span> <span>=</span> <span>PhotoQuality</span><span>.</span><span>medium</span><span>,</span> <span>AutoFocusType</span> <span>autofocusType</span> <span>=</span> <span>AutoFocusType</span><span>.</span><span>average</span><span>})</span> <span>async</span>
```

Examples:

```
<span>import</span> <span>'package:frame/camera.dart'</span><span>;</span>

<span>// Take a photo</span>
<span>Uint8List</span> <span>photoBytes</span> <span>=</span> <span>await</span> <span>frame</span><span>.</span><span>camera</span><span>.</span><span>takePhoto</span><span>();</span>

<span>// Take a photo with more control</span>
<span>Uint8List</span> <span>photoBytes</span> <span>=</span> <span>await</span> <span>frame</span><span>.</span><span>camera</span><span>.</span><span>takePhoto</span><span>(</span>
  <span>autofocusSeconds:</span> <span>2</span><span>,</span>
  <span>quality:</span> <span>PhotoQuality</span><span>.</span><span>high</span><span>,</span>
  <span>autofocusType:</span> <span>AutoFocusType</span><span>.</span><span>centerWeighted</span>
<span>);</span>

<span>// Turn off auto-rotation and metadata</span>
<span>frame</span><span>.</span><span>camera</span><span>.</span><span>autoProcessPhoto</span> <span>=</span> <span>false</span><span>;</span>
<span>// Take a very fast photo</span>
<span>Uint8List</span> <span>photoBytes</span> <span>=</span> <span>await</span> <span>frame</span><span>.</span><span>camera</span><span>.</span><span>takePhoto</span><span>(</span>
  <span>autofocusSeconds:</span> <span>null</span><span>,</span>
  <span>quality:</span> <span>PhotoQuality</span><span>.</span><span>low</span>
<span>);</span>
<span>print</span><span>(</span><span>photoBytes</span><span>.</span><span>length</span><span>);</span>
```

### Save Photo

```
<span>async</span> <span>frame</span><span>.</span><span>camera</span><span>.</span><span>save_photo</span><span>(</span><span>path</span><span>:</span> <span>str</span><span>,</span> <span>autofocus_seconds</span><span>:</span> <span>Optional</span><span>[</span><span>int</span><span>]</span> <span>=</span> <span>3</span><span>,</span> <span>quality</span><span>:</span> <span>Quality</span> <span>=</span> <span>Quality</span><span>.</span><span>MEDIUM</span><span>,</span> <span>autofocus_type</span><span>:</span> <span>AutofocusType</span> <span>=</span> <span>AutofocusType</span><span>.</span><span>AVERAGE</span><span>)</span>
```

Take a photo with the camera and save it to disk as a jpeg image. This is the same as calling `frame.camera.take_photo()` and then saving the bytes to disk.

By default, the image is rotated to the correct orientation and some metadata is added. If you want to skip these, then set `frame.camera.auto_process_photo` to `False`. This will result in a photo that is rotated 90 degrees clockwise and has no metadata.

You’ll need to import `Quality` and `AutofocusType` from `frame.camera` to use these.

-   `path` _(string)_: The local path to save the photo. The photo is always saved in jpeg format regardless of the extension you specify.
-   `autofocus_seconds` _(optional int)_: If `autofocus_seconds` is provided, the camera will attempt to set exposure and other setting automatically for the specified number of seconds before taking a photo. Defaults to 3 seconds. If you want to skip autofocus altogether, then set this to `None`/`null`.
-   `quality` _(Quality)_: The quality of the photo to take. Defaults to `Quality.MEDIUM`. Values are `Quality.LOW` (10), `Quality.MEDIUM` (25), `Quality.HIGH` (50), and `Quality.FULL` (100).
-   `autofocus_type` _(AutofocusType)_: The type of autofocus to use. Defaults to `AutofocusType.AVERAGE`. Values are `AutofocusType.AVERAGE` (“AVERAGE”), `AutofocusType.SPOT` (“SPOT”), and `AutofocusType.CENTER_WEIGHTED` (“CENTER\_WEIGHTED”).

Python

#### Python

```
<span>async</span> <span>def</span> <span>save_photo</span><span>(</span><span>self</span><span>,</span> <span>path</span><span>:</span> <span>str</span><span>,</span> <span>autofocus_seconds</span><span>:</span> <span>Optional</span><span>[</span><span>int</span><span>]</span> <span>=</span> <span>3</span><span>,</span> <span>quality</span><span>:</span> <span>Quality</span> <span>=</span> <span>Quality</span><span>.</span><span>MEDIUM</span><span>,</span> <span>autofocus_type</span><span>:</span> <span>AutofocusType</span> <span>=</span> <span>AutofocusType</span><span>.</span><span>AVERAGE</span><span>)</span>
```

Examples:

```
<span>from</span> <span>frame_sdk.camera</span> <span>import</span> <span>Quality</span><span>,</span> <span>AutofocusType</span>

<span># take a photo and save to disk
</span><span>await</span> <span>f</span><span>.</span><span>camera</span><span>.</span><span>save_photo</span><span>(</span><span>"frame-test-photo.jpg"</span><span>)</span>

<span># or with more control
</span><span>await</span> <span>f</span><span>.</span><span>camera</span><span>.</span><span>save_photo</span><span>(</span><span>"frame-test-photo-2.jpg"</span><span>,</span> <span>autofocus_seconds</span><span>=</span><span>3</span><span>,</span> <span>quality</span><span>=</span><span>Quality</span><span>.</span><span>HIGH</span><span>,</span> <span>autofocus_type</span><span>=</span><span>AutofocusType</span><span>.</span><span>CENTER_WEIGHTED</span><span>)</span>
```
Flutter

#### Flutter

```
<span>Future</span><span>&lt;</span><span>void</span><span>&gt;</span> <span>savePhoto</span><span>(</span><span>String</span> <span>path</span><span>,</span> <span>{</span><span>int</span><span>?</span> <span>autofocusSeconds</span> <span>=</span> <span>3</span><span>,</span> <span>PhotoQuality</span> <span>quality</span> <span>=</span> <span>PhotoQuality</span><span>.</span><span>medium</span><span>,</span> <span>AutoFocusType</span> <span>autofocusType</span> <span>=</span> <span>AutoFocusType</span><span>.</span><span>average</span><span>})</span> <span>async</span>
```

Examples:

```
<span>import</span> <span>'package:frame/camera.dart'</span><span>;</span>

<span>// take a photo and save to disk</span>
<span>await</span> <span>frame</span><span>.</span><span>camera</span><span>.</span><span>savePhoto</span><span>(</span><span>"frame-test-photo.jpg"</span><span>);</span>

<span>// or with more control</span>
<span>await</span> <span>frame</span><span>.</span><span>camera</span><span>.</span><span>savePhoto</span><span>(</span>
  <span>"frame-test-photo-2.jpg"</span><span>,</span>
  <span>autofocusSeconds:</span> <span>3</span><span>,</span>
  <span>quality:</span> <span>PhotoQuality</span><span>.</span><span>high</span><span>,</span>
  <span>autofocusType:</span> <span>AutoFocusType</span><span>.</span><span>centerWeighted</span>
<span>);</span>

```

___

## Display

Display functions are available via `frame.display`.

The display engine of allows drawing of text, sprites and vectors. These elements can be layered atop one another simply in the order they are called, and then be displayed in one go using the `show()` function.

The Frame display is capable of rendering up to 16 colors at one time. These colors are preset by default, however each color can be overridden. See more information about the palette here.

### Write Text

```
<span>async</span> <span>frame</span><span>.</span><span>display</span><span>.</span><span>write_text</span><span>(</span><span>text</span><span>:</span> <span>str</span><span>,</span> <span>x</span><span>:</span> <span>int</span> <span>=</span> <span>1</span><span>,</span> <span>y</span><span>:</span> <span>int</span> <span>=</span> <span>1</span><span>,</span> <span>max_width</span><span>:</span> <span>Optional</span><span>[</span><span>int</span><span>]</span> <span>=</span> <span>640</span><span>,</span> <span>max_height</span><span>:</span> <span>Optional</span><span>[</span><span>int</span><span>]</span> <span>=</span> <span>None</span><span>,</span> <span>align</span><span>:</span> <span>Alignment</span> <span>=</span> <span>Alignment</span><span>.</span><span>TOP_LEFT</span><span>,</span> <span>color</span><span>:</span> <span>PaletteColors</span> <span>=</span> <span>PaletteColors</span><span>.</span><span>WHITE</span><span>)</span>
```

Writes `text` to the display at the specified `x`,`y`position, optionally including word wrapping and alignment. The text is not displayed until `frame.display.show()` is called.

-   `x` _(int)_: The x position to write the text at.
-   `y` _(int)_: The y position to write the text at.
-   `max_width` _(optional int)_: The maximum width for the text bounding box. If text is wider than this, it will be word-wrapped onto multiple lines automatically. Set to the full width of the display by default (640px), but can be overridden with `None`/`null` to disable word-wrapping.
-   `max_height` _(optional int)_: The maximum height for the text bounding box. If text is taller than this, it will be cut off at that height. Also useful for vertical alignment. Set to the full height of the display by default (400px), but can be overridden with `None`/`null` to the vertical cutoff (which may result in errors if the text runs too far past the bottom of the display.
-   `align` _(Alignment)_: The alignment of the text, both horizontally if a `max_width` is provided, and vertically if a `max_height` is provided. Can be any value in `frame.display.Alignment`:
    -   `frame.display.Alignment.TOP_LEFT` = Alignment.TOP\_LEFT **(DEFAULT)**
    -   `frame.display.Alignment.TOP_CENTER` = Alignment.TOP\_CENTER
    -   `frame.display.Alignment.TOP_RIGHT` = Alignment.TOP\_RIGHT
    -   `frame.display.Alignment.MIDDLE_LEFT` = Alignment.MIDDLE\_LEFT
    -   `frame.display.Alignment.MIDDLE_CENTER` = Alignment.MIDDLE\_CENTER
    -   `frame.display.Alignment.MIDDLE_RIGHT` = Alignment.MIDDLE\_RIGHT
    -   `frame.display.Alignment.BOTTOM_LEFT` = Alignment.BOTTOM\_LEFT
    -   `frame.display.Alignment.BOTTOM_CENTER` = Alignment.BOTTOM\_CENTER
    -   `frame.display.Alignment.BOTTOM_RIGHT` = Alignment.BOTTOM\_RIGHT
-   `color` _(PaletteColors)_: The color of the text. Defaults to `PaletteColors.WHITE`.

Python

#### Python

```
<span>async</span> <span>def</span> <span>write_text</span><span>(</span><span>self</span><span>,</span> <span>text</span><span>:</span> <span>str</span><span>,</span> <span>x</span><span>:</span> <span>int</span> <span>=</span> <span>1</span><span>,</span> <span>y</span><span>:</span> <span>int</span> <span>=</span> <span>1</span><span>,</span> <span>max_width</span><span>:</span> <span>Optional</span><span>[</span><span>int</span><span>]</span> <span>=</span> <span>640</span><span>,</span> <span>max_height</span><span>:</span> <span>Optional</span><span>[</span><span>int</span><span>]</span> <span>=</span> <span>None</span><span>,</span> <span>align</span><span>:</span> <span>Alignment</span> <span>=</span> <span>Alignment</span><span>.</span><span>TOP_LEFT</span><span>,</span> <span>color</span><span>:</span> <span>PaletteColors</span> <span>=</span> <span>PaletteColors</span><span>.</span><span>WHITE</span><span>):</span>
```

Examples:

```
<span>await</span> <span>frame</span><span>.</span><span>display</span><span>.</span><span>write_text</span><span>(</span><span>"Hello world"</span><span>,</span> <span>50</span><span>,</span> <span>50</span><span>)</span>
<span>await</span> <span>frame</span><span>.</span><span>display</span><span>.</span><span>show</span><span>()</span>

<span>await</span> <span>frame</span><span>.</span><span>display</span><span>.</span><span>write_text</span><span>(</span><span>"Top-left"</span><span>,</span> <span>align</span><span>=</span><span>Alignment</span><span>.</span><span>TOP_LEFT</span><span>)</span>
<span>await</span> <span>frame</span><span>.</span><span>display</span><span>.</span><span>write_text</span><span>(</span><span>"Top-Center"</span><span>,</span> <span>align</span><span>=</span><span>Alignment</span><span>.</span><span>TOP_CENTER</span><span>)</span>
<span>await</span> <span>frame</span><span>.</span><span>display</span><span>.</span><span>write_text</span><span>(</span><span>"Top-Right"</span><span>,</span> <span>align</span><span>=</span><span>Alignment</span><span>.</span><span>TOP_RIGHT</span><span>)</span>
<span>await</span> <span>frame</span><span>.</span><span>display</span><span>.</span><span>write_text</span><span>(</span><span>"Middle-Left"</span><span>,</span> <span>align</span><span>=</span><span>Alignment</span><span>.</span><span>MIDDLE_LEFT</span><span>)</span>
<span>await</span> <span>frame</span><span>.</span><span>display</span><span>.</span><span>write_text</span><span>(</span><span>"Middle-Center"</span><span>,</span> <span>align</span><span>=</span><span>Alignment</span><span>.</span><span>MIDDLE_CENTER</span><span>)</span>
<span>await</span> <span>frame</span><span>.</span><span>display</span><span>.</span><span>write_text</span><span>(</span><span>"Middle-Right"</span><span>,</span> <span>align</span><span>=</span><span>Alignment</span><span>.</span><span>MIDDLE_RIGHT</span><span>)</span>
<span>await</span> <span>frame</span><span>.</span><span>display</span><span>.</span><span>write_text</span><span>(</span><span>"Bottom-Left"</span><span>,</span> <span>align</span><span>=</span><span>Alignment</span><span>.</span><span>BOTTOM_LEFT</span><span>)</span>
<span>await</span> <span>frame</span><span>.</span><span>display</span><span>.</span><span>write_text</span><span>(</span><span>"Bottom-Center"</span><span>,</span> <span>align</span><span>=</span><span>Alignment</span><span>.</span><span>BOTTOM_CENTER</span><span>)</span>
<span>await</span> <span>frame</span><span>.</span><span>display</span><span>.</span><span>write_text</span><span>(</span><span>"Bottom-Right"</span><span>,</span> <span>align</span><span>=</span><span>Alignment</span><span>.</span><span>BOTTOM_RIGHT</span><span>)</span>
<span>await</span> <span>frame</span><span>.</span><span>display</span><span>.</span><span>show</span><span>()</span>

<span>await</span> <span>frame</span><span>.</span><span>display</span><span>.</span><span>write_text</span><span>(</span><span>"I am longer text</span><span>\n</span><span>Multiple lines can be specified manually or word wrapping can occur automatically"</span><span>,</span> <span>align</span><span>=</span><span>Alignment</span><span>.</span><span>TOP_CENTER</span><span>)</span>
<span>await</span> <span>frame</span><span>.</span><span>display</span><span>.</span><span>show</span><span>()</span>

<span># the following text will be horizontally and vertically centered within a box on the lower right of the screen
# draw the outline
</span><span>await</span> <span>frame</span><span>.</span><span>display</span><span>.</span><span>draw_rect_filled</span><span>(</span><span>x</span><span>=</span><span>400</span><span>,</span> <span>y</span><span>=</span><span>220</span><span>,</span> <span>w</span><span>=</span><span>200</span><span>,</span> <span>h</span><span>=</span><span>150</span><span>,</span> <span>border_width</span><span>=</span><span>8</span><span>,</span> <span>border_color</span><span>=</span><span>PaletteColors</span><span>.</span><span>RED</span><span>,</span> <span>fill_color</span><span>=</span><span>PaletteColors</span><span>.</span><span>CLOUDBLUE</span><span>)</span>
<span># draw the text
</span><span>await</span> <span>frame</span><span>.</span><span>display</span><span>.</span><span>write_text</span><span>(</span><span>"in the box"</span><span>,</span> <span>x</span><span>=</span><span>400</span><span>,</span> <span>y</span><span>=</span><span>220</span><span>,</span> <span>w</span><span>=</span><span>200</span><span>,</span> <span>h</span><span>=</span><span>150</span><span>,</span> <span>align</span><span>=</span><span>Alignment</span><span>.</span><span>MIDDLE_CENTER</span><span>,</span> <span>color</span><span>=</span><span>PaletteColors</span><span>.</span><span>YELLOW</span><span>)</span>
<span>await</span> <span>frame</span><span>.</span><span>display</span><span>.</span><span>show</span><span>()</span>
```
Flutter

#### Flutter

```
<span>Future</span><span>&lt;</span><span>void</span><span>&gt;</span> <span>writeText</span><span>(</span><span>String</span> <span>text</span><span>,</span>
    <span>{</span><span>int</span> <span>x</span> <span>=</span> <span>1</span><span>,</span>
    <span>int</span> <span>y</span> <span>=</span> <span>1</span><span>,</span>
    <span>int</span><span>?</span> <span>maxWidth</span> <span>=</span> <span>640</span><span>,</span>
    <span>int</span><span>?</span> <span>maxHeight</span><span>,</span>
    <span>PaletteColors</span><span>?</span> <span>color</span><span>,</span>
    <span>Alignment2D</span> <span>align</span> <span>=</span> <span>Alignment2D</span><span>.</span><span>topLeft</span><span>})</span>
```

Examples:

```
<span>await</span> <span>frame</span><span>.</span><span>display</span><span>.</span><span>writeText</span><span>(</span><span>"Hello world"</span><span>,</span> <span>x:</span> <span>50</span><span>,</span> <span>y:</span> <span>50</span><span>);</span>
<span>await</span> <span>frame</span><span>.</span><span>display</span><span>.</span><span>show</span><span>();</span>

<span>await</span> <span>frame</span><span>.</span><span>display</span><span>.</span><span>writeText</span><span>(</span><span>"Top-left"</span><span>,</span> <span>align:</span> <span>Alignment2D</span><span>.</span><span>topLeft</span><span>);</span>
<span>await</span> <span>frame</span><span>.</span><span>display</span><span>.</span><span>writeText</span><span>(</span><span>"Top-Center"</span><span>,</span> <span>align:</span> <span>Alignment2D</span><span>.</span><span>topCenter</span><span>);</span>
<span>await</span> <span>frame</span><span>.</span><span>display</span><span>.</span><span>writeText</span><span>(</span><span>"Top-Right"</span><span>,</span> <span>align:</span> <span>Alignment2D</span><span>.</span><span>topRight</span><span>);</span>
<span>await</span> <span>frame</span><span>.</span><span>display</span><span>.</span><span>writeText</span><span>(</span><span>"Middle-Left"</span><span>,</span> <span>align:</span> <span>Alignment2D</span><span>.</span><span>middleLeft</span><span>);</span>
<span>await</span> <span>frame</span><span>.</span><span>display</span><span>.</span><span>writeText</span><span>(</span><span>"Middle-Center"</span><span>,</span> <span>align:</span> <span>Alignment2D</span><span>.</span><span>middleCenter</span><span>);</span>
<span>await</span> <span>frame</span><span>.</span><span>display</span><span>.</span><span>writeText</span><span>(</span><span>"Middle-Right"</span><span>,</span> <span>align:</span> <span>Alignment2D</span><span>.</span><span>middleRight</span><span>);</span>
<span>await</span> <span>frame</span><span>.</span><span>display</span><span>.</span><span>writeText</span><span>(</span><span>"Bottom-Left"</span><span>,</span> <span>align:</span> <span>Alignment2D</span><span>.</span><span>bottomLeft</span><span>);</span>
<span>await</span> <span>frame</span><span>.</span><span>display</span><span>.</span><span>writeText</span><span>(</span><span>"Bottom-Center"</span><span>,</span> <span>align:</span> <span>Alignment2D</span><span>.</span><span>bottomCenter</span><span>);</span>
<span>await</span> <span>frame</span><span>.</span><span>display</span><span>.</span><span>writeText</span><span>(</span><span>"Bottom-Right"</span><span>,</span> <span>align:</span> <span>Alignment2D</span><span>.</span><span>bottomRight</span><span>);</span>
<span>await</span> <span>frame</span><span>.</span><span>display</span><span>.</span><span>show</span><span>();</span>

<span>await</span> <span>frame</span><span>.</span><span>display</span><span>.</span><span>writeText</span><span>(</span>
    <span>"I am longer text</span><span>\n</span><span>Multiple lines can be specified manually or word wrapping can occur automatically"</span><span>,</span>
    <span>align:</span> <span>Alignment2D</span><span>.</span><span>topCenter</span><span>);</span>
<span>await</span> <span>frame</span><span>.</span><span>display</span><span>.</span><span>show</span><span>();</span>

<span>// the following text will be horizontally and vertically centered within a box on the lower right of the screen</span>
<span>// draw the outline</span>
<span>await</span> <span>frame</span><span>.</span><span>display</span><span>.</span><span>drawRectFilled</span><span>(</span>
    <span>x:</span> <span>400</span><span>,</span> <span>y:</span> <span>220</span><span>,</span> <span>w:</span> <span>200</span><span>,</span> <span>h:</span> <span>150</span><span>,</span> <span>borderWidth:</span> <span>8</span><span>,</span> <span>borderColor:</span> <span>PaletteColors</span><span>.</span><span>red</span><span>,</span> <span>fillColor:</span> <span>PaletteColors</span><span>.</span><span>white</span><span>);</span>
<span>// draw the text</span>
<span>await</span> <span>frame</span><span>.</span><span>display</span><span>.</span><span>writeText</span><span>(</span><span>"in the box"</span><span>,</span> <span>x:</span> <span>400</span><span>,</span> <span>y:</span> <span>220</span><span>,</span> <span>maxWidth:</span> <span>200</span><span>,</span> <span>maxHeight:</span> <span>150</span><span>,</span> <span>align:</span> <span>Alignment2D</span><span>.</span><span>middleCenter</span><span>,</span> <span>color:</span> <span>PaletteColors</span><span>.</span><span>yellow</span><span>);</span>
<span>await</span> <span>frame</span><span>.</span><span>display</span><span>.</span><span>show</span><span>();</span>
```

### Show Text

```
<span>async</span> <span>frame</span><span>.</span><span>display</span><span>.</span><span>show_text</span><span>(</span><span>text</span><span>:</span> <span>str</span><span>,</span> <span>x</span><span>:</span> <span>int</span> <span>=</span> <span>1</span><span>,</span> <span>y</span><span>:</span> <span>int</span> <span>=</span> <span>1</span><span>,</span> <span>max_width</span><span>:</span> <span>Optional</span><span>[</span><span>int</span><span>]</span> <span>=</span> <span>640</span><span>,</span> <span>max_height</span><span>:</span> <span>Optional</span><span>[</span><span>int</span><span>]</span> <span>=</span> <span>None</span><span>,</span> <span>align</span><span>:</span> <span>Alignment</span> <span>=</span> <span>Alignment</span><span>.</span><span>TOP_LEFT</span><span>,</span> <span>color</span><span>:</span> <span>PaletteColors</span> <span>=</span> <span>PaletteColors</span><span>.</span><span>WHITE</span><span>)</span>
```

`show_text` is the same as `write_text` except that it immediately displays the text on the screen. It’s equivalent to calling `frame.display.write_text()` and then `frame.display.show()`.

Note that each time you call `show_text()`, it will clear any previous text and graphics. If you want to add text to the screen without erasing what’s already there, then you should use `write_text()` instead.

### Scroll Text

```
<span>async</span> <span>frame</span><span>.</span><span>display</span><span>.</span><span>scroll_text</span><span>(</span><span>text</span><span>:</span> <span>str</span><span>,</span> <span>lines_per_frame</span><span>:</span> <span>int</span> <span>=</span> <span>5</span><span>,</span> <span>delay</span><span>:</span> <span>float</span> <span>=</span> <span>0.12</span><span>,</span> <span>color</span><span>:</span> <span>PaletteColors</span> <span>=</span> <span>PaletteColors</span><span>.</span><span>WHITE</span><span>)</span>
```

Animates scrolling text vertically. Best when `text` is longer than the display height. You can adjust the speed of the scroll by changing `lines_per_frame` and `delay`, but note that depending on how much text is on the screen, a `delay` below 0.12 seconds may result in graphical glitches due to hardware limitations.

This function blocks until the text has finished scrolling, and includes a small margin on time on either end to make sure the text is fully readable.

-   `text` _(str)_: The text to scroll. It is automatically wrapped to fit the display width.
-   `lines_per_frame` _(int)_: The number of vertical pixels to scroll per frame. Defaults to 5. Higher values scroll faster, but will be more jumpy.
-   `delay` _(float)_: The delay between frames in seconds. Defaults to 0.12 seconds. Lower values are faster, but may cause graphical glitches.
-   `color` _(PaletteColors)_: The color of the text. Defaults to `PaletteColors.WHITE`.

Python

#### Python

```
<span>async</span> <span>def</span> <span>scroll_text</span><span>(</span><span>self</span><span>,</span> <span>text</span><span>:</span> <span>str</span><span>,</span> <span>lines_per_frame</span><span>:</span> <span>int</span> <span>=</span> <span>5</span><span>,</span> <span>delay</span><span>:</span> <span>float</span> <span>=</span> <span>0.12</span><span>,</span> <span>color</span><span>:</span> <span>PaletteColors</span> <span>=</span> <span>PaletteColors</span><span>.</span><span>WHITE</span><span>)</span>
```

Example:

```
<span>print</span><span>(</span><span>"scrolling about to start"</span><span>)</span>
<span>await</span> <span>frame</span><span>.</span><span>display</span><span>.</span><span>scroll_text</span><span>(</span><span>"Never gonna give you up</span><span>\n</span><span>Never gonna let you down</span><span>\n</span><span>Never gonna run around and desert you</span><span>\n</span><span>Never gonna make you cry</span><span>\n</span><span>Never gonna say goodbye</span><span>\n</span><span>Never gonna tell a lie and hurt you</span><span>\n</span><span>Never gonna stop</span><span>\n</span><span>Never gonna give you up</span><span>\n</span><span>Never gonna let you down</span><span>\n</span><span>Never gonna run around and desert you</span><span>\n</span><span>Never gonna make you cry</span><span>\n</span><span>Never gonna say goodbye</span><span>\n</span><span>Never gonna tell a lie and hurt you"</span><span>)</span>
<span>print</span><span>(</span><span>"scrolling finished"</span><span>)</span>

<span>print</span><span>(</span><span>"scrolling slowly about to start"</span><span>)</span>
<span>await</span> <span>frame</span><span>.</span><span>display</span><span>.</span><span>scroll_text</span><span>(</span><span>"Never gonna give you up</span><span>\n</span><span>Never gonna let you down</span><span>\n</span><span>Never gonna run around and desert you</span><span>\n</span><span>Never gonna make you cry</span><span>\n</span><span>Never gonna say goodbye</span><span>\n</span><span>Never gonna tell a lie and hurt you</span><span>\n</span><span>Never gonna stop</span><span>\n</span><span>Never gonna give you up</span><span>\n</span><span>Never gonna let you down</span><span>\n</span><span>Never gonna run around and desert you</span><span>\n</span><span>Never gonna make you cry</span><span>\n</span><span>Never gonna say goodbye</span><span>\n</span><span>Never gonna tell a lie and hurt you"</span><span>,</span> <span>lines_per_frame</span><span>=</span><span>2</span><span>,</span> <span>color</span><span>=</span><span>PaletteColors</span><span>.</span><span>YELLOW</span><span>)</span>
<span>print</span><span>(</span><span>"scrolling slowly finished"</span><span>)</span>
```
Flutter

#### Flutter

```
<span>Future</span><span>&lt;</span><span>void</span><span>&gt;</span> <span>scrollText</span><span>(</span><span>String</span> <span>text</span><span>,</span> <span>{</span><span>int</span> <span>linesPerFrame</span> <span>=</span> <span>5</span><span>,</span> <span>double</span> <span>delay</span> <span>=</span> <span>0.12</span><span>,</span> <span>PaletteColors</span><span>?</span> <span>textColor</span><span>})</span> <span>async</span>
```

Example:

```
<span>print</span><span>(</span><span>"scrolling about to start"</span><span>);</span>
<span>await</span> <span>frame</span><span>.</span><span>display</span><span>.</span><span>scrollText</span><span>(</span><span>"Never gonna give you up</span><span>\n</span><span>Never gonna let you down</span><span>\n</span><span>Never gonna run around and desert you</span><span>\n</span><span>Never gonna make you cry</span><span>\n</span><span>Never gonna say goodbye</span><span>\n</span><span>Never gonna tell a lie and hurt you</span><span>\n</span><span>Never gonna stop</span><span>\n</span><span>Never gonna give you up</span><span>\n</span><span>Never gonna let you down</span><span>\n</span><span>Never gonna run around and desert you</span><span>\n</span><span>Never gonna make you cry</span><span>\n</span><span>Never gonna say goodbye</span><span>\n</span><span>Never gonna tell a lie and hurt you"</span><span>);</span>
<span>print</span><span>(</span><span>"scrolling finished"</span><span>);</span>

<span>print</span><span>(</span><span>"scrolling slowly about to start"</span><span>);</span>
<span>await</span> <span>frame</span><span>.</span><span>display</span><span>.</span><span>scrollText</span><span>(</span><span>"Never gonna give you up</span><span>\n</span><span>Never gonna let you down</span><span>\n</span><span>Never gonna run around and desert you</span><span>\n</span><span>Never gonna make you cry</span><span>\n</span><span>Never gonna say goodbye</span><span>\n</span><span>Never gonna tell a lie and hurt you</span><span>\n</span><span>Never gonna stop</span><span>\n</span><span>Never gonna give you up</span><span>\n</span><span>Never gonna let you down</span><span>\n</span><span>Never gonna run around and desert you</span><span>\n</span><span>Never gonna make you cry</span><span>\n</span><span>Never gonna say goodbye</span><span>\n</span><span>Never gonna tell a lie and hurt you"</span><span>,</span> <span>linesPerFrame:</span> <span>2</span><span>,</span> <span>textColor:</span> <span>PaletteColors</span><span>.</span><span>yellow</span><span>);</span>
<span>print</span><span>(</span><span>"scrolling slowly finished"</span><span>);</span>
```

### Draw Rectangle

```
<span>frame</span><span>.</span><span>display</span><span>.</span><span>draw_rect</span><span>(</span><span>x</span><span>:</span> <span>int</span><span>,</span> <span>y</span><span>:</span> <span>int</span><span>,</span> <span>w</span><span>:</span> <span>int</span><span>,</span> <span>h</span><span>:</span> <span>int</span><span>,</span> <span>color</span><span>:</span> <span>PaletteColors</span> <span>=</span> <span>PaletteColors</span><span>.</span><span>WHITE</span><span>)</span>
```

Draws a filled rectangle specified `color` at `x`,`y` with `w` width and `h` height.

The rectangle is drawn in the current buffer, which is not displayed until you call `frame.display.show()`.

Currently, the `x`, `y`, `w`, and `h` parameters are rounded down to the closest multiple of 8, for performance reasons. This is likely to be changed in the future.

-   `x` _(int)_: The x position of the upper-left corner of the rectangle.
-   `y` _(int)_: The y position of the upper-left corner of the rectangle.
-   `w` _(int)_: The width of the rectangle.
-   `h` _(int)_: The height of the rectangle.
-   `color` _(PaletteColors)_: The color of the rectangle. Defaults to `PaletteColors.WHITE`.

Python

#### Python

```
<span>async</span> <span>def</span> <span>draw_rect</span><span>(</span><span>self</span><span>,</span> <span>x</span><span>:</span> <span>int</span><span>,</span> <span>y</span><span>:</span> <span>int</span><span>,</span> <span>w</span><span>:</span> <span>int</span><span>,</span> <span>h</span><span>:</span> <span>int</span><span>,</span> <span>color</span><span>:</span> <span>PaletteColors</span> <span>=</span> <span>PaletteColors</span><span>.</span><span>WHITE</span><span>)</span>
```

Example:

```
<span># draws a white rectangle 200x200 pixels in the center of the screen
</span><span>await</span> <span>frame</span><span>.</span><span>display</span><span>.</span><span>draw_rect</span><span>(</span><span>220</span><span>,</span> <span>100</span><span>,</span> <span>200</span><span>,</span> <span>200</span><span>,</span> <span>PaletteColors</span><span>.</span><span>WHITE</span><span>)</span>

<span># draws a red rectangle 16x16 pixels in the center of the screen
</span><span>await</span> <span>frame</span><span>.</span><span>display</span><span>.</span><span>draw_rect</span><span>(</span><span>320</span><span>-</span><span>8</span><span>,</span> <span>200</span><span>-</span><span>8</span><span>,</span> <span>16</span><span>,</span> <span>16</span><span>,</span> <span>PaletteColors</span><span>.</span><span>RED</span><span>)</span>

<span># show both rectangles
</span><span>await</span> <span>frame</span><span>.</span><span>display</span><span>.</span><span>show</span><span>()</span>
```
Flutter

#### Flutter

```
<span>Future</span><span>&lt;</span><span>void</span><span>&gt;</span> <span>drawRect</span><span>(</span><span>int</span> <span>x</span><span>,</span> <span>int</span> <span>y</span><span>,</span> <span>int</span> <span>w</span><span>,</span> <span>int</span> <span>h</span><span>,</span> <span>PaletteColors</span> <span>color</span><span>)</span> <span>async</span>
```

Example:

```
<span>// draws a white rectangle 200x200 pixels in the center of the screen</span>
<span>await</span> <span>frame</span><span>.</span><span>display</span><span>.</span><span>drawRect</span><span>(</span><span>220</span><span>,</span> <span>100</span><span>,</span> <span>200</span><span>,</span> <span>200</span><span>,</span> <span>PaletteColors</span><span>.</span><span>white</span><span>);</span>

<span>// draws a red rectangle 16x16 pixels in the center of the screen</span>
<span>await</span> <span>frame</span><span>.</span><span>display</span><span>.</span><span>drawRect</span><span>(</span><span>320</span><span>-</span><span>8</span><span>,</span> <span>200</span><span>-</span><span>8</span><span>,</span> <span>16</span><span>,</span> <span>16</span><span>,</span> <span>PaletteColors</span><span>.</span><span>red</span><span>);</span>

<span>// show both rectangles</span>
<span>await</span> <span>frame</span><span>.</span><span>display</span><span>.</span><span>show</span><span>();</span>
```

### Draw Rectangle Filled

```
<span>frame</span><span>.</span><span>display</span><span>.</span><span>draw_rect_filled</span><span>(</span><span>x</span><span>:</span> <span>int</span><span>,</span> <span>y</span><span>:</span> <span>int</span><span>,</span> <span>w</span><span>:</span> <span>int</span><span>,</span> <span>h</span><span>:</span> <span>int</span><span>,</span> <span>border_width</span><span>:</span> <span>int</span><span>,</span> <span>border_color</span><span>:</span> <span>PaletteColors</span><span>,</span> <span>fill_color</span><span>:</span> <span>PaletteColors</span><span>)</span>
```

Draws a filled rectangle with a border and fill color at `x`,`y` with `w` width and `h` height, with an inset border `border_width` pixels wide. The total size of the rectangle including the border is `w`x`h`.

Currently, the `x`, `y`, `w`, `h`, and `border_width` parameters are rounded down to the closest multiple of 8, for performance reasons. This is likely to be changed in the future.

-   `x` _(int)_: The x position of the upper-left corner of the rectangle.
-   `y` _(int)_: The y position of the upper-left corner of the rectangle.
-   `w` _(int)_: The width of the rectangle.
-   `h` _(int)_: The height of the rectangle.
-   `border_width` _(int)_: The width of the border in pixels.
-   `border_color` _(PaletteColors)_: The color of the border.
-   `fill_color` _(PaletteColors)_: The color of the fill.

Python

#### Python

```
<span>async</span> <span>def</span> <span>draw_rect_filled</span><span>(</span><span>self</span><span>,</span> <span>x</span><span>:</span> <span>int</span><span>,</span> <span>y</span><span>:</span> <span>int</span><span>,</span> <span>w</span><span>:</span> <span>int</span><span>,</span> <span>h</span><span>:</span> <span>int</span><span>,</span> <span>border_width</span><span>:</span> <span>int</span><span>,</span> <span>border_color</span><span>:</span> <span>PaletteColors</span><span>,</span> <span>fill_color</span><span>:</span> <span>PaletteColors</span><span>)</span>
```

Example:

```
<span># draws a dialog box with a border and text
</span><span>await</span> <span>frame</span><span>.</span><span>display</span><span>.</span><span>draw_rect_filled</span><span>(</span><span>x</span><span>=</span><span>100</span><span>,</span> <span>y</span><span>=</span><span>100</span><span>,</span> <span>w</span><span>=</span><span>200</span><span>,</span> <span>h</span><span>=</span><span>200</span><span>,</span> <span>border_width</span><span>=</span><span>8</span><span>,</span> <span>border_color</span><span>=</span><span>PaletteColors</span><span>.</span><span>RED</span><span>,</span> <span>fill_color</span><span>=</span><span>PaletteColors</span><span>.</span><span>CLOUDBLUE</span><span>)</span>
<span>await</span> <span>frame</span><span>.</span><span>display</span><span>.</span><span>write_text</span><span>(</span><span>"Hello world!"</span><span>,</span> <span>x</span><span>=</span><span>110</span><span>,</span> <span>y</span><span>=</span><span>110</span><span>,</span> <span>w</span><span>=</span><span>180</span><span>,</span> <span>h</span><span>=</span><span>180</span><span>,</span> <span>align</span><span>=</span><span>Alignment</span><span>.</span><span>MIDDLE_CENTER</span><span>)</span>
<span>await</span> <span>frame</span><span>.</span><span>display</span><span>.</span><span>show</span><span>()</span>
```
Flutter

#### Flutter

```
<span>Future</span><span>&lt;</span><span>void</span><span>&gt;</span> <span>drawRectFilled</span><span>(</span><span>int</span> <span>x</span><span>,</span> <span>int</span> <span>y</span><span>,</span> <span>int</span> <span>w</span><span>,</span> <span>int</span> <span>h</span><span>,</span> <span>int</span> <span>borderWidth</span><span>,</span> <span>PaletteColors</span> <span>borderColor</span><span>,</span> <span>PaletteColors</span> <span>fillColor</span><span>)</span> <span>async</span>
```

Example:

```
<span>// draws a dialog box with a border and text</span>
<span>await</span> <span>frame</span><span>.</span><span>display</span><span>.</span><span>drawRectFilled</span><span>(</span><span>100</span><span>,</span> <span>100</span><span>,</span> <span>200</span><span>,</span> <span>200</span><span>,</span> <span>8</span><span>,</span> <span>PaletteColors</span><span>.</span><span>RED</span><span>,</span> <span>PaletteColors</span><span>.</span><span>CLOUDBLUE</span><span>);</span>
<span>await</span> <span>frame</span><span>.</span><span>display</span><span>.</span><span>writeText</span><span>(</span><span>"Hello world!"</span><span>,</span> <span>x:</span> <span>110</span><span>,</span> <span>y:</span> <span>110</span><span>,</span> <span>maxWidth:</span> <span>180</span><span>,</span> <span>maxHeight:</span> <span>180</span><span>,</span> <span>align:</span> <span>Alignment2D</span><span>.</span><span>middleCenter</span><span>);</span>
<span>await</span> <span>frame</span><span>.</span><span>display</span><span>.</span><span>show</span><span>();</span>
```

### Additional Display Helpers

While the above functions are the most common ones you’ll use, there are a few other display-related functions and properties that you may find useful on occasion.

#### Line Height

```
<span>frame</span><span>.</span><span>display</span><span>.</span><span>line_height</span><span>:</span> <span>int</span> <span>=</span> <span>60</span>
```

The `line_height` property (`lineHeight` in Flutter) is used to get and set the height of each line of text in pixels. It is 60 by default, however you may override that value to change the vertical spacing of the text in all text displaying functions. It must be greater than 0.

#### Character Width

```
<span>frame</span><span>.</span><span>display</span><span>.</span><span>char_width</span><span>:</span> <span>int</span> <span>=</span> <span>4</span>
```

The `char_width` property (`charWidth` in Flutter) is used to get and set the extra horizontal spacing after each character. It is 4 by default, however you may override that value to change the horizontal spacing of the text in all text displaying functions.

#### Get Text Width and Height

```
<span>frame</span><span>.</span><span>display</span><span>.</span><span>get_text_width</span><span>(</span><span>text</span><span>:</span> <span>str</span><span>)</span> <span>-&gt;</span> <span>int</span>
<span>frame</span><span>.</span><span>display</span><span>.</span><span>get_text_height</span><span>(</span><span>text</span><span>:</span> <span>str</span><span>)</span> <span>-&gt;</span> <span>int</span>
```

```
<span>int</span> <span>frame</span><span>.</span><span>display</span><span>.</span><span>getTextWidth</span><span>(</span><span>String</span> <span>text</span><span>)</span>
<span>int</span> <span>frame</span><span>.</span><span>display</span><span>.</span><span>getTextHeight</span><span>(</span><span>String</span> <span>text</span><span>)</span>
```

Gets the rendered width and height of text in pixels. Text on Frame is variable width, so this is important for positioning text. Note that these functions do not perform any text wrapping but do respect any manually-included line breaks, and you can use the outputs in your own word-wrapping or positioning logic. The width is affected by the `char_width` property, and the height is affected by the `line_height` property (as well as `char_width` if word wrapping).

#### Wrap Text

```
<span>frame</span><span>.</span><span>display</span><span>.</span><span>wrap_text</span><span>(</span><span>text</span><span>:</span> <span>str</span><span>,</span> <span>max_width</span><span>:</span> <span>int</span><span>)</span> <span>-&gt;</span> <span>str</span>
```

```
<span>String</span> <span>frame</span><span>.</span><span>display</span><span>.</span><span>wrapText</span><span>(</span><span>String</span> <span>text</span><span>,</span> <span>int</span> <span>maxWidth</span><span>)</span>
```

Wraps text to fit within a specified width. It does this by inserting line breaks at space characters, returning a string with extra ‘\\n’ characters where line wrapping is needed.

## Microphone

The microphone is accessible via the `frame.microphone` object. The microphone on Frame allows for streaming audio to a host device in real-time.

### Record Audio

```
<span>async</span> <span>frame</span><span>.</span><span>microphone</span><span>.</span><span>record_audio</span><span>(</span><span>silence_cutoff_length_in_seconds</span><span>:</span> <span>Optional</span><span>[</span><span>int</span><span>]</span> <span>=</span> <span>3</span><span>,</span> <span>max_length_in_seconds</span><span>:</span> <span>int</span> <span>=</span> <span>30</span><span>)</span> <span>-&gt;</span> <span>np</span><span>.</span><span>ndarray</span>
```

Records audio from the microphone and returns it as a numpy array of int16 or int8 depending on the `bit_depth`.

-   `silence_cutoff_length_in_seconds` _(int)_: The length of silence in seconds to allow before stopping the recording. Defaults to 3 seconds, however you can set to None to disable silence detection. Uses the `silence_threshold` to adjust sensitivity.
-   `max_length_in_seconds` _(int)_: The maximum length of the recording in seconds, regardless of silence. Defaults to 30 seconds.

Python

#### Python

```
<span>async</span> <span>def</span> <span>record_audio</span><span>(</span><span>self</span><span>,</span> <span>silence_cutoff_length_in_seconds</span><span>:</span> <span>Optional</span><span>[</span><span>int</span><span>]</span> <span>=</span> <span>3</span><span>,</span> <span>max_length_in_seconds</span><span>:</span> <span>int</span> <span>=</span> <span>30</span><span>)</span> <span>-&gt;</span> <span>np</span><span>.</span><span>ndarray</span>
```

Examples:

```
<span># record audio for up to 30 seconds, or until 3 seconds of silence is detected
</span><span>audio</span> <span>=</span> <span>await</span> <span>frame</span><span>.</span><span>microphone</span><span>.</span><span>record_audio</span><span>()</span>

<span># record audio for 5 seconds without silence detection
</span><span>audio</span> <span>=</span> <span>await</span> <span>frame</span><span>.</span><span>microphone</span><span>.</span><span>record_audio</span><span>(</span><span>silence_cutoff_length_in_seconds</span><span>=</span><span>None</span><span>,</span> <span>max_length_in_seconds</span><span>=</span><span>5</span><span>)</span>
```
Flutter

#### Flutter

```
<span>Future</span><span>&lt;</span><span>Uint8List</span><span>&gt;</span> <span>recordAudio</span><span>({</span><span>Duration</span><span>?</span> <span>silenceCutoffLength</span> <span>=</span> <span>const</span> <span>Duration</span><span>(</span><span>seconds:</span> <span>3</span><span>),</span> <span>Duration</span> <span>maxLength</span> <span>=</span> <span>const</span> <span>Duration</span><span>(</span><span>seconds:</span> <span>30</span><span>)})</span> <span>async</span>
```

Examples:

```
<span>// record audio for up to 30 seconds, or until 3 seconds of silence is detected</span>
<span>Uint8List</span> <span>audio</span> <span>=</span> <span>await</span> <span>frame</span><span>.</span><span>microphone</span><span>.</span><span>recordAudio</span><span>();</span>

<span>// record audio for 5 seconds without silence detection</span>
<span>Uint8List</span> <span>audio</span> <span>=</span> <span>await</span> <span>frame</span><span>.</span><span>microphone</span><span>.</span><span>recordAudio</span><span>(</span><span>silenceCutoffLength:</span> <span>null</span><span>,</span> <span>maxLength:</span> <span>Duration</span><span>(</span><span>seconds:</span> <span>5</span><span>));</span>
```

### Save Audio File

```
<span>async</span> <span>frame</span><span>.</span><span>microphone</span><span>.</span><span>save_audio_file</span><span>(</span><span>filename</span><span>:</span> <span>str</span><span>,</span> <span>silence_cutoff_length_in_seconds</span><span>:</span> <span>int</span> <span>=</span> <span>3</span><span>,</span> <span>max_length_in_seconds</span><span>:</span> <span>int</span> <span>=</span> <span>30</span><span>)</span> <span>-&gt;</span> <span>float</span>
```

Records audio from the microphone and saves it to a file in PCM Wav format. Returns the number of seconds of audio recorded.

-   `filename` _(str)_: The name of the file to save the audio to. Regardless of any filename extension, the file will be saved as a PCM wav file.
-   `silence_cutoff_length_in_seconds` _(int)_: The length of silence in seconds to allow before stopping the recording. Defaults to 3 seconds, however you can set to None to disable silence detection. Uses the `silence_threshold` to adjust sensitivity.
-   `max_length_in_seconds` _(int)_: The maximum length of the recording in seconds, regardless of silence. Defaults to 30 seconds.

Python

#### Python

```
<span>async</span> <span>def</span> <span>save_audio_file</span><span>(</span><span>self</span><span>,</span> <span>filename</span><span>:</span> <span>str</span><span>,</span> <span>silence_cutoff_length_in_seconds</span><span>:</span> <span>int</span> <span>=</span> <span>3</span><span>,</span> <span>max_length_in_seconds</span><span>:</span> <span>int</span> <span>=</span> <span>30</span><span>)</span> <span>-&gt;</span> <span>float</span>
```

Examples:

```
<span># record audio for up to 30 seconds, or until 3 seconds of silence is detected
</span><span>await</span> <span>frame</span><span>.</span><span>microphone</span><span>.</span><span>save_audio_file</span><span>(</span><span>"audio.wav"</span><span>)</span>

<span># record audio for 5 seconds without silence detection
</span><span>await</span> <span>frame</span><span>.</span><span>microphone</span><span>.</span><span>save_audio_file</span><span>(</span><span>"audio.wav"</span><span>,</span> <span>silence_cutoff_length_in_seconds</span><span>=</span><span>None</span><span>,</span> <span>max_length_in_seconds</span><span>=</span><span>5</span><span>)</span>
```
Flutter

#### Flutter

```
<span>Future</span><span>&lt;</span><span>double</span><span>&gt;</span> <span>saveAudioFile</span><span>(</span><span>String</span> <span>filename</span><span>,</span> <span>{</span><span>Duration</span><span>?</span> <span>silenceCutoffLength</span> <span>=</span> <span>const</span> <span>Duration</span><span>(</span><span>seconds:</span> <span>3</span><span>),</span> <span>Duration</span> <span>maxLength</span> <span>=</span> <span>const</span> <span>Duration</span><span>(</span><span>seconds:</span> <span>30</span><span>)})</span> <span>async</span>
```

Examples:

```
<span>// record audio for up to 30 seconds, or until 3 seconds of silence is detected</span>
<span>await</span> <span>frame</span><span>.</span><span>microphone</span><span>.</span><span>saveAudioFile</span><span>(</span><span>"audio.wav"</span><span>);</span>

<span>// record audio for 5 seconds without silence detection</span>
<span>await</span> <span>frame</span><span>.</span><span>microphone</span><span>.</span><span>saveAudioFile</span><span>(</span><span>"audio.wav"</span><span>,</span> <span>silenceCutoffLength:</span> <span>null</span><span>,</span> <span>maxLength:</span> <span>Duration</span><span>(</span><span>seconds:</span> <span>5</span><span>));</span>
```

### Play Audio

```
<span>frame</span><span>.</span><span>microphone</span><span>.</span><span>play_audio_background</span><span>(</span><span>audio_data</span><span>:</span> <span>np</span><span>.</span><span>ndarray</span><span>,</span> <span>sample_rate</span><span>:</span> <span>Optional</span><span>[</span><span>int</span><span>]</span> <span>=</span> <span>None</span><span>,</span> <span>bit_depth</span><span>:</span> <span>Optional</span><span>[</span><span>int</span><span>]</span> <span>=</span> <span>None</span><span>)</span>
<span>frame</span><span>.</span><span>microphone</span><span>.</span><span>play_audio</span><span>(</span><span>audio_data</span><span>:</span> <span>np</span><span>.</span><span>ndarray</span><span>,</span> <span>sample_rate</span><span>:</span> <span>Optional</span><span>[</span><span>int</span><span>]</span> <span>=</span> <span>None</span><span>,</span> <span>bit_depth</span><span>:</span> <span>Optional</span><span>[</span><span>int</span><span>]</span> <span>=</span> <span>None</span><span>)</span>
<span>async</span> <span>frame</span><span>.</span><span>microphone</span><span>.</span><span>play_audio_async</span><span>(</span><span>audio_data</span><span>:</span> <span>np</span><span>.</span><span>ndarray</span><span>,</span> <span>sample_rate</span><span>:</span> <span>Optional</span><span>[</span><span>int</span><span>]</span> <span>=</span> <span>None</span><span>,</span> <span>bit_depth</span><span>:</span> <span>Optional</span><span>[</span><span>int</span><span>]</span> <span>=</span> <span>None</span><span>)</span>
```

```
<span>void</span> <span>playAudio</span><span>(</span><span>Uint8List</span> <span>audioData</span><span>,</span> <span>{</span><span>int</span><span>?</span> <span>sampleRate</span><span>,</span> <span>int</span><span>?</span> <span>bitDepth</span><span>})</span>
```

Helpers to play audio from `record_audio()` on your computer. `play_audio` blocks until playback is complete, while `play_audio_async` plays the audio in a coroutine. Note that only `play_audio_background` works on Windows at the moment.

-   `audio_data` _(np.ndarray)_: The audio data to play, as returned from `record_audio()`.
-   `sample_rate` _(int)_: The sample rate of the audio data, in case it’s different from the current `sample_rate`.
-   `bit_depth` _(int)_: The bit depth of the audio data, in case it’s different from the current `bit_depth`.

### Sample Rate and Bit Depth

```
<span>frame</span><span>.</span><span>microphone</span><span>.</span><span>sample_rate</span><span>:</span> <span>int</span> <span>=</span> <span>8000</span>
<span>frame</span><span>.</span><span>microphone</span><span>.</span><span>bit_depth</span><span>:</span> <span>int</span> <span>=</span> <span>16</span>
```

```
<span>int</span> <span>frame</span><span>.</span><span>microphone</span><span>.</span><span>sampleRate</span> <span>=</span> <span>8000</span><span>;</span>
<span>int</span> <span>frame</span><span>.</span><span>microphone</span><span>.</span><span>bitDepth</span> <span>=</span> <span>16</span><span>;</span>
```

The `sample_rate` property (`sampleRate` in Flutter) is used to get and set the sample rate of the microphone. It is 8000 by default, however you may override that value to change the sample rate of the microphone. Valid values are 8000 and 16000.

The `bit_depth` property (`bitDepth` in Flutter) is used to get and set the bit depth of the microphone. It is 16 by default, however you may override that value to change the bit depth of the microphone. Valid values are 8 and 16.

Transfers are limited by the Bluetooth bandwidth which is typically around 40kBps under good signal conditions. The audio bitrate for a given `sample_rate` and `bit_depth` is: `sample_rate * bit_depth / 8` bytes per second. An internal 32k buffer automatically compensates for additional tasks that might otherwise briefly block Bluetooth transfers. If this buffer limit is exceeded however, then discontinuities in audio might occur.

### Silence Threshold

```
<span>frame</span><span>.</span><span>microphone</span><span>.</span><span>silence_threshold</span><span>:</span> <span>float</span> <span>=</span> <span>0.02</span>
```

```
<span>double</span> <span>frame</span><span>.</span><span>microphone</span><span>.</span><span>silenceThreshold</span> <span>=</span> <span>0.02</span><span>;</span>
```

The `silence_threshold` property (`silenceThreshold` in Flutter) is used to get and set the threshold for detecting silence in the audio stream. Valid values are between 0 and 1. 0.02 is the default, however you may adjust this value to be more or less sensitive to sound.

## Motion

Motion data is available via the `frame.motion` object. The motion data is collected by the accelerometer and compass on the Frame. You may also register a callback for when the user taps the Frame.

### Get Direction

```
<span>async</span> <span>frame</span><span>.</span><span>motion</span><span>.</span><span>get_direction</span><span>()</span> <span>-&gt;</span> <span>Direction</span>
```

Gets the current orientation of the Frame. Returns a `Direction` object.

The `Direction` object contains the following properties:

| Property | Type | Range | Description | Examples |
| --- | --- | --- | --- | --- |
| `roll` | float | \-180 to 180 | The roll angle of the Frame, in degrees. | 20.0 (right side up, head tilted to the left), -20.0 (left side up, head tilted to the right) |
| `pitch` | float | \-180 to 180 | The pitch angle of the Frame, in degrees. | 40.0 (nose pulled down, looking at the floor), -40.0 (nose pulled up, looking towards the ceiling) |
| `heading` | float | 0 to 360 | The heading angle of the Frame, in degrees. | _not yet implemented_ |
| `amplitude()` | float | \>= 0 | Returns the amplitude of the motion vector. | 0 (looking straight ahead), 20 (a bit away from looking straight ahead) |

The `roll`, `pitch`, and `heading` properties represent the orientation of the Frame in 3D space. The `amplitude()` method returns the magnitude of the motion vector, which can be useful for detecting the intensity of movements.

A standard “looking forward” position has a roll of 0 and a pitch of 0.

The compass data is not yet implemented, so the heading value will always be 0. You can still get the pitch and roll values, however.

Python

#### Python

```
<span>async</span> <span>def</span> <span>get_direction</span><span>(</span><span>self</span><span>)</span> <span>-&gt;</span> <span>Direction</span>
```

Example:

```
<span>direction</span> <span>=</span> <span>await</span> <span>frame</span><span>.</span><span>motion</span><span>.</span><span>get_direction</span><span>()</span>
<span>print</span><span>(</span><span>direction</span><span>)</span>

<span>intensity_of_motion</span> <span>=</span> <span>0</span>
<span>prev_direction</span> <span>=</span> <span>await</span> <span>f</span><span>.</span><span>motion</span><span>.</span><span>get_direction</span><span>()</span>
<span>for</span> <span>_</span> <span>in</span> <span>range</span><span>(</span><span>10</span><span>):</span>
    <span>await</span> <span>asyncio</span><span>.</span><span>sleep</span><span>(</span><span>0.1</span><span>)</span>
    <span>direction</span> <span>=</span> <span>await</span> <span>f</span><span>.</span><span>motion</span><span>.</span><span>get_direction</span><span>()</span>
    <span>intensity_of_motion</span> <span>=</span> <span>max</span><span>(</span><span>intensity_of_motion</span><span>,</span> <span>(</span><span>direction</span><span>-</span><span>prev_direction</span><span>).</span><span>amplitude</span><span>())</span>
    <span>prev_direction</span> <span>=</span> <span>direction</span>
<span>print</span><span>(</span><span>f</span><span>"Intensity of motion: </span><span>{</span><span>intensity_of_motion</span><span>}</span><span>"</span><span>)</span>
<span>await</span> <span>f</span><span>.</span><span>display</span><span>.</span><span>show_text</span><span>(</span><span>f</span><span>"Intensity of motion: </span><span>{</span><span>intensity_of_motion</span><span>}</span><span>"</span><span>,</span> <span>align</span><span>=</span><span>Alignment</span><span>.</span><span>MIDDLE_CENTER</span><span>)</span>
```
Flutter

#### Flutter

```
<span>Future</span><span>&lt;</span><span>Direction</span><span>&gt;</span> <span>getDirection</span><span>()</span> <span>async</span>
```

Example:

```
<span>// get the direction</span>
<span>Direction</span> <span>direction</span> <span>=</span> <span>await</span> <span>frame</span><span>.</span><span>motion</span><span>.</span><span>getDirection</span><span>();</span>

<span>// track the intensity of motion</span>
<span>double</span> <span>intensityOfMotion</span> <span>=</span> <span>0</span><span>;</span>
<span>Direction</span> <span>prevDirection</span> <span>=</span> <span>await</span> <span>frame</span><span>.</span><span>motion</span><span>.</span><span>getDirection</span><span>();</span>
<span>for</span> <span>(</span><span>int</span> <span>i</span> <span>=</span> <span>0</span><span>;</span> <span>i</span> <span>&lt;</span> <span>10</span><span>;</span> <span>i</span><span>++</span><span>)</span> <span>{</span>
  <span>await</span> <span>Future</span><span>.</span><span>delayed</span><span>(</span><span>Duration</span><span>(</span><span>milliseconds:</span> <span>100</span><span>));</span>
  <span>direction</span> <span>=</span> <span>await</span> <span>frame</span><span>.</span><span>motion</span><span>.</span><span>getDirection</span><span>();</span>
  <span>intensityOfMotion</span> <span>=</span> <span>max</span><span>(</span><span>intensityOfMotion</span><span>,</span> <span>(</span><span>direction</span> <span>-</span> <span>prevDirection</span><span>)</span><span>.</span><span>amplitude</span><span>());</span>
  <span>prevDirection</span> <span>=</span> <span>direction</span><span>;</span>
<span>}</span>
<span>print</span><span>(</span><span>"Intensity of motion: </span><span>$intensityOfMotion</span><span>"</span><span>);</span>
<span>await</span> <span>frame</span><span>.</span><span>display</span><span>.</span><span>showText</span><span>(</span><span>"Intensity of motion: </span><span>$intensityOfMotion</span><span>"</span><span>,</span> <span>align:</span> <span>Alignment</span><span>.</span><span>middleCenter</span><span>);</span>
```

### Run On Tap

```
<span>async</span> <span>frame</span><span>.</span><span>motion</span><span>.</span><span>run_on_tap</span><span>(</span><span>lua_script</span><span>:</span> <span>Optional</span><span>[</span><span>str</span><span>]</span> <span>=</span> <span>None</span><span>,</span> <span>callback</span><span>:</span> <span>Optional</span><span>[</span><span>Callable</span><span>[[],</span> <span>None</span><span>]]</span> <span>=</span> <span>None</span><span>)</span> <span>-&gt;</span> <span>None</span>
```

Run a Lua script and/or callback when the user taps the Frame. Replaces any previously set callbacks. If None is provided for both `lua_script` and `callback`, then previously set callbacks will be removed.

-   `lua_script` _(str)_: A Lua script to run on the Frame when the user taps the Frame. This runs even if the Frame is not connected via bluetooth at the time of the tap.
-   `callback` _(Callable\[\[\], None\]\])_: A callback function to run locally when the user taps the Frame. This will only run if the Frame is connected via bluetooth at the time of the tap.

Python

#### Python

```
<span>async</span> <span>def</span> <span>run_on_tap</span><span>(</span><span>self</span><span>,</span> <span>lua_script</span><span>:</span> <span>Optional</span><span>[</span><span>str</span><span>]</span> <span>=</span> <span>None</span><span>,</span> <span>callback</span><span>:</span> <span>Optional</span><span>[</span><span>Callable</span><span>[[],</span> <span>None</span><span>]]</span> <span>=</span> <span>None</span><span>)</span> <span>-&gt;</span> <span>None</span><span>:</span>
```

Example:

```
<span>def</span> <span>on_tap</span><span>(</span><span>self</span><span>):</span>
    <span>print</span><span>(</span><span>"Frame was tapped!"</span><span>)</span>

<span># assign both a local callback and a lua script.  Or you could just do one or the other.
</span><span>await</span> <span>f</span><span>.</span><span>motion</span><span>.</span><span>run_on_tap</span><span>(</span><span>lua_script</span><span>=</span><span>"frame.display.text('I was tapped!',1,1);frame.display.show();"</span><span>,</span> <span>callback</span><span>=</span><span>on_tap</span><span>)</span>
```
Flutter

#### Flutter

```
<span>Future</span><span>&lt;</span><span>void</span><span>&gt;</span> <span>runOnTap</span><span>({</span><span>String</span><span>?</span> <span>luaScript</span><span>,</span> <span>void</span> <span>Function</span><span>()</span><span>?</span> <span>callback</span><span>})</span> <span>async</span>
```

Example:

```
<span>void</span> <span>onTap</span><span>()</span> <span>{</span>
  <span>print</span><span>(</span><span>"Frame was tapped!"</span><span>);</span>
<span>}</span>

<span>// assign both a local callback and a lua script. Or you could just do one or the other.</span>
<span>await</span> <span>f</span><span>.</span><span>motion</span><span>.</span><span>runOnTap</span><span>(</span><span>luaScript:</span> <span>"frame.display.text('I was tapped!',1,1);frame.display.show();"</span><span>,</span> <span>callback:</span> <span>onTap</span><span>);</span>
```

### Wait For Tap

```
<span>async</span> <span>frame</span><span>.</span><span>motion</span><span>.</span><span>wait_for_tap</span><span>()</span> <span>-&gt;</span> <span>None</span>
```

Blocks until the user taps the Frame.

Python

#### Python

```
<span>async</span> <span>def</span> <span>wait_for_tap</span><span>(</span><span>self</span><span>)</span> <span>-&gt;</span> <span>None</span>
```

Example:

```
<span>print</span><span>(</span><span>"Waiting for tap..."</span><span>)</span>
<span>await</span> <span>f</span><span>.</span><span>display</span><span>.</span><span>show_text</span><span>(</span><span>"Tap me to continue"</span><span>,</span> <span>align</span><span>=</span><span>Alignment</span><span>.</span><span>MIDDLE_CENTER</span><span>)</span>
<span>await</span> <span>f</span><span>.</span><span>motion</span><span>.</span><span>wait_for_tap</span><span>()</span>
<span>print</span><span>(</span><span>"Tap received!"</span><span>)</span>
<span>await</span> <span>f</span><span>.</span><span>display</span><span>.</span><span>show_text</span><span>(</span><span>"tap complete"</span><span>,</span> <span>align</span><span>=</span><span>Alignment</span><span>.</span><span>MIDDLE_CENTER</span><span>)</span>
```
Flutter

#### Flutter

```
<span>Future</span><span>&lt;</span><span>void</span><span>&gt;</span> <span>waitForTap</span><span>()</span> <span>async</span>
```

Example:

```
<span>print</span><span>(</span><span>"Waiting for tap..."</span><span>);</span>
<span>await</span> <span>f</span><span>.</span><span>display</span><span>.</span><span>showText</span><span>(</span><span>"Tap me to continue"</span><span>,</span> <span>align:</span> <span>Alignment</span><span>.</span><span>middleCenter</span><span>);</span>
<span>await</span> <span>f</span><span>.</span><span>motion</span><span>.</span><span>waitForTap</span><span>();</span>
<span>print</span><span>(</span><span>"Tap received!"</span><span>);</span>
<span>await</span> <span>f</span><span>.</span><span>display</span><span>.</span><span>showText</span><span>(</span><span>"Tap complete"</span><span>,</span> <span>align:</span> <span>Alignment</span><span>.</span><span>middleCenter</span><span>);</span>
```

## Putting It All Together

Here’s a more comprehensive example of how to use the Frame SDK to build an app.

## Python

```
<span>import</span> <span>asyncio</span>
<span>from</span> <span>frame_sdk</span> <span>import</span> <span>Frame</span>
<span>from</span> <span>frame_sdk.display</span> <span>import</span> <span>Alignment</span>
<span>import</span> <span>datetime</span>

<span>async</span> <span>def</span> <span>main</span><span>():</span>
    <span># the with statement handles the connection and disconnection to Frame
</span>    <span>async</span> <span>with</span> <span>Frame</span><span>()</span> <span>as</span> <span>f</span><span>:</span>
        <span># you can access the lower-level bluetooth connection via f.bluetooth, although you shouldn't need to do this often
</span>        <span>print</span><span>(</span><span>f</span><span>"Connected: </span><span>{</span><span>f</span><span>.</span><span>bluetooth</span><span>.</span><span>is_connected</span><span>()</span><span>}</span><span>"</span><span>)</span>

        <span># let's get the current battery level
</span>        <span>print</span><span>(</span><span>f</span><span>"Frame battery: </span><span>{</span><span>await</span> <span>f</span><span>.</span><span>get_battery_level</span><span>()</span><span>}</span><span>%"</span><span>)</span>

        <span># let's write (or overwrite) the file greeting.txt with "Hello world".
</span>        <span># You can provide a bytes object or convert a string with .encode()
</span>        <span>await</span> <span>f</span><span>.</span><span>files</span><span>.</span><span>write_file</span><span>(</span><span>"greeting.txt"</span><span>,</span> <span>b</span><span>"Hello world"</span><span>)</span>

        <span># And now we read that file back.
</span>        <span># Note that we should convert the bytearray to a string via the .decode() method.
</span>        <span>print</span><span>((</span><span>await</span> <span>f</span><span>.</span><span>files</span><span>.</span><span>read_file</span><span>(</span><span>"greeting.txt"</span><span>)).</span><span>decode</span><span>())</span>
        
        <span># run_lua will automatically handle scripts that are too long for the MTU, so you don't need to worry about it.
</span>        <span># It will also automatically handle responses that are too long for the MTU automatically.
</span>        <span>await</span> <span>f</span><span>.</span><span>run_lua</span><span>(</span><span>"frame.display.text('Hello world', 50, 100);frame.display.show()"</span><span>)</span>

        <span># evaluate is equivalent to f.run_lua("print(\"1+2\"), await_print=True)
</span>        <span># It will also automatically handle responses that are too long for the MTU automatically.
</span>        <span>print</span><span>(</span><span>await</span> <span>f</span><span>.</span><span>evaluate</span><span>(</span><span>"1+2"</span><span>))</span>

        <span>print</span><span>(</span><span>"Tap the Frame to continue..."</span><span>)</span>
        <span>await</span> <span>f</span><span>.</span><span>display</span><span>.</span><span>show_text</span><span>(</span><span>"Tap the Frame to take a photo"</span><span>,</span> <span>align</span><span>=</span><span>Alignment</span><span>.</span><span>MIDDLE_CENTER</span><span>)</span>
        <span>await</span> <span>f</span><span>.</span><span>motion</span><span>.</span><span>wait_for_tap</span><span>()</span>

        <span># take a photo and save to disk
</span>        <span>await</span> <span>f</span><span>.</span><span>display</span><span>.</span><span>show_text</span><span>(</span><span>"Taking photo..."</span><span>,</span> <span>align</span><span>=</span><span>Alignment</span><span>.</span><span>MIDDLE_CENTER</span><span>)</span>
        <span>await</span> <span>f</span><span>.</span><span>camera</span><span>.</span><span>save_photo</span><span>(</span><span>"frame-test-photo.jpg"</span><span>)</span>
        <span>await</span> <span>f</span><span>.</span><span>display</span><span>.</span><span>show_text</span><span>(</span><span>"Photo saved!"</span><span>,</span> <span>align</span><span>=</span><span>Alignment</span><span>.</span><span>MIDDLE_CENTER</span><span>)</span>
        <span># or with more control
</span>        <span>await</span> <span>f</span><span>.</span><span>camera</span><span>.</span><span>save_photo</span><span>(</span><span>"frame-test-photo-2.jpg"</span><span>,</span> <span>autofocus_seconds</span><span>=</span><span>3</span><span>,</span> <span>quality</span><span>=</span><span>f</span><span>.</span><span>camera</span><span>.</span><span>HIGH_QUALITY</span><span>,</span> <span>autofocus_type</span><span>=</span><span>f</span><span>.</span><span>camera</span><span>.</span><span>AUTOFOCUS_TYPE_CENTER_WEIGHTED</span><span>)</span>
        <span># or get the raw bytes
</span>        <span>photo_bytes</span> <span>=</span> <span>await</span> <span>f</span><span>.</span><span>camera</span><span>.</span><span>take_photo</span><span>(</span><span>autofocus_seconds</span><span>=</span><span>1</span><span>)</span>

        <span>print</span><span>(</span><span>"About to record until you stop talking"</span><span>)</span>
        <span>await</span> <span>f</span><span>.</span><span>display</span><span>.</span><span>show_text</span><span>(</span><span>"Say something..."</span><span>,</span> <span>align</span><span>=</span><span>Alignment</span><span>.</span><span>MIDDLE_CENTER</span><span>)</span>
<span># record audio to a file
</span>        <span>length</span> <span>=</span> <span>await</span> <span>f</span><span>.</span><span>microphone</span><span>.</span><span>save_audio_file</span><span>(</span><span>"test-audio.wav"</span><span>)</span>
        <span>print</span><span>(</span><span>f</span><span>"Recorded </span><span>{</span><span>length</span><span>:</span><span>01.1</span><span>f</span><span>}</span><span> seconds: </span><span>\"</span><span>./test-audio.wav</span><span>\"</span><span>"</span><span>)</span>
        <span>await</span> <span>f</span><span>.</span><span>display</span><span>.</span><span>show_text</span><span>(</span><span>f</span><span>"Recorded </span><span>{</span><span>length</span><span>:</span><span>01.1</span><span>f</span><span>}</span><span> seconds"</span><span>,</span> <span>align</span><span>=</span><span>Alignment</span><span>.</span><span>MIDDLE_CENTER</span><span>)</span>
        <span>await</span> <span>asyncio</span><span>.</span><span>sleep</span><span>(</span><span>3</span><span>)</span>

        <span># or get the audio directly in memory
</span>        <span>await</span> <span>f</span><span>.</span><span>display</span><span>.</span><span>show_text</span><span>(</span><span>"Say something else..."</span><span>,</span> <span>align</span><span>=</span><span>Alignment</span><span>.</span><span>MIDDLE_CENTER</span><span>)</span>
        <span>audio_data</span> <span>=</span> <span>await</span> <span>f</span><span>.</span><span>microphone</span><span>.</span><span>record_audio</span><span>(</span><span>max_length_in_seconds</span><span>=</span><span>10</span><span>)</span>
        <span>await</span> <span>f</span><span>.</span><span>display</span><span>.</span><span>show_text</span><span>(</span><span>f</span><span>"Playing back </span><span>{</span><span>len</span><span>(</span><span>audio_data</span><span>)</span> <span>/</span> <span>f</span><span>.</span><span>microphone</span><span>.</span><span>sample_rate</span><span>:</span><span>01.1</span><span>f</span><span>}</span><span> seconds of audio"</span><span>,</span> <span>align</span><span>=</span><span>Alignment</span><span>.</span><span>MIDDLE_CENTER</span><span>)</span>
        <span># you can play back the audio on your computer
</span>        <span>f</span><span>.</span><span>microphone</span><span>.</span><span>play_audio</span><span>(</span><span>audio_data</span><span>)</span>
        <span># or process it using other audio handling libraries, upload to a speech-to-text service, etc.
</span>
        <span>print</span><span>(</span><span>"Move around to track intensity of your motion"</span><span>)</span>
        <span>await</span> <span>f</span><span>.</span><span>display</span><span>.</span><span>show_text</span><span>(</span><span>"Move around to track intensity of your motion"</span><span>,</span> <span>align</span><span>=</span><span>Alignment</span><span>.</span><span>MIDDLE_CENTER</span><span>)</span>
        <span>intensity_of_motion</span> <span>=</span> <span>0</span>
        <span>prev_direction</span> <span>=</span> <span>await</span> <span>f</span><span>.</span><span>motion</span><span>.</span><span>get_direction</span><span>()</span>
        <span>for</span> <span>_</span> <span>in</span> <span>range</span><span>(</span><span>10</span><span>):</span>
            <span>await</span> <span>asyncio</span><span>.</span><span>sleep</span><span>(</span><span>0.1</span><span>)</span>
            <span>direction</span> <span>=</span> <span>await</span> <span>f</span><span>.</span><span>motion</span><span>.</span><span>get_direction</span><span>()</span>
            <span>intensity_of_motion</span> <span>=</span> <span>max</span><span>(</span><span>intensity_of_motion</span><span>,</span> <span>(</span><span>direction</span><span>-</span><span>prev_direction</span><span>).</span><span>amplitude</span><span>())</span>
            <span>prev_direction</span> <span>=</span> <span>direction</span>
        <span>print</span><span>(</span><span>f</span><span>"Intensity of motion: </span><span>{</span><span>intensity_of_motion</span><span>:</span><span>01.2</span><span>f</span><span>}</span><span>"</span><span>)</span>
        <span>await</span> <span>f</span><span>.</span><span>display</span><span>.</span><span>show_text</span><span>(</span><span>f</span><span>"Intensity of motion: </span><span>{</span><span>intensity_of_motion</span><span>:</span><span>01.2</span><span>f</span><span>}</span><span>"</span><span>,</span> <span>align</span><span>=</span><span>Alignment</span><span>.</span><span>MIDDLE_CENTER</span><span>)</span>
        <span>print</span><span>(</span><span>"Tap the Frame to continue..."</span><span>)</span>
        <span>await</span> <span>f</span><span>.</span><span>motion</span><span>.</span><span>wait_for_tap</span><span>()</span>

        <span># Show the full palette
</span>        <span>width</span> <span>=</span> <span>640</span> <span>//</span> <span>4</span>
        <span>height</span> <span>=</span> <span>400</span> <span>//</span> <span>4</span>
        <span>for</span> <span>color</span> <span>in</span> <span>range</span><span>(</span><span>0</span><span>,</span> <span>16</span><span>):</span>
            <span>tile_x</span> <span>=</span> <span>(</span><span>color</span> <span>%</span> <span>4</span><span>)</span>
            <span>tile_y</span> <span>=</span> <span>(</span><span>color</span> <span>//</span> <span>4</span><span>)</span>
            <span>await</span> <span>f</span><span>.</span><span>display</span><span>.</span><span>draw_rect</span><span>(</span><span>tile_x</span><span>*</span><span>width</span><span>+</span><span>1</span><span>,</span> <span>tile_y</span><span>*</span><span>height</span><span>+</span><span>1</span><span>,</span> <span>width</span><span>,</span> <span>height</span><span>,</span> <span>color</span><span>)</span>
            <span>await</span> <span>f</span><span>.</span><span>display</span><span>.</span><span>write_text</span><span>(</span><span>f</span><span>"</span><span>{</span><span>color</span><span>}</span><span>"</span><span>,</span> <span>tile_x</span><span>*</span><span>width</span><span>+</span><span>width</span><span>//</span><span>2</span><span>+</span><span>1</span><span>,</span> <span>tile_y</span><span>*</span><span>height</span><span>+</span><span>height</span><span>//</span><span>2</span><span>+</span><span>1</span><span>)</span>
        <span>await</span> <span>f</span><span>.</span><span>display</span><span>.</span><span>show</span><span>()</span>

        <span>print</span><span>(</span><span>"Tap the Frame to continue..."</span><span>)</span>
        <span>await</span> <span>f</span><span>.</span><span>motion</span><span>.</span><span>wait_for_tap</span><span>()</span>

        <span># scroll some long text
</span>        <span>await</span> <span>f</span><span>.</span><span>display</span><span>.</span><span>scroll_text</span><span>(</span><span>"Never gonna give you up</span><span>\n</span><span>Never gonna let you down</span><span>\n</span><span>Never gonna run around and desert you</span><span>\n</span><span>Never gonna make you cry</span><span>\n</span><span>Never gonna say goodbye</span><span>\n</span><span>Never gonna tell a lie and hurt you"</span><span>)</span>

        <span># display battery indicator and time as a home screen
</span>        <span>batteryPercent</span> <span>=</span> <span>await</span> <span>f</span><span>.</span><span>get_battery_level</span><span>()</span>
        <span># select a battery fill color from the default palette based on level
</span>        <span>color</span> <span>=</span> <span>2</span> <span>if</span> <span>batteryPercent</span> <span>&lt;</span> <span>20</span> <span>else</span> <span>6</span> <span>if</span> <span>batteryPercent</span> <span>&lt;</span> <span>50</span> <span>else</span> <span>9</span>
        <span># specify the size of the battery indicator in the top-right
</span>        <span>batteryWidth</span> <span>=</span> <span>150</span>
        <span>batteryHeight</span> <span>=</span> <span>75</span>
        <span># draw the endcap of the battery
</span>        <span>await</span> <span>f</span><span>.</span><span>display</span><span>.</span><span>draw_rect</span><span>(</span><span>640</span><span>-</span><span>32</span><span>,</span><span>40</span> <span>+</span> <span>batteryHeight</span><span>//</span><span>2</span><span>-</span><span>8</span><span>,</span> <span>32</span><span>,</span> <span>16</span><span>,</span> <span>1</span><span>)</span>
        <span># draw the battery outline
</span>        <span>await</span> <span>f</span><span>.</span><span>display</span><span>.</span><span>draw_rect_filled</span><span>(</span><span>640</span><span>-</span><span>16</span><span>-</span><span>batteryWidth</span><span>,</span> <span>40</span><span>-</span><span>8</span><span>,</span> <span>batteryWidth</span><span>+</span><span>16</span><span>,</span> <span>batteryHeight</span><span>+</span><span>16</span><span>,</span> <span>8</span><span>,</span> <span>1</span><span>,</span> <span>15</span><span>)</span>
        <span># fill the battery based on level
</span>        <span>await</span> <span>f</span><span>.</span><span>display</span><span>.</span><span>draw_rect</span><span>(</span><span>640</span><span>-</span><span>8</span><span>-</span><span>batteryWidth</span><span>,</span> <span>40</span><span>,</span> <span>int</span><span>(</span><span>batteryWidth</span> <span>*</span> <span>0.01</span> <span>*</span> <span>batteryPercent</span><span>),</span> <span>batteryHeight</span><span>,</span> <span>color</span><span>)</span>
        <span># write the battery level
</span>        <span>await</span> <span>f</span><span>.</span><span>display</span><span>.</span><span>write_text</span><span>(</span><span>f</span><span>"</span><span>{</span><span>batteryPercent</span><span>}</span><span>%"</span><span>,</span> <span>640</span><span>-</span><span>8</span><span>-</span><span>batteryWidth</span><span>,</span> <span>40</span><span>,</span> <span>batteryWidth</span><span>,</span> <span>batteryHeight</span><span>,</span> <span>Alignment</span><span>.</span><span>MIDDLE_CENTER</span><span>)</span>
        <span># write the time and date in the center of the screen
</span>        <span>await</span> <span>f</span><span>.</span><span>display</span><span>.</span><span>write_text</span><span>(</span><span>datetime</span><span>.</span><span>datetime</span><span>.</span><span>now</span><span>().</span><span>strftime</span><span>(</span><span>"%-I:%M %p</span><span>\n</span><span>%a, %B %d, %Y"</span><span>),</span> <span>align</span><span>=</span><span>Alignment</span><span>.</span><span>MIDDLE_CENTER</span><span>)</span>
        <span># now show what we've been drawing to the buffer
</span>        <span>await</span> <span>f</span><span>.</span><span>display</span><span>.</span><span>show</span><span>()</span>

        <span># set a wake screen via script, so when you tap to wake the frame, it shows the battery and time
</span>        <span>await</span> <span>f</span><span>.</span><span>run_on_wake</span><span>(</span><span>"""frame.display.text('Battery: ' .. frame.battery_level() ..  '%', 10, 10);
                            if frame.time.utc() &gt; 10000 then
                                local time_now = frame.time.date();
                                frame.display.text(time_now['hour'] .. ':' .. time_now['minute'], 300, 160);
                                frame.display.text(time_now['month'] .. '/' .. time_now['day'] .. '/' .. time_now['year'], 300, 220) 
                            end;
                            frame.display.show();
                            frame.sleep(10);
                            frame.display.text(' ',1,1);
                            frame.display.show();
                            frame.sleep()"""</span><span>)</span>

        <span># tell frame to sleep after 10 seconds then clear the screen and go to sleep, without blocking for that
</span>        <span>await</span> <span>f</span><span>.</span><span>run_lua</span><span>(</span><span>"frame.sleep(10);frame.display.text(' ',1,1);frame.display.show();frame.sleep()"</span><span>)</span>

    <span>print</span><span>(</span><span>"disconnected"</span><span>)</span>

<span>asyncio</span><span>.</span><span>run</span><span>(</span><span>main</span><span>())</span>

```

## Flutter

```
<span>import</span> <span>'dart:convert'</span><span>;</span>
<span>import</span> <span>'dart:typed_data'</span><span>;</span>
<span>import</span> <span>'package:frame_sdk/frame_sdk.dart'</span><span>;</span>
<span>import</span> <span>'package:frame_sdk/display.dart'</span><span>;</span>
<span>import</span> <span>'package:frame_sdk/motion.dart'</span><span>;</span>
<span>import</span> <span>'package:frame_sdk/camera.dart'</span><span>;</span>
<span>import</span> <span>'package:frame_sdk/microphone.dart'</span><span>;</span>
<span>import</span> <span>'package:frame_sdk/bluetooth.dart'</span><span>;</span>
<span>import</span> <span>'package:logging/logging.dart'</span><span>;</span>
<span>import</span> <span>'package:flutter/material.dart'</span><span>;</span>
<span>import</span> <span>'dart:async'</span><span>;</span>
<span>import</span> <span>'dart:math'</span><span>;</span>
<span>import</span> <span>'package:path_provider/path_provider.dart'</span><span>;</span>

<span>Future</span><span>&lt;</span><span>void</span><span>&gt;</span> <span>runExample</span><span>()</span> <span>async</span> <span>{</span>
  <span>// Request bluetooth permission</span>
  <span>await</span> <span>BrilliantBluetooth</span><span>.</span><span>requestPermission</span><span>();</span>


  <span>final</span> <span>frame</span> <span>=</span> <span>Frame</span><span>();</span>

  <span>// Connect to the frame</span>
  <span>while</span> <span>(</span><span>!</span><span>frame</span><span>.</span><span>isConnected</span><span>)</span> <span>{</span>
    <span>print</span><span>(</span><span>"Trying to connect..."</span><span>);</span>
    <span>final</span> <span>didConnect</span> <span>=</span> <span>await</span> <span>frame</span><span>.</span><span>connect</span><span>();</span>
    <span>if</span> <span>(</span><span>didConnect</span><span>)</span> <span>{</span>
      <span>print</span><span>(</span><span>"Connected to device"</span><span>);</span>
    <span>}</span> <span>else</span> <span>{</span>
      <span>print</span><span>(</span><span>"Failed to connect to device, will try again..."</span><span>);</span>
    <span>}</span>
  <span>}</span>

  <span>// Get battery level</span>
  <span>int</span> <span>batteryLevel</span> <span>=</span> <span>await</span> <span>frame</span><span>.</span><span>getBatteryLevel</span><span>();</span>
  <span>print</span><span>(</span><span>"Frame battery: </span><span>$batteryLevel</span><span>%"</span><span>);</span>

  <span>// Write file</span>
  <span>await</span> <span>frame</span><span>.</span><span>files</span><span>.</span><span>writeFile</span><span>(</span><span>"greeting.txt"</span><span>,</span> <span>utf8</span><span>.</span><span>encode</span><span>(</span><span>"Hello world"</span><span>));</span>

  <span>// Read file</span>
  <span>String</span> <span>fileContent</span> <span>=</span> <span>utf8</span><span>.</span><span>decode</span><span>(</span><span>await</span> <span>frame</span><span>.</span><span>files</span><span>.</span><span>readFile</span><span>(</span><span>"greeting.txt"</span><span>));</span>
  <span>print</span><span>(</span><span>fileContent</span><span>);</span>

  <span>// Display text</span>
  <span>await</span> <span>frame</span><span>.</span><span>runLua</span><span>(</span><span>"frame.display.text('Hello world', 50, 100);frame.display.show()"</span><span>);</span>

  <span>// Evaluate expression</span>
  <span>print</span><span>(</span><span>await</span> <span>frame</span><span>.</span><span>evaluate</span><span>(</span><span>"1+2"</span><span>));</span>

  <span>print</span><span>(</span><span>"Tap the Frame to continue..."</span><span>);</span>
  <span>await</span> <span>frame</span><span>.</span><span>display</span><span>.</span><span>showText</span><span>(</span><span>"Tap the Frame to take a photo"</span><span>,</span> <span>align:</span> <span>Alignment2D</span><span>.</span><span>middleCenter</span><span>);</span>
  <span>await</span> <span>frame</span><span>.</span><span>motion</span><span>.</span><span>waitForTap</span><span>();</span>

  <span>// Take and save photo</span>
  <span>await</span> <span>frame</span><span>.</span><span>display</span><span>.</span><span>showText</span><span>(</span><span>"Taking photo..."</span><span>,</span> <span>align:</span> <span>Alignment2D</span><span>.</span><span>middleCenter</span><span>);</span>
  <span>await</span> <span>frame</span><span>.</span><span>camera</span><span>.</span><span>savePhoto</span><span>(</span><span>"frame-test-photo.jpg"</span><span>);</span>
  <span>await</span> <span>frame</span><span>.</span><span>display</span><span>.</span><span>showText</span><span>(</span><span>"Photo saved!"</span><span>,</span> <span>align:</span> <span>Alignment2D</span><span>.</span><span>middleCenter</span><span>);</span>

  <span>// Take photo with more control</span>
  <span>await</span> <span>frame</span><span>.</span><span>camera</span><span>.</span><span>savePhoto</span><span>(</span><span>"frame-test-photo-2.jpg"</span><span>,</span>
      <span>autofocusSeconds:</span> <span>3</span><span>,</span>
      <span>quality:</span> <span>PhotoQuality</span><span>.</span><span>high</span><span>,</span>
      <span>autofocusType:</span> <span>AutoFocusType</span><span>.</span><span>centerWeighted</span><span>);</span>

  <span>// Get raw photo bytes</span>
  <span>Uint8List</span> <span>photoBytes</span> <span>=</span> <span>await</span> <span>frame</span><span>.</span><span>camera</span><span>.</span><span>takePhoto</span><span>(</span><span>autofocusSeconds:</span> <span>1</span><span>);</span>
  <span>print</span><span>(</span><span>"Photo bytes: </span><span>${photoBytes.length}</span><span>"</span><span>);</span>

  <span>print</span><span>(</span><span>"About to record until you stop talking"</span><span>);</span>
  <span>await</span> <span>frame</span><span>.</span><span>display</span><span>.</span><span>showText</span><span>(</span><span>"Say something..."</span><span>,</span> <span>align:</span> <span>Alignment2D</span><span>.</span><span>middleCenter</span><span>);</span>

  <span>// Record audio to file</span>
  <span>double</span> <span>length</span> <span>=</span> <span>await</span> <span>frame</span><span>.</span><span>microphone</span><span>.</span><span>saveAudioFile</span><span>(</span><span>"test-audio.wav"</span><span>);</span>
  <span>print</span><span>(</span><span>"Recorded </span><span>${length.toStringAsFixed(1)}</span><span> seconds: </span><span>\"</span><span>./test-audio.wav</span><span>\"</span><span>"</span><span>);</span>
  <span>await</span> <span>frame</span><span>.</span><span>display</span><span>.</span><span>showText</span><span>(</span><span>"Recorded </span><span>${length.toStringAsFixed(1)}</span><span> seconds"</span><span>,</span> <span>align:</span> <span>Alignment2D</span><span>.</span><span>middleCenter</span><span>);</span>
  <span>await</span> <span>Future</span><span>.</span><span>delayed</span><span>(</span><span>const</span> <span>Duration</span><span>(</span><span>seconds:</span> <span>3</span><span>));</span>

  <span>// Record audio to memory</span>
  <span>await</span> <span>frame</span><span>.</span><span>display</span><span>.</span><span>showText</span><span>(</span><span>"Say something else..."</span><span>,</span> <span>align:</span> <span>Alignment2D</span><span>.</span><span>middleCenter</span><span>);</span>
  <span>Uint8List</span> <span>audioData</span> <span>=</span> <span>await</span> <span>frame</span><span>.</span><span>microphone</span><span>.</span><span>recordAudio</span><span>(</span><span>maxLength:</span> <span>const</span> <span>Duration</span><span>(</span><span>seconds:</span> <span>10</span><span>));</span>
  <span>await</span> <span>frame</span><span>.</span><span>display</span><span>.</span><span>showText</span><span>(</span>
      <span>"Recorded </span><span>${(audioData.length / frame.microphone.sampleRate.toDouble()).toStringAsFixed(1)}</span><span> seconds of audio"</span><span>,</span>
      <span>align:</span> <span>Alignment2D</span><span>.</span><span>middleCenter</span><span>);</span>

  <span>print</span><span>(</span><span>"Move around to track intensity of your motion"</span><span>);</span>
  <span>await</span> <span>frame</span><span>.</span><span>display</span><span>.</span><span>showText</span><span>(</span><span>"Move around to track intensity of your motion"</span><span>,</span> <span>align:</span> <span>Alignment2D</span><span>.</span><span>middleCenter</span><span>);</span>
  <span>double</span> <span>intensityOfMotion</span> <span>=</span> <span>0</span><span>;</span>
  <span>Direction</span> <span>prevDirection</span> <span>=</span> <span>await</span> <span>frame</span><span>.</span><span>motion</span><span>.</span><span>getDirection</span><span>();</span>
  <span>for</span> <span>(</span><span>int</span> <span>i</span> <span>=</span> <span>0</span><span>;</span> <span>i</span> <span>&lt;</span> <span>10</span><span>;</span> <span>i</span><span>++</span><span>)</span> <span>{</span>
    <span>await</span> <span>Future</span><span>.</span><span>delayed</span><span>(</span><span>const</span> <span>Duration</span><span>(</span><span>milliseconds:</span> <span>100</span><span>));</span>
    <span>Direction</span> <span>direction</span> <span>=</span> <span>await</span> <span>frame</span><span>.</span><span>motion</span><span>.</span><span>getDirection</span><span>();</span>
    <span>intensityOfMotion</span> <span>=</span> <span>max</span><span>(</span><span>intensityOfMotion</span><span>,</span> <span>(</span><span>direction</span> <span>-</span> <span>prevDirection</span><span>)</span><span>.</span><span>amplitude</span><span>());</span>
    <span>prevDirection</span> <span>=</span> <span>direction</span><span>;</span>
  <span>}</span>
  <span>print</span><span>(</span><span>"Intensity of motion: </span><span>${intensityOfMotion.toStringAsFixed(2)}</span><span>"</span><span>);</span>
  <span>await</span> <span>frame</span><span>.</span><span>display</span><span>.</span><span>showText</span><span>(</span><span>"Intensity of motion: </span><span>${intensityOfMotion.toStringAsFixed(2)}</span><span>"</span><span>,</span> <span>align:</span> <span>Alignment2D</span><span>.</span><span>middleCenter</span><span>);</span>
  <span>print</span><span>(</span><span>"Tap the Frame to continue..."</span><span>);</span>
  <span>await</span> <span>frame</span><span>.</span><span>motion</span><span>.</span><span>waitForTap</span><span>();</span>

  <span>// Show the full palette</span>
  <span>int</span> <span>width</span> <span>=</span> <span>640</span> <span>~/</span> <span>4</span><span>;</span>
  <span>int</span> <span>height</span> <span>=</span> <span>400</span> <span>~/</span> <span>4</span><span>;</span>
  <span>for</span> <span>(</span><span>int</span> <span>color</span> <span>=</span> <span>0</span><span>;</span> <span>color</span> <span>&lt;</span> <span>16</span><span>;</span> <span>color</span><span>++</span><span>)</span> <span>{</span>
    <span>int</span> <span>tileX</span> <span>=</span> <span>(</span><span>color</span> <span>%</span> <span>4</span><span>);</span>
    <span>int</span> <span>tileY</span> <span>=</span> <span>(</span><span>color</span> <span>~/</span> <span>4</span><span>);</span>
    <span>await</span> <span>frame</span><span>.</span><span>display</span><span>.</span><span>drawRect</span><span>(</span><span>tileX</span> <span>*</span> <span>width</span> <span>+</span> <span>1</span><span>,</span> <span>tileY</span> <span>*</span> <span>height</span> <span>+</span> <span>1</span><span>,</span> <span>width</span><span>,</span> <span>height</span><span>,</span> <span>PaletteColors</span><span>.</span><span>fromIndex</span><span>(</span><span>color</span><span>));</span>
    <span>await</span> <span>frame</span><span>.</span><span>display</span><span>.</span><span>writeText</span><span>(</span><span>"</span><span>$color</span><span>"</span><span>,</span>
        <span>x:</span> <span>tileX</span> <span>*</span> <span>width</span> <span>+</span> <span>width</span> <span>~/</span> <span>2</span> <span>+</span> <span>1</span><span>,</span>
        <span>y:</span> <span>tileY</span> <span>*</span> <span>height</span> <span>+</span> <span>height</span> <span>~/</span> <span>2</span> <span>+</span> <span>1</span><span>);</span>
  <span>}</span>
  <span>await</span> <span>frame</span><span>.</span><span>display</span><span>.</span><span>show</span><span>();</span>

  <span>print</span><span>(</span><span>"Tap the Frame to continue..."</span><span>);</span>
  <span>await</span> <span>frame</span><span>.</span><span>motion</span><span>.</span><span>waitForTap</span><span>();</span>

  <span>// Scroll some long text</span>
  <span>await</span> <span>frame</span><span>.</span><span>display</span><span>.</span><span>scrollText</span><span>(</span>
      <span>"Never gonna give you up</span><span>\n</span><span>Never gonna let you down</span><span>\n</span><span>Never gonna run around and desert you</span><span>\n</span><span>Never gonna make you cry</span><span>\n</span><span>Never gonna say goodbye</span><span>\n</span><span>Never gonna tell a lie and hurt you"</span><span>);</span>

  <span>// Display battery indicator and time as a home screen</span>
  <span>batteryLevel</span> <span>=</span> <span>await</span> <span>frame</span><span>.</span><span>getBatteryLevel</span><span>();</span>
  <span>PaletteColors</span> <span>batteryFillColor</span> <span>=</span> <span>batteryLevel</span> <span>&lt;</span> <span>20</span>
      <span>?</span> <span>PaletteColors</span><span>.</span><span>red</span>
      <span>:</span> <span>batteryLevel</span> <span>&lt;</span> <span>50</span>
          <span>?</span> <span>PaletteColors</span><span>.</span><span>yellow</span>
          <span>:</span> <span>PaletteColors</span><span>.</span><span>green</span><span>;</span>
  <span>int</span> <span>batteryWidth</span> <span>=</span> <span>150</span><span>;</span>
  <span>int</span> <span>batteryHeight</span> <span>=</span> <span>75</span><span>;</span>
  <span>await</span> <span>frame</span><span>.</span><span>display</span><span>.</span><span>drawRect</span><span>(</span>
      <span>640</span> <span>-</span> <span>32</span><span>,</span> <span>40</span> <span>+</span> <span>batteryHeight</span> <span>~/</span> <span>2</span> <span>-</span> <span>8</span><span>,</span> <span>32</span><span>,</span> <span>16</span><span>,</span> <span>PaletteColors</span><span>.</span><span>white</span><span>);</span>
  <span>await</span> <span>frame</span><span>.</span><span>display</span><span>.</span><span>drawRectFilled</span><span>(</span>
      <span>640</span> <span>-</span> <span>16</span> <span>-</span> <span>batteryWidth</span><span>,</span>
      <span>40</span> <span>-</span> <span>8</span><span>,</span>
      <span>batteryWidth</span> <span>+</span> <span>16</span><span>,</span>
      <span>batteryHeight</span> <span>+</span> <span>16</span><span>,</span>
      <span>8</span><span>,</span>
      <span>PaletteColors</span><span>.</span><span>white</span><span>,</span>
      <span>PaletteColors</span><span>.</span><span>voidBlack</span><span>);</span>
  <span>await</span> <span>frame</span><span>.</span><span>display</span><span>.</span><span>drawRect</span><span>(</span>
      <span>640</span> <span>-</span> <span>8</span> <span>-</span> <span>batteryWidth</span><span>,</span>
      <span>40</span><span>,</span>
      <span>(</span><span>batteryWidth</span> <span>*</span> <span>0.01</span> <span>*</span> <span>batteryLevel</span><span>)</span><span>.</span><span>toInt</span><span>(),</span>
      <span>batteryHeight</span><span>,</span>
      <span>batteryFillColor</span><span>);</span>
  <span>await</span> <span>frame</span><span>.</span><span>display</span><span>.</span><span>writeText</span><span>(</span><span>"</span><span>$batteryLevel</span><span>%"</span><span>,</span>
      <span>x:</span> <span>640</span> <span>-</span> <span>8</span> <span>-</span> <span>batteryWidth</span><span>,</span>
      <span>y:</span> <span>40</span><span>,</span>
      <span>maxWidth:</span> <span>batteryWidth</span><span>,</span>
      <span>maxHeight:</span> <span>batteryHeight</span><span>,</span>
      <span>align:</span> <span>Alignment2D</span><span>.</span><span>middleCenter</span><span>);</span>
  <span>await</span> <span>frame</span><span>.</span><span>display</span><span>.</span><span>writeText</span><span>(</span><span>DateTime</span><span>.</span><span>now</span><span>()</span><span>.</span><span>toString</span><span>(),</span> <span>align:</span> <span>Alignment2D</span><span>.</span><span>middleCenter</span><span>);</span>
  <span>await</span> <span>frame</span><span>.</span><span>display</span><span>.</span><span>show</span><span>();</span>

  <span>// Set a wake screen via script</span>
  <span>await</span> <span>frame</span><span>.</span><span>runOnWake</span><span>(</span><span>luaScript:</span> <span>"""
    frame.display.text('Battery: ' .. frame.battery_level() ..  '%', 10, 10);
    if frame.time.utc() &gt; 10000 then
      local time_now = frame.time.date();
      frame.display.text(time_now['hour'] .. ':' .. time_now['minute'], 300, 160);
      frame.display.text(time_now['month'] .. '/' .. time_now['day'] .. '/' .. time_now['year'], 300, 220) 
    end;
    frame.display.show();
    frame.sleep(10);
    frame.display.text(' ',1,1);
    frame.display.show();
    frame.sleep()
  """</span><span>);</span>

  <span>// Tell frame to sleep after 10 seconds then clear the screen and go to sleep</span>
  <span>await</span> <span>frame</span><span>.</span><span>runLua</span><span>(</span><span>"frame.sleep(10);frame.display.text(' ',1,1);frame.display.show();frame.sleep()"</span><span>);</span>
<span>}</span>

```