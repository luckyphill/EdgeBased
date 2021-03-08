classdef PlaneCellKiller < AbstractTissueLevelCellKiller
	% A class for killing Boundary cells.
	% Specify a plane and a direction
	% if the cell centre moves to the wrong side, then it is killed
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

			for i = 1:length(t.cellList)
				if obj.IsCellPastPlane(t.cellList(i))
					% Kill the cell
					obj.EraseCellFromSimulation()
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

		function RemoveRightBoundaryCellFromSimulation(obj, t)

			
			% Clean up elements

			t.elementList(t.elementList == c.elementTop) = [];
			t.elementList(t.elementList == c.elementRight) = [];
			t.elementList(t.elementList == c.elementBottom) = [];

			c.nodeTopLeft.elementList( c.nodeTopLeft.elementList ==  c.elementTop ) = [];
			c.nodeBottomLeft.elementList( c.nodeBottomLeft.elementList ==  c.elementBottom ) = [];

			c.nodeTopLeft.cellList( c.nodeTopLeft.cellList ==  c ) = [];
			c.nodeBottomLeft.cellList( c.nodeBottomLeft.cellList ==  c ) = [];

			c.elementLeft.cellList(c.elementLeft.cellList == c) = [];

			if t.usingBoxes
				t.boxes.RemoveElementFromPartition(c.elementTop);
				t.boxes.RemoveElementFromPartition(c.elementRight);
				t.boxes.RemoveElementFromPartition(c.elementBottom);
			end

			c.elementTop.delete;
			c.elementRight.delete;
			c.elementBottom.delete;
			% c.elementLeft.internal = false; % Handled in the KillCells method of LineSImulatoin

			% Clean up nodes 

			t.nodeList(t.nodeList == c.nodeTopRight) = [];
			t.nodeList(t.nodeList == c.nodeBottomRight) = [];

			if t.usingBoxes
				t.boxes.RemoveNodeFromPartition(c.nodeTopRight);
				t.boxes.RemoveNodeFromPartition(c.nodeBottomRight);
			end

			c.nodeTopRight.delete;
			c.nodeBottomRight.delete;

			% Clean up cell

			% Since the cell List for the tissue is heterogeneous, we can't use
			% t.cellList(t.cellList == c) = []; to delete the cell because 
			% "one or more inputs of class 'AbstractCell' are heterogeneous
			% and 'eq' is not sealed". I have no idea what this means, but
			% it is a quirk of matlab OOP we have to work around
			for i = 1:length(t.cellList)
				oc = t.cellList(i);
				if strcmp(class( oc ), 'SquareCellJoined')
					if oc == c
						t.cellList(i) = [];
						break;
					end
				end
			end

			c.delete;

		end

	end


end