module countdown
#(
    parameter CLOCK_FREQ      = 12000000,
    parameter PRESCALER_COUNT = CLOCK_FREQ/4
)
(
    input reset,
    input clk,
    output reg cd_done_out,
    output reg [3:0] leds_out
);

//Parámetros locales
localparam N_BITS_PRESCALER = $clog2(PRESCALER_COUNT);
//Contador prescaler
reg [N_BITS_PRESCALER-1:0] prescaler_cntr;
reg prescaler_tc;
//Lógica de cuenta regresiva
reg [2:0] cd_prescaler;
wire      cd_clk      ;
reg [4:0] cd_shift_reg;

//Prescaler
always @ (posedge clk, posedge reset)
begin
    if(reset)
    begin
        prescaler_cntr <= {N_BITS_PRESCALER{1'b0}};
        prescaler_tc   <= 1'b0;
    end
    else
    begin
        if(prescaler_cntr >= PRESCALER_COUNT-1)
        begin
            prescaler_cntr <= {N_BITS_PRESCALER{1'b0}};
            prescaler_tc   <= 1'b1;
        end
        else
        begin
            prescaler_cntr <= prescaler_cntr+1;
            prescaler_tc   <= 1'b0;
        end
    end
end

//Prescaler para máscara de cuenta regresiva
always @ (posedge clk, posedge reset)
begin
    if(reset)
        cd_prescaler <= 3'b000;
    else if(prescaler_tc)
        cd_prescaler <= cd_prescaler+1;
end

//Máscara de cuenta regresiva (registro que desplaza ceros!)
always @ (posedge clk, posedge reset)
begin
    if(reset)
        cd_shift_reg <= 5'b01111;
    else if(prescaler_tc && (&cd_prescaler))
        cd_shift_reg <= {1'b0,cd_shift_reg[4:1]};
end

//Salidas
always @ (posedge clk, posedge reset)
begin
    if(reset)
    begin
        leds_out    <= 4'b0000;
        cd_done_out <= 1'b0;
    end
    else if(prescaler_tc)
    begin
        leds_out    <= (~leds_out) & (cd_shift_reg[3:0]);
        cd_done_out <= ~|cd_shift_reg;
    end
end

endmodule