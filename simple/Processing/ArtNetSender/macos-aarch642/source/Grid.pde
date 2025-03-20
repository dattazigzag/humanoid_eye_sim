// Grid class to handle the grid display and pixelation
class Grid {
  int cols, rows;
  int cellWidth, cellHeight;
  boolean enabled = false;
  Canvas canvas;

  // Pixelation algorithm options
  final int ALGO_AVERAGE = 0;
  final int ALGO_NEAREST = 1;
  final int ALGO_THRESHOLD = 2;
  final int ALGO_QUANTIZED = 3;
  int currentAlgorithm = ALGO_AVERAGE;
  String[] algorithmNames = {"Average Color", "Nearest Neighbor", "Threshold", "Color Quantized"};

  Grid(int cols, int rows, Canvas canvas) {
    this.cols = cols;
    this.rows = rows;
    this.canvas = canvas;
    this.cellWidth = canvas.width / cols;
    this.cellHeight = canvas.height / rows;
  }

  boolean isEnabled() {
    return enabled;
  }

  void toggleGrid() {
    enabled = !enabled;
    println("Grid: " + (enabled ? "Enabled" : "Disabled"));
  }

  void cyclePixelationAlgorithm() {
    currentAlgorithm = (currentAlgorithm + 1) % 4;  // Cycle through the 4 algorithms
    println("Pixelation Algorithm: " + algorithmNames[currentAlgorithm]);
  }

  void drawPixelatedGrid(PImage img) {
    img.loadPixels();

    // Create an array for our DMX data (64 RGB values = 192 channels)
    // byte[] dmxData = new byte[cols * rows * 3];  // RGB values for each cell

    // Create a full DMX universe array (always 512 channels for DMX512 standard)
    byte[] dmxData = new byte[512];  // Initialize all channels to 0

    // Calculate color for each cell in the grid using the current algorithm
    for (int y = 0; y < rows; y++) {
      for (int x = 0; x < cols; x++) {
        int startX = x * cellWidth + canvas.x;
        int startY = y * cellHeight + canvas.y;

        // Apply the selected algorithm
        color cellColor;
        switch (currentAlgorithm) {
        case ALGO_AVERAGE:
          cellColor = calculateAverageColor(img, x * cellWidth, y * cellHeight, cellWidth, cellHeight);
          break;
        case ALGO_NEAREST:
          cellColor = getNearestNeighborColor(img, x * cellWidth, y * cellHeight, cellWidth, cellHeight);
          break;
        case ALGO_THRESHOLD:
          cellColor = getThresholdColor(img, x * cellWidth, y * cellHeight, cellWidth, cellHeight);
          break;
        case ALGO_QUANTIZED:
          cellColor = getQuantizedColor(img, x * cellWidth, y * cellHeight, cellWidth, cellHeight);
          break;
        default:
          cellColor = calculateAverageColor(img, x * cellWidth, y * cellHeight, cellWidth, cellHeight);
        }

        // Draw the cell with the calculated color
        fill(cellColor);
        noStroke();
        rect(startX, startY, cellWidth, cellHeight);

        // Draw grid lines
        stroke(50);
        noFill();
        rect(startX, startY, cellWidth, cellHeight);

        // Determine the DMX channel for this cell based on the provided mapping
        // Mapping style: 1
        // From bottom-left (0) to top-right (63) as shown in the mapping
        /*
         63 62 61 60 59 58 57 56
         55 54 53 52 51 50 49 48
         47 46 45 44 43 42 41 40
         39 38 37 36 35 34 33 32
         31 30 29 28 27 26 25 24
         23 22 21 20 19 18 17 16
         15 14 13 12 11 10  9  8
         7  6  5  4  3  2  1  0
         */
        //int cellIndex = ((7-y) * 8) + x;  // Convert from our grid coords to specified mapping

        // Mapping Style: 2
        // From top-left (0) to bottom-right (63)
        /*
         0  1  2  3  4  5  6  7
         8  9 10 11 12 13 14 15
         16 17 18 19 20 21 22 23
         24 25 26 27 28 29 30 31
         32 33 34 35 36 37 38 39
         40 41 42 43 44 45 46 47
         48 49 50 51 52 53 54 55
         56 57 58 59 60 61 62 63
         */
        int cellIndex = y * 8 + x;  // Standard left-to-right, top-to-bottom grid

        // Store RGB values in DMX data array (3 channels per cell)
        // We'll use the first 192 channels of the 512 DMX channels
        int dmxIndex = cellIndex * 3;
        dmxData[dmxIndex] = (byte) (int) red(cellColor);        // R
        dmxData[dmxIndex + 1] = (byte) (int) green(cellColor);  // G
        dmxData[dmxIndex + 2] = (byte) (int) blue(cellColor);   // B
      }
    }

    // Send the DMX data if enabled
    if (enableDMX && dmxSender != null) {
      dmxSender.sendDMXData(dmxData);
    }
  }

  // 1. AVERAGE - Function to calculate average color in a region (original algorithm)
  color calculateAverageColor(PImage img, int startX, int startY, int w, int h) {
    float r = 0, g = 0, b = 0;
    int count = 0;

    // Get the average color of all pixels in the cell
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

  // 2. NEAREST NEIGHBOR - Get color from center of cell
  color getNearestNeighborColor(PImage img, int startX, int startY, int w, int h) {
    // Calculate center of cell
    int centerX = startX + w/2;
    int centerY = startY + h/2;

    // Make sure we're within bounds
    centerX = constrain(centerX, 0, img.width-1);
    centerY = constrain(centerY, 0, img.height-1);

    // Get color at center
    return img.pixels[centerY * img.width + centerX];
  }

  // 3. THRESHOLD - Black and white based on brightness threshold
  color getThresholdColor(PImage img, int startX, int startY, int w, int h) {
    // First get the average color (reusing existing method)
    color avgColor = calculateAverageColor(img, startX, startY, w, h);

    // Calculate brightness (0-255)
    float brightness = (red(avgColor) + green(avgColor) + blue(avgColor)) / 3;

    // Return black or white based on threshold (128 is middle value)
    return brightness < 128 ? color(0) : color(255);
  }

  // 4. COLOR QUANTIZED - Reduce to limited palette
  color getQuantizedColor(PImage img, int startX, int startY, int w, int h) {
    // Get average color first
    color avgColor = calculateAverageColor(img, startX, startY, w, h);

    // Extract RGB components
    float r = red(avgColor);
    float g = green(avgColor);
    float b = blue(avgColor);

    // Quantize each component to 4 levels (0, 85, 170, 255)
    r = round(r / 85) * 85;
    g = round(g / 85) * 85;
    b = round(b / 85) * 85;

    return color(r, g, b);
  }
}
