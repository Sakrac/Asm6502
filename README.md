# Asm6502

6502 Macro Assembler in a single c++ file using the struse single file text parsing library. Supports most syntaxes.

Asm6502 is a struse example that implements a simple 6502 macro assembler.

Every assembler seems to add or change its own quirks to the 6502 syntax. This implementation aims to support all of them at once as long as there is no contradiction.

To keep up with this trend Asm6502 is adding the following features to the mix:

1. Full expression evaluation everywhere values are used: [Expressions](#expressions)
2. C style scoping within '{' and '}': [Scopes](#scopes)
3. Reassignment of labels. This means there is no error if you declare the same label twice, but on the other hand you can do things like label = label + 2.
4. [Local labels](#labels) can be defined in a number of ways, such as leading period (.label) or leading at-sign (@label) or terminating dollar sign (label$).
5. [Directives](#directives) support both with and without leading period.
6. Labels don't need to end with colon, but they can.
7. No indentation required for instructions, meaning that labels can't be mnemonics, macros or directives.
8. As far as achievable, support the syntax of other 6502 assemblers.

In summary, if you are familiar with any 6502 assembler syntax you should feel at home with Asm6502. If you're familiar with C programming expressions you should be familiar with '{', '}' scoping and complex expressions.

There are no hard limits on binary size so if the address exceeds $ffff it will just wrap around to $0000. I'm not sure about the best way to handle that or if it really is a problem.

## Prerequisite

Asm6502.cpp requires struse.h which is a single file text parsing library that can be retrieved from https://github.com/Sakrac/struse.

### References

* [6502 opcodes](http://www.6502.org/tutorials/6502opcodes.html)
* [6502 opcode grid](http://www.llx.com/~nparker/a2/opcodes.html)
* [Codebase64 CPU section](http://codebase64.org/doku.php?id=base:6502_6510_coding)

## Features

* **Code**
* **Comments**
* **Labels**
* **Directives**
* **Macros**
* **Expressions**

### Code

Code is any valid mnemonic/opcode and addressing mode. At the moment only one opcode per line is assembled.

### Comments

Comments are currently line based and both ';' and '//' are accepted as delimiters.

### <a name="expressions">Expressions

Anywhere a number can be entered it can also be interpreted as a full expression, for example:

```
Get123:
    bytes Get1-*, Get2-*, Get3-*
Get1:
	lda #1
	rts
Get2:
	lda #2
	rts
Get3:
	lda #3
	rts
```

Would yield 3 bytes where the address of a label can be calculated by taking the address of the byte plus the value of the byte.

### <a name="labels">Labels

Labels come in two flavors: **Addresses** (PC based) or **Values** (Evaluated from an expression).  An address label is simply placed somewhere in code and a value label is follwed by '**=**' and an expression. All labels are rewritable so it is fine to do things like NumInstance = NumInstance+1. Value assignments can be prefixed with '.const' or '.label' but is not required to be prefixed by anything.

*Local labels* exist inbetween *global labels* and gets discarded whenever a new global label is added. The syntax for local labels are one of: prefix with period, at-sign, exclamation mark or suffix with $, as in: **.local** or **!local** or **@local** or **local$**. Both value labels and address labels can be local labels.

```
Function:			; global label
	ldx #32
.local_label		; local label
	dex
	bpl .local_label
	rts

Next_Function:		; next global label, the local label above is now erased.
	rts
```

### <a name="directives">Directives

Directives are assembler commands that control the code generation but that does not generate code by itself. Some assemblers prefix directives with a period (.org instead of org) so a leading period is accepted but not required for directives.

* [**ORG**](#org) (same as **PC**): Set the current compiling address.
* [**LOAD**](#load) Set the load address for binary formats that support it.
* [**ALIGN**](#align) Align the address to a multiple by filling with 0s
* [**MACRO**](#macro) Declare a macro
* [**EVAL**](#eval) Log an expression during assembly.
* [**BYTES**](#bytes) Insert comma separated bytes at this address (same as **BYTE**)
* [**WORDS**](#words) Insert comma separated 16 bit values at this address (same as **WORD**)
* [**TEXT**](#text) Insert text at this address
* [**INCLUDE**](#include) Include another source file and assemble at this address
* [**INCBIN**](#incbin) Include a binary file at this address
* [**CONST**](#const) Assign a value to a label and make it constant (error if reassigned with other value)
* [**LABEL**](#label) Decorative directive to assign an expression to a label
* [**INCSYM**](#incsym) Include a symbol file with an optional set of wanted symbols.
* [**POOL**](#pool) Add a label pool for temporary address labels
* [**#IF/#ELSE/#IFDEF/#ELIF/#ENDIF**](#conditional) Conditional assembly

<a name="org">**ORG**

```
org $2000
(or pc $2000)
```

Sets the current assembler address to this address

<a name="load">**LOAD**

```
load $2000
```

For c64 .prg files this prefixes the binary file with this address.

<a name="align">**ALIGN**

```
align $100
```

Add bytes of 0 up to the next address divisible by the alignment

<a name="macro">**MACRO**

See the 'Macro' section below

<a name="eval">**EVAL**

Example:
```
eval Current PC: *
```
Might yield the following in stdout:
```
Eval (15): Current PC : "*" = $2010
```

When eval is encountered on a line print out "EVAL (\<line#\>) \<message\>: \<expression\> = \<evaluated expression\>" to stdout. This can be useful to see the size of things or debugging expressions.

<a name="bytes">**BYTES**

Adds the comma separated values on the current line to the assembled output, for example

```
RandomBytes:
	bytes NumRandomBytes
	{
	    bytes 13,1,7,19,32
		NumRandomBytes = * - !
	}
```

byte is also recognized

<a name="words">**WORDS**

Adds comma separated 16 bit values similar to how **BYTES** work

<a name="text">**TEXT**

Copies the string in quotes on the same line. The plan is to do a petscii conversion step. Use the modifier 'petscii' or 'petscii_shifted' to convert alphabetic characters to range.

Example:

```
text petscii_shifted "This might work"
```

<a name="include">**INCLUDE**

Include another source file. This should also work with .sym files to import labels from another build. The plan is for Asm6502 to export .sym files as well.

Example:

```
include "wizfx.s"
```


<a name="incbin">**INCBIN**

Include binary data from a file, this inserts the binary data at the current address.

Example:

```
incbin "wizfx.gfx"
```

<a name="const">**CONST**

Prefix a label assignment with 'const' or '.const' to cause an error if the label gets reassigned.

```
const zpData = $fe
```

<a name="label">**LABEL**

Decorative directive to assign an expression to a label, label assignments are followed by '=' and an expression.

These two assignments do the same thing (with different values):
```
label zpDest = $fc
zpDest = $fa
```

<a name="incsym">**INCSYM**

Include a symbol file with an optional set of wanted symbols.

Open a symbol file and extract a set of symbols, or all symbols if no set was specified. Local labels will be discarded if possible.

```
incsym Part1_Init, Part1_Update, Part1_Exit "part1.sym"
```

<a name="pool">**POOL**

Add a label pool for temporary address labels. This is similar to how stack frame variables are assigned in C.

A label pool is a mini stack of addresses that can be assigned as temporary labels with a scope ('{' and '}'). This can be handy for large functions trying to minimize use of zero page addresses, the function can declare a range (or set of ranges) of available zero page addresses and labels can be assigned within a scope and be deleted on scope closure. The format of a label pool is: "pool <pool name> start-end, start-end" and labels can then be allocated from that range by '<pool name> <label name>[.b][.w]' where .b means allocate one byte and .w means allocate two bytes. The label pools themselves are local to the scope they are defined in so you can have label pools that are only valid for a section of your code. Label pools works with any addresses, not just zero page addresses.

Example:
```
Function_Name: {
	pool zpWork $f6-$100		; these zero page addresses are available for temporary labels
	zpWork zpTrg.w				; zpTrg will be $fe
	zpWork zpSrc.w				; zpSrc will be $fc

	lda #>Src
	sta zpSrc
	lda #<Src
	sta zpSrc+1
	lda #>Dest
	sta zpDst
	lda #<Dest
	sta zpDst+1

	{
		zpWork zpLen			; zpLen will be $fb
		lda #Length
		sta zpLen
	}
	nop
	{
		zpWork zpOff			; zpOff will be $fb (shared with previous scope zpLen)
	}
	rts
```

<a name="conditional">**#IF/#ELSE/#IFDEF/#ELIF/#ENDIF**

Conditional code parsing is very similar to C directive conditional compilation.

Example:

```
DEBUG = 1

#if DEBUG
    lda #2
#else
    lda #0
#endif
```

## <a name="expressions">Expression syntax

Expressions contain values, such as labels or raw numbers and operators including +, -, \*, /, & (and), | (or), ^ (eor), << (shift left), >> (shift right) similar to how expressions work in C. Parenthesis are supported for managing order of operations where C style precedence needs to be overrided. In addition there are some special characters supported:

* \*: Current address (PC). This conflicts with the use of \* as multiply so multiply will be interpreted only after a value or right parenthesis
* <: If less than is the first character in an expression this evaluates to the low byte (and $ff)
* >: If greater than is the first character in an expression this evaluates to the high byte (>>8)
* !: Start of scope (use like an address label in expression)
* %: First address after scope (use like an address label in expression)
* $: Preceeds hexadecimal value
* %: If immediately followed by '0' or '1' this is a binary value and not scope closure address

## Macros

A macro can be defined by the using the directive macro and includes the line within the following scope:

Example:
```
macro ShiftLeftA(Source) {
    rol Source
    rol A
}
```

The macro will be instantiated anytime the macro name is encountered:
```
lda #0
ShiftLeftA($a0)
```

The parameter field is optional for both the macro declaration and instantiation, if there is a parameter in the declaration but not in the instantiation the parameter will be removed from the macro. If there are no parameters in the declaration the parenthesis can be omitted and will be slightly more efficient to assemble, as in:

```
.macro GetBit {
    asl
    bne %
    jsr GetByte
}
```

Currently macros with parameters use search and replace without checking if the parameter is a whole word, the plan is to fix this. 

## <a name="scopes">Scopes

Scopes are lines inbetween '{' and '}' including macros. The purpose of scopes is to reduce the need for local labels and the scopes nest just like C code to support function level and loops and inner loop scoping. '!' is a label that is the first address of the scope and '%' the first address after the scope.

This means you can write
```
{
    lda #0
    ldx #8
    {
        sta Label,x
    	dex
    	bpl !
    }
}
```	
(where ; represents line breaks) to construct a loop without adding a label.

##Examples

Using scoping to avoid local labels

```
; set zpTextPtr to a memory location with text
; return: y is the offset to the first space.
;  (y==0 means either first is space or not found.)
FindFirstSpace
  ldy #0
  {
    lda (zpTextPtr),y
    cmp #$20
    beq %             ; found, exit
    iny
    bne !             ; not found, keep searching
  }
  rts
```

### Development Status

Currently the assembler is in the first public revision and while features are tested individually it is fairly certain that untested combinations of features will indicate flaws and certain features are not in a complete state (such as the TEXT directive not bothering to convert ascii to petscii for example).

**TODO**
* Macro parameters should replace only whole words instead of any substring
* Add 'import' directive as a catch-all include/incbin/etc. alternative
* rept / irp macro helpers (repeat, indefinite repeat)

**FIXED**
* ifdef / if / elif / else / endif conditional code generation directives
* Label Pools added
* Bracket scoping closure ('}') cleans up local variables within that scope (better handling of local variables within macros).
* Context stack cleanup
* % in expressions is interpreted as binary value if immediately followed by 0 or 1
* Add a const directive for labels that shouldn't be allowed to change (currently ignoring const)
* TEXT directive converts ascii to petscii (respect uppercase or lowercase petscii) (simplistic)

Revisions:
* 2015-10-01 Added Label Pools and conditional assembly
* 2015-09-29 Moved Asm6502 out of Struse Samples.
* 2015-09-28 First commit
