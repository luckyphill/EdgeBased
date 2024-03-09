classdef ExampleStableUnstable < Analysis

	properties

		% These cannot be changed, since they relate to a specific
		% set of data. If different values are needed, new data is needed
		% and a new analysis class should be made


		% STATIC: DO NOT CHANGE
		% IF CHANGE IS NEEDED, MAKE A NEW OBJECT
		p = [6,11];
		g = [6,11];

		w = 10;

		f = 0;

		b = 10;

		sae = 10;
		spe = 6;

		seed = 123;

		targetTime = 50;

		analysisName = 'ExampleStableUnstable';

		parameterSet = []
		missingParameterSet = []

		simulationRuns = 1
		slurmTimeNeeded = 1
		simulationDriverName = 'ManageDynamicLayer'
		simulationInputCount = 7
		

	end

	methods

		function obj = ExampleStableUnstable()

			obj.seedIsInParameterSet = false; % The seed not given in MakeParameterSet, it is set in properties
			obj.seedHandledByScript = false; % The seed will be in the parameter file, not the job script
			obj.usingHPC = false;

		end

		function MakeParameterSet(obj)


			% params = [w,p,g,b,f,sae,spe];

			obj.parameterSet = [10,7,7,10,0,10,6;
								10,11,11,10,0,10,6;
								10,10,5,5,0,10,15;
								10,10,5,20,0,10,1
								];

		end

		

		function BuildSimulation(obj)

			obj.MakeParameterSet();
			obj.ProduceSimulationFiles();
			
		end

		function AssembleData(obj)

			% Run past the known buckling value to make reasonable plots
			buckleThreshold = 1.2;

			MakeParameterSet(obj);

			buckleOutcome = [];
			buckleTime = [];

			for i = 1:length(obj.parameterSet)
				s = obj.parameterSet(i,:);
				% w, p, g, b, f, sae, spe, seed
				w = s(1);
				p = s(2);
				g = s(3);
				b = s(4);
				f = s(5);
				sae = s(6);
				spe = s(7);

				for j = obj.seed

					a = ManageDynamicLayer(w,p,g,b,f,sae,spe,j);

					% Not giving a data type because this is a bit of a hack
					a.simObj.timeLimit = 200;
					a.simObj.AddSimulationData(SpatialState());
					a.simObj.AddDataWriter(WriteSpatialState(100,a.simObj.pathName));

					a.LoadSimulationData();
					if isnan(a.data.bottomWiggleData)
						a.simObj.RunToBuckle(buckleThreshold);
					end

				end

				obj.result{i} = {a.data.bottomWiggleData,a.data.stromaWiggleData};

			end

		end

		function PlotData(obj)

			buckleOutcome = obj.result{1};
			buckleTime = obj.result{2};

			MakeParameterSet(obj);

			titleFontSize = 40;
			labelFontSize = 40;
			axisFontSize = 30;
			lineThickness = 6;

			for i = 1:length(obj.parameterSet)
				s = obj.parameterSet(i,:);
				bottom = obj.result{i}{1};
				stroma = obj.result{i}{2};
				w = s(1);
				p = s(2);
				g = s(3);
				b = s(4);
				f = s(5);
				sae = s(6);
				spe = s(7);

				a = DynamicLayer(w,p,g,b,f,sae,spe,obj.seed);
				t = 1:length(bottom);
				r = ones(length(bottom),1) * 1.05;
				t = t * 20 * a.dt;
				h = figure;
				hold on
				plot(t, bottom, 'LineWidth', lineThickness);
				plot(t, stroma, 'LineWidth', lineThickness);
				plot(t, r, 'LineWidth', lineThickness, 'LineStyle', '--');
				ax = gca;
				ax.FontSize = axisFontSize;
				ax.TickLabelInterpreter = 'latex';
				ylabel('Buckling ratios','Interpreter', 'latex', 'FontSize', labelFontSize);
				xlabel('time (hr)','Interpreter', 'latex', 'FontSize', labelFontSize);
				title('Buckling ratio over time','Interpreter', 'latex', 'FontSize', titleFontSize);
	            legend('$r_E$','$r_S$','$r_{\textrm{Buckled}}$','Interpreter','latex','Location','northwest');

	            ylim([1, 1.1]);
	            xlim([0, max(t)]);

				SavePlot(obj, h, sprintf('BucklingRatioVSt_p%dg%dspe%d',p, g, spe));

				v = Visualiser(a);
				for j = 10:10:500
					if length(v.timeSteps) > j
						% v.PlotTimeStep(j);
					end
				end

			end

		end

	end

end