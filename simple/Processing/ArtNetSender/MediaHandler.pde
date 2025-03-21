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
    if (!enableP3D) {
      // Create a PImage from the video frame
      PImage videoFrame = createImage(loadedVideo.width, loadedVideo.height, RGB);
      loadedVideo.loadPixels();
      videoFrame.loadPixels();
      arrayCopy(loadedVideo.pixels, videoFrame.pixels);
      videoFrame.updatePixels();
      loadedImage = videoFrame;
    } else {
      // Modify the updateVideoFrame() method in MediaHandler class for P3D compatibility
      // Create a PImage from the video frame
      if (loadedImage == null || loadedImage.width != loadedVideo.width || loadedImage.height != loadedVideo.height) {
        loadedImage = createImage(loadedVideo.width, loadedVideo.height, RGB);
      }
      loadedImage.loadPixels();
      arrayCopy(loadedVideo.pixels, loadedImage.pixels);
      loadedImage.updatePixels();
    }
    // Process the media to fit the canvas
    processMedia();
  }

  void updateSyphonFrame(PGraphics syphonCanvas) {
    if (syphonCanvas != null) {
      // Set the flag indicating we're using Syphon
      isSyphon = true;
      isVideo = false;

      // Make sure syphon canvas pixels are loaded
      syphonCanvas.loadPixels();

      // Convert PGraphics to PImage for compatibility with existing code
      if (loadedImage == null || loadedImage.width != syphonCanvas.width ||
        loadedImage.height != syphonCanvas.height) {
        loadedImage = createImage(syphonCanvas.width, syphonCanvas.height, RGB);
      }

      // Copy pixels from the Syphon canvas to our image
      loadedImage.loadPixels();

      // Safety check for arrays of the same length
      if (syphonCanvas.pixels.length == loadedImage.pixels.length) {
        arrayCopy(syphonCanvas.pixels, loadedImage.pixels);
      } else {
        log("Warning: Syphon canvas and image have different pixel array lengths");
        // Copy manually if lengths differ
        int minLength = min(syphonCanvas.pixels.length, loadedImage.pixels.length);
        for (int i = 0; i < minLength; i++) {
          loadedImage.pixels[i] = syphonCanvas.pixels[i];
        }
      }

      loadedImage.updatePixels();

      // Process the image same way as for files
      processMedia();
    }
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
      // When enabling Syphon, make sure we indicate there's content
      // by creating a blank image initially
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

  // Modify the loadVideoFile() method for better P3D compatibility
  void loadVideoFile(String filePath) {
    isVideo = true;

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
