# SL-OPENTHREAD/3.1.2.0_GitHub-fb274efe6
Built with OpenThread 3.1.2 from Simplicity SDK 2026.6.2 and ATfE LLVM 23.1.0 LTO, adding no-flow and bounded-wait SW-flow SONOFF Dongle Plus MG24 variants.

- Updated to Simplicity SDK 2026.6.2 (OpenThread 3.1.2.0) built with ATfE LLVM 23.1.0 (`-O2` + `-flto=full`).
- Added four SONOFF Dongle Plus MG24 OpenThread RCP variants: `460800` and `1000000` baud in both `no_flow` and `sw_flow` (`XON`/`XOFF`) configurations (`460800` `no_flow` recommended for unpatched OTBR).
- Doubled UART and radio RX buffers on `1000000` variants (`8192 B` NCP TX, `1024 B` VCOM RX, `32` radio RX buffers; `460800` variants use ZBT-2 sizes: `4096 B` / `512 B` / `16`).
- On `sw_flow` variants only, added a `sl_sleeptimer`-bounded wait (50 ms continuous stall, 150 ms max from the first XOFF stall in a write call) in `sl_iostream_uart.c` paired with `uart_tx_drop_on_timeout.patch` so held or oscillating XOFF cannot starve the bare-metal superloop and trigger a watchdog reset (`no_flow` variants omit both UART TX timeout patches).

# SL-OPENTHREAD/3.1.1.0_GitHub-fb274efe6
Built with OpenThread 3.1.0 from Simplicity SDK 2026.6.1, adding automatic recovery from firmware stalls and fixing serial link lockups.

- Built with OpenThread 3.1.0 from Simplicity SDK 2026.6.0, up from Simplicity SDK 2025.6.2.
- Added a watchdog that resets the adapter if the firmware gets stuck.
- Fixed the serial link locking up when the host stopped reading while hardware flow control was enabled (ZBT-1 and Yellow). Transmits now give up after a short bounded wait and drop the byte, so the adapter keeps running and the host can recover.
- Doubled the host transmit buffer from 2048 to 4096 bytes, reducing dropped frames when a burst of network traffic arrives at once.
- Fixed a Green Power packet filter that misclassified zero-payload frames by reading past the end of the frame.

# SL-OPENTHREAD/3.1.0.0_GitHub-fb274efe6
Built with OpenThread 3.1.0 from Simplicity SDK 2026.6.0, adding automatic recovery from firmware stalls and fixing serial link lockups.

# SL-OPENTHREAD/3.0.2.0_GitHub-61e43cffb
Built with OpenThread 3.0.2 from Simplicity SDK 2025.12.3.

# SL-OPENTHREAD/2.7.2.0_GitHub-fb0446f53
Built with Simplicity SDK 2025.6.2.

# 2.4.7.0_GitHub-fb0446f53
Built with Gecko SDK 4.5.0.

# 2.4.6.0_GitHub-bdb394eb3
Built with Gecko SDK 4.4.6.

# SL-OPENTHREAD/2.4.4.0_GitHub-7074a43e4
Initial release with the new firmware builder. This firmware is identical to the firmware bundled with the OpenThread Border Router addon.
