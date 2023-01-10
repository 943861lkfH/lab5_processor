module test();

reg clk, reset;

initial begin
clk = 1'b0;
reset = 1'b0;
end

always #10
    clk = ~clk;

main m(.clk(clk), .reset(reset), .pc(pc));

endmodule
