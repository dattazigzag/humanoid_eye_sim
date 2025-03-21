import codeanticode.syphon.*;

PGraphics canvas;
SyphonServer server;

void setup() { 
  size(320, 320, P3D);
  canvas = createGraphics(320, 320, P3D);
  
  // The below always makes the window stay on top of other windows
  surface.setAlwaysOnTop(true);
  
  // Create syhpon server to send frames out.
  server = new SyphonServer(this, "LeftEye");
}

void draw() {
  canvas.beginDraw();
  canvas.background(255, 0, 0);
  canvas.lights();
  canvas.translate(width/2, height/2);
  canvas.rotateX(frameCount * 0.01);
  canvas.rotateY(frameCount * 0.01);  
  canvas.box(150);
  canvas.endDraw();
  image(canvas, 0, 0);
  server.sendImage(canvas);
}
