// Global DMX data array
byte[] dmxData = new byte[512];  // Standard DMX universe size

// Drop library for file (Img / Video) load
import drop.*;

// Video library
import processing.video.*;

// Art-Net library
import ch.bildspur.artnet.*;
import java.net.InetAddress;

// ControlP5 for UI controls
import controlP5.*;

// Syphon library for incoming texture
// ** Mac Only - Processing 4 for Intel X86 Architecture
// ** Till someone makes a syphon Lib for Apple silicon
import codeanticode.syphon.*;

// Global settings
boolean enableP3D = true;
int fr = 20;  // framerate

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

// Syphon related
SyphonClient leftSyphonClient;
SyphonClient rightSyphonClient;
PGraphics leftSyphonCanvas;
PGraphics rightSyphonCanvas;
boolean leftSyphonEnabled = false;
boolean rightSyphonEnabled = false;

// Global syphon server names
String leftSyphonServer = "LeftEye";
String rightSyphonServer = "RightEye";

// Snapshot images for pixelation
PImage leftContentSnapshot;
PImage rightContentSnapshot;

void settings() {
  if (!enableP3D) {
    size(640, 550);  // Default renderer
    println("[setting]\tUsing default renderer");
  } else {
    size(640, 550, P3D);  // P3D renderer
    println("[setting]\tUsing P3D renderer");
  }
}

void setup() {
  background(0);

  // Important for P3D mode - set hint to improve 2D rendering performance where appropriate
  if (enableP3D) {
    println("[setup]\tUsing P3D hint optimizations");
    hint(DISABLE_DEPTH_TEST);
    hint(DISABLE_TEXTURE_MIPMAPS);
  } else {
    println("[setup]\tNot using P3D hint optimizations");
  }

  // ** If using Syphon, don't introduce a FrameRate
  // ** as then the other syphon server may be running at a diff framerate
  //frameRate(fr);
  //println("[setup]\tUsing framerate: " + str(fr) + " FPS");

  // The below always makes the window stay on top of other windows
  surface.setAlwaysOnTop(true);

  // Initialize components
  // Create two canvases side by side, each with their own 320px width
  leftCanvas = new Canvas(0, 0, SINGLE_CANVAS_WIDTH, CANVAS_HEIGHT);
  rightCanvas = new Canvas(SINGLE_CANVAS_WIDTH, 0, SINGLE_CANVAS_WIDTH, CANVAS_HEIGHT);

  leftGrid = new Grid(8, 8, leftCanvas);
  rightGrid = new Grid(8, 8, rightCanvas);

  leftMediaHandler = new MediaHandler(this, leftCanvas);
  rightMediaHandler = new MediaHandler(this, rightCanvas);

  // Initialize Syphon canvases
  leftSyphonCanvas = createGraphics(SINGLE_CANVAS_WIDTH, CANVAS_HEIGHT, P3D);
  rightSyphonCanvas = createGraphics(SINGLE_CANVAS_WIDTH, CANVAS_HEIGHT, P3D);

  // Initialize snapshot images for pixelation
  leftContentSnapshot = createImage(SINGLE_CANVAS_WIDTH, CANVAS_HEIGHT, RGB);
  rightContentSnapshot = createImage(SINGLE_CANVAS_WIDTH, CANVAS_HEIGHT, RGB);

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
  log("[setup]\tArtNetSender started");
  log("[setup]\tCanvas dimensions: " + CANVAS_WIDTH + "x" + CANVAS_HEIGHT);
  log("[setup]\tConsole buffer limit: " + CONSOLE_BUFFER_LIMIT + " lines");
}

void draw() {
  // Clear the background
  background(0);

  if (enableP3D) {
    // Set appropriate rendering state for 2D content
    hint(DISABLE_DEPTH_TEST);
  }

  // Reset DMX data array to zeros at the start of each frame
  resetDMXData();

  // Process Syphon frames if enabled
  processSyphonInputs();

  // Setup rendering context
  if (enableP3D) {
    ortho();        // Explicitly set camera to orthographic view for consistent 2D rendering
    pushMatrix();   // Important: push the matrix state for 2D rendering
    translate(0, 0);  // Ensure proper positioning
  }

  // Render canvases
  leftCanvas.render();
  rightCanvas.render();

  // Render media content to canvases
  renderCanvasContent();

  // Reset rendering context if using P3D
  if (enableP3D) {
    popMatrix();
  }

  // Draw dividing lines
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

  // Update videos and handle synchronized playback
  updateVideosAndSync();

  // Send DMX data
  sendDMXData();
}



// Reset the DMX data array to zeros
void resetDMXData() {
  for (int i = 0; i < dmxData.length; i++) {
    dmxData[i] = 0;
  }
}


// Process incoming Syphon frames
void processSyphonInputs() {
  // Process left Syphon input
  if (leftSyphonEnabled && leftSyphonClient != null) {
    boolean newFrame = leftSyphonClient.newFrame();
    if (newFrame) {
      try {
        leftSyphonCanvas.beginDraw();
        leftSyphonClient.getImage(leftSyphonCanvas);
        leftSyphonCanvas.endDraw();

        // Update media handler with new frame
        leftMediaHandler.updateSyphonFrame(leftSyphonCanvas);
      }
      catch (Exception e) {
        log("Error processing left Syphon frame: " + e.getMessage());
      }
    }
  }

  // Process right Syphon input
  if (rightSyphonEnabled && rightSyphonClient != null) {
      boolean newFrame = rightSyphonClient.newFrame();
    if (newFrame) {
      try {
        rightSyphonCanvas.beginDraw();
        rightSyphonClient.getImage(rightSyphonCanvas);
        rightSyphonCanvas.endDraw();

        // Update media handler with new frame
        rightMediaHandler.updateSyphonFrame(rightSyphonCanvas);
      }
      catch (Exception e) {
        log("Error processing right Syphon frame: " + e.getMessage());
      }
    }
  }
}



// Render content to both canvases
void renderCanvasContent() {
  // Render left canvas content
  renderCanvasSide(leftMediaHandler, leftCanvas, leftGrid,
    leftSyphonEnabled, leftSyphonCanvas,
    leftContentSnapshot, 0);

  // Render right canvas content
  renderCanvasSide(rightMediaHandler, rightCanvas, rightGrid,
    rightSyphonEnabled, rightSyphonCanvas,
    rightContentSnapshot, 1);

  // CRITICAL FIX: Render zero-size images of videos to keep P3D video playback working
  if (enableP3D) {
    if (leftMediaHandler.isVideo && leftMediaHandler.loadedVideo != null) {
      image(leftMediaHandler.loadedVideo, 0, 0, 0, 0);
    }
    if (rightMediaHandler.isVideo && rightMediaHandler.loadedVideo != null) {
      image(rightMediaHandler.loadedVideo, 0, 0, 0, 0);
    }
  }
}



// Helper method to render one side of the canvas
void renderCanvasSide(MediaHandler mediaHandler, Canvas canvas, Grid grid,
  boolean syphonEnabled, PGraphics syphonCanvas,
  PImage contentSnapshot, int side) {
  if (!mediaHandler.hasContent()) {
    return;
  }

  if (!grid.isEnabled()) {
    // No grid - direct display
    if (syphonEnabled && syphonCanvas != null) {
      image(syphonCanvas, canvas.x, canvas.y);
    } else {
      image(mediaHandler.getProcessedMedia(), canvas.x, canvas.y);
    }
  } else {
    // With grid - use snapshot approach for Syphon
    if (syphonEnabled && syphonCanvas != null) {
      // Draw content first
      image(syphonCanvas, canvas.x, canvas.y);

      // Take a snapshot
      takeContentSnapshot(canvas, contentSnapshot);

      // Clear and draw pixelated grid
      canvas.render(); // Clear the canvas
      grid.drawPixelatedGridFromImage(contentSnapshot, side);
    } else {
      // Standard file-based media
      grid.drawPixelatedGrid(mediaHandler.getProcessedMedia(), side);
    }
  }
}

// Helper to take a snapshot of the current screen content
void takeContentSnapshot(Canvas canvas, PImage snapshot) {
  loadPixels();
  snapshot.loadPixels();

  for (int y = 0; y < CANVAS_HEIGHT; y++) {
    for (int x = 0; x < SINGLE_CANVAS_WIDTH; x++) {
      int sourceX = x + canvas.x;
      int sourceY = y + canvas.y;
      int sourceIndex = sourceY * width + sourceX;
      int targetIndex = y * SINGLE_CANVAS_WIDTH + x;

      if (sourceIndex < pixels.length && targetIndex < snapshot.pixels.length) {
        snapshot.pixels[targetIndex] = pixels[sourceIndex];
      }
    }
  }

  snapshot.updatePixels();
}



// Update videos and handle synchronized playback
void updateVideosAndSync() {
  // Check for video updates
  leftMediaHandler.update();
  rightMediaHandler.update();

  // Handle synchronized playback if enabled
  if (syncEnabled && bothVideos) {
    // Only sync every few frames to avoid performance issues
    if (frameCount % 5 == 0) {  // Sync every 5 frames
      syncVideoPlayback();
    }
  }
}


// Send DMX data
void sendDMXData() {
  if (enableDMX && dmxSender != null) {
    try {
      dmxSender.sendDMXData(dmxData);
    }
    catch (Exception e) {
      // Handle general exception
      log("DMX Send Error: " + e.getMessage());
    }
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

// List available Syphon servers
void listSyphonServers() {
  HashMap[] servers = SyphonClient.listServers();

  if (servers.length == 0) {
    log("No Syphon servers found");
  } else {
    log("Available Syphon servers:");
    for (int i = 0; i < servers.length; i++) {
      String appName = (String)servers[i].get("AppName");
      String serverName = (String)servers[i].get("ServerName");
      log(" - " + appName + ": " + serverName);
    }
  }
}

void toggleLeftSyphon(boolean enable) {
  leftSyphonEnabled = enable;

  if (enable) {
    // Check available servers first
    HashMap[] servers = SyphonClient.listServers();
    String appName = "";

    // Look for matching server name
    for (int i = 0; i < servers.length; i++) {
      String sName = (String)servers[i].get("ServerName");
      if (sName.equals(leftSyphonServer)) {
        appName = (String)servers[i].get("AppName");
        log("Found left Syphon server from app: " + appName);
        break;
      }
    }

    // Create Syphon client with found app name
    if (leftSyphonClient == null) {
      leftSyphonClient = new SyphonClient(this, appName, leftSyphonServer);
      log("Created left Syphon client - looking for '" + appName + ":" + leftSyphonServer + "'");
    }

    // Initialize syphon canvas if needed
    if (leftSyphonCanvas == null) {
      leftSyphonCanvas = createGraphics(SINGLE_CANVAS_WIDTH, CANVAS_HEIGHT, P3D);
    }

    // Clear any loaded media when switching to Syphon
    leftMediaHandler.clearMedia();
    leftMediaHandler.setSyphonMode(true);

    log("Left canvas switched to Syphon input");
  } else {
    // Disable Syphon but keep the client around
    leftMediaHandler.setSyphonMode(false);
    log("Left canvas switched to file input");
  }

  // Update UI elements
  ui.updateLeftSyphonState(enable);
}

void toggleRightSyphon(boolean enable) {
  rightSyphonEnabled = enable;

  if (enable) {
    // Check available servers first
    HashMap[] servers = SyphonClient.listServers();
    String appName = "";

    // Look for matching server name
    for (int i = 0; i < servers.length; i++) {
      String sName = (String)servers[i].get("ServerName");
      if (sName.equals(leftSyphonServer)) {
        appName = (String)servers[i].get("AppName");
        log("Found right Syphon server from app: " + appName);
        break;
      }
    }

    // Create Syphon client with found app name
    if (rightSyphonClient == null) {
      rightSyphonClient = new SyphonClient(this, appName, leftSyphonServer);
      log("Created right Syphon client - looking for '" + appName + ":" + leftSyphonServer + "'");
    }

    // Initialize syphon canvas if needed
    if (rightSyphonCanvas == null) {
      rightSyphonCanvas = createGraphics(SINGLE_CANVAS_WIDTH, CANVAS_HEIGHT, P3D);
    }

    // Clear any loaded media when switching to Syphon
    rightMediaHandler.clearMedia();
    rightMediaHandler.setSyphonMode(true);

    log("Right canvas switched to Syphon input");
  } else {
    // Disable Syphon but keep the client around
    rightMediaHandler.setSyphonMode(false);
    log("Right canvas switched to file input");
  }

  // Update UI elements
  ui.updateRightSyphonState(enable);
}

// Method to recreate Syphon clients, if needed
void recreateSyphonClients() {
  log("Recreating Syphon clients...");

  if (leftSyphonEnabled) {
    if (leftSyphonClient != null) {
      leftSyphonClient.stop();
    }
    leftSyphonClient = null;
    toggleLeftSyphon(true);
  }

  if (rightSyphonEnabled) {
    if (rightSyphonClient != null) {
      rightSyphonClient.stop();
    }
    rightSyphonClient = null;
    toggleRightSyphon(true);
  }
}

void keyPressed() {
  if (key == 'g' || key == 'G') {
    leftGrid.toggleGrid();
    rightGrid.toggleGrid();
    // Update the UI toggle to match the grid state
    ui.gridToggle.setValue(leftGrid.isEnabled());
    //log("Grid: " + (leftGrid.isEnabled() ? "Enabled" : "Disabled"));
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
  } else if (key == 'l' || key == 'L') {
    // List available Syphon servers
    listSyphonServers();
  } else if (key == 'r' || key == 'R') {
    // Recreate Syphon clients
    recreateSyphonClients();
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
        // Left side drop - only if Syphon is not enabled
        if (!leftSyphonEnabled) {
          leftMediaHandler.loadMedia(event.filePath());
        } else {
          log("Left side is in Syphon mode - drag and drop disabled");
        }
      } else {
        // Right side drop - only if Syphon is not enabled
        if (!rightSyphonEnabled) {
          rightMediaHandler.loadMedia(event.filePath());
        } else {
          log("Right side is in Syphon mode - drag and drop disabled");
        }
      }
      // Update sync state after new file loaded
      updateSyncState();
    }
  }
}

// File selection callbacks
void fileSelectedLeft(File selection) {
  if (selection != null) {
    // Only load if Syphon is not enabled
    if (!leftSyphonEnabled) {
      leftMediaHandler.loadMedia(selection.getAbsolutePath());
      updateSyncState();
    } else {
      log("Left side is in Syphon mode - file loading disabled");
    }
  }
}

void fileSelectedRight(File selection) {
  if (selection != null) {
    // Only load if Syphon is not enabled
    if (!rightSyphonEnabled) {
      rightMediaHandler.loadMedia(selection.getAbsolutePath());
      updateSyncState();
    } else {
      log("Right side is in Syphon mode - file loading disabled");
    }
  }
}

// Helper method to print to console with proper logging
void log(String message) {
  println(message);  // Still print to Processing console

  // Check if UI and console are initialized before using them
  if (ui != null && ui.console != null) {
    ui.printToConsole(message);
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
