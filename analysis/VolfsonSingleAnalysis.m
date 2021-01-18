classdef VolfsonSingleAnalysis < Analysis

	properties

		n
		l
		r
		s
		tg
		w
		f

		seed

		analysisName = 'VolfsonSingleAnalysis';

		parameterSet = []

		simulationRuns = 1
		slurmTimeNeeded = 24
		simulationDriverName = 'VolfsonExperiment'
		simulationInputCount = 7
		

	end

	methods

		function obj = VolfsonSingleAnalysis(n, l, r, s, tg, w, f, seed)

			% Each seed runs in a separate job
			obj.specifySeedDirectly = true;

			obj.n = n;
			obj.l = l;
			obj.r = r;   
		 	obj.s = s;
			obj.tg = tg;   
			obj.w = w;
			obj.f = f;   
			obj.seed = seed;
			obj.analysisName = sprintf('%s/n%gl%gr%gs%gtg%gw%gf%gt00da0ds1dl1a0_seed%g',obj.analysisName,obj.n,obj.l,obj.r,obj.s,obj.tg,obj.w,obj.f,obj.seed);


		end

		function MakeParameterSet(obj)

			obj.parameterSet = [];

		end

	

		function AssembleData(obj)

			obj.result = Visualiser(sprintf('%s/n%gl%gr%gs%gtg%gw%gf%gt00da0ds1dl1a0_seed%g',obj.simulationDriverName,obj.n,obj.l,obj.r,obj.s,obj.tg,obj.w,obj.f,obj.seed));


		end

		function PlotData(obj, varargin)

			h = figure;

			angles = 0;

			A = [];
			Q = [];
			L = [];
			lengths = [];

			xlim([0 1.6]);
			ylim([0  0.5]);
			[I,~] = size(obj.result.cells);
			startI = 1;
			if ~isempty(varargin)
				startI = varargin{1};
			end

			% i = 1900;
			for i = startI:I
				% i is the time steps
				[~,J] = size(obj.result.cells);
				j = 1;
				angles = [];
				while j <= J && ~isempty(obj.result.cells{i,j})

					c = obj.result.cells{i,j};
					ids = c(1:end-1);
					colour = c(end);
					nodeCoords = squeeze(obj.result.nodes(ids,i,:));

					x = nodeCoords(:,1);
					y = nodeCoords(:,2);

					angles(j) = atan( (x(1)-x(2)) / (y(1)-y(2)));

					lengths(end + 1) = norm(nodeCoords(1,:) - nodeCoords(2,:));


					j = j + 1;

				end
				% j will always end up being 1 more than the total number of non empty cells

				Q(end + 1) = sqrt(  mean(cos( 2.* angles))^2 + mean(sin( 2.* angles))^2   );
				A(end + 1) = mean(abs(angles));
				L(end + 1) = mean(lengths);


			end

			plot(obj.result.timeSteps,Q, 'LineWidth', 4);
			ax = gca;
			ax.FontSize = 16;
			% title('Disorder factor Q over time','Interpreter', 'latex','FontSize', 22);
			ylabel('Q','Interpreter', 'latex', 'FontSize', 40);xlabel('time','Interpreter', 'latex', 'FontSize', 40);
			ylim([0 1.1]);; xlim([0 180]);
			SavePlot(obj, h, sprintf('QFactor'));
			
			h = figure;
			plot(obj.result.timeSteps,A, 'LineWidth', 4);
			ax = gca;
			ax.FontSize = 16;
			% title('Average angle over time','Interpreter', 'latex','FontSize', 22);
			ylabel('Avg. angle','Interpreter', 'latex', 'FontSize', 40);xlabel('time','Interpreter', 'latex', 'FontSize', 40);
			ylim([0 1.7]); xlim([0 180]);
			SavePlot(obj, h, sprintf('AvgAngle'));

			h = figure;
			l=1; % The component of the cell length made up of the preferred separation
			plot(obj.result.timeSteps,L+l, 'LineWidth', 4);
			ax = gca;
			ax.FontSize = 16;
			% title('Average length over time','Interpreter', 'latex','FontSize', 22);
			ylabel('Avg. length','Interpreter', 'latex', 'FontSize', 40);xlabel('time','Interpreter', 'latex', 'FontSize', 40);
			ylim([0.4*obj.l 1.1*obj.l]); xlim([0 180]);
			SavePlot(obj, h, sprintf('AvgLength'));

			tFontSize = 40;
			lFontSize = 20;
			aFontSize = 24;

			idx0 = 1;
			idx1 = 600;
			idx2 = 900;
			idx3 = 1380;

			xmin = -85;
			xmax = 85;
			ymin = -obj.w/2-2.5;
			ymax = obj.w/2+2.5;
			h = figure;
			set(h, 'InvertHardcopy', 'off');
			set(h,'color','w');
			h0 = subplot(4,1,1);xlim([xmin,xmax]);ylim([ymin,ymax]);ylabel(['t= ', num2str(0)],'Interpreter', 'latex', 'FontSize', lFontSize);set(gca,'Color','k');
			h1 = subplot(4,1,2);xlim([xmin,xmax]);ylim([ymin,ymax]);ylabel(['t= ', num2str(idx1/10)],'Interpreter', 'latex', 'FontSize', lFontSize);set(gca,'Color','k');
			h2 = subplot(4,1,3);xlim([xmin,xmax]);ylim([ymin,ymax]);ylabel(['t= ', num2str(idx2/10)],'Interpreter', 'latex', 'FontSize', lFontSize);set(gca,'Color','k');
			h3 = subplot(4,1,4);xlim([xmin,xmax]);ylim([ymin,ymax]);ylabel(['t= ', num2str(idx3/10)],'Interpreter', 'latex', 'FontSize', lFontSize);set(gca,'Color','k');
			

			r = 0.4; % The radius of the rod end caps
			obj.result.PlotRodTimeStep(r, idx0);
			copyobj(allchild(gca),h0);

			obj.result.PlotRodTimeStep(r, idx1);
			copyobj(allchild(gca),h1);
			
			obj.result.PlotRodTimeStep(r, idx2);
			copyobj(allchild(gca),h2);
			
			obj.result.PlotRodTimeStep(r, idx3);
			copyobj(allchild(gca),h3);

			
			

			SavePlot(obj, figure(4), sprintf('TimeSnapShots'));


		end

	end

end