#!/bin/bash

set -e

INDEV="hw:1,0"
OUTDEV="hw:2,0"
MIC_SAMPLE_RATE="48000"
MIC_CALIBRATION="flat.txt"
IMPULSE=impulse-${MIC_SAMPLE_RATE}.pcm

run () {
    local TARGET_RATE="$1"
    local CONFIG="$2"
    local PSPointsFile="$3"
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

DRC_BASE="/usr/share/drc"
./measure-noref 24 $MIC_SAMPLE_RATE 10 21000 45 2 $INDEV $OUTDEV $IMPULSE
run 44100 "${DRC_BASE}/config/44.1 kHz/erb-44.1.drc" "${DRC_BASE}/target/44.1 kHz/pa-44.1.txt"
run 44100 "${DRC_BASE}/config/44.1 kHz/normal-44.1.drc" "${DRC_BASE}/target/44.1 kHz/pa-44.1.txt"
run 48000 "${DRC_BASE}/config/48.0 kHz/erb-48.0.drc" "${DRC_BASE}/target/48.0 kHz/pa-48.0.txt"
run 48000 "${DRC_BASE}/config/48.0 kHz/normal-48.0.drc" "${DRC_BASE}/target/48.0 kHz/pa-48.0.txt"
