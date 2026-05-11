#!/bin/bash
set -euo pipefail

GEM5=$HOME/gem5
SIM=$HOME/bioroofline-artifact/bioroofline/bwt_sim
RESULTS=$HOME/bioroofline-artifact/results/gem5
CFG=$GEM5/configs/deprecated/example/se.py
INDEX=1048576
QUERIES=10000

mkdir -p $RESULTS

run_exp() {
    local NAME=$1
    shift
    local EXTRA="${@:-}"
    local OUTDIR=$RESULTS/$NAME
    mkdir -p $OUTDIR
    echo "=============================="
    echo "Running: $NAME — $(date)"
    echo "=============================="
    $GEM5/build/X86/gem5.opt \
        --outdir=$OUTDIR \
        $CFG \
        --cmd $SIM \
        --options "$INDEX $QUERIES" \
        --cpu-type=TimingSimpleCPU \
        --caches \
        --l2cache \
        --l1d_size=32kB \
        --l1i_size=32kB \
        --l2_size=1MB \
        --mem-size=4GB \
        $EXTRA \
        > $OUTDIR/stdout.txt 2>&1
    echo "Done: $NAME exit=$? — $(date)"
    grep -E "simSeconds|\.ipc|demandMissRate::total" \
        $OUTDIR/stats.txt 2>/dev/null | head -5
    echo ""
}

echo "====================================="
echo "BioRoofline Extended GEM5 Experiments"
echo "Queries: $QUERIES per experiment"
echo "Started: $(date)"
echo "====================================="

run_exp "E1_baseline"
run_exp "E2_larger_L2"        "--l2_size=4MB"
run_exp "E3_with_L3"          "--l3_size=8MB --num-l3caches=1"
run_exp "E4_stride_prefetch"  "--l1d-hwp-type=StridePrefetcher"
run_exp "E5_bop_prefetch"     "--l1d-hwp-type=BOPPrefetcher"
run_exp "E6_small_L1"         "--l1d_size=16kB --l1i_size=16kB"
run_exp "E7_large_L1"         "--l1d_size=64kB --l1i_size=64kB"
run_exp "E8_high_assoc"       "--l1d_assoc=16 --l2_assoc=16"
run_exp "E9_L2_plus_stride"   "--l2_size=4MB --l1d-hwp-type=StridePrefetcher"
run_exp "E10_L2_plus_BOP"     "--l2_size=4MB --l1d-hwp-type=BOPPrefetcher"
run_exp "E11_cacheline_32"    "--cacheline_size=32"
run_exp "E12_cacheline_128"   "--cacheline_size=128"
run_exp "E13_DDR3"            "--mem-type=DDR3_1600_8x8"
run_exp "E14_DDR4"            "--mem-type=DDR4_2400_8x8"
run_exp "E15_DDR5"            "--mem-type=DDR5_4400_4x8"

echo "====================================="
echo "ALL 15 EXPERIMENTS COMPLETE: $(date)"
echo "====================================="
