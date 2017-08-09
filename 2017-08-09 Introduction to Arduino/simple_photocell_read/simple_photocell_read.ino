int photocellPin = 0;
int photocellValue = 100;

void setup() {
  // put your setup code here, to run once:
  Serial.begin(115200);
}

void loop() {
  // put your main code here, to run repeatedly:
  photocellValue = analogRead(photocellPin);
  Serial.print(photocellValue);
  Serial.print('a');
  delay(1);
}
