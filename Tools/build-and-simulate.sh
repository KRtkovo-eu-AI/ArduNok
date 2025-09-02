#!/bin/bash
set -euo pipefail

SKETCH="Arduino/Firmware-ardunok/Firmware-ardunok.ino"
FQBN="arduino:avr:mega"
BUILD_DIR="build"

arduino-cli core update-index
arduino-cli core install arduino:avr
arduino-cli compile --fqbn "$FQBN" --build-path "$BUILD_DIR" "$SKETCH" | tee build.log

used=$(grep "Global variables use" build.log | awk '{print $5}')
max=$(grep "Global variables use" build.log | awk '{print $10}')
percent=$((used * 100 / max))
echo "Dynamic memory usage: ${percent}%"
if [ "$percent" -ge 95 ]; then
  echo "Memory usage exceeds safe threshold"
  exit 1
fi

if command -v simavr >/dev/null 2>&1; then
  simavr -m atmega2560 -f 16000000 "$BUILD_DIR/Firmware-ardunok.ino.elf" &
  pid=$!
  sleep 5
  kill $pid || true
else
  echo "simavr not installed; skipping simulation"
fi
