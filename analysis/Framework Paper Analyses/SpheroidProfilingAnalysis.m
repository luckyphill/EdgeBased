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

			fileName = sprintf('%s/HPC/SpheroidProfiling/result.mat',getenv('EDGEDIR'));
			load(fileName);

			run_time = result{1};
			node_count = result{2};
			edge_count = result{3};
			cell_count = result{4};

			% A bit redundant, but helps keep things standardised
			% especially for saving and loading
			obj.result = {run_time, node_count, edge_count, cell_count};

		end

		function PlotData(obj)

			run_time = obj.result{1};
			node_count = obj.result{2};
			edge_count = obj.result{3};
			cell_count = obj.result{4};


			dt = run_time(2:end) - run_time(1:end-1):
			


		end

	end

end