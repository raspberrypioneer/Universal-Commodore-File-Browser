# Universal FB v5

A compact, universal launcher for **CBM FileBrowser** on the Commodore 64, Commodore 16 and VIC-20. The same **271-byte `FB` program** detects the computer (and the VIC-20's active memory configuration), then loads and starts the appropriate FileBrowser program from **device 8**.

The launcher uses a short BASIC `SYS` stub followed by a machine-code bootstrap and loader.

## Supported configurations

| Computer | Selected FileBrowser program |
| --- | --- |
| Commodore 64 | `FB64` |
| Commodore 16 | `FB16` |
| VIC-20, unexpanded | `FB20` |
| VIC-20, +3K RAM | `FB20-3K` |
| VIC-20, +8K RAM or more | `FB20-8K` |

VIC-20 selection follows the **active BASIC memory layout**, not a physical RAM capacity test. Special cartridge-specific FileBrowser versions (such as Mega-Cart) are not supported.

## Requirements

- A C64, C16 or VIC-20 with one of the configurations above.
- An SD2IEC, Pi1541 or compatible device providing the browser programs as files on device **8**.
- The appropriate FileBrowser programs using the **exact names** listed in the table (no filename extension required).
- **ACME** 6502 cross-assembler to build from source.

## Build

The assembly source `universal-fb.asm` is compiled using ACME with build script `fb_build.bat`. The completed program `./prg/fb` (without the `.prg` extension) should be **271 bytes**, including the two-byte PRG load address.

## Install and run

The `./prg` folder with the compiled loader also contains the supported **CBM FileBrowser** programs.

```text
fb
fb64
fb16
fb20
fb20-3k
fb20-8k
```

On any supported computer, enter:

```basic
LOAD"FB",8
RUN
```

**Use `LOAD"FB",8`, not `LOAD"FB",8,1`.** The normal BASIC load relocates the program to the machine's current BASIC start address. The BASIC stub calculates the bootstrap address at runtime.

The launcher selects the filename automatically, suppresses routine KERNAL loading messages and starts FileBrowser.

## How it works

1. **BASIC stub:** A single tokenised BASIC line executes the relocated machine code. Its listing is:

   ```basic
   10 SYS PEEK(43)+256*PEEK(44)+27
   ```

2. **Bootstrap:** A 28-byte position-independent routine locates the embedded 214-byte loader, copies it to `$1C00` and jumps there.
3. **Detection:** The main loader identifies the machine using the BASIC start address and the KERNAL screen-width routine where necessary. On the VIC-20 it distinguishes unexpanded, +3K and +8K-or-more BASIC configurations.
4. **Browser load:** A small loading trampoline is copied to `$0350` to remain safe while the selected FileBrowser program loads. It then transfers control to that browser's entry point.

The assembly source uses ACME's `!pseudopc` directive to assemble the main loader for its execution address while embedding the bytes immediately after the bootstrap. The literal `+27` in the BASIC line is the bootstrap offset from the BASIC start; it must be updated if the BASIC stub layout changes.

## Notes

- The launcher expects **device 8** and conventional browser filenames.
- It is intended for standard BASIC memory configurations, not cartridge-specific launch environments.
- Keep the extensionless `fb` file in a Commodore-accessible directory. Host-filesystem filename and extension handling may depend on the emulator or drive firmware.
