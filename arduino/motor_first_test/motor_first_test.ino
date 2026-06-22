// First hardware test: drive all 4 motors via Serial Monitor.
// Commands: F = forward, B = backward, S = stop
// Send from Arduino IDE Serial Monitor at 115200 baud.
// Remove Serial.println() calls before writing the real Phase 2 sketch.
//
// Wiring (Arduino pin -> L298N pin):
//   Pin 5  -> ENA   (left motors speed, PWM)
//   Pin 4  -> IN1   (left motors direction)
//   Pin 7  -> IN2   (left motors direction)
//   Pin 6  -> ENB   (right motors speed, PWM)
//   Pin 8  -> IN3   (right motors direction)
//   Pin 9  -> IN4   (right motors direction)

const int LEFT_EN  = 5;
const int LEFT_IN1 = 4;
const int LEFT_IN2 = 7;
const int RIGHT_EN = 6;
const int RIGHT_IN3 = 8;
const int RIGHT_IN4 = 9;

const int TEST_SPEED = 150;

void stopMotors();
void forward();
void backward();

void setup() {
  Serial.begin(115200);

  pinMode(LEFT_EN,   OUTPUT);
  pinMode(LEFT_IN1,  OUTPUT);
  pinMode(LEFT_IN2,  OUTPUT);
  pinMode(RIGHT_EN,  OUTPUT);
  pinMode(RIGHT_IN3, OUTPUT);
  pinMode(RIGHT_IN4, OUTPUT);

  stopMotors();
  Serial.println("Ready. F=forward  B=backward  S=stop");
}

void loop() {
  if (Serial.available() > 0) {
    char cmd = (char)Serial.read();

    if      (cmd == 'F' || cmd == 'f') forward();
    else if (cmd == 'B' || cmd == 'b') backward();
    else if (cmd == 'S' || cmd == 's') stopMotors();
  }
}

void forward() {
  digitalWrite(LEFT_IN1,  HIGH);
  digitalWrite(LEFT_IN2,  LOW);
  digitalWrite(RIGHT_IN3, HIGH);
  digitalWrite(RIGHT_IN4, LOW);
  analogWrite(LEFT_EN,  TEST_SPEED);
  analogWrite(RIGHT_EN, TEST_SPEED);
  Serial.println("Forward");
}

void backward() {
  digitalWrite(LEFT_IN1,  LOW);
  digitalWrite(LEFT_IN2,  HIGH);
  digitalWrite(RIGHT_IN3, LOW);
  digitalWrite(RIGHT_IN4, HIGH);
  analogWrite(LEFT_EN,  TEST_SPEED);
  analogWrite(RIGHT_EN, TEST_SPEED);
  Serial.println("Backward");
}

void stopMotors() {
  digitalWrite(LEFT_IN1,  LOW);
  digitalWrite(LEFT_IN2,  LOW);
  digitalWrite(RIGHT_IN3, LOW);
  digitalWrite(RIGHT_IN4, LOW);
  analogWrite(LEFT_EN,  0);
  analogWrite(RIGHT_EN, 0);
  Serial.println("Stopped");
}
