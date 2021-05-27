classdef MembranePressureAnalysis < Analysis
	% Checks how varying the internal pressure affects things
	properties

		
		r = 5;
		t0 = 9;
		tg = 9;

		mpe = 20:20:100;

		f = 0.9;

		dF = 0.5; % Log steps from 0.1 to 100

		seed = 1;

		analysisName = 'MembranePressureAnalysis';

		parameterSet = []

		simulationRuns = 1
		slurmTimeNeeded = 24
		simulationDriverName = 'ManageTumourInMembrane'
		simulationInputCount = 6
		

	end

	methods

		function obj = MembranePressureAnalysis()

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


			% No special assembly required

			
		end

		function PlotData(obj)

			obj.MakeParameterSet();

			h1 = figure;

			h2 = figure;

			h3 = figure;

			h4 = figure;

			h5 = figure;

			tFontSize = 40;
			lFontSize = 30;
			aFontSize = 24;

			for i = 1:size(obj.parameterSet,1)

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

				count = a.data.cellCountData;

				void = a.data.innerRadiusData;

				tm = mem(:,1);

				memintArea = mem(:,2);
				memperimeter = mem(:,3);
				memavgRadius = mem(:,4);


				tc = count(:,1);
				count = count(:,2);

				tv = void(:,1);
				intArea = void(:,2);
				perimeter = void(:,3);
				avgRadius = void(:,4);
				centre = void(:,5:6);


				intArea(intArea == intArea(end)) = nan;
				
				figure(h1);
				plot(tm, memintArea, 'LineWidth', 4);
				hold on

				
				figure(h2);
				plot(tc, count, 'LineWidth', 4);
				hold on


				figure(h3);
				plot(tc, count./memintArea, 'LineWidth', 4);
				hold on
				legend(sprintf('%g',mpe));


				figure(h4);
				plot(tc, intArea, 'LineWidth', 4);
				hold on


				figure(h5);
				plot(tm, memavgRadius, 'LineWidth', 4);
				hold on


			end

			figure(h1);
			title(sprintf('Area over time'),'Interpreter', 'latex', 'FontSize', tFontSize);
			xlabel('Time (hr)','Interpreter', 'latex', 'FontSize', lFontSize);
			ylabel('Area (CD$^2$)','Interpreter', 'latex', 'FontSize', lFontSize);
			xlim([0,150])
			ylim([80, 450])
			ax = gca;
			ax.FontSize = aFontSize;
			legend(num2str(obj.mpe'));
			legend('Location','best');

			SavePlot(obj, h1, sprintf('Area'));


			figure(h2);
			title(sprintf('Cell count over time'),'Interpreter', 'latex', 'FontSize', tFontSize);
			xlabel('Time (hr)','Interpreter', 'latex', 'FontSize', lFontSize);
			ylabel('Cell count','Interpreter', 'latex', 'FontSize', lFontSize);
			ax = gca;
			ax.FontSize = aFontSize;
			legend(num2str(obj.mpe'));
			legend('Location','best');

			SavePlot(obj, h2, sprintf('Cell_count'));


			figure(h3);
			title(sprintf('Cell density over time'),'Interpreter', 'latex', 'FontSize', tFontSize);
			xlabel('Time (hr)','Interpreter', 'latex', 'FontSize', lFontSize);
			ylabel('Density (cells/CD$^2$)','Interpreter', 'latex', 'FontSize', lFontSize);
			legend(num2str(obj.mpe'));
			legend('Location','best');

			SavePlot(obj, h3, sprintf('Cell_density'));


			figure(h4);
			title(sprintf('Lumen area over time'),'Interpreter', 'latex', 'FontSize', tFontSize);
			xlabel('Time (hr)','Interpreter', 'latex', 'FontSize', lFontSize);
			ylabel('Area (CD$^2$)','Interpreter', 'latex', 'FontSize', lFontSize);
			ax = gca;
			ax.FontSize = aFontSize;
			legend(num2str(obj.mpe'));
			legend('Location','best');

			SavePlot(obj, h4, sprintf('Void_area'));


			figure(h5);
			title(sprintf('Membrane radius over time'),'Interpreter', 'latex', 'FontSize', tFontSize);
			xlabel('Time (hr)','Interpreter', 'latex', 'FontSize', lFontSize);
			ylabel('Radius (CD)','Interpreter', 'latex', 'FontSize', lFontSize);
			ylim([5, 12])
			ax = gca;
			ax.FontSize = aFontSize;
			legend(num2str(obj.mpe'));
			legend('Location','best');

			SavePlot(obj, h5, sprintf('Membrane_radius'));


		end

	end

end