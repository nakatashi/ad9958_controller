/*
 * Registers accessed in this project is listed here.
 */

`ifndef _AD9958_ADDRESS_VH_

`define _AD9958_ADDRESS_VH_

`define ADDR_CSR 8'h00
`define ADDR_FR1 8'h01
`define ADDR_FR2 8'h02
`define ADDR_CFR 8'h03
`define ADDR_CFTW0 8'h04
`define ADDR_ACR 8'h06

// bit size of each register.
`define SIZE_INST 8 //2
`define SIZE_CSR 8 //2
`define SIZE_FR1 24 //6
`define SIZE_FR2 16 //4
`define SIZE_CFR 24 //6
`define SIZE_CFTW0 32 //8
`define SIZE_ACR 16 //4
`endif
