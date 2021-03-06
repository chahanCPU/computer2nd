# xvlog --sv FPU/fle/fle.sv
# xvlog --sv FPU/flt/flt.sv
# xvlog --sv FPU/feq/feq.sv
xvlog --sv constant.sv
xvlog --sv register.sv
xvlog --sv fetch.sv
xvlog --sv decode.sv
xvlog --sv execute.sv
# xvlog --sv writereg.sv
xvlog --sv top.sv
# xvlog --sv uart_tx.sv
# xvlog --sv top.sv
xvlog --sv test_cpu.sv
xvlog top_wrapper.v

echo `date`
