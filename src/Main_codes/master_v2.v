/*
Module name  : master_v2.v
Author 	     : W.M.R.R.Wickramasinghe
Date Modified: 03/06/2019
Organization : ABruTECH
Description  : Master module of the bus
*/

module master_v2(
    clk,
    rstn,

    m_hold,
    m_execute,
    m_RW,
    m_address,
    m_din,
    m_dout,
    m_dvalid,
    m_master_bsy,

    b_grant,
    b_BUS,
    b_request,
    b_RW,
    b_bus_utilizing
);

// Parameters
parameter DATA_WIDTH  = 8;
parameter ADDRS_WIDTH = 15;
parameter TIMEOUT_LEN = 5; //in bits 4 means 16 clocks
parameter BIT_LENGTH  = 4;


// Port declaration
input clk;
input rstn;
// module side
input m_hold;
input m_execute;
input m_RW;
input      [ADDRS_WIDTH-1:0] m_address;
input      [DATA_WIDTH-1:0]  m_din;
output reg                   m_dvalid     = 1'b0;
output reg                   m_master_bsy = 1'b0;
output     [DATA_WIDTH-1:0]  m_dout;
// BUS side
input b_grant;
inout b_BUS; //master bus .have to rout the converter
output reg b_request = 1'b0;
output b_RW; //Usually pullup
output b_bus_utilizing; //Usually pulldown


// States
localparam IDLE          = 5'd0;
localparam BUS_REQUESTED = 5'd1;
localparam BUS_GRANTED   = 5'd2;
localparam READ          = 5'd3;
localparam WRITE         = 5'd4;
localparam STATE_SIZE    = 5;  //change above number width according to this


// Internal wires and registers
wire                   d_received;
wire                   d_sent;
wire [ADDRS_WIDTH-1:0] converter_parallel_line;

reg                   RW_reg            = 1'b0;
reg [DATA_WIDTH-1:0]  data_reg          = {DATA_WIDTH{1'b0}};
reg [ADDRS_WIDTH-1:0] address_reg       = {ADDRS_WIDTH{1'b0}};
reg                   bus_util_reg      = 1'b0;
reg                   bus_in_out_reg    = 1'b0; // 1: sending data 0: receiving data
reg [TIMEOUT_LEN-1:0] timeout_reg       = {TIMEOUT_LEN{1'b0}};
reg [STATE_SIZE-1:0]  STATE             = IDLE;
reg [BIT_LENGTH-1:0]  bit_length_reg    = {BIT_LENGTH{1'b0}}; //newly added. add to reset and others
reg                   converter_send    = 1'b0;    //newly added. add to reset and others
reg                   converter_rd_en   = 1'b0;    //newly added. add to reset and others
reg [ADDRS_WIDTH-1:0] conv_parallel_reg = {ADDRS_WIDTH{1'b0}};



// Instantiations
serial_parallel_2way #(
    .PORT_WIDTH(ADDRS_WIDTH), // Parallel port width
    .BIT_LENGTH(BIT_LENGTH)            // can send upto 16 bits
)   converter_m(
    .clk(clk),
    .rstn(rstn),
    .dv_in(converter_send),
    .invert_sp2(bus_in_out_reg),
    .en(converter_rd_en),
    .bit_length(bit_length_reg),
    .dv_out(d_received),  // parallel data received
    .serial_tx_done(d_sent), // parallel data transmitted
    .parallel_port(converter_parallel_line),  // assign accordingly.rout data and address regs accordingly
    .serial_port(b_BUS)
);

// Assignments
assign b_RW                    = (bus_util_reg)? RW_reg:1'bZ; // Idle RW will be Read(0)
assign b_bus_utilizing         = (bus_util_reg)? 1'b1:1'bZ;  //Idle bus will be pull down
assign converter_parallel_line = (bus_util_reg & bus_in_out_reg) ? conv_parallel_reg: {ADDRS_WIDTH{1'bZ}};
//assign b_BUS           = (bus_util_reg & bus_in_out_reg) ? (whatever writing port):1'bZ;


// Code
always@(posedge clk,negedge rstn)
begin
    if(~rstn)
    begin
        // Reset the module
        m_dvalid       <= 1'b0;
        data_reg       <= {DATA_WIDTH{1'b0}};
        m_master_bsy   <= 1'b0;
        b_request      <= 1'b0;
        RW_reg         <= 1'b0;
        address_reg    <= {ADDRS_WIDTH{1'b0}};
        bus_util_reg   <= 1'b0;
        bus_in_out_reg <= 1'b0; // 1: sending data 0: receiving data
        timeout_reg    <= {TIMEOUT_LEN{1'b0}};
        bit_length_reg <= {BIT_LENGTH{1'b0}};
        converter_send <= 1'b0; 
        converter_rd_en<= 1'b0; 
        conv_parallel_reg <= {ADDRS_WIDTH{1'b0}};
        STATE          <= IDLE;
    end else begin
        case(STATE):


            IDLE:
            begin
                data_reg       <= {DATA_WIDTH{1'b0}};
                m_master_bsy   <= 1'b0;
                m_dvalid       <= 1'b0;
                RW_reg         <= 1'b0;
                address_reg    <= {ADDRS_WIDTH{1'b0}};
                bus_util_reg   <= 1'b0;
                bus_in_out_reg <= 1'b0; // 1: sending data 0: receiving data
                timeout_reg    <= {TIMEOUT_LEN{1'b0}};
                bit_length_reg <= {BIT_LENGTH{1'b0}};
                converter_send <= 1'b0; 
                converter_rd_en<= 1'b0; 
                conv_parallel_reg <= {ADDRS_WIDTH{1'b0}};
                if(m_hold)
                begin
                    b_request      <= 1'b1;
                    STATE          <= BUS_REQUESTED;
                end else begin
                    b_request      <= 1'b0;
                    STATE          <= IDLE;
                end
            end


            BUS_REQUESTED:
            begin
                //data_reg         <= {DATA_WIDTH{1'b0}};
                m_dvalid       <= 1'b0;
                //m_master_bsy   <= 1'b0;
                b_request      <= 1'b1;
                //RW_reg         <= 1'b0;
                //address_reg    <= {ADDRS_WIDTH{1'b0}};
                bus_in_out_reg <= 1'b0; // 1: sending data 0: receiving data
                timeout_reg    <= {TIMEOUT_LEN{1'b0}};
                bit_length_reg <= {BIT_LENGTH{1'b0}};
                converter_send <= 1'b0; 
                converter_rd_en<= 1'b0; 
                if(b_grant)
                begin
                    STATE <= BUS_GRANTED;
                    bus_util_reg   <= 1'b1;
                end else begin 
                    STATE <= BUS_REQUESTED;
                    bus_util_reg   <= 1'b0;
                end
            end


            BUS_GRANTED: 
            begin
                if(~m_hold)
                begin
                    STATE <= IDLE;
                end else if(~b_grant) 
                begin
                    STATE <= FREEZE;
                    m_master_bsy   <= 1'b1;
                end else if(m_master_bsy) 
                begin
                    m_dvalid          <= 1'b0;
                    //address_reg       <= m_address;
                    conv_parallel_reg <= address_reg;
                    //RW_reg            <= m_RW;
                    timeout_reg       <= {TIMEOUT_LEN{1'b0}};
                    //if(m_RW) data_reg <= m_din;
                    //else     data_reg <= {DATA_WIDTH{1'b0}};
                    b_request      <= 1'b1;
                    bit_length_reg <= ADDRESS_WIDTH; // Telling to send address size bits
                    bus_util_reg   <= 1'b1;
                    converter_send <= 1'b1; 
                    converter_rd_en<= 1'b0; 
                    bus_in_out_reg <= 1'b1; // 1: sending data 0: receiving data
                    STATE          <= ADDRESS_SEND;
                end else if (m_execute)
                begin
                    m_dvalid          <= 1'b0;
                    address_reg       <= m_address;
                    conv_parallel_reg <= m_address;
                    RW_reg            <= m_RW;
                    timeout_reg       <= {TIMEOUT_LEN{1'b0}};
                    if(m_RW) data_reg <= m_din;
                    else     data_reg <= {DATA_WIDTH{1'b0}};
                    b_request      <= 1'b1;
                    bit_length_reg <= ADDRESS_WIDTH; // Telling to send address size bits
                    bus_util_reg   <= 1'b1;
                    converter_send <= 1'b1; 
                    converter_rd_en<= 1'b0; 
                    bus_in_out_reg <= 1'b1; // 1: sending data 0: receiving data
                    STATE          <= ADDRESS_SEND;
                end else begin
                    m_dvalid       <= 1'b0;
                    //data_reg        <= {DATA_WIDTH{1'b0}};
                    m_master_bsy   <= 1'b0;
                    b_request      <= 1'b1;
                    RW_reg         <= 1'b0;
                    address_reg    <= {ADDRS_WIDTH{1'b0}};
                    bus_util_reg   <= 1'b1;
                    bus_in_out_reg <= 1'b0; // 1: sending data 0: receiving data
                    timeout_reg    <= {TIMEOUT_LEN{1'b0}};
                    STATE          <= BUS_GRANTED;
                end
                                // timeout_reg    <= timeout_reg + 1'b1;
                // if (timeout_reg[TIMEOUT_LEN-1]==1'b0) //first half of timeout register
                // begin
                //     b_request      <= 1'b1;
                //     if(b_grant)
                //     begin
                //         STATE          <= BUS_GRANTED;
                //         bus_util_reg   <= 1'b1;
                //     end else begin
                //         STATE          <= BUS_REQUESTED;
                //         bus_util_reg   <= 1'b0;
                //     end
                // end else begin                       //second half of timeout register
                //     b_request      <= 1'b0;
                //     bus_util_reg   <= 1'b0;
                //     STATE          <= BUS_REQUESTED;


                ADDRESS_SEND:
                    m_dvalid          <= 1'b0;
                    //data_reg          <= {DATA_WIDTH{1'b0}};
                    m_master_bsy      <= 1'b0;
                    b_request         <= 1'b1;
                    //RW_reg            <= 1'b0;
                    //address_reg       <= {ADDRS_WIDTH{1'b0}};
                    bus_util_reg      <= 1'b1;
                    timeout_reg       <= {TIMEOUT_LEN{1'b0}};
                    bit_length_reg    <= ADDRESS_WIDTH;
                    converter_send    <= 1'b0; 
                    converter_rd_en   <= 1'b0;
                    conv_parallel_reg <= address_reg;                    
                    if(d_sent) //confirmation of address send
                    begin
                        STATE <= ADD_ACK_WAIT;
                        bus_in_out_reg    <= 1'b0; // 1: sending data 0: receiving data
                    end else begin
                        bus_in_out_reg    <= 1'b1; // 1: sending data 0: receiving data                        
                        STATE             <= ADDRESS_SEND;
                    end


                RECEIVE_ACK:
                begin
                    timeout_reg    <= timeout_reg + 1'b1;
                    if(b_BUS==1'b0) //ACK Received
                    begin
                        STATE <= 
                    end else begin
                        
                    end
                end


                SEND_ACK:
                begin
                    
                end
                READ:
                begin

                end
                WIRTE:
                begin
                    
                end
                FREEZE:
                begin
                    
                end
            end
            default: STATE <= IDLE;
        endcase
    end
end

endmodule