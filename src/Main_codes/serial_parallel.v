/*
Module name  : serial_parallel.v
Author 	     : W.M.R.R.Wickramasinghe
Date Modified: 01/06/2019
Organization : ABruTECH
Description  : Serial to parallel data converter module
*/

module serial_parallel(
    clk,
    rstn,
    din,
    dout,
    dv_out,
    bit_length,
    en
);

// Parameters
parameter PORT_WIDTH    = 15;//Parallel port width
parameter EXTRACT_LNGTH = 4; //bit_length port size
parameter STATE_BW      = 1; //BITWIDTH to accommodate the STATE

// Port declaration
input                           clk;
input                           rstn;
input                           din;
input  wire [EXTRACT_LNGTH-1:0] bit_length;
input                           en;
output reg                      dv_out = 1'b0;
output reg [PORT_WIDTH-1:0]     dout;

// Internal registers and wires
reg [EXTRACT_LNGTH-1:0] counter = {EXTRACT_LNGTH{1'b0}};
reg [STATE_BW-1:0]      STATE   = {STATE_BW{1'b0}}; 

// STATES
localparam IDLE = 1'b0;
localparam DONE = 1'b1;

always@(posedge clk,negedge rstn)
begin
    if(~rstn)
    begin
        dout    <= {PORT_WIDTH{1'b0}};
        counter <= {EXTRACT_LNGTH{1'b0}};
        dv_out  <= 1'b0;
        STATE   <= {STATE_BW{1'b0}};
    end else begin
        case(STATE)
            IDLE:
            begin
                if(~en)
                begin
                    dout    <= {PORT_WIDTH{1'b0}};
                    counter <= {EXTRACT_LNGTH{1'b0}};
                    dv_out  <= 1'b0;
                    STATE   <= IDLE;
                end else begin
                    dout[counter] <= din;
                    counter       <= counter+1'b1;
                    if(counter == bit_length-1)
                    begin
                        dv_out  <= 1'b1;
                        STATE   <= DONE;
                    end else begin
                        dv_out  <= 1'b0;
                        STATE   <= IDLE;
                    end
                end
            end
            DONE:
            begin
                if(~en)
                begin
                    dout    <= {PORT_WIDTH{1'b0}};
                    counter <= {EXTRACT_LNGTH{1'b0}};
                    dv_out  <= 1'b0;
                    STATE   <= IDLE;
                end
            end
            default: STATE <= IDLE;
        endcase
    end
end 
endmodule
