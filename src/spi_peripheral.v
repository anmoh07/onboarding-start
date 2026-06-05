module spi_peripheral
(

    input wire clk,
    input wire rst_n,

    input wire sclk,
    input wire copi,
    input wire ncs,

    output reg [7:0] en_reg_out_7_0,
    output reg [7:0] en_reg_out_15_8,
    output reg [7:0] en_reg_pwm_7_0,
    output reg [7:0] en_reg_pwm_15_8,
    output reg [7:0] pwm_duty_cycle

);

//synchronization
reg sclk_1;
reg sclk_2;
reg ncs_1;
reg ncs_2;
reg copi_1;
reg copi_2;

always @(posedge clk)
begin
	if (!rst_n)
	begin
    
		sclk_1 <= 1'b0;
		sclk_2 <= 1'b0;
		ncs_1 <= 1'b0;
		ncs_2 <= 1'b0;
		copi_1 <= 1'b0;
    	copi_2 <= 1'b0;

	end
	else
	begin

		sclk_1 <= sclk;
		sclk_2 <= sclk_1;
		ncs_1 <= ncs;
		ncs_2 <= ncs_1;
		copi_1 <= copi;
    	copi_2 <= copi_1;
    
	end
end

reg last_sclk;
reg [15:0] copi_storage;
reg [3:0] copi_counter;

reg last_ncs;

//Getting COPI
always @(posedge clk)
begin

    if (!rst_n)
    begin
        last_sclk    <= 1'b0;
        last_ncs     <= 1'b0;
        copi_storage <= 16'h0000;
        copi_counter <= 4'hF;
    end
    else
    begin

        //Updates last_sclk on clock edge
        last_sclk <= sclk_2;
        last_ncs  <= ncs_2;

        //checks to see if sclk changed
        if ((last_sclk != sclk_2) && sclk_2 && !ncs_2)
        begin

            copi_storage[copi_counter] <= copi_2;
            copi_counter <= copi_counter - 1;

        end

    end

end

wire read_write;   
wire [6:0] address; 
wire [7:0] data;  

assign read_write = copi_storage[15];
assign address = copi_storage[14:8];
assign data = copi_storage[7:0];

//decode logic
always @(posedge clk)
begin


	if (!rst_n) //reset behaviour
	begin

		    en_reg_out_7_0  <= 8'h00;
    		en_reg_out_15_8 <= 8'h00;
    		en_reg_pwm_7_0  <= 8'h00;
    		en_reg_pwm_15_8 <= 8'h00;
    		pwm_duty_cycle  <= 8'h00;

	end
	else if ((read_write) && (last_ncs != ncs_2) && (ncs_2) && (copi_counter == 4'hF))
	begin

    		case (address)

        	7'h00: en_reg_out_7_0 <= data;
		    7'h01: en_reg_out_15_8 <= data;
        	7'h02: en_reg_pwm_7_0 <= data;
        	7'h03: en_reg_pwm_15_8 <= data;
            7'h04: pwm_duty_cycle <= data;

		    default: /*nothing*/;
            

    		endcase
	end
end



endmodule