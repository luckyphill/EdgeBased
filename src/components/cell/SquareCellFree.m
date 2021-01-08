classdef SquareCellFree < SquareCellJoined
	% A Square cell that does not explicitly need to be attached
	% to another cell. Interactions are handled by the 
	% neighbour node/element forces

	methods
		
		function obj = SquareCellFree(Cycle, elementList, id)
			
			obj = obj@SquareCellJoined(Cycle, elementList, id);

			obj.freeCell = true;

		end

		% Overwrite divide method to account for not being joined
		function [newCell, newNodeList, newElementList] = Divide(obj)
			% Divide cell when simulation is made of free cells
			% that are not constrained to be adjacent to others
			% To divide, split the top and bottom elements in half
			% add an element in the middle

			% This process needs to be done carefully to update all the new
			% links between node, element and cell

			%  o----------o
			%  |          |
			%  |          |
			%  |     1    |
			%  |          |
			%  |          |
			%  o----------o

			% Becomes

			%  o~~~~~x x-----o
			%  |     l l     |
			%  |     l l     |
			%  |  2  l l  1  |
			%  |     l l     |
			%  |     l l     |
			%  o~~~~~x x-----o

			% Links for everything in new cell will automatically be correct
			% but need to update links for old centre nodes and old centre edge
			% because they will point to the original cell


			% Find the new points for the nodes

			midTop 				= obj.elementTop.GetMidPoint;
			midBottom 			= obj.elementBottom.GetMidPoint;

			% The free cells will need to be separated by a set margin
			% but we don't want to make it so large that it will cause large forces
			% due to the new cells being smaller than their target area
			% This will be a balancing act between the neighbourhood interaction force
			% and the area + perimeter forces

			% Place the new nodes so they lie on the old top or bottom elements
			% Vectors point from cell 1 to cell 2

			topV = (obj.nodeTopLeft.position - obj.nodeTopRight.position) / obj.elementTop.GetLength();
			bottomV = (obj.nodeBottomLeft.position - obj.nodeBottomRight.position) / obj.elementBottom.GetLength();

			top1 = midTop - topV * obj.newFreeCellSeparation / 2;
			top2 = midTop + topV * obj.newFreeCellSeparation / 2;

			bottom1 = midBottom - bottomV * obj.newFreeCellSeparation / 2;
			bottom2 = midBottom + bottomV * obj.newFreeCellSeparation / 2;


			% Give -ve ids because id is a feature of the simulation
			% and can't be assigned here. This is handled in AbstractCellSimulation

			% Make the new nodes
			nodeTop1 		= Node(top1(1),top1(2),-1);
			nodeBottom1 	= Node(bottom1(1), bottom1(2),-2);

			nodeTop2 		= Node(top2(1),top2(2),-3);
			nodeBottom2 	= Node(bottom2(1), bottom2(2),-4);
			
			% Make the new elements,
			newLeft1		 	= Element(nodeTop1, nodeBottom1, -1);
			newRight2	 		= Element(nodeTop2, nodeBottom2, -2);
			newTop2			 	= Element(obj.nodeTopLeft, nodeTop2, -3);
			newBottom2		 	= Element(obj.nodeBottomLeft, nodeBottom2, -4);

			% Duplicate the cell cycle model from the old cell
			newCCM = obj.CellCycleModel.Duplicate();

			% Now we have all the parts we need to build the new cell in its correct position
			% The new cell will have the correct links with its constituent elements and nodes
			newCell = SquareCellFree(newCCM, [newTop2, newBottom2, obj.elementLeft, newRight2], -1);

			% Now we need to remodel the old cell and fix all the links

			% The old cell needs to change the links to the top left and bottom left nodes
			% and the left element
			% The old left element needs it's link to old cell (it already has a link to new cell)

			% The top and bottom elements stay with the old cell, but we need to replace the
			% left nodes with the new middle nodes. This function repairs the links from node
			% to cell
			obj.elementTop.ReplaceNode(obj.nodeTopLeft, nodeTop1);
			obj.elementBottom.ReplaceNode(obj.nodeBottomLeft, nodeBottom1);

			% Fix the link to the top left and bottom left nodes
			obj.nodeTopLeft.RemoveCell(obj);
			obj.nodeBottomLeft.RemoveCell(obj);

			% Theses process would be done automatically in a new cell
			% but need to be done manually here
			nodeTop1.AddCell(obj);
			nodeBottom1.AddCell(obj);

			obj.nodeTopLeft = nodeTop1;
			obj.nodeBottomLeft = nodeBottom1;


			% Old top left nodes are now replaced.

			% Now to fix the links with the new left element and old left element

			% At this point, old left element still links to old cell (and vice versa), and new left element
			% only links to new cell.

			obj.elementLeft.RemoveCell(obj);
			obj.elementLeft = newLeft1;

			newLeft1.AddCell(obj);
						

			% Old cell should be completely remodelled by this point, adjust the age back to zero

			obj.CellCycleModel.SetAge(0);
			obj.age = 0;

			% Reset the node list for this cell
			obj.nodeList = [obj.nodeBottomLeft, obj.nodeBottomRight, obj.nodeTopRight, obj.nodeTopLeft];
			obj.elementList = [obj.elementBottom, obj.elementRight, obj.elementTop, obj.elementLeft];

			% Make a list of new nodes and elements
			newNodeList 	= [nodeTop1, nodeTop2, nodeBottom1, nodeBottom2];
			newElementList	= [newLeft1, newRight2, newTop2, newBottom2];

			% Update the sister cells
			newCell.sisterCell = obj;
			obj.sisterCell = newCell;
			% ...and ancestorId
			newCell.ancestorId = obj.id;
		
		end

	end

end