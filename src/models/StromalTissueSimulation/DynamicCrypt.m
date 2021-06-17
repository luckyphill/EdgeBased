classdef DynamicCrypt < LineSimulation

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

		function obj = DynamicCrypt(p, g, b, f, sae, spe, nh, ch, wnt, seed)
			
			obj.SetRNGSeed(seed);

			epiCellType = 1;
			stromalCellType = 5;

			% p, the pause/resting phase duration
			% g, the growing phase duration
			% b, The interaction spring force parameter
			% sae, the stromal area energy factor
			% spe, the stroma perimeter energy factor
			% nh = nicheHeight, the distance from the bottom of the stroma to the bottom of the crypt
			% ch = cryptHeight, the length from top to bottom of the crypt
			% wnt = wntCutoff, the distance from the bottom of the crypt to the point where differentiation occurs

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

			% Chosen from empirical testing
			% Areas and perimeters for crypt cells
			newArea = 0.55;
			grownArea = 1;
			newPerimeter = 3.4;
			grownPrimeter = 4;


			% Parameters defining the shape of the stroma
			w = 10;
			halfWidth = w/2;
			nicheRadius = 1.5;
			% nicheHeight = nh;
			% cryptHeight = ch;
			% wntCutoff = wnt;
			cryptSideLength = ch - nicheRadius;

			% The width and height of the rectangular cells
			% empirically chosen tominimise the pinching issue
			cellW = 0.4;
			cellH = 1.3;

			% This simulation is symetric about the y axis, so the width is evenly
			% split between each part

			k = BoundaryCellKiller(-w/2+2, w/2-2);

			obj.AddTissueLevelKiller(k);

			
			

			[stroma, nodeList, elementList, cornerNodes] = BuildStroma(obj, halfWidth, nicheRadius, nh, cryptSideLength, stromalCellType);

			obj.AddNodesToList( nodeList );
			obj.AddElementsToList( elementList );
			obj.cellList = [stroma];


			%---------------------------------------------------
			% Make cells that will populate the crypt
			%---------------------------------------------------

			[bottomNodes, topNodes] = MakeCellNodes(obj, dSep, halfWidth, nicheRadius, nh, cryptSideLength, cellW, cellH);

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

			% Must add in WntCutoff calculator to simdata
			obj.AddSimulationData(WntCutoffFromNiche(stroma, wnt));
			ccm = WntCellCycle(p, g, f, obj);

			% Assemble the cell

			c = SquareCellJoined(ccm, [elementTop, elementBottom, elementLeft, elementRight], obj.GetNextCellId());
			c.cellType = epiCellType;

			c.AddCellData(TargetAreaSpecified(newArea,grownArea));
			c.AddCellData(TargetPerimeterSpecified(newPerimeter,grownPrimeter));

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

				ccm = WntCellCycle(p, g, f, obj);

				c = SquareCellJoined(ccm, [elementTop, elementBottom, elementLeft, elementRight], obj.GetNextCellId());
				c.cellType = epiCellType;

				c.AddCellData(TargetAreaSpecified(newArea,grownArea));
				c.AddCellData(TargetPerimeterSpecified(newPerimeter,grownPrimeter));

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
			pathName = sprintf('DynamicCrypt/p%gg%gb%gsae%gspe%gf%gda%gds%gdl%galpha%gbeta%gt%ghw%gnh%gnr%gch%gwnt%gan%gag%gpn%gpg%g_seed%g/',p,g,b,sae,spe,f,dAsym,dSep, dLim, areaEnergy, perimeterEnergy, tensionEnergy, halfWidth, nh, nicheRadius, ch, wnt, newArea, grownArea, newPerimeter, grownPrimeter, seed);
			obj.AddDataWriter(WriteSpatialState(100,pathName));

			%---------------------------------------------------
			% All done. Ready to roll
			%---------------------------------------------------

		end

		function [stroma, nodeList, elementList, cornerNodes] = BuildStroma(obj, halfWidth, nicheRadius, nicheHeight, cryptSideLength, stromalCellType)

			% Produces a stroma with crypt shape for the crypt cells
			% Total width is 2 x halfWidth
			% Total height is nicheHeight + cryptSideLength + nicheRadius + corner radius (re)
			% Crypt width is 2 x radius

			% Returns the stromal cell, and a vector of nodes that mark the corners, so they
			% can be pinned in place

			%---------------------------------------------------
			% Make the nodes for the stroma
			%---------------------------------------------------

			totalHeight = nicheHeight + nicheRadius + cryptSideLength;
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

		function [bottomNodes, topNodes] = MakeCellNodes(obj, dSep, halfWidth, nicheRadius, nicheHeight, cryptSideLength, cellW, cellH)

			% Reduce the prepopulated height of the epithelial cells
			% in order to give the stroma time to settle
			transientClearance = 2; 

			totalHeight = nicheHeight + nicheRadius + cryptSideLength - transientClearance;
			dx = cellW; % The width of the cells in the plane of the epithelial layer
			dy = cellH; % THe height


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

				xt(end + 1) = (r - dy) * cos(theta);
				yt(end + 1) = nicheHeight + nicheRadius + (r - dy) * sin(theta);

				

			end

			% Then up the side

			for Y = (nicheHeight+nicheRadius):dx:totalHeight

				xb(end + 1) = r;
				yb(end + 1) = Y;

				xt(end + 1) = r - dy;
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
