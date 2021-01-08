classdef NodeSpatialState < AbstractSimulationData
	% Calculates the wiggle ratio

	properties 

		name = 'spatialState'
		data = {};

	end

	methods

		function obj = NodeSpatialState
			% No special initialisation
			
		end

		function CalculateData(obj, t)

			% In this case, the data is a structure containing all the node
			% positions, and a list of cells containing the nodes that make it up

			% At some point I want to add in elements as well, primarily for
			% when membrane is modelled, but I'll have to have a separate way
			% of handling a membrane object

			% This will only work when every cell has the same number of nodes
			% so it won't work with the stromal situation.
			% I will implement a way to introduce the stromal layer so it is separate
			% from the cell List

			nodeData = [[t.nodeList.id]',[t.nodeList.x]', [t.nodeList.y]'];

			cellData = {};

			for i = 1:t.GetNumCells()
				c = t.cellList(i);
				nL = c.nodeList;

				% A cell can have any number of nodes, but it's usually 4
				l = length(nL);
				% NaN is used to signify the end of a cell when writing to file
				% cellData(i,:) = [nL.id, c.CellCycleModel.colour];
				cellData{i} = [l, nL.id, c.CellCycleModel.colour];
			end

			obj.data = {nodeData, cellData};

		end
		
	end

end