module mux_tb;
    logic [3:0] a, b, c, d, y;
    logic [3:0] expected [4];
    integer errors;


    logic [1:0]sel;

    mux #(
    .WIDTH (4)
    )u_mux(
    .a(a),
    .b(b),
    .c(c),
    .d(d),
    .sel(sel),
    .y(y));


    initial begin 
        a = 4'd5; b=4'd6; c = 4'd7; d = 4'd8; 
        errors=0;
        expected[0] =a; expected[1] =b; expected[2] = c; expected[3]=d; 
        for (int i = 0; i<4; i++) begin
            sel = i[1:0];
            #1ns;
            if (y!== expected[i])begin
                errors++;
                $error("sel=%0d: got %0h, expected %0h", i, y, expected[i]);
            end
        end
        if (errors == 0) $display("PASS");
        else $display("FAIL: %0d errors", errors);
        $finish;
    end
endmodule
