% Compute the common average reference of the data d [ time, electrodes ].

function d_car = common_average_reference(d)

  average = mean(d,2);              % Average over electrodes.
  for i=1:size(d,1)                 % For each time,
      d(i,:) = d(i,:) - average(i); % ... subtract the average reference.
  end
  d_car = d;
end