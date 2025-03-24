# ArtNet DMX Sender for 2*8x8 addreassable LED matrices - for 🤖 👀

A Processing application for real-time pixelation of media content (images, videos, and Syphon streams) with ArtNet DMX output capabilities. 
> Designed to control 8x8 LED Matrix displays, primarily for humanoid eye animations, but also suitable for other 8x8 pixel mapping projects and visual effects creation.

![alt text](<_assets/Screenshot 2025-03-24 at 11.16.21.png>)

![alt text](<_assets/2 videos - synced.jpg>)
> The usb cable is only there for providing power to the microcontrollers. The DMX512 ArtNet data is sent over the network.

---

## How does it work?

### Understanding the requirement

![alt text](<_assets/Pixel Processing algorithms.png>)

### How is image data mapped from software to the physical matrix?

![alt text](<_assets/Pixel Processing algorithms-2.png>)

### How do we downsample an image texture?

![alt text](<_assets/Pixel Processing algorithms-3.png>)

### About the hardware

![HW](<_assets/Hardware ....png>)

[More in details here](Arduino/README.md)

---

## Features

![alt text](<_assets/Our software.png>)

![alt text](<_assets/2 videos - synced.jpg>)
> Two videos, loaded and are syncornized.

<br>

![alt text](<_assets/1 syphon 1 video.jpg>)
> Two different asynchronous sources.
>
> Left: Video Loop.
>
> Right: Graphical Textures from another application being sent over via Syphon and analysed and outoputted to ArtNet through by our software.

<br>

![alt text](<_assets/2 syphon.jpg>)
> Two different asynchronous sources.
>
> Left: Graphical Textures from another application being sent over via Syphon and analysed and outoputted to ArtNet through by our software.
>
> Right: Graphical Textures from another application being sent over via Syphon and analysed and outoputted to ArtNet through by our software.

---

__A Note on [Syphon](https://syphon.github.io/)__ 
> Syphon is an open source Mac OS X technology that allows applications to share frames - full frame rate video or stills - with one another in realtime.

This means, since our application can receive Syphon frames, designers can design interactive animations (say 👀 movements, trigerred by diff inputs) in a compeltely different sofware and send frames using Syphon and our software just does one thing evry well, pixelate and send the data to LED matrix.

This de-coupling allows this "module" / "middleware" to be flexible enough for various files and stream formats and thus it can be used in a different setup alllowing for quick prototyping.

---

## Features (Summary)

- **Multiple Input Sources**:
  - Load static images (JPG, PNG, GIF, TIFF, TGA)
    - Drag-and-drop media loading or use the GUI
  - Play videos (MP4, MOV, AVI, WEBM)
    - **Video Synchronization**: Option to sync playback between left and right video streams
  - Capture real-time Syphon streams from other applications - _We will use that for sending eye animations from other softwares, for example ..._
- **Advanced Pixelation**: Four algorithms for different visual effects:
  - Average Color: Smooth, averaged colors for each cell
  - Nearest Neighbor: Crisp, center-sampled colors
  - Threshold: High-contrast black and white
  - Color Quantized: Limited color palette for retro aesthetics
- **ArtNet DMX Output**: Send color data to DMX-controlled lighting fixtures:
  - Broadcast or unicast mode (to a Target IP of a LED matrix controller)
  - Configurable universe and subnet
  - [You can find the Arduino / ESP32 project here for the HW code ..](simple/Arduino/esp32s3_8x8_ledmatrix_artnet_receiver)
- **User-Friendly Interface**
  - Toggle grid and effects with keyboard shortcuts
  - Interactive console with status updates

## System Requirements

- MacOS (Intel or Arm)
- ~~[Windows] Would need SPOUT Implementation - TBD~~

## Installation

1. Install [Processing](https://processing.org/download) - __Processing 4.x recommended for Intel X86 Architecture__
  > As the [Syphon Lib](https://github.com/Syphon/Processing) for Processing has not been ported for ARM Architechture yet. But running a Processing with Intel Architecture will render the things over Rosetta, on any ARM M Series Macs. [Follow this thread](https://github.com/Syphon/Java/issues/7) for more details.
2. Install the required libraries via Processing's Library Manager
   - Sketch > Import Library > Add Library
   - Search for and install: Video, Syphon, ArtNet, ControlP5, Drop
3. Clone or download this repository
4. Open `ArtNetSender.pde` in Processing

## Usage Instructions

### Starting the Application

1. Open `ArtNetSender.pde` in Processing
2. Click the Run button or press Ctrl/Cmd + R
3. The application window will appear with empty canvases

### Loading Media

- **Images/Videos**: Click "Select Left Eye File" or "Select Right Eye File" buttons
- **Drag and Drop**: Drag media files directly onto either canvas
- **Syphon**: Toggle the SYPHON buttons to capture from other applications

![alt text](_assets/software.gif)

### Controls

| Key | Function |
|-----|----------|
| `G` | Toggle grid/pixelation |
| `P` | Cycle through pixelation algorithms |
| `D` | Toggle DMX output |
| `S` | Toggle video synchronization |
| `L` | List available Syphon servers |
| `R` | Reload Syphon clients |
| `BACKSPACE` | Clear media under cursor |
| Mouse click on video | Play/pause video |

### DMX Configuration

1. Set broadcast mode or enter target IP address
2. Configure port (default: 6454)
3. Set subnet and universe values
4. Click "START DMX" to begin transmission

## Pixelation Settings

The application divides each canvas into an 8x8 grid, creating 64 cells per side, with each cell represented by 3 DMX channels (RGB).

- Left canvas: DMX channels 1-192
- Right canvas: DMX channels 193-384

---

## Troubleshooting

### Syphon Issues

- Use the `L` key to list available Syphon servers
- Ensure server names match "LeftEye" and "RightEye"
- Try reloading Syphon with the `R` key
- Confirm your Syphon source is running and publishing

### DMX Problems

- Check network connectivity
- Verify IP address, subnet, and universe settings
- Ensure receiving devices are properly configured
- Check console for error messages

---
