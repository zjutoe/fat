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

set output "tests/log/ls/plot_c256_all.eps"
plot "tests/log/ls/mrb.out.c256" using 1:4 title 'DDFG Width' with lines lt 2

set output "tests/log/date/plot_c256_all.eps"
plot "tests/log/date/mrb.out.c256" using 1:4 title 'DDFG Width' with lines lt 2

# 5000 ~ 6000

set xr [50000:55000]

set ylabel "Instruction Counts / DDFG Width"
   
set output "tests/log/ls/plot_c256_1k.eps"
     
plot \
   "tests/log/ls/mrb.out.c256" using 1:2 title 'Issued Instructions' with lines lt 3, \
      "tests/log/ls/mrb.out.c256" using 1:4 title 'DDFG Width' with lines lt 1
#      "tests/log/ls/mrb.out.c16" using 1:3 title 'Execution Cycles' with lines lt 3, \

	
set output "tests/log/date/plot_c256_1k.eps"

plot \
   "tests/log/date/mrb.out.c256" using 1:2 title 'Issued Instructions' with lines lt 3, \
      "tests/log/date/mrb.out.c256" using 1:4 title 'DDFG Width' with lines lt 1
#      "tests/log/date/mrb.out.c16" using 1:3 title 'Execution Cycles' with lines lt 3, \

	
