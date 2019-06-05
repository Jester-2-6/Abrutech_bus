/*
Module name  : master.v
Author 	     : W.M.R.R.Wickramasinghe
Date Modified: 03/06/2019
Organization : ABruTECH
Description  : Master module of the bus
*/

module master(
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
parameter ADDRS_WIDTH = 4'd15;
parameter TIMEOUT_LEN = 6; //in bits 4 means 16 clocks
parameter BIT_LENGTH  = 4; //size of bit_length port 4=> can 


// Port declaration
input                        clk;
input                        rstn;
// module side
input                        m_hold;
input                        m_execute;
input                        m_RW;
input      [ADDRS_WIDTH-1:0] m_address;
input      [DATA_WIDTH-1:0]  m_din;
output reg                   m_dvalid     = 1'b0;
output reg                   m_master_bsy = 1'b0;
output     [DATA_WIDTH-1:0]  m_dout;
// BUS side
input                        b_grant;
inout                        b_BUS;            // Master bus. Have to rout the converter
output reg                   b_request = 1'b0;
output                       b_RW;             // Usually pulldown
output                       b_bus_utilizing;  // Usually pulldown


// States
localparam IDLE                 = 4'd0;
localparam BUS_REQUESTED        = 4'd1;
localparam BUS_GRANTED          = 4'd2;
localparam WAIT_BFRE_ADDRS_SEND = 4'd3;
localparam ADDRESS_SEND         = 4'd4;
localparam ADD_ACK_WAIT         = 4'd5;
localparam TIMEOUT              = 4'd6;
localparam READ1                = 4'd7;
localparam READ2                = 4'd8;
localparam WRITE                = 4'd9;
localparam DATA_ACK_WAIT        = 4'd10;
localparam STATE_SIZE           = 4;     // Change above number width according to this
localparam DATA_ACK_PATTERN     = 2'b01; // Serial DATA/ACK prefix
localparam ADD_ACK_PATTERN      = 2'b00; // Serial ADDRESS prefix


// Internal wires and registers
wire                   d_received;
wire                   d_sent;
wire [ADDRS_WIDTH-1:0] converter_parallel_line;

reg                   RW_reg            = 1'b0;
reg [DATA_WIDTH-1:0]  data_reg          = {DATA_WIDTH{1'b0}};  // To store received/sending byte
reg [ADDRS_WIDTH-1:0] address_reg       = {ADDRS_WIDTH{1'b0}}; // To store the current address
reg                   bus_util_reg      = 1'b0;                // To indicate whether the current master utilize the bus
reg                   bus_in_out_reg    = 1'b0;                // To rout the bus. 1: sending data 0: receiving data
reg [TIMEOUT_LEN-1:0] timeout_reg       = {TIMEOUT_LEN{1'b0}}; // Counter for timeouts
reg [STATE_SIZE-1:0]  STATE             = IDLE;                // Current state machine STATE
reg [BIT_LENGTH-1:0]  bit_length_reg    = {BIT_LENGTH{1'b0}};  // To set the number of bits to receive/send
reg                   converter_send    = 1'b0;                // To initiate parallel to serial transmission
reg                   converter_rd_en   = 1'b0;                // To initiate serial to parallel transmission
reg [ADDRS_WIDTH-1:0] conv_parallel_reg = {ADDRS_WIDTH{1'b0}}; // ADDRESS size register to store sending address/byte
reg                   ack_buffer_reg    = 1'b1;                // To buffer incoming data to check for prefix



// Instantiations
serial_parallel_2way #(
    .PORT_WIDTH(ADDRS_WIDTH),                 // Parallel port width
    .BIT_LENGTH(BIT_LENGTH)                   // can send upto (2^BIT_LENGTH)-1 bits
)   converter_m(
    .clk(clk),
    .rstn(rstn),
    .dv_in(converter_send),                   // Initiate parallel to serial
    .invert_s2p(bus_in_out_reg),              // To change direction of converter 1: s<-p 0: s->p
    .en(converter_rd_en),                     // will immediately start reading from serial line
    .bit_length(bit_length_reg),              // Number of bits to send/receive
    .dv_out(d_received),                      // parallel data received
    .serial_tx_done(d_sent),                  // parallel data transmitted
    .parallel_port(converter_parallel_line),  // assign accordingly.rout data and address regs accordingly
    .serial_port(b_BUS)
);

// Assignments
assign b_RW                    = (bus_util_reg)? RW_reg:1'bZ; // Idle RW will be Read(0)
assign b_bus_utilizing         = (bus_util_reg)? 1'b1:1'bZ;   //Idle bus will be pull down
assign converter_parallel_line = (bus_util_reg & bus_in_out_reg) ? conv_parallel_reg: {ADDRS_WIDTH{1'bZ}};
assign m_dout                  = data_reg;
//assign b_BUS           = (bus_util_reg & bus_in_out_reg) ? (whatever writing port):1'bZ;


// Code
always@(posedge clk,negedge rstn)
begin
    if(~rstn)
    begin
        // Reset the module
        m_dvalid          <= 1'b0;
        data_reg          <= {DATA_WIDTH{1'b0}};
        m_master_bsy      <= 1'b0;
        b_request         <= 1'b0;
        RW_reg            <= 1'b0;
        address_reg       <= {ADDRS_WIDTH{1'b0}};
        bus_util_reg      <= 1'b0;
        bus_in_out_reg    <= 1'b0; // 1: sending data 0: receiving data
        timeout_reg       <= {TIMEOUT_LEN{1'b0}};
        bit_length_reg    <= {BIT_LENGTH{1'b0}};
        converter_send    <= 1'b0; 
        converter_rd_en   <= 1'b0; 
        conv_parallel_reg <= {ADDRS_WIDTH{1'b0}};
        ack_buffer_reg    <= 1'b1;
        STATE             <= IDLE;
    end else begin
        case(STATE)


            IDLE:
            begin
                data_reg       <= {DATA_WIDTH{1'b0}};
                m_dvalid       <= 1'b0;
                RW_reg         <= 1'b0;
                address_reg    <= {ADDRS_WIDTH{1'b0}};
                bus_util_reg   <= 1'b0;
                bus_in_out_reg <= 1'b0; // 1: sending data 0: receiving data
                timeout_reg    <= {TIMEOUT_LEN{1'b0}};
                bit_length_reg <= {BIT_LENGTH{1'b0}};
                converter_send <= 1'b0; 
                converter_rd_en<= 1'b0; 
                ack_buffer_reg <= 1'b1;
                conv_parallel_reg <= {ADDRS_WIDTH{1'b0}};
                if(m_hold)
                begin
                    b_request      <= 1'b1;
                    m_master_bsy   <= 1'b1;
                    STATE          <= BUS_REQUESTED;
                end else begin
                    b_request      <= 1'b0;
                    STATE          <= IDLE;
                    m_master_bsy   <= 1'b0;
                end
            end


            BUS_REQUESTED:
            begin
                //data_reg         <= {DATA_WIDTH{1'b0}};
                m_dvalid       <= 1'b0;
                b_request      <= 1'b1;
                //RW_reg         <= 1'b0;
                //address_reg    <= {ADDRS_WIDTH{1'b0}};
                bus_in_out_reg <= 1'b0; // 1: sending data 0: receiving data
                timeout_reg    <= {TIMEOUT_LEN{1'b0}};
                bit_length_reg <= ADDRS_WIDTH; // Telling to send address size bits
                converter_send <= 1'b0; 
                ack_buffer_reg   <= 1'b1;
                converter_rd_en<= 1'b0;                 
                if(b_grant)
                begin
                    STATE <= BUS_GRANTED;
                    bus_util_reg   <= 1'b1;
                    m_master_bsy   <= 1'b0;
                end else begin 
                    STATE <= BUS_REQUESTED;
                    bus_util_reg   <= 1'b0;
                    m_master_bsy   <= 1'b1;
                end
            end




            BUS_GRANTED: 
            begin
                m_dvalid          <= 1'b0;
                converter_rd_en   <= 1'b0;
                ack_buffer_reg    <= 1'b1;
                bit_length_reg    <= ADDRS_WIDTH; // Telling to send address size bits
                
                if(~m_hold)
                begin
                    STATE <= IDLE;
                    b_request         <= 1'b0;
                    bus_util_reg    <= 1'b0;
                    m_master_bsy    <= 1'b0;
                    timeout_reg       <= {TIMEOUT_LEN{1'b0}};
                 end else if(~b_grant) 
                 begin
                     
                     bus_util_reg    <= 1'b0;
                     m_master_bsy    <= 1'b1; // Dont send data from module side
                     bus_in_out_reg  <= 1'b0; // 1: sending data 0: receiving data
                     converter_send  <= 1'b0;
                     b_request       <= 1'b0;
                     timeout_reg     <= timeout_reg + 1'b1;
                     if(timeout_reg[TIMEOUT_LEN-1] == 1'b1)
                     begin
                         STATE           <= BUS_REQUESTED;
                     end else begin
                         STATE           <= BUS_GRANTED;
                     end
                     
                end else if (m_execute)
                begin
                    m_master_bsy      <= 1'b1;
                    b_request         <= 1'b1;
                    bus_util_reg      <= 1'b1;
                    address_reg       <= m_address;
                    conv_parallel_reg <= m_address;
                    RW_reg            <= m_RW;
                    timeout_reg       <= {TIMEOUT_LEN{1'b0}};
                    if(m_RW) 
                    begin
                        data_reg <= m_din;
                    end else begin
                        data_reg <= {DATA_WIDTH{1'b0}};
                    end
                    converter_send <= 1'b0; 
                    bus_in_out_reg <= 1'b0; // 1: sending data 0: receiving data
                    STATE          <= WAIT_BFRE_ADDRS_SEND;
                end else begin
                    //data_reg        <= {DATA_WIDTH{1'b0}};
                    m_master_bsy      <= 1'b0;
                    b_request         <= 1'b1;
                    bus_util_reg      <= 1'b1;
                    m_master_bsy      <= 1'b0;
                    converter_send    <= 1'b0; 
                    RW_reg            <= 1'b0;
                    address_reg       <= {ADDRS_WIDTH{1'b0}};
                    bus_in_out_reg    <= 1'b0; // 1: sending data 0: receiving data
                    timeout_reg       <= {TIMEOUT_LEN{1'b0}};
                    STATE             <= BUS_GRANTED;
                end
            end

            WAIT_BFRE_ADDRS_SEND:
            begin
                m_dvalid          <= 1'b0;
                m_master_bsy      <= 1'b1;
                b_request         <= 1'b1;
                bit_length_reg    <= ADDRS_WIDTH;
                converter_rd_en   <= 1'b0; 
                ack_buffer_reg    <= 1'b1;
                if(b_grant) 
                begin
                    bus_util_reg      <= 1'b1;
                    timeout_reg <= timeout_reg + 1'b1;
                    if(timeout_reg[TIMEOUT_LEN-1] == 1'b1)
                    begin
                        STATE <= ADDRESS_SEND;
                        bus_in_out_reg    <= 1'b1; // 1: sending data 0: receiving data
                        converter_send    <= 1'b1;
                        conv_parallel_reg <= address_reg;
                    end else begin
                        STATE <= WAIT_BFRE_ADDRS_SEND;
                        bus_in_out_reg    <= 1'b0; // 1: sending data 0: receiving data
                        converter_send    <= 1'b0;
                    end
                end else begin
                    converter_send    <= 1'b0;
                    timeout_reg <= {TIMEOUT_LEN{1'b0}};
                    STATE <= WAIT_BFRE_ADDRS_SEND;
                    bus_util_reg      <= 1'b0;
                    bus_in_out_reg    <= 1'b0; // 1: sending data 0: receiving data
                end





                if(timeout_reg[TIMEOUT_LEN-1]== 1'b1)
                begin
                    STATE <= ADDRESS_SEND;
                    converter_send <= 1'b1; 
                    bus_util_reg   <= 1'b1;
                    bus_in_out_reg <= 1'b1; // 1: sending data 0: receiving data
                end else begin
                    if(b_grant) begin
                        timeout_reg <= timeout_reg + 1'b1;
                        bus_util_reg      <= 1'b1;
                    end else begin
                        bus_util_reg      <= 1'b0;
                    end
                end
            end

            ADDRESS_SEND:
            begin
                m_dvalid          <= 1'b0;
                m_master_bsy      <= 1'b1;
                b_request         <= 1'b1;
                //address_reg       <= {ADDRS_WIDTH{1'b0}};
                bus_util_reg      <= 1'b1;
                timeout_reg       <= {TIMEOUT_LEN{1'b0}};
                bit_length_reg    <= ADDRS_WIDTH;
                converter_send    <= 1'b0; //making a pulse
                converter_rd_en   <= 1'b0; 
                conv_parallel_reg <= address_reg; 
                ack_buffer_reg    <= 1'b1;                   
                if(d_sent) //confirmation of address send
                begin
                    STATE <= ADD_ACK_WAIT;
                    bus_in_out_reg    <= 1'b0; // 1: sending data 0: receiving data
                end else begin
                    bus_in_out_reg    <= 1'b1; // 1: sending data 0: receiving data                        
                    STATE             <= ADDRESS_SEND;
                end
            end


            ADD_ACK_WAIT:
            begin
                
                m_dvalid          <= 1'b0;
                m_master_bsy      <= 1'b1;
                //bus_in_out_reg    <= 1'b0; // 1: sending data 0: receiving data
                timeout_reg       <= timeout_reg + 1'b1;
                converter_rd_en   <= 1'b0; 
                //conv_parallel_reg <= {ADDRS_WIDTH{1'b0}};
                
                if(timeout_reg == {TIMEOUT_LEN{1'b1}}) //Retry re-requesting bus
                begin
                    STATE <= TIMEOUT;
                    b_request         <= 1'b1;
                    ack_buffer_reg    <= 1'b1;
                end else if(timeout_reg[TIMEOUT_LEN-1] == 1'b1) begin // Release bus to wait for retrying
                    b_request         <= 1'b0;
                    bus_util_reg      <= 1'b0;
                    bus_in_out_reg    <= 1'b0; // 1: sending data 0: receiving data
                    ack_buffer_reg    <= 1'b1;
                end else begin
                    b_request         <= 1'b1;
                    bus_util_reg      <= 1'b1;
                    if({ack_buffer_reg,b_BUS} == ADD_ACK_PATTERN) // ACK received.begin data transmission
                    begin 
                        ack_buffer_reg    <= 1'b1;
                        bit_length_reg    <= DATA_WIDTH;
                        if(RW_reg) // Write operation
                        begin
                            STATE <= WRITE;
                            bus_in_out_reg    <= 1'b1; // 1: sending data 0: receiving data
                            conv_parallel_reg[ADDRS_WIDTH-1:ADDRS_WIDTH-DATA_WIDTH] <= data_reg;
                            converter_send    <= 1'b1; 
                        end else begin // Read operation
                            STATE <= READ1;
                            bus_in_out_reg    <= 1'b0; // 1: sending data 0: receiving data
                            converter_send    <= 1'b0; 
                        end
                    end else begin // ACK not yet received
                        ack_buffer_reg    <= b_BUS;
                        bus_in_out_reg    <= 1'b0; // 1: sending data 0: receiving data
                        converter_send    <= 1'b0; 
                        bit_length_reg    <= ADDRS_WIDTH;
                        conv_parallel_reg <= address_reg;
                    end
                end 
            end
                
            TIMEOUT:
            begin
                m_dvalid          <= 1'b0;
                //data_reg          <= {DATA_WIDTH{1'b0}};
                m_master_bsy      <= 1'b1;
                b_request         <= 1'b1;
                //RW_reg            <= 1'b0;
                //address_reg       <= {ADDRS_WIDTH{1'b0}};
                timeout_reg       <= {TIMEOUT_LEN{1'b0}};
                bit_length_reg    <= ADDRS_WIDTH;
                converter_rd_en   <= 1'b0; 
                conv_parallel_reg <= address_reg;
                ack_buffer_reg    <= 1'b1;
                b_request <= 1'b1;
                if(b_grant) begin
                    bus_util_reg      <= 1'b1;
                    converter_send    <= 1'b1;
                    bus_in_out_reg    <= 1'b1; // 1: sending data 0: receiving data
                    STATE <= ADDRESS_SEND;
                end else begin
                    bus_util_reg      <= 1'b0;
                    converter_send    <= 1'b0;
                    bus_in_out_reg    <= 1'b0; // 1: sending data 0: receiving data
                    STATE <= TIMEOUT;
                end
            end



            READ1: // indefinitely listening and freezing
            begin
                b_request         <= 1'b1;
                m_master_bsy      <= 1'b1;
                timeout_reg       <= {TIMEOUT_LEN{1'b0}};
                bit_length_reg    <= DATA_WIDTH;
                converter_send    <= 1'b0; 
                conv_parallel_reg <= address_reg;
                if(b_grant)begin    // This master have the bus
                    ack_buffer_reg    <= b_BUS;
                    m_dvalid          <= 1'b0;
                    bus_util_reg      <= 1'b1;
                    bus_in_out_reg    <= 1'b0; // 1: sending data 0: receiving data
                    if({ack_buffer_reg,b_BUS} == DATA_ACK_PATTERN) // Start bit received
                    begin
                        converter_rd_en   <= 1'b1; 
                        STATE <= READ2;
                    end else begin
                        converter_rd_en   <= 1'b0; 
                    end
                end else begin  // Bus is granted for another master
                    STATE <= READ1;
                    m_dvalid          <= 1'b0;
                    // data_reg          <= {DATA_WIDTH{1'b0}};
                    // RW_reg            <= 1'b0;
                    // address_reg       <= {ADDRS_WIDTH{1'b0}};
                    bus_util_reg      <= 1'b0;
                    bus_in_out_reg    <= 1'b0; // 1: sending data 0: receiving data
                    converter_rd_en   <= 1'b0; 
                    ack_buffer_reg    <= 1'b1;
                end
            end

            READ2:
            begin
                b_request         <= 1'b1;
                bus_util_reg      <= 1'b1;
                timeout_reg       <= {TIMEOUT_LEN{1'b0}};
                ack_buffer_reg    <= 1'b1;
                converter_send    <= 1'b0; 
                bit_length_reg    <= DATA_WIDTH; 
                bus_in_out_reg    <= 1'b0; // 1: sending data 0: receiving data
                if(d_received)
                begin
                    data_reg        <= converter_parallel_line[ADDRS_WIDTH-1:ADDRS_WIDTH-DATA_WIDTH];
                    m_dvalid        <= 1'b1;   // Saying the module the task is done
                    m_master_bsy    <= 1'b0;
                    converter_rd_en <= 1'b0; 
                    STATE           <= BUS_GRANTED; 
                end else begin
                    m_dvalid        <= 1'b0;
                    m_master_bsy    <= 1'b1;
                    converter_rd_en <= 1'b1; 
                    STATE           <= READ2;
                end
                
            end


            WRITE:
            begin
                m_dvalid          <= 1'b0;
                m_master_bsy      <= 1'b1;
                b_request         <= 1'b1;
                bus_util_reg      <= 1'b1;
                timeout_reg       <= {TIMEOUT_LEN{1'b0}};
                bit_length_reg    <= DATA_WIDTH;
                converter_send    <= 1'b0; 
                converter_rd_en   <= 1'b0; 
                conv_parallel_reg[ADDRS_WIDTH-1:ADDRS_WIDTH-DATA_WIDTH] <= data_reg;                    
                if(d_sent) //confirmation of address send
                begin
                    STATE <= DATA_ACK_WAIT;
                    bus_in_out_reg    <= 1'b0; // 1: sending data 0: receiving data
                end else begin
                    bus_in_out_reg    <= 1'b1; // 1: sending data 0: receiving data                        
                    STATE             <= WRITE;
                end
                
            end

            


            DATA_ACK_WAIT:
            begin
                b_request         <= 1'b1;
                bus_in_out_reg    <= 1'b0; // 1: sending data 0: receiving data
                bit_length_reg    <= address_reg;
                converter_send    <= 1'b0;
                converter_rd_en   <= 1'b0; 
                if(b_grant) 
                begin
                    ack_buffer_reg    <= b_BUS;
                    bus_util_reg      <= 1'b1;
                    if({ack_buffer_reg,b_BUS} == DATA_ACK_PATTERN)
                    begin
                        STATE <= BUS_GRANTED;
                        m_dvalid <= 1'b1;
                        m_master_bsy      <= 1'b0;
                    end else begin
                        STATE <= DATA_ACK_WAIT;
                        m_dvalid          <= 1'b0;
                        m_master_bsy      <= 1'b1;
                        
                    end
                end else begin
                    STATE <= DATA_ACK_WAIT;
                    m_dvalid          <= 1'b0;
                    m_master_bsy      <= 1'b1;
                    bus_util_reg      <= 1'b0;
                    ack_buffer_reg    <= 1'b1;
                    
                end
            end
        
        default: STATE <= IDLE;
        endcase
    end
end

endmodule