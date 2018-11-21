function eeg_plot(t,d)

  for k=1:size(d,2)
    plot(t,d(:,k)+2*k)
    hold on
  end
  set(gca, 'YTick', [])
  
end