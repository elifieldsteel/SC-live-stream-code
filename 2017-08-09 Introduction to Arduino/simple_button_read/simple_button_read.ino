int buttonPin = 9;
int buttonValue = 0;

void setup() {
  // put your setup code here, to run once:
  Serial.begin(115200);
  pinMode(buttonPin, INPUT);
}

void loop() {
  // put your main code here, to run repeatedly:
  buttonValue = digitalRead(buttonPin);
  if (buttonValue == HIGH) {
    Serial.print(1);
  } else {
    Serial.print(0);
  };
  delay(1);
}
