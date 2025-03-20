// ToDo
// 1. Fix the DropDown selector on top always.
// 2. Save config of IP and boardcast 
// 3. Enlarge the window
// 4. Add console

// Libraries for file dropping and video processing
import drop.*;
import processing.video.*;
// Art-Net library
import ch.bildspur.artnet.*;
import java.net.InetAddress;
// ControlP5 for UI controls
import controlP5.*;



// Main sketch dimensions
final int SKETCH_WIDTH = 320;
final int SKETCH_HEIGHT = 320;
final int CANVAS_WIDTH = 320;
final int CANVAS_HEIGHT = 320;


// Main Objects / Classes / Components
Canvas mainCanvas;
MediaHandler mediaHandler;
Grid grid;
SDrop drop;
DMXSender dmxSender;
//UserInterface ui;
ControlFrame controlFrame;

// DMX Configuration - Can be adjusted easily here
boolean enableDMX = false;
boolean useBroadcast = true;  // true for broadcast, false for unicast
String targetIP = "255.255.255.255";  // IP address (use .255 for broadcast)
int artNetPort = 6454;  // Standard Art-Net port
int universe = 0;  // DMX Universe
int subnet = 0;  // DMX Subnet


void setup() {
  size(320, 320);
  background(0);

  frameRate(20);

  // The below always makes the window stay on top of other windows
  surface.setAlwaysOnTop(true);

  // Initialize components
  mainCanvas = new Canvas(0, 0, CANVAS_WIDTH, CANVAS_HEIGHT);
  grid = new Grid(8, 8, mainCanvas);
  mediaHandler = new MediaHandler(this, mainCanvas);

  // Setup drop functionality
  drop = new SDrop(this);

  // Initialize DMX Sender
  if (enableDMX) {
    dmxSender = new DMXSender(useBroadcast, targetIP, artNetPort, universe, subnet);
    dmxSender.connect();
  }

  // Initialize UI
  controlFrame = new ControlFrame(this, 320, 230, "Controller");
  surface.setLocation(10+320, 10); // Position main window
}

void draw() {
  // Clear the background
  background(0);

  // Render canvas
  mainCanvas.render();

  // Draw media content
  if (mediaHandler.hasContent()) {
    if (!grid.isEnabled()) {
      // Show normal image/video
      image(mediaHandler.getProcessedMedia(), mainCanvas.x, mainCanvas.y);
    } else {
      // Show pixelated version
      grid.drawPixelatedGrid(mediaHandler.getProcessedMedia());
    }
  }

  // Check for video updates
  mediaHandler.update();
}



void keyPressed() {
  if (key == 'g' || key == 'G') {
    grid.toggleGrid();
  } else if (key == 'p' || key == 'P') {
    grid.cyclePixelationAlgorithm();
  } else if (key == 'd' || key == 'D') {
    // Toggle DMX on/off
    enableDMX = !enableDMX;
    println("DMX Output: " + (enableDMX ? "Enabled" : "Disabled"));

    if (enableDMX && dmxSender == null) {
      dmxSender = new DMXSender(useBroadcast, targetIP, artNetPort, universe, subnet);
      dmxSender.connect();
    }
  }
}

void dropEvent(DropEvent event) {
  if (event.isFile()) {
    mediaHandler.loadMedia(event.filePath());
  }
}

//File selection callback
void fileSelected(File selection) {
  if (selection != null) {
    mediaHandler.loadMedia(selection.getAbsolutePath());
  }
}

// Override exit to perform cleanup before closing
void exit() {
  println("Application closing, performing cleanup...");

  // If DMX is enabled, send blackout before closing
  if (enableDMX && dmxSender != null) {
    // Create all-zero (black) DMX data
    byte[] blackoutData = new byte[512];

    // Fill with zeros (creating a blackout)
    for (int i = 0; i < blackoutData.length; i++) {
      blackoutData[i] = 0;
    }

    // Send the blackout data
    println("Sending DMX blackout before exit");
    dmxSender.sendDMXData(blackoutData);

    // Add a small delay to ensure data is sent
    delay(100);

    // Stop the DMX sender properly
    dmxSender.stop();
  }

  // Call the super method to continue with normal exit process
  super.exit();
}
