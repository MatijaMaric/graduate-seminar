function [fused] = swt_fusion(img1, img2)
    [A1, H1, V1, D1] = swt2(img1, 1, 'sym2');
    [A2, H2, V2, D2] = swt2(img2, 1, 'sym2');
    
    Af = 0.5 * (A1 + A2);
    D = (abs(H1) - abs(H2)) >= 0;
    Hf = D .* H1 + (~D) .* H2;
    D = (abs(V1) - abs(V2)) >= 0;
    Vf = D .* V1 + (~D) .* V2;
    D = (abs(D1) - abs(D2)) >= 0;
    Df = D .* D1 + (~D) .* D2;
    
    fused = iswt2(Af, Hf, Vf, Df, 'sym2');
end