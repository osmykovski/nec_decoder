#ifndef SRC_NEC_H_
#define SRC_NEC_H_

#define CSR          0x00
#define PULSE_PERIOD 0x04
#define RX_DATA      0x08
#define FSM_STATE    0x0C

#define RX_EN(val)  (val << 0)
#define RX_INV(val) (val << 1)
#define DONE        (1   << 2)
#define IRQ_EN(val) (val << 31)

typedef struct {
	UINTPTR BaseAddress;
	u32 period;
	u32 is_inverse;
	u32 irq_en;
} nec_decoder;

void NEC_Init(nec_decoder *inst){
	Xil_Out32(inst->BaseAddress + CSR, RX_EN(1) | RX_INV(inst->is_inverse) | IRQ_EN(inst->irq_en));
	Xil_Out32(inst->BaseAddress + PULSE_PERIOD, inst->period);
}

u32 NEC_is_done(nec_decoder *inst){
	return (Xil_In32(inst->BaseAddress + CSR) & DONE) >> 2;
}

u32 NEC_get_data(nec_decoder *inst){
	Xil_Out32(inst->BaseAddress + CSR, Xil_In32(inst->BaseAddress + CSR) & ~DONE);
	return Xil_In32(inst->BaseAddress + RX_DATA);
}

#endif /* SRC_NEC_H_ */
