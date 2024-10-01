RUN_DIR=OUTPUT
HEADER_PATH=/home/sg05060/VPU_Design/VPU/RTL/Header/VPU_PKG.svh
COMPILE_CMD='vcs'
COMPILE_OPTIONS='-full64 -debug_access+all -kdb -LDFLAGS -Wl,--no-as-needed'
COMPILE_VFLAGS='-sverilog +incdir+$(HEADER_PATH)'
#COMPILE_OPTIONS='-full64 -debug_access+all -kdb -LDFLAGS -Wl'
SIM_OPTIONS=''

VERDI_CMD='Verdi'
VERDI_OPTIONS=''

DC_CMD='dc_shell-xg-t'
DC_OPTIONS=''
VPU_HOME=
#LIB_PATH=/media/2/LogicLibraries
