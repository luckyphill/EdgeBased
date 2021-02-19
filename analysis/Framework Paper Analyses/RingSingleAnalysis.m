classdef RingSingleAnalysis < Analysis

	properties

		n
		t0
		tg

		seed

		analysisName = 'RingSingleAnalysis';

		parameterSet = []

		simulationRuns = 1
		slurmTimeNeeded = 24
		simulationDriverName = 'RingBuckling'
		simulationInputCount = 7
		

	end

	methods

		function obj = RingSingleAnalysis(n, t0, tg, seed)

			% Each seed runs in a separate job
			obj.specifySeedDirectly = true;

			obj.n = n;
			obj.t0 = t0;
			obj.tg = tg;     
			obj.seed = seed;
			obj.analysisName = sprintf('%s/n%gt0%gtg%gs10a0f0.9da0ds0.1dl0.2alpha20beta10t%1_seed%g/',obj.analysisName,obj.n,obj.t0,obj.tg,obj.seed);


		end

		function MakeParameterSet(obj)

			obj.parameterSet = [];

		end

	

		function AssembleData(obj)

			circFile = sprintf('%s/SimulationOutput/%s/n%gt0%gtg%gs10a0f0.9da0ds0.1dl0.2alpha20beta10t1_seed%g/Circularity.csv',getenv('EDGEDIR'),obj.simulationDriverName,obj.n,obj.t0,obj.tg,obj.seed);
			C = dlmread(circFile);

			obj.result = {C(:,2),C(:,1)};

		end

		function PlotData(obj)

			C = obj.result{1};
			t = obj.result{2};
				
			h = figure;
			plot(t,C, 'LineWidth', 4);
			ax = gca;
			ax.FontSize = 16;
			tFontSize = 40;
			title('Ring shape over time','Interpreter', 'latex','FontSize', tFontSize);
			ylabel('Circularity','Interpreter', 'latex', 'FontSize', 40);xlabel('Time (hr)','Interpreter', 'latex', 'FontSize', 40);
			ylim([0 max(C)]);; xlim([0 max(t)]);
			SavePlot(obj, h, sprintf('Circularity'));

			v = Visualiser(sprintf('%s/n%gt0%gtg%gs10a0f0.9da0ds0.1dl0.2alpha20beta10t1_seed%g/',obj.simulationDriverName,obj.n,obj.t0,obj.tg,obj.seed));

			v.PlotTimeStep(750);
			a = gca;
			xyrange = [a.XLim, a.YLim];

			SavePlot(obj, gcf, sprintf('T75'));

			v.PlotTimeStep(600, xyrange);SavePlot(obj, gcf, sprintf('T60'));
			v.PlotTimeStep(400, xyrange);SavePlot(obj, gcf, sprintf('T40'));
			v.PlotTimeStep(1, xyrange,'t = 0 hrs');SavePlot(obj, gcf, sprintf('T0'));
		end

	end

end