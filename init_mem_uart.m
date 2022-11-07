clear all; close all; clc;

k = 0;
f = fopen('init_mem_uart.txt', 'wt');
% s = "always_comb begin";
% fwrite(f, s);
for i = 1 : 307200
    ver = rand(1);
    srt = "111";
    if (ver <= 0.55)
        srt = "100";
    end

    if ((ver > 0.55) && (ver <= 0.65))
        srt = "010";
    end

    if ((ver > 0.65) && (ver <= 0.7))
        srt = "110";
    end

    if ((ver > 0.7) && (ver <= 0.76))
        srt = "001";
    end

    if ((ver > 0.76) && (ver <= 0.8))
        srt = "000";
    end

    if ((ver > 0.8) && (ver <= 0.88))
        srt = "101";
    end

    if ((ver > 0.88) && (ver <= 0.95))
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