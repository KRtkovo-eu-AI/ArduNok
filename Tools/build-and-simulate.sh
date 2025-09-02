#!/bin/bash
set -euo pipefail

SKETCH="Arduino/Firmware-ardunok/Firmware-ardunok.ino"
FQBN="arduino:avr:mega"
BUILD_DIR="build"
LIB_DIR="Arduino/Libraries"

arduino-cli core update-index
arduino-cli core install arduino:avr
arduino-cli lib update-index
arduino-cli lib install "Adafruit GFX Library" "Adafruit PCD8544 Nokia 5110 LCD library"

arduino-cli compile --fqbn "$FQBN" --build-path "$BUILD_DIR" --libraries "$LIB_DIR" "$SKETCH" | tee build.log

used=$(grep "Global variables use" build.log | awk '{print $5}')
max=$(grep "Global variables use" build.log | awk '{print $10}')
percent=$((used * 100 / max))
echo "Dynamic memory usage: ${percent}%"
if [ "$percent" -ge 95 ]; then
  echo "Memory usage exceeds safe threshold"
  exit 1
fi

if command -v simavr >/dev/null 2>&1; then
  if [ ! -f "$BUILD_DIR/Firmware-ardunok.ino.elf" ]; then
    echo "Firmware ELF not found"
    exit 1
  fi
  if ! timeout 5s simavr -m atmega2560 -f 16000000 "$BUILD_DIR/Firmware-ardunok.ino.elf"; then
    status=$?
    if [ "$status" -ne 124 ]; then
      echo "Simulation failed"
      exit "$status"
    fi
  fi
else
  echo "simavr not installed; skipping simulation"
fi
