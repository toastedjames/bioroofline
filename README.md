# BioRoofline: Cache-Aware Roofline Analysis of Memory Bottlenecks in Parallel Genomic Sequence Alignment Workloads

**Authors:** Somak Goswami (somakg63@vt.edu), Wu-Chun Feng (wfeng@vt.edu)  
**Institution:** Bradley Department of Electrical and Computer Engineering, Virginia Polytechnic Institute and State University, Blacksburg, Virginia, USA  
**Course:** CS/ECE 4504/5504 — Computer Organization  
**Paper (Overleaf):** https://www.overleaf.com/project/69feb2a2f7305a152e6576cb  

---

## Overview

This repository contains the complete artifact for the BioRoofline project — a cache-aware roofline analysis of the memory hierarchy bottleneck that causes parallel scaling collapse in BWA-MEM genomic sequence alignment.

Clinical whole-genome sequencing (WGS) pipelines are limited by a fundamental memory bottleneck: the BWA-MEM FM-index (5.7 GB for the human genome) exceeds all cache capacities, causing every parallel alignment thread to compete for shared DRAM bandwidth. We characterize this bottleneck using GEM5 architectural simulation and 15 controlled cache hierarchy experiments.

### Key Findings

| Finding | Result |
|---|---|
| Baseline IPC | 0.168 (CPU at 16.8% of peak) |
| L3 cache benefit | 0% — FM-index exceeds all L3 capacities |
| Larger L2 (4MB) | +40.1% IPC |
| Stride prefetcher | +2.8% IPC, −4.2% L1 miss rate |
| Combined L2 + Stride (best) | **+45.5% IPC** |
| 32-byte cache lines | +10.5% IPC (reduces bandwidth waste) |
| 128-byte cache lines | −8.6% IPC (worst configuration) |
| DDR5 vs DDR3 | +2.6% IPC |

---

## Repository Structure

```
bioroofline-artifact/
├── README.md                          # This file
├── Proposal-somakg63.pdf              # Original project proposal
├── environment/
│   └── versions.txt                   # Pinned software versions
├── bioroofline/
│   ├── bwt_sim.c                      # BWT FM-index access pattern simulator (source)
│   └── bwt_sim                        # Pre-compiled static binary for GEM5
├── workflow/
│   └── scripts/
│       ├── run_gem5_all.sh            # Runs original 5 GEM5 experiments
│       ├── run_gem5_extended.sh       # Runs all 15 GEM5 experiments
│       ├── run_gem5_parallel.sh       # Runs all 15 experiments in parallel
│       └── generate_figures.py        # Generates all paper figures
├── results/
│   └── gem5/
│       ├── E1_baseline/stats.txt      # Baseline (32KB L1, 1MB L2)
│       ├── E2_larger_L2/stats.txt     # 4MB L2
│       ├── E3_with_L3/stats.txt       # 8MB L3 added
│       ├── E4_stride_prefetch/stats.txt  # Stride prefetcher
│       ├── E5_bop_prefetch/stats.txt     # BOP prefetcher
│       ├── E6_small_L1/stats.txt      # 16KB L1
│       ├── E7_large_L1/stats.txt      # 64KB L1
│       ├── E8_high_assoc/stats.txt    # 16-way associativity
│       ├── E9_L2_plus_stride/stats.txt   # 4MB L2 + Stride (BEST)
│       ├── E10_L2_plus_BOP/stats.txt     # 4MB L2 + BOP
│       ├── E11_cacheline_32/stats.txt    # 32-byte cache line
│       ├── E12_cacheline_128/stats.txt   # 128-byte cache line (WORST)
│       ├── E13_DDR3/stats.txt         # DDR3-1600
│       ├── E14_DDR4/stats.txt         # DDR4-2400
│       └── E15_DDR5/stats.txt         # DDR5-4400
└── figures/
    ├── fig1_ipc_all15.pdf             # Figure 1: IPC all 15 experiments
    ├── fig2_miss_rate_all15.pdf       # Figure 2: L1 miss rate
    ├── fig3_exec_time_all15.pdf       # Figure 3: Execution time
    ├── fig4_roofline_all15.pdf        # Figure 4: CARM roofline plot
    └── fig5_category_comparison.pdf   # Figure 5: Category grouped comparison
```

---

## Requirements

### Hardware
- x86-64 Linux machine (tested on Arch Linux kernel 7.0.3, Intel Core Ultra 285H)
- Minimum 8 GB RAM (16 GB recommended for full workload)
- 2 GB free disk space

### Software
- **GEM5 v25.1.0.1** — [Build instructions](https://www.gem5.org/documentation/general_docs/building)
- **GCC 10+** with static linking support
- **Python 3.10+** with numpy, matplotlib, pandas
- BWA-MEM v0.7.17 (optional — for real pipeline only)
- SAMtools v1.15 (optional — for real pipeline only)

---

## Quick Start — Reproduce All GEM5 Results (20 minutes)

These steps reproduce all 15 simulation results and all figures.  
**No genome data download required.**

### Step 1 — Clone the repository

```bash
git clone https://github.com/toastedjames/bioroofline
cd bioroofline-artifact
```

### Step 2 — Build the BWT simulator

```bash
gcc -O2 -static \
    -o bioroofline/bwt_sim \
    bioroofline/bwt_sim.c

# Verify it is statically linked
file bioroofline/bwt_sim
# Expected: ELF 64-bit LSB executable, statically linked

# Test run
./bioroofline/bwt_sim 1048576 100
# Expected: BWT simulator: index=8 MB, queries=100
```

### Step 3 — Set your GEM5 path

```bash
export GEM5=/path/to/your/gem5

# Example for rlogin (Virginia Tech):
# export GEM5=/home/vt/somakg63/gem5_workspace/gem5

# Verify GEM5 binary exists
ls $GEM5/build/X86/gem5.opt
```

### Step 4 — Run all 15 GEM5 experiments

```bash
# Sequential (safer, ~20 min total)
bash workflow/scripts/run_gem5_extended.sh

# OR parallel (faster, ~5 min total, uses all CPU cores)
bash workflow/scripts/run_gem5_parallel.sh
```

Progress is shown as each experiment completes:
```
Running: E1_baseline — [timestamp]
Done: E1_baseline exit=0
  system.cpu.ipc = 0.168331
Running: E2_larger_L2 — [timestamp]
...
ALL 15 EXPERIMENTS COMPLETE
```

### Step 5 — Generate all figures

```bash
# Install Python dependencies
pip install numpy matplotlib pandas

# Generate figures
python3 workflow/scripts/generate_figures.py
```

Figures are saved to `figures/` as both `.pdf` and `.png`.

---

## Expected Results

If reproduction is successful, your results should match these values within ±1%:

| Exp. | Description | IPC | L1 Miss Rate | vs Baseline |
|---|---|---|---|---|
| E1 | Baseline (32KB L1, 1MB L2) | 0.1683 | 5.071% | — |
| E2 | Larger L2 (4MB) | 0.2358 | 5.071% | +40.1% |
| E3 | Add L3 (8MB) | 0.1683 | 5.071% | +0.0% |
| E4 | Stride prefetcher | 0.1731 | 4.858% | +2.8% |
| E5 | BOP prefetcher | 0.1723 | 4.892% | +2.4% |
| E6 | Small L1 (16KB) | 0.1682 | 5.118% | −0.1% |
| E7 | Large L1 (64KB) | 0.1686 | 4.987% | +0.1% |
| E8 | High associativity (16-way) | 0.1688 | 5.068% | +0.3% |
| **E9** | **L2 4MB + Stride (BEST)** | **0.2449** | **4.858%** | **+45.5%** |
| E10 | L2 4MB + BOP | 0.2434 | 4.892% | +44.6% |
| E11 | Cache line 32B | 0.1859 | 5.225% | +10.5% |
| E12 | Cache line 128B (WORST) | 0.1539 | 4.998% | −8.6% |
| E13 | DDR3-1600 | 0.1683 | 5.071% | +0.0% |
| E14 | DDR4-2400 | 0.1699 | 5.071% | +0.9% |
| E15 | DDR5-4400 | 0.1728 | 5.071% | +2.6% |

> **Tolerance:** Results should match within ±1% due to GEM5 version differences.  
> If larger differences appear, ensure you are using GEM5 v25.x with `TimingSimpleCPU`.

---

## BWT Simulator Description

`bioroofline/bwt_sim.c` models the FM-index memory access pattern of BWA-MEM genomic alignment.

**Biological basis:** BWA-MEM aligns DNA reads by performing LF-mapping backward search through the FM-index. Each step accesses two non-contiguous positions in the Occ array, creating irregular pointer-chasing behavior. The simulator replicates this two-access-per-step pattern.

**Parameters:**
- Index size: 512 MB (scaled from the 5.7 GB hg38 FM-index)
- Queries: 10,000 (simulating 10,000 DNA reads of 150 bp)
- Steps per query: 150 (modeling 150 bp Illumina read length)
- Total LF-mapping operations: 1,500,000

**Usage:**
```bash
./bioroofline/bwt_sim <index_size_longs> <num_queries>

# Default (used in all experiments):
./bioroofline/bwt_sim 1048576 10000

# Quick smoke test:
./bioroofline/bwt_sim 1048576 100
```

---

## GEM5 Configuration

All experiments use the following base configuration:

| Parameter | Value |
|---|---|
| GEM5 version | 25.1.0.1 |
| CPU model | TimingSimpleCPU |
| ISA | x86-64 |
| Simulation mode | Syscall Emulation (SE) |
| Clock | 1 GHz (simulated) |
| L1 I/D-cache | 32 KB, 8-way, 64-byte line (baseline) |
| L2 cache | 1 MB, 8-way (baseline) |
| Memory | 4 GB DDR4 |
| Cache line | 64 bytes (baseline) |
| Prefetcher | None (baseline) |

Each of the 15 experiments varies exactly one parameter from this baseline.

---

## Software Versions

See `environment/versions.txt` for the complete pinned version manifest.

| Software | Version |
|---|---|
| GEM5 | 25.1.0.1 |
| BWA-MEM | 0.7.17 |
| SAMtools | 1.15 |
| GATK | 4.3.0 |
| Python | 3.14.4 |
| numpy | 2.4.4 |
| matplotlib | 3.10.9 |
| OS | Arch Linux, kernel 7.0.3 |
| CPU | Intel Core Ultra 285H |

