`timescale 1ns/1ps

module mixed_precision_mac (
    input  logic               clk,
    input  logic               rst_n,
    input  logic               enable,
    input  logic               clear_acc,
    input  logic               precision_mode, // 0: INT4, 1: INT8
    input  logic signed [7:0]  activation,
    input  logic signed [7:0]  weight,
    output logic signed [31:0] accumulator
);

    logic signed [7:0] activation_operand;
    logic signed [7:0] weight_operand;
    logic signed [15:0] product;

    // INT4 mode interprets the low four bits as signed two's complement.
    // INT8 mode uses the complete signed eight-bit input.
    always_comb begin
        if (precision_mode) begin
            activation_operand = activation;
            weight_operand     = weight;
        end else begin
            activation_operand = {
                {4{activation[3]}}, activation[3:0]
            };
            weight_operand = {
                {4{weight[3]}}, weight[3:0]
            };
        end
    end

    // Exact signed multiplication for the selected operand precision.
    always_comb begin
        product = activation_operand * weight_operand;
    end

    // Synchronous accumulator clear; asynchronous active-low reset.
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            accumulator <= 32'sd0;
        end else if (clear_acc) begin
            accumulator <= 32'sd0;
        end else if (enable) begin
            accumulator <= accumulator + {{16{product[15]}}, product};
        end
    end

endmodule
