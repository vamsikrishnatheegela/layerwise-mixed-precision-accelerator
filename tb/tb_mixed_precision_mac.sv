`timescale 1ns/1ps

module tb_mixed_precision_mac;

    logic clk = 1'b0;
    logic rst_n = 1'b0;
    logic enable = 1'b0;
    logic clear_acc = 1'b0;
    logic precision_mode = 1'b0;

    logic signed [7:0] activation = '0;
    logic signed [7:0] weight = '0;
    logic signed [31:0] accumulator;

    integer checks = 0;

    // Generate a 100 MHz clock (10 ns period).
    always #5 clk = ~clk;

    // Device under test.
    mixed_precision_mac dut (
        .clk           (clk),
        .rst_n         (rst_n),
        .enable        (enable),
        .clear_acc     (clear_acc),
        .precision_mode(precision_mode),
        .activation    (activation),
        .weight        (weight),
        .accumulator   (accumulator)
    );

    // Check the accumulator against an expected result.
    task automatic check_accumulator(
        input logic signed [31:0] expected,
        input string test_name
    );
        begin
            // Allow nonblocking assignments to complete.
            #1;
            checks = checks + 1;

            if (accumulator !== expected) begin
                $error(
                    "FAIL %s: expected %0d, got %0d",
                    test_name,
                    expected,
                    accumulator
                );
                $fatal(1, "Testbench failed.");
            end

            $display(
                "PASS %s: accumulator=%0d",
                test_name,
                accumulator
            );
        end
    endtask

    // Apply one MAC operation and check its accumulated result.
    task automatic apply_mac(
        input logic mode,
        input logic signed [7:0] a,
        input logic signed [7:0] b,
        input logic signed [31:0] expected,
        input string test_name
    );
        begin
            @(negedge clk);

            precision_mode = mode;
            activation     = a;
            weight         = b;
            enable         = 1'b1;
            clear_acc      = 1'b0;

            @(posedge clk);
            check_accumulator(expected, test_name);

            @(negedge clk);
            enable = 1'b0;
        end
    endtask

    // Clear the accumulator between independent test cases.
    task automatic clear_accumulator(
        input string test_name
    );
        begin
            @(negedge clk);
            clear_acc = 1'b1;
            enable    = 1'b0;

            @(posedge clk);
            check_accumulator(32'sd0, test_name);

            @(negedge clk);
            clear_acc = 1'b0;
        end
    endtask

    initial begin
        $dumpfile("results/waveforms/mixed_precision_mac.vcd");
        $dumpvars(0, tb_mixed_precision_mac);

        $display("------------------------------------------");
        $display(" Mixed-Precision MAC Verification");
        $display("------------------------------------------");

        // --------------------------------------------------
        // 1. Reset test
        // --------------------------------------------------
        rst_n = 1'b0;

        repeat (2) @(negedge clk);
        rst_n = 1'b1;

        check_accumulator(32'sd0, "Reset");

        // --------------------------------------------------
        // 2. INT4 tests
        //
        // INT4 operands are interpreted as signed
        // two's-complement values from -8 through +7.
        // --------------------------------------------------

        // 7 * 7 = 49
        apply_mac(
            1'b0,
            8'h07,
            8'h07,
            32'sd49,
            "INT4 maximum positive"
        );

        // The low nibble of 8'h0F represents -1.
        // Accumulator: 49 + (-1 * 1) = 48.
        apply_mac(
            1'b0,
            8'h0F,
            8'h01,
            32'sd48,
            "INT4 negative one"
        );

        // The low nibble of 8'h08 represents -8.
        // Accumulator: 48 + (-8 * 1) = 40.
        apply_mac(
            1'b0,
            8'h08,
            8'h01,
            32'sd40,
            "INT4 minimum negative"
        );

        // Clear the accumulator before INT8 testing.
        clear_accumulator("Clear after INT4 tests");

        // --------------------------------------------------
        // 3. INT8 tests
        //
        // INT8 operands use the complete signed 8-bit
        // input range: -128 through +127.
        // --------------------------------------------------

        // 127 * 127 = 16129
        apply_mac(
            1'b1,
            8'sd127,
            8'sd127,
            32'sd16129,
            "INT8 maximum positive product"
        );

        // Clear before testing the negative product.
        clear_accumulator("Clear before INT8 negative test");

        // -128 * 1 = -128
        apply_mac(
            1'b1,
            -8'sd128,
            8'sd1,
            -32'sd128,
            "INT8 minimum negative"
        );

        // Clear before the next independent test.
        clear_accumulator("Clear before INT8 minimum product");

        // -128 * -128 = 16384
        apply_mac(
            1'b1,
            -8'sd128,
            -8'sd128,
            32'sd16384,
            "INT8 minimum times minimum"
        );

        // --------------------------------------------------
        // 4. Enable/hold test
        //
        // When enable = 0 and clear_acc = 0, the
        // accumulator must retain its previous value.
        // --------------------------------------------------

        @(negedge clk);

        activation = 8'sd12;
        weight     = 8'sd3;
        enable     = 1'b0;
        clear_acc  = 1'b0;

        @(posedge clk);

        check_accumulator(
            32'sd16384,
            "Disabled accumulator hold"
        );

        @(negedge clk);

        // --------------------------------------------------
        // 5. Final result
        // --------------------------------------------------

        $display("------------------------------------------");
        $display("PASS: all %0d checks completed", checks);
        $display("------------------------------------------");

        $finish;
    end

    // Prevent the simulation from running indefinitely.
    initial begin
        #2000;
        $fatal(1, "TIMEOUT: testbench did not finish.");
    end

endmodule
