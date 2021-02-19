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
		spe = [2:0.5:5];

		seed = 1:20;

		targetTime = 500;

		analysisName = 'NoAreaEffect';

		avgGrid = {}
		timePoints = {}

		stabilityGrids = {};

		parameterSet = []

		simulationRuns = 20
		slurmTimeNeeded = 24
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


			params = [];

			for p = obj.p
				for g = obj.g
					for w = obj.w
						for b = obj.b
							for sae = obj.sae
								for spe = obj.spe

									params(end+1,:) = [2*w,p,g,w,b,sae,spe];

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

			% Used when there is at least some data ready
			MakeParameterSet(obj);
			result = nan(1,length(obj.parameterSet));
			for i = 1:length(obj.parameterSet)
				s = obj.parameterSet(i,:);
				n = s(1);
				p = s(2);
				g = s(3);
				w = s(4);
				b = s(5);
				sae = s(6);
				spe = s(7);


				bottom = [];
				for j = obj.seed
					% try
						a = RunLayerOnStroma(n,p,g,w,b,sae,spe,j);
						a.LoadSimulationData();
						bottom = Concatenate(obj, bottom, a.data.bottomWiggleData');
					% end
				end

				b = nanmean(bottom);

				result(i) = max(b);


			end


			obj.result = result;

			

		end

		function PlotData(obj)

			for p = obj.p
				for g = obj.g


					h = figure;

					Lidx = obj.parameterSet(:,2) == p;
					tempR = obj.result(L);
					Lidx = obj.parameterSet(Lidx,3) == g;
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

	end

end