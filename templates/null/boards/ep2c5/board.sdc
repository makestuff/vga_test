create_clock -period 20.000 [get_ports sysClk_in]   # 50MHz clock on pin 17
#create_clock -period 62.500 [get_ports sysClk_in]   # 16MHz clock on pin 91
derive_pll_clocks
