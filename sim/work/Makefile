VPU_HOME = ${PWD}/../../
export VPU_HOME

VPU_SIM_HOME = ${VPU_HOME}/sim
export VPU_SIM_HOME

#FILE_LISTS	+= $(VPU_HOME)/design/filelist.f
#PRECOMP_DUT_DIR = ${VPU_HOME}/sim/build_project/
FILE_LISTS	+= $(VPU_SIM_HOME)/env/compile.f

SIMULATOR	?= vcs
#RANDOM_SEED	?= auto
RANDOM_SEED	= 0
DUMP	?= off
GUI	?= off

BASE_TC = base_test

.PHONY: all cli gui base csv clean clean_all

all: base

base:
	make --eval=GUI=verdi --eval=DUMP=fsdb --eval=TC=$(BASE_TC) --eval=VCS_ARGS=+define+DEVEL_CXL  sim_$(SIMULATOR) TEST=base

CLEAN_TARGET	+= *.log
CLEAN_ALL_TARGET += *.log
CLEAN_ALL_TARGET += *.key

clean:
	rm -rf $(CLEAN_TARGET)

clean_all:
	make clean
	rm -rf $(CLEAN_ALL_TARGET)
	rm -rf $(addprefix */,$(CLEAN_ALL_TARGET))

include vcs.mk