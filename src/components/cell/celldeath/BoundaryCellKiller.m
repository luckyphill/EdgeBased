classdef BoundaryCellKiller < AbstractTissueLevelCellKiller
	% A class for killing Boundary cells.
	% This only kills cells when they move past a certain position
	% Can only be used in a LineSimulation
	properties

		leftBoundary
		rightBoundary

	end
	methods

		function obj = BoundaryCellKiller(leftBoundary, rightBoundary)

			if leftBoundary >= rightBoundary
				error('BCK:WrongOrder','Left boundary is further right than right boundary');
			end
			obj.leftBoundary = leftBoundary;
			obj.rightBoundary = rightBoundary;

		end

		function KillCells(obj, t)

			% Kills the cells at the boundary if requested
			bcs = t.simData('boundaryCells').GetData(t);
			leftCell = bcs('left');
			rightCell = bcs('right');

			while obj.IsPastLeftBoundary(leftCell)

				obj.RemoveLeftBoundaryCellFromSimulation(t);
                leftCell = bcs('left');

			end

			while obj.IsPastRightBoundary(rightCell)

				obj.RemoveRightBoundaryCellFromSimulation(t);
                rightCell = bcs('right');
			end

		end

		function past = IsPastLeftBoundary(obj, c)

			past = false;
			if c.nodeTopRight.x < obj.leftBoundary && c.nodeBottomRight.x < obj.leftBoundary
				past = true;
			end

		end

		function past = IsPastRightBoundary(obj, c)

			past = false;
			if c.nodeTopLeft.x > obj.rightBoundary && c.nodeBottomLeft.x > obj.rightBoundary
				past = true;
			end

		end

		function RemoveLeftBoundaryCellFromSimulation(obj, t)

			% This is used when a cell is removed on the boundary
			% A different method is needed when the cell is internal

			% Need to becareful to actually remove the nodes etc.
			% rather than just lose the links
			bcs = t.simData('boundaryCells').GetData(t);
			c = bcs('left');

			% bcs is the container.Map from BoundaryCells
			% apparently, this is actually a handle, so
			% changing it here modifies the value
			bcs('left') = c.elementRight.GetOtherCell(c);
			% t.simData('boundaryCells').SetData(bcs);
			% Clean up elements

			t.elementList(t.elementList == c.elementTop) = [];
			t.elementList(t.elementList == c.elementLeft) = [];
			t.elementList(t.elementList == c.elementBottom) = [];

			c.nodeTopRight.elementList( c.nodeTopRight.elementList ==  c.elementTop ) = [];
			c.nodeBottomRight.elementList( c.nodeBottomRight.elementList ==  c.elementBottom ) = [];

			c.nodeTopRight.cellList( c.nodeTopRight.cellList ==  c ) = [];
			c.nodeBottomRight.cellList( c.nodeBottomRight.cellList ==  c ) = [];

			c.elementRight.cellList(c.elementRight.cellList == c) = [];

			if t.usingBoxes
				t.boxes.RemoveElementFromPartition(c.elementTop);
				t.boxes.RemoveElementFromPartition(c.elementLeft);
				t.boxes.RemoveElementFromPartition(c.elementBottom);
			end

			c.elementTop.delete;
			c.elementLeft.delete;
			c.elementBottom.delete;
			
			% c.elementRight.internal = false; % Handled in the KillCells method of LineSImulatoin
			% Clean up nodes

			t.nodeList(t.nodeList == c.nodeTopLeft) = [];
			t.nodeList(t.nodeList == c.nodeBottomLeft) = [];

			if t.usingBoxes
				t.boxes.RemoveNodeFromPartition(c.nodeTopLeft);
				t.boxes.RemoveNodeFromPartition(c.nodeBottomLeft);
			end

			c.nodeTopLeft.delete;
			c.nodeBottomLeft.delete;

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

		function RemoveRightBoundaryCellFromSimulation(obj, t)

			% This is used when a cell is removed on the boundary
			% A different method is needed when the cell is internal

			% Need to becareful to actually remove the nodes etc.
			% rather than just lose the links

			bcs = t.simData('boundaryCells').GetData(t);
			c = bcs('right');

			% bcs is the container.Map from BoundaryCells
			% apparently, this is actually a handle, so
			% changing it here modifies the value
			bcs('right') = c.elementLeft.GetOtherCell(c);
			
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