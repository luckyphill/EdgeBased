classdef NodeNeighbours < AbstractCellData
	% Calculates the wiggle ratio

	properties 

		name = 'nodeNeighbours'
		data = []
		radius = 0.1

	end

	methods

		function obj = NodeNeighbours(varargin)
			% Can give a radius or just use the default
			if length(varargin)
				obj.radius = varargin;
			end
		end

		function CalculateData(obj, n, t)
			% Node list must be in order around the cell

			obj.data = t.boxes.GetNeighbouringNodes(obj, n, obj.radius); 

		end
		
	end

end