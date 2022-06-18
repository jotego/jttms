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

module jt34070(
    input            rst,
    input            clk,
    input            cen,
    output reg       cen2d,     // clock enable at half the rate of cen

    input            mode,
    input            dataen,
    input            dump,      // not supported
    output reg       xat,

    input      [3:0] din_a,     // phase A
    input      [3:0] din_b,     // phase B

    output reg [3:0] red,
    output reg [3:0] green,
    output reg [3:0] blue
);

reg  [13:0] pal[0:15];
reg  [ 4:0] rdcnt;
reg  [ 7:0] dlatch;
wire [ 3:0] amux;
wire [13:0] pxl_mux;
reg         rdokl, phase;
wire        rdok;
integer     aux;

assign rdok    = !mode && !dataen;
assign amux    = phase ? dlatch[7:4] : dlatch[3:0];
assign pxl_mux = pal[ amux ];

always @(posedge clk) begin
    cen2d <= ~phase & cen;
end

always @(posedge clk) begin
    if( rst ) begin
        for( aux=0; aux<16; aux=aux+1 ) pal[aux] <= 0;
        rdcnt <= 0;
        rdokl <= 0;
        phase <= 0;
        red   <= 0;
        green <= 0;
        blue  <= 0;
        xat   <= 0;
    end else if(cen) begin
        rdokl <= rdok;
        phase <= ~phase;
        if( rdok ) begin
            rdcnt <= !rdokl ? 1 : rdcnt+5'd1;
        end
        if( rdok ) begin // loads the LUT values
            if( !rdcnt[0] )
                pal[ rdcnt[4:1] ][13:8] <= { din_a[2:1], din_b };
            else
                pal[ rdcnt[4:1] ][ 7:0] <= { din_a, din_b };
        end
        if( phase ) dlatch <= { din_a, din_b };
        if( dataen ) begin
            xat <= pxl_mux[13];
            if( !pxl_mux[12] ) begin // not a repeated pixel
                { red, green, blue } <= pxl_mux[11:0];
            end
        end else begin
            { red, green, blue } <= 0;
        end
    end
end

endmodule