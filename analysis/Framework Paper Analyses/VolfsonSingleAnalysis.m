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

			v = Visualiser(sprintf('%s/n%gl%gr%gs%gtg%gw%gf%gt00da0ds1dl1a0_seed%g',obj.simulationDriverName,obj.n,obj.l,obj.r,obj.s,obj.tg,obj.w,obj.f,obj.seed));


			A = [];
			Q = [];
			L = [];
			N = [];
			lengths = [];

			xlim([0 1.6]);
			ylim([0  0.5]);
			[I,~] = size(v.cells);

			for i = 1:I
				% i is the time steps
				[~,J] = size(v.cells);
				j = 1;
				angles = [];
				while j <= J && ~isempty(v.cells{i,j})

					c = v.cells{i,j};
					ids = c(1:end-1);
					colour = c(end);
					nodeCoords = squeeze(v.nodes(ids,i,:));

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
				N(end + 1) = j-1;


			end

			t = v.timeSteps;
			obj.result = {Q, A, L, N, t};

		end

		function PlotData(obj)

			

			l = 1; % The extra amount added to the length of the edge to bring it up to the length of the cell

			Q = obj.result{1};
			A = obj.result{2};
			L = obj.result{3} + l;
			N = obj.result{4};
			t = obj.result{5};

			
			h = figure;
			plot(t,Q, 'LineWidth', 4);
			ax = gca;
			ax.FontSize = 16;
			% title('Disorder factor Q over time','Interpreter', 'latex','FontSize', 22);
			ylabel('Q','Interpreter', 'latex', 'FontSize', 40);xlabel('Time (min)','Interpreter', 'latex', 'FontSize', 40);
			ylim([0 1.1]);; xlim([0 max(t)]);
			SavePlot(obj, h, sprintf('QFactor'));
			
			h = figure;
			plot(t,A, 'LineWidth', 4);
			ax = gca;
			ax.FontSize = 16;
			ylabel('Avg. angle','Interpreter', 'latex', 'FontSize', 40);xlabel('Time (min)','Interpreter', 'latex', 'FontSize', 40);
			ylim([0 1.7]); xlim([0 max(t)]);
			SavePlot(obj, h, sprintf('AvgAngle'));

			h = figure;
			plot(t,N, 'LineWidth', 4);
			ax = gca;
			ax.FontSize = 16;
			ylabel('Cell Count','Interpreter', 'latex', 'FontSize', 40);xlabel('Time (min)','Interpreter', 'latex', 'FontSize', 40);
			ylim([0 1.05*max(N)]); xlim([0 max(t)]);
			SavePlot(obj, h, sprintf('CellCount'));

			h = figure;
			l=1; % The component of the cell length made up of the preferred separation
			plot(t,L, 'LineWidth', 4);
			ax = gca;
			ax.FontSize = 16;
			ylabel('Avg. length','Interpreter', 'latex', 'FontSize', 40);xlabel('Time (min)','Interpreter', 'latex', 'FontSize', 40);
			ylim([2 5]); xlim([0 max(t)]);
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
			h0 = subplot(4,1,1);xlim([xmin,xmax]);ylim([ymin,ymax]);ylabel(['t= ', num2str(0), ' min'],'Interpreter', 'latex', 'FontSize', lFontSize);set(gca,'Color','k');
			h1 = subplot(4,1,2);xlim([xmin,xmax]);ylim([ymin,ymax]);ylabel(['t= ', num2str(idx1/10)],'Interpreter', 'latex', 'FontSize', lFontSize);set(gca,'Color','k');
			h2 = subplot(4,1,3);xlim([xmin,xmax]);ylim([ymin,ymax]);ylabel(['t= ', num2str(idx2/10)],'Interpreter', 'latex', 'FontSize', lFontSize);set(gca,'Color','k');
			h3 = subplot(4,1,4);xlim([xmin,xmax]);ylim([ymin,ymax]);ylabel(['t= ', num2str(idx3/10)],'Interpreter', 'latex', 'FontSize', lFontSize);set(gca,'Color','k');xlabel('Position ($\mu$m)','Interpreter', 'latex', 'FontSize', lFontSize);
			


			v = Visualiser(sprintf('%s/n%gl%gr%gs%gtg%gw%gf%gt00da0ds1dl1a0_seed%g',obj.simulationDriverName,obj.n,obj.l,obj.r,obj.s,obj.tg,obj.w,obj.f,obj.seed));

			r = 0.4; % The radius of the rod end caps
			v.PlotRodTimeStep(r, idx0);
			copyobj(allchild(gca),h0);

			v.PlotRodTimeStep(r, idx1);
			copyobj(allchild(gca),h1);
			
			v.PlotRodTimeStep(r, idx2);
			copyobj(allchild(gca),h2);
			
			v.PlotRodTimeStep(r, idx3);
			copyobj(allchild(gca),h3);

			set(h,'Units','Inches');
			h.Position = [6.1 4.0 7.8 7.1];

			SavePlot(obj, h, sprintf('TimeSnapShots'));


			r = 0.4; % The radius of the rod end caps
			v.PlotRodAngles(r, idx0);
			copyobj(allchild(gca),h0);

			v.PlotRodAngles(r, idx1);
			copyobj(allchild(gca),h1);
			
			v.PlotRodAngles(r, idx2);
			copyobj(allchild(gca),h2);
			
			v.PlotRodAngles(r, idx3);
			copyobj(allchild(gca),h3);

			set(h,'Units','Inches');
			h.Position = [6.1 4.0 7.8 7.1];

			SavePlot(obj, h, sprintf('AngleSnapShots'));


		end

	end

end