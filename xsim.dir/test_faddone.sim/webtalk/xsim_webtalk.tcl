webtalk_init -webtalk_dir /home/yamaguchi/Floating_Point_Addr/xsim.dir/test_faddone.sim/webtalk/
webtalk_register_client -client project
webtalk_add_data -client project -key date_generated -value "Thu Jun  8 16:51:51 2017" -context "software_version_and_target_device"
webtalk_add_data -client project -key product_version -value "XSIM v2016.4 (64-bit)" -context "software_version_and_target_device"
webtalk_add_data -client project -key build_version -value "1756540" -context "software_version_and_target_device"
webtalk_add_data -client project -key os_platform -value "LIN64" -context "software_version_and_target_device"
webtalk_add_data -client project -key registration_id -value "211142045_1777515821_210626051_443" -context "software_version_and_target_device"
webtalk_add_data -client project -key tool_flow -value "xsim" -context "software_version_and_target_device"
webtalk_add_data -client project -key beta -value "FALSE" -context "software_version_and_target_device"
webtalk_add_data -client project -key route_design -value "FALSE" -context "software_version_and_target_device"
webtalk_add_data -client project -key target_family -value "not_applicable" -context "software_version_and_target_device"
webtalk_add_data -client project -key target_device -value "not_applicable" -context "software_version_and_target_device"
webtalk_add_data -client project -key target_package -value "not_applicable" -context "software_version_and_target_device"
webtalk_add_data -client project -key target_speed -value "not_applicable" -context "software_version_and_target_device"
webtalk_add_data -client project -key random_id -value "48fd524467d6501097bd2592607c6b2f" -context "software_version_and_target_device"
webtalk_add_data -client project -key project_id -value "5c9c7606-9f20-4e40-9223-934dd2484aca" -context "software_version_and_target_device"
webtalk_add_data -client project -key project_iteration -value "40" -context "software_version_and_target_device"
webtalk_add_data -client project -key os_name -value "Ubuntu" -context "user_environment"
webtalk_add_data -client project -key os_release -value "Ubuntu 14.04.5 LTS" -context "user_environment"
webtalk_add_data -client project -key cpu_name -value "Intel(R) Core(TM) i7-4610M CPU @ 3.00GHz" -context "user_environment"
webtalk_add_data -client project -key cpu_speed -value "3600.585 MHz" -context "user_environment"
webtalk_add_data -client project -key total_processors -value "1" -context "user_environment"
webtalk_add_data -client project -key system_ram -value "16.000 GB" -context "user_environment"
webtalk_register_client -client xsim
webtalk_add_data -client xsim -key runall -value "true" -context "xsim\\command_line_options"
webtalk_add_data -client xsim -key Command -value "xsim" -context "xsim\\command_line_options"
webtalk_add_data -client xsim -key runtime -value "1 ns" -context "xsim\\usage"
webtalk_add_data -client xsim -key iteration -value "0" -context "xsim\\usage"
webtalk_add_data -client xsim -key Simulation_Time -value "0.00_sec" -context "xsim\\usage"
webtalk_add_data -client xsim -key Simulation_Memory -value "135436_KB" -context "xsim\\usage"
webtalk_transmit -clientid 1990158969 -regid "211142045_1777515821_210626051_443" -xml /home/yamaguchi/Floating_Point_Addr/xsim.dir/test_faddone.sim/webtalk/usage_statistics_ext_xsim.xml -html /home/yamaguchi/Floating_Point_Addr/xsim.dir/test_faddone.sim/webtalk/usage_statistics_ext_xsim.html -wdm /home/yamaguchi/Floating_Point_Addr/xsim.dir/test_faddone.sim/webtalk/usage_statistics_ext_xsim.wdm -intro "<H3>XSIM Usage Report</H3><BR>"
webtalk_terminate
