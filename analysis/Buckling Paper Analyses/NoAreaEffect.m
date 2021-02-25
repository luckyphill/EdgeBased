classdef NoAreaEffect < Analysis

	% This analysis demonstrates that buckling likelihood is not impacted by
	% the area properties of the stroma and only impacted by the boundary tension
	% properties (which is represented by an energy due to difference from intended
	% length). This an easily explainable phenomenon, due to the fact there are many
	% ways to draw the target area, but only one way to draw the target perimeter

	properties

		% STATIC: DO NOT CHANGE
		% IF CHANGE IS NEEDED, MAKE A NEW OBJECT
		
		n = 20;

		p = 5;
		g = 10;

		f = 0;

		b = 10;

		sae = [2:2:40];
		spe = [2:19];

		seed = 1:50;

		targetTime = 500;

		analysisName = 'NoAreaEffect';

		avgGrid = {}
		timePoints = {}

		stabilityGrids = {};

		parameterSet = []

		simulationRuns = 50
		slurmTimeNeeded = 12
		simulationDriverName = 'ManageLayerOnStroma'
		simulationInputCount = 7
		

	end

	methods

		function obj = NoAreaEffect()

			% Each seed runs in a separate job
			obj.specifySeedDirectly = true;
			obj.usingHPC = true;

		end

		function MakeParameterSet(obj)

			% n, p, g, b, f, sae, spe, seed

			params = [];

			for n = obj.n
				for p = obj.p
					for g = obj.g
						for b = obj.b
							for f = obj.f
								for sae = obj.sae
									for spe = obj.spe

										params(end+1,:) = [n,p,g,b,f,sae,spe];

									end
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

			buckleThreshold = 1.05;

			MakeParameterSet(obj);

			buckleOutcome = [];
			buckleTime = [];

			for i = 1:length(obj.parameterSet)
				s = obj.parameterSet(i,:);
				% n, p, g, b, f, sae, spe, seed
				n = s(1);
				p = s(2);
				g = s(3);
				b = s(4);
				f = s(5);
				sae = s(6);
				spe = s(7);


				bottom = [];
				for j = obj.seed
					% try
						a = ManageLayerOnStroma(n,p,g,b,f,sae,spe,j);
						a.LoadSimulationData();
						if max(a.data.bottomWiggleData) >= buckleThreshold
							buckleOutcome(i,j) = true;
							buckleTime(i,j) = find(a.data.bottomWiggleData >= buckleThreshold,1) * 20 * a.dt;
						else
							buckleOutcome(i,j) = false;
							buckleTime(i,j) = obj.targetTime;
						end


					% end
				end

				fprintf('Completed %.2f%%\n', 100*i/length(obj.parameterSet));

			end


			obj.result = {buckleOutcome, buckleTime};

			

		end

		function PlotData(obj)

			buckleOutcome = obj.result{1};
			buckleTime = obj.result{2};

			h = figure;

			scatter(obj.parameterSet(:,7), obj.parameterSet(:,6), 100, sum(buckleOutcome,2)/length(obj.seed),'filled');
			ylabel('Area energy parameter','Interpreter', 'latex', 'FontSize', 15);xlabel('Perimeter energy parameter','Interpreter', 'latex', 'FontSize', 15);
			title(sprintf('Proportion buckled, p=%g, g=%g',obj.p,obj.g),'Interpreter', 'latex', 'FontSize', 22);
			ylim([min(obj.sae)-1, max(obj.sae)+1]);xlim([min(obj.spe)-1, max(obj.spe)+1]);
			colorbar; caxis([0 1]);
			colormap jet;
			ax = gca;
			c = ax.Color;
			ax.Color = 'black';
			set(h, 'InvertHardcopy', 'off')
			set(h,'color','w');

			SavePlot(obj, h, sprintf('BodyParams'));



		end

	end

end