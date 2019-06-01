module bidir_mod_tb(input a);
    reg [1:0] sel_t;
    wire [1:0] bus_t;

    bidir_mod mod_inst(
        .sel(sel_t),
        .bus(bus_t)
    );

    initial begin
        sel_t = 2'b00;
        #10
        sel_t = 2'b01;
        #10
        sel_t = 2'b10;
        #10
        sel_t = 2'b11;
        #10
        sel_t = 2'b00;
    end
endmodule // bidir_mod_tb