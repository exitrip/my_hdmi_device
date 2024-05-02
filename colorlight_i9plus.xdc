################################################################################
# IO constraints
################################################################################
# clk25:0
set_property PACKAGE_PIN K4 [get_ports {clk_25mhz}]
set_property IOSTANDARD LVCMOS33 [get_ports {clk_25mhz}]

# user_led:0
set_property PACKAGE_PIN A18 [get_ports {led}]
set_property IOSTANDARD LVCMOS33 [get_ports {led}]
# set_property DRIVE 12 [get_ports {led}]

# # sdram_clock:0
# set_property LOC E14 [get_ports {sdram_clock}]
# set_property IOSTANDARD LVCMOS33 [get_ports {sdram_clock}]

# # serial:0.tx
# set_property LOC P5 [get_ports {serial_tx}]
# set_property IOSTANDARD LVCMOS33 [get_ports {serial_tx}]

# # serial:0.rx
# set_property LOC V5 [get_ports {serial_rx}]
# set_property IOSTANDARD LVCMOS33 [get_ports {serial_rx}]

set_property PACKAGE_PIN AB6 [get_ports {hdmi_p[0]}]
set_property PACKAGE_PIN AA5 [get_ports {hdmi_n[0]}]
set_property PACKAGE_PIN AB7 [get_ports {hdmi_p[1]}]
set_property PACKAGE_PIN Y7 [get_ports {hdmi_n[1]}]
set_property PACKAGE_PIN W7 [get_ports {hdmi_p[2]}]
set_property PACKAGE_PIN Y8 [get_ports {hdmi_n[2]}]
set_property PACKAGE_PIN AB5 [get_ports {hdmi_p[3]}]
set_property PACKAGE_PIN AA4 [get_ports {hdmi_n[3]}]
set_property IOSTANDARD TMDS_33 [get_ports {hdmi_p[0]}]
set_property IOSTANDARD TMDS_33 [get_ports {hdmi_p[1]}]
set_property IOSTANDARD TMDS_33 [get_ports {hdmi_p[2]}]
set_property IOSTANDARD TMDS_33 [get_ports {hdmi_p[3]}]
set_property IOSTANDARD TMDS_33 [get_ports {hdmi_n[0]}]
set_property IOSTANDARD TMDS_33 [get_ports {hdmi_n[1]}]
set_property IOSTANDARD TMDS_33 [get_ports {hdmi_n[2]}]
set_property IOSTANDARD TMDS_33 [get_ports {hdmi_n[3]}]

set_property OFFCHIP_TERM NONE [get_ports hdmi_p[3]]
set_property OFFCHIP_TERM NONE [get_ports hdmi_p[2]]
set_property OFFCHIP_TERM NONE [get_ports hdmi_p[1]]
set_property OFFCHIP_TERM NONE [get_ports hdmi_p[0]]

# # sdram:0.a
# set_property LOC C20 [get_ports {sdram_a[0]}]
# set_property IOSTANDARD LVCMOS33 [get_ports {sdram_a[0]}]
# set_property SLEWRATE FAST [get_ports {sdram_a[0]}]

# # sdram:0.a
# set_property LOC C19 [get_ports {sdram_a[1]}]
# set_property IOSTANDARD LVCMOS33 [get_ports {sdram_a[1]}]
# set_property SLEWRATE FAST [get_ports {sdram_a[1]}]

# # sdram:0.a
# set_property LOC C13 [get_ports {sdram_a[2]}]
# set_property IOSTANDARD LVCMOS33 [get_ports {sdram_a[2]}]
# set_property SLEWRATE FAST [get_ports {sdram_a[2]}]

# # sdram:0.a
# set_property LOC F13 [get_ports {sdram_a[3]}]
# set_property IOSTANDARD LVCMOS33 [get_ports {sdram_a[3]}]
# set_property SLEWRATE FAST [get_ports {sdram_a[3]}]

# # sdram:0.a
# set_property LOC G13 [get_ports {sdram_a[4]}]
# set_property IOSTANDARD LVCMOS33 [get_ports {sdram_a[4]}]
# set_property SLEWRATE FAST [get_ports {sdram_a[4]}]

# # sdram:0.a
# set_property LOC G15 [get_ports {sdram_a[5]}]
# set_property IOSTANDARD LVCMOS33 [get_ports {sdram_a[5]}]
# set_property SLEWRATE FAST [get_ports {sdram_a[5]}]

# # sdram:0.a
# set_property LOC F14 [get_ports {sdram_a[6]}]
# set_property IOSTANDARD LVCMOS33 [get_ports {sdram_a[6]}]
# set_property SLEWRATE FAST [get_ports {sdram_a[6]}]

# # sdram:0.a
# set_property LOC F18 [get_ports {sdram_a[7]}]
# set_property IOSTANDARD LVCMOS33 [get_ports {sdram_a[7]}]
# set_property SLEWRATE FAST [get_ports {sdram_a[7]}]

# # sdram:0.a
# set_property LOC E13 [get_ports {sdram_a[8]}]
# set_property IOSTANDARD LVCMOS33 [get_ports {sdram_a[8]}]
# set_property SLEWRATE FAST [get_ports {sdram_a[8]}]

# # sdram:0.a
# set_property LOC E18 [get_ports {sdram_a[9]}]
# set_property IOSTANDARD LVCMOS33 [get_ports {sdram_a[9]}]
# set_property SLEWRATE FAST [get_ports {sdram_a[9]}]

# # sdram:0.a
# set_property LOC C14 [get_ports {sdram_a[10]}]
# set_property IOSTANDARD LVCMOS33 [get_ports {sdram_a[10]}]
# set_property SLEWRATE FAST [get_ports {sdram_a[10]}]

# # sdram:0.a
# set_property LOC A13 [get_ports {sdram_a[11]}]
# set_property IOSTANDARD LVCMOS33 [get_ports {sdram_a[11]}]
# set_property SLEWRATE FAST [get_ports {sdram_a[11]}]

# # sdram:0.dq
# set_property LOC F21 [get_ports {sdram_dq[0]}]
# set_property IOSTANDARD LVCMOS33 [get_ports {sdram_dq[0]}]
# set_property SLEWRATE FAST [get_ports {sdram_dq[0]}]

# # sdram:0.dq
# set_property LOC E22 [get_ports {sdram_dq[1]}]
# set_property IOSTANDARD LVCMOS33 [get_ports {sdram_dq[1]}]
# set_property SLEWRATE FAST [get_ports {sdram_dq[1]}]

# # sdram:0.dq
# set_property LOC F20 [get_ports {sdram_dq[2]}]
# set_property IOSTANDARD LVCMOS33 [get_ports {sdram_dq[2]}]
# set_property SLEWRATE FAST [get_ports {sdram_dq[2]}]

# # sdram:0.dq
# set_property LOC E21 [get_ports {sdram_dq[3]}]
# set_property IOSTANDARD LVCMOS33 [get_ports {sdram_dq[3]}]
# set_property SLEWRATE FAST [get_ports {sdram_dq[3]}]

# # sdram:0.dq
# set_property LOC F19 [get_ports {sdram_dq[4]}]
# set_property IOSTANDARD LVCMOS33 [get_ports {sdram_dq[4]}]
# set_property SLEWRATE FAST [get_ports {sdram_dq[4]}]

# # sdram:0.dq
# set_property LOC D22 [get_ports {sdram_dq[5]}]
# set_property IOSTANDARD LVCMOS33 [get_ports {sdram_dq[5]}]
# set_property SLEWRATE FAST [get_ports {sdram_dq[5]}]

# # sdram:0.dq
# set_property LOC E19 [get_ports {sdram_dq[6]}]
# set_property IOSTANDARD LVCMOS33 [get_ports {sdram_dq[6]}]
# set_property SLEWRATE FAST [get_ports {sdram_dq[6]}]

# # sdram:0.dq
# set_property LOC D21 [get_ports {sdram_dq[7]}]
# set_property IOSTANDARD LVCMOS33 [get_ports {sdram_dq[7]}]
# set_property SLEWRATE FAST [get_ports {sdram_dq[7]}]

# # sdram:0.dq
# set_property LOC K21 [get_ports {sdram_dq[8]}]
# set_property IOSTANDARD LVCMOS33 [get_ports {sdram_dq[8]}]
# set_property SLEWRATE FAST [get_ports {sdram_dq[8]}]

# # sdram:0.dq
# set_property LOC L21 [get_ports {sdram_dq[9]}]
# set_property IOSTANDARD LVCMOS33 [get_ports {sdram_dq[9]}]
# set_property SLEWRATE FAST [get_ports {sdram_dq[9]}]

# # sdram:0.dq
# set_property LOC K22 [get_ports {sdram_dq[10]}]
# set_property IOSTANDARD LVCMOS33 [get_ports {sdram_dq[10]}]
# set_property SLEWRATE FAST [get_ports {sdram_dq[10]}]

# # sdram:0.dq
# set_property LOC M21 [get_ports {sdram_dq[11]}]
# set_property IOSTANDARD LVCMOS33 [get_ports {sdram_dq[11]}]
# set_property SLEWRATE FAST [get_ports {sdram_dq[11]}]

# # sdram:0.dq
# set_property LOC L20 [get_ports {sdram_dq[12]}]
# set_property IOSTANDARD LVCMOS33 [get_ports {sdram_dq[12]}]
# set_property SLEWRATE FAST [get_ports {sdram_dq[12]}]

# # sdram:0.dq
# set_property LOC M22 [get_ports {sdram_dq[13]}]
# set_property IOSTANDARD LVCMOS33 [get_ports {sdram_dq[13]}]
# set_property SLEWRATE FAST [get_ports {sdram_dq[13]}]

# # sdram:0.dq
# set_property LOC N20 [get_ports {sdram_dq[14]}]
# set_property IOSTANDARD LVCMOS33 [get_ports {sdram_dq[14]}]
# set_property SLEWRATE FAST [get_ports {sdram_dq[14]}]

# # sdram:0.dq
# set_property LOC M20 [get_ports {sdram_dq[15]}]
# set_property IOSTANDARD LVCMOS33 [get_ports {sdram_dq[15]}]
# set_property SLEWRATE FAST [get_ports {sdram_dq[15]}]

# # sdram:0.dq
# set_property LOC B18 [get_ports {sdram_dq[16]}]
# set_property IOSTANDARD LVCMOS33 [get_ports {sdram_dq[16]}]
# set_property SLEWRATE FAST [get_ports {sdram_dq[16]}]

# # sdram:0.dq
# set_property LOC D20 [get_ports {sdram_dq[17]}]
# set_property IOSTANDARD LVCMOS33 [get_ports {sdram_dq[17]}]
# set_property SLEWRATE FAST [get_ports {sdram_dq[17]}]

# # sdram:0.dq
# set_property LOC A19 [get_ports {sdram_dq[18]}]
# set_property IOSTANDARD LVCMOS33 [get_ports {sdram_dq[18]}]
# set_property SLEWRATE FAST [get_ports {sdram_dq[18]}]

# # sdram:0.dq
# set_property LOC A21 [get_ports {sdram_dq[19]}]
# set_property IOSTANDARD LVCMOS33 [get_ports {sdram_dq[19]}]
# set_property SLEWRATE FAST [get_ports {sdram_dq[19]}]

# # sdram:0.dq
# set_property LOC A20 [get_ports {sdram_dq[20]}]
# set_property IOSTANDARD LVCMOS33 [get_ports {sdram_dq[20]}]
# set_property SLEWRATE FAST [get_ports {sdram_dq[20]}]

# # sdram:0.dq
# set_property LOC B21 [get_ports {sdram_dq[21]}]
# set_property IOSTANDARD LVCMOS33 [get_ports {sdram_dq[21]}]
# set_property SLEWRATE FAST [get_ports {sdram_dq[21]}]

# # sdram:0.dq
# set_property LOC C22 [get_ports {sdram_dq[22]}]
# set_property IOSTANDARD LVCMOS33 [get_ports {sdram_dq[22]}]
# set_property SLEWRATE FAST [get_ports {sdram_dq[22]}]

# # sdram:0.dq
# set_property LOC B22 [get_ports {sdram_dq[23]}]
# set_property IOSTANDARD LVCMOS33 [get_ports {sdram_dq[23]}]
# set_property SLEWRATE FAST [get_ports {sdram_dq[23]}]

# # sdram:0.dq
# set_property LOC G21 [get_ports {sdram_dq[24]}]
# set_property IOSTANDARD LVCMOS33 [get_ports {sdram_dq[24]}]
# set_property SLEWRATE FAST [get_ports {sdram_dq[24]}]

# # sdram:0.dq
# set_property LOC G22 [get_ports {sdram_dq[25]}]
# set_property IOSTANDARD LVCMOS33 [get_ports {sdram_dq[25]}]
# set_property SLEWRATE FAST [get_ports {sdram_dq[25]}]

# # sdram:0.dq
# set_property LOC H20 [get_ports {sdram_dq[26]}]
# set_property IOSTANDARD LVCMOS33 [get_ports {sdram_dq[26]}]
# set_property SLEWRATE FAST [get_ports {sdram_dq[26]}]

# # sdram:0.dq
# set_property LOC H22 [get_ports {sdram_dq[27]}]
# set_property IOSTANDARD LVCMOS33 [get_ports {sdram_dq[27]}]
# set_property SLEWRATE FAST [get_ports {sdram_dq[27]}]

# # sdram:0.dq
# set_property LOC J20 [get_ports {sdram_dq[28]}]
# set_property IOSTANDARD LVCMOS33 [get_ports {sdram_dq[28]}]
# set_property SLEWRATE FAST [get_ports {sdram_dq[28]}]

# # sdram:0.dq
# set_property LOC J22 [get_ports {sdram_dq[29]}]
# set_property IOSTANDARD LVCMOS33 [get_ports {sdram_dq[29]}]
# set_property SLEWRATE FAST [get_ports {sdram_dq[29]}]

# # sdram:0.dq
# set_property LOC G20 [get_ports {sdram_dq[30]}]
# set_property IOSTANDARD LVCMOS33 [get_ports {sdram_dq[30]}]
# set_property SLEWRATE FAST [get_ports {sdram_dq[30]}]

# # sdram:0.dq
# set_property LOC J21 [get_ports {sdram_dq[31]}]
# set_property IOSTANDARD LVCMOS33 [get_ports {sdram_dq[31]}]
# set_property SLEWRATE FAST [get_ports {sdram_dq[31]}]

# # sdram:0.we_n
# set_property LOC D17 [get_ports {sdram_we_n}]
# set_property IOSTANDARD LVCMOS33 [get_ports {sdram_we_n}]
# set_property SLEWRATE FAST [get_ports {sdram_we_n}]

# # sdram:0.ras_n
# set_property LOC A14 [get_ports {sdram_ras_n}]
# set_property IOSTANDARD LVCMOS33 [get_ports {sdram_ras_n}]
# set_property SLEWRATE FAST [get_ports {sdram_ras_n}]

# # sdram:0.cas_n
# set_property LOC D14 [get_ports {sdram_cas_n}]
# set_property IOSTANDARD LVCMOS33 [get_ports {sdram_cas_n}]
# set_property SLEWRATE FAST [get_ports {sdram_cas_n}]

# # sdram:0.ba
# set_property LOC D19 [get_ports {sdram_ba[0]}]
# set_property IOSTANDARD LVCMOS33 [get_ports {sdram_ba[0]}]
# set_property SLEWRATE FAST [get_ports {sdram_ba[0]}]

# # sdram:0.ba
# set_property LOC B13 [get_ports {sdram_ba[1]}]
# set_property IOSTANDARD LVCMOS33 [get_ports {sdram_ba[1]}]
# set_property SLEWRATE FAST [get_ports {sdram_ba[1]}]


################################################################################
# Design constraints
################################################################################

################################################################################
# Clock constraints
################################################################################


create_clock -name clk_25mhz -period 40.0 -waveform {0.000 20.000} [get_ports clk_25mhz]

# set_clock_groups -group [get_clocks -include_generated_clocks -of [get_nets sys_clk]] -group [get_clocks -include_generated_clocks -of [get_nets main_crg_clkin]] -asynchronous

################################################################################
# False path constraints
################################################################################


# set_false_path -quiet -through [get_nets -hierarchical -filter {mr_ff == TRUE}]

# set_false_path -quiet -to [get_pins -filter {REF_PIN_NAME == PRE} -of_objects [get_cells -hierarchical -filter {ars_ff1 == TRUE || ars_ff2 == TRUE}]]

# set_max_delay 2 -quiet -from [get_pins -filter {REF_PIN_NAME == C} -of_objects [get_cells -hierarchical -filter {ars_ff1 == TRUE}]] -to [get_pins -filter {REF_PIN_NAME == D} -of_objects [get_cells -hierarchical -filter {ars_ff2 == TRUE}]]