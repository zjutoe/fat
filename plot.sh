#!/bin/bash

find tests/log -name "*.eps" | xargs rm 

for f in tests/log/*/mrb.out.c*; do

# set yr [0:250]
gnuplot <<EOF
load "plot_common.p"

set ylabel "DDFG Width"
set output "${f}_all.eps"
plot "$f" using 1:4 title "DDFG Width" with lines lt 2

set xr [15000:20000]
set ylabel "Speedup / DDFG Width"
set output "${f}_1k.eps"

plot  "$f" using 1:5 title "Speedup" with lines lt 3, \
      "$f" using 1:4 title "DDFG Width" with lines lt 1

EOF



done
