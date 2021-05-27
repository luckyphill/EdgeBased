classdef PlaneCellKiller < AbstractCellKiller
	% A class for killing Boundary cells.
	% Specify a plane and a direction
	% if the cell centre moves to the wrong side, then it is killed
	% The wrong side is specified by the direction of the normal

	properties

		point
		normal

	end
	methods

		function obj = PlaneCellKiller(point, normal)

			% We need a single point to specify the location in space
			% and a normal vector to specify the orientation of the plane

			obj.point = point;
			obj.normal = normal;

		end

		function killList = MakeKillList(obj, cellList)

			killList = AbstractCell.empty();

			for i = 1:length(cellList)
				c = cellList(i);
				if obj.IsCellPastPlane(c)
					% add to the list
					killList(end + 1) = c;
				end

			end

		end

		function past = IsCellPastPlane(obj,c)

			past = false;

			centre = c.GetCellCentre;

			AtoC = centre - obj.point;

			if dot(AtoC, obj.normal) > 0
				past = true;
			end

		end


	end


end