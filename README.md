# TMR-Voter-System

Triple Modular Redundancy (TMR) Voter System. This project implements a Triple Modular Redundancy (TMR) system on an FPGA. It features three identical ALU cores, a radiation/fault simulator, and a majority voter to ensure high reliability and fault tolerance in mission-critical applications (like aerospace or medical systems).

## ## Project Overview
The system processes data through three parallel "Cores." Even if one core produces an incorrect result due to a simulated "radiation hit" (bit flip or corruption), the **Majority Voter** identifies the correct output based on the agreement of the other two cores.

### ### Key Features
* **Three ALU Cores:** 8-bit operations (Addition, Multiplication, Logic, etc.).
* **Fault Injection:** Use onboard buttons to manually corrupt the data of specific cores.
* **Majority Voter Logic:** Real-time error correction.
* **Status Logging:** A 7-segment display shows which core is failing, while a Red LED indicates an irrecoverable system failure (when all cores disagree).

---

## ## Hardware Mapping (Pin Constraints)
Based on the XDC/Vivado settings, the following physical components are mapped:

### ### Inputs
| Signal | Package Pin | Function |
| :--- | :--- | :--- |
| **clk** | E3 | System Clock |
| **sw[5:0]** | J15 to T18 | Input Operand A |
| **sw[11:6]** | U18 to H6 | Input Operand B |
| **sw[15:12]** | U12 to V10 | Operation Selector (OpCode) |
| **btnC** | N17 | Corrupt Core A (Stuck-at-0) |
| **btnU** | M18 | Corrupt Core B (Stuck-at-1) |
| **btnD** | P18 | Corrupt Core C (Bitwise Inversion) |

### ### Outputs
| Signal | Package Pin | Function |
| :--- | :--- | :--- |
| **led[11:0]** | K15 to U14 | 12-bit ALU Result |
| **led15_r** | N16 | **Red LED:** Irrecoverable Failure |
| **seg[6:0]** | T10 to L18 | 7-Segment Display (Shows A, B, C, or F) |
| **an[7:0]** | J17 to U13 | Anode Control for 7-Segment |

---

## ## How it Works
1. **The Cores:** Three instances of `alu_core` perform the same calculation simultaneously. They support 16 operations, including arithmetic, logical shifts, and comparisons.
2. **Fault Injection:** * **btnC:** Forces Core A to 0.
   * **btnU:** Forces Core B to all 1s (0xFFF).
   * **btnD:** Inverts all bits of Core C's result.
3. **Voter Logic:** The system constantly compares `resA`, `resB`, and `resC`.
   * **Normal:** All agree? LEDs show result, 7-Seg is OFF.
   * **Single Failure:** If one core fails, the system uses the other two. The 7-Seg displays the failing core's name.
   * **Irrecoverable:** If all three cores disagree, the Red LED turns ON and the 7-Seg displays "F".

---

## ## Summary of Logic
The core reliability is governed by the majority function:
$$Result = (A \cdot B) + (B \cdot C) + (A \cdot C)$$

This ensures that as long as any two cores are functional, the system output remains valid.
