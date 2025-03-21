// User Interface class to manage all controls
class UserInterface {
  PApplet parent;
  int x, y, width, height;
  ControlP5 cp5;
  Textarea console;

  // Colors
  color bgColor = color(25);
  color textColor = color(220);
  color disabledColor = color(15);
  color dimmedTextColor = color(120); // Dimmed text color for disabled fields

  // Control dimensions
  int padding = 12;
  int elementHeight = 20;
  int buttonWidth = 80;
  int rowHeight = 38;

  // Controls references
  Textfield ipField;
  Textfield portField;
  Textfield subnetField;
  Textfield universeField;
  Toggle broadcastToggle;
  Toggle gridToggle;
  Toggle dmxToggle;
  Toggle syncToggle;
  Toggle leftSyphonToggle;
  Toggle rightSyphonToggle;


  UserInterface(PApplet parent, int x, int y, int width, int height) {
    this.parent = parent;
    this.x = x;
    this.y = y;
    this.width = width;
    this.height = height;

    // Initialize ControlP5
    cp5 = new ControlP5(parent);

    // Setup controls
    setupControls();
  }

  void setupControls() {
    // Control styles
    cp5.setColorForeground(color(50));
    cp5.setColorBackground(color(50));
    cp5.setColorActive(color(57, 184, 213));

    // Create and configure console
    setupConsole();

    // Section 1: File and Grid Controls
    int currentY = y + padding;
    int currentX = x + padding;

    // File Select Buttons
    cp5.addButton("selectLeftEye")
      .setPosition(currentX, currentY)
      .setSize(buttonWidth+20, elementHeight)
      .setCaptionLabel("Select Left Eye File")
      .setColorCaptionLabel(textColor)
      .onClick(new CallbackListener() {
      public void controlEvent(CallbackEvent event) {
        selectInput("Select left eye image or video file:", "fileSelectedLeft");
      }
    }
    );

    // Sync Toggle - Positioned in the middle
    syncToggle = cp5.addToggle("syncToggle")
      .setPosition(width/2 - elementHeight/2, currentY)
      .setSize(elementHeight, elementHeight)
      .setCaptionLabel("SYNC")
      .setValue(syncEnabled)
      .setColorCaptionLabel(textColor)
      .onChange(new CallbackListener() {
      public void controlEvent(CallbackEvent event) {
        // Only toggle if both are videos
        if (bothVideos) {
          syncEnabled = event.getController().getValue() > 0;
          log("Video Sync: " + (syncEnabled ? "Enabled" : "Disabled"));
        }
      }
    }
    );

    cp5.addButton("selectRightEye")
      .setPosition((width - (buttonWidth+20))-currentX, currentY)
      .setSize(buttonWidth+20, elementHeight)
      .setCaptionLabel("Select Right Eye File")
      .setColorCaptionLabel(textColor)
      .onClick(new CallbackListener() {
      public void controlEvent(CallbackEvent event) {
        selectInput("Select right eye image or video file:", "fileSelectedRight");
      }
    }
    );

    int syphonButtonY = currentY;  // Same row as file select buttons

    // Left Syphon Toggle - position it near the left file select
    leftSyphonToggle = cp5.addToggle("leftSyphonToggle")
      .setPosition(currentX + buttonWidth + 30, syphonButtonY)
      .setSize(elementHeight, elementHeight)
      .setCaptionLabel("SYPHON")
      .setValue(leftSyphonEnabled)
      .setColorCaptionLabel(textColor)
      .onChange(new CallbackListener() {
      public void controlEvent(CallbackEvent event) {
        boolean enabled = event.getController().getValue() > 0;
        toggleLeftSyphon(enabled);
      }
    }
    );

    // Right Syphon Toggle - position it near the right file select
    rightSyphonToggle = cp5.addToggle("rightSyphonToggle")
      .setPosition(width - buttonWidth - (50+padding), syphonButtonY)
      .setSize(elementHeight, elementHeight)
      .setCaptionLabel("SYPHON")
      .setValue(rightSyphonEnabled)
      .setColorCaptionLabel(textColor)
      .onChange(new CallbackListener() {
      public void controlEvent(CallbackEvent event) {
        boolean enabled = event.getController().getValue() > 0;
        toggleRightSyphon(enabled);
      }
    }
    );

    currentY += rowHeight;

    // Grid Toggle - Moved below Select File
    gridToggle = cp5.addToggle("gridToggle")
      .setPosition(currentX, currentY)
      .setSize(elementHeight, elementHeight)
      .setCaptionLabel(leftGrid.isEnabled() ? "GRID ON" : "GRID OFF")
      .setValue(leftGrid.isEnabled())
      .setColorCaptionLabel(textColor)
      .onChange(new CallbackListener() {
      public void controlEvent(CallbackEvent event) {
        // Only toggle the grid if the UI state doesn't match the grid state
        // This prevents double-toggling when triggered by key press
        if (event.getController().getValue() != (leftGrid.isEnabled() ? 1.0 : 0.0)) {
          leftGrid.toggleGrid();
          rightGrid.toggleGrid();
        }
        // Update caption based on state
        event.getController().setCaptionLabel(leftGrid.isEnabled() ? "GRID ON" : "GRID OFF");
      }
    }
    );

    // Add divider line before ArtNet settings
    currentY += rowHeight + padding;

    // Section Header: ArtNet Settings
    cp5.addTextlabel("artnetLabel")
      .setText("ARTNET DMX SETTINGS")
      .setPosition(currentX - 5, currentY)
      .setColor(textColor);

    currentY += rowHeight - 18;

    // Broadcast/Target IP Toggle
    broadcastToggle = cp5.addToggle("broadcastToggle")
      .setPosition(currentX, currentY)
      .setSize(elementHeight, elementHeight)
      .setCaptionLabel("BROADCAST")
      .setState(useBroadcast)
      .setColorCaptionLabel(textColor)
      .onChange(new CallbackListener() {
      public void controlEvent(CallbackEvent event) {
        useBroadcast = event.getController().getValue() > 0;
        updateIPField();
      }
    }
    );

    // IP Address Field
    ipField = cp5.addTextfield("ipField")
      .setPosition(currentX + elementHeight*2 + padding + 10, currentY)
      .setSize(100, elementHeight)
      .setCaptionLabel("TARGET IP")
      .setText(targetIP)
      .setColor(useBroadcast ? dimmedTextColor : textColor) // Dimmed text when disabled
      .setColorBackground(useBroadcast ? disabledColor : color(60))
      .setLock(useBroadcast);

    // Port field, positioned relative to IP field
    portField = cp5.addTextfield("portField")
      .setPosition(ipField.getPosition()[0] + ipField.getWidth() + padding*2, currentY)
      .setSize(50, elementHeight)
      .setCaptionLabel("PORT")
      .setText(str(artNetPort))
      .setColor(textColor)
      .setInputFilter(ControlP5.INTEGER);

    currentY += rowHeight + padding;

    // Subnet field
    subnetField = cp5.addTextfield("subnetField")
      .setPosition(currentX, currentY-5)
      .setSize(30, elementHeight)
      .setCaptionLabel("SUBNET")
      .setText(str(subnet))
      .setColor(textColor)
      .setInputFilter(ControlP5.INTEGER);

    // Universe field, positioned relative to subnet field
    universeField = cp5.addTextfield("universeField")
      .setPosition(subnetField.getPosition()[0] + subnetField.getWidth() + padding*3, currentY-5)
      .setSize(30, elementHeight)
      .setCaptionLabel("UNIVERSE")
      .setText(str(universe))
      .setColor(textColor)
      .setInputFilter(ControlP5.INTEGER);

    // Single DMX Toggle that changes label based on state
    dmxToggle = cp5.addToggle("dmxToggle")
      .setPosition(universeField.getPosition()[0] + universeField.getWidth() + padding*3, currentY-5)
      .setSize(elementHeight, elementHeight)
      .setCaptionLabel(enableDMX ? "STOP DMX" : "START DMX")
      .setValue(enableDMX)
      .setColorCaptionLabel(textColor)
      .onChange(new CallbackListener() {
      public void controlEvent(CallbackEvent event) {
        boolean isEnabled = event.getController().getValue() > 0;
        if (isEnabled) {
          startDMX();
          event.getController().setCaptionLabel("STOP DMX");
        } else {
          stopDMX();
          event.getController().setCaptionLabel("START DMX");
        }
      }
    }
    );

    // algo selector (Dropdown List)
    DropdownList algorithmList = cp5.addDropdownList("algorithmDropdown")
      .setPosition(currentX + elementHeight + padding*2, gridToggle.getPosition()[1])
      .setSize(120, 120) // Make it taller to show options
      .setItemHeight(20)
      .setBarHeight(elementHeight)
      .setColorBackground(color(60))
      .setColorActive(color(57, 184, 213))
      .setColorForeground(color(100))
      .bringToFront();

    // Position the caption label below the control
    algorithmList.getCaptionLabel()
      .align(ControlP5.LEFT, ControlP5.BOTTOM_OUTSIDE)
      .setPaddingY(5)
      .setText("PIXELATION ALGORITHM");

    // Add items to the dropdown
    for (int i = 0; i < leftGrid.algorithmNames.length; i++) {
      algorithmList.addItem(leftGrid.algorithmNames[i], i);
    }

    // Set the current value to Average Color (0) by default
    algorithmList.setValue(0);
    // Ensure it's closed by default
    algorithmList.close();

    // Add event listener
    algorithmList.addCallback(new CallbackListener() {
      public void controlEvent(CallbackEvent event) {
        if (event.getAction() == ControlP5.ACTION_BROADCAST) {
          int algoIndex = (int)algorithmList.getValue();
          // Update both grids
          while (leftGrid.currentAlgorithm != algoIndex) {
            leftGrid.cyclePixelationAlgorithm();
            rightGrid.cyclePixelationAlgorithm();
          }
        }
      }
    }
    );
  }


  void render() {
    // Draw the background for the UI area
    fill(bgColor);
    rect(x, y, width, height);

    // Draw divider line before ArtNet settings
    stroke(textColor, 100); // Semi-transparent color
    strokeWeight(0.25);
    line(x, y + padding + rowHeight*2, x + width, y + padding + rowHeight*2);
    noStroke();
  }

  void updateIPField() {
    if (useBroadcast) {
      ipField.setText("255.255.255.255");
      ipField.setLock(true);
      ipField.setColorBackground(disabledColor);
      ipField.setColor(dimmedTextColor); // Dim the text when disabled
    } else {
      ipField.setLock(false);
      ipField.setColorBackground(color(60));
      ipField.setColor(textColor); // Normal text color when enabled
    }
  }

  void startDMX() {
    // Get values from UI
    artNetPort = parseInt(portField.getText());
    subnet = parseInt(subnetField.getText());
    universe = parseInt(universeField.getText());
    targetIP = ipField.getText();

    // Create new DMX sender with updated values
    if (dmxSender != null) {
      dmxSender.stop();
    }

    dmxSender = new DMXSender(useBroadcast, targetIP, artNetPort, universe, subnet);
    dmxSender.connect();
    enableDMX = true;

    String dmxSettings = "DMX started with settings: " +
      "IP=" + targetIP + ", " +
      "Port=" + artNetPort + ", " +
      "Subnet=" + subnet + ", " +
      "Universe=" + universe;

    log(dmxSettings);
  }

  void stopDMX() {
    if (dmxSender != null) {
      // Reset global DMX data array to all zeros (black)
      for (int i = 0; i < dmxData.length; i++) {
        dmxData[i] = 0;
      }

      // Send the blackout data
      log("Sending DMX blackout");
      dmxSender.sendDMXData(dmxData);

      // Small delay to ensure data is sent
      delay(100);

      dmxSender.stop();
      enableDMX = false;
      log("DMX stopped");
    }
  }

  void updateLeftSyphonState(boolean enabled) {
    // Lock/unlock the left file select button based on Syphon state
    cp5.getController("selectLeftEye").setLock(enabled);
    // Update the appearance of the button when locked
    if (enabled) {
      cp5.getController("selectLeftEye").setColorBackground(disabledColor);
    } else {
      cp5.getController("selectLeftEye").setColorBackground(color(50));
    }
  }

  void updateRightSyphonState(boolean enabled) {
    // Lock/unlock the right file select button based on Syphon state
    cp5.getController("selectRightEye").setLock(enabled);
    // Update the appearance of the button when locked
    if (enabled) {
      cp5.getController("selectRightEye").setColorBackground(disabledColor);
    } else {
      cp5.getController("selectRightEye").setColorBackground(color(50));
    }
  }

  //---------//
  void setupConsole() {
    // Create console in the highlighted area
    int consoleX = width / 2 - 10;  // Right side of UI
    int consoleY = y + padding + rowHeight*2 + 35;  // Below ARTNET DMX SETTINGS label
    int consoleWidth = width / 2 - padding+10;
    int consoleHeight = 100;  // Adjust as needed to fit the area

    // Create a textarea to serve as console
    console = cp5.addTextarea("console")
      .setPosition(consoleX, consoleY)
      .setSize(consoleWidth, consoleHeight)
      //.setFont(createFont("", 10))
      .setLineHeight(14)
      .setColor(color(100))  // Text color
      //.setColorBackground(color(150, 50))    // Same as UI background
      .setColorForeground(color(255, 50))  // Scroll bar color - semi-transparent magenta
      .scroll(1.0)                    // Enable scrolling
      .showScrollbar();               // Show scrollbar

    // Add a thin magenta border - ControlP5 Textarea doesn't support borders directly,
    // but we can use styling to make it look like it has one
    console.getCaptionLabel().setText("");  // No caption text

    // Set console as global reference
    appConsole = console;

    // Welcome message
    console.clear();
    printToConsole("ArtNet DMX Console initialized");
    printToConsole("-------------------------------");
  }

  void printToConsole(String message) {
    // Get current hour:minute:second
    //String timestamp = nf(hour(), 2) + ":" + nf(minute(), 2) + ":" + nf(second(), 2);
    //String formattedMessage = "[" + timestamp + "] " + message + "\n";

    // Append to textarea
    //console.append(formattedMessage);

    String formattedMessage = message + "\n";
    console.append(formattedMessage);

    // Scroll to bottom - this ensures newest messages are visible
    console.scroll(1.0);

    // Auto-clear if buffer exceeds limit
    if (countLines(console.getText()) > CONSOLE_BUFFER_LIMIT) {
      console.clear();
      //console.append("[" + timestamp + "] Console buffer limit reached. Cleared.\n");
      console.append("Console buffer limit reached. Cleared.\n");
    }
  }

  int countLines(String text) {
    if (text == null || text.isEmpty()) return 0;
    return text.split("\n").length;
  }
}
