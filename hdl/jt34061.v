/*  This file is part of JTTMS.
    JTTMS program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    JTTMS program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with JTTMS.  If not, see <http://www.gnu.org/licenses/>.

    Author: Jose Tejada Gomez. Twitter: @topapate
    Version: 1.0
    Date: 18-6-2022 */

module jt34061(
    input            rst,
    input            clk,
    input            sys_cen,
    input            pxl_cen,

    // Memory access
    input      [7:0] din,

    input      [7:0] ra,    // row address
    input      [7:0] ca,    // column address
    input            cs,    // ~CS pin
    input      [1:0] ce,    // ~CEH and ~CEL pins
    input      [2:0] fs,
    input            wrn,
    input            ale,   // address latch enable

    // Video signals
    output           hs,
    output           vs,
    output           lhbl,
    output           lvbl,
    output           blank_n,
    output           int_n,

);

parameter [11:0]
    HS_END     = 12'h010,
    HB_END     = 12'h020,
    HB_START   = 12'h1f0,
    H_TOTAL    = 12'h200,
    VS_END     = 12'h004,
    VB_END     = 12'h010,
    VB_START   = 12'h0f0,
    V_TOTAL    = 12'h100,
    DISP_START = 12'h,
    DISP_ADDR  = 12'h,
    V_CNT      = 12'h,
    V_INT      = 12'h000,
    XY_OFFSET  = 12'h010;

reg  [15:0] mmr[0:17];
wire [11:0] hs_end,
            hb_end, hb_start,
            h_total, vb_end,
            vb_start, vs_end, v_total,
            disp_start, disp_addr, v_cnt,
            v_int, xy_offset;

// hidden registers
reg  [11:0] h_cnt=0, v_cnt=0;
reg  [ 9:0] rfsh_addr; // refresh address
reg  [ 2:0] rfsh_cnt;  // refresh burst counter
reg  [ 3:0] scan_cnt;  // scan line counter

// Bus interface
reg  ale_l;

assign hs_end   = mmr[0][11:0];
assign hb_end   = mmr[1][11:0];
assign hb_start = mmr[2][11:0];
assign h_total  = mmr[3][11:0];

assign vs_end   = mmr[4][11:0];
assign vb_end   = mmr[5][11:0];
assign vb_start = mmr[6][11:0];
assign v_total  = mmr[7][11:0];

assign disp_start = mmr[ 9][11:0];
assign v_int      = mmr[10][11:0];
assign xy_offset  = mmr[14][11:0];

assign blank_n    = lhbl & lvbl;

always @(posedge clk) begin
    // HS -active high- & LHBL
    h_cnt <= h_cnt == h_total ? 12'd0 : h_cnt+12'd1;
    if( h_cnt == h_total  ) hs   <= 1;
    if( h_cnt == hs_end   ) hs   <= 0;
    if( h_cnt == hb_end   ) lhbl <= 1;
    if( h_cnt == hb_start ) begin
        lhbl  <= 0;
        // VS
        v_cnt <= v_cnt == v_total ? 12'd0 : v_cnt+12'd1;
        if( v_cnt == v_total  ) vs   <= 1;
        if( v_cnt == vs_end   ) vs   <= 0;
        if( v_cnt == vb_end   ) lvbl <= 1;
        if( v_cnt == vb_start ) lvbl <= 0;
    end
end

always @(posedge clk, posedge rst) begin
    if( rst ) begin
        hs_end     <= HS_END;
        hb_end     <= HB_END;
        hb_start   <= HB_START;
        h_total    <= H_TOTAL;
        vs_end     <= VS_END;
        vb_end     <= VB_END;
        vb_start   <= VB_START;
        v_total    <= V_TOTAL;
        disp_start <= DISP_START;
        disp_addr  <= DISP_ADDR;
        v_cnt      <= V_CNT;
        v_int      <= V_INT;
        xy_offset  <= XY_OFFSET;
        // hidden registers
        rfsh_addr  <= 0;
        rfsh_cnt   <= 0;
        scan_cnt   <= 0;
        ale_l      <= 0;
    end else begin
        ale_l <= ale;
        if( !ale && ale_l ) begin
            case( fs )
                0,2: if ( !wrn ) begin
                    if( ca[1] )
                        mmr[ ca[6:2] ][15:8] <= din;
                    else
                        mmr[ ca[6:2] ][ 7:0] <= din;
                end
            endcase // fs
        end
    end
end

endmodule