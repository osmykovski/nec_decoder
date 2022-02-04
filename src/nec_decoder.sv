`timescale 1 ns / 1 ps

	module nec_decoder #
	(
		 parameter integer C_S_AXI_DATA_WIDTH   = 32
		,parameter integer C_S_AXI_ADDR_WIDTH   = 4
	)
	(
		 input  wire                                S_AXI_ACLK
		,input  wire                                S_AXI_ARESETN

		,input  logic                               data_rx
		,output logic                               irq

		,input  wire [C_S_AXI_ADDR_WIDTH-1 : 0]     S_AXI_AWADDR
		,input  wire                                S_AXI_AWVALID
		,output wire                                S_AXI_AWREADY

		,input  wire [C_S_AXI_DATA_WIDTH-1 : 0]     S_AXI_WDATA
		,input  wire [(C_S_AXI_DATA_WIDTH/8)-1 : 0] S_AXI_WSTRB
		,input  wire                                S_AXI_WVALID
		,output wire                                S_AXI_WREADY

		,output wire [1 : 0]                        S_AXI_BRESP
		,output wire                                S_AXI_BVALID
		,input  wire                                S_AXI_BREADY

		,input  wire [C_S_AXI_ADDR_WIDTH-1 : 0]     S_AXI_ARADDR
		,input  wire                                S_AXI_ARVALID
		,output wire                                S_AXI_ARREADY

		,output wire [C_S_AXI_DATA_WIDTH-1 : 0]     S_AXI_RDATA
		,output wire [1 : 0]                        S_AXI_RRESP
		,output wire                                S_AXI_RVALID
		,input  wire                                S_AXI_RREADY
	);

	// AXI4LITE signals
	reg [C_S_AXI_ADDR_WIDTH-1 : 0]  axi_awaddr;
	reg                             axi_awready;
	reg                             axi_wready;
	reg [1 : 0]                     axi_bresp;
	reg                             axi_bvalid;
	reg [C_S_AXI_ADDR_WIDTH-1 : 0]  axi_araddr;
	reg                             axi_arready;
	reg [C_S_AXI_DATA_WIDTH-1 : 0]  axi_rdata;
	reg [1 : 0]                     axi_rresp;
	reg                             axi_rvalid;

	// Example-specific design signals
	// local parameter for addressing 32 bit / 64 bit C_S_AXI_DATA_WIDTH
	// ADDR_LSB is used for addressing 32/64 bit registers/memories
	// ADDR_LSB = 2 for 32 bits (n downto 2)
	// ADDR_LSB = 3 for 64 bits (n downto 3)
	localparam integer ADDR_LSB = (C_S_AXI_DATA_WIDTH/32) + 1;
	localparam integer OPT_MEM_ADDR_BITS = 1;
	//----------------------------------------------
	//-- Signals for user logic register space example
	//------------------------------------------------
	//-- Number of Slave Registers 4
	wire     slv_reg_rden;
	wire     slv_reg_wren;
	reg [C_S_AXI_DATA_WIDTH-1:0]     reg_data_out;
	integer  byte_index;
	reg  aw_en;

	// I/O Connections assignments

	assign S_AXI_AWREADY = axi_awready;
	assign S_AXI_WREADY  = axi_wready;
	assign S_AXI_BRESP   = axi_bresp;
	assign S_AXI_BVALID  = axi_bvalid;
	assign S_AXI_ARREADY = axi_arready;
	assign S_AXI_RDATA   = axi_rdata;
	assign S_AXI_RRESP   = axi_rresp;
	assign S_AXI_RVALID  = axi_rvalid;
	// Implement axi_awready generation
	// axi_awready is asserted for one S_AXI_ACLK clock cycle when both
	// S_AXI_AWVALID and S_AXI_WVALID are asserted. axi_awready is
	// de-asserted when reset is low.

	always @( posedge S_AXI_ACLK )
	begin
		if ( S_AXI_ARESETN == 1'b0 )
		begin
			axi_awready <= 1'b0;
			aw_en <= 1'b1;
		end
		else
		begin
			if (~axi_awready && S_AXI_AWVALID && S_AXI_WVALID && aw_en)
			begin
				// slave is ready to accept write address when
				// there is a valid write address and write data
				// on the write address and data bus. This design
				// expects no outstanding transactions.
				axi_awready <= 1'b1;
				aw_en <= 1'b0;
			end
			else if (S_AXI_BREADY && axi_bvalid)
				begin
					aw_en <= 1'b1;
					axi_awready <= 1'b0;
				end
			else
			begin
				axi_awready <= 1'b0;
			end
		end
	end

	// Implement axi_awaddr latching
	// This process is used to latch the address when both
	// S_AXI_AWVALID and S_AXI_WVALID are valid.

	always @( posedge S_AXI_ACLK )
	begin
		if ( S_AXI_ARESETN == 1'b0 )
		begin
			axi_awaddr <= 0;
		end
		else
		begin
			if (~axi_awready && S_AXI_AWVALID && S_AXI_WVALID && aw_en)
			begin
				// Write Address latching
				axi_awaddr <= S_AXI_AWADDR;
			end
		end
	end

	// Implement axi_wready generation
	// axi_wready is asserted for one S_AXI_ACLK clock cycle when both
	// S_AXI_AWVALID and S_AXI_WVALID are asserted. axi_wready is
	// de-asserted when reset is low.

	always @( posedge S_AXI_ACLK )
	begin
		if ( S_AXI_ARESETN == 1'b0 )
		begin
			axi_wready <= 1'b0;
		end
		else
		begin
			if (~axi_wready && S_AXI_WVALID && S_AXI_AWVALID && aw_en )
			begin
				// slave is ready to accept write data when
				// there is a valid write address and write data
				// on the write address and data bus. This design
				// expects no outstanding transactions.
				axi_wready <= 1'b1;
			end
			else
			begin
				axi_wready <= 1'b0;
			end
		end
	end

	// Implement memory mapped register select and write logic generation
	// The write data is accepted and written to memory mapped registers when
	// axi_awready, S_AXI_WVALID, axi_wready and S_AXI_WVALID are asserted. Write strobes are used to
	// select byte enables of slave registers while writing.
	// These registers are cleared when reset (active low) is applied.
	// Slave register write enable is asserted when valid address and data are available
	// and the slave is ready to accept the write address and write data.
	assign slv_reg_wren = axi_wready && S_AXI_WVALID && axi_awready && S_AXI_AWVALID;

	always @( posedge S_AXI_ACLK )
	begin
		if ( S_AXI_ARESETN == 1'b0 )
		begin
			rx_en        <= 0;
			rx_inv       <= 0;
			irq_en       <= 0;
			pulse_period <= 0;
		end
		else begin
		if (slv_reg_wren)
			begin
			case ( axi_awaddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] )
				2'h0: begin
					if(S_AXI_WSTRB[0]) begin
						rx_en <= S_AXI_WDATA[0];
						rx_inv <= S_AXI_WDATA[1];
					end
					if(S_AXI_WSTRB[3]) begin
						irq_en <= S_AXI_WDATA[31];
					end
				end
				2'h1:
				for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
					if ( S_AXI_WSTRB[byte_index] == 1 ) begin
						pulse_period[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
					end
				default : begin
				end
			endcase
			end
		end
	end

	// Implement write response logic generation
	// The write response and response valid signals are asserted by the slave
	// when axi_wready, S_AXI_WVALID, axi_wready and S_AXI_WVALID are asserted.
	// This marks the acceptance of address and indicates the status of
	// write transaction.

	always @( posedge S_AXI_ACLK )
	begin
		if ( S_AXI_ARESETN == 1'b0 )
		begin
			axi_bvalid  <= 0;
			axi_bresp   <= 2'b0;
		end
		else
		begin
			if (axi_awready && S_AXI_AWVALID && ~axi_bvalid && axi_wready && S_AXI_WVALID)
			begin
				// indicates a valid write response is available
				axi_bvalid <= 1'b1;
				axi_bresp  <= 2'b0; // 'OKAY' response
			end                   // work error responses in future
			else
			begin
				if (S_AXI_BREADY && axi_bvalid)
				//check if bready is asserted while bvalid is high)
				//(there is a possibility that bready is always asserted high)
				begin
					axi_bvalid <= 1'b0;
				end
			end
		end
	end

	// Implement axi_arready generation
	// axi_arready is asserted for one S_AXI_ACLK clock cycle when
	// S_AXI_ARVALID is asserted. axi_awready is
	// de-asserted when reset (active low) is asserted.
	// The read address is also latched when S_AXI_ARVALID is
	// asserted. axi_araddr is reset to zero on reset assertion.

	always @( posedge S_AXI_ACLK )
	begin
		if ( S_AXI_ARESETN == 1'b0 )
		begin
			axi_arready <= 1'b0;
			axi_araddr  <= 32'b0;
		end
		else
		begin
			if (~axi_arready && S_AXI_ARVALID)
			begin
				// indicates that the slave has acceped the valid read address
				axi_arready <= 1'b1;
				// Read address latching
				axi_araddr  <= S_AXI_ARADDR;
			end
			else
			begin
				axi_arready <= 1'b0;
			end
		end
	end

	// Implement axi_arvalid generation
	// axi_rvalid is asserted for one S_AXI_ACLK clock cycle when both
	// S_AXI_ARVALID and axi_arready are asserted. The slave registers
	// data are available on the axi_rdata bus at this instance. The
	// assertion of axi_rvalid marks the validity of read data on the
	// bus and axi_rresp indicates the status of read transaction.axi_rvalid
	// is deasserted on reset (active low). axi_rresp and axi_rdata are
	// cleared to zero on reset (active low).
	always @( posedge S_AXI_ACLK )
	begin
		if ( S_AXI_ARESETN == 1'b0 )
		begin
			axi_rvalid <= 0;
			axi_rresp  <= 0;
		end
		else
		begin
			if (axi_arready && S_AXI_ARVALID && ~axi_rvalid)
			begin
				// Valid read data is available at the read data bus
				axi_rvalid <= 1'b1;
				axi_rresp  <= 2'b0; // 'OKAY' response
			end
			else if (axi_rvalid && S_AXI_RREADY)
			begin
				// Read data is accepted by the master
				axi_rvalid <= 1'b0;
			end
		end
	end

	// Implement memory mapped register select and read logic generation
	// Slave register read enable is asserted when valid address is available
	// and the slave is ready to accept the read address.
	assign slv_reg_rden = axi_arready & S_AXI_ARVALID & ~axi_rvalid;
	always @(*)
	begin
			// Address decoding for reading registers
			case ( axi_araddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] )
			2'h0   : reg_data_out <= {irq_en, 28'h0000000, rx_state == ST_DONE ? 1 : 0, rx_inv, rx_en};
			2'h1   : reg_data_out <= pulse_period;
			2'h2   : reg_data_out <= rx_data;
			2'h3   : reg_data_out <= {'b0, rx_state};
			default : reg_data_out <= 0;
			endcase
	end

	// Output register or memory read data
	always @( posedge S_AXI_ACLK )
	begin
		if ( S_AXI_ARESETN == 1'b0 )
		begin
			axi_rdata  <= 0;
		end
		else
		begin
			// When there is a valid read address (S_AXI_ARVALID) with
			// acceptance of read address by the slave (axi_arready),
			// output the read dada
			if (slv_reg_rden)
			begin
				axi_rdata <= reg_data_out;     // register read data
			end
		end
	end


	// User logic

	// REG 0: CSR (RW)
	// 0    - rx_en
	// 1    - rx_inv
	// 2    - done (R)
	// 31   - irq_en

	// REG 1: pulse period (RW)
	// 31:0 - pulse_period

	// REG 2: RX data (R)
	// 31:0 - rx_data

	// REG 3: FSM state (R)
	// 7:0  - FSM state


	logic        rx_inv;
	logic [31:0] pulse_period; // 56250 @100MHz
	logic        rx_en;
	logic        irq_en;

	assign irq = irq_en && rx_state == ST_DONE ? 1 : 0;

	logic data_cdc;
	logic data_in;

	xpm_cdc_single #(
		 .DEST_SYNC_FF  (3          )
		,.INIT_SYNC_FF  (0          )
		,.SIM_ASSERT_CHK(0          )
		,.SRC_INPUT_REG (0          )
	)
	xpm_cdc_data_rx (
		 .dest_out      (data_cdc   )
		,.dest_clk      (S_AXI_ACLK )
		,.src_clk       (           )
		,.src_in        (data_rx    )
	);

	assign data_in = rx_inv ? ~data_cdc : data_cdc;

	typedef enum logic [6:0] {
		 ST_IDLE        = 7'b0000001
		,ST_WAIT_HPULSE = 7'b0000010
		,ST_LEAD_PULSE  = 7'b0000100
		,ST_PACKET_TYPE = 7'b0001000
		,ST_DATA_PULSE  = 7'b0010000
		,ST_DATA        = 7'b0100000
		,ST_DONE        = 7'b1000000
	} rx_fsm;
	rx_fsm rx_state;

	always @(posedge S_AXI_ACLK) begin
		if (!S_AXI_ARESETN || !rx_en) begin
			rx_state <= ST_IDLE;
		end else case (rx_state)
			ST_IDLE : begin
				if(data_in)
					rx_state <= ST_WAIT_HPULSE;
			end
			/* **************** */
			ST_WAIT_HPULSE : begin
				if(pulse_cnt == pulse_period/2)
					rx_state <= ST_LEAD_PULSE;
			end
			/* **************** */
			ST_LEAD_PULSE : begin
				if(rd_en) begin
					if(bit_cnt == 15)
						rx_state <= ST_PACKET_TYPE;
					else if(!data_in)
						rx_state <= ST_IDLE;
				end
			end
			/* **************** */
			ST_PACKET_TYPE : begin
				if(bit_cnt == 7 && rd_en) begin
					if(ptype == 8'h00)
						rx_state <= ST_DATA_PULSE;
					else if(ptype == 8'h10)
						rx_state <= ST_DONE;
					else
						rx_state <= ST_IDLE;
				end
			end
			/* **************** */
			ST_DATA_PULSE : begin
				if(rd_en)
					rx_state <= ST_DATA;
			end
			/* **************** */
			ST_DATA : begin
				if(bit_cnt == 32 && rd_en)
					rx_state <= ST_DONE;
			end
			/* **************** */
			ST_DONE : begin
				if(slv_reg_wren && axi_awaddr == 0 && S_AXI_WSTRB[0] && S_AXI_WDATA[2] == 0)
					rx_state <= ST_IDLE;
			end
			/* **************** */
			default: begin
			end
		endcase
	end
	
	logic rd_en;
	always @(posedge S_AXI_ACLK) begin
		if(!S_AXI_ARESETN || !rx_en)
			rd_en <= 0;
		else begin
			if(pulse_cnt == pulse_period)
				rd_en <= 1;
			else
				rd_en <= 0;
		end
	end

	logic [15:0] pulse_cnt;
	always @(posedge S_AXI_ACLK) begin
		if(!S_AXI_ARESETN || !rx_en)
			pulse_cnt <= pulse_period/2;
		else begin
			if(rx_state == ST_IDLE || rx_state == ST_DONE)
				pulse_cnt <= pulse_period/2;
			else begin
				if(pulse_cnt >= pulse_period)
					pulse_cnt <= 0;
				else
					pulse_cnt <= pulse_cnt + 1;
			end
		end
	end

	logic [6:0] bit_cnt;
	always @(posedge S_AXI_ACLK) begin
		if(!S_AXI_ARESETN || rx_state == ST_IDLE || !rx_en)
			bit_cnt <= 0;
		else begin
			if(rd_en) begin
				case (rx_state)
					ST_LEAD_PULSE : begin
						if(bit_cnt == 15)
							bit_cnt <= 0;
						else
							bit_cnt <= bit_cnt + 1;
					end
					/* **************** */
					ST_PACKET_TYPE : begin
						if(bit_cnt == 7)
							bit_cnt <= 0;
						else
							bit_cnt <= bit_cnt + 1;
					end
					/* **************** */
					ST_DATA : begin
						if(data_in) begin
							if(bit_cnt == 32)
								bit_cnt <= 0;
							else
								bit_cnt <= bit_cnt + 1;
						end
					end
					/* **************** */
					default: begin
					end
				endcase
			end
		end
	end

	logic [7:0] ptype;
	always @(posedge S_AXI_ACLK) begin
		if(!S_AXI_ARESETN || !rx_en)
			ptype <= 8'h00;
		else begin
			if(rx_state == ST_PACKET_TYPE && rd_en)
				ptype[bit_cnt] <= data_in;
		end
	end

	logic [1:0] data_bit;
	always @(posedge S_AXI_ACLK) begin
		if(!S_AXI_ARESETN || rx_state == ST_IDLE || !rx_en)
			data_bit <= 0;
		else if(rx_state == ST_DATA && rd_en) begin
			if(data_in)
				data_bit <= 0;
			else
				data_bit <= data_bit + 1;
		end
	end

	logic [31:0] rx_data;
	always @(posedge S_AXI_ACLK) begin
		if(!S_AXI_ARESETN || !rx_en)
			rx_data <= 0;
		else if(rx_state == ST_DATA && data_in && rd_en)
			rx_data[bit_cnt] <= (data_bit == 1) ? 0 : 1;
	end

endmodule
