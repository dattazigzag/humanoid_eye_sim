// Canvas class to handle the main display area

class Canvas {
  int x, y, width, height;

  Canvas(int x, int y, int width, int height) {
    this.x = x;
    this.y = y;
    this.width = width;
    this.height = height;
    println("Created canvas at (" + x + "," + y + ") with size " + width + "x" + height);
  }

  void render() {
    // Draw the canvas background
    noStroke();
    fill(0);
    rect(x, y, width, height);
  }
}
