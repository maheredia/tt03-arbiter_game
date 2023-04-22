//`include "arbiter_game_fsm.v"
//`include "countdown.v"
//`include "winner.v"

module maheredia_arbiter_game 
(
  input [7:0] io_in,
  output [7:0] io_out
);

//Local parameters:
localparam CLOCK_FREQ      = 1000;
localparam PRESCALER_COUNT = CLOCK_FREQ/4;

//I/O ports renaming:
wire       player_1_in_n  ;
wire       player_2_in_n  ;
wire       rst_in_n       ;
wire       clk            ;
reg  [3:0] leds_out       ;

//Logic for LED control
wire cd_done;
wire [3:0] cd_leds_o;
wire w_done;
wire [3:0] w_leds_o;
wire req1;
wire req2;
assign req1 = ~player_1_in_n;
assign req2 = ~player_2_in_n;
wire [3:0] leds_mux;

//FSM outputs
wire gnt1;
wire gnt2;
wire cd_rst;
wire w_rst;
wire leds_rst;
wire leds_sel;

//Input ports connections:
assign clk           = io_in[0];
assign rst_in_n      = io_in[1];
assign player_1_in_n = io_in[2];
assign player_2_in_n = io_in[3];

//Outputs
always @ (posedge clk)
begin
    if(leds_rst)
        leds_out <= 4'b0000;
    else
        leds_out <= leds_mux;
end

assign io_out        = {4'b0000,leds_out};

//Output MUX for LEDs
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
