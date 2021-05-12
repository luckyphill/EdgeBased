classdef FlatAreaAnalysis < Analysis

	properties

		n
		p
		g   
		b
		f
		an
		pn
		ag
		pg
		hack  

		seed

		analysisName = 'FlatAreaAnalysis';

		parameterSet = []

		simulationRuns = 1
		slurmTimeNeeded = 24
		simulationDriverName = 'LayerOnFlat'
		simulationInputCount = 9
		

	end

	methods

		function obj = FlatAreaAnalysis(n, p, g, b, f, an, ag, pn, pg, hack, seed)

			% Each seed runs in a separate job
			obj.seedIsInParameterSet = false; % The seed not given in MakeParameterSet, it is set in properties
			obj.seedHandledByScript = false; % The seed will be in the parameter file, not the job script

			obj.n = n;
			obj.p = p;
			obj.g = g;   
		 	obj.b = b;
			obj.f = f;
			obj.an = an;
			obj.pn = pn;
			obj.ag = ag;
			obj.pg = pg;
			obj.hack = hack;

			obj.seed = seed;
			obj.analysisName = sprintf('FlatAreaAnalysis/n%gp%gg%gb%gf%gda0ds0.1dl0.2alpha20beta10t0an%gag%gpn%gpg%ghack%g_seed%g/',n,p,g,b,f,an,ag,pn,pg, hack, seed);

		end

		function MakeParameterSet(obj)

			obj.parameterSet = [];

		end

	

		function AssembleData(obj)

			homeDir = getenv('EDGEDIR');

			driverLocation = sprintf('LayerOnFlat/n%gp%gg%gb%gf%gda0ds0.1dl0.2alpha20beta10t0an%gag%gpn%gpg%ghack%g_seed%g/',obj.n,obj.p,obj.g,obj.b,obj.f,obj.an,obj.ag,obj.pn,obj.pg,obj.hack,obj.seed);
			geoData = dlmread([homeDir, '/SimulationOutput/', driverLocation, 'CellGeometry.csv']);

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
			perims = obj.result{6};

			fontSize = 20;


			time(ages(:,1) > 0.2,:) = [];
			areas(ages(:,1) > 0.2,:) = [];
			perims(ages(:,1) > 0.2,:) = [];
			ages(ages(:,1) > 0.2,:) = [];
			

			h = figure;
			plot(ages',areas');
			xlabel('Age (hr)','Interpreter', 'latex', 'FontSize', fontSize);
			ylabel('Area','Interpreter', 'latex', 'FontSize', fontSize);
			ylim([0.3,1]);
			SavePlot(obj, h, sprintf('AreaByAge'));

			h = figure;
			plot(ages',perims');
			xlabel('Age (hr)','Interpreter', 'latex', 'FontSize', fontSize);
			ylabel('Perimeter','Interpreter', 'latex', 'FontSize', fontSize);
			ylim([2.6,4.2]);
			SavePlot(obj, h, sprintf('PerimeterByAge'));

			h = figure;
			plot(time',areas');
			xlabel('Time (hr)','Interpreter', 'latex', 'FontSize', fontSize);
			ylabel('Area','Interpreter', 'latex', 'FontSize', fontSize);
			ylim([0.3,1]);
			SavePlot(obj, h, sprintf('AreaByTime'));

			h = figure;
			plot(time',perims');
			xlabel('Age (hr)','Interpreter', 'latex', 'FontSize', fontSize);
			ylabel('Perimeter','Interpreter', 'latex', 'FontSize', fontSize);
			ylim([2.6,4.2]);
			SavePlot(obj, h, sprintf('PerimeterByTime'));


			% h = figure;
			% scatter3(areas(:),perims(:),ages(:),[],ages(:));
			% xlabel('Area','Interpreter', 'latex', 'FontSize', fontSize);
			% ylabel('Perimeter','Interpreter', 'latex', 'FontSize', fontSize);
			% zlabel('Age (hr)','Interpreter', 'latex', 'FontSize', fontSize);
			% colorbar
			% % ylim([2.6,4.2]);
			% SavePlot(obj, h, sprintf('AreaVSPerimeter'));


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
			xlim([-0.3, 25]);
			ylim([0.3,1]);
			xlabel('Age (hr)','Interpreter', 'latex', 'FontSize', fontSize);
			ylabel('Area (CD$^2$)','Interpreter', 'latex', 'FontSize', fontSize);
			title('Average area by cell age','Interpreter', 'latex','FontSize', 22);

			SavePlot(obj, h, sprintf('AverageAreaByAge'));


			mL = nanmean(perims);
			t = nanmean(ages);
			uL = mL + 2*sqrt(nanvar(perims));
			bL = mL - 2*sqrt(nanvar(perims));

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
			xlim([-0.3, 25]);
			ylim([2.6,4.2]);
			xlabel('Age (hr)','Interpreter', 'latex', 'FontSize', fontSize);
			ylabel('Perimeter (CD)','Interpreter', 'latex', 'FontSize', fontSize);
			title('Average perimeter by cell age','Interpreter', 'latex','FontSize', 22);

			SavePlot(obj, h, sprintf('AveragePerimeterByAge'));

		end

	end

end