// Global DMX data array
byte[] dmxData = new byte[512];  // Standard DMX universe size// Libraries for file dropping and video processing
import drop.*;
import processing.video.*;
// Art-Net library
import ch.bildspur.artnet.*;
import java.net.InetAddress;
// ControlP5 for UI controls
import controlP5.*;

// Main sketch dimensions
final int SKETCH_WIDTH = 640;
final int SKETCH_HEIGHT = 550;
final int CANVAS_WIDTH = 640;  // Using full width of the sketch
final int CANVAS_HEIGHT = 320;
final int RESERVED_HEIGHT = 230;
final int SINGLE_CANVAS_WIDTH = 320; // Each canvas gets half of the total width

// Console configuration
final int CONSOLE_BUFFER_LIMIT = 100; // Maximum number of lines in console before auto-clearing
// Global reference to the console for easy access
Textarea appConsole;

// Main Objects / Classes / Components
Canvas leftCanvas;
Canvas rightCanvas;
MediaHandler leftMediaHandler;
MediaHandler rightMediaHandler;
Grid leftGrid;
Grid rightGrid;
SDrop drop;
DMXSender dmxSender;
UserInterface ui;

// DMX Configuration - Can be adjusted easily here
boolean enableDMX = false;
boolean useBroadcast = true;  // true for broadcast, false for unicast
String targetIP = "255.255.255.255";  // IP address (use .255 for broadcast)
int artNetPort = 6454;  // Standard Art-Net port
int universe = 0;  // DMX Universe
int subnet = 0;  // DMX Subnet

// Sync configuration
boolean syncEnabled = false;
boolean bothVideos = false;

void setup() {
  size(640, 550, P3D);
  background(0);

  // Important for P3D mode - set hint to improve 2D rendering performance where appropriate
  hint(DISABLE_DEPTH_TEST);
  hint(DISABLE_TEXTURE_MIPMAPS);

  frameRate(20);

  // The below always makes the window stay on top of other windows
  surface.setAlwaysOnTop(true);

  // Initialize components
  // Create two canvases side by side, each with their own 160px width
  leftCanvas = new Canvas(0, 0, SINGLE_CANVAS_WIDTH, CANVAS_HEIGHT);
  rightCanvas = new Canvas(SINGLE_CANVAS_WIDTH, 0, SINGLE_CANVAS_WIDTH, CANVAS_HEIGHT);

  leftGrid = new Grid(8, 8, leftCanvas);
  rightGrid = new Grid(8, 8, rightCanvas);

  leftMediaHandler = new MediaHandler(this, leftCanvas);
  rightMediaHandler = new MediaHandler(this, rightCanvas);

  // Setup drop functionality
  drop = new SDrop(this);

  // Initialize DMX Sender
  if (enableDMX) {
    dmxSender = new DMXSender(useBroadcast, targetIP, artNetPort, universe, subnet);
    dmxSender.connect();
  }

  // Initialize UI
  ui = new UserInterface(this, 0, CANVAS_HEIGHT, SKETCH_WIDTH, RESERVED_HEIGHT);

  // Update sync state after initializing media handlers
  updateSyncState();

  // Log application startup
  log("ArtNetSender started");
  log("Canvas dimensions: " + CANVAS_WIDTH + "x" + CANVAS_HEIGHT);
  log("Console buffer limit: " + CONSOLE_BUFFER_LIMIT + " lines");
}

void draw() {
  // Clear the background
  background(0);

  // Set appropriate rendering state for 2D content
  hint(DISABLE_DEPTH_TEST);

  // Reset DMX data array to zeros at the start of each frame
  for (int i = 0; i < dmxData.length; i++) {
    dmxData[i] = 0;
  }

  // Explicitly set camera to orthographic view for consistent 2D rendering
  ortho();
  // Important: push the matrix state for 2D rendering
  pushMatrix();
  // Set the coordinate system to top-left origin for 2D
  //resetMatrix();
  translate(0, 0);

  // Render canvases
  leftCanvas.render();
  rightCanvas.render();

  // Draw left media content
  if (leftMediaHandler.hasContent()) {
    if (!leftGrid.isEnabled()) {
      // Show normal image/video - ensure it's positioned correctly at the left canvas origin
      image(leftMediaHandler.getProcessedMedia(), leftCanvas.x, leftCanvas.y);
      //image(leftMediaHandler.loadedVideo, 0, 0, 0, 0);
    } else {
      // Show pixelated version
      leftGrid.drawPixelatedGrid(leftMediaHandler.getProcessedMedia(), 0); // 0 indicates left side
    }
  }

  // Draw right media content
  if (rightMediaHandler.hasContent()) {
    if (!rightGrid.isEnabled()) {
      // Show normal image/video - ensure it's positioned correctly at the right canvas origin
      image(rightMediaHandler.getProcessedMedia(), rightCanvas.x, rightCanvas.y);
      //image(rightMediaHandler.loadedVideo, 0, 0, 0, 0);
    } else {
      // Show pixelated version
      rightGrid.drawPixelatedGrid(rightMediaHandler.getProcessedMedia(), 1); // 1 indicates right side
    }
  }

  // CRITICAL FIX: Render zero-size images of videos to keep P3D video playback working
  if (leftMediaHandler.isVideo && leftMediaHandler.loadedVideo != null) {
    image(leftMediaHandler.loadedVideo, 0, 0, 0, 0);
  }

  if (rightMediaHandler.isVideo && rightMediaHandler.loadedVideo != null) {
    image(rightMediaHandler.loadedVideo, 0, 0, 0, 0);
  }

  // Restore the matrix state
  popMatrix();
  
  // Draw a dividing line for the reserved area
  stroke(50);
  strokeWeight(0.5);
  line(0, leftCanvas.height, CANVAS_WIDTH, leftCanvas.height);
  noStroke();

  // Draw a dividing line between left and right canvases
  stroke(100);
  strokeWeight(0.5);
  line(SINGLE_CANVAS_WIDTH, 0, SINGLE_CANVAS_WIDTH, CANVAS_HEIGHT);
  noStroke();

  // Render UI
  ui.render();

  // Check for video updates
  leftMediaHandler.update();
  rightMediaHandler.update();

  // Handle synchronized playback if enabled
  if (syncEnabled && bothVideos) {
    // Only sync every few frames to avoid performance issues
    if (frameCount % 8 == 0) {  // Sync every 8 frames
      syncVideoPlayback();
    }
  }

  // *** Send combined DMX data once per frame ***
  if (enableDMX && dmxSender != null) {
    dmxSender.sendDMXData(dmxData);
  }
}

void syncVideoPlayback() {
  // Only proceed if both sides have videos
  if (leftMediaHandler.isVideo && rightMediaHandler.isVideo &&
    leftMediaHandler.loadedVideo != null && rightMediaHandler.loadedVideo != null) {

    // Match play/pause state
    if (leftMediaHandler.loadedVideo.isPlaying() && !rightMediaHandler.loadedVideo.isPlaying()) {
      rightMediaHandler.loadedVideo.play();
    } else if (!leftMediaHandler.loadedVideo.isPlaying() && rightMediaHandler.loadedVideo.isPlaying()) {
      leftMediaHandler.loadedVideo.play();
    }

    // For same video files, try to match positions more precisely
    // Get current time positions
    float leftTime = leftMediaHandler.loadedVideo.time();
    float rightTime = rightMediaHandler.loadedVideo.time();

    // If there's more than a small threshold difference, sync them
    if (abs(leftTime - rightTime) > 0.1) {
      // Use the left video as the reference
      rightMediaHandler.loadedVideo.jump(leftTime);
      log("Syncing videos: Setting right video to time: " + leftTime);
    }
  }
}

void keyPressed() {
  if (key == 'g' || key == 'G') {
    leftGrid.toggleGrid();
    rightGrid.toggleGrid();
    // Update the UI toggle to match the grid state
    ui.gridToggle.setValue(leftGrid.isEnabled());
    log("Grid: " + (leftGrid.isEnabled() ? "Enabled" : "Disabled"));
  } else if (key == 'p' || key == 'P') {
    leftGrid.cyclePixelationAlgorithm();
    rightGrid.cyclePixelationAlgorithm();
    log("Pixelation Algorithm: " + leftGrid.algorithmNames[leftGrid.currentAlgorithm]);
  } else if (key == 'd' || key == 'D') {
    // Toggle DMX on/off
    enableDMX = !enableDMX;
    log("DMX Output: " + (enableDMX ? "Enabled" : "Disabled"));

    if (enableDMX && dmxSender == null) {
      dmxSender = new DMXSender(useBroadcast, targetIP, artNetPort, universe, subnet);
      dmxSender.connect();
    }
  } else if (key == 's' || key == 'S') {
    // Toggle sync
    toggleSync();
  } else if (key == BACKSPACE) {
    // Delete the file under the mouse cursor
    deleteFileUnderCursor();
  }
}

void toggleSync() {
  if (bothVideos) {
    syncEnabled = !syncEnabled;
    log("Video Sync: " + (syncEnabled ? "Enabled" : "Disabled"));

    // Update the UI toggle
    ui.syncToggle.setValue(syncEnabled);

    // If sync just got enabled, immediately sync the videos
    if (syncEnabled &&
      leftMediaHandler.loadedVideo != null &&
      rightMediaHandler.loadedVideo != null) {

      // If the left video is playing, make sure the right one is too
      if (leftMediaHandler.loadedVideo.isPlaying()) {
        rightMediaHandler.loadedVideo.play();

        // Also try to match positions
        float leftTime = leftMediaHandler.loadedVideo.time();
        rightMediaHandler.loadedVideo.jump(leftTime);
        log("Initial sync: Setting right video to time: " + leftTime);
      }
      // If left is paused but right is playing, pause right too
      else if (rightMediaHandler.loadedVideo.isPlaying()) {
        rightMediaHandler.loadedVideo.pause();
      }
    }
  }
}

void updateSyncState() {
  // Check if both media are videos and have loaded video objects
  boolean wasVideos = bothVideos;
  bothVideos = (leftMediaHandler.isVideo && rightMediaHandler.isVideo &&
    leftMediaHandler.loadedVideo != null && rightMediaHandler.loadedVideo != null);

  // If either is not a video, disable sync
  if (!bothVideos) {
    syncEnabled = false;
    ui.syncToggle.setValue(false);
    ui.syncToggle.setLock(true);
    log("Sync disabled: Not both videos");
  } else {
    ui.syncToggle.setLock(false);
    log("Both videos detected, sync toggle enabled");

    // If we just got both videos and weren't before, and sync is enabled, do an initial sync
    if (!wasVideos && syncEnabled) {
      // Force an immediate sync
      syncVideoPlayback();
    }
  }
}

void deleteFileUnderCursor() {
  // Only handle deletion if mouse is within the application window
  if (mouseX >= 0 && mouseX < width && mouseY >= 0 && mouseY < height) {
    if (mouseY < CANVAS_HEIGHT) {
      if (mouseX < SINGLE_CANVAS_WIDTH) {
        // Delete left side media
        leftMediaHandler.clearMedia();
      } else {
        // Delete right side media
        rightMediaHandler.clearMedia();
      }
      // Update sync state after deletion
      updateSyncState();
    }
  }
}

void mousePressed() {
  // Only handle clicks in the canvas area
  if (mouseY < CANVAS_HEIGHT) {
    if (mouseX < SINGLE_CANVAS_WIDTH) {
      // Handle left canvas click
      if (leftMediaHandler.isVideo && leftMediaHandler.loadedVideo != null) {
        if (leftMediaHandler.loadedVideo.isPlaying()) {
          leftMediaHandler.loadedVideo.pause();
        } else {
          leftMediaHandler.loadedVideo.play();
        }

        // If sync is enabled, match the right video playback state
        if (syncEnabled && rightMediaHandler.isVideo && rightMediaHandler.loadedVideo != null) {
          if (leftMediaHandler.loadedVideo.isPlaying()) {
            rightMediaHandler.loadedVideo.play();
          } else {
            rightMediaHandler.loadedVideo.pause();
          }
        }
      }
    } else {
      // Handle right canvas click
      if (rightMediaHandler.isVideo && rightMediaHandler.loadedVideo != null) {
        if (rightMediaHandler.loadedVideo.isPlaying()) {
          rightMediaHandler.loadedVideo.pause();
        } else {
          rightMediaHandler.loadedVideo.play();
        }

        // If sync is enabled, match the left video playback state
        if (syncEnabled && leftMediaHandler.isVideo && leftMediaHandler.loadedVideo != null) {
          if (rightMediaHandler.loadedVideo.isPlaying()) {
            leftMediaHandler.loadedVideo.play();
          } else {
            leftMediaHandler.loadedVideo.pause();
          }
        }
      }
    }
  }
}

void dropEvent(DropEvent event) {
  if (event.isFile()) {
    // Determine drop location
    if (event.y() < CANVAS_HEIGHT) {
      if (event.x() < SINGLE_CANVAS_WIDTH) {
        // Left side drop
        leftMediaHandler.loadMedia(event.filePath());
      } else {
        // Right side drop
        rightMediaHandler.loadMedia(event.filePath());
      }
      // Update sync state after new file loaded
      updateSyncState();
    }
  }
}

// File selection callbacks
void fileSelectedLeft(File selection) {
  if (selection != null) {
    leftMediaHandler.loadMedia(selection.getAbsolutePath());
    updateSyncState();
  }
}

void fileSelectedRight(File selection) {
  if (selection != null) {
    rightMediaHandler.loadMedia(selection.getAbsolutePath());
    updateSyncState();
  }
}

// Override exit to perform cleanup before closing
void exit() {
  log("Application closing, performing cleanup...");

  // If DMX is enabled, send blackout before closing
  if (enableDMX && dmxSender != null) {
    // Reset the DMX data array to zeros (creating a blackout)
    for (int i = 0; i < dmxData.length; i++) {
      dmxData[i] = 0;
    }

    // Send the blackout data
    log("Sending DMX blackout before exit");
    dmxSender.sendDMXData(dmxData);

    // Add a small delay to ensure data is sent
    delay(100);

    // Stop the DMX sender properly
    dmxSender.stop();
  }

  // Call the super method to continue with normal exit process
  super.exit();
}



// Helper method to print to console with proper logging
void log(String message) {
  println(message);  // Still print to Processing console

  // Check if UI and console are initialized before using them
  if (ui != null && ui.console != null) {
    ui.printToConsole(message);
  }
}
