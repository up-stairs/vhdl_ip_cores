clear;
clc;
close all;

code_range = 1:21;
P = 180;
fid = fopen('EdgeMap.vhd','wt');
%%
file{1} = '----------------------------------------------------------------------------------\n';
file{2} = '-- Company: \n';
file{3} = '-- Engineer: \n';
file{4} = '-- \n';
file{5} = '-- Create Date:    15:58:54 09/16/2011 \n';
file{6} = '-- Design Name: \n';
file{7} = '-- Module Name:    EdgeMap - Behavioral \n';
file{8} = '-- Project Name: \n';
file{9} = '-- Target Devices: \n';
file{10} = '-- Tool versions: \n';
file{11} = '-- Description: \n';
file{12} = '--\n';
file{13} = '-- Dependencies: \n';
file{14} = '--\n';
file{15} = '-- Revision: \n';
file{16} = '-- Revision 0.01 - File Created\n';
file{17} = '-- Additional Comments: \n';
file{18} = '--\n';
file{19} = '----------------------------------------------------------------------------------\n';
file{20} = 'LIBRARY IEEE;\n';
file{21} = 'USE IEEE.STD_LOGIC_1164.ALL;\n';
file{22} = 'USE IEEE.STD_LOGIC_ARITH.ALL;\n';
file{23} = 'USE IEEE.STD_LOGIC_UNSIGNED.ALL;\n';
file{24} = 'USE STD.TEXTIO.ALL;\n';
file{25} = '\n';
file{26} = '-- Uncomment the following library declaration if using\n';
file{27} = '-- arithmetic functions with Signed or Unsigned values\n';
file{28} = '--use IEEE.NUMERIC_STD.ALL;\n';
file{29} = '\n';
file{30} = '-- Uncomment the following library declaration if instantiating\n';
file{31} = '-- any Xilinx primitives in this code.\n';
file{32} = '--library UNISIM;\n';
file{33} = '--use UNISIM.VComponents.all;\n';
file{34} = '\n';
file{35} = 'entity EdgeMap is\n';
file{36} = '	port(\n';
file{37} = '		clk						: in  std_logic;\n';
file{38} = '		\n';
file{39} = '		Addr					: in  std_logic_vector( downto 0);\n'; % 34
file{40} = '		Do						: out std_logic_vector(17 downto 0)\n';
file{41} = '	);\n';
file{42} = 'end EdgeMap;\n';
file{43} = '\n';
file{44} = 'architecture Behavioral of EdgeMap is\n';
file{45} = '	type INT_TYPE is array (0 to ) of integer;\n'; %30
file{46} = '	constant EdgeMapMemory : INT_TYPE := (\n';

file{47} = 'begin\n';
file{48} = '	process(clk)\n';
file{49} = '	begin\n';
file{50} = '		if rising_edge(clk) then\n';
file{51} = '			Do <= conv_std_logic_vector(EdgeMapMemory(conv_integer(Addr)),18);\n';
file{52} = '		end if;\n';
file{53} = '	end process;\n';
file{54} = 'end Behavioral;\n';

%% print Hbm1 for all rates
for k = 1:38
    fprintf(fid,file{k});
end

TotEdge = 0;
for code = code_range
    [Hb EdgeCnt] = Convert2Hb(code,P);
    TotEdge = TotEdge + EdgeCnt;
end

file{39} = [file{39}(1:34), num2str(ceil(log2(TotEdge))-1), file{39}(35:end)];

for k = 39:44
    fprintf(fid,file{k});
end

file{45} = [file{45}(1:30), num2str(TotEdge-1), file{45}(31:end)];

for k = 45:46
    fprintf(fid,file{k});
end

EdgeCnt = 0;
for code = code_range
    [Hb EdgeCnt] = Convert2Hb(code,P);
    Start(code) = EdgeCnt;

    [mb nb] = size(Hb(:,:,1));
    kb = nb - mb;

    TotEdgeCnt = 0;
    for i = 1:mb
        EdgeCnt = 0;
        for j = 1:kb
            EdgeCnt = EdgeCnt + (Hb(i,j,1) ~= -1) + (Hb(i,j,2) ~= -1)  + (Hb(i,j,3) ~= -1);
        end
        
        file_row = '';
        for j = 1:kb
            if Hb(i,j,1) ~= -1
                EdgeCnt = EdgeCnt - 1;
                if EdgeCnt == 0
                    RowEnd = 1;
                else
                    RowEnd = 0;
                end
                file_row = [file_row sprintf('(2**17)*%d+(2**%d)*%3d+%3d, ',RowEnd,ceil(log2(P)),j-1,Hb(i,j,1))];
            end
            if Hb(i,j,2) ~= -1
                EdgeCnt = EdgeCnt - 1;
                if EdgeCnt == 0
                    RowEnd = 1;
                else
                    RowEnd = 0;
                end
                file_row = [file_row sprintf('(2**17)*%d+(2**%d)*%3d+%3d, ',RowEnd,ceil(log2(P)),j-1,Hb(i,j,2))];
            end
            if Hb(i,j,3) ~= -1
                EdgeCnt = EdgeCnt - 1;
                if EdgeCnt == 0
                    RowEnd = 1;
                else
                    RowEnd = 0;
                end
                file_row = [file_row sprintf('(2**17)*%d+(2**%d)*%3d+%3d, ',RowEnd,ceil(log2(P)),j-1,Hb(i,j,3))];
            end
        end
        
        
        if code == code_range(end) && i == mb
            file_row(end-1:end) = '';
            fprintf(fid,file_row);
            fprintf(fid,');\n');
        else
            fprintf(fid,file_row);
            fprintf(fid,'\n');
        end
    end
    fprintf(fid,'\n');
    fprintf(fid,'\n');
end


for k = 47:54
    fprintf(fid,file{k});
end

fclose('all');