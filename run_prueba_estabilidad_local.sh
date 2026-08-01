#!/bin/bash
set -e

export C_INCLUDE_PATH=/tmp/so-commons-library/src:${C_INCLUDE_PATH}
export LIBRARY_PATH=/tmp/so-commons-library/src/build:${LIBRARY_PATH}
export LD_LIBRARY_PATH=/tmp/so-commons-library/src/build:${LD_LIBRARY_PATH}

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$REPO_DIR"

echo "========================================="
echo "  RECOMPILANDO MÓDULOS"
echo "========================================="
make -C utils clean && make -C utils
make -C kernel_memory clean && make -C kernel_memory
make -C kernel_scheduler clean && make -C kernel_scheduler
make -C cpu clean && make -C cpu
make -C memory_stick clean && make -C memory_stick
make -C swap clean && make -C swap
make -C io clean && make -C io

echo ""
echo "========================================="
echo "  LIMPIANDO PROCESOS PREVIOS"
echo "========================================="
pkill -9 -f "bin/kernel_memory" || true
pkill -9 -f "bin/kernel_scheduler" || true
pkill -9 -f "bin/cpu" || true
pkill -9 -f "bin/memory_stick" || true
pkill -9 -f "bin/swap" || true
pkill -9 -f "bin/io" || true
sleep 1

SCRIPT_INIT="${1:-ES3_1.prc}"

echo ""
echo "========================================="
echo "  INICIANDO ENTORNO (4 CPUs, 4 MS 2048B)"
echo "========================================="

# 1. Kernel Memory
echo "[1/6] Iniciando Kernel Memory..."
./kernel_memory/bin/kernel_memory kernel_memory/kernel_memory.config &
sleep 1

# 2. Kernel Scheduler
echo "[2/6] Iniciando Kernel Scheduler ($SCRIPT_INIT)..."
./kernel_scheduler/bin/kernel_scheduler kernel_scheduler/kernel_scheduler.config "$SCRIPT_INIT" &
sleep 1

# 3. 4 Memory Sticks de 2048B
echo "[3/6] Iniciando 4 Memory Sticks de 2048B..."
./memory_stick/bin/memory_stick memory_stick/memory_stick1.config 2048 &
sleep 1
./memory_stick/bin/memory_stick memory_stick/memory_stick2.config 2048 &
sleep 1
./memory_stick/bin/memory_stick memory_stick/memory_stick3.config 2048 &
sleep 1
./memory_stick/bin/memory_stick memory_stick/memory_stick4.config 2048 &
sleep 1

# 4. IO
echo "[4/6] Iniciando módulos IO (STDIN, STDOUT, SLEEP)..."
./io/bin/io io/io.config STDIN &
./io/bin/io io/io.config STDOUT &
./io/bin/io io/io.config SLEEP &
sleep 1

# 5. SWAP
echo "[5/6] Iniciando SWAP..."
./swap/bin/swap swap/swap.config &
sleep 1

# 6. 4 CPUs
echo "[6/6] Iniciando 4 CPUs (CPU 1, CPU 2, CPU 3 y CPU 4)..."
./cpu/bin/cpu cpu/cpu.config 1 &
./cpu/bin/cpu cpu/cpu.config 2 &
./cpu/bin/cpu cpu/cpu.config 3 &
./cpu/bin/cpu cpu/cpu.config 4 &
sleep 1

echo "========================================="
echo "  TODOS LOS MÓDULOS INICIADOS EXITOSAMENTE"
echo "========================================="
