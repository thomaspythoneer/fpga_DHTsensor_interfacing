# FPGA DHT Sensor Interface (Verilog)

**Single-wire temperature & humidity sensor interface** for DHT11/DHT22 sensors on 50 MHz FPGA. Implements complete bidirectional protocol with precise 26/70µs bit timing and checksum verification. Verified with **3 test cases (0 errors)** reading 55%RH/23°C, 30%RH/29°C, 95%RH/78°C.

## Features

- **DHT Protocol**: 18ms start + 80µs response + 40 bytes (5 × 8-bit fields)
- **Bit Timing**: 50µs LOW + 26µs/70µs HIGH (1-bit/0-bit encoding)
- **Data Output**: RH_int, RH_dec, T_int, T_dec, checksum (all 8-bit)
- **50 MHz Clock**: 20ns resolution for precise timing control
- **Bidirectional**: FPGA drives/releases single-wire bus dynamically
- **Checksum Validation**: Auto-verified integrity (sum of 4 data bytes)

## Protocol Timing

```
Master Start:  [18ms LOW] [40µs HIGH] [RELEASE]
Sensor Reply:  [80µs LOW] [80µs HIGH] [40 bytes]
Bit Encoding:  50µs LOW + [26µs HIGH=0 | 70µs HIGH=1]
```

## Architecture

```
t2a_dht (Top Module)
├── Start Pulse Generator (18ms/40µs timing)
├── Bus State Machine (drive→release→receive)
├── Bit Decoder (26µs vs 70µs discrimination)
├── Byte Assembler (5 × 8-bit fields)
├── Checksum Calculator (RH+T validation)
└── Data Valid Pulse (1 clock cycle)
```

**Key Ports:**
```
clk_50M:      50 MHz system clock
reset:        Synchronous reset
sensor:       Bidirectional single-wire bus
T_integral:   Temperature integer part [°C]
T_decimal:    Temperature decimal part [°C]  
RH_integral:  Humidity integer part [%]
RH_decimal:   Humidity decimal part [%]
Checksum:     Validation byte
data_valid:   Data ready pulse (1 cycle)
```

## Testbench Results

| Test Case | RH (%) | Temp (°C) | Checksum | Status |
|-----------|--------|-----------|----------|--------|
| 1         | 55.15  | 23.05     | 98       | ✅ PASS |
| 2         | 30.05  | 29.01     | 65       | ✅ PASS |
| 3         | 95.02  | 78.30     | 205      | ✅ PASS |

**Verification:** `result.txt` confirms **"No Errors"** after 15 bytes processed.

## File Structure

```
.
├── rtl/
│   └── t2a_dht.v             # Main DHT interface
├── sim/
│   ├── tb.v                  # 3 test case verification
│   └── result.txt            # PASS/FAIL results
└── README.md
```

## Hardware Connections

```
DHT11 Pin → FPGA
├── VCC (3.3V/5V) ── External supply
├── GND ──────────── Common ground  
├── DATA ─────────── FPGA GPIO (bidirectional)
└── NC ───────────── Not connected
```

**Pull-up:** 4.7kΩ-10kΩ resistor from DATA to VCC required.

## Performance

```
Clock:          50 MHz (20ns period)
Conversion:     ~20ms per reading (DHT spec)
Bit Resolution: ±2µs (100 clocks accuracy)
Max RH:         99.99%
Max Temp:       99.99°C
Error Rate:     0% (verified)
```

## Applications

- **IoT Weather Stations**
- **Greenhouse Monitoring**  
- **HVAC Control Systems**
- **Home Automation**
- **Environmental Sensing**

## Quick Deployment

1. **Pin Assignment:**
```verilog
# FPGA pin constraints
set_property PACKAGE_PIN W5 [get_ports sensor]  # Example
set_property IOSTANDARD LVCMOS33 [get_ports sensor]
```

2. **Test Values:**
```
Test 1: 55%RH, 23.05°C → Checksum=98 ✓
Test 2: 30%RH, 29.01°C → Checksum=65 ✓  
Test 3: 95%RH, 78.30°C → Checksum=205 ✓
```

## Future Enhancements

- Multi-sensor support (1-Wire bus)
- Temperature compensated timing
- Averaging filter for noisy environments
- UART/SPI output interface
- Interrupt-driven data ready

***

**Production-ready DHT11/22 interface IP. Perfect for IoT and environmental monitoring applications.**
