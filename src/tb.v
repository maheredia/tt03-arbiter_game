`default_nettype none
`timescale 1ns/1ps

module tb 
    (
        input clk,
        input rst_in_n,
        input req1_in,
        input req2_in,
        output [3:0] leds_out
    );

    initial begin
        $dumpfile ("tb.vcd");
        $dumpvars (0, tb);
        #1;
    end

    wire [7:0] inputs = {4'b0000, req2_in, req1_in, rst_in_n, clk};
    wire [7:0] outputs;

    maheredia_arbiter_game maheredia_arbiter_game (
        .io_in (inputs),
        .io_out (outputs)
    );

    assign leds_out = outputs[3:0];

endmodule
