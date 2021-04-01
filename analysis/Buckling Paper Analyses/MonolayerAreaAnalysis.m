classdef MonolayerAreaAnalysis < Analysis

	properties

		n
		p
		g   
		b
		f
		sae
		spe  

		seed

		analysisName = 'MonolayerAreaAnalysis';

		parameterSet = []

		simulationRuns = 1
		slurmTimeNeeded = 24
		simulationDriverName = 'LayerOnStroma'
		simulationInputCount = 7
		

	end

	methods

		function obj = MonolayerAreaAnalysis(n, p, g, b, f, sae, spe, seed)

			% Each seed runs in a separate job
			obj.specifySeedDirectly = true;

			obj.n = n;
			obj.p = p;
			obj.g = g;   
		 	obj.b = b;
			obj.f = f;
			obj.sae = sae;
			obj.spe = spe; 
			obj.seed = seed;
			obj.analysisName = sprintf('LayerOnStroma/n%gp%gg%gb%gsae%gspe%gf%gda0ds0.1dl0.2alpha40beta10t0_seed%g/',n,p,g,b,sae,spe, f, seed);

		end

		function MakeParameterSet(obj)

			obj.parameterSet = [];

		end

	

		function AssembleData(obj)

			homeDir = getenv('EDGEDIR');
			geoData = dlmread([homeDir, '/SimulationOutput/', obj.analysisName, 'CellGeometry.csv']);

			geoData(geoData==0) = NaN;

			timeSteps = geoData(:,1);
			geoData = geoData(:,2:end);

			[m,~] = size(geoData);

			% Need to get the max ID
			allIDS = geoData(:,1:6:end);
			maxID = max(max(allIDS));

			geo = nan(maxID,m,6);

			for i = 1:m
				nD  = geoData(i,:);
				nD = reshape(nD,6,[])';
				% First column is ID, then x and y
				
				% For each cell, use the id as the first index,
				% and the second index is the time step. In that
				% position is stored the (x,y) coords
				[mnD, ~] = size(nD);

				for j = 1:mnD
					n = nD(j,:);
					if ~isnan(n(1))
						geo(n(1),i,:) = [timeSteps(i), n(2:end)];
					end

				end

			end

			% Extract the plot of the cell area between division events
			allTime = [];
			allAges = [];
			allAreas = [];
			allPerim = [];
			allTAreas = [];
			allTPerim = [];

			for cID = 1:maxID
				ages = geo(cID,:,2);

				% The indices just before division
				% Add in first non nan at the start to make sure we capture the initial stages
				% after the simulation starts and the last non nan to make sure we get
				% the last stages when the simulation ends or the cell dies
				% We subtract 1 from the first non nan because it helps standardise
				% the for loop below
				div = [find(~isnan(ages),1)-1, find(ages(2:end) < ages(1:end-1)), find(~isnan(ages),1,'last')];

				for i = 1:length(div)-1
					% Separate out the age and the data we want
					timeSep = geo(cID, (div(i)+1):div(i+1), 1);
					agesSep = geo(cID, (div(i)+1):div(i+1), 2);
					areaSep = geo(cID, (div(i)+1):div(i+1), 3);
					periSep = geo(cID, (div(i)+1):div(i+1), 4);
					tAreaSep = geo(cID, (div(i)+1):div(i+1), 5);
					tPeriSep = geo(cID, (div(i)+1):div(i+1), 6);

					allTime = obj.Concatenate(allTime, timeSep);
					allAges = obj.Concatenate(allAges, agesSep);
					allAreas = obj.Concatenate(allAreas, areaSep);
					allPerim = obj.Concatenate(allPerim, periSep);
					allTAreas = obj.Concatenate(allTAreas, tAreaSep);
					allTPerim = obj.Concatenate(allTPerim, tPeriSep);

				end

			end

			

			obj.result = {timeSteps, geo, allTime, allAges, allAreas, allPerim, allTAreas, allTPerim};

		end

		function PlotData(obj)

			geo = obj.result{2};
			time = obj.result{3};
			ages = obj.result{4};
			areas = obj.result{5};

			fontSize = 20;


			time(ages(:,1) > 0.2,:) = [];
			areas(ages(:,1) > 0.2,:) = [];
			ages(ages(:,1) > 0.2,:) = [];

			h = figure;
			plot(ages',areas');
			xlabel('Age (hr)','Interpreter', 'latex', 'FontSize', fontSize);
			ylabel('Area','Interpreter', 'latex', 'FontSize', fontSize);
			ylim([0.3,1]);
			SavePlot(obj, h, sprintf('AreaByAge'));

			h = figure;
			plot(time',areas');
			xlabel('Time (hr)','Interpreter', 'latex', 'FontSize', fontSize);
			ylabel('Area','Interpreter', 'latex', 'FontSize', fontSize);
			ylim([0.3,1]);
			SavePlot(obj, h, sprintf('AreaByTime'));


			mL = nanmean(areas);
			t = nanmean(ages);
			uL = mL + 2*sqrt(nanvar(areas));
			bL = mL - 2*sqrt(nanvar(areas));

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
			ylim([0.3,1]);
			xlabel('Time (hr)','Interpreter', 'latex', 'FontSize', fontSize);
			ylabel('Area','Interpreter', 'latex', 'FontSize', fontSize);
			% title('Average length over time','Interpreter', 'latex','FontSize', 22);
			% ylabel('Avg. length ($\mu$m)','Interpreter', 'latex', 'FontSize', 40);xlabel('Time (min)','Interpreter', 'latex', 'FontSize', 40);

			SavePlot(obj, h, sprintf('AverageAreaByAge'));

		end

	end

end