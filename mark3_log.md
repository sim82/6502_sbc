## Let the AI do the boring stuff, like writing a log book...

**21.09.2025: The Clock Qualification 'Hack' Is Out: Making Room for IDE Controller Timing.**
Changed the **IO Select** method to an alternative that uses an explicit **Read Strobe** signal from the PLD_07.

---

### Rationale & Modifications

The previous method qualified IO Write cycles with a clock cycle. While this successfully worked around a timing issue with using the raw RWB signal as a read strobe on the UART, it made the overall IO Select timing too rigid. Specifically, it prevented the IO Select signal from being latched on the second half of the clock cycle, as the signal was already qualified and thus latched too late.

To prepare for experiments with the IDE controller, which requires the IO Select to be latched on the second half of the cycle for wait state logic, the following changes were made:

* **Clock cycle qualification** was removed from the IO Write cycles.
* The system now uses a dedicated **Read Strobe** signal from the **PLD output 7** instead of the raw RWB signal.

This adjustment provides greater flexibility in IO Select timing and is a necessary prerequisite for the upcoming IDE controller work.



**22.09.2025: Decoder Mod Fixes WrB Pulse Bug, Requires a Circuit Change (and a Little Transistor Botch).**

Continued work on the hard disk controller wait state logic.

---

### Rationale & Modifications

An issue was identified where the **WrB signal** continued to pulse while the CPU was in a non-ready state due to clock qualification. To fix this, the **Addressdecoder** was modified to stop qualifying the clock on the WrB signal when the CPU is not ready.

* The unused input **PLD Input 1** was repurposed for the **CPU-ready signal**, which required a physical circuit change.
* A discrete **open collector output stage** was built using a BC548 transistor to provide an inverting output.

**28.09.2025: Wait States Now Working—A Transistor Gets Fired for Being Slow.**

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

**2025-09-30: Upper Bits Achieved: We're Halfway to 16-Bit I/O (Read-Only Edition).**

---

### Initial Logic for Upper 8-Bit Read

The initial logic to enable reading the **upper 8 bits** of a 16-bit word has been implemented and tested.

### Hardware & Modifications

* **Lower 8-Bit Selection:** A **74HC245 transceiver** was used to control the selection of the lower 8 data bits on the bus.
* **Upper 8-Bit Latching:** A **74HC574 latch** was introduced to capture the upper 8 data bits on every read cycle.
* **Bus Output Mapping:** The latched value of the upper 8 bits can be output onto the bus by performing an I/O read operation where address line **A3 is high** (corresponding to an IO address like **$FE28**).
* **PLD Update:** Necessary control and select signals for this new logic block were added to the **PLD**.

### Status

This logic currently only works in the **read direction**, with the write direction still pending implementation.


**2025-10-02: 16-Bit Write is Go—Now Begging the PLD for One More Pin.**

---

### Hardware Integration & PLD Resource Management

The 16-bit write path is now complete following hardware integration and necessary pin optimization:

* A **second 74HC574 latch** was wired in to handle the **upper 8 data bits** for write operations.
* **PLD outputs are now fully utilized.** To free up a critical control signal:
    * The **DIR (Direction)** signal was freed by creatively re-using the existing **disk read strobe signal**.
    * The newly available PLD output pin was then re-purposed to generate the **latch signal** for the second 74HC574.

### Software Update

* The hard disk **test program** was extended to include a **write command**, allowing for initial testing of the full 16-bit read/write data path.
