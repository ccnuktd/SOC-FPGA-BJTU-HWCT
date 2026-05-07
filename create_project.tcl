#/*
# * Date           Author       Notes
# * 2023-06-20     Lyons        first version
# */

# ##############################################
# set project name & set chip #
# ##############################################

set prj_name "soc-fpga"
set prj_part_name "xc7k325tffg900-2"

# ##############################################
# change work path & create project #
# ##############################################

set proj_dir [file dirname [info script]]

cd $proj_dir

set prj_path "$proj_dir/project"
set prj_source "$proj_dir"

create_project $prj_name $prj_path -part $prj_part_name -force

# ##############################################
# add rtl design file #
# ##############################################

add_files [glob $prj_source/rtl/core/*.v]
add_files [glob $prj_source/rtl/perips/*.v]
add_files [glob $prj_source/rtl/soc/*.v]
add_files [glob $prj_source/rtl/utils/*.v]
add_files [glob $prj_source/rtl/*.v]

# ##############################################
# add Xilinx IP library #
# ##############################################

set ip_names [list \
    blk_mem_gen_0 \
    clk_wiz_0 \
]

set ip_xci_files [list]
foreach ip_name $ip_names {
    set ip_xci [file normalize "$prj_source/ipdefs/$ip_name/$ip_name.xci"]
    if {![file exists $ip_xci]} {
        error "Cannot find IP definition: $ip_xci"
    }
    lappend ip_xci_files $ip_xci
}

set imported_files [import_files -fileset sources_1 -norecurse $ip_xci_files]

set blk_mem_coe [file normalize "$prj_source/ipdefs/blk_mem_gen_0/rom.coe"]
if {![file exists $blk_mem_coe]} {
    error "Cannot find blk_mem_gen_0 COE file: $blk_mem_coe"
}

set blk_mem_project_dir [file normalize "$prj_path/$prj_name.srcs/sources_1/ip/blk_mem_gen_0"]
file mkdir $blk_mem_project_dir
file copy -force $blk_mem_coe [file join $blk_mem_project_dir rom.coe]

set ips [get_ips]
if {[llength $ips] > 0} {
    set blk_mem_ip [get_ips blk_mem_gen_0 -quiet]
    if {[llength $blk_mem_ip] > 0} {
        set_property CONFIG.Coe_File $blk_mem_coe $blk_mem_ip
    }

    upgrade_ip $ips
    generate_target all $ips
    export_ip_user_files -of_objects $ips -no_script -sync -force -quiet
}

# ##############################################
# add constraint file #
# ##############################################

add_files -fileset constrs_1 -norecurse $prj_source/chip_pin.xdc

# ##############################################
# add testbench file #
# ##############################################

set_property SOURCE_SET sources_1 [get_filesets sim_1]

add_files -fileset sim_1 -norecurse "$prj_source/tb/core_data_monitor_tb.v"
add_files -fileset sim_1 -norecurse "$prj_source/tb/core_uart_monitor_tb.v"
add_files -fileset sim_1 -norecurse "$prj_source/tb/core_uart_iap_tb.v"
add_files -fileset sim_1 -norecurse "$prj_source/tb/core_tb.v"

# ##############################################
# check & set design top #
# ##############################################

set_property simulator_language Verilog [current_project]

update_compile_order -fileset sources_1
update_compile_order -fileset sim_1

# ##############################################
# simulate all signals #
# ##############################################

set_property -name {xsim.simulate.log_all_signals} -value {true} -objects [get_filesets sim_1]
