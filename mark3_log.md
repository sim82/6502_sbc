
### 21.09.2025: 
Changed the **IO Select** method to an alternative that uses an explicit **Read Strobe** signal from the PLD_07.

---

### Rationale & Modifications

The previous method qualified IO Write cycles with a clock cycle. While this successfully worked around a timing issue with using the raw RWB signal as a read strobe on the UART, it made the overall IO Select timing too rigid. Specifically, it prevented the IO Select signal from being latched on the second half of the clock cycle, as the signal was already qualified and thus latched too late.

To prepare for experiments with the IDE controller, which requires the IO Select to be latched on the second half of the cycle for wait state logic, the following changes were made:

* **Clock cycle qualification** was removed from the IO Write cycles.
* The system now uses a dedicated **Read Strobe** signal from the **PLD output 7** instead of the raw RWB signal.

This adjustment provides greater flexibility in IO Select timing and is a necessary prerequisite for the upcoming IDE controller work.



### 22.09.2025: Logbook Entry

Continued work on the hard disk controller wait state logic.

---

### Rationale & Modifications

An issue was identified where the **WrB signal** continued to pulse while the CPU was in a non-ready state due to clock qualification. To fix this, the **Addressdecoder** was modified to stop qualifying the clock on the WrB signal when the CPU is not ready.

* The unused input **PLD Input 1** was repurposed for the **CPU-ready signal**, which required a physical circuit change.
* A discrete **open collector output stage** was built using a BC548 transistor to provide an inverting output.
