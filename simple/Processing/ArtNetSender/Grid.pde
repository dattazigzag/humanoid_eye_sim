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
    println("Grid initialized with cell size: " + cellWidth + "x" + cellHeight + " for canvas width: " + canvas.width);
  }

  boolean isEnabled() {
    return enabled;
  }

  void toggleGrid() {
    enabled = !enabled;
    log("Grid: " + (enabled ? "Enabled" : "Disabled"));
  }

  void cyclePixelationAlgorithm() {
    currentAlgorithm = (currentAlgorithm + 1) % 4;  // Cycle through the 4 algorithms
    log("Pixelation Algorithm: " + algorithmNames[currentAlgorithm]);
  }

  void drawPixelatedGrid(PImage img, int side) {
    img.loadPixels();

    // Calculate color for each cell in the grid using the current algorithm
    // But don't send DMX data here, just return color values to be combined later
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

        // Standard left-to-right, top-to-bottom grid mapping
        int cellIndex = y * 8 + x;

        // Store RGB values in DMX data array (3 channels per cell)
        int dmxIndex;
        if (side == 0) {  // Left side
          dmxIndex = cellIndex * 3;
        } else {  // Right side
          dmxIndex = 192 + (cellIndex * 3);  // Start at channel 192 for right side
        }

        // Only update if within our range
        if (dmxIndex < 384) {  // 384 = 128 cells * 3 channels
          // Store in the global DMX array instead of sending immediately
          dmxData[dmxIndex] = (byte) (int) red(cellColor);        // R
          dmxData[dmxIndex + 1] = (byte) (int) green(cellColor);  // G
          dmxData[dmxIndex + 2] = (byte) (int) blue(cellColor);   // B
        }
      }
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
