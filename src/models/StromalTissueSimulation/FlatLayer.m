classdef FlatLayer < LineSimulation

	% A row of cells growing on a flat surface

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

		function obj = FlatLayer(w, p, g, b, f, seed)
			
			obj.SetRNGSeed(seed);

			epiCellType = 1;

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
			leftBoundary = 0;
			rightBoundary = w;

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

			nodeTopLeft 	= Node(0,cH,obj.GetNextNodeId());
			nodeBottomLeft 	= Node(0,0,obj.GetNextNodeId());
			nodeTopRight 	= Node(cW,cH,obj.GetNextNodeId());
			nodeBottomRight	= Node(cW,0,obj.GetNextNodeId());

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
				nodeTopRight 	= Node(i*cW,cH,obj.GetNextNodeId());
				nodeBottomRight	= Node(i*cW,0,obj.GetNextNodeId());
				

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
				% c.AddCellData(TargetPerimeterControlled(fadeTime,newPerimeter,grownPrimeter));

			end

			% Set the boundary cells so it doesn't get the stromal cell
			bcs = obj.simData('boundaryCells');
			bcs.data = containers.Map({'left','right'}, {obj.cellList(1), obj.cellList(end)});
			

			%---------------------------------------------------
			% Add in the forces
			%---------------------------------------------------

			% Cell growth force
			obj.AddCellBasedForce(PolygonCellGrowthForce(areaEnergy, perimeterEnergy, tensionEnergy));

			point = [0,-0.1];
			normal = [0,1];

			obj.AddTissueBasedForce(FlatPlaneForce(b, point, normal, dAsym, dSep, dLim));
			
			%---------------------------------------------------
			% Add space partition
			%---------------------------------------------------
			% In this simulation we are fixing the size of the boxes

			% obj.boxes = SpacePartition(0.5, 0.5, obj);
			obj.usingBoxes = false;

			%---------------------------------------------------
			% Add the modfier to keep the stromal corner nodes
			% locked in place
			%---------------------------------------------------

			%---------------------------------------------------
			% A modifier to help with the pinching issue
			%---------------------------------------------------

			obj.AddSimulationModifier(DivisionHack(1));


			%---------------------------------------------------
			% Add the data writers
			%---------------------------------------------------

			
			obj.pathName = sprintf('FlatLayer/w%gp%gg%gb%gf%gda%gds%gdl%galpha%gbeta%gt%gan%gag%gpn%gpg%g_seed%g/',w,p,g,b,f,dAsym,dSep, dLim, areaEnergy, perimeterEnergy, tensionEnergy, newArea, grownArea, newPerimeter, grownPrimeter, seed);

			obj.AddSimulationData(SpatialState());
			obj.AddDataWriter(WriteSpatialState(100,obj.pathName));
			% obj.AddSimulationData(TrackCellGeometry());
			% obj.AddDataWriter(WriteCellGeometry(1,obj.pathName));

			%---------------------------------------------------
			% All done. Ready to roll
			%---------------------------------------------------


			% A little hack to make the parameter sweeps slightly easier to handle
			obj.simulationOutputLocation = [getenv('EDGEDIR'),'/SimulationOutput/' obj.pathName];

		end

	end

end
