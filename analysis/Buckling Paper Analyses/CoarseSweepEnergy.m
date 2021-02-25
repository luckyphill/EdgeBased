classdef CoarseSweepEnergy < Analysis

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

		sae = [5:10:100];
		spe = [5:10:100];

		seed = 1:20;

		targetTime = 500;

		analysisName = 'CoarseSweepEnergy';

		avgGrid = {}
		timePoints = {}

		stabilityGrids = {};

		parameterSet = []

		simulationRuns = 20
		slurmTimeNeeded = 12
		simulationDriverName = 'ManageLayerOnStroma'
		simulationInputCount = 7
		

	end

	methods

		function obj = CoarseSweepEnergy()

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

			end


			obj.result = {buckleOutcome, buckleTime};

			

		end

		function PlotData(obj)

			buckleOutcome = obj.result{1};
			buckleTime = obj.result{2};

			h = figure;

			Lidx = obj.parameterSet(:,2) == obj.p;
			tempR = obj.result(L);
			Lidx = obj.parameterSet(Lidx,3) == obj.g;
			data = tempR(Lidx);

			data = reshape(obj.result,length(obj.sae),length(obj.spe));

			[A,P] = meshgrid(obj.sae,obj.spe);

			surf(A,P,data);
			xlabel('Area force parameter','Interpreter', 'latex', 'FontSize', 15);ylabel('Perimeter force parameter','Interpreter', 'latex', 'FontSize', 15);
			title(sprintf('Long term max wiggle ratio for stroma force params'),'Interpreter', 'latex', 'FontSize', 22);
			shading interp
			xlim([2 20]);ylim([1 10]);
			colorbar;view(90,-90);caxis([1 1.5]);

			SavePlot(obj, h, sprintf('BodyParams'));



		end

	end

end