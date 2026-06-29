#ifndef COMMANDS_H
#define COMMANDS_H

// Serial command parser and forward/reverse safety interlock.
// Protocol (newline-terminated):
//   D <left> <right>   drive pairs, signed PWM -255..255
//   S                  soft stop (coast)
//   B                  active brake pulse, then stop
//   ?                  print status

void commandsBegin();
void commandsUpdate();  // call every loop(); fully non-blocking

#endif
