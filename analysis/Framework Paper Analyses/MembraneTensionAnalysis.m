classdef MembraneTensionAnalysis < Analysis
	% Checks how varying the internal pressure affects things
	properties

		
		r = 5;
		t0 = 9;
		tg = 9;

		mpe = 20:1:100;

		f = 0.9;

		dF = 0.5; % Log steps from 0.1 to 100

		seed = 1;

		analysisName = 'MembraneTensionAnalysis';

		parameterSet = []

		simulationRuns = 1
		slurmTimeNeeded = 24
		simulationDriverName = 'ManageTumourInMembrane'
		simulationInputCount = 6
		

	end

	methods

		function obj = MembraneTensionAnalysis()

			obj.seedIsInParameterSet = false; % The seed not given in MakeParameterSet, it is set in properties
			obj.seedHandledByScript = false; % The seed will be in the parameter file, not the job script

			obj.usingHPC = true;

		end

		function MakeParameterSet(obj)

			% radius, t0, tg, mpe, f, dF

			params = [];

			for r = obj.r
				for t0 = obj.t0
					for tg = obj.tg
						for mpe = obj.mpe
							for f = obj.f
								for dF = obj.dF

									params(end+1,:) = [r, t0, tg, mpe, f, dF];

								end
							end
						end
					end
				end
			end

			

			obj.parameterSet = params;

		end

		function BuildSimulation(obj)

			obj.MakeParameterSet();
			obj.ProduceSimulationFiles();
			
		end

		function AssembleData(obj)

			% Collect the membrane contained area when proliferetion ceases

			obj.MakeParameterSet();

			for i = 1:length(obj.parameterSet)

				params = obj.parameterSet(i,:);

				r = params(1);
				t0 = params(2);
				tg = params(3);
				mpe = params(4);
				f = params(5);
				dF = params(6);


				a = ManageTumourInMembrane(r, t0, tg, mpe, f, dF, obj.seed);

				a.LoadSimulationData();

				mem = a.data.membraneData;

				y(i) = mem(end,2);

				x(i) = mpe;

			end

			obj.result = {x,y};

			
		end

		function PlotData(obj)

			x = obj.result{1};
			y = obj.result{2};

			tFontSize = 40;
			lFontSize = 30;
			aFontSize = 24;


			h4 = figure;
			plot(x,y, 'LineWidth', 4);
			ax = gca;
			ax.FontSize = aFontSize;
			title(sprintf('Final area vs tension'),'Interpreter', 'latex', 'FontSize', tFontSize);
			xlabel('Tension parameter','Interpreter', 'latex', 'FontSize', lFontSize);
			ylabel('Area (CD$^2$)','Interpreter', 'latex', 'FontSize', lFontSize);

			SavePlot(obj, h4, sprintf('RvsT'));

		end

	end

end