# Silicon Labs Firmware Builder — SONOFF Dongle Plus MG24 (OpenThread RCP)

> [!NOTE]
> **Unofficial community fork** of [NabuCasa/silabs-firmware-builder](https://github.com/NabuCasa/silabs-firmware-builder) — not affiliated with, maintained, or endorsed by Nabu Casa, Silicon Labs, or ITEAD/SONOFF. Compiled firmwares are intended solely for EFR32MG24 hardware and are provided as-is without warranty; flash at your own risk.

Production OpenThread RCP builds for the **SONOFF Dongle Plus MG24** (`EFR32MG24A420F1536IM48`) built on **Simplicity SDK 2026.6.2** (`OpenThread 3.1.2.0`) with **Arm Toolchain for Embedded (ATfE) LLVM 23.1.0**, full LTO, and bounded-wait software flow control.

## Prebuilt Releases

If you only want to flash the firmware without building it yourself, download the latest `.gbl` files from the [GitHub Releases](https://github.com/smnws/silabs-firmware-builder-sonoff-mg24/releases) page and jump straight to [Flashing](#flashing).

## SONOFF Dongle Plus MG24 Variants

Both variants share the same hardware configuration (`38.4 MHz` HFXO `CTUNE=130`, `EUSART1` on `PC1`/`PC2`, software flow control `XON`/`XOFF`, `WDOG0` hardware watchdog with crash dump, LLVM 23.1.0 `-O2` + `-flto` + `Omax.cfg`/`OmaxLTO.cfg`, and all three SDK stability patches):

| Variant | Manifest | Baudrate | NCP TX / VCOM RX Buffer | Notes |
| :--- | :--- | :---: | :---: | :--- |
| **Default (Recommended)** | [`dongle_plus_mg24_openthread_rcp.yaml`](manifests/sonoff/dongle_plus_mg24/dongle_plus_mg24_openthread_rcp.yaml) | `460800` | `4096 B` / `512 B` | Matches Nabu Casa ZBT-2 baudrate & stock buffer sizes (adapted for SW flow control) |
| **High-Speed (`1000000`)** | [`dongle_plus_mg24_openthread_rcp_1000000.yaml`](manifests/sonoff/dongle_plus_mg24/dongle_plus_mg24_openthread_rcp_1000000.yaml) | `1000000` | `8192 B` / `1024 B` | Higher UART throughput with doubled buffers |

### Key Firmware Fixes
* **Software flow-control watchdog fix** (`src/openthread_rcp/sdk_patches/uart_tx_bounded_wait_sw_flow.patch`): Stock SiSDK `nolock_uart_write()` spins indefinitely while `uart_context->xon == false`, starving the bare-metal OpenThread superloop and causing a `WDOG0` reset whenever the host holds `XOFF`. This patch caps continuous `XOFF` stalls at **50 ms** and total write duration at **150 ms** via `sl_sleeptimer_get_tick_count()`, propagates `SL_STATUS_TIMEOUT` through `uart_write()`, and lets `uart_tx_drop_on_timeout.patch` drop the stalled frame cleanly so the watchdog stays serviced.
* **Green Power RX filter fix** (`disable_gp_rx_filter.patch`): Prevents misclassification of zero-payload IEEE 802.15.4-2003 MAC commands.
* **Hardware watchdog** (`nabucasa/watchdog`): Enables `WDOG0` (~4 s reset, ~3 s warning interrupt) with crash dump reporting.

---

## Building Firmwares

### 1. Download ATfE LLVM 23.1.0 Toolchain
Supported on `x86_64` and `arm64`/`aarch64` Linux hosts (SHA-256 verified):

```bash
./tools/setup_toolchain.sh
```

### 2. Build with Docker
Run the build inside Nabu Casa's prebuilt container (which includes Simplicity SDK `2026.6.1` and `2026.6.2`):

```bash
# Default (460800 baud, recommended)
docker run --rm \
  -v "$(pwd):/repo" \
  -w /repo \
  --entrypoint /bin/bash \
  ghcr.io/nabucasa/silabs-firmware-builder:cf5d48af0aac8b31 \
  -c "
    export HOME=/tmp/home && mkdir -p \$HOME
    /opt/venv/bin/python3 -m tools.build_project \
      --manifest manifests/sonoff/dongle_plus_mg24/dongle_plus_mg24_openthread_rcp.yaml \
      --build-dir build/sonoff_mg24 \
      --output-dir outputs \
      --output gbl --output hex --output out
  "
```

To build the explicit `1000000` baud variant, pass `--manifest manifests/sonoff/dongle_plus_mg24/dongle_plus_mg24_openthread_rcp_1000000.yaml`.

Built `.gbl`, `.hex`, and `.out` files are written to `outputs/`.

---

## Flashing

Flash the generated `.gbl` with [`universal-silabs-flasher`](https://github.com/NabuCasa/universal-silabs-flasher):

```bash
universal-silabs-flasher \
  --device /dev/serial/by-id/usb-SONOFF_SONOFF_Dongle_Plus_MG24_...-if00-port0 \
  --bootloader-reset rts_dtr \
  flash \
  --firmware outputs/dongle_plus_mg24_openthread_rcp_3.1.2.0_GitHub-fb274efe6_gsdk_2026.6.2.gbl \
  --probe-methods spinel:460800,spinel:1000000
```

> [!NOTE]
> **Host-side OTBR Software Flow Control**: OpenThread's POSIX `HdlcInterface::InitAdapter()` calls `cfmakeraw()`, which clears Linux `IXON`/`IXOFF` every time the serial port is opened. If you rely on bidirectional `XON`/`XOFF` from the host, re-enable it on the TTY (`stty -F /dev/ttyACM0 ixon ixoff -ixany -crtscts`) after OTBR opens the port, or patch OTBR's `hdlc_interface.cpp` to support software flow control natively.

---

## Upstream Nabu Casa Reference

The project templates and manifests in this repository are generic and also support Home Assistant Connect ZBT-1/SkyConnect, ZBT-2, ZWA-2, and Yellow.

### Size Limits
Two optional `gbl` keys fail the build when an image does not fit:

- **`max_app_end`:** the application, including its ECDSA or CRC32 signature, must end at or below this address.
- **`max_size`:** the largest allowed GBL file size in bytes.

### Setting up Simplicity Studio (for development)
If you are developing using Simplicity Studio, note that each project can use a different SDK release. To manually manage SDKs:

1. Clone a specific version of the Gecko / Simplicity SDK into `~/SimplicityStudio/SDKs/`.
2. Open preferences, navigate to **Simplicity Studio > SDKs**, click **Add SDK...**, and browse to the folder.
3. Once added, select its entry and click **Add Extension...** to register extensions from this repo.
