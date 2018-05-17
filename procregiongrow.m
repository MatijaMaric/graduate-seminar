function J = procregiongrow(I)
    threshL = multithresh(I, 8);
    vals = [0 threshL(2:end) 1];
    quantized = imquantize(I, threshL, vals);
    Jbool = regiongrowing(quantized);
    J = zeros(size(I, 1), size(I, 2));
    J(Jbool) = 1;
end