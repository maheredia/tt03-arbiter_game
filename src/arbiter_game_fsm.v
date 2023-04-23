module arbiter_game_fsm
(
  //Inputs
  input wire req1,
  input wire req2,
  input wire cd_done,
  input wire w_done,
  input wire rst_in_n,
  input wire clk,
  //Outputs
  output gnt1_out,
  output gnt2_out,
  output cd_rst_out,
  output w_rst_out,
  output leds_rst_out,
  output leds_sel_out
);

//Number of bits to represent FSM states
parameter N_BITS_STATE = 3;

//FSM outputs
reg gnt1;
reg gnt2;
reg cd_rst;
reg w_rst;
reg leds_rst;
reg leds_sel;

//Current state
reg[N_BITS_STATE-1:0] state;

//Next state
reg[N_BITS_STATE-1:0] next_state;

//FSM states
localparam RESET     = 3'b111 ;
localparam COUNTDOWN = 3'b110 ;
localparam IDLE      = 3'b000 ;
localparam GNT_1     = 3'b001 ;
localparam GNT_2     = 3'b010 ;
localparam WINNER_1  = 3'b011 ;
localparam WINNER_2  = 3'b100 ;
localparam GAME_END  = 3'b101 ;

//Outputs
assign gnt1_out     = gnt1     ;    
assign gnt2_out     = gnt2     ;    
assign cd_rst_out   = cd_rst   ;  
assign w_rst_out    = w_rst    ;   
assign leds_rst_out = leds_rst ;
assign leds_sel_out = leds_sel ;

//Combinational definition of next state
always @(*) begin

   case (state)
      
      RESET : begin
         next_state = COUNTDOWN;
      end

      COUNTDOWN : begin
         if(cd_done)
            next_state = IDLE;
         else
            next_state = COUNTDOWN;
      end

      IDLE : begin
         if (req1==1'b1 && req2==1'b0) begin
            next_state = GNT_1;
         end else if (req2==1'b1 && req1==1'b0) begin
            next_state = GNT_2;
         end else begin
            next_state = IDLE;
         end
      end

      GNT_1 :begin
         if (req1==1'b1) begin
            next_state = GNT_1;
         end else begin
            next_state = WINNER_1;
         end
      end

      GNT_2 : begin
         if (req2==1'b1) begin
            next_state = GNT_2;
         end else begin
            next_state = WINNER_2;
         end
      end

      WINNER_1 : begin
         if (w_done) begin
            next_state = GAME_END;
         end else begin
            next_state = WINNER_1;
         end
      end

      WINNER_2 : begin
         if (w_done) begin
            next_state = GAME_END;
         end else begin
            next_state = WINNER_2;
         end
      end

      GAME_END : begin
         next_state = GAME_END;
      end

      default : next_state = RESET;
   endcase
end

//Internal state
always @(negedge rst_in_n or posedge clk) begin
   if (!rst_in_n) begin
      state <= RESET;
   end else begin
      state <= next_state;
   end
end

//Combinational definition of FSM outputs
always @(*) begin
   
   case (state)
      RESET : begin
         gnt1   = 0;
         gnt2   = 0;
         cd_rst = 1; 
         w_rst  = 1;
         leds_rst = 1;
         leds_sel = 0;
      end

      COUNTDOWN : begin
         gnt1     = 0;
         gnt2     = 0;
         cd_rst   = 0; 
         w_rst    = 1;
         leds_rst = 0;
         leds_sel = 0;
      end

      IDLE : begin
         gnt1   = 0;
         gnt2   = 0;
         cd_rst = 1; 
         w_rst  = 1;
         leds_rst = 1;
         leds_sel = 0;
      end

      GNT_1 : begin
         gnt1   = 1;
         gnt2   = 0;
         cd_rst = 1; 
         w_rst  = 0;
         leds_rst = 0;
         leds_sel = 1;
      end

      GNT_2 : begin
         gnt1   = 0;
         gnt2   = 1;
         cd_rst = 1; 
         w_rst  = 0;
         leds_rst = 0;
         leds_sel = 1;
      end

      WINNER_1 : begin
         gnt1   = 1;
         gnt2   = 0;
         cd_rst = 1; 
         w_rst  = 0;
         leds_rst = 0;
         leds_sel = 1;
      end

      WINNER_2 : begin
         gnt1   = 0;
         gnt2   = 1;
         cd_rst = 1; 
         w_rst  = 0;
         leds_rst = 0;
         leds_sel = 1;
      end

      GAME_END : begin
         gnt1   = 0;
         gnt2   = 0;
         cd_rst = 1; 
         w_rst  = 1;
         leds_rst = 1;
         leds_sel = 0;
      end

      default : begin
         gnt1   = 0;
         gnt2   = 0;
         cd_rst = 1; 
         w_rst  = 1;
         leds_rst = 1;
         leds_sel = 0;
      end 
      
   endcase
end

endmodule