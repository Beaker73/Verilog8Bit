# Beaker8 CPU

## Registers

The Beaker8 virtual CPU does not name it registers, but instead uses a 'virtual stack'. As such it's a mix between a stack based cpu (like most VMs like Java and .NET) but instead of using memory for stack, it's using an internal set of registers. This allows for short instructions, even with large number of virtual registers (32) -keeping within the 8-bit restrictions- witout the slowdown of a stack in ram memory. This virtual stack is only used for registers, the call stack is still in memory, otherwise we would quickly run out of registers after a few calls.

### Technical Registers

Name| Size | Description
:--:|-----:|-----------
 PC |   16 | Program Counter
 RP |    5 | Register Pointer
 SP |   16 | Stack Pointer
 A  |    8 | Accumulator
 F  |    8 | Flags
 T  |    8 | Temporary
 Rx |    8 | R0 t/m R31 stack registers

### Flags

 7 | 6 | 5 | 4 | 3 | 2 | 1 | 0 | 
:-:|:-:|:-:|:-:|:-:|:-:|:-:|:-:|
 0 | 0 | 0 | 0 | 0 | 0 | C | Z |

Z - Zero Flag
C - Carry Flag

## Instructions

### parameters

Instructions take there parameters from the register stack
Most instructions also have a variant with a constant (-1 to 3) embedded as part of the instruction. This allows us to leave out instructions like inc and dec, those can then replaced with add 1 and sub 1.
Furthermore there is a version with a byte value after the instruction.
And a version that takes an address from the register stack and fetches the byte at that address.

 2 | 1 | 0 | type      | description
:-:|:-:|:-:|:----------|:-----------
 0 | 0 | 0 | opc 0     | constant value 0
 0 | 0 | 1 | opc 1     | constant value 1
 0 | 1 | 0 | opc 2     | constant value 2
 0 | 1 | 1 | opc 3     | constant value 3
 1 | 0 | 0 | opc       | all from stack (default variant)
 1 | 0 | 1 | opc n     | constant byte after opcode
 1 | 1 | 0 | opc -(rp) | addres from stack, read byte there
 1 | 1 | 1 | opc -1    | constant value -1 (or 255)

## Instructions by name

name  | action 1   | action 2   | action 3   | action 4   | flags
------|------------|------------|------------|------------|-----------
add   | -(rp) => t | -(rp) => a | a = a + t  | a => (rp)+ | `∙∙∙∙∙∙cz`
add n | -(rp) => a | a = a + n  | a => (rp)+ |            | `∙∙∙∙∙∙cz`

## Instructions by code

 7 | 6 | 5 | 4 | 3 | 2 | 1 | 0 | data | name 
:-:|:-:|:-:|:-:|:-:|:-:|:-:|:-:|:-----|:---------
 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |      | nop

00000 000 nop
      001 halt

00001 add
00010 addc
00011 sub
00100 subc
00101 and
00110 or
00111 xor
