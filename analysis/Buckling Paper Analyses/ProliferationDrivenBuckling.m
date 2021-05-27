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
		spe = 10;

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

			spe = obj.spe;

			h = figure;

			data = nansum(buckleOutcome,2)./sum(~isnan(buckleOutcome),2);
			% data = sum(~isnan(buckleOutcome),2);

			params = obj.parameterSet(:,[2,3]);

			scatter(params(:,2), params(:,1), 100, data,'filled');
			ylabel('Pause','Interpreter', 'latex', 'FontSize', 15);xlabel('Grow','Interpreter', 'latex', 'FontSize', 15);
			title(sprintf('Proportion buckled, spe=%d', spe),'Interpreter', 'latex', 'FontSize', 22);
			ylim([4.5 12.5]);
			xlim([4.5 12.5]);
			colorbar; 
			caxis([0 1]);
			colormap jet;
			ax = gca;
			c = ax.Color;
			ax.Color = 'black';
			set(h, 'InvertHardcopy', 'off')
			set(h,'color','w');

			SavePlot(obj, h, sprintf('PhaseTestProp_spe%d',spe));

			% h = figure;
			% scatter(params(:,2), params(:,1), 100, dataT,'filled');
			% ylabel('Pause','Interpreter', 'latex', 'FontSize', 15);xlabel('Grow','Interpreter', 'latex', 'FontSize', 15);
			% title(sprintf('Tipping point, p=%g, g=%g',p,g),'Interpreter', 'latex', 'FontSize', 22);
			% ylim([1 41]);xlim([1.5 15.5]);
			% colorbar; caxis([1 1.1]);
			% colormap jet;
			% ax = gca;
			% c = ax.Color;
			% ax.Color = 'black';
			% set(h, 'InvertHardcopy', 'off')
			% set(h,'color','w');

			% SavePlot(obj, h, sprintf('PhaseTestTip_spe%d',spe));



			% h = figure;
			% leg = {};
			% for spe = 5:5:20
			% 	leg{end+1} = sprintf('spe=%d',spe);
			% 	Lidx = obj.parameterSet(:,7) == spe;
			% 	data = obj.result(Lidx);
			% 	para = obj.parameterSet(Lidx,:);

			% 	Lidx = (data > 0.4);

			% 	data = data(Lidx);
			% 	para = para(Lidx,:);

			% 	Lidx = (data < 0.6);

			% 	data = data(Lidx);
			% 	para = para(Lidx,:);

			% 	x = para(:,3);
			% 	y = para(:,2);

			% 	hold on
			% 	% scatter(x,y,100,'filled');
			% 	% Perform a least squares regression
			% 	b = [ones(size(x)),x]\y;
			% 	p = b' * [ones(size(obj.g)); obj.g];
			% 	plot(obj.g,p,'LineWidth', 4)

			% end

			% ylabel('Pause','Interpreter', 'latex', 'FontSize', 15);xlabel('Grow','Interpreter', 'latex', 'FontSize', 15);
			% title(sprintf('Proportion buckled = 0.5'),'Interpreter', 'latex', 'FontSize', 22);
			% ylim([4.5 15.5]);xlim([4.5 15.5]);
			% legend(leg);
			% SavePlot(obj, h, sprintf('PhaseTestWaveFront_spe%d',spe));

		end

	end

end