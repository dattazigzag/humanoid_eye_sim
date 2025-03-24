#include <Adafruit_NeoPixel.h>
#include <ArtnetWiFi.h>.  // for chips that has wifi
// #include <Artnet.h>.      // can use both WiFi and Ethernet


// LED stuff
#define LED_PIN 14    // ESP32 GPIO14 connects to LED data input
#define LED_COUNT 64  // 8x8 matrix = 64 LEDs
Adafruit_NeoPixel pixels(LED_COUNT, LED_PIN, NEO_RGB + NEO_KHZ800);


/*
63 62 61 60 59 58 57 56
55 54 53 52 51 50 49 48
47 46 45 44 43 42 41 40
39 38 37 36 35 34 33 32
31 30 29 28 27 26 25 24
23 22 21 20 19 18 17 16
15 14 13 12 11 10  9  8
7  6  5  4  3  2  1  0
*/
int xyToIndex(int x, int y) {
  return (7 - y) * 8 + (7 - x);  // Bottom to top, right to left
}


unsigned long prevWiFiBlinkMillis = 0;
bool wifiLEDState = false;

void initLEDs() {
  pixels.begin();            // Initialize NeoPixel strip
  pixels.setBrightness(20);  // Set brightness (max 255)
  pixels.clear();            // Set all pixels to 'off'
}


void showWiFiConnecting() {
  unsigned long currWiFiBlinkMillis = millis();
  if (currWiFiBlinkMillis - prevWiFiBlinkMillis >= 100) {
    prevWiFiBlinkMillis = currWiFiBlinkMillis;
    wifiLEDState = !wifiLEDState;
    if (wifiLEDState) {
      pixels.setPixelColor(xyToIndex(0, 0), pixels.Color(255, 180, 0));
      pixels.show();
    } else {
      pixels.clear();
      pixels.show();
    }
  }
}


void showWiFiConnected() {
  pixels.setPixelColor(xyToIndex(0, 0), pixels.Color(0, 255, 0));
  pixels.show();
  delay(2500);
  pixels.clear();
  pixels.show();
}

// WiFi& Artnet stuff
const char *ssid = "YOUR_WIFI_SSID";
const char *pwd = "YOUR_WIFI_PWD";

const IPAddress ip(192, 168, 1, 201); // Adjust based on your router's DNS Settings
// const IPAddress ip(192, 168, 1, 202); // Adjust based on your router's DNS Settings; **but give the send setup a diff IP

const IPAddress gateway(192, 168, 1, 1); // Adjust based on your router's DNS Settings
const IPAddress subnet_mask(255, 255, 255, 0);  // Adjust based on your router's DNS Settings

ArtnetWiFiReceiver artnet;

uint16_t universe0 = 0;  // 0 - 32767
uint8_t net = 0;         // 0 - 127
uint8_t subnet = 0;      // 0 - 15


void setup() {
  initLEDs();

  Serial.begin(115200);
  delay(2000);

  // WiFi stuff
  Serial.print("Connecting to Wifi:\t");
  Serial.println(ssid);

  WiFi.begin(ssid, pwd);
  WiFi.config(ip, gateway, subnet_mask);

  while (WiFi.status() != WL_CONNECTED) {
    showWiFiConnecting();
    Serial.print(".");
    delay(50);
  }

  showWiFiConnected();

  Serial.println("\n");
  Serial.print("WiFi connected, IP = ");
  Serial.println(WiFi.localIP());

  delay(1000);

  artnet.begin();

  // Option2
  artnet.subscribeArtDmxUniverse(universe0, [&](const uint8_t *data, uint16_t size, const ArtDmxMetadata &metadata, const ArtNetRemoteInfo &remote) {

    // // DEBUG print artnet data
    // Serial.print("lambda : artnet data from ");
    // Serial.print(remote.ip);
    // Serial.print(":");
    // Serial.print(remote.port);
    // Serial.print(", universe = ");
    // Serial.print(universe0);
    // Serial.print(", size = ");
    // Serial.print(size);
    // Serial.println();
    // print8x8Data(data);

    // Update all LEDs based on DMX data
    pixels.clear();
    for (int i = 0; i < LED_COUNT; i++) {
      // Calculate DMX data index for this LED (3 channels per LED: R,G,B)
      
      int dmxIndex = i * 3;  // For the Left Eye (1st Matrix)
      // int dmxIndex = (i * 3) + 192;  // For the Right Eye (2nd Matrix)
      
      // Get the RGB values
      uint8_t red = data[dmxIndex];
      uint8_t green = data[dmxIndex + 1];
      uint8_t blue = data[dmxIndex + 2];
      // Calculate the actual LED position in the strip
      // Based on the LED layout in your comment
      int row = i / 8;
      int col = i % 8;
      int ledPosition = (7 - row) * 8 + (7 - col);
      // Set the pixel color
      pixels.setPixelColor(ledPosition, pixels.Color(red, green, blue));
    }
    // Show the updated pixels
    pixels.show();
  });
}

void loop() {
  artnet.parse();  // check if artnet packet has come and execute callback
}
