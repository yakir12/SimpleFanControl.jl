#include <PWM.h>
#include <PacketSerial.h> // for the COBS

PacketSerial myPacketSerial;

int pwmPin = 3;
int tachPin = 2;
unsigned long v;
uint8_t t[4];

void setup()
{
  myPacketSerial.begin(115200);
  myPacketSerial.setPacketHandler(&onPacketReceived);

  InitTimersSafe();
  bool success = SetPinFrequencySafe(pwmPin, 25000);
  if (success) {
//    pinMode(tachPin, OUTPUT);
    digitalWrite(tachPin, HIGH);
  }
  delay(100);
  pwmWrite(pwmPin, 0);

}

void loop()
{
  myPacketSerial.update();

  v = pulseIn(tachPin, HIGH, 100000);
  t[0] = v >> 24;
  t[1] = v >> 16;
  t[2] = v >>  8;
  t[3] = v;
 
  myPacketSerial.send(t, 4);
  delay(100);
}

void onPacketReceived(const uint8_t* buffer, size_t size)
{
  pwmWrite(pwmPin, buffer[0]);
}
