/*
Module name  : pulse.v
Author 	     : W.M.R.R.Wickramasinghe
Date Modified: 01/06/2019
Organization : ABruTECH
Description  : Gives a pulse of given clock width
*/

module pulse(
    din,
    dout,
    clk,
    rstn
);

// Port declaration
input din;
input rstn;
input clk;
output reg dout = 1'b1;

reg temp = 1'b1;


always@(posedge clk,negedge rstn)
begin
    if(~rstn)
    begin
        temp <= 1'b1;
        dout <= 1'b1;
    end else begin
        temp <= din;
        if({temp,din} == 2'b01) dout <= 1'b1;
        else    dout <= 1'b0;
    end
end 

endmodule