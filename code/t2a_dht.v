module t2a_dht(
    input clk_50M,
    input reset,
    inout sensor,
    output reg [7:0] T_integral,
    output reg [7:0] RH_integral,
    output reg [7:0] T_decimal,
    output reg [7:0] RH_decimal,
    output reg [7:0] Checksum,
    output reg data_valid
);

    // initial values
    initial begin
        T_integral = 0;
        RH_integral = 0;
        T_decimal = 0;
        RH_decimal = 0;
        Checksum = 0;
        data_valid = 0;
    end

//////////////////////// DO NOT CHANGE ABOVE THIS LINE //////////////////////

    reg sensor_dir;
    reg sensor_out;
    reg [5:0] bit_counter;      

    assign sensor = (sensor_dir) ? sensor_out : 1'bz;
    wire sensor_in = sensor;   // read data from sensor

    // State definitions 
    localparam S_START_LOW   = 0; 
    localparam S_START_HIGH  = 1; 
    localparam S_RESP_LOW    = 2; 
    localparam S_RESP_HIGH   = 3; 
    localparam S_RX_START    = 4; 
    localparam S_RX_DATA     = 5; 
    localparam S_CHECK       = 6; 
    localparam S_DONE        = 7; 

    // Timings 
    localparam CNT_START_LOW   = 899990; 
    localparam CNT_START_HIGH  = 1990;   
    localparam CNT_RESP_LOW    = 3990;   
    localparam CNT_RESP_HIGH   = 3990;   
    localparam CNT_BIT_START   = 2490;  
    localparam CNT_BIT_ONE     = 2390;   
    localparam CNT_BIT_ZERO    = 1290;   

    reg [3:0] state = 0;          
    reg [39:0] data_reg = 0;       
    reg [31:0] timer_counter = 0;  
    reg data_valid_buf = 0;        

    always @(posedge clk_50M) begin

        // reset condition
        if(!reset) begin
            state <= S_START_LOW;
            sensor_out <= 0;
            T_integral <= 0;
            RH_integral <= 0;
            T_decimal <= 0;
            RH_decimal <= 0;
            Checksum <= 0;
            data_valid_buf <= 0;
            timer_counter <= 0;
            sensor_dir <= 0;
            bit_counter <= 0;
        end

        else begin
            case(state)

            // start signal low (Master drives LOW)
            S_START_LOW: begin
                sensor_dir <= 1;
                sensor_out <= 0;
                timer_counter <= timer_counter + 1;
                data_valid_buf <= 0;

                if(timer_counter >= CNT_START_LOW) begin
                    state <= S_START_HIGH;
                    sensor_out <= 1;
                    timer_counter <= 0;
                    sensor_dir <= 1;
                end
            end

            // start signal high (Master drives HIGH)
            S_START_HIGH: begin
                timer_counter <= timer_counter + 1;
                if(timer_counter >= CNT_START_HIGH) begin
                    state <= S_RESP_LOW;
                    timer_counter <= 0;
                    sensor_dir <= 0;   // release line
                end
            end

            // sensor gives response low
            S_RESP_LOW: begin
                if(sensor_in == 0) begin
                    timer_counter <= timer_counter + 1;
                    if(timer_counter >= CNT_RESP_LOW) begin
                        state <= S_RESP_HIGH;
                        timer_counter <= 0;
                    end
                end
            end

            // sensor gives response high
            S_RESP_HIGH: begin
                if(sensor_in == 1) begin
                    timer_counter <= timer_counter + 1;
                    if(timer_counter >= CNT_RESP_HIGH) begin
                        state <= S_RX_START;
                        timer_counter <= 0;
                        bit_counter <= 0;
                    end
                end
            end

            // read each bit low time (Start of bit)
            S_RX_START: begin
                if(bit_counter >= 40) begin
                    state <= S_CHECK;
                    timer_counter <= 0;
                end
                else if(sensor_in == 0) begin
                    timer_counter <= timer_counter + 1;
                    if(timer_counter >= CNT_BIT_START) begin
                        timer_counter <= 0;
                        state <= S_RX_DATA;
                    end
                end
            end

            // read high part of bit (Data reading)
            S_RX_DATA: begin
                if(sensor_in == 1) begin
                    timer_counter <= timer_counter + 1;
                end
                else begin
                    if(bit_counter <= 40) begin
                        if(timer_counter >= CNT_BIT_ONE) begin
                            data_reg[39 - bit_counter] <= 1;   // logic 1
                            bit_counter <= bit_counter + 1;
                            timer_counter <= 0;
                            state <= S_RX_START;
                        end
                        else if(timer_counter >= CNT_BIT_ZERO && timer_counter <= CNT_BIT_ONE) begin
                            data_reg[39 - bit_counter] <= 0;   // logic 0
                            bit_counter <= bit_counter + 1;
                            timer_counter <= 0;
                            state <= S_RX_START;
                        end
                    end
                end
            end

            // check sum verification
            S_CHECK: begin
                if(data_reg[7:0] == (data_reg[15:8] + data_reg[23:16] + data_reg[31:24] + data_reg[39:32])) begin
                    data_valid_buf <= 1;
                    state <= S_DONE;
                end
                else begin
                    data_valid_buf <= 0;
                    state <= S_DONE;
                end
            end

            // output temperature and humidity
            S_DONE: begin
                T_integral <= data_reg[23:16];
                RH_integral <= data_reg[39:32];
                T_decimal <= data_reg[15:8];
                RH_decimal <= data_reg[31:24];
                Checksum <= data_reg[7:0];
                data_valid_buf <= 0;
                state <= S_START_LOW;
            end

            default: begin
                state <= S_START_LOW;
                T_integral <= 0;
                RH_integral <= 0;
                T_decimal <= 0;
                RH_decimal <= 0;
                Checksum <= 0;
                data_valid_buf <= 0;
            end

            endcase
        end
    end

// latch valid bit
always @(posedge clk_50M) begin
    data_valid <= data_valid_buf;
end

//////////////////// DO NOT CHANGE BELOW THIS LINE ////////////////////

endmodule