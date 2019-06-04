/*
Module name  : parallel_serial.v
Author 	     : C. Wimalasuriya
Date Modified: 02/06/2019
Organization : ABruTECH
Description  : parallel serial converter
*/

module parallel_serial #(
    parameter PARALLEL_PORT_WIDTH = 15,
    parameter BIT_LENGTH = 4
)(
    input clk, rstn, dv_in, 
    input [PARALLEL_PORT_WIDTH - 1:0] din, 
    input [BIT_LENGTH - 1:0] bit_length,
    
    output reg dout = 1'bZ,
    output reg data_sent = 1'b0
);  
    localparam IDLE         = 2'd0;
    localparam START        = 2'd1;
    localparam IN_PROGRESS  = 2'd2;

    reg [1:0] state                                 = IDLE;
    reg [BIT_LENGTH - 1:0] serial_tx_counter        = {BIT_LENGTH{1'b0}};
    reg [PARALLEL_PORT_WIDTH - 1:0] serial_buffer   = {PARALLEL_PORT_WIDTH{1'b0}};

    // main execution
    always @(posedge clk, negedge rstn) begin
        if (rstn == 1'b0) begin
            // reset
            state               <= IDLE;
            serial_tx_counter   <= bit_length;
            dout                <= 1'bZ;
            serial_buffer       <= {PARALLEL_PORT_WIDTH{1'b0}};
        end else begin
            case(state)
                IDLE: begin
                    dout                <= 1'bZ;
                    data_sent           <= 1'b0;
                    if (dv_in) begin
                        state           <= START;
                        serial_buffer   <= din;
                    end
                end

                START: begin
                    dout    <= 1'b0;
                    state   <= IN_PROGRESS;
                end

                IN_PROGRESS: begin
                    if (bit_length == 0) state <= IDLE;
                    else begin
                        dout <= serial_buffer[serial_tx_counter];
                        serial_tx_counter <= serial_tx_counter - 1;

                        if (serial_tx_counter == 0) begin
                            state <= IDLE;
                            serial_buffer <= {PARALLEL_PORT_WIDTH{1'b0}};
                            serial_tx_counter <= {BIT_LENGTH{1'b0}};
                            data_sent <= 1'b1;
                        end
                    end
                end
            endcase
        end
    end
endmodule