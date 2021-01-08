classdef SpacePartition < matlab.mixin.SetGet
	% This class holds a space partition for all the nodes
	% in a simulation. It distributes each node into a box
	% based on its spatial position. This will help to minimise
	% the space searching effort needed to find collisions
	% and resolve them

	% The partition is regular, so that the width and height of each
	% box is the same, called dx and dy. A node can instantly work
	% out which box it is in by taking the integer part of x/dx and y/dy.
	% However, we also need a place to store all the nodes that are
	% in the same box, so they can be compared for interactions.

	% There are two main operations to perform here. The first is
	% move nodes between boxes, and the second is to query neighbours.
	% Depending on where the node is precisely found, the neighbours
	% will either be found in the same box, or an adjacent box
	% and nowhere else.

	% This will also need to store which boxes an element passes
	% through, in order to work out the node-edge interactions.
	% Setting and moving the edge boxes will take a bit more work.

	% We use matlab arrays to store the box contents, and we use a
	% bit of trickery to allow -ve indices

	% All of the box handling process will be done in the cell simulation
	% this just implements the processes the simulation will call

	properties

		% Each quadrant is part of the cartesian plane
		% 1: (+,+)
		% 2: (+,-)
		% 3: (-,-)
		% 4: (-,+)

		% nodesQ and elementsQ are cell vectors 
		% containing the 4 quadrants
		% The index matches to the quadrant number
		% Each quadrant is a cell matrix that matches
		% the actual box location.
		% Each box is a cell vector of nodes or elements
		% So, all in all they are cell vectors of cell arrays
		% of vectors
		nodesQ = {{},{},{},{}}
		elementsQ = {{},{},{},{}}

		% The size of the cell arrays is dynamic, so will be
		% regularly reallocated as the simulation progresses
		% This could cause issues as the simulation gets large
		% but I'm not aware of a manual way to deal with growing
		% arrays in matlab properly, but preallocating will help

		% These are the lengths of the box edges
		dx
		dy

		% A pointer to the simulation
		simulation

		% A flag stating if the partition will search only the boxes
		% that a node is in or close to, rather than all 8 surrounding
		% boxes. For small dx,dy in comparision to the average element
		% length, taking all 8 will probably be more efficient than
		% specifying the precise boxes. If the boxes are quite large
		% or the elements and nodes are quite dense, this should be set
		% to true, as it will reduce the number of comparison operations

		onlyBoxesInProximity = true;


	end


	methods
		
		function obj = SpacePartition(dx, dy, t)
			
			% Need to pass in a cell simulation to initialise
			obj.dx = dx;
			obj.dy = dy;
			obj.simulation = t;

			for i = 1:length(t.nodeList)
				obj.PutNodeInBox(t.nodeList(i));
			end

			for i=1:length(t.elementList)
				% If the element is an internal element, skip it
				% because they don't interact with nodes
				
				e = t.elementList(i);
				if ~e.IsElementInternal()
					obj.PutElementInBoxes(e);
				end
			end

		end

		function neighbours = GetNeighbouringElements(obj, n, r)

			% The pinacle of this piece of code
			% A function that (hopefully) efficiently finds
			% the set of elements that are within a distance r
			% of the node n

			% There are two stages
			% 1. Get the candidate elements. This includes
			% grabbing elements from adjacent boxes if the
			% node is close to a box boundary
			% 2. Calculate the distances to each candidate
			% element. This involves making sure the node
			% is within the range of the element

			% The elements are assembled into a vector

			% First off, get the elements in the same box


			b = [];
			
			if obj.onlyBoxesInProximity
				b = obj.AssembleCandidateElements(n, r);
			else
				b = obj.GetAllAdjacentElementBoxes(n);
			end

			neighbours = Element.empty();

			for i = 1:length(b)

				e = b(i);

				u = e.GetVector1to2();
				v = e.GetOutwardNormal();

				% Make box around element
				% determine if node is in that box

				n1 = e.Node1;
				n2 = e.Node2;

				p1 = n1.position + v * r;
				p2 = n1.position - v * r;
				p3 = n2.position - v * r;
				p4 = n2.position + v * r;

				x = [p1(1), p2(1), p3(1), p4(1)];
				y = [p1(2), p2(2), p3(2), p4(2)];

				% Inside includes on the boundary
				[inside, on] = inpolygon(n.x, n.y, x ,y);

				if inside
					neighbours(end+1) = e;
				end

			end
			
		end

		function neighbours = GetNeighbouringNodes(obj, n1, r)

			% Given the node n and the radius r find all the nodes
			% that are neighbours

			b = [];
			
			if obj.onlyBoxesInProximity
				b = obj.AssembleCandidateNodes(n1, r);
			else
				b = obj.GetAllAdjacentNodeBoxes(n1);
			end

			neighbours = Node.empty();

			for i = 1:length(b)

				n2 = b(i);

				n1ton2 = n2.position - n1.position;

				d = norm(n1ton2);

				if d < r
					neighbours(end + 1) = n2;
				end

			end

		end

		function [neighboursE, neighboursN] = GetNeighbouringNodesAndElements(obj, n, r)

			% Finds the neighbouring nodes and elements at the same
			% time, taking account of obtuse angled element pairs
			% necessitating node-node interactions

			b = [];

			if obj.onlyBoxesInProximity
				b = obj.AssembleCandidateElements(n, r);
			else
				b = obj.GetAllAdjacentElementBoxes(n);
			end

			neighboursN = Node.empty();
			neighboursE = Element.empty();

			for i = 1:length(b)

				e = b(i);

				u = e.GetVector1to2();
				v = e.GetOutwardNormal();

				% Make box around element
				% determine if node is in that box

				n1 = e.Node1;
				n2 = e.Node2;

				p1 = n1.position + v * r;
				p2 = n1.position - v * r;
				p3 = n2.position - v * r;
				p4 = n2.position + v * r;

				x = [p1(1), p2(1), p3(1), p4(1)];
				y = [p1(2), p2(2), p3(2), p4(2)];

				% Inside includes on the boundary
				[inside, on] = inpolygon(n.x, n.y, x, y);


				if inside
					neighboursE(end+1) = e;

					% If the node is determined to interact with an element
					% we need to make sure we remove any instances of it interacting
					% with any of the elements end nodes.

					neighboursN(neighboursN == e.Node1) = [];
					neighboursN(neighboursN == e.Node2) = [];
				else
					% If the node is not inside the element interaction box
					% then it might be in the node interaction wedge
					% Need to determine if which (if any) of the elements
					% nodes are in proximity to the node in question

					n1 = e.Node1;
					n2 = e.Node2;

					nton1 = n1.position - n.position;
					nton2 = n2.position - n.position;

					d1 = norm(nton1);
					d2 = norm(nton2);

					if d1 < r
						neighboursN(end + 1) = n1;
					end

					if d2 < r
						neighboursN(end + 1) = n2;
					end

				end

			end

			neighboursN = obj.QuickUnique(neighboursN);
			
		end

		function b = GetAllAdjacentElementBoxes(obj, n);

			% Grab all potential elements from the 8 adjacent boxes

			b = obj.GetElementBoxFromNode(n);
			b = [b, obj.GetAdjacentElementBoxFromNode(n, [-1, 0])];
			b = [b, obj.GetAdjacentElementBoxFromNode(n, [-1, -1])];
			b = [b, obj.GetAdjacentElementBoxFromNode(n, [0, -1])];
			b = [b, obj.GetAdjacentElementBoxFromNode(n, [1, -1])];
			b = [b, obj.GetAdjacentElementBoxFromNode(n, [1, 0])];
			b = [b, obj.GetAdjacentElementBoxFromNode(n, [1, 1])];
			b = [b, obj.GetAdjacentElementBoxFromNode(n, [0, 1])];
			b = [b, obj.GetAdjacentElementBoxFromNode(n, [-1, 1])];

			% Remove duplicates
			% Must do this because elements can be in multiple boxes
			b = obj.QuickUnique(b);

			% Remove nodes own elements
			for i = 1:length(n.elementList)
				b(b==n.elementList(i)) = [];
			end

			% Remove elements from the cell the node is in
			% it doesn't interact with them except indirectly
			% via a volume force
			for j = 1:length(n.cellList)
				eL = n.cellList(j).elementList;
				for i = 1:length(eL)
					b(b==eL(i)) = [];
				end
			end

		end

		function b = GetAllAdjacentNodeBoxes(obj, n);

			% Grab all potential Nodes from the 8 adjacent boxes

			b = obj.GetNodeBoxFromNode(n);
			b = [b, obj.GetAdjacentNodeBoxFromNode(n, [-1, 0])];
			b = [b, obj.GetAdjacentNodeBoxFromNode(n, [-1, -1])];
			b = [b, obj.GetAdjacentNodeBoxFromNode(n, [0, -1])];
			b = [b, obj.GetAdjacentNodeBoxFromNode(n, [1, -1])];
			b = [b, obj.GetAdjacentNodeBoxFromNode(n, [1, 0])];
			b = [b, obj.GetAdjacentNodeBoxFromNode(n, [1, 1])];
			b = [b, obj.GetAdjacentNodeBoxFromNode(n, [0, 1])];
			b = [b, obj.GetAdjacentNodeBoxFromNode(n, [-1, 1])];

			% Remove the node itself
			b(b==n) = [];

		end

		function b = AssembleCandidateElements(obj, n, r)

			b = obj.GetElementBoxFromNode(n);

			% Then check if the node is near a boundary

			% Need to decide if the process of check is more effort than
			% just taking the adjacent boxes always, even when the node is
			% in the middle of its box


			% Check sides
			if floor(n.x/obj.dx) ~= floor((n.x-r)/obj.dx)
				% Close to left
				b = [b, obj.GetAdjacentElementBoxFromNode(n, [-1, 0])];
			end

			if floor(n.x/obj.dx) ~= floor((n.x+r)/obj.dx)
				% Close to right
				b = [b, obj.GetAdjacentElementBoxFromNode(n, [1, 0])];
			end

			if floor(n.y/obj.dx) ~= floor((n.y-r)/obj.dx)
				% Close to bottom
				b = [b, obj.GetAdjacentElementBoxFromNode(n, [0, -1])];
			end

			if floor(n.y/obj.dx) ~= floor((n.y+r)/obj.dx)
				% Close to top
				b = [b, obj.GetAdjacentElementBoxFromNode(n, [0, 1])];
			end


			if ( floor(n.x/obj.dx) ~= floor((n.x-r)/obj.dx) ) && ( floor(n.y/obj.dx) ~= floor((n.y-r)/obj.dx) )
				% Close to left bottom
				b = [b, obj.GetAdjacentElementBoxFromNode(n, [-1, -1])];
			end

			if ( floor(n.x/obj.dx) ~= floor((n.x+r)/obj.dx) ) && ( floor(n.y/obj.dx) ~= floor((n.y-r)/obj.dx) )
				% Close to right bottom
				b = [b, obj.GetAdjacentElementBoxFromNode(n, [1, -1])];
			end

			if ( floor(n.x/obj.dx) ~= floor((n.x-r)/obj.dx) ) && ( floor(n.y/obj.dx) ~= floor((n.y+r)/obj.dx))
				% Close to left top
				b = [b, obj.GetAdjacentElementBoxFromNode(n, [-1, 1])];
			end

			if ( floor(n.x/obj.dx) ~= floor((n.x+r)/obj.dx) ) && ( floor(n.y/obj.dx) ~= floor((n.y+r)/obj.dx)) 
				% Close to right top
				b = [b, obj.GetAdjacentElementBoxFromNode(n, [1, 1])];
			end

			% Checking diagonally not needed for elements when box side length
			% is about the same size as the maximum element length since the
			% element will almost certainly be in an adjacent box

			% If the box size is much smaller than the max element length
			% then it is most likely easier to not check at all, and just
			% add the adjacent boxes


			% Remove duplicates
			% Must do this because elements can be in multiple boxes
			% b = unique(b);
			b = obj.QuickUnique(b);

			% Remove nodes own elements
			for i = 1:length(n.elementList)
				b(b==n.elementList(i)) = [];
			end

			% Remove elements from the cell the node is in
			% it doesn't interact with them except indirectly
			% via a volume force
			for j = 1:length(n.cellList)
				eL = n.cellList(j).elementList;
				for i = 1:length(eL)
					b(b==eL(i)) = [];
				end
			end

		end

		function b = AssembleCandidateNodes(obj, n, r)

			b = obj.GetNodeBoxFromNode(n);

			% Then check if the node is near a boundary

			% All this checking might be more effort than it's worth...

			% Check sides
			if floor(n.x/obj.dx) ~= floor((n.x-r)/obj.dx)
				% Close to left
				b = [b, obj.GetAdjacentNodeBoxFromNode(n, [-1, 0])];
			end

			if floor(n.x/obj.dx) ~= floor((n.x+r)/obj.dx)
				% Close to right
				b = [b, obj.GetAdjacentNodeBoxFromNode(n, [1, 0])];
			end

			if floor(n.y/obj.dx) ~= floor((n.y-r)/obj.dx)
				% Close to bottom
				b = [b, obj.GetAdjacentNodeBoxFromNode(n, [0, -1])];
			end

			if floor(n.y/obj.dx) ~= floor((n.y+r)/obj.dx)
				% Close to top
				b = [b, obj.GetAdjacentNodeBoxFromNode(n, [0, 1])];
			end

			% Check corners

			if ( floor(n.x/obj.dx) ~= floor((n.x-r)/obj.dx) ) && ( floor(n.y/obj.dx) ~= floor((n.y-r)/obj.dx) )
				% Close to left bottom
				b = [b, obj.GetAdjacentNodeBoxFromNode(n, [-1, -1])];
			end

			if ( floor(n.x/obj.dx) ~= floor((n.x+r)/obj.dx) ) && ( floor(n.y/obj.dx) ~= floor((n.y-r)/obj.dx) )
				% Close to right bottom
				b = [b, obj.GetAdjacentNodeBoxFromNode(n, [1, -1])];
			end

			if ( floor(n.x/obj.dx) ~= floor((n.x-r)/obj.dx) ) && ( floor(n.y/obj.dx) ~= floor((n.y+r)/obj.dx))
				% Close to left top
				b = [b, obj.GetAdjacentNodeBoxFromNode(n, [-1, 1])];
			end

			if ( floor(n.x/obj.dx) ~= floor((n.x+r)/obj.dx) ) && ( floor(n.y/obj.dx) ~= floor((n.y+r)/obj.dx)) 
				% Close to right top
				b = [b, obj.GetAdjacentNodeBoxFromNode(n, [1, 1])];
			end

			b(b==n) = [];

		end

		function b = QuickUnique(obj, b)
			% Test to see if I can do the unique check quicker without
			% needing all the bells and whistles - it can by a factor of 2

			% Is there a more efficient way when the most repetitions is 3?
			if ~isempty(b)
				b = sort(b);

				% If there are repeated elements, they will be adjacent after sorting
				Lidx = b(1:end-1) ~= b(2:end);
				Lidx = [Lidx, true];
				b = b(Lidx);
			end

		end

		function PutNodeInBox(obj, n)

			[q,i,j] = obj.GetQuadrantAndIndices(n.x,n.y);

			obj.InsertNode(q,i,j,n);

		end

		function PutElementInBoxes(obj, e)

			% Given the list of elements that a given node
			% is part of, distribute the elements to the element
			% boxes. This will require putting elements in 
			% intermediate boxes too

			n1 = e.Node1;
			n2 = e.Node2;

			[Q,I,J] = GetBoxIndicesBetweenNodes(obj, n1, n2);

			for j = 1:length(Q)

				obj.InsertElement(Q(j),I(j),J(j),e);
				
			end

		end

		function b = GetNodeBoxFromNode(obj, n)
			% Returns the same box that n is in
			[q,i,j] = obj.GetQuadrantAndIndices(n.x,n.y);

			try
				b = obj.nodesQ{q}{i,j};
			catch
				error('SP:GetNodeBoxFromNode:Missing','Node doesnt exist where expected in the partition');
			end
		
		end

		function b = GetElementBoxFromNode(obj, n)
			% Returns the same box that n is in
			[q,i,j] = obj.GetQuadrantAndIndices(n.x,n.y);

			b = [];

			try
				b = obj.elementsQ{q}{i,j};
			catch
				error('SP:GetElementBoxFromNode:Missing','Elements dont exist where expected in the partition');
			end
		
		end

		function [q,i,j] = GetAdjacentIndicesFromNode(obj, n, direction)

			% direction = [a, b]
			% where a,b = 1 or -1
			% 1 indicates an increase in the global index etc.
			% a is applied to I and b applied to J

			b = [];
			a = direction(1);
			c = direction(2);
			[q,i,j] = obj.GetQuadrantAndIndices(n.x,n.y);
			[I, J] = obj.ConvertToGlobal(q,i,j);

			I = I + a;
			J = J + c;

			% This is needed because matlab doesn't index from 0!!!!!!!!!!!!!!!!!

			if I == 0; I = a; end
			if J == 0; J = c; end

			[q,i,j] = obj.ConvertToQuadrant(I,J);

		end

		function b = GetAdjacentNodeBoxFromNode(obj, n, direction)

			% Returns the node box adjacent to the one indicated
			% specifying the directionection

			[q,i,j] = obj.GetAdjacentIndicesFromNode(n, direction);

			b = [];

			try
				b = obj.nodesQ{q}{i,j};
			catch ME
				if ~strcmp(ME.identifier,'MATLAB:badsubscript')
					error('SP:GetAdjacentNodeBox','Assignment didnt fail properly');
				end
			end

		end

		function b = GetAdjacentElementBoxFromNode(obj, n, direction)

			% Returns the node box adjacent to the one indicated
			% specifying the directionection

			[q,i,j] = obj.GetAdjacentIndicesFromNode(n, direction);

			b = [];
			
			try
				b = obj.elementsQ{q}{i,j};
			catch ME
				if ~strcmp(ME.identifier,'MATLAB:badsubscript')
					error('SP:GetAdjacentElementBox','Assignment didnt fail properly');
				end
			end

		end

		function [qp,ip,jp] = GetBoxIndicesBetweenPoints(obj, pos1, pos2)

			% Given two points, we want all the indices between them
			% in order to determine which boxes an element needs to go in

			[q1,i1,j1] = obj.GetQuadrantAndIndices(pos1(1),pos1(2));
			[q2,i2,j2] = obj.GetQuadrantAndIndices(pos2(1),pos2(2));

			[qp,ip,jp] = obj.MakeElementBoxList(q1,i1,j1,q2,i2,j2);

		end

		function [ql,il,jl] = GetBoxIndicesBetweenNodes(obj, n1, n2)

			% Given two nodes, we want all the indices between them
			[ql,il,jl] = obj.GetBoxIndicesBetweenPoints(n1.position, n2.position);

		end

		% Redundant
		function [qp,ip,jp] = GetBoxIndicesBetweenNodesPrevious(obj, n1, n2)

			% Given two nodes, we want all the indices between their previous positions
			if isempty(n1.previousPosition) || isempty(n2.previousPosition)
				error('SP:GetBoxIndicesBetweenNodesPrevious:NoPrevious', 'There has not been a previous position');
			end

			[qp,ip,jp] = obj.GetBoxIndicesBetweenPoints(n1.previousPosition, n2.previousPosition);

		end

		function [qp,ip,jp] = GetBoxIndicesBetweenNodesPreviousCurrent(obj, n1, n2)

			% Given two nodes, we want all the indices between n1s previous
			% and n2s current positions
			if isempty(n1.previousPosition)
				error('SP:GetBoxIndicesBetweenNodesPrevious:NoPrevious', 'There has not been a previous position');
			end

			[qp,ip,jp] = obj.GetBoxIndicesBetweenPoints(n1.previousPosition, n2.position);

		end

		function [ql,il,jl] = MakeElementBoxList(obj,q1,i1,j1,q2,i2,j2)

			% This method for finding the boxes that we should put the
			% elements in is not exact.
			% An exact method will get exactly the right boxes and no more
			% but as a consequence, will need to be checked at every time
			% step, which can slow things down. An exact method might be better
			% when the box size is quite small in relation to the max
			% element length.
			% An exact method transverses the vector beteen the ttwo nodes
			% and calculates the position where it crosses the box
			% boundaries. It uses this to know which box to add the element to

			% A non exact method will look at all the possible boxes the element 
			% could pass through, given that we only know which boxes its end
			% points are in. This will only need to be updated when
			% a node moves to a new box.

			% The non exact method used here is probably the greediest method
			% and the least efficient in a small box case, but is quick, and
			% arrives at the same answer when the boxes are the large, hence
			% it is kept for now.

			% To find the boxes that the element could pass through
			% it is much simpler to convert to global indices, then
			% back to quadrants
			[I1, J1] = obj.ConvertToGlobal(q1,i1,j1);
			[I2, J2] = obj.ConvertToGlobal(q2,i2,j2);


			if I1<I2; Il = I1:I2; else; Il = I2:I1; end
			if J1<J2; Jl = J1:J2; else; Jl = J2:J1; end

			% Once again, I need to hack a solution because matlab
			% decided to index from 1..........
			Il(Il==0) = [];
			Jl(Jl==0) = [];

			% This method will always produce a rectangular grid
			% of boxes which may be many times more than is needed
			% when the box size is small compared to the element length
			% This is an area for optimisation
			% In reality though, the box size probably won't be that small
			% so it should be ok
			[p,q] = meshgrid(Il, Jl);
			Il = p(:);
			Jl = q(:);

			[ql,il,jl] = obj.ConvertToQuadrant(Il,Jl);

		end

		function UpdateBoxForNode(obj, n)

			if isempty(n.previousPosition)
				error('SP:UpdateBoxForNode:NoPrevious', 'There has not been a previous position');
			end

			[qn,in,jn] = obj.GetQuadrantAndIndices(n.x,n.y);
			[qo,io,jo] = obj.GetQuadrantAndIndices(n.previousPosition(1),n.previousPosition(2));

			if ~prod([qn,in,jn] == [qo,io,jo])
				% The given node is in a different box compared to
				% the previous timestep/position, so need to do some adjusting

				obj.InsertNode(qn,in,jn,n);

				obj.nodesQ{qo}{io,jo}( obj.nodesQ{qo}{io,jo} == n ) = [];

				% Also need to adjust the elements
				obj.UpdateBoxesForElementsUsingNode(n);

			end

		end

		function UpdateBoxForNodeAdjusted(obj, n)

			% Used when manually moving a node to a new position
			% a special method is needed since previousPosition is
			% not changed in this propcess

			[qn,in,jn] = obj.GetQuadrantAndIndices(n.x,n.y);
			[qo,io,jo] = obj.GetQuadrantAndIndices(n.preAdjustedPosition(1),n.preAdjustedPosition(2));

			if ~prod([qn,in,jn] == [qo,io,jo])
				% The given node is in a different box compared to
				% the previous timestep/position, so need to do some adjusting

				obj.InsertNode(qn,in,jn,n);

				obj.nodesQ{qo}{io,jo}( obj.nodesQ{qo}{io,jo} == n ) = [];

				% Also need to adjust the elements
				obj.UpdateBoxesForElementsUsingNodeAdjusted(n);

			end

			n.nodeAdjusted = false;
			n.preAdjustedPosition = [];

		end

		function UpdateBoxesForElementsUsingNode(obj, n1)

			% This function will be used as each node is moved
			% As such, we know the node n1 has _just_ moved therefore
			% we need to look at the current position and the previous
			% position to see which boxes need changing
			% We know nothing about the other nodes of the elements
			% so at this point we just assume they are in their final
			% position. This will cause doubling up of effort if both
			% nodes end up moving to a new box, but this should be
			% fairly rare occurrance.

			% Logic of processing:
			% If the node n1 is the first one from an element to move
			% boxes, then we use the current position for n2
			% If node n1 is the second to move, then the current position
			% for n2 will still be the correct to use

			for i=1:length(n1.elementList)
				% If the element is an internal element, skip it
				% because they don't interact with nodes
				
				e = n1.elementList(i);
				if ~e.IsElementInternal()

					n2 = e.GetOtherNode(n1);

					[qn,in,jn] = obj.GetBoxIndicesBetweenNodes(n1, n2);
					[qo,io,jo] = obj.GetBoxIndicesBetweenNodesPreviousCurrent(n1, n2);

					new = [qn,in,jn];
					old = [qo,io,jo];

					obj.MoveElementToNewBoxes(old, new, e);

				end

			end

		end

		function UpdateBoxesForElementsUsingNodeAdjusted(obj, n1)

			% This function does the same as UpdateBoxesForElementsUsingNode
			% when the given node is moved by adjusting it's position manually
			if n1.nodeAdjusted
				for i=1:length(n1.elementList)
					% If the element is an internal element, skip it
					% because they don't interact with nodes
					
					e = n1.elementList(i);
					if ~e.IsElementInternal()

						n2 = e.GetOtherNode(n1);

						[qn,in,jn] = obj.GetBoxIndicesBetweenNodes(n1, n2);
						[qo,io,jo] = obj.GetBoxIndicesBetweenPoints(n1.preAdjustedPosition, n2.position);

						new = [qn,in,jn];
						old = [qo,io,jo];

						obj.MoveElementToNewBoxes(old, new, e);

					end

				end
			else
				warning('SP:UpdateBoxesAdjusted:NotAdjusted', 'Node %d has not been adjusted, this will do nothing', n1.id);
			end

		end

		% Redundant
		function UpdateBoxesForElement(obj, e)

			% This function will be run in the simulation
			% It will be done after all the nodes have moved

			% This check should really be done in the simulation
			% but this is the only good spot to do it
			if ~e.IsElementInternal() 

				n1 = e.Node1;
				n2 = e.Node2;
				if obj.IsNodeInNewBox(n1) || obj.IsNodeInNewBox(n2)
					[ql,il,jl] = obj.GetBoxIndicesBetweenNodes(n1, n2);
					[qp,ip,jp] = obj.GetBoxIndicesBetweenNodesPrevious(n1, n2);

					% If the box appears in both, nothing needs to change
					% If it only appears in previous, remove element
					% If it only appears in current, add element

					new = [ql,il,jl];
					old = [qp,ip,jp];

					obj.MoveElementToNewBoxes(old, new, e);

				end

			end

		end

		function MoveElementToNewBoxes(obj, old, new, e)

			% Old is the set of boxes the element used to be in
			% new is the set that it should be in now

			ql = new(:,1);
			il = new(:,2);
			jl = new(:,3);

			qp = old(:,1);
			ip = old(:,2);
			jp = old(:,3);

			% Get the unique new boxes
			J = ~ismember(new,old,'rows');
			% And get the indices to add

			qa = ql(J);
			ia = il(J);
			ja = jl(J);
			
			for j = 1:length(qa)
				obj.InsertElement(qa(j),ia(j),ja(j),e);
			end

			% Get the old boxes
			J = ~ismember(old,new,'rows');
			% ... and the indices to remove
			qt = qp(J);
			it = ip(J);
			jt = jp(J);
			for j = 1:length(qt)
				obj.RemoveElementFromBox(qt(j),it(j),jt(j),e);
			end

		end

		function InsertNode(obj,q,i,j,n)

			% This is the sensible way to do this, but it doesn't always
			% work properly
			% if i > size(obj.nodesQ{q},1) || j > size(obj.nodesQ{q},2)
			% 	obj.nodesQ{q}{i,j} = [n];
			% else
			% 	obj.nodesQ{q}{i,j}(end + 1) = n;
			% end

			% I know it's bad practice to make the work flow work from an error
			% but it doesn't work the proper way if the box exists, but is empty
			% and you want to make sure the node doesn't already exist in there
			try
				if sum(obj.nodesQ{q}{i,j} == n) == 0
					obj.nodesQ{q}{i,j}(end + 1) = n;
				else
					% Node already in box
					% Maybe put a warning here, but I think it should be ok
				end
			catch ME
				if (strcmp(ME.identifier,'MATLAB:badsubscript'))
					obj.nodesQ{q}{i,j} = [n];
				else
					error('SP:InsertNode:WrongFail','Assignment didnt fail properly');
				end
			end

		end

		function InsertElement(obj,q,i,j,e)


			try
				if sum(obj.elementsQ{q}{i,j} == e) == 0
					obj.elementsQ{q}{i,j}(end + 1) = e;
				else
					% Element already in box
					% Maybe put a warning here, but I think it should be ok
				end
			catch ME
				if (strcmp(ME.identifier,'MATLAB:badsubscript'))
					obj.elementsQ{q}{i,j} = [e];
				else
					error('SP:InsertElement:WrongFail','Assignment didnt fail properly');
				end
			end

			% % Put the element in the box, first checking that the box exists
			% % This should be the best way to do it, but the line ~prod(obj.elementsQ{  Q(j)  }{  I(j), J(j)  } == e)
			% % doesn't work with an empty vector
			% if I(j) > size(obj.elementsQ{  Q(j)  }, 1 ) || J(j) > size(obj.elementsQ{  Q(j)  }, 2)


			% 	obj.elementsQ{  Q(j)  }{  I(j), J(j)  } = [e];

			% else
			% 	% If the box does exist, make sure we aren't duplicating
			% 	% the element
			% 	if ~prod(obj.elementsQ{  Q(j)  }{  I(j), J(j)  } == e)
			% 		obj.elementsQ{  Q(j)  }{  I(j), J(j)  }(end + 1) = e;
			% 	end

			% end

		end

		function RemoveElementFromBox(obj,q,i,j,e)

			% If it gets to this point, the element should be in
			% the given box. If it's not, could be a sign of other problems
			% but the simulation can continue
			try
				if sum(obj.elementsQ{q}{i,j} == e) == 0
					% warning('SP:RemoveElementFromBox:NotHere','Element %d is not in box (%d,%d,%d)', e.id,q,i,j);
				else
					obj.elementsQ{q}{i,j}( obj.elementsQ{q}{i,j} == e ) = [];
				end
			catch
				warning('SP:RemoveElementFromBox:DeleteFail','Deleting element %d from box (%d,%d,%d) failed for some reason', e.id,q,i,j);
			end

		end

		function RemoveNodeFromPartition(obj, n)

			% Used when cells die
			[q,i,j] = obj.GetQuadrantAndIndices(n.x,n.y);

			if sum(obj.nodesQ{q}{i,j} == n) == 0
					warning('SP:RemoveNodeFromPartition:NotHere','Node %d is not in box (%d,%d,%d)', n.id,q,i,j);
			else
				obj.nodesQ{q}{i,j}( obj.nodesQ{q}{i,j} == n ) = [];
			end
			
		end

		function RemoveElementFromPartition(obj, e)

			% Used when cells die
			% Assumes that the element is completely up to date

			[ql,il,jl] = GetBoxIndicesBetweenNodes(obj, e.Node1, e.Node2);

			for k = 1:length(ql)
				q = ql(k);
				i = il(k);
				j = jl(k);
				obj.RemoveElementFromBox(q,i,j,e);
			end

		end

		function RepairModifiedElement(obj, e)

			% One or both of the nodes has been
			% modified, so we need to fix the boxes
			if ~isempty(e.oldNode1)
				old1 = e.oldNode1;
			else
				old1 = e.Node1;
			end

			if ~isempty(e.oldNode2)
				old2 = e.oldNode2;
			else
				old2 = e.Node2;
			end

			if old1 == e.Node1 && old2 == e.Node2
				warning('SP:AddNewCells:BothOldAreNotOld','Both old nodes match the current nodes. The modified flag was set incorrectly for element %d', e.id);
			else

				% Assume neither node is adjusted first, then if either is
				% change the boxes
				[ql,il,jl] = obj.GetBoxIndicesBetweenNodes(old1, old2);

				if old1.nodeAdjusted && ~old2.nodeAdjusted
					[ql,il,jl] = obj.GetBoxIndicesBetweenPoints(old1.preAdjustedPosition, old2.position);
					obj.UpdateBoxForNodeAdjusted(old1);
				end

				if ~old1.nodeAdjusted && old2.nodeAdjusted
					[ql,il,jl] = obj.GetBoxIndicesBetweenPoints(old1.position, old2.preAdjustedPosition);
					obj.UpdateBoxForNodeAdjusted(old2);
				end

				if old1.nodeAdjusted && old2.nodeAdjusted
					[ql,il,jl] = obj.GetBoxIndicesBetweenPoints(old1.preAdjustedPosition, old2.preAdjustedPosition);
					obj.UpdateBoxForNodeAdjusted(old1);
					obj.UpdateBoxForNodeAdjusted(old2);
				end

				
				for k = 1:length(ql)
					obj.RemoveElementFromBox(ql(k),il(k),jl(k),e);
				end

				obj.PutElementInBoxes(e);

			end

			% All repaired, remove the flag and old nodes
			e.modifiedInDivision = false;
			e.oldNode1 = [];
			e.oldNode2 = [];

		end

		function b = GetNodeBox(obj, x, y)
			% Given a pair of coordinates, access the matching box

			[q,i,j] = obj.GetQuadrantAndIndices(x,y);

			try
				b = obj.nodesQ{q}{i,j};
			catch
				error('SP:GetNodeBox:NoBox','Node box (%d,%d,%d) doesnt exist yet', q,i,j);
				b = [];
			end

		end

		function new = IsNodeInNewBox(obj, n)

			% Redundant now, but leaving for testing
			new = false;

			if isempty(n.previousPosition)
				error('SP:IsNodeInNewBox:NoPrevious', 'There has not been a previous position');
			end

			[qn,in,jn] = obj.GetQuadrantAndIndices(n.x,n.y);
			[qo,io,jo] = obj.GetQuadrantAndIndices(n.previousPosition(1),n.previousPosition(2));

			if ~prod([qn,in,jn] == [qo,io,jo])
				new = true;
			end

		end

		function b = GetElementBox(obj, x, y)
			% Given a pair of coordinates, access the matching box

			% Determine the indices
			[q,i,j] = obj.GetQuadrantAndIndices(x,y);

			try
				b = obj.elementsQ{q}{i,j};
			catch
				error('SP:GetElementBox:NoBox','Element box (%d,%d,%d) doesnt exist yet', q,i,j);
				b = [];
			end

		end

		function [q,i,j] = GetQuadrantAndIndices(obj, x,y)
			
			q = obj.GetQuadrant(x,y);
			[i,j] = obj.GetIndices(x,y);

		end

		function [I,J] = GetGlobalIndices(obj, x, y)
			% The indices we would have if matlab could
			% handle negative indices

			I = sign(x) * (floor(abs(x/obj.dx)) + 1);
			J = sign(y) * (floor(abs(y/obj.dy)) + 1);

			% Need this since sign(0) = 0
			if I==0; I=1; end
			if J==0; J=1; end

		end

		function [I, J] = ConvertToGlobal(obj,q,i,j)

			switch q
				case 1
					I = i;
					J = j;
				case 2
					I = i;
					J = -j;
				case 3
					I = -i;
					J = -j;
				case 4
					I = -i;
					J = j;
				otherwise
					error('q must be 1,2,3, or 4')
			end

		end

		function [q,i,j] = ConvertToQuadrant(obj,I,J)

			q = GetQuadrant(obj,I,J);
			i = abs(I);
			j = abs(J);

		end

		function [i,j] = GetIndices(obj, x,y)
			% Determine the indices
			% Have to add 1 because matlab is a language that
			% doesn't index from zero, like a sensible language ¯\_(ツ)_/¯
			i = floor(abs(x/obj.dx)) + 1;
			j = floor(abs(y/obj.dy)) + 1;

		end

		function q = GetQuadrant(obj,x,y)


			% Determine the correct quadrant
			% 1: (+,+)
			% 2: (+,-)
			% 3: (-,-)
			% 4: (-,+)

			if length(x) > 1
				% Vectorising attempt
				q = (sign(x)+1) + 3 * (sign(y)+1);

				% Magic numbers
				% Basically, there are 8 situations to handle
				% The equation above produces a unique value
				% for each situation, which is processed below
				q(q==1) = 2;
				q(q==4) = 1;
				q(q==3) = 4;
				q(q==5) = 1;
				q(q==7) = 1;
				q(q==8) = 1;
				q(q==6) = 4;
				q(q==0) = 3;
			else
				% Quick checking if x,y are scalars 
				if sign(x) >= 0 
					if sign(y) >= 0
						q = 1;
					else
						q = 2;
					end
				else
					if sign(y) < 0
						q = 3;
					else
						q = 4;
					end
				end
			end	

		end

	end


end