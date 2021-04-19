classdef BucklingModes < Analysis

	% This analysis compares buckling due to weak membrane adhesion,
	% buckling due to weak membrane tension

	properties

		% STATIC: DO NOT CHANGE
		% IF CHANGE IS NEEDED, MAKE A NEW OBJECT
		
		w = 10;

		p = 10;
		g = 5;

		f = 0;

		b = 1:20;

		sae = 10;
		spe = 1:20;

		seed = 1:50;

		targetTime = 500;

		analysisName = 'BucklingModes';

		parameterSet = []
		missingParameterSet = []

		simulationRuns = 50
		slurmTimeNeeded = 12
		simulationDriverName = 'ManageDynamicLayer'
		simulationInputCount = 7
		

	end

	methods

		function obj = BucklingModes()

			obj.seedIsInParameterSet = false; % The seed not given in MakeParameterSet, it is set in properties
			obj.seedHandledByScript = false; % The seed will be in the parameter file, not the job script
			obj.usingHPC = true;

		end

		function MakeParameterSet(obj)

			% n, p, g, b, f, sae, spe

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

			buckleThreshold = 1.1;

			MakeParameterSet(obj);

			buckleOutcome = [];
			buckleTime = [];
			stromaRatioAtBuckle = [];

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
							if ~isnan(a.data.stromaWiggleData)
								stromaRatioAtBuckle(i,j) = a.data.stromaWiggleData(find(a.data.bottomWiggleData >= buckleThreshold,1));
							else
								stromaRatioAtBuckle(i,j) = nan;
								obj.missingParameterSet(end + 1,:) =[w,p,g,b,f,sae,spe,j];
							end
						else
							buckleOutcome(i,j) = false;
							buckleTime(i,j) = obj.targetTime;
							stromaRatioAtBuckle(i,j) = nan;
						end
					else
						% In case the simulation fails for some reason
						buckleOutcome(i,j) = nan;
						buckleTime(i,j) = nan;
						stromaRatioAtBuckle(i,j) = nan;

						obj.missingParameterSet(end + 1,:) =[w,p,g,b,f,sae,spe,j];
					end
			
				end

				fprintf('Completed %3.2f%%\n', 100*i/length(obj.parameterSet));

			end


			obj.result = {buckleOutcome, buckleTime, stromaRatioAtBuckle};

			if ~isempty(obj.missingParameterSet)

				obj.ProduceMissingDataSimulationFiles();
			end
			

		end

		function PlotData(obj)

			buckleOutcome = obj.result{1};
			buckleTime = obj.result{2};

			h = figure;

			% data = nansum(buckleOutcome,2)./sum(~isnan(buckleOutcome),2);
			data = nanmean(buckleOutcome,2);

			scatter(obj.parameterSet(:,7), obj.parameterSet(:,4), 100, data,'filled');
			ylabel('Adhesion parameter','Interpreter', 'latex', 'FontSize', 15);
			xlabel('Perimeter energy parameter','Interpreter', 'latex', 'FontSize', 15);
			title(sprintf('Proportion buckled, p=%g, g=%g',obj.p,obj.g),'Interpreter', 'latex', 'FontSize', 22);
			ylim([min(obj.b)-1, max(obj.b)+1]);
			xlim([min(obj.spe)-1, max(obj.spe)+1]);
			colorbar; caxis([0 1]);
			colormap jet;
			ax = gca;
			c = ax.Color;
			ax.Color = 'black';
			set(h, 'InvertHardcopy', 'off')
			set(h,'color','w');

			SavePlot(obj, h, sprintf('PerimVSAdhesion'));


			stromaRatioAtBuckle = obj.result{3};

			h = figure;

			data = nanmean(stromaRatioAtBuckle,2);

			scatter(obj.parameterSet(:,7), obj.parameterSet(:,4), 100, data,'filled');
			ylabel('Adhesion parameter','Interpreter', 'latex', 'FontSize', 15);
			xlabel('Perimeter energy parameter','Interpreter', 'latex', 'FontSize', 15);
			title(sprintf('Average stroma ratio at buckle, p=%g, g=%g',obj.p,obj.g),'Interpreter', 'latex', 'FontSize', 22);
			ylim([min(obj.b)-1, max(obj.b)+1]);
			xlim([min(obj.spe)-1, max(obj.spe)+1]);
			colorbar; caxis([0 1]);
			colormap jet;
			ax = gca;
			c = ax.Color;
			ax.Color = 'black';
			set(h, 'InvertHardcopy', 'off')
			set(h,'color','w');

			SavePlot(obj, h, sprintf('BucklingMode'));



		end

	end

end