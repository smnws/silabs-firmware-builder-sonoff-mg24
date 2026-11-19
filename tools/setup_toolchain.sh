#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
TOOLCHAIN_DIR="${REPO_ROOT}/toolchains"
ATFE_VER="23.1.0"
RELEASE_URL="https://github.com/arm/arm-toolchain/releases/download/release-${ATFE_VER}-ATfE"

case "$(uname -m)" in
    x86_64|amd64)
        ARCH="x86_64"
        ATFE_SHA256="a7be511613af15151c93961ad39c8cf9ae6889a453c8b547f42f4051a416dc8e"
        ;;
    aarch64|arm64)
        ARCH="AArch64"
        ATFE_SHA256="df3b055d05659d8fda710d820e6c1ceff7bca3234c5067abe82a16e781d8de99"
        ;;
    *)
        echo "Unsupported host architecture: $(uname -m)" >&2
        exit 1
        ;;
esac

NEWLIB_SHA256="fbf7722f32ffc42d76800a7facfb9660636963ce2ed1eebe929f2274c2401edc"
NEWLIB_NANO_SHA256="7b3919c352a2528d990c1c12fbc8e2a8f45e6c22e50ae6230c7383dfe469036a"

BASE_NAME="ATfE-${ATFE_VER}-Linux-${ARCH}"
NEWLIB_TAR="ATfE-newlib-overlay-${ATFE_VER}.tar.xz"
NEWLIB_NANO_TAR="ATfE-newlib-nano-overlay-${ATFE_VER}.tar.xz"

mkdir -p "${TOOLCHAIN_DIR}"
cd "${TOOLCHAIN_DIR}"

if [ -x "${BASE_NAME}/bin/clang" ] && [ -f "${BASE_NAME}/bin/newlib.cfg" ] && [ -f "${BASE_NAME}/bin/newlib-nano.cfg" ]; then
    echo "Toolchain ${BASE_NAME} is already downloaded and configured."
    exit 0
fi

TMP_DIR="$(mktemp -d "${TOOLCHAIN_DIR}/.${BASE_NAME}.tmp.XXXXXX")"
cleanup() {
    rm -rf "${TMP_DIR}"
}
trap cleanup EXIT

CURL_OPTS=(-fsSL --retry 5 --retry-delay 2)
if curl --help all 2>/dev/null | grep -q -- --retry-all-errors; then
    CURL_OPTS+=(--retry-all-errors)
else
    CURL_OPTS+=(--retry-connrefused)
fi

echo "Downloading Arm Toolchain for Embedded (ATfE) ${ATFE_VER} (${ARCH})..."
curl "${CURL_OPTS[@]}" -o "${TMP_DIR}/${BASE_NAME}.tar.xz" "${RELEASE_URL}/${BASE_NAME}.tar.xz"
curl "${CURL_OPTS[@]}" -o "${TMP_DIR}/${NEWLIB_TAR}" "${RELEASE_URL}/${NEWLIB_TAR}"
curl "${CURL_OPTS[@]}" -o "${TMP_DIR}/${NEWLIB_NANO_TAR}" "${RELEASE_URL}/${NEWLIB_NANO_TAR}"

echo "Verifying SHA-256 checksums..."
(cd "${TMP_DIR}" && sha256sum -c <<EOF
${ATFE_SHA256}  ${BASE_NAME}.tar.xz
${NEWLIB_SHA256}  ${NEWLIB_TAR}
${NEWLIB_NANO_SHA256}  ${NEWLIB_NANO_TAR}
EOF
)

echo "Extracting toolchain and runtime overlays..."
tar -xf "${TMP_DIR}/${BASE_NAME}.tar.xz" -C "${TMP_DIR}"
tar -xf "${TMP_DIR}/${NEWLIB_TAR}" -C "${TMP_DIR}/${BASE_NAME}"
tar -xf "${TMP_DIR}/${NEWLIB_NANO_TAR}" -C "${TMP_DIR}/${BASE_NAME}"

test -x "${TMP_DIR}/${BASE_NAME}/bin/clang"
test -f "${TMP_DIR}/${BASE_NAME}/bin/newlib.cfg"
test -f "${TMP_DIR}/${BASE_NAME}/bin/newlib-nano.cfg"

rm -rf "${TOOLCHAIN_DIR}/${BASE_NAME}"
mv "${TMP_DIR}/${BASE_NAME}" "${TOOLCHAIN_DIR}/${BASE_NAME}"

echo "Toolchain setup complete at ${TOOLCHAIN_DIR}/${BASE_NAME}"
