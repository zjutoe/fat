#Gnuplot script to plot ls and data

set autoscale                        # scale axes automatically
unset log                              # remove any log-scaling
unset label                            # remove any previous labels 
set xtic auto                          # set xtics automatically 
set ytic auto                          # set ytics automatically
#set title "Force Deflection Data for a Beam and a Column"
set xlabel "Elapsed Cycles"

#  set key 0.01,100
#  set label "Yield Point" at 0.003,260	
#  set arrow from 0.0028,250 to 0.003,280

set terminal postscript enhanced mono dashed lw 1 "Helvetica" 16

set yr [0:250]

set ylabel "DDFG Width"

# 5000 ~ 6000

set xr [15000:16000]

set ylabel "Speedup / DDFG Width"
   
set output "tests/log/ls/c256s50_1k.eps"
     
plot \
   "tests/log/date/mrb.out.c256s50" using 1:5 title 'Speedup' with lines lt 3, \
      "tests/log/date/mrb.out.c256s50" using 1:4 title 'DDFG Width' with lines lt 1


