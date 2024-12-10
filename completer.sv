module apb3_completer #(
    ADDR_WIDTH = 32,
    DATA_WIDTH = 32
) (
    input logic PCLK,
    input logic PRESETn,
    input logic [ADDR_WIDTH-1:0] PADDR,
    input logic PSEL,
    input logic PENABLE,
    input logic PWRITE,
    input logic [DATA_WIDTH-1:0] PWDATA,
    output logic [DATA_WIDTH-1:0] PRDATA,
    output logic PREADY,
    output logic PSLVERR
);

    // parameterised memory
    reg [DATA_WIDTH-1:0] mem[ADDR_WIDTH-1:0];

    // an enum to store current state in the FSM
    typedef enum {
        idle = 0,
        setup = 1,
        access = 2,
        transfer = 3
    } state_t;

    state_t current_state;
    state_t next_state;

    // reset decoder
    always @(posedge PCLK) begin
        if (!PRESETn) begin
            reset_mem();
            current_state <= idle;
        end else current_state <= next_state;
    end

    always_comb begin
        case (current_state)

            // when reset is applied completer goes to this state
            idle: begin
                PRDATA <= 32'hx;
                PREADY <= 1'b0;
                PSLVERR <= 1'b0;
                next_state <= setup;
            end

            // completer stays in this state unless PSEL is asserted
            setup: begin
                if (!PSEL) next_state <= setup;
                else next_state <= access;
            end

            access: begin

                // if PENABLE is not asserted i.e., there is no active transfer; completet goes to setup
                if (!PENABLE) next_state <= setup;
                else begin

                    // no matter the address the next state is always transfer
                    next_state <= transfer;

                    // if PADDR is beyond ADDR_WIDTH-1 completer must assert PSLVERR
                    if (PADDR > 32) begin
                        PREADY  <= 1'b1;
                        PSLVERR <= 1'b1;
                        PRDATA  <= 32'hx;
                    end else begin
                        if (PWRITE) begin
                            mem[PADDR] = PWDATA;
                        end else begin
                            PRDATA <= mem[PADDR];
                        end
                        PREADY  <= 1'b1;
                        PSLVERR <= 1'b0;
                    end
                end
            end

            transfer: begin
                next_state <= setup;
                PREADY <= 1'b0;
                PSLVERR <= 1'b0;
            end

            // adding this to ensure there are no latches
            default: next_state <= idle;

        endcase
    end


    // helper function for abstraction
    function void reset_mem();
        foreach (mem[i]) begin
            mem[i] = 0;
        end
    endfunction

endmodule
