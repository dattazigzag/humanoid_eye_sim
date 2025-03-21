import codeanticode.syphon.*;

// Separate canvases for each source
PGraphics canvasRed;
PGraphics canvasGreen;
PGraphics displayCanvas;

SyphonClient client_red;
SyphonClient client_green;

int SIZE_TOTAL_WIDTH = 640;
int SIZE_TOTAL_HEIGHT = 320;
int SIZE_CANVAS_WIDTH = 320;   // SIZE_TOTAL_WIDTH/2
int SIZE_CANVAS_HEIGHT = 320;  // Same as the cloient heights and the main window height

void settings() {
  size(SIZE_TOTAL_WIDTH, SIZE_TOTAL_HEIGHT, P3D);
}

void setup() {

  frameRate(60); // Try to match source framerates

  // The below always makes the window stay on top of other windows
  surface.setAlwaysOnTop(true);

  // Create separate canvases for each source
  canvasRed = createGraphics(SIZE_CANVAS_WIDTH, SIZE_TOTAL_HEIGHT, P3D);
  canvasGreen = createGraphics(SIZE_CANVAS_WIDTH, SIZE_TOTAL_HEIGHT, P3D);
  displayCanvas = createGraphics(SIZE_TOTAL_WIDTH, SIZE_TOTAL_HEIGHT, P3D);

  // Create Syphon clients
  client_red = new SyphonClient(this, "", "LeftEye");
  client_green = new SyphonClient(this, "", "RightEye");

  background(0);
}

void draw() {
  background(0);

  // Update the red canvas if there's a new frame
  if (client_red.newFrame()) {
    client_red.getImage(canvasRed);
  }

  // Update the green canvas if there's a new frame
  if (client_green.newFrame()) {
    client_green.getImage(canvasGreen);
  }

  // Draw to the display canvas
  displayCanvas.beginDraw();
  displayCanvas.background(0);

  // Draw the red image on the left side
  displayCanvas.image(canvasRed, 0, 0);

  // Draw the green image on the right side
  displayCanvas.image(canvasGreen, SIZE_TOTAL_WIDTH/2, 0);

  displayCanvas.endDraw();

  // Display the final canvas
  image(displayCanvas, 0, 0);

  // Show framerate for debugging
  fill(255);
  text("FPS: " + nf(frameRate, 0, 1), 10, 20);
}

void keyPressed() {
  if (key == ' ') {
    client_red.stop();
    client_green.stop();
  } else if (key == 'l') {
    println("Available Syphon servers:");
    println(SyphonClient.listServers());
    SyphonClient.
  }
}
