import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, FallingEdge, Timer, ClockCycles
import random

@cocotb.test()
async def test_my_design(dut):
    dut._log.info("start")
    
    random.seed(0)
    
    #Test parameters:
    CLOCK_FREQ      = 1000
    PRESCALER_COUNT = CLOCK_FREQ//4
    TIMEOUT         = PRESCALER_COUNT*50
    
    #Countdown steps:
    cd_steps = [1,3,7,15]
    w_steps  = [1,2,4,8]
    
    #Do clock:
    clock = Clock(dut.clk, 1, units="us")
    cocotb.start_soon(clock.start())
    
    for j in range(1,3):
        dut._log.info("Apply reset and verify countdown")
        dut.req1_in.value  = random.randrange(0,2,1)
        dut.req2_in.value  = random.randrange(0,2,1)
        dut.rst_in_n.value = 0 
        await ClockCycles(dut.clk, 2)
        dut.rst_in_n.value = 1 
        await ClockCycles(dut.clk, 2)
        
        dut._log.info("Verify countdown as: 1111 -> 0111 -> 0011 -> 0001")
        cd_verif_dly = (dut.leds_out.value == cd_steps[-1])
        for i in reversed(range(1,5)):
            dut._log.info("COUNTDOWN %d...",i)
            toggle_count = 0
            timeout_cntr = 0
            while((dut.leds_out.value == 0 or dut.leds_out.value == cd_steps[i-1]) and (timeout_cntr < TIMEOUT)):
                cd_verif = (dut.leds_out.value == cd_steps[i-1])
                if((cd_verif==1) and (cd_verif_dly==0)):
                    toggle_count = toggle_count+1
                    dut._log.info("toggle_count = %d",toggle_count)
                if(i==1 and toggle_count >= 4):
                    dut.req1_in.value = 1
                    dut.req2_in.value = 1
                    timeout_cntr = timeout_cntr+1
                cd_verif_dly = cd_verif
                await ClockCycles(dut.clk, 1)
            #end while
            dut._log.info("timer = %d",timeout_cntr)
            dut._log.info("leds  = %d",dut.leds_out.value)
            assert (toggle_count == 4)
        #end for
        
        dut._log.info("Verify that output remains in zero")
        timeout_cntr = 0
        while(timeout_cntr < TIMEOUT):
            assert (dut.leds_out.value == 0)
            await ClockCycles(dut.clk, 1)
            timeout_cntr = timeout_cntr+1
        #end while
        
        dut._log.info("Check winner toggling")
        dut._log.info("\nWINNER %d...\n",j)
        toggle_count = 0
        timeout_cntr = 0
        dut.req1_in.value = 0 if(j==1) else 1
        dut.req2_in.value = 0 if(j==2) else 1
        
        dut._log.info("Wait until shif begins")
        while((dut.leds_out.value not in w_steps) and (timeout_cntr < TIMEOUT)):
            await ClockCycles(dut.clk, 1)
            timeout_cntr = timeout_cntr+1
        #end while  
        if(timeout_cntr == TIMEOUT):
            assert False
        else:
            timeout_cntr = 0
        await ClockCycles(dut.clk, 1)
        dut.req1_in.value = 1
        dut.req2_in.value = 1
        w_verif_dly = dut.leds_out.value
        while((dut.leds_out.value != 0) and (timeout_cntr < TIMEOUT)):
            if(j==1):
                w_verif_dly_shifted = (w_verif_dly<<1)%15
                assert not((dut.leds_out.value not in w_steps) or ((w_verif_dly != dut.leds_out.value) and (dut.leds_out.value != w_verif_dly_shifted)))
            else:
                w_verif_dly_shifted = (w_verif_dly>>1)%15 if(w_verif_dly>>1) else 8
                assert not((dut.leds_out.value not in w_steps) or ((w_verif_dly != dut.leds_out.value) and (dut.leds_out.value != w_verif_dly_shifted)))
            
            w_verif_dly = dut.leds_out.value
            await ClockCycles(dut.clk, 1)
            timeout_cntr = timeout_cntr+1
        #end while
        if(timeout_cntr == TIMEOUT):
            assert False
        else:
            timeout_cntr = 0
            
        dut._log.info("Verify that output remains zero\n\n")
        dut.req1_in.value = 1
        dut.req2_in.value = 1
        while(timeout_cntr < TIMEOUT):
            assert (dut.leds_out.value == 0)
            await ClockCycles(dut.clk, 1)
            test_req1_in = random.randrange(0,2,1) 
            test_req2_in = random.randrange(0,2,1) 
            timeout_cntr = timeout_cntr+1
        #end while
    #end for