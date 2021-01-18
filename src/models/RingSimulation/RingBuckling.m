classdef RingBuckling < RingSimulation

	% This simulation makes a ring of cells, so there is no
	% start or end cell. The intention is for the ring to buckle
	% and self contact. The cell-cell interaction force allows
	% the ring to interact with itself

	properties

		dt = 0.005
		t = 0
		eta = 1

		timeLimit = 2000

	end

	methods

		function obj = RingBuckling(n, t0, tg, seed)
			% All the initilising
			obj.SetRNGSeed(seed);

			% n is the number of cells in the ring, we restrict it to be  >10
			% t0 is the growth start age
			% tg is the growth end age

			% Other parameters
			% The repulsion interaction force
			s = 10;
			% Adhesion interaction (not used by default)
			% If it is used, it is preferable to set a = s, but not vital
			a = 0;

			% Contact inhibition fraction
			f = 0.9;

			% The asymptote, separation, and limit distances for the interaction force
			dAsym = 0;
			dSep = 0.1;
			dLim = 0.2;

			% The energy densities for the cell growth force
			areaEnergy = 20;
			perimeterEnergy = 10;
			tensionEnergy = 1;


			%---------------------------------------------------
			% Make all the cells
			%---------------------------------------------------

			% The cells in this simulation form a closed ring
			% so every cell will have two neighbours
			% The diameter of the ring is determined by the number of cells
			% In order to have a sensible starting configuration, 
			% we set a minimum number of 10 cells

			if n < 10
				error('For a ring, at least 10 starting cells are needed');
			end

			
			%---------------------------------------------------
			% Make a list of top nodes and bottom nodes
			%---------------------------------------------------

			% We want to minimise the difference between the top and bottom
			% element lengths. The internal element lengths will be 1
			% Cells will be spaced evenly, covering 2pi/n rads
			% WE also keep the cell area at 0.5 since we are starting in Pause

			% Under these conditions, the radius r of the bottom nodes is given
			% by:

			r = 0.5 / sin(2*pi/n) - 0.5;

			topNodes = Node.empty();
			bottomNodes = Node.empty();

			for i = 1:n

				theta = 2*pi*i/n;
				xb = r * cos(theta);
				yb = r * sin(theta);

				xt = (r + 1) * cos(theta);
				yt = (r + 1) * sin(theta);

				bottomNodes(end + 1) = Node(xb, yb, obj.GetNextNodeId());
				topNodes(end + 1) = Node(xt, yt, obj.GetNextNodeId());

			end

			obj.AddNodesToList(bottomNodes);
			obj.AddNodesToList(topNodes);

			% The list of nodes goes anticlockwise, so from a node pair
			% i and i+1, i will be the right node, and i+1 the left

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
			ccm = GrowthContactInhibition(t0, tg, f, obj.dt);

			% Assemble the cell

			obj.cellList = SquareCellJoined(ccm, [elementTop, elementBottom, elementLeft, elementRight], obj.GetNextCellId());

			%---------------------------------------------------
			% Make the middle cells
			%---------------------------------------------------

			for i = 2:n-1
				% Each time we advance to the next cell, the right most nodes and element of the previous cell
				% become the leftmost element of the new cell

				elementRight 	= elementLeft;
				elementLeft 	= Element(bottomNodes(i+1), topNodes(i+1), obj.GetNextElementId());
				elementBottom 	= Element(bottomNodes(i), bottomNodes(i+1), obj.GetNextElementId());
				elementTop	 	= Element(topNodes(i), topNodes(i+1), obj.GetNextElementId());

				% Critical for joined cells
				elementLeft.internal = true;

				obj.AddElementsToList([elementBottom, elementRight, elementTop]);

				ccm = GrowthContactInhibition(t0, tg, f, obj.dt);

				obj.cellList(i) = SquareCellJoined(ccm, [elementTop, elementBottom, elementLeft, elementRight], obj.GetNextCellId());

			end

			%---------------------------------------------------
			% Make the last cell
			%---------------------------------------------------
			
			elementRight 	= elementLeft;
			elementLeft 	= obj.cellList(1).elementRight;
			elementBottom 	= Element(bottomNodes(n), bottomNodes(1), obj.GetNextElementId());
			elementTop	 	= Element(topNodes(n), topNodes(1), obj.GetNextElementId());

			% Critical for joined cells
			elementLeft.internal = true;

			obj.AddElementsToList([elementBottom, elementTop]);

			ccm = GrowthContactInhibition(t0, tg, f, obj.dt);

			obj.cellList(n) = SquareCellJoined(ccm, [elementTop, elementBottom, elementLeft, elementRight], obj.GetNextCellId());


			%---------------------------------------------------
			% Add in the forces
			%---------------------------------------------------

			% Cell growth force
			obj.AddCellBasedForce(PolygonCellGrowthForce(areaEnergy, perimeterEnergy, tensionEnergy));


			% Node-Element interaction force - requires a SpacePartition
			obj.AddNeighbourhoodBasedForce(CellCellInteractionForce(a, s, dAsym, dSep, dLim, obj.dt, true));

			
			%---------------------------------------------------
			% Add space partition
			%---------------------------------------------------
			% In this simulation we are fixing the size of the boxes

			obj.boxes = SpacePartition(0.5, 0.5, obj);

			%---------------------------------------------------
			% Add the data we'd like to store
			%---------------------------------------------------

			obj.AddSimulationData(Circularity());
			obj.AddDataStore(StoreCircularity(1));
			obj.AddSimulationData(SpatialState());
			pathName = sprintf('RingBuckling/n%gt0%gtg%gs%ga%gf%gda%gds%gdl%galpha%gbeta%gt%g_seed%g/',n,t0,tg,s,a,f,dAsym,dSep, dLim, areaEnergy, perimeterEnergy, tensionEnergy, seed);
			obj.AddDataWriter(WriteSpatialState(20,pathName));
			

			%---------------------------------------------------
			% All done. Ready to roll
			%---------------------------------------------------

		end


	end

end
