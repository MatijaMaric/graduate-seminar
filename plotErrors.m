function fig = plotErrors(areas1, areas2, areasFus)
    mean1 = mean(areas1);
    mean2 = mean(areas2);
    meanFus = mean(areasFus);
    
    std1 = std(areas1);
    std2 = std(areas2);
    stdFus = std(areasFus);
    
    fig = figure();
    subplot(131);
    errorbar(mean1, std1);
    set(gca, 'Xlim', [0, 11])
    set(gca, 'Xtick', 1:10)
    title('T1');
    
    subplot(132);
    errorbar(mean2, std2);
    set(gca, 'Xlim', [0, 11])
    set(gca, 'Xtick', 1:10)
    title('T2');
    
    subplot(133);
    errorbar(meanFus, stdFus);
    set(gca, 'Xlim', [0, 11])
    set(gca, 'Xtick', 1:10)
    title('T1 + T2');
    
end