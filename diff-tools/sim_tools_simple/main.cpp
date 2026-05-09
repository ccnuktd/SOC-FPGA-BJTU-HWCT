/*
 * PA-CHIP Simple Simulator
 * 
 * Enhanced debug tool for CPU simulation
 * Features:
 *   - 's' or Enter: single step one cycle
 *   - 'c': continue/running mode (auto-run until finish or limit)
 *   - 'c <num>': run for specified cycles
 *   - 'w pc==0xaddr': set breakpoint at PC address
 *   - 'info r': display register values
 *   - 'q': quit simulation
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include <verilated.h>
#include <verilated_vcd_c.h>
#include "Vpa_chip_top_sim.h"

Vpa_chip_top_sim* top;
vluint64_t main_time = 0;
VerilatedVcdC* tfp = nullptr;

bool trace_requested = false;
bool trace_active = false;
uint64_t trace_start_cycle = 0;
uint64_t trace_cycle_count = 0;
const char* trace_file = "sim.vcd";

// Breakpoint support
uint32_t breakpoint_pc = 0;
bool breakpoint_set = false;
bool hit_breakpoint = false;

// Print current state
void print_state() {
    printf("[%4lu] PC=0x%08x INST=0x%08x\n", 
           main_time / 2,
           top->current_pc, 
           top->current_instr);
}

// Display all registers
void print_registers() {
    printf("\n=== Register Values ===\n");
    printf("PC  = 0x%08x\n", top->current_pc);
    printf("x0  = 0x%08x  (zero)\n", top->reg_file_0);
    printf("x1  = 0x%08x  (ra)\n", top->reg_file_1);
    printf("x2  = 0x%08x  (sp)\n", top->reg_file_2);
    printf("x3  = 0x%08x  (gp)\n", top->reg_file_3);
    printf("x4  = 0x%08x  (tp)\n", top->reg_file_4);
    printf("x5  = 0x%08x  (t0)\n", top->reg_file_5);
    printf("x6  = 0x%08x  (t1)\n", top->reg_file_6);
    printf("x7  = 0x%08x  (t2)\n", top->reg_file_7);
    printf("x8  = 0x%08x  (s0/fp)\n", top->reg_file_8);
    printf("x9  = 0x%08x  (s1)\n", top->reg_file_9);
    printf("x10 = 0x%08x  (a0)\n", top->reg_file_10);
    printf("x11 = 0x%08x  (a1)\n", top->reg_file_11);
    printf("x12 = 0x%08x  (a2)\n", top->reg_file_12);
    printf("x13 = 0x%08x  (a3)\n", top->reg_file_13);
    printf("x14 = 0x%08x  (a4)\n", top->reg_file_14);
    printf("x15 = 0x%08x  (a5)\n", top->reg_file_15);
    printf("x16 = 0x%08x  (a6)\n", top->reg_file_16);
    printf("x17 = 0x%08x  (a7)\n", top->reg_file_17);
    printf("x18 = 0x%08x  (s2)\n", top->reg_file_18);
    printf("x19 = 0x%08x  (s3)\n", top->reg_file_19);
    printf("x20 = 0x%08x  (s4)\n", top->reg_file_20);
    printf("x21 = 0x%08x  (s5)\n", top->reg_file_21);
    printf("x22 = 0x%08x  (s6)\n", top->reg_file_22);
    printf("x23 = 0x%08x  (s7)\n", top->reg_file_23);
    printf("x24 = 0x%08x  (s8)\n", top->reg_file_24);
    printf("x25 = 0x%08x  (s9)\n", top->reg_file_25);
    printf("x26 = 0x%08x  (s10)\n", top->reg_file_26);
    printf("x27 = 0x%08x  (s11)\n", top->reg_file_27);
    printf("x28 = 0x%08x  (t3)\n", top->reg_file_28);
    printf("x29 = 0x%08x  (t4)\n", top->reg_file_29);
    printf("x30 = 0x%08x  (t5)\n", top->reg_file_30);
    printf("x31 = 0x%08x  (t6)\n", top->reg_file_31);
    printf("========================\n");
}

void print_help() {
    printf("\n=== Commands ===\n");
    printf("  s, or Enter  - Single step one cycle\n");
    printf("  c [num]      - Continue/run (no debug output)\n");
    printf("  w pc==0xaddr - Set breakpoint at PC address\n");
    printf("  trace on     - Start waveform recording now\n");
    printf("  trace off    - Stop waveform recording\n");
    printf("  info r       - Display register values\n");
    printf("  q            - Quit simulation\n");
    printf("  h            - Show this help\n");
    printf("\n=== Current Cycle: %lu ===\n", main_time / 2);
    if (breakpoint_set) {
        printf("=== Breakpoint: PC==0x%08x ===\n", breakpoint_pc);
    }
    if (hit_breakpoint) {
        printf("=== Breakpoint hit! ===\n");
    }
}

void start_trace() {
    if (trace_active) return;

    if (!tfp) {
        Verilated::traceEverOn(true);
        tfp = new VerilatedVcdC;
        top->trace(tfp, 99);
        tfp->open(trace_file);
    }

    trace_active = true;
    printf("[INFO] Waveform recording started at cycle %lu: %s\n", main_time / 2, trace_file);
}

void stop_trace() {
    if (!trace_active) return;

    trace_active = false;
    if (tfp) {
        tfp->flush();
    }
    printf("[INFO] Waveform recording paused at cycle %lu\n", main_time / 2);
}

void update_trace_window() {
    if (!trace_requested || trace_active) return;

    uint64_t cycle = main_time / 2;
    bool before_stop = (trace_cycle_count == 0) ||
                       (cycle < trace_start_cycle + trace_cycle_count);

    if (cycle >= trace_start_cycle && before_stop) {
        start_trace();
    }
}

void close_trace() {
    if (!tfp) return;

    if (trace_active) {
        trace_active = false;
    }
    tfp->flush();
    tfp->close();
    delete tfp;
    tfp = nullptr;
    printf("[INFO] Waveform saved: %s\n", trace_file);
}

void clock_cycle(bool verbose) {
    update_trace_window();

    top->clk_i = 0;
    top->eval();
    main_time++;
    
    if (verbose) {
        print_state();
    }
    
    if (trace_active) tfp->dump(main_time);
    
    top->clk_i = 1;
    top->eval();
    main_time++;
    
    if (trace_active) tfp->dump(main_time);

    if (trace_active && trace_cycle_count > 0 &&
        (main_time / 2) >= trace_start_cycle + trace_cycle_count) {
        stop_trace();
    }
    
    // Check breakpoint after clock rising edge
    if (breakpoint_set && !hit_breakpoint) {
        uint32_t pc = top->current_pc;
        if (pc == breakpoint_pc) {
            hit_breakpoint = true;
            printf("\n*** Breakpoint hit at PC=0x%08x ***\n\n", pc);
        }
    }
}

// Run simulation for specified cycles (0 = unlimited, verbose = false)
void run_cycles(uint64_t max_cycles, bool verbose) {
    uint64_t start_cycles = main_time / 2;
    
    while (true) {
        if (Verilated::gotFinish()) {
            if (verbose) printf("\n[HALT] Simulation finished\n");
            break;
        }
        
        if (max_cycles > 0 && (main_time / 2 - start_cycles) >= max_cycles) {
            break;
        }
        
        clock_cycle(verbose);

        if (hit_breakpoint) {
            hit_breakpoint = false;  // Clear for next run
            break;
        }
        
        if (Verilated::gotFinish()) {
            if (verbose) printf("\n[HALT] Simulation finished\n");
            break;
        }
        
        if (verbose && (main_time / 2) % 100000 == 0 && main_time > 0) {
            printf("\n--- Running: %lu cycles ---\n", main_time / 2);
            fflush(stdout);
        }
    }
}

// Parse breakpoint command: "w pc==0xaddr"
void parse_watchpoint(char* cmd) {
    uint32_t addr;
    if (sscanf(cmd, "w pc==0x%x", &addr) == 1) {
        breakpoint_pc = addr;
        breakpoint_set = true;
        printf("[INFO] Breakpoint set at PC=0x%08x\n", addr);
    } else {
        printf("[ERROR] Invalid watchpoint format. Use: w pc==0xaddr\n");
    }
}

int main(int argc, char** argv) {
    Verilated::commandArgs(argc, argv);
    
    bool enable_trace = false;
    uint64_t auto_run_cycles = 0;
    
    for (int i = 1; i < argc; i++) {
        if (strcmp(argv[i], "--trace") == 0) {
            enable_trace = true;
            trace_requested = true;
        } else if (strcmp(argv[i], "--run") == 0 && i + 1 < argc) {
            auto_run_cycles = atoll(argv[++i]);
        } else if (strcmp(argv[i], "--trace-start") == 0 && i + 1 < argc) {
            trace_start_cycle = strtoull(argv[++i], nullptr, 0);
        } else if (strcmp(argv[i], "--trace-cycles") == 0 && i + 1 < argc) {
            trace_cycle_count = strtoull(argv[++i], nullptr, 0);
        } else if (strcmp(argv[i], "--trace-file") == 0 && i + 1 < argc) {
            trace_file = argv[++i];
        }
    }
    
    printf("\n=== PA-CHIP Simulator ===\n");
    printf("Type 'h' for help\n");
    if (enable_trace) {
        if (trace_start_cycle > 0 || trace_cycle_count > 0) {
            printf("Waveform recording armed: start=%lu cycles=%lu file=%s\n",
                   trace_start_cycle, trace_cycle_count, trace_file);
        } else {
            printf("Waveform recording enabled: %s\n", trace_file);
        }
    }
    printf("\n");
    
    if (trace_requested) {
        Verilated::traceEverOn(true);
    }

    top = new Vpa_chip_top_sim();
    
    printf("[RESET]\n");
    top->rst_n_i = 0;
    top->clk_i = 0;
    for (int i = 0; i < 10; i++) clock_cycle(true);
    top->rst_n_i = 1;
    clock_cycle(true);
    
    printf("\n--- Start Simulation ---\n");
    
    if (auto_run_cycles > 0) {
        printf("[MODE] Auto-running for %lu cycles...\n", auto_run_cycles);
        run_cycles(auto_run_cycles, false);
        printf("\n[INFO] Auto-run complete. Total cycles: %lu\n", main_time / 2);
    } else {
        char line[64];
        
        while (true) {
            printf("> ");
            fflush(stdout);
            
            if (!fgets(line, sizeof(line), stdin)) {
                break;
            }
            
            // Trim newline
            line[strcspn(line, "\n")] = 0;
            
            if (line[0] == 'q' || line[0] == 'Q') {
                break;
            } else if (line[0] == 'h' || line[0] == 'H' || line[0] == '?') {
                print_help();
            } else if (strncmp(line, "info r", 6) == 0 || strncmp(line, "info", 4) == 0) {
                print_registers();
            } else if (strcmp(line, "trace on") == 0) {
                trace_requested = true;
                trace_start_cycle = main_time / 2;
                trace_cycle_count = 0;
                start_trace();
            } else if (strcmp(line, "trace off") == 0) {
                stop_trace();
            } else if (line[0] == 'w' || line[0] == 'W') {
                parse_watchpoint(line);
            } else if (line[0] == 'c' || line[0] == 'C') {
                uint64_t run_cycles_count = 0;
                if (sscanf(line + 1, "%lu", &run_cycles_count) == 1 && run_cycles_count > 0) {
                    printf("[MODE] Running for %lu cycles...\n", run_cycles_count);
                    run_cycles(run_cycles_count, false);
                    printf("\n[INFO] Reached cycle limit: %lu cycles\n", main_time / 2);
                } else {
                    printf("[MODE] Running (non-verbose)...\n");
                    run_cycles(0, false);
                    printf("\n[INFO] Simulation finished: %lu cycles\n", main_time / 2);
                }
            } else {
                // Single step
                clock_cycle(true);
                
                if (Verilated::gotFinish()) {
                    printf("\n[HALT] Simulation finished\n");
                    break;
                }
            }
        }
    }
    
    close_trace();
    
    delete top;
    printf("\nTotal cycles: %lu\n", main_time / 2);
    return 0;
}
