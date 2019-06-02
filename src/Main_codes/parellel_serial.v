/*
Module name  : parellel_serial.v
Author 	     : C. Wimalasuriya
Date Modified: 02/06/2019
Organization : ABruTECH
Description  : parellel serial converter
*/

module #(
    parameter parellel_port_width = 14
)parallel_serial(
    input clk, rstn, dv_in,
    input [parellel_port_width - 1:0] din, 
    input [3:0] bit_lngt,
    
    output reg dout = 1'bZ
);  
    localparam IDLE         = 2'd0;
    localparam START        = 2'd1;
    localparam IN_PROGRESS  = 2'd2;

    reg [1:0] state                 = IDLE;
    reg [3:0] serial_tx_counter     = 4'b0;

    // main execution
    always @(posedge clk, negedge rstn) begin
        if (rstn == 1'b0) begin
            // reset
            state               <= IDLE;
            serial_tx_counter   <= 4'b0;
            dout                <= 1'bZ;
        end else begin
            case(state)
            IDLE: begin
                dout                <= 1'bZ;
                if (dv_in) state    <= START;
            end

            START: begin
                dout    <= 1'b0;
                state   <= IN_PROGRESS;
            end

            IN_PROGRESS: begin
                dout <= din[serial_tx_counter];

                if (serial_tx_counter == bit_lngt - 1) state <= IDLE;
            end
            endcase
        end

endmodule