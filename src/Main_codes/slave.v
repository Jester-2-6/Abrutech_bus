/*
Module name  : slave.v
Author 	     : C.Wimalasuriya
Date Modified: 01/06/2019
Organization : ABruTECH
Description  : Slave module of the bus
*/
module slave #(
    parameter MEM_OFFSET = 0,
    parameter MEM_SIZE = 2048,
    parameter ADDRESS_WIDTH = 12,
    parameter DATA_WIDTH = 8
)(
    input [ADDRESS_WIDTH - 1:0] addr_in,
    input clk, rstn, write_en,
    input [DATA_WIDTH - 1:0] data_in_parellel,

    output reg ready, done,
    output reg [DATA_WIDTH - 1:0] data_out_parellel,
    output wire [ADDRESS_WIDTH -1:0] addr_out,

    inout data_bus_serial
);

localparam IDLE         = 3'd0;
localparam WRITE        = 3'd1;
localparam FETCH        = 3'd2;
localparam DATA_READY   = 3'd3;
localparam SERIAL_TX    = 3'd4;
localparam CLEANUP      = 3'd5;

localparam DATA_WIDTH_LOG = $clog2(DATA_WIDTH);

wire addr_valid;
reg [2:0] state;

reg serial_out_enable                               = 1'b0;
reg serial_out_buff                                 = 1'b0;
reg parellel_out_valid;

reg [DATA_WIDTH - 1:0] parellel_out_buff               = (DATA_WIDTH{1'b0});
reg [DATA_WIDTH - 1:0] parellel_in_buff            = (DATA_WIDTH{1'b0});

reg [DATA_WIDTH_LOG - 1:0] serial_data_counter  = 0;

// address range checking
addr_in_range #(
    MEM_OFFSET = MEM_OFFSET, 
    MEM_SIZE = MEM_SIZE
)(
    .addr_in(addr_in),
    .in_range(addr_valid)
);

// tristate buffers
assign data_bus_serial = serial_out_enable ? serial_out_buff : 1'bZ;

// assignments
assign addr_out = addr_in & (ADDRESS_WIDTH{addr_valid});

// main execution
always @(posedge clk, negedge rstn) begin
    if (rstn == 1'b0) begin
        //reset logic
        ready                   <= 1'b0;
        done                    <= 1'b0;
        data_out_parellel       <= (DATA_WIDTH{1'b0});
        serial_out_enable       <= 1'b0;
        state                   <= IDLE;
        parellel_out_buff       <= (DATA_WIDTH{1'b0});
        parellel_in_buff        <= (DATA_WIDTH{1'b0});
        serial_out_buff         <= 1'b0;
        serial_data_counter     <= (DATA_WIDTH_LOG{1'b0});

    end else begin
        case(state)

            IDLE: begin
                if (addr_valid & ~write_en) state <= FETCH;
                else if addr_valid state <= WRITE;
            end

            WRITE: begin
                if serial_data_counter < DATA_WIDTH begin
                    parellel_out_buff <= parellel_out_buff & (data_bus_serial << serial_data_counter);
                    serial_data_counter <= serial_data_counter + 1;

                end else begin
                    state <= IDLE;
                    parellel_out_valid <= 1'b1;
                end
            end

            FETCH: begin
                parellel_in_buff <= data_in_parellel;
                state <= DATA_READY;
            end

            DATA_READY: begin
                if addr_valid state <= SERIAL_TX;
            end

            SERIAL_TX: begin
                if serial_data_counter < DATA_WIDTH begin
                    serial_out_buff         <= parellel_in_buff[serial_data_counter];
                    serial_data_counter     <= serial_data_counter + 1;

                end else state <= IDLE;
            end

            CLEANUP: begin
                parellel_out_buff       <= (DATA_WIDTH{1'b0});
                parellel_in_buff        <= (DATA_WIDTH{1'b0});
                serial_out_buff         <= 1'b0;
                serial_data_counter     <= (DATA_WIDTH_LOG{1'b0});
                state                   <= IDLE;
            end
    end
end

endmodule 