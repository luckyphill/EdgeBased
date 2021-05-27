classdef TumourInMembraneAnalysis < Analysis
	% Checks how varying the membrane tension affects things
	properties

		
		r = 5;
		t0 = 9;
		tg = 9;

		mpe = 40:20:100;

		f = 0.9;

		dF = 0.5;

		seed = 1:20;

		analysisName = 'TumourInMembraneAnalysis';

		parameterSet = []

		simulationRuns = 1
		slurmTimeNeeded = 24
		simulationDriverName = 'ManageTumourInMembrane'
		simulationInputCount = 6
		

	end

	methods

		function obj = TumourInMembraneAnalysis()

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


			obj.MakeParameterSet();

			memArea = [];
			intArea = [];
			memAreaVar = [];
			intAreaVar = [];
			
			for i = 1:size(obj.parameterSet,1)

				params = obj.parameterSet(i,:);

				r = params(1);
				t0 = params(2);
				tg = params(3);
				mpe = params(4);
				f = params(5);
				dF = params(6);

				allMem = [];
				allInt = [];

				for j = obj.seed

					a = ManageTumourInMembrane(r, t0, tg, mpe, f, dF, j);

					a.LoadSimulationData();

					mem = a.data.membraneData;

					void = a.data.innerRadiusData;

					% Pad with the last value
					allMem = Concatenate(obj, allMem, mem(:,2)', mem(end,2));

					lumen = void(:,2)';
					lumen(lumen == lumen(end)) = [];

					% Pad with zeros
					allInt = Concatenate(obj, allInt, lumen, 0);

				end

				% Only count time points with more than 10 results
				% nanIdx = sum(sum(~isnan(allInt))>6);
				% (:,1:nanIdx)

				memArea = Concatenate(obj, memArea, mean(allMem),0);
				intArea = Concatenate(obj, intArea, mean(allInt),0);

				memAreaVar = Concatenate(obj, memAreaVar, var(allMem), 0);
				intAreaVar = Concatenate(obj, intAreaVar, var(allInt), 0);

			end

			obj.result = {memArea, intArea, memAreaVar, intAreaVar};

			
		end

		function PlotData(obj)

			memArea = obj.result{1};
			intArea = obj.result{2};
			memAreaVar = obj.result{3};
			intAreaVar = obj.result{4};

			scaleFactor = 0.0001; % 10um^2
			memArea = memArea * scaleFactor;
			intArea = intArea * scaleFactor;
			memAreaVar = memAreaVar * scaleFactor^2;
			intAreaVar = intAreaVar * scaleFactor^2;



			tm = 0.1:0.1:0.1*length(memArea);
			ti = 0.1:0.1:0.1*length(intArea);

			tFontSize = 40;
			lFontSize = 30;
			aFontSize = 24;


			uQ = memArea + sqrt(memAreaVar);
			bQ = memArea - sqrt(memAreaVar);

			h1 = figure;
			plot(tm, memArea, 'LineWidth', 4);
			hold on
			fill([tm,fliplr(tm)], [uQ(1,:),fliplr(bQ(1,:))], [0, .45, 0.74], 'FaceAlpha', 0.25, 'EdgeAlpha',0);
			fill([tm,fliplr(tm)], [uQ(2,:),fliplr(bQ(2,:))], [0.85 0.32 0.01], 'FaceAlpha', 0.25, 'EdgeAlpha',0);
			fill([tm,fliplr(tm)], [uQ(3,:),fliplr(bQ(3,:))], [0.92 0.69 0.12], 'FaceAlpha', 0.25, 'EdgeAlpha',0);
			fill([tm,fliplr(tm)], [uQ(4,:),fliplr(bQ(4,:))], [0.49 0.18 0.55], 'FaceAlpha', 0.25, 'EdgeAlpha',0);		
			
			ax = gca;
			ax.FontSize = aFontSize;
			title(sprintf('Contained area over time'),'Interpreter', 'latex', 'FontSize', tFontSize);
			xlabel('Time (hr)','Interpreter', 'latex', 'FontSize', lFontSize);
			ylabel('Area (mm$^2$)','Interpreter', 'latex', 'FontSize', lFontSize);
			xlim([0,200])
			ylim(scaleFactor*[80, 400])
			
			legend(num2str(obj.mpe'));
			legend('Location','northwest');

			SavePlot(obj, h1, sprintf('Area'));

			uQ = intArea + sqrt(intAreaVar);
			bQ = intArea - sqrt(intAreaVar);

			h4 = figure;
			plot(ti, intArea, 'LineWidth', 4);
			hold on
			fill([ti,fliplr(ti)], [uQ(1,:),fliplr(bQ(1,:))], [0, .45, 0.74], 'FaceAlpha', 0.25, 'EdgeAlpha',0);
			fill([ti,fliplr(ti)], [uQ(2,:),fliplr(bQ(2,:))], [0.85 0.32 0.01], 'FaceAlpha', 0.25, 'EdgeAlpha',0);
			fill([ti,fliplr(ti)], [uQ(3,:),fliplr(bQ(3,:))], [0.92 0.69 0.12], 'FaceAlpha', 0.25, 'EdgeAlpha',0);
			fill([ti,fliplr(ti)], [uQ(4,:),fliplr(bQ(4,:))], [0.49 0.18 0.55], 'FaceAlpha', 0.25, 'EdgeAlpha',0);
			ax = gca;
			ax.FontSize = aFontSize;
			title(sprintf('Lumen area over time'),'Interpreter', 'latex', 'FontSize', tFontSize);
			xlabel('Time (hr)','Interpreter', 'latex', 'FontSize', lFontSize);
			ylabel('Area (mm$^2$)','Interpreter', 'latex', 'FontSize', lFontSize);
			xlim([0,100])
			ylim(scaleFactor*[0, 120])
			legend(num2str(obj.mpe'));
			legend('Location','best');

			SavePlot(obj, h4, sprintf('Void_area'));



		end

	end

end