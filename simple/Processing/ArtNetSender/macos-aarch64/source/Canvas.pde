// Canvas class to handle the main display area

class Canvas {
  int x, y, width, height;

  Canvas(int x, int y, int width, int height) {
    this.x = x;
    this.y = y;
    this.width = width;
    this.height = height;
  }

  void render() {
    // Draw the canvas background
    fill(0);
    rect(x, y, width, height);
  }
}
