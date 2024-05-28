# Struggles from last install
1. Black screen on boot, thought it was an AMDGPU driver issue because of 
dmesg entries, turned out not to have compiled in console framebuffer support.
(Although drivers are needed, the missing ones were for integrated graphics).
2. Integrated wifi and bluetooth not working, `lspci` shows available wireless and bluetooth
devices, `dmesg` shows loading failure because of a missing patch, fixed by compiling in
`mediatek/WIFI_MT7922_patch_mcu_1_1_hdr.bin` and `mediatek/BT_RAM_CODE_MT7922_1_1_hdr.bin` for 
wifi and bluetooth respectively.
3. Compared vanilla O2, O2+(fat)LTO, O3+(fat)LTO, O3+(fat)LTO+znver4, O2+(fat)LTO+znver4, O2+(fat)LTO wins on 
all benchmarks, although all differences were within noise, except LTO, which produces some percentages improvement statistically significant.