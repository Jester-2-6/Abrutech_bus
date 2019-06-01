module controller_top(
    input [3:0] p1_master_port,
    input [3:0] p2_master_port,
    input [3:0] p3_master_port,

    input [3:0] slaves_busy,

    input clk, rstn,

    output reg [11:0] master_grant
);

wire p1_req, p2_req, p3_req;
wire selected_master;
reg selected_master_reg;
reg [3:0] master_select = 4'b0;

assign selected_master = selected_master_reg;

assign p1_req = |p1_master_port;
assign p2_req = |p2_master_port;
assign p3_req = |p3_master_port;

always @(negedge rstn) begin
	master_grant <= 12'b0;
    master_select <= 4'b0;
end

always @(p1_master_port, p2_master_port, p3_master_port) begin
    case(master_select)
        12'd0:  selected_master_reg <= p1_master_port[0];
        12'd1:  selected_master_reg <= p1_master_port[1];
        12'd2:  selected_master_reg <= p1_master_port[2];
        12'd3:  selected_master_reg <= p1_master_port[3];

        12'd4:  selected_master_reg <= p2_master_port[0];
        12'd5:  selected_master_reg <= p2_master_port[1];
        12'd6:  selected_master_reg <= p2_master_port[2];
        12'd7:  selected_master_reg <= p2_master_port[3];

        12'd8:  selected_master_reg <= p3_master_port[0];
        12'd9:  selected_master_reg <= p3_master_port[1];
        12'd10: selected_master_reg <= p3_master_port[2];
        12'd11: selected_master_reg <= p3_master_port[3];
    endcase
end


endmodule