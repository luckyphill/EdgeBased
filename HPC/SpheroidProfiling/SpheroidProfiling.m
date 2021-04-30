
s = Spheroid(10, 10, 10, 5, 111);
s.dt = 0.002;

t_end = 200;
dt = 1;

run_time = [];
node_count = [];
edge_count = [];
cell_count = [];

tic;
for t = dt:dt:t_end
	s.RunToTime(t);
	run_time(end+1) = toc;
	node_count(end+1) = length(s.nodeList);
	edge_count(end+1) = length(s.elementList);
	cell_count(end+1) = length(s.cellList);
end

result = {run_time, node_count, edge_count, cell_count};

save('result','result');
