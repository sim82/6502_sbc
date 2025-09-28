## Let the AI do the boring stuff, like writing a log book...

### 21.09.2025: The Clock Qualification 'Hack' Is Out: Making Room for IDE Controller Timing.
Changed the **IO Select** method to an alternative that uses an explicit **Read Strobe** signal from the PLD_07.

---

### Rationale & Modifications

The previous method qualified IO Write cycles with a clock cycle. While this successfully worked around a timing issue with using the raw RWB signal as a read strobe on the UART, it made the overall IO Select timing too rigid. Specifically, it prevented the IO Select signal from being latched on the second half of the clock cycle, as the signal was already qualified and thus latched too late.

To prepare for experiments with the IDE controller, which requires the IO Select to be latched on the second half of the cycle for wait state logic, the following changes were made:

* **Clock cycle qualification** was removed from the IO Write cycles.
* The system now uses a dedicated **Read Strobe** signal from the **PLD output 7** instead of the raw RWB signal.

This adjustment provides greater flexibility in IO Select timing and is a necessary prerequisite for the upcoming IDE controller work.



### 22.09.2025: Decoder Mod Fixes WrB Pulse Bug, Requires a Circuit Change (and a Little Transistor Botch).

Continued work on the hard disk controller wait state logic.

---

### Rationale & Modifications

An issue was identified where the **WrB signal** continued to pulse while the CPU was in a non-ready state due to clock qualification. To fix this, the **Addressdecoder** was modified to stop qualifying the clock on the WrB signal when the CPU is not ready.

* The unused input **PLD Input 1** was repurposed for the **CPU-ready signal**, which required a physical circuit change.
* A discrete **open collector output stage** was built using a BC548 transistor to provide an inverting output.

### 28.09.2025: Wait States Now Working—A Transistor Gets Fired for Being Slow.

Wait state logic is now functional, and the HD test program has been improved.

---

### Wait State Logic Implementation

* The **wait state logic** is confirmed to be working.
* The implementation uses a **74LS193 counter** to pull down the CPU ready signal for a configurable duration of **1 to 16 clock cycles**, allowing the slower IDE controller to synchronize with the CPU.

### Hardware Modification & Improvement

* The discrete transistor-based open collector solution for the CPU ready signal was found to be too slow to return to a high-impedance (high-Z) state, failing to operate reliably at the system's **14 MHz** clock speed. This naive implementation was replaced.
* The new solution uses a **tri-state output** on the PLD to interface correctly with the open collector CPU ready signal. This modification resolved the speed issue.

### Software Update

* The **HD test program** was significantly improved to perform critical IDE commands:
    * **IDENTIFY**
    * **READ BLOCK**
    * **DUMP BLOCK**
