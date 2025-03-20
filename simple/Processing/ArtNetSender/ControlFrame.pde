// ControlFrame class to create a separate Ctrl UI window
class ControlFrame extends PApplet {
  private int w;
  private int h;
  private PApplet parent;
  private ControlP5 cp5;
  private String name;

  // Colors and dimensions
  color bgColor = color(30);
  color textColor = color(220);
  color disabledColor = color(15);
  color dimmedTextColor = color(120);
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
  DropdownList algorithmList;

  public ControlFrame(PApplet _parent, int _w, int _h, String _name) {
    super();
    this.parent = _parent;
    this.w = _w;
    this.h = _h;
    this.name = _name;
    PApplet.runSketch(new String[]{this.getClass().getName()}, this);
  }

  public void settings() {
    size(w, h);
  }

  public void setup() {
    surface.setLocation(10+320*2, 400); // Position below the main window
    surface.setTitle(name);

    cp5 = new ControlP5(this);
    setupControls();
  }

  // Accessor methods to interact with the parent ArtNetSender
  boolean getGridEnabled() {
    return ((ArtNetSender)parent).grid.isEnabled();
  }

  void toggleGrid() {
    ((ArtNetSender)parent).grid.toggleGrid();
  }

  int getCurrentAlgorithm() {
    return ((ArtNetSender)parent).grid.currentAlgorithm;
  }

  void cycleAlgorithm() {
    ((ArtNetSender)parent).grid.cyclePixelationAlgorithm();
  }

  String[] getAlgorithmNames() {
    return ((ArtNetSender)parent).grid.algorithmNames;
  }

  boolean getBroadcastMode() {
    return ((ArtNetSender)parent).useBroadcast;
  }

  void setBroadcastMode(boolean value) {
    ((ArtNetSender)parent).useBroadcast = value;
  }

  String getTargetIP() {
    return ((ArtNetSender)parent).targetIP;
  }

  void setTargetIP(String ip) {
    ((ArtNetSender)parent).targetIP = ip;
  }

  int getArtNetPort() {
    return ((ArtNetSender)parent).artNetPort;
  }

  void setArtNetPort(int port) {
    ((ArtNetSender)parent).artNetPort = port;
  }

  int getSubnet() {
    return ((ArtNetSender)parent).subnet;
  }

  void setSubnet(int subnet) {
    ((ArtNetSender)parent).subnet = subnet;
  }

  int getUniverse() {
    return ((ArtNetSender)parent).universe;
  }

  void setUniverse(int universe) {
    ((ArtNetSender)parent).universe = universe;
  }

  boolean getDMXEnabled() {
    return ((ArtNetSender)parent).enableDMX;
  }

  void setDMXEnabled(boolean value) {
    ((ArtNetSender)parent).enableDMX = value;
  }

  DMXSender getDMXSender() {
    return ((ArtNetSender)parent).dmxSender;
  }

  void selectMediaFile() {
    ((ArtNetSender)parent).selectInput("Select an image or video file:", "fileSelected");
  }

  void setupControls() {
    // Control styles
    cp5.setColorForeground(color(50));
    cp5.setColorBackground(color(50));
    cp5.setColorActive(color(57, 184, 213));

    // Section 1: File and Grid Controls
    int currentY = padding;
    int currentX = padding;

    // File Select Button
    cp5.addButton("selectFile")
      .setPosition(currentX, currentY)
      .setSize(buttonWidth, elementHeight)
      .setCaptionLabel("Select File")
      .setColorCaptionLabel(textColor)
      .onClick(new CallbackListener() {
      public void controlEvent(CallbackEvent event) {
        selectMediaFile();
      }
    }
    );

    currentY += rowHeight;

    // Grid Toggle
    gridToggle = cp5.addToggle("gridToggle")
      .setPosition(currentX, currentY)
      .setSize(elementHeight, elementHeight)
      .setCaptionLabel(getGridEnabled() ? "GRID ON" : "GRID OFF")
      .setValue(getGridEnabled())
      .setColorCaptionLabel(textColor)
      .onChange(new CallbackListener() {
      public void controlEvent(CallbackEvent event) {
        toggleGrid();
        event.getController().setCaptionLabel(getGridEnabled() ? "GRID ON" : "GRID OFF");
      }
    }
    );

    // Algorithm selector (Dropdown List)
    algorithmList = cp5.addDropdownList("algorithmDropdown")
      .setPosition(currentX + elementHeight + padding*2, gridToggle.getPosition()[1])
      .setSize(w - (currentX + elementHeight + padding*3), 120)
      .setItemHeight(20)
      .setBarHeight(elementHeight)
      .setColorBackground(color(60))
      .setColorActive(color(57, 184, 213))
      .setColorForeground(color(100));

    algorithmList.getCaptionLabel()
      .align(ControlP5.LEFT, ControlP5.BOTTOM_OUTSIDE)
      .setPaddingY(5)
      .setText("PIXELATION ALGORITHM");

    // Add items to the dropdown
    String[] algoNames = getAlgorithmNames();
    for (int i = 0; i < algoNames.length; i++) {
      algorithmList.addItem(algoNames[i], i);
    }

    algorithmList.setValue(getCurrentAlgorithm());
    algorithmList.close();

    // Add event listener
    algorithmList.addCallback(new CallbackListener() {
      public void controlEvent(CallbackEvent event) {
        if (event.getAction() == ControlP5.ACTION_BROADCAST) {
          int algoIndex = (int)algorithmList.getValue();
          while (getCurrentAlgorithm() != algoIndex) {
            cycleAlgorithm();
          }
        }
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
      .setState(getBroadcastMode())
      .setColorCaptionLabel(textColor)
      .onChange(new CallbackListener() {
      public void controlEvent(CallbackEvent event) {
        setBroadcastMode(event.getController().getValue() > 0);
        updateIPField();
      }
    }
    );

    // IP Address Field
    ipField = cp5.addTextfield("ipField")
      .setPosition(currentX + elementHeight*2 + padding + 10, currentY)
      .setSize(100, elementHeight)
      .setCaptionLabel("TARGET IP")
      .setText(getTargetIP())
      .setColor(getBroadcastMode() ? dimmedTextColor : textColor)
      .setColorBackground(getBroadcastMode() ? disabledColor : color(60))
      .setLock(getBroadcastMode());

    // Port field, positioned relative to IP field
    portField = cp5.addTextfield("portField")
      .setPosition(ipField.getPosition()[0] + ipField.getWidth() + padding*2, currentY)
      .setSize(50, elementHeight)
      .setCaptionLabel("PORT")
      .setText(str(getArtNetPort()))
      .setColor(textColor)
      .setInputFilter(ControlP5.INTEGER);

    currentY += rowHeight + padding;

    // Subnet field
    subnetField = cp5.addTextfield("subnetField")
      .setPosition(currentX, currentY-5)
      .setSize(30, elementHeight)
      .setCaptionLabel("SUBNET")
      .setText(str(getSubnet()))
      .setColor(textColor)
      .setInputFilter(ControlP5.INTEGER);

    // Universe field, positioned relative to subnet field
    universeField = cp5.addTextfield("universeField")
      .setPosition(subnetField.getPosition()[0] + subnetField.getWidth() + padding*3, currentY-5)
      .setSize(30, elementHeight)
      .setCaptionLabel("UNIVERSE")
      .setText(str(getUniverse()))
      .setColor(textColor)
      .setInputFilter(ControlP5.INTEGER);

    // DMX Toggle
    dmxToggle = cp5.addToggle("dmxToggle")
      .setPosition(universeField.getPosition()[0] + universeField.getWidth() + padding*3, currentY-5)
      .setSize(elementHeight, elementHeight)
      .setCaptionLabel(getDMXEnabled() ? "STOP DMX" : "START DMX")
      .setValue(getDMXEnabled())
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
  }

  void updateIPField() {
    if (getBroadcastMode()) {
      ipField.setText("255.255.255.255");
      ipField.setLock(true);
      ipField.setColorBackground(disabledColor);
      ipField.setColor(dimmedTextColor);
    } else {
      ipField.setLock(false);
      ipField.setColorBackground(color(60));
      ipField.setColor(textColor);
    }
  }

  void startDMX() {
    // Get values from UI
    setArtNetPort(parseInt(portField.getText()));
    setSubnet(parseInt(subnetField.getText()));
    setUniverse(parseInt(universeField.getText()));
    setTargetIP(ipField.getText());

    // Start DMX in the main sketch
    ArtNetSender mainSketch = (ArtNetSender)parent;

    // Stop existing DMX sender if it exists
    if (mainSketch.dmxSender != null) {
      mainSketch.dmxSender.stop();
    }

    // Create new DMX sender with updated values
    mainSketch.dmxSender = new DMXSender(getBroadcastMode(), getTargetIP(), getArtNetPort(), getUniverse(), getSubnet());
    mainSketch.dmxSender.connect();
    setDMXEnabled(true);

    println("DMX started with settings: " +
      "IP=" + getTargetIP() + ", " +
      "Port=" + getArtNetPort() + ", " +
      "Subnet=" + getSubnet() + ", " +
      "Universe=" + getUniverse());
  }

  void stopDMX() {
    ArtNetSender mainSketch = (ArtNetSender)parent;

    if (mainSketch.dmxSender != null) {
      // Create all-zero (black) DMX data
      byte[] blackoutData = new byte[512];

      // Send the blackout data
      println("Sending DMX blackout");
      mainSketch.dmxSender.sendDMXData(blackoutData);

      // Small delay to ensure data is sent
      delay(100);

      mainSketch.dmxSender.stop();
      setDMXEnabled(false);
      println("DMX stopped");
    }
  }

  public void draw() {
    background(bgColor);

    // Draw divider line before ArtNet settings
    stroke(textColor, 100);
    strokeWeight(0.25);
    line(0, padding + rowHeight*2, width, padding + rowHeight*2);
    noStroke();
  }
}
