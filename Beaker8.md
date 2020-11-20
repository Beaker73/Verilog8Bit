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
 0 | 0 | 0 | 0 | 0 | O | C | Z |

Z - Zero Flag
C - Carry Flag
O - Overflow


### Flag conditions

Some instructions might execute based on flag state. The following conditions are supported.

 2 | 1 | 0 | Cond.| Description
:-:|:-:|:-:|:----:|:-----------
 0 | 0 | 0 | nz   | Non Zero: Zero flag cleared
 0 | 0 | 1 | z    | Zero: Zero flag set
 0 | 1 | 0 | nc   | No Carry: Carry flag cleared
 0 | 1 | 1 | c    | Carry: Carry flag set
 1 | 0 | 0 | no   | No Overflow: Overflow flag cleared (2-compl)
 1 | 0 | 1 | o    | Overflow: Overflow flag set (2-compl)
 1 | 1 | 0 | ?    | ?
 1 | 1 | 1 | true | Default: Jump Always

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
 1 | 0 | 0 | opc       | from register stack (default variant)
 1 | 0 | 1 | opc n     | constant byte after opcode
 1 | 1 | 0 | opc (rp)  | addres from stack, read byte there
 1 | 1 | 1 | opc -1    | constant value -1 (or 255)

## Instructions by name

name  | action 1   | action 2   | action 3   | action 4   | flags
------|------------|------------|------------|------------|-----------
add   | -(rp) => t | -(rp) => a | a = a + t  |            | `∙∙∙∙∙∙cz`
add n | -(rp) => a | a = a + n  |            |            | `∙∙∙∙∙∙cz`

## Instructions by code

 7 | 6 | 5 | 4 | 3 | 2 | 1 | 0 | data | name 
:-:|:-:|:-:|:-:|:-:|:-:|:-:|:-:|:-----|:---------
 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |      | nop
 

00000 000 nop
00000 001 halt
00000 010 di
00000 011 ei
00000 100 
00000 101 
00000 110 
00000 111 

00001 load      nn  (nn)                                nn
00010                                                   n
00011 ret       .nz .z  nc  .c  .no .o  -   .true
00100 jmp.r     .nz .z  nc  .c  .no .o  -   .true       n
00101 jmp       .nz .z  nc  .c  .no .o  -   .true       nn
00110 jsr.r     .nz .z  nc  .c  .no .o  -   .true       n
00111 jsr       .nz .z  nc  .c  .no .o  -   .true       nn

01000 load      0   1   2   4   nn  n   .a  -1
01001 store                             .a
01010 clone     0   1   2   3   4   5   6   7
01011 update    0   1   2   3   4   5   6   7
01100 drop      0   1   2   3   4   5   6   7
01101 undrop    0   1   2   3   4   5   6   7
01110 push      0   1   2   3   4   5   6   7
01111 pop       0   1   2   3   4   5   6   7

10000 add       0   1   2   4       n   .a  -1
10001 addc      0   1   2   4       n   .a  -1
10010 sub       0   1   2   4       n   .a  -1
10011 subc      0   1   2   4       n   .a  -1
10100 cmp       0   1   2   4       n   .a  -1
10101 and       0   1   2   4       n   .a  -1
10110 or        0   1   2   4       n   .a  -1
10111 xor       0   1   2   4       n   .a  -1

11000 rr        0   1   2   3   4   5   6   7
11001 rrc       0   1   2   3   4   5   6   7
11010 sr        0   1   2   3   4   5   6   7
11011 src       0   1   2   3   4   5   6   7
11100 rl        0   1   2   3   4   5   6   7
11101 rlc       0   1   2   3   4   5   6   7
11110 sl        0   1   2   3   4   5   6   7
11111 slc       0   1   2   3   4   5   6   7

# examples

        ld hl,$4000
        ld b,0
.loop   ld a,(hl)
        cp 0
        jr z,.done
        xor b
        ld b,a
        inc hl
        jr .loop
.done


        load    $40
        load.0
        load.0
.loop   load.a
        cmp.0
        jmpr.z  .done
        xor
        drop.2
        add.1
        undrop
        addc.1
        undrop
        jr      .loop
.done