`define PC_WIDTH 10
`define COMMAND_SIZE 46
`define PROGRAM_SIZE 1024 // 1024
`define DATA_SIZE 1024 // 1024
`define OP_SIZE 4
`define ADDR_SIZE 10

`define NOP 0
`define LOAD 1
`define ADD 2
`define SUB 4
`define JMP_GZ 5

`define INCR 9
`define CMP 6
`define MOV 7
`define JMP_NZ 8
`define MUL 3

/*
    Формат команды:
    ADD, SUB, NOP, MUL:
    | код операции  | Адрес 1            | Адрес 2         | Адрес 3
         4 бита     | 10 бит             | 10 бит          | 10 бит
    CMP, MOV:
    | код операции  | Адрес 1            | Адрес 2         |        
         4 бита     | 10 бит             | 10 бит          | 20 бит
    INCR:
    | код операции  | Адрес 1            |        
         4 бита     | 10 бит             |           32 бита
    LOAD:
    | код операции  |  адрес в памяти    |           Литерал             |
         4 бита     |     10 бит         |            32 бита            |
    JMP_GZ:
    | код операции  |           Адрес перехода      |                        |
         4 бита     |            10 бит             |       32 бита          |
    
*/


module cpu_conv3_mips(
    input clk_in,
    input reset,
    output pc
);

wire clk;
reg[`PC_WIDTH-1 : 0] pc, newpc;


reg [`COMMAND_SIZE-1 : 0]   Program [0:`PROGRAM_SIZE - 1  ];
reg [31:0]                  Data    [0:`DATA_SIZE - 1];

reg[`COMMAND_SIZE-1 : 0] command_1, command_2, command_3;
wire [`OP_SIZE - 1 : 0] op_2 = command_2 [`COMMAND_SIZE - 1 -: `OP_SIZE];
wire [`OP_SIZE - 1 : 0] op_3 = command_3 [`COMMAND_SIZE - 1 -: `OP_SIZE];

wire [`ADDR_SIZE - 1 : 0] addr1 = command_2[`COMMAND_SIZE - 1 - `OP_SIZE                 -: `ADDR_SIZE];
wire [`ADDR_SIZE - 1 : 0] addr2 = command_2[`COMMAND_SIZE - 1 - `OP_SIZE - `ADDR_SIZE    -: `ADDR_SIZE];

wire [$clog2(`DATA_SIZE) - 1 : 0] new_addr = command_3 [`COMMAND_SIZE - 1 - `OP_SIZE -: $clog2(`DATA_SIZE)];
wire [$clog2(`DATA_SIZE) - 1 : 0] addr_to_load = command_3 [`COMMAND_SIZE - 1 - `OP_SIZE - `ADDR_SIZE - `ADDR_SIZE -: $clog2(`DATA_SIZE)];
wire [$clog2(`DATA_SIZE) - 1 : 0] addr_to_load_L = command_3 [`COMMAND_SIZE - 1 - `OP_SIZE  -: `ADDR_SIZE];

wire [31:0] literal_to_load = command_3 [`COMMAND_SIZE - 1 - `OP_SIZE - $clog2(`DATA_SIZE) -: 32];
reg [31:0] Reg_A, Reg_B, newReg_A, newReg_B;
reg flag_GZ, new_flag_GZ;
reg flag_NZ, new_flag_NZ;

integer i;
initial 
begin
    pc = 0; newpc = 0;
    $readmemb("MyMem.mem", Program); //Program_Svertka.mem
    for(i = 0; i < `DATA_SIZE; i = i + 1)
        Data[i] = 32'b0;
    command_1 = 0;
    command_2 = 0;
    command_3 = 0;
    Reg_A = 0;
    Reg_B = 0;
    newReg_A = 0; 
    newReg_B = 0;
end

clk_wiz_0 inst(
    .clk_in1(clk_in),
    .clk_out1(clk)
);

//Блок управления счётчиком команд
always@(posedge clk)
    if(reset)
        pc <= 0;
    else
        pc <= newpc;


//Такт 2
//Изменение регистра A
always @(posedge clk)
begin 
    if(reset) Reg_A <= 0;
    else Reg_A <= newReg_A;
end

//Изменение регистра B
always @(posedge clk)
begin 
    if(reset) Reg_B <= 0;
    else Reg_B <= newReg_B;
end


always @*
begin
    case(op_2)
        `ADD, `SUB:
            if(addr1 == addr_to_load && (op_3 == `ADD || op_3 == `SUB) || addr1 == addr_to_load && (op_3 == `LOAD))
                newReg_A <= new_data;
            else newReg_A <= Data[addr1];
         `CMP: begin
            newReg_A = Data[addr1];
            newReg_A = Data[newReg_A];
            end
         `MUL: begin
            newReg_A = Data[addr1];
            //newReg_A = Data[newReg_A];
            end
        default: newReg_A <= newReg_A;
    endcase
end

always @*
begin
    case(op_2)
        `ADD, `SUB:
            if(addr2 == addr_to_load && (op_3 == `ADD || op_3 == `SUB) || addr2 == addr_to_load_L && (op_3 == `LOAD))
                newReg_B <= new_data;
            else newReg_B <= Data[addr2];
        `CMP:
            newReg_B <= Data[addr2];
        `MUL: begin
            newReg_B = Data[addr2];
            //newReg_B = Data[newReg_B];
            end
        `MOV: begin
            newReg_B = Data[addr2];
            newReg_B = Data[newReg_B];
            end
        default: newReg_B <= newReg_B;
    endcase
end

//Такт_3
reg signed [31:0] new_data;

always @(posedge clk)
begin
    case(op_3)
        `ADD, `SUB:
            Data[addr_to_load] <= new_data;
         `MOV:
            Data[Data[addr_to_load_L]] <= new_data;
         `MUL:
            Data[addr_to_load] <= new_data;
         `INCR:
            Data[addr_to_load_L] <= new_data;
         `LOAD:
            Data[addr_to_load_L] <= new_data;
    endcase
end

always @*
begin
    case(op_3)
        `ADD: new_data <= Reg_A + Reg_B;
        `SUB: new_data <= Reg_A - Reg_B;
        `MOV: new_data <= Reg_B;
        `MUL: new_data <= Reg_A * Reg_B;
        `INCR: new_data <= Data[addr_to_load_L] + 1;
        `LOAD: new_data <= literal_to_load;
    endcase
end

always @(posedge clk)
begin
    flag_GZ <= new_flag_GZ;
    flag_NZ <= new_flag_NZ;
end

always @*
begin 
    case(op_3)
        `ADD, `SUB: 
            new_flag_GZ <= new_data <= 0;
        `CMP: begin
            new_flag_GZ <= Reg_A == Reg_B;
            new_flag_NZ <= ~(Reg_A == Reg_B);
            end
    endcase
end

//Блок определения следующего значения счётчика команд
always@*
begin
    if(op_3 == `JMP_GZ && new_flag_GZ)
        newpc <= new_addr;
    else if (op_3 == `JMP_NZ && new_flag_NZ)
        newpc <= new_addr;
    else
        newpc <= pc + 1;
end

always@(posedge clk)
begin
    command_1 <= Program[pc];
    command_2 <= command_1;
    command_3 <= command_2;
end


endmodule
