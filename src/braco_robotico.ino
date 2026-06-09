//
// Comandos para o monitor Serial 
// U -> Up : sobe a articulacao do braco
// D -> Down : desce a articulacao do braco
// O -> Open : abre a garra
// C -> Close : fecha a garra (captura a amostra)
// H -> Home : retorna a posicao neutra

#include <Servo.h>
// Mapeamento dos pinos
const uint8_t PIN_SERVO_ARM = 9; // Articulacao (Up / Down)
const uint8_t PIN_SERVO_GRIP = 10; // Garra (Open / Close)
const uint8_t PIN_LED_STATUS = 7; // LED de status

const int ARM_MIN = 10; // angulo minimo da articulacao
const int ARM_MAX = 170; // angulo maximo da articulacao
const int ARM_STEP = 15; // incremento de angulo por comando U/D
const int ARM_HOME = 90; // posicao neutra da articulacao
const int GRIP_OPEN = 120; // angulo da garra aberta
const int GRIP_CLOSE = 30; // angulo da garra fechada 
const int MOVE_DELAY = 15; // ms entre cada grau

Servo servoArm;
Servo servoGrip;
int armAngle = ARM_HOME; // posicao atual da articulacao
int gripAngle = GRIP_OPEN; // posicao atual da garra
// 
// Move um servo suavemente o angulo, grau a grau.
//
void moveSmooth(Servo &s, int from, int to) {
 if (to >= from) {
 for (int a = from; a <= to; a++) { s.write(a); delay(MOVE_DELAY); }
 } else {
 for (int a = from; a >= to; a--) { s.write(a); delay(MOVE_DELAY); }
 }
}
// Pisca o LED de status
void blinkStatus(int times) {
 for (int i = 0; i < times; i++) {
 digitalWrite(PIN_LED_STATUS, HIGH); delay(120);
 digitalWrite(PIN_LED_STATUS, LOW); delay(120);
 }
}
// LED aceso = garra fechada; apagado = garra aberta.
void updateStatusLed() {
 digitalWrite(PIN_LED_STATUS, (gripAngle == GRIP_CLOSE) ? HIGH : LOW);
}
void printHelp() {
 Serial.println(F("BRACO ROBOTICO - COMANDOS"));
 Serial.println(F(" U -> Sobe articulacao (Up)"));
 Serial.println(F(" D -> Desce articulacao (Down)"));
 Serial.println(F(" O -> Abre garra (Open)"));
 Serial.println(F(" C -> Fecha garra (Close)"));
 Serial.println(F(" H -> Home (posicao neutra)"));
}
void printState() {
 Serial.print(F("[STATUS] Articulacao: "));
 Serial.print(armAngle);
 Serial.print(F(" deg | Garra: "));
 Serial.print((gripAngle == GRIP_OPEN) ? F("ABERTA") : F("FECHADA"));
 Serial.print(F(" ("));
 Serial.print(gripAngle);
 Serial.println(F(" deg)"));
}
void setup() {
 Serial.begin(9600);
 pinMode(PIN_LED_STATUS, OUTPUT);
 digitalWrite(PIN_LED_STATUS, LOW);
 servoArm.attach(PIN_SERVO_ARM);
 servoGrip.attach(PIN_SERVO_GRIP);
 // Posiciona o braco na posicao inicial.
 servoArm.write(armAngle);
 servoGrip.write(gripAngle);
 blinkStatus(2); // sinaliza inicializacao bem-sucedida
 Serial.println(F("Braco robotico inicializado. Sistema pronto."));
 printHelp();
 printState();
}
void loop() {
 if (!Serial.available()) return;
 char cmd = Serial.read();
 // Ignora caracteres de controle (Enter / espaco).
 if (cmd == '\n' || cmd == '\r' || cmd == ' ') return;
 cmd = toupper(cmd);
 digitalWrite(PIN_LED_STATUS, HIGH); // LED aceso = executando comando
 switch (cmd) {
 case 'U': { // Up - sobe articulacao
 int target = min(armAngle + ARM_STEP, ARM_MAX);
 moveSmooth(servoArm, armAngle, target);
 armAngle = target;
 Serial.println(F("UP: articulacao subindo"));
 break;
 }
 case 'D': { // Down - desce articulacao
 int target = max(armAngle - ARM_STEP, ARM_MIN);
 moveSmooth(servoArm, armAngle, target);
 armAngle = target;
 Serial.println(F("DOWN: articulacao descendo"));
 break;
 }
 case 'O': { // Open - abre a garra
 moveSmooth(servoGrip, gripAngle, GRIP_OPEN);
 gripAngle = GRIP_OPEN;
 Serial.println(F("OPEN: garra aberta"));
 break;
 }
 case 'C': { // Close - fecha a garra
 moveSmooth(servoGrip, gripAngle, GRIP_CLOSE);
 gripAngle = GRIP_CLOSE;
 Serial.println(F("CLOSE: amostra capturada"));
 break;
 }
 case 'H': { // Home - posicao neutra
 moveSmooth(servoArm, armAngle, ARM_HOME);
 armAngle = ARM_HOME;
 moveSmooth(servoGrip, gripAngle, GRIP_OPEN);
 gripAngle = GRIP_OPEN;
 Serial.println(F(">> HOME: posicao neutra"));
 break;
 }
 }
 updateStatusLed(); // LED reflete o estado final da garra
 printState();
}
