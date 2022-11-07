clear all; close all; clc;

k = 0;
f = fopen('init_mem_uart.txt', 'wt');
% s = "always_comb begin";
% fwrite(f, s);
for i = 1 : 307200
    ver = rand(1);
    srt = "111";
    if (ver <= 0.5)
        srt = "100";
    end

    if ((ver > 0.5) && (ver <= 0.7))
        srt = "010";
    end

    if ((ver > 0.7) && (ver <= 0.8))
        srt = "110";
    end

    if ((ver > 0.8) && (ver <= 0.85))
        srt = "001";
    end

    if ((ver > 0.85) && (ver <= 0.9))
        srt = "000";
    end

    if ((ver > 0.9) && (ver <= 0.94))
        srt = "101";
    end

    if ((ver > 0.94) && (ver <= 0.97))
        srt = "011";
    end

%     disp("mem["+num2str(i)+"]=3'b" + srt + ";");
    s = srt + newline;
    fwrite(f, s);
    k = k + 1;
end
% 
% s = newline + "end";
% fwrite(f, s);
fclose(f);