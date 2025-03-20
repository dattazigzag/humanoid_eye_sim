// MediaHandler class to manage media loading and processing

class MediaHandler {
  PImage loadedImage = null;
  PImage processedImage = null;
  Movie loadedVideo = null;
  boolean isVideo = false;
  PApplet parent;
  Canvas canvas;

  MediaHandler(PApplet parent, Canvas canvas) {
    this.parent = parent;
    this.canvas = canvas;
  }

  boolean hasContent() {
    return processedImage != null;
  }

  PImage getProcessedMedia() {
    return processedImage;
  }

  void update() {
    // Process video frame if we have a video
    if (isVideo && loadedVideo != null && loadedVideo.available()) {
      loadedVideo.read();
      updateVideoFrame();
    }
  }

  void updateVideoFrame() {
    // Create a PImage from the video frame
    PImage videoFrame = createImage(loadedVideo.width, loadedVideo.height, RGB);
    loadedVideo.loadPixels();
    videoFrame.loadPixels();
    arrayCopy(loadedVideo.pixels, videoFrame.pixels);
    videoFrame.updatePixels();

    loadedImage = videoFrame;
    processMedia();
  }

  void loadMedia(String filePath) {
    String fileExt = filePath.substring(filePath.lastIndexOf(".")).toLowerCase();

    // Check if it's an image file
    if (fileExt.equals(".jpg") || fileExt.equals(".jpeg") ||
      fileExt.equals(".png") || fileExt.equals(".gif") ||
      fileExt.equals(".tiff") || fileExt.equals(".tga")) {
      loadImageFile(filePath);
    }
    // Check if it's a video file
    else if (fileExt.equals(".mp4") || fileExt.equals(".mov") ||
      fileExt.equals(".avi") || fileExt.equals(".webm")) {
      loadVideoFile(filePath);
    } else {
      log("Unsupported file format. Please drop an image or video file.");
    }
  }

  void loadImageFile(String filePath) {
    isVideo = false;
    if (loadedVideo != null) {
      loadedVideo.stop();
      loadedVideo = null;
    }
    loadedImage = loadImage(filePath);
    processMedia();
  }

  void loadVideoFile(String filePath) {
    isVideo = true;
    loadedImage = null;
    processedImage = null;

    if (loadedVideo != null) {
      loadedVideo.stop();
    }

    loadedVideo = new Movie(parent, filePath);
    loadedVideo.loop();
    log("Loaded video: " + filePath);
  }

  void clearMedia() {
    // Stop and release video if it exists
    if (loadedVideo != null) {
      loadedVideo.stop();
      loadedVideo = null;
    }

    // Clear image references
    loadedImage = null;
    processedImage = null;
    isVideo = false;

    log("Media cleared");
  }

  void processMedia() {
    if (loadedImage != null) {
      // Get the actual width and height of this canvas
      int canvasWidth = canvas.width;
      int canvasHeight = canvas.height;

      //log("Processing media for canvas with dimensions: " + canvasWidth + "x" + canvasHeight);

      // Calculate scaling factor to fit the image in the canvas
      float scaleFactor = 1.0;
      if (loadedImage.width > loadedImage.height) {
        // Width is the limiting factor
        scaleFactor = (float) canvasWidth / loadedImage.width;
      } else {
        // Height is the limiting factor
        scaleFactor = (float) canvasHeight / loadedImage.height;
      }

      // Create a new image with the scaled dimensions
      int newWidth = (int) (loadedImage.width * scaleFactor);
      int newHeight = (int) (loadedImage.height * scaleFactor);

      // Create a processed image with the canvas dimensions
      processedImage = createImage(canvasWidth, canvasHeight, RGB);
      processedImage.loadPixels();

      // Fill with black
      for (int i = 0; i < processedImage.pixels.length; i++) {
        processedImage.pixels[i] = color(0);
      }

      // Calculate the position to center the image
      int xOffset = (canvasWidth - newWidth) / 2;
      int yOffset = (canvasHeight - newHeight) / 2;

      // Copy the scaled image to the center of processedImage
      PImage scaledImage = loadedImage.copy();
      scaledImage.resize(newWidth, newHeight);

      // Copy scaled image to the processed image at the centered position
      processedImage.copy(scaledImage, 0, 0, newWidth, newHeight, xOffset, yOffset, newWidth, newHeight);

      processedImage.updatePixels();
    }
  }
}
