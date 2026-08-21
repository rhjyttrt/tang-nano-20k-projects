\# 128 Bit IEEE 754 Floating Point Unit Core



A synthesizable IEEE 754 2008 quadruple precision (`binary128`) Floating Point Unit IP core written in Verilog HDL.



Designed specifically as an embeddable IP block for custom processors (such as RISC V), coprocessors, and hardware acceleration datapaths on resource constrained FPGAs like the Gowin GW2AR 18 (Tang Nano 20K).



\*\*\*



\## Features



\* \*\*Format:\*\* IEEE 754 2008 Quadruple Precision (`binary128`)

&#x20; \* 1 bit Sign

&#x20; \* 15 bit Exponent (Bias = 16383)

&#x20; \* 112 bit Fraction (113 bit effective significand with implicit leading bit)

\* \*\*Supported Operations:\*\*

&#x20; \* Addition (`2'b00`)

&#x20; \* Subtraction (`2'b01`)

&#x20; \* Multiplication (`2'b10`)

\* \*\*Rounding Modes:\*\*

&#x20; \* `2'b00`: Round to Nearest, Ties to Even (RNE)

&#x20; \* `2'b01`: Round toward Zero (RTZ)

&#x20; \* `2'b10`: Round Down / toward negative infinity (RDN)

&#x20; \* `2'b11`: Round Up / toward positive infinity (RUP)

\* \*\*Status \& Exception Flags:\*\*

&#x20; \* `flags\[3]`: Overflow (OF)

&#x20; \* `flags\[2]`: Underflow (UF)

&#x20; \* `flags\[1]`: Inexact (NX)

&#x20; \* `flags\[0]`: Invalid Operation (NV)

\* \*\*FPGA Resource Optimized:\*\*

&#x20; \* Multi cycle 29 bit iterative multiplier datapath requiring only \*\*4 DSP blocks\*\* (well within the Tang Nano 20K physical limit of 12 DSPs).



\*\*\*



