// Syphon Pixelation Test
// This is a simplified sketch to test pixelation on Syphon frames

// Libraries
import codeanticode.syphon.*;
import ch.bildspur.artnet.*;
import java.net.InetAddress;

// Canvas and Syphon objects
PGraphics canvasRed;
PGraphics displayCanvas;
SyphonClient client_red;
PImage contentSnapshot;

// Canvas dimensions
int SIZE_TOTAL_WIDTH = 320;
int SIZE_TOTAL_HEIGHT = 320;
int SIZE_CANVAS_WIDTH = 320;
int SIZE_CANVAS_HEIGHT = 320;

// Grid and pixelation
boolean gridEnabled = false;
int currentAlgorithm = 0; // 0=Average, 1=Nearest, 2=Threshold, 3=Quantized
String[] algorithmNames = {"Average Color", "Nearest Neighbor", "Threshold", "Color Quantized"};
int gridSize = 8; // 8x8 grid
int cellWidth, cellHeight;

// DMX data array and configuration
byte[] dmxData = new byte[512];  // Standard DMX universe size
int artNetPort = 6454;  // Standard Art-Net port
int universe = 0;       // DMX Universe
int subnet = 0;         // DMX Subnet
ArtNetClient artnet;
boolean dmxStarted = false;     // Track if ArtNet client is started
boolean dmxTogglePending = false; // To prevent rapid socket toggling
int dmxToggleDelay = 500;       // Time to wait between DMX state changes (milliseconds)
long lastDmxToggleTime = 0;     // Track when we last toggled DMX
boolean useBroadcast = true;    // Use broadcast mode
String targetIP = "255.255.255.255"; // Broadcast address

void settings() {
  size(SIZE_TOTAL_WIDTH, SIZE_TOTAL_HEIGHT, P3D);
}

void setup() {
  hint(DISABLE_DEPTH_TEST);
  hint(DISABLE_TEXTURE_MIPMAPS);

  // Calculate cell dimensions
  cellWidth = SIZE_CANVAS_WIDTH / gridSize;
  cellHeight = SIZE_CANVAS_HEIGHT / gridSize;
  println("Grid cell size: " + cellWidth + "x" + cellHeight);

  // The below always makes the window stay on top of other windows
  surface.setAlwaysOnTop(true);

  // Create separate canvases for each source
  canvasRed = createGraphics(SIZE_CANVAS_WIDTH, SIZE_TOTAL_HEIGHT, P3D);
  displayCanvas = createGraphics(SIZE_TOTAL_WIDTH, SIZE_TOTAL_HEIGHT, P3D);

  // Create Syphon client
  client_red = new SyphonClient(this, "", "LeftEye");

  // Create snapshot image for pixelation processing
  contentSnapshot = createImage(SIZE_CANVAS_WIDTH, SIZE_CANVAS_HEIGHT, RGB);

  // Initialize ArtNet but don't start yet
  artnet = new ArtNetClient(new ArtNetBuffer(), artNetPort, artNetPort);

  background(0);

  println("Syphon Pixelation Test Started");
  println("Press 'g' to toggle grid (also controls DMX broadcasting)");
  println("Press 1-4 to change pixelation algorithm");
  println("Press 'l' to list available Syphon servers");
  println("Press BACKSPACE to clear media");
  println("Press 'r' to reload Syphon client");
}

void draw() {
  background(0);
  hint(DISABLE_DEPTH_TEST);

  // Reset DMX data array to zeros at the start of each frame
  for (int i = 0; i < dmxData.length; i++) {
    dmxData[i] = 0;
  }

  // Get new Syphon frame
  if (client_red.newFrame()) {
    canvasRed.beginDraw();
    client_red.getImage(canvasRed);
    canvasRed.endDraw();
  }

  // Draw content based on grid state
  if (!gridEnabled) {
    // Without grid - just show the content directly
    image(canvasRed, 0, 0);
  } else {
    // With grid - capture content, then pixelate it

    // 1. Draw content to main sketch
    pushMatrix();
    ortho();
    image(canvasRed, 0, 0);
    popMatrix();

    // 2. Take a snapshot of what was just drawn
    loadPixels();
    contentSnapshot.loadPixels();
    for (int y = 0; y < SIZE_CANVAS_HEIGHT; y++) {
      for (int x = 0; x < SIZE_CANVAS_WIDTH; x++) {
        int index = y * width + x;
        if (index < pixels.length && index < contentSnapshot.pixels.length) {
          contentSnapshot.pixels[index] = pixels[index];
        }
      }
    }
    contentSnapshot.updatePixels();

    // 3. Clear and draw pixelated grid using the snapshot
    background(0);
    drawPixelatedGridFromImage(contentSnapshot);
  }

  // Draw info overlay
  fill(0, 150);
  noStroke();
  rect(0, 0, width, 60);

  fill(255);
  textAlign(LEFT, TOP);
  textSize(12);
  text("Grid: " + (gridEnabled ? "ON" : "OFF"), 10, 10);
  text("Algorithm: " + algorithmNames[currentAlgorithm], 10, 30);


  // Send DMX data if enabled
  if (dmxTogglePending && millis() - lastDmxToggleTime >= dmxToggleDelay) {
    manageDMX(gridEnabled);
  }

  // Send DMX data if grid is enabled and DMX is started
  if (gridEnabled && dmxStarted) {
    try {
      // Only send if artnet exists and is started
      if (artnet != null) {
        artnet.unicastDmx(targetIP, subnet, universe, dmxData);

        // Periodically log DMX transmission
        if (frameCount % 60 == 0) {
          println("DMX data sent - Universe: " + universe);
        }
      }
    }
    catch (Exception e) {
      // Handle all exceptions more generally
      if (e.getMessage() != null && e.getMessage().contains("Socket closed")) {
        println("Warning: DMX socket was closed. Attempting to restart...");
        dmxStarted = false;
        manageDMX(gridEnabled);
      } else {
        println("Error sending DMX: " + e.getMessage());
        e.printStackTrace();  // Print the stack trace for debugging
      }
    }
  }

  // Indicate frame updates
  if (frameCount % 30 == 0) {
    println("FPS: " + nf(frameRate, 0, 1));
  }
}

// Process a PImage and draw a pixelated grid
void drawPixelatedGridFromImage(PImage img) {
  img.loadPixels();

  // Process each cell in the grid
  for (int y = 0; y < gridSize; y++) {
    for (int x = 0; x < gridSize; x++) {
      int startX = x * cellWidth;
      int startY = y * cellHeight;

      // Apply the selected algorithm
      color cellColor;
      switch (currentAlgorithm) {
      case 0: // Average
        cellColor = calculateAverageColorFromImage(img, startX, startY, cellWidth, cellHeight);
        break;
      case 1: // Nearest Neighbor
        cellColor = getNearestNeighborColorFromImage(img, startX, startY, cellWidth, cellHeight);
        break;
      case 2: // Threshold
        cellColor = getThresholdColorFromImage(img, startX, startY, cellWidth, cellHeight);
        break;
      case 3: // Quantized
        cellColor = getQuantizedColorFromImage(img, startX, startY, cellWidth, cellHeight);
        break;
      default:
        cellColor = calculateAverageColorFromImage(img, startX, startY, cellWidth, cellHeight);
      }

      // Draw the cell with the calculated color
      fill(cellColor);
      noStroke();
      rect(startX, startY, cellWidth, cellHeight);

      // Draw grid lines
      stroke(50);
      strokeWeight(0.5);
      noFill();
      rect(startX, startY, cellWidth, cellHeight);

      // Calculate DMX data
      int cellIndex = y * gridSize + x;
      int dmxIndex = cellIndex * 3;

      // Store RGB values in DMX data array (3 channels per cell)
      if (dmxIndex < 384) {  // 384 = 64 cells * 3 channels = 192 DMX channels
        dmxData[dmxIndex] = (byte) (int) red(cellColor);
        dmxData[dmxIndex + 1] = (byte) (int) green(cellColor);
        dmxData[dmxIndex + 2] = (byte) (int) blue(cellColor);
      }
    }
  }
}

// Color Algorithm 1: AVERAGE - Calculate average color in a cell
color calculateAverageColorFromImage(PImage img, int startX, int startY, int w, int h) {
  float r = 0, g = 0, b = 0;
  int count = 0;

  for (int y = startY; y < startY + h && y < img.height; y++) {
    for (int x = startX; x < startX + w && x < img.width; x++) {
      int index = y * img.width + x;
      if (index < img.pixels.length) {
        color c = img.pixels[index];
        r += red(c);
        g += green(c);
        b += blue(c);
        count++;
      }
    }
  }

  if (count > 0) {
    r /= count;
    g /= count;
    b /= count;
  }

  return color(r, g, b);
}

// Color Algorithm 2: NEAREST NEIGHBOR - Get color from center of cell
color getNearestNeighborColorFromImage(PImage img, int startX, int startY, int w, int h) {
  int centerX = startX + w/2;
  int centerY = startY + h/2;

  centerX = constrain(centerX, 0, img.width-1);
  centerY = constrain(centerY, 0, img.height-1);

  int index = centerY * img.width + centerX;
  if (index >= 0 && index < img.pixels.length) {
    return img.pixels[index];
  } else {
    return color(0);
  }
}

// Color Algorithm 3: THRESHOLD - Black and white based on brightness threshold
color getThresholdColorFromImage(PImage img, int startX, int startY, int w, int h) {
  color avgColor = calculateAverageColorFromImage(img, startX, startY, w, h);
  float brightness = (red(avgColor) + green(avgColor) + blue(avgColor)) / 3;
  return brightness < 128 ? color(0) : color(255);
}

// Color Algorithm 4: COLOR QUANTIZED - Reduce to limited palette
color getQuantizedColorFromImage(PImage img, int startX, int startY, int w, int h) {
  color avgColor = calculateAverageColorFromImage(img, startX, startY, w, h);
  float r = red(avgColor);
  float g = green(avgColor);
  float b = blue(avgColor);

  r = round(r / 85) * 85;
  g = round(g / 85) * 85;
  b = round(b / 85) * 85;

  return color(r, g, b);
}

void keyPressed() {
  if (key == ' ') {
    client_red.stop();
    println("Syphon client stopped");
  } else if (key == 'l') {
    println("Available Syphon servers:");
    HashMap[] servers = SyphonClient.listServers();
    if (servers.length == 0) {
      println("No servers found");
    } else {
      for (int i = 0; i < servers.length; i++) {
        String appName = (String)servers[i].get("AppName");
        String serverName = (String)servers[i].get("ServerName");
        println(" - " + appName + ": " + serverName);
      }
    }
  } else if (key == 'g' || key == 'G') {
    // Toggle grid
    gridEnabled = !gridEnabled;
    println("Grid: " + (gridEnabled ? "Enabled" : "Disabled"));

    // Link DMX state to grid state
    manageDMX(gridEnabled);

    // If grid was just enabled, print DMX data for debugging
    if (gridEnabled) {
      println("DMX Data (first 24 channels):");
      for (int i = 0; i < 24; i += 3) {
        println("Pixel " + (i/3) + ": R=" + (dmxData[i] & 0xFF) +
          ", G=" + (dmxData[i+1] & 0xFF) +
          ", B=" + (dmxData[i+2] & 0xFF));
      }
    }
  } else if (key == '1') {
    // Algorithm 1 - Average
    currentAlgorithm = 0;
    println("Algorithm: " + algorithmNames[currentAlgorithm]);
  } else if (key == '2') {
    // Algorithm 2 - Nearest Neighbor
    currentAlgorithm = 1;
    println("Algorithm: " + algorithmNames[currentAlgorithm]);
  } else if (key == '3') {
    // Algorithm 3 - Threshold
    currentAlgorithm = 2;
    println("Algorithm: " + algorithmNames[currentAlgorithm]);
  } else if (key == '4') {
    // Algorithm 4 - Quantized
    currentAlgorithm = 3;
    println("Algorithm: " + algorithmNames[currentAlgorithm]);
  } else if (key == BACKSPACE) {
    // Clear by recreating client
    client_red.stop();
    client_red = new SyphonClient(this, "", "LeftEye");
    println("Media cleared, Syphon client recreated");
  } else if (key == 'r' || key == 'R') {
    // Reload Syphon client
    client_red.stop();
    client_red = new SyphonClient(this, "", "LeftEye");
    println("Syphon client reloaded");
  }
}



void manageDMX(boolean shouldBeActive) {
  // Don't allow rapid toggling
  long currentTime = millis();
  if (currentTime - lastDmxToggleTime < dmxToggleDelay) {
    // Queue the toggle for later
    dmxTogglePending = true;
    return;
  }

  if (shouldBeActive && !dmxStarted) {
    // Start ArtNet
    try {
      if (artnet != null) {
        artnet.stop(); // Make sure it's stopped first
        delay(100);    // Small delay to ensure clean state
      }

      // Create a fresh client
      artnet = new ArtNetClient(new ArtNetBuffer(), artNetPort, artNetPort);

      if (useBroadcast) {
        artnet.start();
        println("DMX broadcasting started (grid enabled)");
      } else {
        InetAddress address = InetAddress.getByName(targetIP);
        artnet.start(address);
        println("DMX unicast started to " + targetIP);
      }
      dmxStarted = true;
    }
    catch (Exception e) {
      println("Error starting ArtNet: " + e.getMessage());
    }
  } else if (!shouldBeActive && dmxStarted) {
    // Stop ArtNet
    try {
      if (artnet != null) {
        // Send a blackout first
        try {
          byte[] blackout = new byte[512];
          artnet.unicastDmx(targetIP, subnet, universe, blackout);
          delay(50); // Brief delay to let the packet go out
        }
        catch (Exception e) {
          // Ignore errors during blackout
        }

        artnet.stop();
        println("DMX broadcasting stopped (grid disabled)");
      }
    }
    catch (Exception e) {
      println("Error stopping ArtNet: " + e.getMessage());
    }
    finally {
      dmxStarted = false;
    }
  }

  lastDmxToggleTime = currentTime;
  dmxTogglePending = false;
}



void exit() {
  // Clean shutdown of ArtNet
  if (dmxStarted) {
    // Send blackout before closing
    for (int i = 0; i < dmxData.length; i++) {
      dmxData[i] = 0;
    }

    try {
      artnet.unicastDmx(targetIP, subnet, universe, dmxData);
      println("Sending DMX blackout before exit");
      delay(100); // Small delay to ensure data is sent
    }
    catch (Exception e) {
      println("Error sending final DMX: " + e.getMessage());
    }

    artnet.stop();
  }

  super.exit();
}
