/*
Module name  : bus_controller.v
Author 	     : Abarajithan G
Date Modified: 
Organization : ABruTECH
Description  : Arbiter and Splitter
*/

module bus_controller (
    clk,
    rstn,
    m_reqs,
    m_grants,
    slaves_in,
    slaves_out,
    bus_util,
    state,
    mid_current
);

input       clk;
input       rstn;
input       bus_util;
input  wire [11:0]      m_reqs;
output reg  [11:0]      m_grants = 12'b000000000000;
input       [5:0]       slaves_in;
output reg  [5:0]       slaves_out = 6'd0;
// inout       slave_0, slave_1, slave_2, slave_3, slave_4, slave_5;

// Parameters:
parameter MID_NONE      = 4'b1111;
parameter SID_NONE      = 3'd7;
parameter SLAVE_FREE    = 2'b00;
parameter SLAVE_BUSY    = 2'b01;
parameter SLAVE_DONE    = 2'b10;
parameter P1            = 2'b00;
parameter P2            = 2'b01;
parameter P3            = 2'b10;

// States
parameter IDLE          = 4'd0;
parameter BUSY_SLAVE_1  = 4'd1;
parameter BUSY_SLAVE_2  = 4'd2;
parameter SEARCH_S      = 4'd3;
parameter SEARCH_P1     = 4'd4;
parameter SEARCH_P2     = 4'd5;
parameter SEARCH_P3     = 4'd6;
parameter FOUND         = 4'd7;
parameter GRANT_1       = 4'd8;
parameter GRANT_2       = 4'd9;
parameter ACK_SLAVE_1   = 4'd10;
parameter ACK_SLAVE_2   = 4'd11;
parameter WAIT          = 4'd12;

// Regs
output reg [3:0]   state       = IDLE;

output reg [3:0]   mid_current = MID_NONE;
reg [3:0]   mid_search  = MID_NONE;
reg [3:0]   mid_grant   = MID_NONE;// 1111 => None granted
reg [11:0]  mid_blocked = 12'b000000000000;


reg [1:0]   slaves_state[5:0] = '{SLAVE_FREE, SLAVE_FREE, SLAVE_FREE, 
                                  SLAVE_FREE, SLAVE_FREE, SLAVE_FREE};
reg [3:0]   slaves_mid  [5:0] = '{MID_NONE, MID_NONE, MID_NONE, 
                                  MID_NONE, MID_NONE, MID_NONE};
reg [2:0]   sid_busy    = SID_NONE;
reg [2:0]   sid_done    = SID_NONE;
reg slave_got_busy      = 0;
reg switch_to_slave     = 0;

reg [2:0]   wait_counter= 3'd0;

// Wires
wire any_p1_req;
wire any_p2_req;
wire any_p3_req;
wire any_s_done;

wire [1:0] p_current;

// Assignments

assign p_current = mid_current[3:2];


// Filter requests by ~blocked bit and take
assign any_p1_req = | (m_reqs[ 3:0] & (~mid_blocked[ 3:0]));
assign any_p2_req = | (m_reqs[ 7:4] & (~mid_blocked[ 7:4]));
assign any_p3_req = | (m_reqs[11:8] & (~mid_blocked[11:8]));

assign any_s_done = slaves_state[0][1] | slaves_state[1][1] | slaves_state[2][1]
                |   slaves_state[3][1] | slaves_state[4][1] | slaves_state[5][1]; // done = 10


/*
MASTER GRANT DECODER:
- input : 4-bit mid (0-11 valid)
- output: m_grants      - set of 12 grant wires
                        - (12-16: none activated)
*/

always @ (*) begin
    case (mid_grant)
        4'd0    : m_grants <= 12'b000000000001;
        4'd1    : m_grants <= 12'b000000000010;
        4'd2    : m_grants <= 12'b000000000100;
        4'd3    : m_grants <= 12'b000000001000;
        4'd4    : m_grants <= 12'b000000010000;
        4'd5    : m_grants <= 12'b000000100000;
        4'd6    : m_grants <= 12'b000001000000;
        4'd7    : m_grants <= 12'b000010000000;
        4'd8    : m_grants <= 12'b000100000000;
        4'd9    : m_grants <= 12'b001000000000;
        4'd10   : m_grants <= 12'b010000000000;
        4'd11   : m_grants <= 12'b100000000000;
        default : m_grants <= 12'b000000000000;
    endcase
end

// STATE MACHINE

always @ (posedge clk, negedge rstn) begin
    // Add reset

    if (~ rstn) begin
        state                   <= IDLE;
        mid_current             <= MID_NONE;
        mid_search              <= MID_NONE;
        slaves_out              <= 6'd0;
        mid_grant               <= MID_NONE;// 1111 => None granted
        mid_blocked             <= 12'b000000000000;
        slaves_state[5:0]       <= '{SLAVE_FREE, SLAVE_FREE, SLAVE_FREE,
                                    SLAVE_FREE, SLAVE_FREE, SLAVE_FREE};
        slaves_mid  [5:0]       <= '{MID_NONE, MID_NONE, MID_NONE,
                                    MID_NONE, MID_NONE, MID_NONE};
        sid_busy                <= SID_NONE;
        sid_done                <= SID_NONE;
        slave_got_busy          <= 0;
        switch_to_slave         <= 0;

    end
    
    else    begin
        case (state)

            IDLE: begin

                if      (slave_got_busy)    state <= BUSY_SLAVE_1;
                else if (any_s_done)        state <= SEARCH_S;

                else if (p_current == P1)   state <= IDLE;
                else if (any_p1_req)        state <= SEARCH_P1;
                else if (p_current == P2)   state <= IDLE;
                else if (any_p2_req)        state <= SEARCH_P2;
                else if (p_current == P3)   state <= IDLE;
                else if (any_p3_req)        state <= SEARCH_P3;
                else                        state <= IDLE;

                if (bus_util) begin  // Master dropped
                    mid_grant   <= MID_NONE;
                    mid_current <= MID_NONE;
                end
            end

            BUSY_SLAVE_1: begin
                slaves_mid[sid_busy]    <= mid_current;
                
                mid_blocked[mid_current]<= 1;
                mid_grant               <= MID_NONE;

                slave_got_busy          <= 0;
                sid_busy                <= 3'd7;
                state                   <= BUSY_SLAVE_2;
            end

            BUSY_SLAVE_2: begin
                if (~bus_util)   state   <= BUSY_SLAVE_2;
                else begin
                    mid_current <= MID_NONE;
                    state       <= IDLE;
                end
            end

            SEARCH_S: begin
                if      (slaves_state[0] == SLAVE_DONE) begin
                    mid_search <= slaves_mid[0];
                    sid_done   <= 3'd0;
                end
                else if (slaves_state[1] == SLAVE_DONE) begin
                    mid_search <= slaves_mid[1];
                    sid_done   <= 3'd1;
                end
                else if (slaves_state[2] == SLAVE_DONE) begin
                    mid_search <= slaves_mid[2];
                    sid_done   <= 3'd2;
                end
                else if (slaves_state[3] == SLAVE_DONE) begin
                    mid_search <= slaves_mid[3];
                    sid_done   <= 3'd3;
                end
                else if (slaves_state[4] == SLAVE_DONE) begin
                    mid_search <= slaves_mid[4];
                    sid_done   <= 3'd4;
                end
                else if (slaves_state[5] == SLAVE_DONE) begin
                    mid_search <= slaves_mid[5];
                    sid_done   <= 3'd5;
                end
                
                switch_to_slave <= 1;
                state           <= FOUND;
            end

            SEARCH_P1: begin
                if      (m_reqs[ 0] & ~mid_blocked[0])   mid_search <= 4'd0;
                else if (m_reqs[ 1] & ~mid_blocked[1])   mid_search <= 4'd1;
                else if (m_reqs[ 2] & ~mid_blocked[2])   mid_search <= 4'd2;
                else if (m_reqs[ 3] & ~mid_blocked[3])   mid_search <= 4'd3;
                
                switch_to_slave <= 0;
                state           <= FOUND;
            end

            SEARCH_P2: begin
                if      (m_reqs[ 4] & ~mid_blocked[4])   mid_search <= 4'd4;
                else if (m_reqs[ 5] & ~mid_blocked[5])   mid_search <= 4'd5;
                else if (m_reqs[ 6] & ~mid_blocked[6])   mid_search <= 4'd6;
                else if (m_reqs[ 7] & ~mid_blocked[7])   mid_search <= 4'd7;
                
                switch_to_slave <= 0;
                state           <= FOUND;
            end

            SEARCH_P3: begin
                if      (m_reqs[ 8] & ~mid_blocked[ 8])   mid_search <= 4'd8;
                else if (m_reqs[ 9] & ~mid_blocked[ 9])   mid_search <= 4'd9;
                else if (m_reqs[10] & ~mid_blocked[10])   mid_search <= 4'd10;
                else if (m_reqs[11] & ~mid_blocked[11])   mid_search <= 4'd11;
                
                switch_to_slave <= 0;
                state           <= FOUND;
            end

            // FOUND: begin
            //     mid_grant <= MID_NONE;
                
            //     if (~bus_util) state <= FOUND;   // Wait until bus is free
            //     else           state <= GRANT_1;
            // end

            // GRANT_1: begin
            //     mid_current <= mid_search;
            //     mid_grant   <= mid_search;
            //     mid_search  <= MID_NONE;

            //     state <= GRANT_2;
            // end

            // GRANT_2: begin
            //     if      (bus_util)          state <= GRANT_2;  // wait until master picks up the bus
            //     else if (switch_to_slave)   state <= ACK_SLAVE_1;
            //     else                        state <= IDLE;
            // end

            FOUND: begin
                mid_grant <= MID_NONE;
                
                if (~bus_util)                  // Wait until bus is free
                               state <= FOUND;   
                else  begin
                                mid_current <= MID_NONE;
                                state <= GRANT_1;
                end
            end

            GRANT_1: begin
                if (bus_util)   begin           // Wait until master picks the bus
                                mid_grant   <= mid_search;
                                state       <= GRANT_1;
                end
                else begin
                                mid_current <= mid_search;
                                mid_search  <= MID_NONE;
                                state       <= GRANT_2; 
                end
            end

            GRANT_2: begin
                if (switch_to_slave)        state <= ACK_SLAVE_1;
                else                        state <= IDLE;
            end

            ACK_SLAVE_1: begin
                // slaves_inout_dir[sid_done]  <= 0; // Make output
                slaves_out[sid_done]        <= 1; // send one bit
                
                state <= ACK_SLAVE_2;
            end

            ACK_SLAVE_2: begin
                // slaves_inout_dir[sid_done]  <= 1; // Make input
                slaves_out[sid_done]        <= 0;

                slaves_mid[sid_done]        <= MID_NONE;
                slaves_state[sid_done]      <= SLAVE_FREE;
                sid_done                    <= SID_NONE;
                switch_to_slave             <= 0;
                mid_blocked[mid_current]    <= 0;
                wait_counter                <= 3'd1;

                state <= WAIT;
            end

            WAIT   : begin
                if (wait_counter == 3'd0)
                    state                   <= IDLE;
                else begin
                    wait_counter            <= wait_counter + 3'd1;
                    state                   <= WAIT;
                end
            end

        endcase

        //Check if a slave just got BUSY.
        for (int i = 0; i < 6; i=i+1) begin
            if ((slaves_state[i] == SLAVE_FREE) & (slaves_in[i] == 1) ) begin
                slaves_state[i] <= SLAVE_BUSY; 
                slave_got_busy  <= 1;
                sid_busy        <= i;
            end
        end
        
        // Check if a slave just got DONE.
        for (int i = 0; i < 6; i=i+1) begin
            if ((slaves_state[i] == SLAVE_BUSY) & (slaves_in[i] == 0) ) begin
                slaves_state[i]     <= SLAVE_DONE;
            end
        end

    end

end
endmodule
