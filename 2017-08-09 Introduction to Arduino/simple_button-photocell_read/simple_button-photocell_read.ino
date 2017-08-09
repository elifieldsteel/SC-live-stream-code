int photocellPin = 0;
int buttonPin = 9;
int photocellValue = 100;
int buttonValue = 0;

void setup() {
  // put your setup code here, to run once:
  Serial.begin(115200);
  pinMode(buttonPin, INPUT);
}

void loop() {
  // put your main code here, to run repeatedly:
  photocellValue = analogRead(photocellPin);
  buttonValue = digitalRead(buttonPin);
  Serial.print(photocellValue);
  Serial.print('a');
  if (buttonValue == HIGH) {
    Serial.print(1);
  } else {
    Serial.print(0);
  };
  Serial.print('b');
  delay(1);
}
