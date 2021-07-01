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

  // Ar condicionado - sem temperatura desejada
  // https://github.com/OpenDevUFCG/Tamburetei/blob/master/loac/leites/maquinasDeEstados/arcondicionado.md

  // Definido a posição de elementos de entrada
  parameter DECREASE_SWI = 0, INCRESE_SWI = 1, RESET_SWI = 7, CLOCK_LED = 7;
  // Definindo tamanho e posições de elementos de saída
  parameter TEMP_NBITS = 3, DRIPPING_LED = 3, CYCLES_NBITS = 4;
  // Definindo estados e seus tamanhos
  parameter STATE_NBITS = 2;
  enum logic [STATE_NBITS - 1 : 0] {
    NORMAL,
    DRIP
  } state;
  
  // Entradas
  // clock com 1Hz
  logic clock;
  // Indica que a temperatura deve diminuir 1 grau
  logic decrease;
  // Indica que a temperatura deve aumentar 1 grau
  logic increase;
  // Deixa o ar condicionado no estado inicial
  logic reset;

  // Atribuição de entradas:
  always_comb begin
    decrease <= SWI[DECREASE_SWI];
    increase <= SWI[INCRESE_SWI];
    reset <= SWI[RESET_SWI];
  end

  // Saídas
  // Temperatura real
  logic [TEMP_NBITS - 1:0] temperature;
  // Indica se está gotejando
  logic dripping;
  // Ciclos de clock
  logic [CYCLES_NBITS - 1:0] cycles = `CYCLE_INIT_VALUE;
    
  // Atribuição de saídas:
  always_comb begin
    LED[TEMP_NBITS - 1 : 0] <= temperature;
    LED[DRIPPING_LED] <= dripping;
    LED[CLOCK_LED] <= clock;
  end

  // Pega o clock de 1Hz
  always_ff @(posedge clk_2) begin
    clock <= ~clock;
  end

  always_ff @(posedge clock or posedge reset) begin
    // Quando o ar condicionado é resetado, esses são seus estados
    if (reset) begin
      state <= NORMAL;
      temperature <= `TEMP_INIT;
      dripping <= `NOT_DRIPPING;
      cycles <= `CYCLE_INIT_VALUE;
    end
    else begin
      if (decrease != increase) begin
        // A temperatura só aumentar até 7 (27 graus)
        if (increase && temperature < 7) begin
          temperature <= temperature + `INCRESE_VALUE;
        // A temperatura só diminui até 0 (20 graus)
        end else if (decrease && temperature > 0) begin
          temperature <= temperature - `DECREASE_VALUE;
        end
      end

      unique case (state)
        // Define o que ocorre em estado normal (sem gotejamento)
        NORMAL: begin
          // Realiza contagem de ciclos de clock
          cycles <= cycles + 1;
          // Caso chegue a 10 ciclos de clock e não esteja gotejando, muda de para gotejando
          if (cycles == `CYCLES_TO_DRIP && !dripping) begin
            state <= DRIP;
            cycles <= `CYCLE_INIT_VALUE;
            dripping <= `DRIPPING;
          end
        end
        // Estado em que está ocorrendo gotejamento 
        DRIP: begin
          // Se a temperatura é a máxima, há contagem de ciclos de clock
          if (temperature == `MAX_TEMPERATURE)
            cycles <= cycles + 1;
          // Quando se tem 4 ciclos de clock no estado de gotejamento, há mudança para o normal e para de gotejar
          if (cycles == `CYCLES_TO_NORMAL) begin
            state <= NORMAL;
            dripping <= `NOT_DRIPPING;
            cycles <= `CYCLE_INIT_VALUE;
          end
        end
      endcase
    end
  end
endmodule