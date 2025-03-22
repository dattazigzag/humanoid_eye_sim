// MediaHandler class to manage media loading and processing
class MediaHandler {
  PImage loadedImage = null;
  PImage processedImage = null;
  Movie loadedVideo = null;

  boolean isVideo = false;
  boolean isSyphon = false;

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

      // For P3D compatibility - make sure movie is continually handled
      if (enableP3D) {
        loadedVideo.loadPixels();
      }

      updateVideoFrame();
    }
  }

  void updateVideoFrame() {
    if (loadedVideo == null) return;

    // Create or reuse a PImage for the current frame
    if (loadedImage == null || loadedImage.width != loadedVideo.width || loadedImage.height != loadedVideo.height) {
      loadedImage = createImage(loadedVideo.width, loadedVideo.height, RGB);
    }

    // Copy the video frame data
    loadedVideo.loadPixels();
    loadedImage.loadPixels();

    // Use System.arrayCopy for efficiency when possible
    if (loadedVideo.pixels.length == loadedImage.pixels.length) {
      System.arraycopy(loadedVideo.pixels, 0, loadedImage.pixels, 0, loadedVideo.pixels.length);
    } else {
      // Fall back to manual copying if sizes differ
      int minLength = min(loadedVideo.pixels.length, loadedImage.pixels.length);
      for (int i = 0; i < minLength; i++) {
        loadedImage.pixels[i] = loadedVideo.pixels[i];
      }
    }

    loadedImage.updatePixels();

    // Process the media to fit the canvas
    processMedia();
  }

  void updateSyphonFrame(PGraphics syphonCanvas) {
    if (syphonCanvas == null) return;

    // Set the flags indicating we're using Syphon
    isSyphon = true;
    isVideo = false;

    // Make sure syphon canvas pixels are loaded
    syphonCanvas.loadPixels();

    // Create or resize loadedImage if needed
    if (loadedImage == null || loadedImage.width != syphonCanvas.width ||
      loadedImage.height != syphonCanvas.height) {
      loadedImage = createImage(syphonCanvas.width, syphonCanvas.height, RGB);
    }

    // Copy pixels from the Syphon canvas to our image with fast array copy
    loadedImage.loadPixels();

    try {
      // Attempt to use fast System.arrayCopy when possible
      if (syphonCanvas.pixels.length == loadedImage.pixels.length) {
        System.arraycopy(syphonCanvas.pixels, 0, loadedImage.pixels, 0, syphonCanvas.pixels.length);
      } else {
        // Fall back to manual copying if sizes differ
        log("Warning: Syphon canvas and image have different pixel array lengths");
        int minLength = min(syphonCanvas.pixels.length, loadedImage.pixels.length);
        for (int i = 0; i < minLength; i++) {
          loadedImage.pixels[i] = syphonCanvas.pixels[i];
        }
      }
    }
    catch (Exception e) {
      log("Error copying Syphon pixels: " + e.getMessage());
    }

    loadedImage.updatePixels();

    // Process the image same way as for files
    processMedia();
  }

  // Method to enable/disable Syphon mode
  void setSyphonMode(boolean enabled) {
    // Clear current media
    if (loadedVideo != null) {
      loadedVideo.stop();
      loadedVideo = null;
    }

    isSyphon = enabled;

    if (enabled) {
      // When enabling Syphon, create a blank image initially
      if (processedImage == null) {
        processedImage = createImage(canvas.width, canvas.height, RGB);
        processedImage.loadPixels();
        for (int i = 0; i < processedImage.pixels.length; i++) {
          processedImage.pixels[i] = color(0);
        }
        processedImage.updatePixels();
      }
    } else {
      // When disabling Syphon, clear the images
      loadedImage = null;
      processedImage = null;
    }
  }

  void loadMedia(String filePath) {
    if (filePath == null || filePath.isEmpty()) {
      log("Error: Invalid file path");
      return;
    }

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
    isSyphon = false;

    // Stop any existing video
    if (loadedVideo != null) {
      loadedVideo.stop();
      loadedVideo = null;
    }

    try {
      loadedImage = loadImage(filePath);
      if (loadedImage == null) {
        throw new Exception("Failed to load image");
      }
      processMedia();
      log("Loaded image: " + filePath);
    }
    catch (Exception e) {
      log("Error loading image: " + e.getMessage());
    }
  }

  void loadVideoFile(String filePath) {
    isVideo = true;
    isSyphon = false;

    // Stop any existing video
    if (loadedVideo != null) {
      loadedVideo.stop();
    }

    // Clear existing images
    loadedImage = null;
    processedImage = null;

    // Load the new video
    try {
      loadedVideo = new Movie(parent, filePath);
      loadedVideo.loop();
      log("Loaded video: " + filePath + (enableP3D ? " with P3D renderer" : ""));
    }
    catch (Exception e) {
      log("Error loading video: " + e.getMessage());
      isVideo = false;
    }
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
    isSyphon = false;

    log("Media cleared");
  }

  void processMedia() {
    if (loadedImage != null) {
      // Get the actual width and height of this canvas
      int canvasWidth = canvas.width;
      int canvasHeight = canvas.height;

      // Calculate scaling factor to fit the image in the canvas
      float scaleFactor = 1.0;
      if (loadedImage.width > loadedImage.height) {
        // Width is the limiting factor
        scaleFactor = (float) canvasWidth / loadedImage.width;
      } else {
        // Height is the limiting factor
        scaleFactor = (float) canvasHeight / loadedImage.height;
      }

      // Calculate the new dimensions
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
