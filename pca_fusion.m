function [fused] = pca_fusion(img1, img2)
    C = cov([img1(:) img2(:)]);
    [V, D] = eig(C);
    if D(1,1) >= D(2,2)
      pca = V(:,1)./sum(V(:,1));
    else  
      pca = V(:,2)./sum(V(:,2));
    end
    fused = pca(1)*img1 + pca(2)*img2;
end