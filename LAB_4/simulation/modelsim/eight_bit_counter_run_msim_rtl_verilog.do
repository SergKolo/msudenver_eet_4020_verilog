transcript on
if {[file exists rtl_work]} {
	vdel -lib rtl_work -all
}
vlib rtl_work
vmap work rtl_work

vlog -vlog01compat -work work +incdir+/home/xieerqi/GIT/msudenver_eet_4020_verilog/LAB_4 {/home/xieerqi/GIT/msudenver_eet_4020_verilog/LAB_4/eight_bit_counter.v}

