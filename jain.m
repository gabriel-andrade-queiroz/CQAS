% Calculate the Jain's index for a given array

function score = jain(x)
score = sum(x)^2/length(x)/sum(x.^2);