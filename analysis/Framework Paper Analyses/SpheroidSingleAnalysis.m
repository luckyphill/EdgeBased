classdef SpheroidSingleAnalysis < Analysis

	properties

		% These cannot be changed, since they relate to a specific
		% set of data. If different values are needed, new data is needed
		% and a new analysis class should be made


		% STATIC: DO NOT CHANGE
		% IF CHANGE IS NEEDED, MAKE A NEW OBJECT

		% No input parameters needed

		t0
		tg
		s
		sreg

		seed

		analysisName = 'SpheroidSingleAnalysis';

		parameterSet = []

		simulationRuns = 1
		slurmTimeNeeded = 24
		simulationDriverName = 'Spheroid'
		simulationInputCount = 7
		

	end

	methods

		function obj = SpheroidSingleAnalysis(t0, tg, s, sreg, seed)

			obj.seedIsInParameterSet = false; % The seed not given in MakeParameterSet, it is set in properties
			obj.seedHandledByScript = false; % The seed will be in the parameter file, not the job script

			obj.t0 = t0;
			obj.tg = tg;
			obj.s = s;
			obj.sreg = sreg;   
			obj.seed = seed;
			obj.analysisName = sprintf('%s/t0%gtg%gs%gsreg%gf0.9da-0.1ds0.1dl0.2a20b10t1_seed%g',obj.analysisName, t0, tg, s, sreg, seed);


		end

		function MakeParameterSet(obj)

			obj.parameterSet = [];

		end

	

		function AssembleData(obj)

			% Just need to load the time series as in the visaliser

			pathName = sprintf('%s/t0%gtg%gs%gsreg%gf0.9da-0.1ds0.1dl0.2a20b10t1_seed%g',obj.simulationDriverName, obj.t0, obj.tg, obj.s, obj.sreg, obj.seed);
			v = Visualiser(pathName);

			N = []; % Number of cells
			C = []; % Centre of area
			R90 = []; % Radius about C that captures 80% of the cells
			mA = []; % Mean area of non-growing cells
			RA = {}; % Area/Distance pairs
			pauseRA = {};

			t = v.timeSteps;
			
			[I,~] = size(v.cells);

			for i = 1:I
				R = []; % Radii
				pauseAreas = []; % self evident
				pauseRadii = [];
				CC = []; % Cell centres
				A = []; % Areas
				% i is the time steps
				[~,J] = size(v.cells);
				j = 1;
				angles = [];
				while j <= J && ~isempty(v.cells{i,j})

					c = v.cells{i,j};
					ids = c(1:end-1);
					colour = c(end);
					nodeCoords = squeeze(v.nodes(ids,i,:));

					CC(j,:) = mean(nodeCoords);

					x = nodeCoords(:,1);
					y = nodeCoords(:,2);

					A(j) = polyarea(x,y);



					if colour == 1 && A(j) > 0.4 
						% The are limit cuts out some extreme outliers possibly
						% due to a division event in the previous timestep that
						% does not reflect the true area of the cell
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

			obj.result = {N, C, R90, mA, RA, pauseRA, t}


		end

		function PlotData(obj)

			N = obj.result{1};
			C = obj.result{2};
			R90 = obj.result{3};
			mA = obj.result{4};
			RA = obj.result{5};
			pauseRA = obj.result{6};
			t = obj.result{7};

			h=figure;
			hold on
			box on
			leg = {};
			for idx = 400:400:length(pauseRA)

				if ~isempty(pauseRA{idx})
					r = pauseRA{idx}(:,1);
					a = pauseRA{idx}(:,2);
					bins = 0:0.8:14;
					m = [];
					for i = 1:length(bins)-1
						m(i) = mean(a(  logical( (r>bins(i)) .* (r <= bins(i+1))  )   ) );
					end
					
					plot(bins(2:end), m, 'LineWidth', 4);
					leg{end+1} = ['t= ', num2str(t(idx))];
				end
			end


			tFontSize = 40;
			lFontSize = 40;
			aFontSize = 24;
			% legend(leg)
			ax = gca;
			ax.FontSize = aFontSize;
			title('Avg cell area vs radius','Interpreter', 'latex','FontSize', tFontSize);
			ylabel('Avg area','Interpreter', 'latex', 'FontSize', lFontSize);xlabel('Radius','Interpreter', 'latex', 'FontSize', lFontSize);
			xlim([0 14]);
			ylim([0.425 0.48]);
			
			SavePlot(obj, h, sprintf('AreaRadiusDistribution'));

			figure 
			idx = 2000;
			r = pauseRA{idx}(:,1);
			a = pauseRA{idx}(:,2);
			scatter(r,a)

			figure 
			idx = 1800;
			r = pauseRA{idx}(:,1);
			a = pauseRA{idx}(:,2);
			scatter(r,a)


			h = figure;
			plot(t,N, 'LineWidth', 4);
			ax = gca;
			ax.FontSize = aFontSize;
			title('Cell count over time','Interpreter', 'latex','FontSize', tFontSize);
			ylabel('N','Interpreter', 'latex', 'FontSize', lFontSize);xlabel('time','Interpreter', 'latex', 'FontSize', lFontSize);
			xlim([0 t(end)]);
			SavePlot(obj, h, sprintf('CellCount'));

			h = figure;
			plot(t,mA, 'LineWidth', 4);
			ax = gca;
			ax.FontSize = aFontSize;
			title('Average cell area','Interpreter', 'latex','FontSize', tFontSize);
			ylabel('Area','Interpreter', 'latex', 'FontSize', lFontSize);xlabel('time','Interpreter', 'latex', 'FontSize', lFontSize);
			xlim([0 t(end)]);
			SavePlot(obj, h, sprintf('AvgPauseArea'));

			h = figure;
			plot(t,R90, 'LineWidth', 4);
			ax = gca;
			ax.FontSize = aFontSize;
			title('90\% Radius over time','Interpreter', 'latex','FontSize', tFontSize);
			ylabel('Radius','Interpreter', 'latex', 'FontSize', lFontSize);xlabel('time','Interpreter', 'latex', 'FontSize', lFontSize);
			xlim([0 t(end)]);
			SavePlot(obj, h, sprintf('Radius90'));


			pathName = sprintf('%s/t0%gtg%gs%gsreg%gf0.9da-0.1ds0.1dl0.2a20b10t1_seed%g',obj.simulationDriverName, obj.t0, obj.tg, obj.s, obj.sreg, obj.seed);
			v = Visualiser(pathName);

			v.PlotTimeStep(2000);
			a = gca;
			xyrange = [a.XLim, a.YLim];

			SavePlot(obj, gcf, sprintf('T200'));

			v.PlotTimeStep(1600, xyrange);SavePlot(obj, gcf, sprintf('T160'));
			v.PlotTimeStep(1200, xyrange);SavePlot(obj, gcf, sprintf('T120'));
			v.PlotTimeStep(800, xyrange);SavePlot(obj, gcf, sprintf('T80'));
			v.PlotTimeStep(400, xyrange);SavePlot(obj, gcf, sprintf('T40'));
			v.PlotTimeStep(1, xyrange,'t = 0 hrs');SavePlot(obj, gcf, sprintf('T0'));


		end

	end

end