SIM ?= icarus
TOPLEVEL_LANG ?= verilog

VERILOG_SOURCES += $(PWD)/tb.v $(PWD)/top.v $(PWD)/arbiter_game.v $(PWD)/arbiter_game_fsm.v $(PWD)/countdown.v $(PWD)/winner.v

TOPLEVEL = tb

MODULE = test

include $(shell cocotb-config --makefiles)/Makefile.sim
