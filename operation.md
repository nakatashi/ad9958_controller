# Operation
## Sending command via SPI
1. (instruction_write) Send Instruction bytes (includes information of write/read, address to the register to access)
 In this project, only write feature is used. 
2. (send_xx) Send desired data to selected register
3. (io_update) Latch IO Update if necessary.

## Initialization
1. Issue master reset
2. instruction_write to CSR, send data disable ch0, 1, set io mode to 4-bit mode, send in MSB first
3. io_update
4. instruction_write to FR1, vcogain, clock multiplier (pll divider ratio), 
5. io_update
6. instruction_write to FR2, (no need to do this operation, because all the values are not changed from default value.)
7. io_update


## Main Loop
just set frequency
1. instruction_write to CSR, enable ch0 select serial mode, MSB First,
2. instruction_write to FTW set frequency for ch0
3. instruction_write to CSR, enable ch1 select serial mode, MSB First,
4. instruction_write to FTW set frequency for ch1
ioupdate.


# State machine behaviour description
list of state machine
- STATE_MASTER_RESET
- STATE_IO_UPDATE
- STATE_INSTRUCTION_WRITE
- STATE_CSR_CONFIG
- STATE_FR1_CONFIG
- STATE_FR2_CONFIG
- STATE_FTW_CONFIG
- STATE_ASF_CONFIG

and other state machine...

channel selection

- CH0_SELECTED
- CH1_SELECTED
- BOTH_SELECTED
- NONE_SELECTED

variable

state, nextstate
address


intial state = MASTER_RESET


