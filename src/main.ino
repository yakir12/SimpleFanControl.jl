#include <PWM.h>
#include <PacketSerial.h> // for the COBS

PacketSerial myPacketSerial;

int pwmPin = 3;
int tachPin1 = 2;
int tachPin2 = 4;
int tachPin3 = 5;
unsigned long v;
uint8_t t[12];

void setup()
{
  myPacketSerial.begin(115200);
  myPacketSerial.setPacketHandler(&onPacketReceived);

  InitTimersSafe();
  bool success = SetPinFrequencySafe(pwmPin, 25000);
  if (success) {
    //    pinMode(tachPin, OUTPUT);
    digitalWrite(tachPin1, HIGH);
    digitalWrite(tachPin2, HIGH);
    digitalWrite(tachPin3, HIGH);
  }
  delay(100);
  pwmWrite(pwmPin, 0);

}

void loop()
{
  myPacketSerial.update();
}

void onPacketReceived(const uint8_t* buffer, size_t size)
{
  if (buffer[0] == 0) {
    v = pulseIn(tachPin1, HIGH, 100000);
    t[0] = v >> 24;
    t[1] = v >> 16;
    t[2] = v >>  8;
    t[3] = v;
    v = pulseIn(tachPin2, HIGH, 100000);
    t[4] = v >> 24;
    t[5] = v >> 16;
    t[6] = v >>  8;
    t[7] = v;
    v = pulseIn(tachPin3, HIGH, 100000);
    t[8] = v >> 24;
    t[9] = v >> 16;
    t[10] = v >>  8;
    t[11] = v;

    myPacketSerial.send(t, 12);
  }
  else {
    pwmWrite(pwmPin, buffer[0]);
  }
}
