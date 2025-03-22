// DMX Sender class
class DMXSender {
  private ArtNetClient artnet;
  private boolean useBroadcast;
  private String targetIP;
  //private int port;
  private int universe;
  private int subnet;

  DMXSender(boolean useBroadcast, String targetIP, int port, int universe, int subnet) {
    this.useBroadcast = useBroadcast;
    this.targetIP = targetIP;
    //this.port = port;
    this.universe = universe;
    this.subnet = subnet;

    // Create ArtNet client with specific ports
    artnet = new ArtNetClient(new ArtNetBuffer(), port, port);
  }

  void connect() {
    try {
      if (useBroadcast) {
        artnet.start();
        log("ArtNet started in broadcast mode");
      } else {
        InetAddress address = InetAddress.getByName(targetIP);
        artnet.start(address);
        log("ArtNet started to target IP: " + targetIP);
      }
    }
    catch (Exception e) {
      log("Error connecting to ArtNet: " + e.getMessage());
    }
  }

  void sendDMXData(byte[] data) {
    if (artnet != null) {
      try {
        // Unicast DMX with the correct method signature: IP, subnet, universe, data
        artnet.unicastDmx(targetIP, subnet, universe, data);
      }
      catch (Exception e) {
        log("Error sending DMX data: " + e.getMessage());
      }
    }
  }

  void stop() {
    if (artnet != null) {
      artnet.stop();
      log("ArtNet stopped");
    }
  }
}
