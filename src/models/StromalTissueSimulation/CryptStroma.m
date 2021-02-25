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

		function obj = CryptStroma(p, g, b, f, sae, spe, seed)
			
			obj.SetRNGSeed(seed);

			epiCellType = 1;
			stromalCellType = 5;

			% N is the number of cells in the layer. This in turn defines the width
			% of the stromal blob supporting the cells
			% p, the pause/resting phase duration
			% g, the growing phase duration
			% b, The interaction spring force parameter
			% sae, the stromal area energy factor
			% spe, the stroma perimeter energy factor

			% Contact inhibition fraction
			% f = 0.9;

			% The asymptote, separation, and limit distances for the interaction force
			dAsym = 0;
			dSep = 0.1;
			dLim = 0.2;

			% The energy densities for the cell growth force
			areaEnergy = 20;
			perimeterEnergy = 10;
			tensionEnergy = 1;

			

			% Allowable epithelial x width
			w = 10;

			% This simulation is symetric about the y axis, so the width is evenly
			% split between each part

			k = BoundaryCellKiller(-w/2+2, w/2-2);

			obj.AddTissueLevelKiller(k);

			halfWidth = w/2;
			nicheRadius = 1.5;
			nicheHeight = 5;
			cryptHeight = 5;

			% y axis Position where differentation occurs
			wntCutoff = nicheHeight + nicheRadius + 0.5 * cryptHeight;

			[stroma, nodeList, elementList, cornerNodes] = BuildStroma(obj, halfWidth, nicheRadius, nicheHeight, cryptHeight, stromalCellType);

			obj.AddNodesToList( nodeList );
			obj.AddElementsToList( elementList );
			obj.cellList = [stroma];


			%---------------------------------------------------
			% Make cells that will populate the crypt
			%---------------------------------------------------

			[bottomNodes, topNodes] = MakeCellNodes(obj, dSep, halfWidth, nicheRadius, nicheHeight, cryptHeight);

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

			ccm = WntCellCycle(p, g, wntCutoff, f, obj.dt);

			% Assemble the cell

			c = SquareCellJoined(ccm, [elementTop, elementBottom, elementLeft, elementRight], obj.GetNextCellId());
			c.cellType = epiCellType;
			obj.cellList(end + 1) = c;

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

				ccm = WntCellCycle(p, g, wntCutoff, f, obj.dt);

				c = SquareCellJoined(ccm, [elementTop, elementBottom, elementLeft, elementRight], obj.GetNextCellId());
				c.cellType = epiCellType;
				obj.cellList(end + 1) = c;

			end

			boundaryCellMap('left') = obj.cellList(end);

			bc = obj.simData('boundaryCells');
			bc.SetData(boundaryCellMap);
			%---------------------------------------------------
			% Add in the forces
			%---------------------------------------------------

			% Cell growth force
			obj.AddCellBasedForce(PolygonCellGrowthForce(areaEnergy, perimeterEnergy, tensionEnergy));

			% A special distinct force for the stroma
			obj.AddCellBasedForce(StromaStructuralForce(stroma, sae, spe, 0));

			% Node-Element interaction force - requires a SpacePartition
			% Handles different interaction strengths between different cell types
			cellTypes = [epiCellType,stromalCellType];
			att = [0,b;
				   b,0]; % No attraction between epithelial cells
			obj.AddNeighbourhoodBasedForce(CellTypeInteractionForce(att, repmat(b,2), repmat(dAsym,2), repmat(dSep,2), repmat(dLim,2), cellTypes, obj.dt, true));
			
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
			obj.AddSimulationModifier(   PinNodes(  cornerNodes  )   );

			% %---------------------------------------------------
			% % Add the modfier to keep the boundary cells at the
			% % same vertical position
			% %---------------------------------------------------
			
			% obj.AddSimulationModifier(ShiftBoundaryCells());

			%---------------------------------------------------
			% Add the data writers
			%---------------------------------------------------

			obj.AddSimulationData(SpatialState());
			pathName = sprintf('CryptStroma/p%gg%gb%gsae%gspe%gf%gda%gds%gdl%galpha%gbeta%gt%ghw%gnh%gnr%gch%gwnt%g_seed%g/',p,g,b,sae,spe,f,dAsym,dSep, dLim, areaEnergy, perimeterEnergy, tensionEnergy, halfWidth, nicheHeight, nicheRadius, cryptHeight, wntCutoff, seed);
			obj.AddDataWriter(WriteSpatialState(100,pathName));

			%---------------------------------------------------
			% All done. Ready to roll
			%---------------------------------------------------

		end

		function [stroma, nodeList, elementList, cornerNodes] = BuildStroma(obj, halfWidth, nicheRadius, nicheHeight, cryptHeight, stromalCellType)

			% Produces a stroma with crypt shape for the crypt cells
			% Total width is 2 x halfWidth
			% Total height is nicheHeight + cryptHeight + nicheRadius + corner radius (re)
			% Crypt width is 2 x radius

			% Returns the stromal cell, and a vector of nodes that mark the corners, so they
			% can be pinned in place

			%---------------------------------------------------
			% Make the nodes for the stroma
			%---------------------------------------------------

			totalHeight = nicheHeight + nicheRadius + cryptHeight;
			dx = 0.25; % The length of the edges not on the curved part

			x = [];
			y = [];

			% Go along the top
			for X = halfWidth:-dx:nicheRadius

				x(end + 1) = X;
				y(end + 1) = totalHeight;

			end

			% Then down the side

			for Y = (totalHeight-dx):-dx:(nicheHeight+nicheRadius)

				x(end + 1) = nicheRadius;
				y(end + 1) = Y;

			end

			% Then around the curve
			n = 10;
			for theta = -pi/(2*n):-pi/(2*n):-pi/2

				x(end + 1) = nicheRadius * cos(theta);
				y(end + 1) = (nicheHeight + nicheRadius) + nicheRadius * sin(theta);

			end

			% Make the vector of positions
			% the indices (1:end-1) stop it from repeating the bottom centre node
			pos = [x',y';-flipud(x(1:end-1)'),flipud(y(1:end-1)')];

			% Add in the missing bottom corner positions

			pos = [pos;-halfWidth,0;halfWidth,0];


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
			ccm.colour = stromalCellType;

			stroma = CellFree(ccm, nodeList, elementList, obj.GetNextCellId());

			% Critical to stop the ChasteNagaiHondaForce beign applied to the stroma
			stroma.cellType = stromalCellType;

			% Make a maltab polygon to exploit the area and perimeter calculation
			stroma.grownCellTargetArea = polyarea(pos(:,1), pos(:,2));

			perim = 0;
			for i = 1:length(elementList)
				perim = perim + elementList(i).GetLength();
			end

			stroma.cellData('targetPerimeter') = TargetPerimeterStroma(perim);

			cornerNodes = [nodeList(1), nodeList(end-2:end)];

		end

		function [bottomNodes, topNodes] = MakeCellNodes(obj, dSep, halfWidth, nicheRadius, nicheHeight, cryptHeight)

			% Reduce the prepopulated height of the epithelial cells
			% in order to give the stroma time to settle
			transientClearance = 2; 

			totalHeight = nicheHeight + nicheRadius + cryptHeight - transientClearance;
			dx = 0.5; % The width of the cells in the plane of the epithelial layer

			xb = [];
			yb = [];

			xt = [];
			yt = [];

			% We want to minimise the difference between the top and bottom
			% element lengths. The internal element lengths will be 1
			% Cells will be spaced evenly, covering 2pi/n rads
			% WE also keep the cell area at 0.5 since we are starting in Pause

			% Under these conditions, the radius r of the bottom nodes is given
			% by:

			% r = 0.5 / sin(2*pi/n) - 0.5;

			% Since we know the radius of the bottom nodes is nichRadius - dSep
			% this gives us a set number of cells

			r = nicheRadius - dSep;

			n = ceil( 2*pi / (4 * asin(1/(2*r-1))) );

			for i = 0:n-1

				theta = -pi/2 + i*pi/(2*n);
				xb(end + 1) = r * cos(theta);
				yb(end + 1) = nicheHeight + nicheRadius + r * sin(theta);

				xt(end + 1) = (r - 1) * cos(theta);
				yt(end + 1) = nicheHeight + nicheRadius + (r - 1) * sin(theta);

				

			end

			% Then up the side

			for Y = (nicheHeight+nicheRadius):dx:totalHeight

				xb(end + 1) = r;
				yb(end + 1) = Y;

				xt(end + 1) = r-1;
				yt(end + 1) = Y;

			end
			

			% Make the vector of positions
			% the indices (2:end) stop it from repeating the bottom centre node
			xb = [flipud(xb(2:end)');-xb'];
			xt = [flipud(xt(2:end)');-xt'];

			yb = [flipud(yb(2:end)');yb'];
			yt = [flipud(yt(2:end)');yt'];

			topNodes = Node.empty();
			bottomNodes = Node.empty();
			for i = 1:length(xt)

				bottomNodes(i) = Node(xb(i), yb(i), obj.GetNextNodeId());
				topNodes(i) = Node(xt(i), yt(i), obj.GetNextNodeId());

			end

		end

	end

end
