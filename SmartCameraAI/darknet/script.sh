#!/usr/bin/env sh

export LD_LIBRARY_PATH=/usr/local/cuda-9.0/lib64${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}
export PATH=/usr/local/cuda-9.0/bin${PATH:+:${PATH}}
export LD_LIBRARY_PATH=/usr/lib/aarch64-linux-gnu:/usr/lib/aarch64-linux-gnu/tegra${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}
export LD_LIBRARY_PATH=/usr/lib/atlas-base/atlas${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}
export LD_LIBRARY_PATH=/usr/lib/aarch64-linux-gnu/gstreamer-1.0${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}

