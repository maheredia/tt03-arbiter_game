`timescale 1 ns/100 ps
`define SIMULATION
`include "top.v"

module top_tb();

//Local parameters:
localparam CLOCK_FREQ      = 1000; 
localparam PER2            = (1e9)/(2*CLOCK_FREQ);
localparam PRESCALER_COUNT = CLOCK_FREQ/4;
localparam TIMEOUT         = PRESCALER_COUNT*50;

//DUT signals:
reg        test_req1_in  ;
reg        test_req2_in  ;
reg        test_rst_in_n ;
reg        test_clk      ;
wire [3:0] test_leds_out ;
wire [7:0] test_io_out   ;

//Internal signals:
integer toggle_count = 0;
integer result = 0;
integer i = 0;
integer j = 0;
integer timeout_cntr = 0;
wire timeout_flag;
integer seed = 0;
wire [4:1] cd_verif;
reg  [4:1] cd_verif_dly = 4'b0000;
wire [4:1] cd_steps [4:1];
wire [3:0] w_verif;
reg  [3:0] w_verif_dly = 4'b0000;

//DUT:
maheredia_arbiter_game dut
(
    .io_in   ( {4'b0000, test_req2_in, test_req1_in, test_rst_in_n, test_clk} ),
    .io_out  ( test_io_out  )
);
assign test_leds_out = test_io_out[3:0];

//Verification logic
assign cd_steps[4] = 4'b1111;
assign cd_steps[3] = 4'b0111;
assign cd_steps[2] = 4'b0011;
assign cd_steps[1] = 4'b0001;

assign cd_verif[4] = (test_leds_out == 4'b1111);
assign cd_verif[3] = (test_leds_out == 4'b0111);
assign cd_verif[2] = (test_leds_out == 4'b0011);
assign cd_verif[1] = (test_leds_out == 4'b0001);

assign w_verif[3] = (test_leds_out == 4'b1000);
assign w_verif[2] = (test_leds_out == 4'b0100);
assign w_verif[1] = (test_leds_out == 4'b0010);
assign w_verif[0] = (test_leds_out == 4'b0001);

always @ (posedge test_clk)
begin
    cd_verif_dly <= cd_verif ;
    w_verif_dly  <= w_verif  ;
end

assign timeout_flag = (timeout_cntr == TIMEOUT);

//Clock:
always
begin
    test_clk = 1'b1;
    #PER2;
    test_clk = 1'b0;
    #PER2;
end

//Test:
initial 
begin
    $dumpfile("wf.vcd");
    $dumpvars(0, top_tb);
    test_req1_in  = $urandom(seed)%2;
    test_req2_in  = $urandom(seed)%2;

    for(j=1;j<=2;j=j+1)
    begin
        //Apply reset and verify countdown:
        test_rst_in_n = 1'b0;
        #(PER2*4);
        test_rst_in_n = 1'b1;
        #(PER2*4);

        //Verify countdown as: 1111 -> 0111 -> 0011 -> 0001
        for(i=4; i>=1; i=i-1)
        begin
            $display("COUNTDOWN %d...",i);
            toggle_count = 0;
            timeout_cntr = 0;
            while((test_leds_out == 4'b0000 || test_leds_out == cd_steps[i]) && (timeout_cntr < TIMEOUT))
            begin
                if((cd_verif[i]==1'b1) && (cd_verif_dly[i]==1'b0))
                begin
                    toggle_count = toggle_count+1;
                    $display("toggle_count = %d",toggle_count);
                end
                if(i==1 && toggle_count >= 4)
                begin
                    test_req1_in = 1'b1;
                    test_req2_in = 1'b1;
                    timeout_cntr = timeout_cntr+1;
                end
                #(PER2*2);
            end
            if(toggle_count != 4)
                $error("LED toggle failed at step %d!\n",i);
        end

        //Verify that output remains in zero:
        timeout_cntr = 0;
        while(timeout_cntr < TIMEOUT)
        begin
            if(test_leds_out != 4'b0000)
                $error("LEDs are toggling in wait state!");
            #(PER2*2);
            timeout_cntr = timeout_cntr+1;
        end

        //Check winner toggling:
        $display("\nWINNER %d...\n",j);
        toggle_count = 0;
        timeout_cntr = 0;
        test_req1_in = ~(j==1);
        test_req2_in = ~(j==2);

        //Wait until shif begins
        while((w_verif==4'b0000) && (timeout_cntr < TIMEOUT))
        begin
            #(PER2*2);
            timeout_cntr = timeout_cntr+1;
        end
        if(timeout_cntr == TIMEOUT)
            $fatal(1);
        else
            timeout_cntr = 0;
        #(PER2*2);
        test_req1_in = 1'b1;
        test_req2_in = 1'b1;
        while((test_leds_out != 4'b0000) && (timeout_cntr < TIMEOUT))
        begin
            if(j==1)
            begin
                if((w_verif==4'b0000) || ((w_verif_dly != w_verif) && (w_verif != {w_verif_dly[2:0],w_verif_dly[3]})))
                    $error("Error in winner 1 shift!\n\tw_verif = 0x%x\n\tw_verif_dly = 0x%x\n",w_verif,w_verif_dly);
            end
            else
            begin
                if((w_verif==4'b0000) || ((w_verif_dly != w_verif) && (w_verif != {w_verif_dly[0],w_verif_dly[3:1]})))
                    $error("Error in winner 2 shift!\n\tw_verif = 0x%x\n\tw_verif_dly = 0x%x\n",w_verif,w_verif_dly);
            end    
            #(PER2*2);
            timeout_cntr = timeout_cntr+1;
        end
        if(timeout_cntr == TIMEOUT)
            $fatal(1);
        else
            timeout_cntr = 0;
        //Verify that output remains zero:
        test_req1_in  = 1'b1;
        test_req2_in  = 1'b1;
        while(timeout_cntr < TIMEOUT)
        begin
            if(test_leds_out != 4'b0000)
                $error("LEDs are toggling after winner shift!");
            #(PER2*2);
            test_req1_in  = $urandom(seed)%2;
            test_req2_in  = $urandom(seed)%2;
            timeout_cntr = timeout_cntr+1;
        end
    end
    
    $finish();
end

endmodule