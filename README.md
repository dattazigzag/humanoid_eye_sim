# ArtNet DMX Sender for 2*8x8 addreassable LED matrices - for 🤖 👀

A Processing-based application for real-time pixelation of media content (images, videos, and Syphon streams) with ArtNet DMX output capabilities. Designed for controlling LED installations, pixel mapping projects, and creating visual effects for performances and installations.

![ArtNet DMX Pixelator](https://via.placeholder.com/800x450)

## Features

- **Dual-Channel Operation**: Process two separate media inputs simultaneously
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
  - [You can find the Arduino / ESP32 project here for teh HW code ..](simple/Arduino/esp32s3_8x8_ledmatrix_artnet_receiver)
- **User-Friendly Interface**
  - Toggle grid and effects with keyboard shortcuts
  - Interactive console with status updates

## System Requirements

- MacOS (Intel or Arm)
- ~~[Windows] Would need SPOUT Implementation - TBD~~

## Installation

1. Install [Processing](https://processing.org/download) - __Processing 4.x recommended for Intel X86 Architecture__
  > As the [Syphon Lib](https://github.com/Syphon/Processing) for Processing has not been ported for ARM Architechture yet. But running a Processing with Intel Architecture will render the thing sover Rosetta, on an ARM M Series Macs. [Follow this thread](https://github.com/Syphon/Java/issues/7)
2. Install the required libraries via Processing's Library Manager:
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

## Troubleshooting

### Syphon Issues

- Use the `L` key to list available Syphon servers
- Ensure server names match "LeftEye" and "RightEye"
- Try reloading Syphon with the `R` key
- Confirm your Syphon source is running and publishing

### Performance Issues

- Disable P3D mode in settings for better performance on older hardware
- Reduce video resolution for smoother operation
- Close other memory-intensive applications

### DMX Problems

- Check network connectivity
- Verify IP address, subnet, and universe settings
- Ensure receiving devices are properly configured
- Check console for error messages

## Credits

- ArtNet DMX Pixelator - Created with Processing
- Uses the following libraries:
  - [Syphon](https://github.com/Syphon/Processing) for inter-application video sharing
  - [ArtNet](https://github.com/cansik/artnet4j) for DMX communication
  - [ControlP5](https://github.com/sojamo/controlp5) for UI elements
  - [Drop](https://github.com/transfluxus/drop) for drag and drop functionality