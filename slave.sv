module apb_slave #(
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

    reg [31:0] mem[32];

    typedef enum {
        idle = 0,
        setup = 1,
        access = 2,
        transfer = 3
    } state_t;

    state_t current_state;
    state_t next_state;

    always @(posedge PCLK) begin
        if (!PRESETn) begin
            reset_mem();
            current_state <= idle;
        end else current_state <= next_state;
    end

    always_comb begin
        case (current_state)

            idle: begin
                PRDATA <= 0;
                PREADY <= 0;
                PSLVERR <= 0;
                next_state <= setup;
            end

            setup: begin
                if (!PSEL) next_state <= setup;
                else next_state <= access;
            end

            access: begin
                if (!PENABLE) next_state <= setup;
                else begin
                    next_state <= transfer;
                    if (PADDR > 32) begin
                        PREADY  <= 1;
                        PSLVERR <= 1;
                        PRDATA  <= 32'hxxxxxxxx;
                    end else begin
                        if (PWRITE) begin
                            mem[PADDR] = PWDATA;
                        end else begin
                            PRDATA <= mem[PADDR];
                        end
                        PREADY  <= 1;
                        PSLVERR <= 0;
                    end
                end
            end

            transfer: begin
                next_state <= setup;
                PREADY <= 0;
                PSLVERR <= 0;
            end

            default: next_state <= idle;

        endcase
    end

    function void reset_mem();
        foreach (mem[i]) begin
            mem[i] = 0;
        end
    endfunction

endmodule
