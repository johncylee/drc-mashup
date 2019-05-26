#!/bin/bash

set -e

INDEV="hw:1,0"
OUTDEV="hw:2,0"
MIC_SAMPLE_RATE="48000"
TARGET_RATE="44100"
MIC_CALIBRATION="flat.txt"
IMPULSE=impulse-${MIC_SAMPLE_RATE}.pcm

run () {
    local CONFIG="$1"
    local PSPointsFile="$2"
    local BCInFile=impulse-${TARGET_RATE}.pcm
    local PSOutFile=$(basename "$CONFIG")
    PSOutFile="${PSOutFile%.drc}"

    if [ "$MIC_SAMPLE_RATE" != "$TARGET_RATE" ]; then
        sox -t f32 -r $MIC_SAMPLE_RATE -c 1 $IMPULSE \
            -t f32 ${BCInFile} rate -v $TARGET_RATE
    fi
    drc \
        --BCInFile=$BCInFile \
        --MCFilterType=M \
        --MCPointsFile="$MIC_CALIBRATION" \
        --MCOutFile=rmc.pcm \
        --PSPointsFile="$PSPointsFile" \
        --PSOutFile="${PSOutFile}.pcm" \
        "$CONFIG"
    sox -t f32 -r $TARGET_RATE -c 1 "${PSOutFile}.pcm" \
        -t wav ../"${PSOutFile}.wav"

    echo "Generated ../${PSOutFile}.wav"
}

run_all_conf () {
    KHZ=$(printf '%2.1f' "$((${TARGET_RATE}))e-3")
    for conf in erb minimal soft normal strong extreme insane; do
        run "${DRC_BASE}/config/${KHZ} kHz/${conf}-${KHZ}.drc" \
            "${DRC_BASE}/target/${KHZ} kHz/pa-${KHZ}.txt"
    done
}

DRC_BASE="/usr/share/drc"
./measure-noref 24 $MIC_SAMPLE_RATE 10 21000 45 2 $INDEV $OUTDEV $IMPULSE msrecsweep.wav
run_all_conf
