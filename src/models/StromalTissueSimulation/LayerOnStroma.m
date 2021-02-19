classdef LayerOnStroma < LineSimulation

	% This simulation is the most basic - a simple row of cells growing on
	% a plate. It allows us to choose the number of initial cells
	% the force related parameters, and the cell cycle lengths

	properties

		dt = 0.005
		t = 0
		eta = 1

		timeLimit = 500

		samplingMultiple = 100;

		pathName
		simulationOutputLocation

	end

	methods

		function obj = LayerOnStroma(N, p, g, b, f, sae, spe, seed)
			
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


			% This simulation only allows cells to exist in a limited x domain

			% Cells are set to be 0.5 units wide, and we make the supporting stroma
			% 0.5 * (N + 1) in length so there is a little room to expand before the
			% cell killer kicks in


			leftBoundary = -0.25;
			rightBoundary = 0.5 * N + 0.25;

			k = BoundaryCellKiller(leftBoundary, rightBoundary);

			obj.AddTissueLevelKiller(k);

			%---------------------------------------------------
			% Make all the cells
			%---------------------------------------------------

			% The first cell needs all elements and nodes created
			% subsquent cells will have nodes and elements from their
			% neighbours

			% Make the nodes

			nodeTopLeft 	= Node(0,1,obj.GetNextNodeId());
			nodeBottomLeft 	= Node(0,0,obj.GetNextNodeId());
			nodeTopRight 	= Node(0.5,1,obj.GetNextNodeId());
			nodeBottomRight	= Node(0.5,0,obj.GetNextNodeId());

			obj.AddNodesToList([nodeBottomLeft, nodeBottomRight, nodeTopRight, nodeTopLeft]);

			% Make the elements

			elementBottom 	= Element(nodeBottomLeft, nodeBottomRight, obj.GetNextElementId());
			elementRight 	= Element(nodeBottomRight, nodeTopRight, obj.GetNextElementId());
			elementTop	 	= Element(nodeTopLeft, nodeTopRight, obj.GetNextElementId());
			elementLeft 	= Element(nodeBottomLeft, nodeTopLeft, obj.GetNextElementId());

			obj.AddElementsToList([elementBottom, elementRight, elementTop, elementLeft]);

			% Cell cycle model

			ccm = GrowthContactInhibition(p, g, f, obj.dt);

			% Assemble the cell

			c = SquareCellJoined(ccm, [elementTop, elementBottom, elementLeft, elementRight], obj.GetNextCellId());
			c.cellType = epiCellType;
			obj.cellList = c;


			for i = 2:N
				% Each time we advance to the next cell, the right most nodes and element of the previous cell
				% become the leftmost element of the new cell

				nodeBottomLeft 	= nodeBottomRight;
				nodeTopLeft 	= nodeTopRight;
				nodeTopRight 	= Node(i*0.5,1,obj.GetNextNodeId());
				nodeBottomRight	= Node(i*0.5,0,obj.GetNextNodeId());
				

				obj.AddNodesToList([nodeBottomRight, nodeTopRight]);

				elementLeft 	= elementRight;
				elementBottom 	= Element(nodeBottomLeft, nodeBottomRight,obj.GetNextElementId());
				elementTop	 	= Element(nodeTopLeft, nodeTopRight,obj.GetNextElementId());
				elementRight 	= Element(nodeBottomRight, nodeTopRight,obj.GetNextElementId());

				% Critical for joined cells
				elementLeft.internal = true;
				
				obj.AddElementsToList([elementBottom, elementRight, elementTop]);

				ccm = GrowthContactInhibition(p, g, f, obj.dt);

				c = SquareCellJoined(ccm, [elementTop, elementBottom, elementLeft, elementRight], obj.GetNextCellId());
				c.cellType = epiCellType;
				obj.cellList(end + 1) = c;

			end

			% Set the boundary cells so it doesn't get the stromal cell
			bcs = obj.simData('boundaryCells');
			bcs.data = containers.Map({'left','right'}, {obj.cellList(1), obj.cellList(end)});
			

			%---------------------------------------------------
			% Make the cell that acts as the stroma
			%---------------------------------------------------
			stromaTop = -0.1;
			stromaBottom = -4;
			nodeList = Node.empty();

			% We add in twice as many edges along the top of the stroma as
			% there are cells in total.
			dx = (leftBoundary - rightBoundary)/(2*N);
			for x = rightBoundary:dx:leftBoundary
				nodeList(end + 1) = Node(x, stromaTop, obj.GetNextNodeId());
			end

			nodeList(end + 1) = Node(leftBoundary, stromaBottom, obj.GetNextNodeId());
			nodeList(end + 1) = Node(rightBoundary, stromaBottom, obj.GetNextNodeId());
			
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

			stroma.grownCellTargetArea = (rightBoundary - leftBoundary) * (stromaTop - stromaBottom);

			stroma.cellData('targetPerimeter') = TargetPerimeterStroma( 2 * (rightBoundary - leftBoundary) + 2 * (stromaTop - stromaBottom));

			obj.AddNodesToList( nodeList );
			obj.AddElementsToList( elementList );
			obj.cellList = [obj.cellList, stroma];

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
				   b,0]; % No attraction between epithelial cells or between stromal cells
			obj.AddNeighbourhoodBasedForce(CellTypeInteractionForce(att, repmat(b,2), repmat(dAsym,2), repmat(dSep,2), repmat(dLim,2), cellTypes, obj.dt, true));
			
			%---------------------------------------------------
			% Add space partition
			%---------------------------------------------------
			% In this simulation we are fixing the size of the boxes

			obj.boxes = SpacePartition(0.5, 0.5, obj);

			%---------------------------------------------------
			% Add the modfier to keep the stromal corner nodes
			% locked in place
			%---------------------------------------------------
			
			% nodeList comes from building the stroma
			obj.AddSimulationModifier(   PinNodes(  [nodeList(1), nodeList(end-2:end)]  )   );


			%---------------------------------------------------
			% Add the data writers
			%---------------------------------------------------

			obj.AddSimulationData(SpatialState());
			obj.pathName = sprintf('LayerOnStroma/n%gp%gg%gb%gsae%gspe%gf%gda%gds%gdl%galpha%gbeta%gt%g_seed%g/',N,p,g,b,sae,spe,f,dAsym,dSep, dLim, areaEnergy, perimeterEnergy, tensionEnergy, seed);
			obj.AddDataWriter(WriteSpatialState(20,obj.pathName));

			%---------------------------------------------------
			% All done. Ready to roll
			%---------------------------------------------------


			% A little hack to make the parameter sweeps slightly easier to handle
			obj.simulationOutputLocation = [getenv('EDGEDIR'),'/SimulationOutput/' obj.pathName];

		end

	end

end
