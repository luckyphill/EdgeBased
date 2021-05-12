classdef NodeCellArea < AbstractCellData
	% Calculates the area of the cell using 
	% neighbourhood searching

	properties 

		name = 'cellArea'
		data = []

		simulation

		dSC 	% The preferred separation distance to another cell
		dSM		% The preferred seapration distance to a membrane

	end

	methods

		function obj = NodeCellArea(simulation, dSC, dSM)
			
			% Need a pointer to the space simulation
			obj.simulation = simulation;

			obj.dSC = dSC;
			obj.dSM = dSM;

		end

		function CalculateData(obj, c)

			if ~isa(c, 'NodeCell')
				error('NCA:NotANode','Can only use NodeCellArea for NodeCells' );
			end

			eList = obj.simulation.boxes.GetNeighbouringElements(c.nodeList(1), obj.dSM);
			nList = obj.simulation.boxes.GetNeighbouringNodes(c.nodeList(1), obj.dSC);

			pos = c.nodeList.position;
			sepN = [];

			% [c.nodeList.id, c.age, c.CellCycleModel.colour, pos]
			% [nList.id]
			for i = 1:length(nList)

				% Don't use the nodes on an edge in the calculation
				if ~isa(nList(i).cellList, 'Membrane')
					posN = nList(i).position;
					% Divide by two because this is centre to centre distance
					% meaning it accounts for the radius of two cells
					sepN(end + 1) = norm(pos - posN)/2;
				end
			end

			sepE = [];
			for i = 1:length(eList)

				e = eList(i);
				
				posN1 = e.Node1.position;
				NtoN1 = pos - posN1;

				v = e.GetOutwardNormal();
				sepE(end + 1) = abs(dot(NtoN1, v));

			end

			% We assume that it takes a minimum of 6 sides to completely pack around a cell
			% This won't be true if there are growing cells neigbouring the cell of interest
			% but that gets really complicated.
			% Neighbouring nodes count for one side
			% First edge counts for two sides, each additional after that, only one. This implicitly
			% assumes that multiple edges are connected, and we don't have a case of two edges parallel
			% either side of the node

			% If there are fewer than 6 sides, the missing ones are assumed to be at the preferred
			% separation.

			% When all the sides are found, we average the distances in sepE and sepN and this
			% makes the average radius. The area is then pi*r^2

			nNSides = length(sepN);
			nESides = length(sepE) + ~isempty(sepE);

			nSides = nNSides + nESides;

			% [nNSides, nESides, nSides]

			freeSides = 0;
			if nSides < 6
				freeSides = 6 - nSides;
			end
			% [sepN, sepE, mean(sepE), obj.dSM*ones(1,freeSides) ]
			radius = nanmean(  [sepN, sepE, mean(sepE), obj.dSM*ones(1,freeSides) ]  );
			% [radius, pi*radius^2]
			obj.data = pi*radius^2;

		end
		
	end

end