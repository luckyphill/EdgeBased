classdef SpheroidProfilingAnalysis < Analysis

	properties

		% These cannot be changed, since they relate to a specific
		% set of data. If different values are needed, new data is needed
		% and a new analysis class should be made


		% STATIC: DO NOT CHANGE
		% IF CHANGE IS NEEDED, MAKE A NEW OBJECT

		% No input parameters needed

		t0
		tg
		s
		sreg

		seed

		analysisName = 'SpheroidProfilingAnalysis';

		parameterSet = []

		simulationRuns = 1
		slurmTimeNeeded = 24
		simulationDriverName = 'Spheroid'
		simulationInputCount = 7
		

	end

	methods

		function obj = SpheroidProfilingAnalysis(t0, tg, s, sreg, seed)

			obj.seedIsInParameterSet = false; % The seed not given in MakeParameterSet, it is set in properties
			obj.seedHandledByScript = false; % The seed will be in the parameter file, not the job script

			obj.t0 = t0;
			obj.tg = tg;
			obj.s = s;
			obj.sreg = sreg;   
			obj.seed = seed;
			obj.analysisName = sprintf('%s/t0%gtg%gs%gsreg%gf0.9da-0.1ds0.1dl0.2a20b10t1_seed%g',obj.analysisName, t0, tg, s, sreg, seed);


		end

		function MakeParameterSet(obj)

			obj.parameterSet = [];

		end

	

		function AssembleData(obj)

			% Just need to load the time series as in the visaliser

			% fileName = sprintf('%s/HPC/SpheroidProfiling/result.mat',getenv('EDGEDIR'));
			% load(fileName);

			% run_time = result{1};
			% node_count = result{2};
			% edge_count = result{3};
			% cell_count = result{4};

			% % A bit redundant, but helps keep things standardised
			% % especially for saving and loading
			% obj.result = {run_time, node_count, edge_count, cell_count};


			% Trying out something new - using assemble data to run th simulation
			% maybe there's a better way in general, but this should do the trick

			s = Spheroid(obj.t0, obj.tg, obj.s, obj.sreg, obj.seed);
			s.dt = 0.002;

			% Stop any file output, we don't want to measure that
			remove(s.simData,'spatialState');
			s.dataWriters = AbstractDataWriter.empty();

			t_end = 200;
			run_dt = 1;

			run_time = [];
			node_count = [];
			edge_count = [];
			cell_count = [];

			time_points = run_dt:run_dt:t_end;


			tic;

			for t = time_points
				s.RunToTime(t);
				run_time(end+1) = toc;
				node_count(end+1) = length(s.nodeList);
				edge_count(end+1) = length(s.elementList);
				cell_count(end+1) = length(s.cellList);
			end

			obj.result = {run_time, node_count, edge_count, cell_count, time_points};

		end

		function PlotData(obj)

			run_time = obj.result{1};
			node_count = obj.result{2};
			edge_count = obj.result{3};
			cell_count = obj.result{4};


			t = obj.result{5};
			

			h = figure;

			tFontSize = 40;
			lFontSize = 30;
			aFontSize = 24;

			h = figure;
			plot(t, run_time, 'LineWidth', 4);
			ax = gca;
			ax.FontSize = aFontSize;
			title('Cumulative running time as simulation progresses','Interpreter', 'latex','FontSize', tFontSize);
			xlabel('Simulation Time (hr)','Interpreter', 'latex', 'FontSize', lFontSize);
			ylabel('Running Time (s)','Interpreter', 'latex', 'FontSize', lFontSize);
			SavePlot(obj, h, sprintf('CumTimeVsTime'));


			dt = [run_time(1), run_time(2:end) - run_time(1:end-1)];

			h = figure;
			plot(t,  dt, 'LineWidth', 4);
			ax = gca;
			ax.FontSize = aFontSize;
			title('Running time between time steps','Interpreter', 'latex','FontSize', tFontSize);
			xlabel('Simulation Time (hr)','Interpreter', 'latex', 'FontSize', lFontSize);
			ylabel('Running Time (s)','Interpreter', 'latex', 'FontSize', lFontSize);
			SavePlot(obj, h, sprintf('dtVsTime'));


			% h = figure;

			% data = dt./node_count;
			% plot(data, t, 'LineWidth', 4);
			% ax = gca;
			% ax.FontSize = aFontSize;
			% title('Running time between time steps','Interpreter', 'latex','FontSize', tFontSize);
			% xlabel('Simulation Time (hr)','Interpreter', 'latex', 'FontSize', lFontSize);
			% ylabel('Running Time (s)','Interpreter', 'latex', 'FontSize', lFontSize);
			% SavePlot(obj, h, sprintf('dtVsTime'));



		end

	end

end