classdef DynamicLayer < LineSimulation

	% This simulation is the most basic - a simple row of cells growing on
	% a plate. It allows us to choose the number of initial cells
	% the force related parameters, and the cell cycle lengths

	properties

		dt = 0.002
		t = 0
		eta = 1

		timeLimit = 500

		samplingMultiple = 100;

		pathName
		simulationOutputLocation

	end

	methods

		function obj = DynamicLayer(w, p, g, b, f, sae, spe, seed)
			
			obj.SetRNGSeed(seed);

			epiCellType = 1;
			stromalCellType = 5;

			% w is the width of the domain
			% p, the pause/resting phase duration
			% g, the growing phase duration
			% b, The interaction spring force parameter
			% f the contact inhibition fraction

			% Contact inhibition fraction
			% f = 0.9;

			% The asymptote, separation, and limit distances for the interaction force
			dAsym = 0;
			dSep = 0.1;
			dLim = 0.2;

			% The energy densities for the cell growth force
			areaEnergy = 20;
			perimeterEnergy = 10;
			tensionEnergy = 0;

			% Chosen from empirical testing
			newArea = 0.55;
			grownArea = 1;
			newPerimeter = 3.4;
			grownPrimeter = 4;

			% This simulation only allows cells to exist in a limited x domain

			leftBoundary = -w/2;
			rightBoundary = w/2;

			k = BoundaryCellKiller(leftBoundary, rightBoundary);

			obj.AddTissueLevelKiller(k);

			%---------------------------------------------------
			% Make all the cells
			%---------------------------------------------------

			% The first cell needs all elements and nodes created
			% subsquent cells will have nodes and elements from their
			% neighbours

			% Make the nodes

			% Empirically determined to match the shape of cells due to 
			% an, ag, pn, pg
			cW = 0.4;
			cH = 1.3;

			nodeTopLeft 	= Node(leftBoundary,cH,obj.GetNextNodeId());
			nodeBottomLeft 	= Node(leftBoundary,0,obj.GetNextNodeId());
			nodeTopRight 	= Node(leftBoundary + cW,cH,obj.GetNextNodeId());
			nodeBottomRight	= Node(leftBoundary + cW,0,obj.GetNextNodeId());

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

			c.AddCellData(TargetAreaSpecified(newArea,grownArea));
			c.AddCellData(TargetPerimeterSpecified(newPerimeter,grownPrimeter));


			nCells = floor(w/cW);

			for i = 2:nCells
				% Each time we advance to the next cell, the right most nodes and element of the previous cell
				% become the leftmost element of the new cell

				nodeBottomLeft 	= nodeBottomRight;
				nodeTopLeft 	= nodeTopRight;
				nodeTopRight 	= Node(leftBoundary + i*cW,cH,obj.GetNextNodeId());
				nodeBottomRight	= Node(leftBoundary + i*cW,0,obj.GetNextNodeId());
				

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

				c.AddCellData(TargetAreaSpecified(newArea,grownArea));
				c.AddCellData(TargetPerimeterSpecified(newPerimeter,grownPrimeter));

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
			dx = (leftBoundary - rightBoundary)/(2*nCells);
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

			% A force to keep the cell corners square - hopefully to stop node jumping after division
			% obj.AddCellBasedForce(CornerForceCouple(cornerParameter,cornerAngle));

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
			% A modifier to help with the pinching issue
			%---------------------------------------------------

			obj.AddSimulationModifier(DivisionHack(1));


			%---------------------------------------------------
			% Add the data writers
			%---------------------------------------------------
			
			obj.pathName = sprintf('DynamicLayer/w%gp%gg%gb%gsae%gspe%gf%gda%gds%gdl%galpha%gbeta%gt%gan%gag%gpn%gpg%g_seed%g/',w,p,g,b,sae,spe,f,dAsym,dSep, dLim, areaEnergy, perimeterEnergy, tensionEnergy, newArea, grownArea, newPerimeter, grownPrimeter, seed);

			obj.AddSimulationData(SpatialState());
			obj.AddDataWriter(WriteSpatialState(100,obj.pathName));
			% obj.AddSimulationData(TrackCellGeometry());
			% obj.AddDataWriter(WriteCellGeometry(10,obj.pathName));

			%---------------------------------------------------
			% All done. Ready to roll
			%---------------------------------------------------


			% A little hack to make the parameter sweeps slightly easier to handle
			obj.simulationOutputLocation = [getenv('EDGEDIR'),'/SimulationOutput/' obj.pathName];

		end

	end

end
