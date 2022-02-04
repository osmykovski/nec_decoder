# NEC Decoder
This logic receives and decodes IR remote commands.

## Ports

| Port name         | Description                    |
|-------------------|--------------------------------|
| `S_AXI_ACLK`      | AXI4 bus clock input           |
| `S_AXI_ARESETN`   | Core reset                     |
| `S_AXI_*`         | AXI4 Lite control interface    |
| `data_rx`         | IR receiver input port         |
| `irq`             | Interrupt request output port  |

## Registers

| Register   | Description                  | Address |
|------------|------------------------------|---------|
| `CSR`      | Control and status register  | `0x00`  |
| `Period`   | Clock divide value           | `0x04`  |
| `RX`       | Received data                | `0x08`  |
| `FSM`      | FSM State for debug purporse | `0x0c`  |

### `CSR`

| Bits   | Function     |
|--------|--------------|
| `31`   | IRQ Enable   |
| `30:3` | *Reserved*   |
| `2`    | RX Done      |
| `1`    | RX inversion |
| `0`    | RX Enable    |

### `Period`

| Bits   | Function     |
|--------|--------------|
| `31:0` | Div value    |

### `RX`

| Bits   | Function     |
|--------|--------------|
| `31:0` | RX value     |

### `FSM`

| Bits   | Function     |
|--------|--------------|
| `31:7` | *Reserved*   |
| `6:0`  | FSM state    |


### States description

| Value  | State              | Description                                                        |
|--------|--------------------|--------------------------------------------------------------------|
| 1      | `ST_IDLE`          | Receiver is idle                                                   |
| 2      | `ST_WAIT_HPULSE`   | Wait half of the period to latch the data at the center of the bit |
| 4      | `ST_LEAD_PULSE`    | 9 ms (16 bit) leading pulse. Also used for glitch filtering        |
| 8      | `ST_PACKET_TYPE`   | Determine packet type: `0x10` when repeat packet                   |
| 16     | `ST_DATA_PULSE`    | Data capture first pulse                                           |
| 32     | `ST_DATA`          | Data capture                                                       |
| 64     | `ST_DONE`          | Capture is done                                                    |

## Driver usage

1. Create `nec_decoder` instance and fill in its fields.
1. Call `NEC_Init()` to configure the IP-core
1. In polling mode, check if the core done receiving using `NEC_is_done()`
1. If something is received, get the data using `NEC_get_data()` function
