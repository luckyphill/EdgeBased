classdef Visualiser < matlab.mixin.SetGet
	% Stores the wiggle ratio

	properties

		pathToSpatialState
		pathToOutput
		nodes
		elements
		cells

		timeSteps

		cs = ColourSet()
		
	end

	methods

		function obj = Visualiser(v)

			% v can be either of two types:
			% a string that gives the subdirectory structure from
			% the folder SimulationOutput to the folder SpatialState for the desired simulation
			% i.e. [path]/[to]/SimulatioOutput/[v]/SpatialState
			% OR
			% the simulation object handle

			if isa(v, 'AbstractCellSimulation')
				
				obj.pathToSpatialState = v.dataWriters(1).fullPath;
				rootDir = v.dataWriters(1).rootStorageLocation;

				subDir = erase(obj.pathToSpatialState, rootDir);
				subDir = subDir(1:end-13); % remove SpatialState/ from subDir

				obj.pathToOutput = [getenv('EDGEDIR'),'/Images/',subDir];


			else

				% If the input is not a simulation object, then assume its a string

				if ~strcmp(v(end),'/')
					v(end+1) = '/';
				end

				v = [v, 'SpatialState/'];

				obj.pathToSpatialState = [getenv('EDGEDIR'),'/SimulationOutput/',v];

				obj.pathToOutput = [getenv('EDGEDIR'),'/Images/',v];

				if ~strcmp( obj.pathToOutput(end),'/' )
					obj.pathToOutput(end+1) = '/';
				end

			end

			if exist(obj.pathToOutput,'dir')~=7
				mkdir(obj.pathToOutput);
			end



			obj.LoadData();

		end

		function LoadData(obj)

			% For some reason matlab decides to ignore some lines
			% when using readmatrix, so to stop this, we need to pass in special options
			% See https://stackoverflow.com/questions/62399666/why-does-readmatrix-in-matlab-skip-the-first-n-lines?
			
			% Despite this, readmatrix is still valuable because when it feeds the file
			% into a matrix, any empty entries are filled with nans. On the other hand
			% dlmread, or csvread fill empty entries with zeros, which unfortunately are
			% also valid spatial positions, so it is difficult to reliably distinguish
			% empty values from valid zeros. To throw a complete spanner in the works
			% readmatrix can't handle exceptionally large data files (above something like
			% 100MB or 200MB), so we have to revert to dlmread in this case and just accept
			% that in certain cases cells will disappear in the visualisation because one of their
			% coordinates gets convereted to nan. Fortunately, this should be a fleeting
			% extraordinarily rare event in general. It will however be be common if
			% boundary conditions are set on the x or y axes

			opts = detectImportOptions([obj.pathToSpatialState, 'nodes.csv']);
			opts.DataLines = [1 Inf];
			if strcmp(opts.VariableTypes{1}, 'char')
				opts = setvartype(opts, opts.VariableNames{1}, 'double');
			end
			% nodeData = readmatrix([obj.pathToSpatialState, 'nodes.csv'],opts);
			nodeData = dlmread([obj.pathToSpatialState, 'nodes.csv']);
			nodeData(nodeData == 0) = nan;

			opts = detectImportOptions([obj.pathToSpatialState, 'elements.csv']);
			opts.DataLines = [1 Inf];
			if strcmp(opts.VariableTypes{1}, 'char')
				opts = setvartype(opts, opts.VariableNames{1}, 'double');
			end
			elementData = readmatrix([obj.pathToSpatialState, 'elements.csv'],opts);

			opts = detectImportOptions([obj.pathToSpatialState, 'cells.csv']);
			opts.DataLines = [1 Inf];
			if strcmp(opts.VariableTypes{1}, 'char')
				opts = setvartype(opts, opts.VariableNames{1}, 'double');
			end
			cellData = readmatrix([obj.pathToSpatialState, 'cells.csv'],opts);
			% cellData = csvread([obj.pathToSpatialState, 'cells.csv']);

			obj.timeSteps = nodeData(:,1);
			nodeData = nodeData(:,2:end);
			elementData = elementData(:,2:end);
			cellData = cellData(:,2:end);

			[m,~] = size(nodeData);

			% Need to get the max ID
			allIDS = nodeData(:,1:3:end);
			maxID = max(max(allIDS));

			nodes = nan(maxID,m,2);

			for i = 1:m
				nD  = nodeData(i,:);
				nD = reshape(nD,3,[])';
				% First column is ID, then x and y
				
				% For each node, use the id as the first index,
				% and the second index is the time step. In that
				% position is stored the (x,y) coords
				[mnD, ~] = size(nD);

				for j = 1:mnD
					n = nD(j,:);
					if ~isnan(n(1))
						nodes(n(1),i,:) = [n(2), n(3)];
					end

				end

			end

			% This 3D array gives the (x,y) position of each node at each point in time
			% First dimension, id, second dimension, time, third dimension position data
			obj.nodes = nodes;

			% Now make an array the cells and elements
			% First dimension, time, second dimension, cell or element, third dimension, node id
			% so to get the nodes for a given time,t, and a given cell, c, it's accessed
			% cellData(t,c,:)
			obj.elements = permute(reshape(elementData,m,2,[]),[1,3,2]);
			% obj.cells = permute(reshape(cellData,m,obj.nEntriesCell,[]),[1,3,2]);
			
			
			% Each row in the matrix lists the nodes for each cell. The first number is the number
			% of nodes in the cell, call it jump, then the nodes for the cell are listed, followed by
			% the cell colour
			[m,~] = size(cellData);
			cells = {};
			for i = 1:m
				a = cellData(i,:);
				j = 1;
				counter = 1;
				while j <= length(a) && ~isnan(a(j))
					jump = a(j);
					cells{i,counter} = a(j+1:j+jump+1);
					j = j + jump + 2;
					counter = counter + 1;
				end

			end

			obj.cells = cells;

		end


		% Really need to abstract this so the code isn't copied over and over
		function VisualiseCells(obj, varargin)

			% varargin 
			% Arg 1: [indexStart, indexEnd] - a vector of the start and ending indices. Leave empty to run the whole simulation
			% Arg 2: plot axis range in the form [xmin,xmax,ymin,ymax]

			xyrange = [];
			indices = [];
			if ~isempty(varargin)
				indices = varargin{1};
				if length(varargin) > 1
					xyrange = varargin{2};
				end
			end

			h = figure();
			axis equal
			hold on

			if ~isempty(xyrange)
				xlim(xyrange(1:2));
				ylim(xyrange(3:4));
			end

			[I,~] = size(obj.cells);


			% Initialise the array with anything
			fillObjects(1) = fill([1,1],[2,2],'r');

			startI =  1;
			endI = I;
			if ~isempty(indices)
				startI = indices(1);
				endI = indices(2);
			end

			for i = startI:endI
				% i is the time steps
				[~,J] = size(obj.cells);
				j = 1;
				while j <= J && ~isempty(obj.cells{i,j})

					c = obj.cells{i,j};
					ids = c(1:end-1);
					colour = c(end);
					nodeCoords = squeeze(obj.nodes(ids,i,:));

					x = nodeCoords(:,1);
					y = nodeCoords(:,2);

					if j > length(fillObjects)
						fillObjects(j) = fill(x,y,obj.cs.GetRGB(colour));
					else
						fillObjects(j).XData = x;
						fillObjects(j).YData = y;
						fillObjects(j).FaceColor = obj.cs.GetRGB(colour);
					end

					j = j + 1;

				end
				% j will always end up being 1 more than the total number of non empty cells

				for k = length(fillObjects):-1:j
					fillObjects(k).delete;
					fillObjects(k) = [];
				end

				drawnow
				title(sprintf('t = %g',obj.timeSteps(i)),'Interpreter', 'latex');
				pause(0.1);

			end

		end

		function ProduceMovie(obj, varargin)

			% varargin 
			% Arg 1: [indexStart, indexEnd] - a vector of the start and ending indices
			% Arg 2: plot axis range in the form [xmin,xmax,ymin,ymax]
			
			xyrange = [];
			indices = [];
			videoFormat = 'MPEG-4';
			if ~isempty(varargin)
				indices = varargin{1};
				if length(varargin) > 1
					xyrange = varargin{2};
					if length(varargin) > 2
						videoFormat = varargin{3};
					end
				end
			end



			% Currently same as run visualiser, but saves the movie

			h = figure();
			axis equal
			axis off
			hold on

			F = getframe(h);
			
			if ~isempty(xyrange)
				xlim(xyrange(1:2));
				ylim(xyrange(3:4));
			end

			if ~isempty(indices)
				tIdxStart = indices(1);
				tIdxEnd = indices(2);
			else
				tIdxStart = 1;
				tIdxEnd = length(obj.timeSteps);
			end

			% Initialise the array with anything
			fillObjects(1) = fill([1,1],[2,2],.5);

			for i = tIdxStart:tIdxEnd
				% i is the time steps
				[~,J] = size(obj.cells);
				j = 1;
				while j <= J && ~isempty(obj.cells{i,j})

					c = obj.cells{i,j};
					ids = c(1:end-1);
					colour = c(end);
					nodeCoords = squeeze(obj.nodes(ids,i,:));

					x = nodeCoords(:,1);
					y = nodeCoords(:,2);
					A = polyarea(x,y);
				
					if j > length(fillObjects)
						fillObjects(j) = fill(x,y,obj.cs.GetRGB(colour));
					else
						fillObjects(j).XData = x;
						fillObjects(j).YData = y;
						fillObjects(j).FaceColor = obj.cs.GetRGB(colour);
					end

					j = j + 1;

				end
				% j will always end up being 1 more than the total number of non empty cells

				for k = length(fillObjects):-1:j
					fillObjects(k).delete;
					fillObjects(k) = [];
				end

				drawnow

				title(sprintf('t = %g',obj.timeSteps(i)),'Interpreter', 'latex');
				F(end+1) = getframe(h);

			end

			fileName = [obj.pathToOutput,'animation'];

			if ~isempty(indices)
				ts = obj.timeSteps(tIdxStart);
				if tIdxStart == 1
					ts = 0; % A little hack to make the numbers look nice, technically its lying
				end
				te = obj.timeSteps(tIdxEnd);
				fileName = sprintf('%s_%gto%g',fileName, ts, te );
			else
				fileName = sprintf('%s_Full',fileName);
			end

			writerObj = VideoWriter(fileName,videoFormat);
			writerObj.FrameRate = 10;

			% open the video writer
			open(writerObj);
			% write the frames to the video
			for i=2:length(F)
				% convert the image to a frame
				frame = F(i) ;    
				writeVideo(writerObj, frame);
			end
			% close the writer object
			close(writerObj);

		end

		function PlotTimeStep(obj, timeStep, varargin)

			% Plots a single given timestep
			% the number timeStep must be an integer matching the row number of the
			% saved data. Usually this will be 10xt but not always

			% varargin has inputs
			% 1: plot axis range in the form [xmin,xmax,ymin,ymax]
			% 2: plot title. can include latex

			% if you want to ignore a particular input, use []

			xyrange = [];
			plotTitle = '';

			if ~isempty(varargin)
				xyrange = varargin{1};
				if length(varargin)>1
					plotTitle = varargin{2};
				end
			end

			h = figure();
			axis equal
			hold on

			i = timeStep;


			% Initialise the array with anything
			fillObjects(1) = fill([1,1],[2,2],'r');


			[~,J] = size(obj.cells);
			j = 1;
			while j <= J && ~isempty(obj.cells{i,j})

				c = obj.cells{i,j};
				ids = c(1:end-1);
				colour = c(end);
				nodeCoords = squeeze(obj.nodes(ids,i,:));

				x = nodeCoords(:,1);
				y = nodeCoords(:,2);
				
				fillObjects(j) = fill(x,y,obj.cs.GetRGB(colour));


				j = j + 1;

			end

			if ~isempty(xyrange)
				xlim(xyrange(1:2));
				ylim(xyrange(3:4));
			end
			
			% j will always end up being 1 more than the total number of non empty cells
			axis off
			drawnow
			if ~isempty(plotTitle)
				title(plotTitle,'Interpreter', 'latex', 'FontSize', 34);
			else
				title(sprintf('t = %g',obj.timeSteps(i)),'Interpreter', 'latex', 'FontSize', 34);
			end

			set(h,'Units','Inches');
			pos = get(h,'Position');
			set(h,'PaperPositionMode','Auto','PaperUnits','Inches','PaperSize',[pos(3), pos(4)]);
			
			fileName = sprintf('ImageAtTime_%g',obj.timeSteps(timeStep));
			fileName = strrep(fileName,'.','_'); % If any time has decimals, change the point to underscore
			fileName = sprintf('%s%s', obj.pathToOutput, fileName);
			print(fileName,'-dpdf')

		end

		function VisualiseRods(obj, r, varargin)

			% varargin 
			% Arg 1: [indexStart, indexEnd] - a vector of the start and ending indices. Leave empty to run the whole simulation
			% Arg 2: plot axis range in the form [xmin,xmax,ymin,ymax]

			xyrange = [];
			indices = [];
			if ~isempty(varargin)
				indices = varargin{1};
				if length(varargin) > 1
					xyrange = varargin{2};
				end
			end

			h = figure();
			set(gca,'Color','k');
			axis equal
			hold on

			if ~isempty(xyrange)
				xlim(xyrange(1:2));
				ylim(xyrange(3:4));
			end

			[I,~] = size(obj.cells);


			% Initialise the array with anything
			patchObjects(1) = patch([1,1],[2,2],obj.cs.GetRGB(6), 'LineWidth', 0.5);

			startI =  1;
			endI = I;
			if ~isempty(indices)
				startI = indices(1);
				endI = indices(2);
			end

			for i = startI:I
				% i is the time steps
				[~,J] = size(obj.cells);
				j = 1;
				while j <= J && ~isempty(obj.cells{i,j})

					c = obj.cells{i,j};
					ids = c(1:end-1);
					colour = c(end);
					nodeCoords = squeeze(obj.nodes(ids,i,:));

					a = nodeCoords(1,:);
					b = nodeCoords(2,:);

					if j > length(patchObjects)
						[pillX,pillY] = obj.DrawPill(a,b,r);
						patchObjects(j) = patch(pillX,pillY,obj.cs.GetRGB(colour), 'LineWidth', .5);
					else
						[pillX,pillY] = obj.DrawPill(a,b,r);
						patchObjects(j).XData = pillX;
						patchObjects(j).YData = pillY;
						patchObjects(j).FaceColor = obj.cs.GetRGB(colour);
					end

					j = j + 1;

				end
				% j will always end up being 1 more than the total number of non empty cells

				for k = length(patchObjects):-1:j
					patchObjects(k).delete;
					patchObjects(k) = [];
				end

				drawnow
				title(sprintf('t = %g',obj.timeSteps(i)),'Interpreter', 'latex');
				pause(0.1);

			end

		end

		function ProduceRodMovie(obj, r, varargin)


			% varargin 
			% Arg 1: [indexStart, indexEnd] - a vector of the start and ending indices
			% Arg 2: plot axis range in the form [xmin,xmax,ymin,ymax]

			xyrange = [];
			indices = [];
			videoFormat = 'MPEG-4';
			if ~isempty(varargin)
				indices = varargin{1};
				if length(varargin) > 1
					xyrange = varargin{2};
					if length(varargin) > 2
						videoFormat = varargin{3};
					end
				end
			end

			% Currently same as run visualiser, but saves the movie

			h = figure();
			axis equal
			% axis off
			hold on
			set(h, 'InvertHardcopy', 'off')
			set(h,'color','w');
			set(gca,'Color','k');

			if ~isempty(xyrange)
				xlim(xyrange(1:2));
				ylim(xyrange(3:4));
			end

			if ~isempty(indices)
				tIdxStart = indices(1);
				tIdxEnd = indices(2);
			else
				tIdxStart = 1;
				tIdxEnd = length(obj.timeSteps);
			end

			F = getframe(gca); % Initialise the array

			% Initialise the array with anything
			patchObjects(1) = patch([1,1],[2,2],obj.cs.GetRGB(6), 'LineWidth', 0.5);

			for i = tIdxStart:tIdxEnd
				% i is the time steps
				[~,J] = size(obj.cells);
				j = 1;
				while j <= J && ~isempty(obj.cells{i,j})

					c = obj.cells{i,j};
					ids = c(1:end-1);
					colour = c(end);
					nodeCoords = squeeze(obj.nodes(ids,i,:));

					a = nodeCoords(1,:);
					b = nodeCoords(2,:);

					if j > length(patchObjects)
						[pillX,pillY] = obj.DrawPill(a,b,r);
						patchObjects(j) = patch(pillX,pillY,obj.cs.GetRGB(colour), 'LineWidth', 0.5);
					else
						[pillX,pillY] = obj.DrawPill(a,b,r);
						patchObjects(j).XData = pillX;
						patchObjects(j).YData = pillY;
						patchObjects(j).FaceColor = obj.cs.GetRGB(colour);
					end

					j = j + 1;

				end
				% j will always end up being 1 more than the total number of non empty cells

				for k = length(patchObjects):-1:j
					patchObjects(k).delete;
					patchObjects(k) = [];
				end

				drawnow

				title(sprintf('t = %g',obj.timeSteps(i)),'Interpreter', 'latex');
				F(end+1) = getframe(gca);

			end

			fileName = [obj.pathToOutput,'animation'];

			if ~isempty(indices)
				ts = obj.timeSteps(tIdxStart);
				if tIdxStart == 1
					ts = 0; % A little hack to make the numbers look nice, technically its lying
				end
				te = obj.timeSteps(tIdxEnd);
				fileName = sprintf('%s_%gto%g',fileName, ts, te );
			else
				fileName = sprintf('%s_Full',fileName);
			end

			writerObj = VideoWriter(fileName,videoFormat);
			writerObj.FrameRate = 10;

			% open the video writer
			open(writerObj);
			% write the frames to the video
			for i=2:length(F)
				% convert the image to a frame
				frame = F(i) ;    
				writeVideo(writerObj, frame);
			end
			% close the writer object
			close(writerObj);

		end

		function ProduceRodAngleMovie(obj, r, varargin)


			% varargin 
			% Arg 1: [indexStart, indexEnd] - a vector of the start and ending indices
			% Arg 2: plot axis range in the form [xmin,xmax,ymin,ymax]

			xyrange = [];
			indices = [];
			videoFormat = 'MPEG-4';
			if ~isempty(varargin)
				indices = varargin{1};
				if length(varargin) > 1
					xyrange = varargin{2};
					if length(varargin) > 2
						videoFormat = varargin{3};
					end
				end
			end

			lineWidth = 0.5;

			% Currently same as run visualiser, but saves the movie

			h = figure();
			axis equal
			% axis off
			hold on
			set(h, 'InvertHardcopy', 'off')
			set(h,'color','w');
			set(gca,'Color','k');

			if ~isempty(xyrange)
				xlim(xyrange(1:2));
				ylim(xyrange(3:4));
			end

			if ~isempty(indices)
				tIdxStart = indices(1);
				tIdxEnd = indices(2);
			else
				tIdxStart = 1;
				tIdxEnd = length(obj.timeSteps);
			end

			F = getframe(gca); % Initialise the array

			% Initialise the array with anything
			patchObjects(1) = patch([1,1],[2,2],obj.cs.GetRGB(6), 'LineWidth', lineWidth);

			for i = tIdxStart:tIdxEnd
				% i is the time steps
				[~,J] = size(obj.cells);
				j = 1;
				while j <= J && ~isempty(obj.cells{i,j})

					c = obj.cells{i,j};
					ids = c(1:end-1);
					colour = c(end);
					nodeCoords = squeeze(obj.nodes(ids,i,:));

					a = nodeCoords(1,:);
					b = nodeCoords(2,:);

					x = nodeCoords(:,1);
					y = nodeCoords(:,2);

					angColour = 2 * abs( atan( (x(1)-x(2)) / (y(1)-y(2))) ) / pi;

					[pillX,pillY] = obj.DrawPill(a,b,r);
					

					if j > length(patchObjects)
						patchObjects(j) = patch(pillX, pillY, angColour, 'LineWidth', lineWidth);
					else
						patchObjects(j).XData = pillX;
						patchObjects(j).YData = pillY;
						patchObjects(j).FaceVertexCData = angColour;
					end

					j = j + 1;

				end
				% j will always end up being 1 more than the total number of non empty cells

				for k = length(patchObjects):-1:j
					patchObjects(k).delete;
					patchObjects(k) = [];
				end

				drawnow

				title(sprintf('t = %g',obj.timeSteps(i)),'Interpreter', 'latex');
				F(end+1) = getframe(gca);

			end

			fileName = [obj.pathToOutput,'animation_angle'];

			if ~isempty(indices)
				ts = obj.timeSteps(tIdxStart);
				if tIdxStart == 1
					ts = 0; % A little hack to make the numbers look nice, technically its lying
				end
				te = obj.timeSteps(tIdxEnd);
				fileName = sprintf('%s_%gto%g',fileName, ts, te );
			else
				fileName = sprintf('%s_Full',fileName);
			end

			writerObj = VideoWriter(fileName,videoFormat);
			writerObj.FrameRate = 10;

			% open the video writer
			open(writerObj);
			% write the frames to the video
			for i=2:length(F)
				% convert the image to a frame
				frame = F(i) ;    
				writeVideo(writerObj, frame);
			end
			% close the writer object
			close(writerObj);

		end

		function PlotRodTimeStep(obj, r, timeStep)

			% Plots a single given timestep

			h = figure();
			axis equal
			hold on
			set(h, 'InvertHardcopy', 'off')
			set(h,'color','w');
			set(gca,'Color','k');

			i = timeStep;

			lineWidth = 0.5;
			% Initialise the array with anything
			patchObjects(1) = patch([1,1],[2,2],obj.cs.GetRGB(6), 'LineWidth', lineWidth);


			[~,J] = size(obj.cells);
			j = 1;
			while j <= J && ~isempty(obj.cells{i,j})

				c = obj.cells{i,j};
				ids = c(1:end-1);
				colour = c(end);
				nodeCoords = squeeze(obj.nodes(ids,i,:));

				a = nodeCoords(1,:);
				b = nodeCoords(2,:);

				[pillX,pillY] = obj.DrawPill(a,b,r);
				patchObjects(j) = patch(pillX,pillY,obj.cs.GetRGB(colour), 'LineWidth', lineWidth);

				j = j + 1;

			end
				% j will always end up being 1 more than the total number of non empty cells
			% axis off
			drawnow
			title(sprintf('t = %g',obj.timeSteps(i)),'Interpreter', 'latex');


			set(h,'Units','Inches');
			pos = get(h,'Position');
			set(h,'PaperPositionMode','Auto','PaperUnits','Inches','PaperSize',[pos(3), pos(4)]);
			

			fileName = sprintf('ImageAtTime_%g',obj.timeSteps(timeStep));
			fileName = strrep(fileName,'.','_'); % If any time has decimals, change the point to underscore
			fileName = sprintf('%s%s', obj.pathToOutput, fileName);
			print(fileName,'-dpdf')

		end

		function PlotRodAngles(obj, r, timeStep)

			% Plots a single given timestep

			h = figure();
			axis equal
			hold on
			set(gca,'Color','k');
			set(h, 'InvertHardcopy', 'off')
			set(h,'color','w');

			i = timeStep;

			lineWidth = 0.5;
			% Initialise the array with anything
			patchObjects(1) = patch([1,1],[2,2],obj.cs.GetRGB(6), 'LineWidth', lineWidth);


			[~,J] = size(obj.cells);
			j = 1;
			while j <= J && ~isempty(obj.cells{i,j})

				c = obj.cells{i,j};
				ids = c(1:end-1);
				colour = c(end);
				nodeCoords = squeeze(obj.nodes(ids,i,:));

				a = nodeCoords(1,:);
				b = nodeCoords(2,:);

				x = nodeCoords(:,1);
				y = nodeCoords(:,2);

				angColour = 2 * abs( atan( (x(1)-x(2)) / (y(1)-y(2))) ) / pi;

				[pillX,pillY] = obj.DrawPill(a,b,r);
				patchObjects(j) = patch(pillX,pillY,angColour, 'LineWidth', lineWidth);

				j = j + 1;

			end
				% j will always end up being 1 more than the total number of non empty cells
			% axis off
			drawnow
			title(sprintf('t = %g',obj.timeSteps(i)),'Interpreter', 'latex');


			set(h,'Units','Inches');
			pos = get(h,'Position');
			set(h,'PaperPositionMode','Auto','PaperUnits','Inches','PaperSize',[pos(3), pos(4)]);
			

			fileName = sprintf('AnglesAtTime_%g',obj.timeSteps(timeStep));
			fileName = strrep(fileName,'.','_'); % If any time has decimals, change the point to underscore
			fileName = sprintf('%s%s', obj.pathToOutput, fileName);
			print(fileName,'-dpdf')

		end

		function VisualiseNodesAndEdges(obj, r, varargin)

			% r is the radius of the node
			% varargin 
			% Arg 1: [indexStart, indexEnd] - a vector of the start and ending indices. Leave empty to run the whole simulation
			% Arg 2: plot axis range in the form [xmin,xmax,ymin,ymax]

			xyrange = [];
			indices = [];
			if ~isempty(varargin)
				indices = varargin{1};
				if length(varargin) > 1
					xyrange = varargin{2};
				end
			end

			h = figure();
			axis equal
			hold on

			if ~isempty(xyrange)
				xlim(xyrange(1:2));
				ylim(xyrange(3:4));
			end

			[I,~] = size(obj.cells);


			% Initialise the array with anything
			patchObjects(1) = patch([1,1],[2,2],obj.cs.GetRGB(6), 'LineWidth', 0.5);
			lineObjects(1)  = line([1,1],[2,2],'Color', 'k', 'LineWidth', 4);

			startI =  1;
			endI = I;
			if ~isempty(indices)
				startI = indices(1);
				endI = indices(2);
			end

			for i = startI:endI
				
				% First draw node cells

				[~,J] = size(obj.cells);
				j = 1; % loops node cells
				jN = 0; % tracks the number of node cells
				jM = 0; % tracks the number of membrane 'cells'
				while j <= J && ~isempty(obj.cells{i,j})

					c = obj.cells{i,j};
					ids = c(1:end-1);
					colour = c(end);

					% This should only for the node cells
					if length(ids) < 2
						jN = jN + 1;
						a = squeeze(obj.nodes(ids,i,:))';

						if jN > length(patchObjects)
							[pillX,pillY] = obj.DrawPill(a,a,r);
							patchObjects(jN) = patch(pillX,pillY,obj.cs.GetRGB(colour), 'LineWidth', .5);
						else
							[pillX,pillY] = obj.DrawPill(a,a,r);
							patchObjects(jN).XData = pillX;
							patchObjects(jN).YData = pillY;
							patchObjects(jN).FaceColor = obj.cs.GetRGB(colour);
						end

					else

						% Doesn't quite work for closed loops
						% so need a little hack for now
						jM = jM + 1;

						nodeCoords = squeeze(obj.nodes(ids,i,:));
						x = nodeCoords(:,1);
						y = nodeCoords(:,2);

						x(end+1) = x(1);
						y(end+1) = y(1);

						if jM > length(lineObjects)
							lineObjects(jM) = line(x,y, 'Color', 'k', 'LineWidth', 4);
						else
							lineObjects(jM).XData = x;
							lineObjects(jM).YData = y;
						end

					end


					j = j + 1;

				end
				% j will always end up being 1 more than the total number of non empty cells

				for k = length(patchObjects):-1:jN+1
					patchObjects(k).delete;
					patchObjects(k) = [];
				end

				for k = length(lineObjects):-1:jM+1
					lineObjects(k).delete;
					lineObjects(k) = [];
				end

				drawnow
				title(sprintf('t = %g',obj.timeSteps(i)),'Interpreter', 'latex');
				pause(0.1);

			end

		end

		function ProduceNodesAndEdgesMovie(obj, r, varargin)


			% varargin 
			% Arg 1: [indexStart, indexEnd] - a vector of the start and ending indices
			% Arg 2: plot axis range in the form [xmin,xmax,ymin,ymax]

			xyrange = [];
			indices = [];
			videoFormat = 'MPEG-4';
			if ~isempty(varargin)
				indices = varargin{1};
				if length(varargin) > 1
					xyrange = varargin{2};
					if length(varargin) > 2
						videoFormat = varargin{3};
					end
				end
			end

			% Currently same as run visualiser, but saves the movie

			h = figure();
			axis equal
			axis off
			hold on

			if ~isempty(xyrange)
				xlim(xyrange(1:2));
				ylim(xyrange(3:4));
			end

			if ~isempty(indices)
				startI = indices(1);
				endI = indices(2);
			else
				startI = 1;
				endI = length(obj.timeSteps);
			end

			F = getframe(gca); % Initialise the array

			% Initialise the array with anything
			patchObjects(1) = patch([1,1],[2,2],obj.cs.GetRGB(6), 'LineWidth', 0.5);
			lineObjects(1)  = line([1,1],[2,2],'Color', 'k', 'LineWidth', 4);


			for i = startI:endI
				
				% First draw node cells

				[~,J] = size(obj.cells);
				j = 1; % loops node cells
				jN = 0; % tracks the number of node cells
				jM = 0; % tracks the number of membrane 'cells'
				while j <= J && ~isempty(obj.cells{i,j})

					c = obj.cells{i,j};
					ids = c(1:end-1);
					colour = c(end);

					% This should only for the node cells
					if length(ids) < 2
						jN = jN + 1;
						a = squeeze(obj.nodes(ids,i,:))';

						if jN > length(patchObjects)
							[pillX,pillY] = obj.DrawPill(a,a,r);
							patchObjects(jN) = patch(pillX,pillY,obj.cs.GetRGB(colour), 'LineWidth', .5);
						else
							[pillX,pillY] = obj.DrawPill(a,a,r);
							patchObjects(jN).XData = pillX;
							patchObjects(jN).YData = pillY;
							patchObjects(jN).FaceColor = obj.cs.GetRGB(colour);
						end

					else

						% Doesn't quite work for closed loops
						% so need a little hack for now
						jM = jM + 1;

						nodeCoords = squeeze(obj.nodes(ids,i,:));
						x = nodeCoords(:,1);
						y = nodeCoords(:,2);

						x(end+1) = x(1);
						y(end+1) = y(1);

						if jM > length(lineObjects)
							lineObjects(jM) = line(x,y, 'Color', 'k', 'LineWidth', 4);
						else
							lineObjects(jM).XData = x;
							lineObjects(jM).YData = y;
						end

					end


					j = j + 1;

				end
				% j will always end up being 1 more than the total number of non empty cells

				for k = length(patchObjects):-1:jN+1
					patchObjects(k).delete;
					patchObjects(k) = [];
				end

				for k = length(lineObjects):-1:jM+1
					lineObjects(k).delete;
					lineObjects(k) = [];
				end

				drawnow
				title(sprintf('t = %g',obj.timeSteps(i)),'Interpreter', 'latex');
				F(end+1) = getframe(gca);

			end


			fileName = [obj.pathToOutput,'animation'];

			if ~isempty(indices)
				ts = obj.timeSteps(tIdxStart);
				if tIdxStart == 1
					ts = 0; % A little hack to make the numbers look nice, technically its lying
				end
				te = obj.timeSteps(tIdxEnd);
				fileName = sprintf('%s_%gto%g',fileName, ts, te );
			else
				fileName = sprintf('%s_Full',fileName);
			end

			writerObj = VideoWriter(fileName,videoFormat);
			writerObj.FrameRate = 10;

			% open the video writer
			open(writerObj);
			% write the frames to the video
			for i=2:length(F)
				% convert the image to a frame
				frame = F(i) ;    
				writeVideo(writerObj, frame);
			end
			% close the writer object
			close(writerObj);

		end


		function PlotNodesAndEdgesTimeStep(obj, r, timeStep, varargin)


			xyrange = [];
			plotTitle = '';

			if ~isempty(varargin)
				xyrange = varargin{1};
				if length(varargin)>1
					plotTitle = varargin{2};
				end
			end


			h = figure();
			axis equal
			hold on

			i = timeStep;

			lineWidth = 0.5;
			% Initialise the array with anything
			patchObjects(1) = patch([1,1],[2,2],obj.cs.GetRGB(6), 'LineWidth', lineWidth);
			lineObjects(1)  = line([1,1],[2,2],'Color', 'k', 'LineWidth', 4);



			[~,J] = size(obj.cells);
			j = 1; % loops node cells

			while j <= J && ~isempty(obj.cells{i,j})

				c = obj.cells{i,j};
				ids = c(1:end-1);
				colour = c(end);

				% This should only for the node cells
				if length(ids) < 2

					a = squeeze(obj.nodes(ids,i,:))';

					[pillX,pillY] = obj.DrawPill(a,a,r);
					patchObjects(j) = patch(pillX,pillY,obj.cs.GetRGB(colour), 'LineWidth', .5);

				else

					nodeCoords = squeeze(obj.nodes(ids,i,:));
					x = nodeCoords(:,1);
					y = nodeCoords(:,2);

					x(end+1) = x(1);
					y(end+1) = y(1);

					% This assumes only a single membrane exists
					% to handle multiple membranes, change 1 to j
					% but this will break the "bring to front command" uistack(lineObjects(1),'top')
					lineObjects(1) = line(x,y, 'Color', 'k', 'LineWidth', 4);

				end

				j = j + 1;

			end

			uistack(lineObjects(1),'top');


			if ~isempty(xyrange)
				xlim(xyrange(1:2));
				ylim(xyrange(3:4));
			end
			
			% j will always end up being 1 more than the total number of non empty cells
			axis off
			drawnow
			if ~isempty(plotTitle)
				title(plotTitle,'Interpreter', 'latex', 'FontSize', 34);
			else
				title(sprintf('t = %g',obj.timeSteps(i)),'Interpreter', 'latex', 'FontSize', 34);
			end

			set(h,'Units','Inches');
			pos = get(h,'Position');
			set(h,'PaperPositionMode','Auto','PaperUnits','Inches','PaperSize',[pos(3), pos(4)]);
			
			fileName = sprintf('ImageAtTime_%g',obj.timeSteps(timeStep));
			fileName = strrep(fileName,'.','_'); % If any time has decimals, change the point to underscore
			fileName = sprintf('%s%s', obj.pathToOutput, fileName);
			print(fileName,'-dpdf')


		end


		function [pillX,pillY] = DrawPill(obj,a,b,r)

			% Draws a pill shape where the centre of the circles are at
			% a and b and the radius is r

			AtoB = b - a;
			 
			normAtoB = [-AtoB(2), AtoB(1)];
			 
			normAtoB = normAtoB / norm(normAtoB);
			if isnan(normAtoB)
				normAtoB = [1,0];
			end
			 
			R = r*normAtoB;
			% Make n equally spaced points around a circle starting from R
			
			n = 10;
			apoints = [];
			bpoints = [];
			
			rot = @(theta) [cos(theta), -sin(theta); sin(theta), cos(theta)];
			
			for i=1:n-1
				
				theta = i*pi/n;
				apoints(i,:) = rot(theta)*R' + a';
				bpoints(i,:) = -rot(theta)*R' + b';
				
			end
			pill = [ a + R; apoints; a - R; b - R; bpoints;  b + R];
			
			pillX = pill(:,1);
			pillY = pill(:,2);

		end


	end


end