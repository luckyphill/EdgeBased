classdef VolfsonMultiAnalysis < Analysis

	properties

		seed

		analysisName = 'VolfsonMultiAnalysis';

		parameterSet = []

		simulationRuns = 1
		slurmTimeNeeded = 24
		simulationDriverName = 'VolfsonExperiment'
		simulationInputCount = 7

		allQ
		allL
		

	end

	methods

		function obj = VolfsonMultiAnalysis(seed)

			obj.specifySeedDirectly = true;
  
			obj.seed = seed;


		end

		function MakeParameterSet(obj)

			obj.parameterSet = [];

		end

	

		function AssembleData(obj)

			allQ = [];
			allL = [];
			allN = [];
			r = Visualiser.empty;
			for k = obj.seed
				pathName = sprintf('VolfsonExperiment/n20l6r5s40tg10w30f0.9t00da0ds1dl1a0_seed%g/',k);
				r = Visualiser(pathName);

				angles = 0;

				Q = [];
				L = [];
				N = [];
				lengths = [];

				[I,~] = size(r.cells);
				for i = 1:I
					% i is the time steps
					[~,J] = size(r.cells);
					j = 1;
					angles = [];
					while j <= J && ~isempty(r.cells{i,j})

						c = r.cells{i,j};
						ids = c(1:end-1);
						colour = c(end);
						nodeCoords = squeeze(r.nodes(ids,i,:));

						x = nodeCoords(:,1);
						y = nodeCoords(:,2);

						angles(j) = atan( (x(1)-x(2)) / (y(1)-y(2)));
						lengths(end + 1) = norm(nodeCoords(1,:) - nodeCoords(2,:));

						j = j + 1;

					end
					% j will always end up being 1 more than the total number of non empty cells

					Q(end + 1) = sqrt(  mean(cos( 2.* angles))^2 + mean(sin( 2.* angles))^2   );
					L(end + 1) = mean(lengths);
					N(end + 1) = J;

				end

				allQ = Concatenate(obj, allQ, Q);
				allL = Concatenate(obj, allL, L);
				allN = Concatenate(obj, allN, N);

			end

			obj.result = {allQ, allL, allN};

		end

		function PlotData(obj, varargin)

			l = 1; % The component of the length taken up by the preferred separation radius

			allQ = obj.result{1};
			allL = obj.result{2} + l;
			allN = obj.result{3};

			tFontSize = 40;
			lFontSize = 20;
			aFontSize = 24;

			% t = 0.1:0.1:200;
			t = 0.1:0.1:length(allQ)/10;

			mQ = nanmean(allQ);
			uQ = mQ + sqrt(nanvar(allQ));
			bQ = mQ - sqrt(nanvar(allQ));
			% figure;plot(sqrt(nanvar(allQ)))
			h = figure;
			plot(t,mQ, 'LineWidth', 4);
			hold on
			fill([t,fliplr(t)], [uQ,fliplr(bQ)], [0, .45, 0.74], 'FaceAlpha', 0.25, 'EdgeAlpha',0);
			ax = gca;
			ax.FontSize = 16;
			% title('Disorder factor Q over time','Interpreter', 'latex','FontSize', 22);
			ylabel('Q','Interpreter', 'latex', 'FontSize', 40);xlabel('time','Interpreter', 'latex', 'FontSize', 40);
			ylim([0 0.7]);; xlim([0 200]);
			SavePlot(obj, h, sprintf('QFactor'));


			mL = nanmean(allL);
			uL = mL + 2*sqrt(nanvar(allL));
			bL = mL - 2*sqrt(nanvar(allL));

			uT = t(~isnan(uL));
			uL = uL(~isnan(uL));

			bT = t(~isnan(bL));
			bL = bL(~isnan(bL));
			
			h = figure;
			plot(t,mL, 'LineWidth', 4);
			hold on
			fill([bT,fliplr(uT)], [bL,fliplr(uL)], [0, .45, 0.74], 'FaceAlpha', 0.25, 'EdgeAlpha',0);
			ax = gca;
			ax.FontSize = 16;
			% title('Average length over time','Interpreter', 'latex','FontSize', 22);
			ylabel('Avg. length','Interpreter', 'latex', 'FontSize', 40);xlabel('time','Interpreter', 'latex', 'FontSize', 40);
			ylim([2 5]); xlim([0 200]);
			SavePlot(obj, h, sprintf('AvgLength'));




			mN = nanmean(allN);
			uN = mN + sqrt(nanvar(allN));
			bN = mN - sqrt(nanvar(allN));
			% figure;plot(sqrt(nanvar(allN)))
			h = figure;
			plot(t,mN, 'LineWidth', 4);
			hold on
			fill([t,fliplr(t)], [uN,fliplr(bN)], [0, .45, 0.74], 'FaceAlpha', 0.25, 'EdgeAlpha',0);
			ax = gca;
			ax.FontSize = 16;
			% title('Disorder factor N over time','Interpreter', 'latex','FontSize', 22);
			ylabel('N','Interpreter', 'latex', 'FontSize', 40);xlabel('time','Interpreter', 'latex', 'FontSize', 40);
			xlim([0 200]); %ylim([0 0.7]);
			SavePlot(obj, h, sprintf('N'));


		end

	end

end