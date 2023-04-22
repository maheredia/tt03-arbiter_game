`include "arbiter_game_fsm.v"
`include "countdown.v"
`include "winner.v"

module arbiter_game 
#(
  parameter CLOCK_FREQ      = 12000000,
  parameter PRESCALER_COUNT = CLOCK_FREQ/4
)
(
  //Entradas
  input wire req1_in,
  input wire req2_in,
  input wire rst_in_n,
  input wire clk,
  //Salidas
  output reg [3:0] leds_out
);

//Lógica para manejo de leds
wire cd_done;
wire [3:0] cd_leds_o;
wire w_done;
wire [3:0] w_leds_o;
wire req1;
wire req2;
assign req1 = ~req1_in;
assign req2 = ~req2_in;
wire [3:0] leds_mux;

//Salidas de la FSM
wire gnt1;
wire gnt2;
wire cd_rst;
wire w_rst;
wire leds_rst;
wire leds_sel;

//Salidas
always @ (posedge clk)
begin
    if(leds_rst)
        leds_out <= 4'b0000;
    else
        leds_out <= leds_mux;
end

//Mux de salida para LEDs
assign leds_mux = (leds_sel) ? (w_leds_o) : (cd_leds_o);

//Countdown block
countdown 
#(
    .CLOCK_FREQ      ( CLOCK_FREQ      ),
    .PRESCALER_COUNT ( PRESCALER_COUNT )
)
u_cd
(
    .clk         ( clk       ),
    .reset       ( cd_rst    ),
    .cd_done_out ( cd_done   ),
    .leds_out    ( cd_leds_o )
);

//Winner block
winner 
#(
    .CLOCK_FREQ      ( CLOCK_FREQ      ),
    .PRESCALER_COUNT ( PRESCALER_COUNT )
)
u_winner
(
    .clk        ( clk      ),
    .reset      ( w_rst    ),
    .w1_in      ( gnt1     ),
    .w2_in      ( gnt2     ),
    .w_done_out ( w_done   ),
    .leds_out   ( w_leds_o )
);

//FSM
arbiter_game_fsm fsm
(
    .req1          ( req1     ),
    .req2          ( req2     ),
    .cd_done       ( cd_done  ),
    .w_done        ( w_done   ),
    .rst_in_n      ( rst_in_n ),
    .clk           ( clk      ),
    .gnt1_out      ( gnt1     ),
    .gnt2_out      ( gnt2     ),
    .cd_rst_out    ( cd_rst   ),
    .w_rst_out     ( w_rst    ),
    .leds_rst_out  ( leds_rst ),
    .leds_sel_out  ( leds_sel )
);

endmodule
