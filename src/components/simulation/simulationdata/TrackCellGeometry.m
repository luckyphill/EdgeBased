classdef TrackCellGeometry < AbstractSimulationData
	% Tracks the area and perimeter of a cell with the given index
	% in the cell list
	% If no cell death is present, this will track the same cell lineage
	% i.e. the given cell and all its decendent that take the originals place
	% If cell can die, then it will change upon death to the next cell lineage
	% in the cell list

	properties 

		name = 'cellGeometry'
		data = []
		idx
	end

	methods

		function obj = TrackCellGeometry(i)
			% The index in the cell list that we track
			
			obj.idx = i;
		end

		function CalculateData(obj, t)

			obj.data = [t.cellList(obj.idx).GetCellArea, t.cellList(obj.idx).GetCellTargetArea, t.cellList(obj.idx).GetCellPerimeter, t.cellList(obj.idx).GetCellTargetPerimeter];

		end
		
	end


end