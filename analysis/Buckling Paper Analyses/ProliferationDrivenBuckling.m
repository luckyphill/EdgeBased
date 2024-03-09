classdef ProliferationDrivenBuckling < Analysis

	properties

		% These cannot be changed, since they relate to a specific
		% set of data. If different values are needed, new data is needed
		% and a new analysis class should be made


		% STATIC: DO NOT CHANGE
		% IF CHANGE IS NEEDED, MAKE A NEW OBJECT
		p = 5:.5:12;
		g = 5:.5:12;

		w = 10;

		f = 0;

		b = 10;

		sae = 10;
		spe = [4,6,8,10,12];

		seed = 1:50;

		targetTime = 500;

		analysisName = 'ProliferationDrivenBuckling';

		parameterSet = []
		missingParameterSet = []

		simulationRuns = 50
		slurmTimeNeeded = 12
		simulationDriverName = 'ManageDynamicLayer'
		simulationInputCount = 7
		

	end

	methods

		function obj = ProliferationDrivenBuckling()

			obj.seedIsInParameterSet = false; % The seed not given in MakeParameterSet, it is set in properties
			obj.seedHandledByScript = false; % The seed will be in the parameter file, not the job script
			obj.usingHPC = true;

		end

		function MakeParameterSet(obj)


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

			for spe = obj.spe;

				h = figure;

				idx = obj.parameterSet(:,7) == spe;

				d = buckleOutcome(idx,:);

				data = nansum(d,2)./sum(~isnan(d),2);
				% data = sum(~isnan(d),2);

				params = obj.parameterSet(idx,[2,3]);

				scatter(params(:,2), params(:,1), 400, data,'filled');
                ax = gca;
                ax.FontSize = 15;
				ylabel('Mean pause duration ($\bar{t}_P$)','Interpreter', 'latex', 'FontSize', 20);
                xlabel('Mean growth duration ($\bar{t}_G$)','Interpreter', 'latex', 'FontSize', 20);
				% title(sprintf('Proportion buckled'),'Interpreter', 'latex', 'FontSize', 28);
				axis equal;
                ylim([4.5 12.5]);
				xlim([4.5 12.5]);
				set(ax, 'XTick', min(obj.g):max(obj.g));
				set(ax, 'XTickLabel', min(obj.g):max(obj.g));
				c = colorbar;
				c.Label.String = 'Proportion buckled';
				c.Label.Interpreter = 'latex';
				c.Label.FontSize = 20;
                c.TickLabelInterpreter = 'latex';
				caxis([0 1]);
				colormap jet;
                ax.TickLabelInterpreter = 'latex';
				ax.Color = 'black';
				set(h, 'InvertHardcopy', 'off')
				set(h,'color','w');
                

				SavePlot(obj, h, sprintf('PhaseTestProp_spe%d',spe));

			end

		end

	end

end