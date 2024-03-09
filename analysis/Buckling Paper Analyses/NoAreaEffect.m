classdef NoAreaEffect < Analysis

	% This analysis demonstrates that buckling likelihood is not impacted by
	% the area properties of the stroma and only impacted by the boundary tension
	% properties (which is represented by an energy due to difference from intended
	% length). This an easily explainable phenomenon, due to the fact there are many
	% ways to draw the target area, but only one way to draw the target perimeter

	properties

		% STATIC: DO NOT CHANGE
		% IF CHANGE IS NEEDED, MAKE A NEW OBJECT
		
		w = 10;

		p = 10;
		g = 5;

		f = 0;

		b = 10;

		sae = [1:20];
		spe = [1:20];

		seed = 1:50;

		targetTime = 500;

		analysisName = 'NoAreaEffect';

		parameterSet = []
		missingParameterSet = []

		simulationRuns = 50
		slurmTimeNeeded = 12
		simulationDriverName = 'ManageDynamicLayer'
		simulationInputCount = 7
		

	end

	methods

		function obj = NoAreaEffect()

			obj.seedIsInParameterSet = false; % The seed not given in MakeParameterSet, it is set in properties
			obj.seedHandledByScript = false; % The seed will be in the parameter file, not the job script
			obj.usingHPC = true;

		end

		function MakeParameterSet(obj)

			% w, p, g, b, f, sae, spe, seed

			params = [];

			for w = obj.w
				for p = obj.p
					for g = obj.g
						for b = obj.b
							for f = obj.f
								for sae = obj.sae
									for spe = obj.spe

										params(end+1,:) = [w,p,g,b,f,sae,spe];

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
				% w, p, g, b, f, sae, spe, seed
				w = s(1);
				p = s(2);
				g = s(3);
				b = s(4);
				f = s(5);
				sae = s(6);
				spe = s(7);


				bottom = [];
				for j = obj.seed

					a = ManageDynamicLayer(w,p,g,b,f,sae,spe,j);
					a.LoadSimulationData();
					if ~isnan(a.data.bottomWiggleData)
						if max(a.data.bottomWiggleData) >= buckleThreshold
							buckleOutcome(i,j) = true;
							buckleTime(i,j) = find(a.data.bottomWiggleData >= buckleThreshold,1) * 20 * a.dt;
						else
							buckleOutcome(i,j) = false;
							buckleTime(i,j) = obj.targetTime;
						end
					else
						% In case the simulation fails for some reason
						buckleOutcome(i,j) = nan;
						buckleTime(i,j) = nan;

						obj.missingParameterSet(end + 1,:) =[w,p,g,b,f,sae,spe,j];

					end


				end

				fprintf('Completed %3.2f%%\n', 100*i/length(obj.parameterSet));

			end


			obj.result = {buckleOutcome, buckleTime};

			if ~isempty(obj.missingParameterSet)

				obj.ProduceMissingDataSimulationFiles();
			end
			

		end

		function PlotData(obj)

			buckleOutcome = obj.result{1};
			buckleTime = obj.result{2};

			h = figure;

			data = nansum(buckleOutcome,2)./sum(~isnan(buckleOutcome),2);

			scatter(obj.parameterSet(:,7), obj.parameterSet(:,6), 250, data,'filled');
			ax = gca;
            ax.FontSize = 15;
            ylabel('Area energy ($\alpha_S$)','Interpreter', 'latex', 'FontSize', 20);
			xlabel('Perimeter energy ($\beta_S$)','Interpreter', 'latex', 'FontSize', 20);
			% title(sprintf('Proportion buckled'),'Interpreter', 'latex', 'FontSize', 28);
			axis equal;
            ylim([min(obj.sae)-1, max(obj.sae)+1]);
            xlim([min(obj.spe)-1, max(obj.spe)+1]);
            set(ax, 'XTick', 0:2:max(obj.spe));
			set(ax, 'XTickLabel', 0:2:max(obj.spe));
			c = colorbar;
			c.Label.String = 'Proportion buckled';
			c.Label.Interpreter = 'latex';
			c.Label.FontSize = 20;
            c.TickLabelInterpreter = 'latex';
            ax.TickLabelInterpreter = 'latex';
            caxis([0 1]);
			colormap jet;
			c = ax.Color;
			ax.Color = 'black';
			set(h, 'InvertHardcopy', 'off')
			set(h,'color','w');

			SavePlot(obj, h, sprintf('BodyParams'));



		end

	end

end