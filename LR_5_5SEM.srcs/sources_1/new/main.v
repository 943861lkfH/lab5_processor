module main(
    input clk,
    input reset,
    output pc
    );
    
cpu_conv3_mips cpu(.clk_in(clk), .reset(reset), .pc(pc));
    
endmodule