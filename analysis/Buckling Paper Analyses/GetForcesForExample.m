classdef GetForcesForExample < LineSimulation

	% Aborted, can do the intended calculations in a script controlling the actual
	% simulation I used

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

		function obj = GetForcesForExample


			% The energy densities for the cell growth force
			areaEnergy = 20;
			perimeterEnergy = 10;
			tensionEnergy = 0;

			newArea = an;
			grownArea = ag;
			newPerimeter = pn;
			grownPrimeter = pg;
 
			x = [1.336,2.092,2.115,1.439]; %tl,tr,br,bl
			y = [1.204,1.337,-0.0491,-0.0278]);

			x1 = [1.336,1.714,1.777,1.439];
			y1 = [1.204,1.2705,-0.03845,-0.0278]);

			x2 = [1.714,2.092,2.115,1.777];
			y2 = [1.2705,1.337,-0.0491,-0.03845]);


			%---------------------------------------------------
			% Make all the cells
			%---------------------------------------------------

			% The first cell needs all elements and nodes created
			% subsquent cells will have nodes and elements from their
			% neighbours

			% Make the nodes

			nodeTopLeft 	= Node(x(1),y(1),obj.GetNextNodeId());
			nodeTopRight 	= Node(x(2),y(2),obj.GetNextNodeId());
			nodeBottomRight	= Node(x(3),y(3),obj.GetNextNodeId());
			nodeBottomLeft 	= Node(x(4),y(4),obj.GetNextNodeId());
			

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


			% c.AddCellData(TargetAreaSpecified(newArea,grownArea));
			% c.AddCellData(TargetPerimeterSpecified(newPerimeter,grownPrimeter));
			% c.AddCellData(TargetPerimeterControlled(fadeTime,newPerimeter,grownPrimeter));


			
			%---------------------------------------------------
			% Add in the forces
			%---------------------------------------------------

			% Cell growth force
			obj.AddCellBasedForce(PolygonCellGrowthForce(areaEnergy, perimeterEnergy, tensionEnergy));





		end

	end

end
