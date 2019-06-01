module bidir_unit #(
    parameter my_val = 2'b0
)(
    input wire [1:0] sel,
    inout wire [1:0] bus_wire
);

    assign bus_wire = (sel == my_val) ? my_val : 2'bZ;

endmodule // bidir_unit

module bidir_mod(
    input [1:0] sel,
    output [1:0] bus
);

wire [3:0] sel_int;

always @(sel):
begin
  case (sel)
    2'b00: sel_int <= 4'b0000
    2'b01: sel_int <= 4'b0010
    2'b10: sel_int <= 4'b0100
    2'b11: sel_int <= 4'b1000
    default
end

bidir_unit mod1 (
    .sel(sel_int[1]),
    .bus_wire(bus)
    );

defparam mod1.my_val = 2'b01;

bidir_unit mod2 (
    .sel(sel_int[2]),
    .bus_wire(bus)
    );

defparam mod2.my_val = 2'b10;

bidir_unit mod3 (
    .sel(sel_int[3]),
    .bus_wire(bus)
    );

defparam mod3.my_val = 2'b11;
endmodule
