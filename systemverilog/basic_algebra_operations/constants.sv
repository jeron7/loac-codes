// Representações no segmento

// Define a representação de números de 0 à 3
`define ZERO_SEG 7'b0111111
`define ONE_SEG 7'b0000110
`define TWO_SEG 7'b1011011
`define THREE_SEG 7'b1001111
`define FOUR_SEG 7'b1100110

// Define casos especiais
`define NEGATIVE_SIGNAL 1'b1
`define NOT_AN_NUMBER 8'b0

// Define operações de soma, subtração, multiplicação com naturais e com inteiros
`define ADD_OPER 2'b00
`define SUB_OPER 2'b01
`define MULT_UNSIGNED_OPER 2'b10
`define MULT_SIGNED_OPER 2'b11