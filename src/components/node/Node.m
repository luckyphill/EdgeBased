classdef Node < matlab.mixin.SetGet
	% A class specifying the details about nodes

	properties
		% Essential porperties of a node
		x
		y

		position

		previousPosition

		id

		force = [0, 0]

		previousForce = [0, 0]

		% This will be circular - each element will have two nodes
		% each node can be part of multiple elements, similarly for cells
		elementList = []

		cellList = []

		isTopNode

		% Each node stores it's local drag coefficient, so we can distinguish
		% between different regions in a tissue more easily
		eta = 1

		nodeAdjusted = false;
		preAdjustedPosition = [];

		nodeData

	end

	methods

		function obj = Node(x,y,id)
			% Initialise the node

			obj.x 	= x;
			obj.y 	= y;

			obj.position = [x,y];
			% Need to give the node a previous position so elements
			% can move to a new nox on the very first time step
			obj.previousPosition = [x,y];  
			
			obj.id 	= id;

			nodeData = [ElementNeighbours()];

		end

		function delete(obj)

			clear obj;

		end

		function AddForceContribution(obj, force)
			
			if sum(isnan(force)) || sum(isinf(force))
				error('N:AddForceContribution:InfNaN', 'Force is inf or NaN');
			end
			obj.force = obj.force + force;

		end

		function MoveNode(obj, pos)
			% This function is used to move the position due to time stepping
			% so the force must be reset here
			% This is only to be used by the numerical integration

			obj.NewPosition(pos);
			% Reset the force for next time step
			obj.previousForce = obj.force;
			obj.force = [0,0];

		end

		function AdjustPosition(obj, pos)
			% Used when modifying the position manually
			% Doesn't affect previous position, or reset the force
			% But it will require fixing up the space partition

			obj.preAdjustedPosition = obj.position;

			obj.position = pos;

			obj.x = pos(1);
			obj.y = pos(2);

			obj.nodeAdjusted = true;

		end

		function AddElement(obj, e)

			% e can be a vector
			if sum( ismember(e,obj.elementList)) ~=0
				warning('N:AddElement:ElementAlreadyHere', 'Adding at least one element that already appears in elementList for Node %d. This has not been added.', obj.id);
				e(ismember(e,obj.elementList)) = [];
			end
			obj.elementList = [obj.elementList , e];
			
		end

		function RemoveElement(obj, e)
			
			% Remove the element from the list
			if sum(obj.elementList == e) == 0
				warning('N:RemoveElement:ElementNotHere', 'Element %d does not appear in elementList for Node %d', e.id, obj.id);
			else
				obj.elementList(obj.elementList == e) = [];
			end

		end

		function ReplaceElementList(obj, eList)

			obj.elementList = eList;

		end

		function AddCell(obj, c)

			% c can be a vector
			if sum( ismember(c,obj.cellList)) ~=0
				warning('N:AddCell:CellAlreadyHere', 'Adding at least one cell that already appears in cellList for Node %d. This has not been added.', obj.id);
				c(ismember(c,obj.cellList)) = [];
			end
			obj.cellList = [obj.cellList , c];

		end

		function RemoveCell(obj, c)

			% Remove the cell from the list
			if sum(obj.cellList == c) == 0
				warning('N:RemoveCell:CellNotHere', 'At least one cell does not appear in nodeList for Node %d', obj.id);
			else
				obj.cellList(obj.cellList == c) = [];
			end

		end

		function ReplaceCellList(obj, cList)

			% Used for CellFree to overwrite the existing cell
			% Does not modify any links in the cell, it assumes
			% they are handled in the division or creation process

			obj.cellList = cList;

		end

		function SetDragCoefficient(obj, eta)

			% Use this to change the drag coefficient
			% so that the associated elements have their
			% properties updated
			obj.eta = eta;

			for i = 1:length(obj.elementList)

				obj.elementList(i).UpdateTotalDrag();

			end

		end

		function neighbours = GetNeighbouringElements(obj, t)
			% Used to find nodes that are in proximity
			% and are not explicitily connected to this node
			% The simulation managinf object must be passeed in
			% because this function needs access to the space partition

			neighbours = nodeData('elementNeighbours').GetData(obj, t);

		end

	end

	methods (Access = private)
		
		function NewPosition(obj, pos)

			% Should not be used directly, only as part of MoveNode
			obj.previousPosition = obj.position;
			obj.position = pos;

			obj.x = pos(1);
			obj.y = pos(2);

		end

	end


end
