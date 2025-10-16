# Cracktro Demo (AutoHotkey + BASSMOD + GDI+)

This project is a small **cracktro-style demo** built using **AutoHotkey**, with music powered by **bassmod.dll** and visuals created through **GDI+**.

Cracktros (short for *crack intros*) were short demos that appeared before cracked software, especially popular during the 1980s and 1990s. They often featured scrolling text, chipmusic, raster effects, and colorful logos, serving as a "calling card" for cracking groups.

## Preview Demo


https://github.com/user-attachments/assets/118f64a6-8eb2-43df-b3ec-52c101cae021


## About the Demoscene

The **demoscene** is a computer art subculture that specializes in creating **real-time audiovisual demonstrations**. These demos showcase programming skill, artistic design, and musical composition, often pushing hardware beyond its intended limits.

Some of the most iconic roots of the demoscene lie in **Commodore 64** and **Amiga** computers, but there are demos on pretty much any system:

- 🎨 **Commodore 64 (C64):** Famous for its SID chip sound and colorful raster effects. Many legendary demos were written for this platform.
- 🖥 **Amiga:** Known for its advanced graphics and audio for the time, it became a hub for creative productions with smooth animations, sampled music, and effects that influenced PC demos later on.

The tradition carried over to DOS and modern PCs, evolving into large demoparties and competitions that continue today.

## Technical Details

- **Language:** AutoHotkey v1
- **Graphics:** GDI+ (via the AHK GDIp library)
- **Music:** bassmod.dll (XM music playback)

This project demonstrates how even a scripting language like AutoHotkey can be used to recreate the retro charm of the demoscene.

---

> [!IMPORTANT]
> Requires *32bit Unicode* AHK due to Bassmod.dll

## Cracktro Demo - Methods & Effects

This section describes the main techniques used in the **AutoHotkey Cracktro Demo**, inspired by classic demoscene productions.

---

### 🎵 Sine Wave (SIN) Text Animation

The script uses **sine wave functions (`Sin`)** to animate text and elements smoothly across the screen.  
This technique was widely used in the demoscene to create wavy scrolling text, bouncing titles, and oscillating effects.

- Example:  
  
  ```autohotkey
  size  := titleSizeBase + titlePulse * Sin(t*1.1)
  rot   := titleRotAmp  * Sin(t*0.85)
  yOff  := -titleYAmp   * Sin(t*1.7)
  ```

This gives the text a pulsing, rotating, and waving motion over time.

---

### 📜 Scrolling Text (Scroller)

A **horizontal text scroller** displays greetings and messages, moving from right to left across the screen.  
This effect mimics the iconic greetings scrollers in C64 and Amiga intros.

- Customizable font, size, and speed
- Combined with sine modulation for extra smoothness

---

### 🌈 Raster Bars

Raster bars are colored horizontal bars that move, wave, or pulse across the screen.  
They were a staple effect on the **Commodore 64** and **Amiga**, showing off synchronization with the display.

In this demo, raster bars are drawn dynamically with GDI+.

---

### ✨ Starfield Effect

A starfield simulates moving stars, giving the illusion of traveling through space.  
This effect adds depth and movement, often used in cracktros to fill the background dynamically.

---

### 🖼 Vignette & Layered Graphics

The script also applies a **vignette effect** to darken the screen edges and focus attention on the center.  
With **GDI+ layered windows**, effects like transparency, rotation, and scaling are achieved.

---

### 🎨 Pixelated vs Smooth Rendering

The script lets you toggle between **pixelated rendering** (retro, blocky look) and **smoothed rendering** (anti-aliased modern look):

```autohotkey
global pixelatedTexts := 1 ; Toggle for smoothing / pixel effect
Gdip_SetSmoothingMode(G, pixelatedTexts ? 1 : 4)
```

---

### Summary of Methods

- **SIN wave functions** → smooth oscillations for text and objects  
- **Scrolling text** → classic demoscene greets and messages  
- **Raster bars** → colorful moving stripes from C64/Amiga tradition  
- **Starfield** → depth and motion illusion  
- **Vignette & layering** → visual polish and retro atmosphere  

## Credits

- **bassmod.dll** by *k3ph*
- **Taric Porter**, **Marius Șucan** and the **AHK community** for the GDIp library and supporting functions
- Inspiration from the **demoscene** and classic **cracktros**
- **AGAiN - EIQ FirewallAnalyzer 3.2.10 kg.xm** is the *"chiptune"* theme I used
- Not really a credit but [you may find this thread interesting!](https://www.autohotkey.com/boards/viewtopic.php?t=42047)

## License

This demo is provided for educational and nostalgic purposes. Feel free to experiment, modify, and learn from it.

If you make another AutoHotkey demo and want to share it here or improve mine, feel free to make a PR!



> [!TIP]
> Fun fact, the whole source including AutoHotkey libraries (without DLL & XM) fit under 64Kb. Everything included except the AHK interpreter is 101Kb.
