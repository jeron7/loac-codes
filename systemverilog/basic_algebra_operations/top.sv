// DESCRIPTION: Verilator: Systemverilog example module
// with interface to switch buttons, LEDs, LCD and register display

`include "constants.sv"

parameter NINSTR_BITS = 32;
parameter NBITS_TOP = 8, NREGS_TOP = 32, NBITS_LCD = 64;
module top(input  logic clk_2,
           input  logic [NBITS_TOP-1:0] SWI,
           output logic [NBITS_TOP-1:0] LED,
           output logic [NBITS_TOP-1:0] SEG,
           output logic [NBITS_LCD-1:0] lcd_a, lcd_b,
           output logic [NINSTR_BITS-1:0] lcd_instruction,
           output logic [NBITS_TOP-1:0] lcd_registrador [0:NREGS_TOP-1],
           output logic [NBITS_TOP-1:0] lcd_pc, lcd_SrcA, lcd_SrcB,
             lcd_ALUResult, lcd_Result, lcd_WriteData, lcd_ReadData, 
           output logic lcd_MemWrite, lcd_Branch, lcd_MemtoReg, lcd_RegWrite);

  always_comb begin
    lcd_WriteData <= SWI;
    lcd_pc <= 'h12;
    lcd_instruction <= 'h34567890;
    lcd_SrcA <= 'hab;
    lcd_SrcB <= 'hcd;
    lcd_ALUResult <= 'hef;
    lcd_Result <= 'h11;
    lcd_ReadData <= 'h33;
    lcd_MemWrite <= SWI[0];
    lcd_Branch <= SWI[1];
    lcd_MemtoReg <= SWI[2];
    lcd_RegWrite <= SWI[3];
    for(int i=0; i<NREGS_TOP; i++) lcd_registrador[i] <= i+i*16;
    lcd_a <= {56'h1234567890ABCD, SWI};
    lcd_b <= {SWI, 56'hFEDCBA09876543};
  end

  // ----------------------------------------------------------------------------------------------------------------------------------------
  // 1. Implemente um circuito que represente um valor inteiro de tamanho 3 bits (SWI[2:0]) em base decimal no display de sete segmentos
  // Número de BITS que podem representar um número inteiro para operações simples
  parameter NBITS_INT = 3;
  // Número de bits que representam um valor no segmento
  parameter NBITS_SEG = 8;
  
  // Entrada:
  // Número inteiro com sinal representado com 3 bits
  logic signed [NBITS_INT - 1:0] number_to_show;

  // Atribuição das entrada:
  // Define os switches responsáveis por representar o número
  always_comb number_to_show <= SWI[NBITS_INT - 1:0];
 
  // Saída:
  // Vetor binário com 8 bits que representa o número a ser mostrado no segmento
  logic [NBITS_SEG - 1:0] to_segment;

  // Atribuição de saída:
  // É atribuido o vetor binário com 8 bits aos 8 bits do segmento (onde o bit mais significativo é o ponto  
  // que aqui representará o sinal)
  always_comb SEG[NBITS_SEG - 1:0] <= to_segment;

  always_comb begin 
    case(number_to_show)
      // Caso seja zero, mostra representação de zero no segmento 
      0: to_segment <= `ZERO_SEG;
      // Caso seja um, mostra representação de um no segmento
      1: to_segment <= `ONE_SEG;
      // Caso seja dois, mostra representação de dois no segmento
      2: to_segment <= `TWO_SEG;
      // Caso seja três, mostra representação de três no segmento
      3: to_segment <= `THREE_SEG;
      // Caso seja quatro negativo, mostra representação de quatro negativo no segmento
      -4: to_segment <= {`NEGATIVE_SIGNAL, `FOUR_SEG};
      // Caso seja três negativo, mostra representação de três negativo no segmento
      -3: to_segment <= {`NEGATIVE_SIGNAL, `THREE_SEG};
      // Caso seja dois negativo, mostra representação de dois negativo no segmento
      -2: to_segment <= {`NEGATIVE_SIGNAL, `TWO_SEG};
      // Caso seja um negativo, mostra representação de um negativo no segmento
      -1: to_segment <= {`NEGATIVE_SIGNAL, `ONE_SEG};
      // Caso seja qualquer número que não seja possível representar com 3 bits
      default: to_segment <= `NOT_AN_NUMBER;
    endcase
  end

  // ----------------------------------------------------------------------------------------------------------------------------------------
  // 2. Implemente um somador para dois valores inteiros de 3 bits (SWI[7:5) e SWI[2:0]) e visualize o resultado de 3 bits em LED[2:0].
  // Visualize o resultado também em base decimal no display de sete segmentos

  // Incremento na posição do vetor para representar o valor de A
  parameter A_POS_INCREMENT = 5;
  
  // Entradas:
  // Número inteiro A com sinal representado com 3 bits
  logic signed [NBITS_INT - 1:0] A;
  // Número inteiro B com sinal representado com 3 bits
  logic signed [NBITS_INT - 1:0] B;

  // Atribuição das entradas:
  // Define os switches responsáveis por representar o número de A
  always_comb A <= SWI[A_POS_INCREMENT + NBITS_INT - 1: A_POS_INCREMENT];
  // Define os switches responsáveis por representar o número de B
  always_comb B <= SWI[NBITS_INT - 1:0];
 
  // Saída:
  // Vetor de 3 bits que contém o resultado da soma 
  logic signed [NBITS_INT - 1:0] sum;

  always_comb begin
      // Representação binária da soma
      sum <= (A + B);
  end

   // ---------------------------------------------------------------------------------------------------------------------------------------- 
  // 3. Indique a ocorrência de overflow ou underflow para valores inteiros no LED[7]. 
  // No caso de overflow ou underflow não importa o que estiver no display de sete segmentos.

  parameter ERROR_DETECTION_POS = 7;
  
  // Saída:  
  // Representa se ouve ou não um overflow ou underflow
  logic error_detection;
  // Representa o carry out dos bits mais significativos(last ou últimos) e dos penultimo bit mais significativos
  logic penultimate_carry_out, last_carry_out;

  // Atribuição da saída:
  // Define os switch responsável por representar aS operações de subtração ou soma
  always_comb LED[ERROR_DETECTION_POS] <= error_detection;

  // Pega o carry out dos penúltimos bits mais significativos
  always_comb begin
    penultimate_carry_out <= A[NBITS_INT - 2] & B[NBITS_INT - 2];
  end

  // Pega o carry out dos bits mais significativos
  always_comb begin
    last_carry_out <= A[NBITS_INT - 1] & B[NBITS_INT - 1];
  end

  // Representa se ouve ou não o overflow ou underflow
  always_comb error_detection <= last_carry_out ^ penultimate_carry_out;

  // ---------------------------------------------------------------------------------------------------------------------------------------- 
  // 4. Implemente a operação de subtração para o caso a chave SWI[3]=F[0] estiver em '1'. 
  // Com a chave SWI[3] em '0' o somador continua funcionando.
  
  // Define a quantidade de bits que representam os operadores
  parameter NBITS_OPER = 2;
  
  // Entrada:  
  // Representa o valor para uma operação aritmética, onde: 00 - soma, 01 - subtração, 10 - multiplicação de números naturais e
  // 11 - multiplicação de inteiros
  logic [NBITS_OPER - 1 : 0] F;

  // Atribuição das entradas:
  // Define os switch responsável por representar aS operações de subtração ou soma
  always_comb F[0] <= SWI[3];
 
  // Saída:
  // Vetor de 3 bits que contém o resultado da subtração 
  logic signed [NBITS_INT - 1:0] substract;

  always_comb begin
      substract <= A - B;
  end

  // ---------------------------------------------------------------------------------------------------------------------------------------- 
  // 5. Implemente a operação de subtração para o caso a chave SWI[3]=F[0] estiver em '1'. 
  // Com a chave SWI[3] em '0' o somador continua funcionando.
  // Representa o número de bits para operações de multiplicação
  parameter NBITS_INT_MULT = 6;

    // Atribuição das entradas:
  // Define os switch responsável por representar aS operações de subtração ou soma
  always_comb F[1] <= SWI[4];

  // Saídas:
  // Vetor de 6 bits que contém o resultado da multiplicação entre números naturais
  logic unsigned [NBITS_INT_MULT - 1:0] unsigned_mult;
  // Vetor de 6 bits que contém o resultado da multiplicação entre números inteiros
  logic signed [NBITS_INT_MULT - 1:0] signed_mult;
  // Vetor de 6 bits que contém o resultados das operações
  logic [NBITS_INT_MULT - 1:0] result;

  // Atribuição de saída:
  // Representação binaria dos resultados das operações nos LEDS 
  always_comb LED[NBITS_INT_MULT - 1:0] <= result;

  // Define as operações multiplicação com naturais e inteiros
  always_comb begin
      unsigned_mult <= $unsigned(A) * $unsigned(B);
      signed_mult <= A * B;
  end

  // Switch case mostrar o resultado para uma das quatro operações.
  // A operação é escolhida usando o sinal lógico F, que é representado pelo SWI[4] como o bit mais
  // significativo e o SWI[3] o menos significativo
  always_comb begin
      case(F)
        // Resultado da operação de soma 3 bits mais a esquerda com 0
        `ADD_OPER: begin 
                      result <= {3'b0, sum};
                      // Mostra a representação decimal do valor da soma no segmento
                      number_to_show <= sum;
                   end
        // Resultado da operação de soma 3 bits mais a esquerda com 0
        `SUB_OPER: result <= {3'b0, substract};
        // Multiplicação utilizando números naturais
        `MULT_UNSIGNED_OPER: result <= unsigned_mult;
        // Multiplicação utilizando números inteiros
        `MULT_SIGNED_OPER: result <= signed_mult;
        default: result <= 0;
      endcase
  end
endmodule