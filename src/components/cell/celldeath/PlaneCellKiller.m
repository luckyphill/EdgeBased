classdef PlaneCellKiller < AbstractTissueLevelCellKiller
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

		function KillCells(obj, t)

			for i = length(t.cellList):-1:1
				c = t.cellList(i);
				if obj.IsCellPastPlane(c)
					% Kill the cell
					RemoveCellFromSimulation(obj, t, c);
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

		function RemoveCellFromSimulation(obj, t, c)

			
			% Clean up elements

			for i = 1:length(c.elementList)

				t.elementList(t.elementList == c.elementList(i)) = [];
				if t.usingBoxes
					% Shouldn't be handling this in the killer, but its here for now
					% because we need to remove the element from th partition before
					% it gets deleted
					t.boxes.RemoveElementFromPartition(c.elementList(i));
				end

				c.elementList(i).delete;

			end

			for i = 1:length(c.nodeList)

				t.nodeList(t.nodeList == c.nodeList(i)) = [];
				if t.usingBoxes
					t.boxes.RemoveNodeFromPartition(c.nodeList(i));
				end
				c.nodeList(i).delete;

			end


			% Clean up cell

			% Since the cell List for the tissue is heterogeneous, we can't use
			% t.cellList(t.cellList == c) = []; to delete the cell because 
			% "one or more inputs of class 'AbstractCell' are heterogeneous
			% and 'eq' is not sealed". I have no idea what this means, but
			% it is a quirk of matlab OOP we have to work around
			for i = length(t.cellList)
				oc = t.cellList(i);

				if oc == c
					t.cellList(i) = [];
					break;
				end

			end

			c.delete;

		end

	end


end