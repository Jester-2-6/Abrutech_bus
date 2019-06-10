module(
    clk,
    rstn,
    hex0,
    hex1,
    hex2,
    hex3,
    hex4,
    hex5,
    hex6,
    hex7,
    requests,
    utilization,
    slave_busy,
    current_m_bsy,
    mux_switch,
    clk_mux,
    BUS,
    execute_procedure,
    procedure
);

// Instantiate top module

always@(posedge clk,negedge rstn)
begin
    if(~rstn)
    begin

    end else begin
        case(PROCEDURE)
        IDLE:
        begin
            
        end
        SAME_PRIORITY:
        begin
            case(MINI_PROCEDURE)
            _1_RESET:
            _1_M1:
            _1_:
            _1_:
            _1_:
            _1_:
            _1_:
            _1_:
            _1_:
            default: PROCEDURE <= IDLE;
            endcase
        end
        DIFFERENT_PRIORITY:
        begin
            case(MINI_PROCEDURE)
            default: PROCEDURE <= IDLE;
            endcase
            
        end
        MULTIPRIORITY:
        begin
            case(MINI_PROCEDURE)
            default: PROCEDURE <= IDLE;
            endcase
            
        end
        SPLIITER_EQUAL_PRIORITY:
        begin
            case(MINI_PROCEDURE)
            default: PROCEDURE <= IDLE;
            endcase
            
        end
        SPLITTER_DIFFERENT_PRIORITY:
        begin
            case(MINI_PROCEDURE)
            default: PROCEDURE <= IDLE;
            endcase
            
        end
        default:IDLE;
        endcase
    end
end 

endmodule