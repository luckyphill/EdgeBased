classdef CryptStroma < LineSimulation

	% This simulation gives a crypt-like structure in a "waterbed" type model
	% It currently uses a quick hack to make the cells stop dividing past a certain height
	% using WntCellCycle

	properties

		dt = 0.002
		t = 0
		eta = 1

		timeLimit = 1000

	end

	methods

		function obj = CryptStroma(p, g, w, b, seed, varargin)
			% All the initilising
			obj.SetRNGSeed(seed);

			% We keep the option of diffent box sizes for efficiency reasons
			if length(varargin) > 0
				if length(varargin) == 3
					areaEnergy = varargin{1};
					perimeterEnergy = varargin{2};
					adhesionEnergy = varargin{3};
				else
					error('Error using varargin, must have 3 args, areaEnergy, perimeterEnergy, and adhesionEnergy');
				end
			else
				areaEnergy = 20;
				perimeterEnergy = 10;
				adhesionEnergy = 1;
			end

			% This simulation is symetric about the y axis, so the width is evenly
			% split between each part

			k = BoundaryCellKiller(-w/2, w/2);

			obj.AddTissueLevelKiller(k);

			%---------------------------------------------------
			% Make the nodes for the stroma
			%---------------------------------------------------

			rb = 1.5; % radius of bottom/niche
			re = 0.5; % radius of the edge

			h = 5; % height of the crypt from cb to ce
			wd = 10; % width from edge to edge of sim domain
			% if w < 2*(rb+re)
			% 	error('Too narrow, increase width');
			% end

			cb = [0,0];
			cel = cb - [(rb+re), 0] + [0,h];
			cer = cb + [(rb+re), 0] + [0,h];

			d = 10; % divisions in a quater of a circle

			pos = []; % a vector of all the positions

			% We start from the right and work our way to the left to make an
			% anticlockwise loop.

			x = linspace(wd/2,(rb+re),10);

			pos = [x',(h + re)*ones(size(x'))];

			% First curve
			% Theta goes from pi/2 to pi in d steps
			for i = 1:d-1
			    theta = pi/2 + i * pi / (2*d);
			    pos(end+1,:) = cer + [re*cos(theta), re*sin(theta)];
			end

			y = linspace(h,0,20);

			temp = [rb * ones(size(y')), y'];

			pos = [pos;temp];


			% Second curve
			% Theta goes from 0 to -pi/2 in d steps
			for i = 1:d
			    theta = 0 - i * pi / (2*d);
			    pos(end+1,:) = cb + [rb*cos(theta), rb*sin(theta)];
			end


			% The line is symetrical so just duplicate and reflect the x values
			% except for the very bottom

			rpos = flipud(pos);
			rpos(:,1) = -rpos(:,1);
			rpos(1,:) = [];

			pos = [pos;rpos];

			stromaBottom = -3;

			pos(end+1,:) = [pos(end,1), stromaBottom];
			pos(end+1,:) = [pos(1,1), stromaBottom];

			%---------------------------------------------------
			% Make the cell that acts as the stroma
			%---------------------------------------------------
			
			nodeList = Node.empty();

			for i = 1:length(pos)
				nodeList(end+1) = Node(pos(i,1), pos(i,2), obj.GetNextNodeId());
			end
			
			elementList = Element.empty();
			for i = 1:length(nodeList)-1
				elementList(end + 1) = Element(nodeList(i), nodeList(i+1), obj.GetNextElementId() );
			end

			elementList(end + 1) = Element(nodeList(end), nodeList(1), obj.GetNextElementId() );

			ccm = NoCellCycle();
			ccm.colour = 5;

			s = CellFree(ccm, nodeList, elementList, obj.GetNextCellId());

			% Critical to stop the ChasteNagaiHondaForce beign applied to the stroma
			s.cellType = 2;

			% Make a maltab polygon to exploit the area and perimeter calculation

			s.grownCellTargetArea = polyarea(pos(:,1), pos(:,2));

			perim = 0;
			for i = 1:length(elementList)
				perim = perim + elementList(i).GetLength();
			end

			s.cellData('targetPerimeter') = TargetPerimeterStroma(perim);

			obj.AddNodesToList( nodeList );
			obj.AddElementsToList( elementList );
			obj.cellList = s;

			%---------------------------------------------------
			% Make cells that will populate the crypt
			%---------------------------------------------------

			nCells = 10;
			r = 0.5 / sin(2*pi/nCells) - 0.5;

			topNodes = Node.empty();
			bottomNodes = Node.empty();

			for n = 0:floor(nCells/2)

				theta = -2*pi*n/nCells;
				xt = r * cos(theta);
				yt = r * sin(theta);

				xb = (r + 1) * cos(theta);
				yb = (r + 1) * sin(theta);

				bottomNodes(end + 1) = Node(xb, yb, obj.GetNextNodeId());
				topNodes(end + 1) = Node(xt, yt, obj.GetNextNodeId());

			end

			obj.AddNodesToList(bottomNodes);
			obj.AddNodesToList(topNodes);


			%---------------------------------------------------
			% Make the first cell
			%---------------------------------------------------
			% Make the elements

			elementRight 	= Element(bottomNodes(1), topNodes(1), obj.GetNextElementId());
			elementLeft 	= Element(bottomNodes(2), topNodes(2), obj.GetNextElementId());
			elementBottom 	= Element(bottomNodes(1), bottomNodes(2), obj.GetNextElementId());
			elementTop	 	= Element(topNodes(1), topNodes(2), obj.GetNextElementId());
			
			% Critical for joined cells
			elementLeft.internal = true;

			obj.AddElementsToList([elementBottom, elementRight, elementTop, elementLeft]);

			% Cell cycle model

			ccm = WntCellCycle(p, g);

			% Assemble the cell

			obj.cellList(end + 1) = SquareCellJoined(ccm, [elementTop, elementBottom, elementLeft, elementRight], obj.GetNextCellId());

			boundaryCellMap = containers.Map({'right'}, {obj.cellList(end)});
			%---------------------------------------------------
			% Make the middle cells
			%---------------------------------------------------

			for i = 2:length(topNodes)-1
				% Each time we advance to the next cell, the right most nodes and element of the previous cell
				% become the leftmost element of the new cell

				elementRight 	= elementLeft;
				elementLeft 	= Element(bottomNodes(i+1), topNodes(i+1), obj.GetNextElementId());
				elementBottom 	= Element(bottomNodes(i), bottomNodes(i+1), obj.GetNextElementId());
				elementTop	 	= Element(topNodes(i), topNodes(i+1), obj.GetNextElementId());

				% Critical for joined cells
				elementLeft.internal = true;

				obj.AddElementsToList([elementBottom, elementRight, elementTop]);

				ccm = WntCellCycle(p, g);

				obj.cellList(end + 1) = SquareCellJoined(ccm, [elementTop, elementBottom, elementLeft, elementRight], obj.GetNextCellId());

			end

			boundaryCellMap('left') = obj.cellList(end);

			bc = obj.simData('boundaryCells');
			bc.SetData(boundaryCellMap);
			%---------------------------------------------------
			% Add in the forces
			%---------------------------------------------------

			% Nagai Honda forces
			obj.AddCellBasedForce(ChasteNagaiHondaForce(areaEnergy, perimeterEnergy, adhesionEnergy));

			% A special distinct force for the stroma
			obj.AddCellBasedForce(StromaNagaiHondaForce(s, areaEnergy, perimeterEnergy, 0));

			% Corner force to prevent very sharp corners
			obj.AddCellBasedForce(CornerForceCouple(0.1,pi/2));

			% Element force to stop elements becoming too small
			obj.AddElementBasedForce(EdgeSpringForce(@(n,l) 20 * exp(1-25 * l/n)));

			% Node-Element interaction force - requires a SpacePartition
			obj.AddNeighbourhoodBasedForce(StromaAdhesionForce(0.1, b, obj.dt));

			if b <= 0
				error("Force must be greater than 0")
			end
			
			%---------------------------------------------------
			% Add space partition
			%---------------------------------------------------
			% In this simulation we are fixing the size of the boxes

			obj.boxes = SpacePartition(0.5, 0.5, obj);

			%---------------------------------------------------
			% Add the data we'd like to store
			%---------------------------------------------------

			% obj.AddDataStore(StoreWiggleRatio(10));

			%---------------------------------------------------
			% Add the modfier to keep the stromal corner cells
			% locked in place
			%---------------------------------------------------
			
			% nodeList comes from building the stroma
			obj.AddSimulationModifier(   PinNodes(  [nodeList(1), nodeList(end-2:end)]  )   );

			% %---------------------------------------------------
			% % Add the modfier to keep the boundary cells at the
			% % same vertical position
			% %---------------------------------------------------
			
			% obj.AddSimulationModifier(ShiftBoundaryCells());

			%---------------------------------------------------
			% Add the data writers
			%---------------------------------------------------

			obj.AddSimulationData(SpatialState());
			pathName = sprintf('CryptStroma/p%gg%gw%gb%g_seed%g/',p,g,w,b,seed);
			obj.AddDataWriter(WriteSpatialState(100,pathName));

			%---------------------------------------------------
			% All done. Ready to roll
			%---------------------------------------------------

		end

	end

end
