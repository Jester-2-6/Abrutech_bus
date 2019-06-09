module clock_divider(inclk,ena,clk);

	parameter maxcount=24'd2500000;// input 10MHz clock and output 1Hz clk
	
	input inclk;
	input ena;
	output reg clk=1;
	
	reg [23:0] count=24'd0;
	
	always @ (posedge inclk )
		begin
		if (ena) 
			begin
				if (count==maxcount)
					begin 
					clk=~clk;
					count=24'd0;
					end
				else 
					begin
					count=count+1;
					end
			end
		else 
			begin 
			clk=0; 
			end
		end
		
endmodule