`timescale 1 ns / 100 ps
`define wait_pulse(num) #(562500*num)

module nec_tb();
	
	// CLOCKS AND RESET
	
	logic clk  = 1'b1;
	logic rst  = 1'b1;

	always begin
		#5 clk = ~clk;
	end
	
	logic [7:0] rstcnt = 'b0;
	always_ff @(posedge clk) begin
		if (rstcnt < 20)
			rstcnt <= rstcnt + 1;
		else
			rst <= 1'b0;
	end
	
	// Test data generation
	
	logic test_data = 0;
	
	task tx_bit();
	input in_bit;
	begin
		test_data = 1;
		`wait_pulse(1);
		test_data = 0;
		`wait_pulse(1);
		if(in_bit) `wait_pulse(2);
	end
	endtask
	
	task tx_byte();
	input [7:0] in_byte;
	begin
		for(int i=0; i<8; i++) begin
		if(in_byte[i] == 1)
			tx_bit(1);
		else
			tx_bit(0);
		end
	end
	endtask
	
	logic [7:0] byte_0 = $urandom;
	logic [7:0] byte_1 = $urandom;
	
	logic          irq          ;
	logic [3 : 0]  S_AXI_AWADDR ;
	logic          S_AXI_AWVALID;
	logic          S_AXI_AWREADY;
	logic [31 : 0] S_AXI_WDATA  ;
	logic [3 : 0]  S_AXI_WSTRB  ;
	logic          S_AXI_WVALID ;
	logic          S_AXI_WREADY ;
	logic [1 : 0]  S_AXI_BRESP  ;
	logic          S_AXI_BVALID ;
	logic          S_AXI_BREADY ;
	logic [3 : 0]  S_AXI_ARADDR ;
	logic          S_AXI_ARVALID;
	logic          S_AXI_ARREADY;
	logic [31 : 0] S_AXI_RDATA  ;
	logic [1 : 0]  S_AXI_RRESP  ;
	logic          S_AXI_RVALID ;
	logic          S_AXI_RREADY ;
	
	initial begin
	
		S_AXI_AWADDR  <= 0;
		S_AXI_AWVALID <= 0;
		S_AXI_WDATA   <= 0;
		S_AXI_WVALID  <= 0;
		S_AXI_BREADY <= 0;
		S_AXI_ARVALID <= 0;
		S_AXI_RREADY <= 1;
		S_AXI_ARADDR <= 0;
		S_AXI_WSTRB <= 4'b1111;
		
		#500
		
		// CONFIGURE
		
		// CSR
		S_AXI_AWADDR <= 0;
		S_AXI_AWVALID <= 1;
		S_AXI_WDATA   <= 1;
		S_AXI_WVALID  <= 1;
		wait(S_AXI_AWREADY == 1);
		#10
		S_AXI_AWVALID <= 0;
		S_AXI_WVALID  <= 0;
		
		wait(S_AXI_BVALID == 1);
		S_AXI_BREADY <= 1;
		#10
		S_AXI_BREADY <= 0;
			
		#500
		
		// pulse period
		S_AXI_AWADDR <= 4;
		S_AXI_AWVALID <= 1;
		S_AXI_WDATA   <= 56250;
		S_AXI_WVALID  <= 1;
		wait(S_AXI_AWREADY == 1);
		#10
		S_AXI_AWVALID <= 0;
		S_AXI_WVALID  <= 0;
		
		wait(S_AXI_BVALID == 1);
		S_AXI_BREADY <= 1;
		#10
		S_AXI_BREADY <= 0;
			
			
		#10000000
		
		test_data = 1;
		`wait_pulse(16);
		
		test_data = 0;
		`wait_pulse(8);
		
		tx_byte(8'h87);
		
		tx_byte(8'h78);
		
		tx_byte(8'h11);
		
		tx_byte(8'hEE);
		
		test_data = 1;
		`wait_pulse(1);
		test_data = 0;
		
		#50000
		
		
		// CSR
		S_AXI_AWADDR <= 0;
		S_AXI_AWVALID <= 1;
		S_AXI_WDATA   <= 1;
		S_AXI_WVALID  <= 1;
		wait(S_AXI_AWREADY == 1);
		#10
		S_AXI_AWVALID <= 0;
		S_AXI_WVALID  <= 0;
		
		wait(S_AXI_BVALID == 1);
		S_AXI_BREADY <= 1;
		#10
		S_AXI_BREADY <= 0;
		
		#10000000
		
		test_data = 1;
		`wait_pulse(16);
		
		test_data = 0;
		`wait_pulse(4);
		
		test_data = 1;
		`wait_pulse(1);
		
		test_data = 0;
		
		#500
		
		
		// CSR
		S_AXI_AWADDR <= 0;
		S_AXI_AWVALID <= 1;
		S_AXI_WDATA   <= 1;
		S_AXI_WVALID  <= 1;
		wait(S_AXI_AWREADY == 1);
		#10
		S_AXI_AWVALID <= 0;
		S_AXI_WVALID  <= 0;
		
		wait(S_AXI_BVALID == 1);
		S_AXI_BREADY <= 1;
		#10
		S_AXI_BREADY <= 0;
		
		#10000000
		
		test_data = 1;
		`wait_pulse(1);
		
		test_data = 0;
		
	end
	
	nec_decoder UUT (
		 .S_AXI_ACLK    (clk           )
		,.S_AXI_ARESETN (~rst          )
		,.data_rx       (test_data     )
		,.irq           (irq           )
		,.S_AXI_AWADDR  (S_AXI_AWADDR  )
		,.S_AXI_AWVALID (S_AXI_AWVALID )
		,.S_AXI_AWREADY (S_AXI_AWREADY )
		,.S_AXI_WDATA   (S_AXI_WDATA   )
		,.S_AXI_WSTRB   (S_AXI_WSTRB   )
		,.S_AXI_WVALID  (S_AXI_WVALID  )
		,.S_AXI_WREADY  (S_AXI_WREADY  )
		,.S_AXI_BRESP   (S_AXI_BRESP   )
		,.S_AXI_BVALID  (S_AXI_BVALID  )
		,.S_AXI_BREADY  (S_AXI_BREADY  )
		,.S_AXI_ARADDR  (S_AXI_ARADDR  )
		,.S_AXI_ARVALID (S_AXI_ARVALID )
		,.S_AXI_ARREADY (S_AXI_ARREADY )
		,.S_AXI_RDATA   (S_AXI_RDATA   )
		,.S_AXI_RRESP   (S_AXI_RRESP   )
		,.S_AXI_RVALID  (S_AXI_RVALID  )
		,.S_AXI_RREADY  (S_AXI_RREADY  )
	);

endmodule		