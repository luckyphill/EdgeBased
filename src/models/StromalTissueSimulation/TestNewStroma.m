classdef TestNewStroma < LineSimulation

	% A template for constructing simulations

	properties

		dt = 0.001
		t = 0
		eta = 1

		timeLimit = 1000

		pathName
		simulationOutputLocation

	end

	methods

		function obj = TestNewStroma(p1, p2, p3, seed)
			
			obj.SetRNGSeed(seed);

			% p1, description
			% p2, description
			% p3, description

			% Internal variables
			v1 = 1;
			v2 = 2;
			v3 = 3;

			w = 10;
			halfWidth = w/2;
			nicheRadius = 1.5;
			nh = 3;
			ch = 10;
			cryptSideLength = ch - nicheRadius;
			stromalCellType = 5;

			[stroma, nodeList, edgeList, fixedNodes] = BuildStroma(obj, halfWidth, nicheRadius, nh, cryptSideLength, stromalCellType);

			%---------------------------------------------------
			% Make cells that will populate the crypt
			%---------------------------------------------------

			obj.AddNodesToList( nodeList );
			obj.AddElementsToList( edgeList );
			obj.cellList = [stroma];


			%---------------------------------------------------
			% Add in the forces
			%---------------------------------------------------

			% obj.AddElementBasedForce(); % Adds force based on the state of the edge
			% obj.AddCellBasedForce(); % Adds force based on the state of the cell
			% obj.AddNeighbourhoodBasedForce(); % Adds force based on neighbourhood interactions. Requires a space partition
			% obj.AddTissueBasedForce(); % Adds force based on the state of the whole tissue
			
			%---------------------------------------------------
			% Add space partition
			%---------------------------------------------------

			obj.boxes = SpacePartition(0.5, 0.5, obj);

			%---------------------------------------------------
			% Add the data we'd like to store
			%---------------------------------------------------

			obj.AddSimulationData(SpatialState());


			%---------------------------------------------------
			% Add modfiers
			%---------------------------------------------------
			
			% obj.AddSimulationModifier();

			%---------------------------------------------------
			% Add the data writers
			%---------------------------------------------------
			
			obj.pathName = sprintf('TestNewStroma/p1%gp2%gp3%gv1%gv2%gv3_seed%d/',p1,p2,p3,v1,v2,v3, seed);
			obj.AddDataWriter(WriteSpatialState(100,obj.pathName));

			% A little hack to make the parameter sweeps slightly easier to handle
			obj.simulationOutputLocation = [getenv('EDGEDIR'),'/SimulationOutput/' obj.pathName];

			%---------------------------------------------------
			% All done. Ready to roll
			%---------------------------------------------------

			

		end


		function [stroma, nodeList, edgeList, fixedNodes] = BuildStroma(obj, halfWidth, nicheRadius, nicheHeight, cryptSideLength, stromalCellType)

			% Produces a stroma with crypt shape for the crypt cells
			% Total width is 2 x halfWidth
			% Total height is nicheHeight + cryptSideLength + nicheRadius + corner radius (re)
			% Crypt width is 2 x radius

			% Returns the stromal cell, and a vector of nodes that mark the corners, so they
			% can be pinned in place

			% No anchoring in this test
			anchorEdges = Element.empty();


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

			% This gets the index of the node at the bottom of the crypt
			botI1 = length(x);

			% Make the vector of positions
			% the indices (1:end-1) stop it from repeating the bottom centre node
			pos = [x',y';-flipud(x(1:end-1)'),flipud(y(1:end-1)')];

			% Add in the missing bottom positions

			pos = [pos;-halfWidth,0;0,0;halfWidth,0];
			posR = [x',y';0,0;halfWidth,0];
			posL = [-flipud(x'),flipud(y');-halfWidth,0;0,0];

			% This gets the index of the node at the bottom of the stromal slab
			botI2 = size(pos,1)-1;

			%---------------------------------------------------
			% Make the cells that acts as the stroma
			%---------------------------------------------------
			
			nodeList = Node.empty();

			% Nodes are easy, just make one for each position
			for i = 1:length(pos)
				nodeList(end+1) = Node(pos(i,1), pos(i,2), obj.GetNextNodeId());
			end
			
			% Need to make node lists for the left and right stromal sections
			nodesR = [nodeList(1:botI1), nodeList(botI2:end)];
			nodesL = nodeList(botI1:botI2);

			% Make left edges except for last one
			edgesL = Element.empty();
			for i = 1:length(nodesL)-1
				edgesL(end + 1) = Element(nodesL(i), nodesL(i+1), obj.GetNextElementId() );
			end

			%Make right edges except for last one
			edgesR = Element.empty();
			% Start with the bottom and side edges so we can keep anticlockwise ordering
			edgesR(end + 1) = Element(nodesR(end-1), nodesR(end), obj.GetNextElementId() );
			edgesR(end + 1) = Element(nodesR(end), nodesR(1), obj.GetNextElementId() );
			% Then go around until the bottom of the crypt
			for i = 1:length(nodesR(1:botI1))-1
				edgesR(end + 1) = Element(nodesR(i), nodesR(i+1), obj.GetNextElementId() );
			end
			
			% Now make the shared edge
			% This will put the nodes in the correct order to be anticlockwise
			% for the right cell only
			edgeShared = Element(nodeList(botI1), nodeList(botI2), obj.GetNextElementId() );

			% Set the shared edge to internal so it doesn't interact with anything as an edge
			edgeShared.internal = true;

			% Use the existing edge vectors to construct the full edge list and avoid
			% duplicating the shared edge
			edgeList = [edgesR, edgesL, edgeShared];

			% Now make the complete edge lists for the two cells

			edgesR = [edgesR, edgeShared];
			edgesL = [edgesL, edgeShared];


			% Now construct the two cells


			% Start with right cell
			ccmR = NoCellCycle();
			ccmR.colour = stromalCellType;

			stromaR = CellFree(ccmR, nodesR, edgesR, obj.GetNextCellId());

			% Critical to stop the ChasteNagaiHondaForce beign applied to the stroma
			stromaR.cellType = stromalCellType;

			% Make a maltab polygon to exploit the area and perimeter calculation
			stromaR.grownCellTargetArea = polyarea(posR(:,1), posR(:,2));

			perim = 0;
			for i = 1:length(edgesR)
				perim = perim + edgesR(i).GetLength();
			end

			stromaR.cellData('targetPerimeter') = TargetPerimeterStroma(perim);


			% Now for left cell
			ccmL = NoCellCycle();
			ccmL.colour = stromalCellType;

			stromaL = CellFree(ccmL, nodesL, edgesL, obj.GetNextCellId());

			% Critical to stop the ChasteNagaiHondaForce beign applied to the stroma
			stromaL.cellType = stromalCellType;

			% Make a maltab polygon to exploit the area and perimeter calculation
			stromaL.grownCellTargetArea = polyarea(posL(:,1), posL(:,2));

			perim = 0;
			for i = 1:length(edgesL)
				perim = perim + edgesL(i).GetLength();
			end

			stromaL.cellData('targetPerimeter') = TargetPerimeterStroma(perim);

			stroma = [stromaR, stromaL];

			fixedNodes = [nodeList(1), nodeList(end-3:end)];

		end

		function [cells, nodeList, edgeList, fixedNodes] = BuildStroma2(obj, halfWidth, nicheRadius, nicheHeight, cryptSideLength, stromalCellType)

			% Produces a stroma with crypt shape for the crypt cells
			% contining three distinct, but joined stromal cells
			% Total width is 2 x halfWidth
			% Total height is nicheHeight + cryptSideLength + nicheRadius + corner radius (re)
			% Crypt width is 2 x radius

			% Returns the stromal cells, and a vector of nodes that mark the corners, so they
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

			% This gets the index of the node at the bottom
			botI = length(x);

			% Make the vector of positions
			% the indices (1:end-1) stop it from repeating the bottom centre node
			% pos = [x',y';-flipud(x(1:end-1)'),flipud(y(1:end-1)')];

			% The positions of the node for the three cells
			posR = [x(1:end-1)',y(1:end-1)'];
			posL = [-flipud(x(1:end-1)'), flipud(y(1:end-1)')];
			posBL = [-halfWidth,0];
			posBR = [halfWidth,0];
			posC = [x(end), y(end)];

			%---------------------------------------------------
			% Make the node that build the stromal cells
			%---------------------------------------------------

			nlR = Node.empty();
			nlL = Node.empty();

			for i = 1:size(posR,1)
				nlR(end+1) = Node(posR(i,1), posR(i,2), obj.GetNextNodeId());
			end
			for i = 1:size(posL,1)
				nlL(end+1) = Node(posL(i,1), posL(i,2), obj.GetNextNodeId());
			end
			
			nlBL = Node(posBL(1,1), posBL(1,2), obj.GetNextNodeId());
			nlBR = Node(posBR(1,1), posBR(1,2), obj.GetNextNodeId());
			nlC = Node(posC(1,1), posC(1,2), obj.GetNextNodeId());

			nodeListL = [nlC, nlL, nlBL];
			nodeListR = [nlC, nlBR, nlR];
			nodeListB = [nlC, nlBL, nlBR];

			posListL = [posC; posL; posBL];
			posListR = [posC; posBR; posR];
			posListB = [posC; posBL; posBR];

			%---------------------------------------------------
			% Make the edges that build the stromal cells
			%---------------------------------------------------

			edgeListL = Element.empty();
			edgeListR = Element.empty();
			edgeListB = Element.empty();

			for i = 1:length(nodeListL)-1
				edgeListL(end + 1) = Element(nodeListL(i), nodeListL(i+1), obj.GetNextElementId() );
			end
			edgeListL(end + 1) = Element(nodeListL(end), nodeListL(1), obj.GetNextElementId() );

			for i = 1:length(nodeListR)-1
				edgeListR(end + 1) = Element(nodeListR(i), nodeListR(i+1), obj.GetNextElementId() );
			end
			edgeListR(end + 1) = Element(nodeListR(end), nodeListR(1), obj.GetNextElementId() );

			for i = 1:length(nodeListB)-1
				edgeListB(end + 1) = Element(nodeListB(i), nodeListB(i+1), obj.GetNextElementId() );
			end
			edgeListB(end + 1) = Element(nodeListB(end), nodeListB(1), obj.GetNextElementId() );

			%---------------------------------------------------
			% Make the Left stroma
			%---------------------------------------------------

			ccmL = NoCellCycle();
			ccmL.colour = stromalCellType;

			stromaL = CellFree(ccmL, nodeListL, edgeListL, obj.GetNextCellId());

			% Critical to stop the ChasteNagaiHondaForce beign applied to the stroma
			stromaL.cellType = stromalCellType;

			% Make a maltab polygon to exploit the area and perimeter calculation
			stromaL.grownCellTargetArea = polyarea(posListL(:,1), posListL(:,2));

			perim = 0;
			for i = 1:length(edgeListL)
				perim = perim + edgeListL(i).GetLength();
			end

			stromaL.cellData('targetPerimeter') = TargetPerimeterStroma(perim);

			%---------------------------------------------------
			% Make the Right stroma
			%---------------------------------------------------

			ccmR = NoCellCycle();
			ccmR.colour = stromalCellType;

			stromaR = CellFree(ccmR, nodeListR, edgeListR, obj.GetNextCellId());

			% Critical to stop the ChasteNagaiHondaForce beign applied to the stroma
			stromaR.cellType = stromalCellType;

			% Make a maltab polygon to exploit the area and perimeter calculation
			stromaR.grownCellTargetArea = polyarea(posListR(:,1), posListR(:,2));

			perim = 0;
			for i = 1:length(edgeListR)
				perim = perim + edgeListR(i).GetLength();
			end

			stromaR.cellData('targetPerimeter') = TargetPerimeterStroma(perim);


			%---------------------------------------------------
			% Make the Bottom stroma
			%---------------------------------------------------

			ccmB = NoCellCycle();
			ccmB.colour = stromalCellType;

			stromaB = CellFree(ccmB, nodeListB, edgeListB, obj.GetNextCellId());

			% Critical to stop the ChasteNagaiHondaForce beign applied to the stroma
			stromaB.cellType = stromalCellType;

			% Make a maltab polygon to exploit the area and perimeter calculation
			stromaB.grownCellTargetArea = polyarea(posListB(:,1), posListB(:,2));

			perim = 0;
			for i = 1:length(edgeListB)
				perim = perim + edgeListB(i).GetLength();
			end

			stromaB.cellData('targetPerimeter') = TargetPerimeterStroma(perim);

			%---------------------------------------------------
			% Construct the return vectors
			%---------------------------------------------------

			cells = [stromaL, stromaR, stromaB];
			nodeList = [nodeListL, nodeListR, nodeListB];
			edgeList = [edgeListL, edgeListR, edgeListB];

			fixedNodes = [nlBL, nlBR];

		end

	end

end
