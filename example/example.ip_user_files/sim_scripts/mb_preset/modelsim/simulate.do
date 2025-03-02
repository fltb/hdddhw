onbreak {quit -f}
onerror {quit -f}

vsim -voptargs="+acc"  -L xpm -L axi_lite_ipif_v3_0_4 -L lib_cdc_v1_0_3 -L lib_pkg_v1_0_4 -L axi_timer_v2_0_33 -L xil_defaultlib -L lib_srl_fifo_v1_0_4 -L axi_uartlite_v2_0_35 -L interrupt_control_v3_1_5 -L axi_iic_v2_1_7 -L dist_mem_gen_v8_0_15 -L fifo_generator_v13_2_10 -L lib_fifo_v1_0_19 -L axi_quad_spi_v3_2_30 -L microblaze_v11_0_13 -L lmb_v10_v3_0_14 -L lmb_bram_if_cntlr_v4_0_24 -L blk_mem_gen_v8_4_8 -L generic_baseblocks_v2_1_2 -L axi_infrastructure_v1_1_0 -L axi_register_slice_v2_1_31 -L axi_data_fifo_v2_1_30 -L axi_crossbar_v2_1_32 -L axi_intc_v4_1_19 -L xlconcat_v2_1_6 -L mdm_v3_2_26 -L proc_sys_reset_v5_0_15 -L axi_gpio_v2_0_33 -L unisims_ver -L unimacro_ver -L secureip -lib xil_defaultlib xil_defaultlib.mb_preset xil_defaultlib.glbl

set NumericStdNoWarnings 1
set StdArithNoWarnings 1

do {wave.do}

view wave
view structure
view signals

do {mb_preset.udo}

run 1000ns

quit -force
