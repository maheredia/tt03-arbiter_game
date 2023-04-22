`timescale 1 ns/100 ps
`include "arbiter_game_fsm.v"

module arbiter_game_fsm_tb();

//Parámetros locales del test:
localparam PER2 = 41.66;

//Señales del DUT:
reg  test_req1     ;    
reg  test_req2     ;     
reg  test_cd_done  ; 
reg  test_w_done   ; 
reg  test_rst_in_n ;
reg  test_clk      ;     
wire test_gnt1     ;    
wire test_gnt2     ;    
wire test_cd_rst   ;  
wire test_w_rst    ;   
wire test_leds_rst ;
wire test_leds_sel ;

//Señales internas:
wire [5:0] fsm_output_vector        ;
wire [5:0] fsm_outputs_at_reset     ;
wire [5:0] fsm_outputs_at_countdown ;
wire [5:0] fsm_outputs_at_waiting   ;
wire [5:0] fsm_outputs_at_gnt_1     ;
wire [5:0] fsm_outputs_at_gnt_2     ;
wire [5:0] fsm_outputs_at_w1        ;
wire [5:0] fsm_outputs_at_w2        ;
wire [5:0] fsm_outputs_at_end       ;

integer seed = 0;
integer n_half_periods = 0;
integer i = 0;

//DUT:
arbiter_game_fsm dut
(
    .req1         ( test_req1     ),
    .req2         ( test_req2     ),
    .cd_done      ( test_cd_done  ),
    .w_done       ( test_w_done   ),
    .rst_in_n     ( test_rst_in_n ),
    .clk          ( test_clk      ),
    .gnt1_out     ( test_gnt1     ),
    .gnt2_out     ( test_gnt2     ),
    .cd_rst_out   ( test_cd_rst   ),
    .w_rst_out    ( test_w_rst    ),
    .leds_rst_out ( test_leds_rst ),
    .leds_sel_out ( test_leds_sel )
);

//Lógica de verificación
assign fsm_output_vector = {test_gnt1,test_gnt2,test_cd_rst,test_w_rst,test_leds_rst,test_leds_sel};

assign fsm_outputs_at_reset     = 6'b001110 ; 
assign fsm_outputs_at_countdown = 6'b000100 ; 
assign fsm_outputs_at_waiting   = 6'b001110 ; 
assign fsm_outputs_at_gnt_1     = 6'b101001 ; 
assign fsm_outputs_at_gnt_2     = 6'b011001 ; 
assign fsm_outputs_at_w1        = 6'b101001 ; 
assign fsm_outputs_at_w2        = 6'b011001 ; 
assign fsm_outputs_at_end       = 6'b001110 ; 


//Generación de clock:
always
begin
    test_clk = 1'b1;
    #PER2;
    test_clk = 1'b0;
    #PER2;
end

//Cuerpo del test:
initial 
begin
    $dumpfile("wf.vcd");
    $dumpvars(0, arbiter_game_fsm_tb);
    test_req1     = $urandom(seed)%2;
    test_req2     = $urandom(seed)%2;
    test_cd_done  = 1'b0;
    test_w_done   = 1'b0;
    test_rst_in_n = 1'b1;
    #(PER2*2);

    $display("Test begins\n");

    for(i=1;i<=2;i=i+1)
    begin
        $display("Testing player %d wins: \n",i);

        $display("Apply reset and verify outputs");
        test_rst_in_n = 1'b0;
        n_half_periods = $urandom(seed)%100;
        #(PER2*n_half_periods);
        if(fsm_output_vector != fsm_outputs_at_reset)
            $error("Output mismatch @ reset\n");

        $display("Deassert reset and check outputs at countdown");
        test_rst_in_n = 1'b1;
        test_req1     = $urandom(seed)%2;
        test_req2     = $urandom(seed)%2;
        n_half_periods = $urandom(seed)%100;
        #(PER2*n_half_periods);
        if(fsm_output_vector != fsm_outputs_at_countdown)
            $error("Output mismatch @ countdown\n");

        $display("Send cd_done signal and check outputs at wait state");
        test_req1    = 1'b0;
        test_req2    = 1'b0;
        test_cd_done = 1'b1;
        #(PER2*2);
        if(fsm_output_vector != fsm_outputs_at_waiting)
            $error("Output mismatch @ waiting\n");

        $display("Change both player inputs at the same time and check outputs at wait state");
        test_req1    = 1'b1;
        test_req2    = 1'b1;
        test_cd_done = 1'b0;
        #(PER2*2);
        if(fsm_output_vector != fsm_outputs_at_waiting)
            $error("Output mismatch @ waiting\n");

        $display("Check if player %d wins",i);
        test_req1 = (i==1);
        test_req2 = (i==2);
        n_half_periods = $urandom(seed)%100;
        #(PER2*n_half_periods);
        if(i==1)
        begin
            if(fsm_output_vector != fsm_outputs_at_gnt_1)
                $error("Output mismatch @ GNT_1\n");
        end
        else
        begin
            if(fsm_output_vector != fsm_outputs_at_gnt_2)
                $error("Output mismatch @ GNT_2\n");
        end
    
        $display("Check transition to player %d wins",i);
        test_req1 = 1'b0;
        test_req2 = 1'b0;
        #(PER2*2);
        if(i==1)
        begin
            if(fsm_output_vector != fsm_outputs_at_w1)
                $error("Output mismatch @ W_1\n");
        end
        else
        begin
            if(fsm_output_vector != fsm_outputs_at_w2)
                $error("Output mismatch @ W_2\n");
        end

        $display("Check transition to game end\n");
        test_req1   = $urandom(seed)%2;
        test_req2   = $urandom(seed)%2;
        test_w_done = 1'b1;
        #(PER2*2);
        if(fsm_output_vector != fsm_outputs_at_end)
            $error("Output mismatch @ END\n");
    end
    
    $display("Test end\n");

    $finish();
end

endmodule