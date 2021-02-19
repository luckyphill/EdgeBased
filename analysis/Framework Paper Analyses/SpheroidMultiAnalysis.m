classdef SpheroidMultiAnalysis < Analysis

	properties

		seed

		analysisName = 'SpheroidMultiAnalysis';

		parameterSet = []

		simulationRuns = 1
		slurmTimeNeeded = 24
		simulationDriverName = 'Spheroid'
		simulationInputCount = 7
		

	end

	methods

		function obj = SpheroidMultiAnalysis(seed)

			% Each seed runs in a separate job
			obj.specifySeedDirectly = true;

			obj.seed = seed;


		end

		function MakeParameterSet(obj)

			obj.parameterSet = [];

		end

		function AssembleData(obj)

			allN = [];
			allR90 = [];
			allPauseRA = {};
			
			for k = obj.seed
				pathName = sprintf('Spheroid/t010tg10s10sreg5f0.9da-0.1ds0.1dl0.2a20b10t1_seed%g/',k);
				r = Visualiser(pathName);

				N = []; % Number of cells
				C = []; % Centre of area
				R90 = []; % Radius about C that captures 90% of the cells
				mA = []; % Mean area of non-growing cells
				RA = {}; % Area/Distance pairs
				pauseRA = {};
				
				[I,~] = size(r.cells);

				for i = 1:I
					R = []; % Radii
					pauseAreas = []; % self evident
					pauseRadii = [];
					CC = []; % Cell centres
					A = []; % Areas
					% i is the time steps
					[~,J] = size(r.cells);
					j = 1;
					angles = [];
					while j <= J && ~isempty(r.cells{i,j})

						c = r.cells{i,j};
						ids = c(1:end-1);
						colour = c(end);
						nodeCoords = squeeze(r.nodes(ids,i,:));

						CC(j,:) = mean(nodeCoords);

						x = nodeCoords(:,1);
						y = nodeCoords(:,2);

						A(j) = polyarea(x,y);

						cs=CoulourSet();

						if colour == cs.GetNumber('PAUSE') || colour == cs.GetNumber('STOPPED')
							% Assemble areas of non-growing cells
							pauseAreas(end+1) = A(j);
							pauseRadii(end+1) = norm(mean(nodeCoords));
						end

						j = j + 1;

					end
					% j will always end up being 1 more than the total number of non empty cells

					N(end + 1) = j-1;
					C(end + 1,:) = mean(CC);
					mA(end + 1) = mean(pauseAreas);


					R = sqrt(sum(abs(CC-C(end,:)).^2,2));

					RA{end + 1} = [R,A'];
					pauseRA{end + 1} = [pauseRadii',pauseAreas'];

					R = sort(R);
					R90(end + 1) = R(ceil(.9*(j-1)));


				end

				allN(end+1,:) = N;
				allR90(end+1,:) = R90;
				allPauseRA{end+1} = pauseRA;

			end

			obj.result = {allN, allR90, allPauseRA};

		end

		function PlotData(obj)


			

			h=figure;
			hold on
			box on
			leg = {};
			allPauseRA = obj.result{3};
			bins = 0:0.8:14;
			M = [];
			for k = obj.seed
				pauseRA = allPauseRA{k};
				allMean = [];
				for idx = 400:400:2000

					if ~isempty(pauseRA{idx})
						r = pauseRA{idx}(:,1);
						a = pauseRA{idx}(:,2);
						
						m = [];
						for i = 1:length(bins)-1
							m(i) = mean(a(  logical( (r>bins(i)) .* (r <= bins(i+1))  )   ) );
						end
						
					end
					allMean(:,end+1) = m;
				end

				M(end+1,:,:) = allMean; 

			end

			CD = 15;
			h = figure;
			hold on;
			for i=1:5
				plot(CD*bins(2:end), nanmean(M(:,:,i)), 'LineWidth', 4);
			end


			tFontSize = 40;
			lFontSize = 30;
			aFontSize = 24;
			% legend(leg)
			ax = gca;
			ax.FontSize = aFontSize;
			title('Avg cell area vs radius','Interpreter', 'latex','FontSize', tFontSize);
			ylabel('Avg area / $$S_{\mathrm{grown}}$$','Interpreter', 'latex', 'FontSize', lFontSize);xlabel('Radius ($\mu$m)','Interpreter', 'latex', 'FontSize', lFontSize);
			xlim([0 14*CD]);
			ylim([0.425 0.48]);
			
			SavePlot(obj, h, sprintf('AreaRadiusDistribution'));

			N = obj.result{1}(obj.seed,:);

			maxN = max(N);
			minN = min(N);
			avgN = mean(N);
			h = figure;
			plot(0.1:0.1:200,avgN, 'LineWidth', 4);
			hold on
			fill([0.1:0.1:200,fliplr(0.1:0.1:200)], [minN,fliplr(maxN)], [0, .45, 0.74], 'FaceAlpha', 0.25, 'EdgeAlpha',0);
			ax = gca;
			ax.FontSize = aFontSize;
			title('Cell count over time','Interpreter', 'latex','FontSize', tFontSize);
			ylabel('N','Interpreter', 'latex', 'FontSize', lFontSize);xlabel('Time (hr)','Interpreter', 'latex', 'FontSize', lFontSize);
			xlim([0 200]);
			SavePlot(obj, h, sprintf('CellCount'));

			R90 = obj.result{2}(obj.seed,:);
			maxR90 = max(R90);
			minR90 = min(R90);
			avgR90 = mean(R90);
			h = figure;
			plot(0.1:0.1:200,CD*avgR90, 'LineWidth', 4);
			hold on
			fill([0.1:0.1:200,fliplr(0.1:0.1:200)], [CD*minR90,CD*fliplr(maxR90)], [0, .45, 0.74], 'FaceAlpha', 0.25, 'EdgeAlpha',0);
			ax = gca;
			ax.FontSize = aFontSize;
			title('90\% Radius over time','Interpreter', 'latex','FontSize', tFontSize);
			ylabel('Radius ($\mu$m)','Interpreter', 'latex', 'FontSize', lFontSize);xlabel('Time (hr)','Interpreter', 'latex', 'FontSize', lFontSize);
			xlim([0 200]);
			SavePlot(obj, h, sprintf('Radius90'));

		end

	end

end