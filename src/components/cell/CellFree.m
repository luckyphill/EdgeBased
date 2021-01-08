classdef CellFree < AbstractCell
	% A square cell that is joined to its neighbours

	properties

		% Division axis calculator maybe
		numNodes
		splitNodeFunction AbstractSplitNode

	end

	methods
		
		function obj = CellFree(varargin)

			% I wish matlab would handle constructor overloads...
			% obj = CellFree(Cycle, nodeList, id) for a brand new simulation
			% obj = CellFree(Cycle, nodeList, elementList, id) for a divided cell

			% All the initialising
			% This cell takes a list of nodes and uses them to
			% build the cell. The nodes must be in anticlockwise
			% order around the perimeter of the cell, otherwise bad
			% stuff will happen

			% Need to have some validation to check that the elements and nodes are
			% in the anticlockwise order

			% ispolycw

			obj.CellCycleModel = varargin{1};
			nodeList = varargin{2};
			obj.id = varargin{end};

			obj.ancestorId = varargin{end};

			cellDataArray = [CellArea(), CellPerimeter(), CellCentre(), TargetPerimeter(), TargetArea()];

			obj.AddCellData(cellDataArray);

			if length(varargin) == 3
				% This case happens when a new simulation is created
				% (or perhaps if a cell springs out of nowhere)

				obj.nodeList = nodeList;
				obj.numNodes = length(nodeList);

				% Verify that nodes are in anticlockwise order
				% not sure how I can do that...
				% ispolycw is a matlab function but it's part of a special toolbox

				for i = 1:obj.numNodes-1

					e = Element(nodeList(i),nodeList(i+1), -1);
					obj.elementList(end + 1) = e;
					nodeList(i).cellList = obj;
					e.cellList = obj;
				end

				e = Element(nodeList(end),nodeList(1), -1);
				obj.elementList(end + 1) = e;
				nodeList(end).cellList = obj;
				e.cellList = obj;

			end

			if length(varargin) == 4
				% This case is mainly used for dividing cells,
				% but may also be used to make new cells at the
				% beginning of a simulation
				
				obj.nodeList = nodeList;
				obj.numNodes = length(nodeList);

				elementList = varargin{3};
				obj.elementList = elementList;

				% Should throw in a verification step to check
				% that nodes are in anticlockwise order and match
				% with elements

				for i = 1:length(nodeList)

					nodeList(i).ReplaceCellList(obj);

				end

				for i = 1:length(elementList)

					elementList(i).ReplaceCellList(obj);

				end

			end


			obj.splitNodeFunction = RandomNode();

		end


		function [newCell, newNodeList, newElementList] = Divide(obj)
			% Divide cell when simulation is made of free cells
			% that are not constrained to be adjacent to others
			% To divide, split the cell in half along a specified axis
			% and add in sufficient nodes and elements to maintain
			% a constant number of nodes and elements

			% This process needs to be done carefully to update all the new
			% links between node, element and cell

			%  o---------o
			%  |         |
			%  |         |
			%  |     1   |
			%  |         |
			%  |         |
			%  o---------o

			% With an even number of elements becomes

			%  x  o------o
			%  |\  \     |
			%  | \  \    |
			%  |  x  x 1 |
			%  | 2 \  \  |
			%  |    \  \ |
			%  o-----x   o

			% With an odd number of elements, it's harder to draw, but need to
			% choose an element to split or give uneven spread of new elements

			% Find the split points

			% Give -ve ids because id is a feature of the simulation
			% and can't be assigned here. This is handled in AbstractCellSimulation

			% Splitnode identifies the point where division starts
			% A line is drawn across to the halfway point when travelling 
			% around the perimeter of the cell (this won't necessarily cut
			% the cell directly in half, but it should be close)
			% The halfway point will be a node if the cell has an even
			% number of nodes, or the mid point of an element if it's odd

			% In both cases the splitnode will be replaced by two nodes
			% Even will mean the opposite node will be split in two, (one node is added)
			% Odd will mean the opposite element gets split in two (two nodes are added)
			

			% Get the node where splitting occurs
			[splitNode, i] = obj.GetSplitNode();
			
			% Get the elements either side
			I = i-1;
			if I==0; I = obj.numNodes; end
			elementSplitLeft = obj.elementList(I);
			elementSplitRight = obj.elementList(i);

			% Get the nodes that will make up the two halves where the
			% division occurs
			[nodesLeft, nodesRight, sTOo] = obj.MakeIntermediateNodes(splitNode, i);

			% sTOo means split node to opposite node
			% Orient the new nodes by the line from s to o
			% If standing at s and looking at o, side points right
			side = [sTOo(2), -sTOo(1)];
			side = side / norm(side);

			% splitNode is where the cells divide, so need to find
			% the position of the resulting nodes
			sPos = splitNode.position;

			newL = sPos - side * obj.newFreeCellSeparation / 2;
			newR = sPos + side * obj.newFreeCellSeparation / 2;

			% splitNode stays with the original cell which will be to the right
			splitNode.AdjustPosition(newR);

			% The left cell gets a new node
			newSplitNodeLeft = Node(newL(1), newL(2), -1);

			% We have to handle the two different cases now
			hN = obj.numNodes / 2;

			if  hN == floor(hN)

				%-----------------------------
				% Even case
				%-----------------------------


				% Same stuff needs to happen to the opposite node
				% oppositeNode stays with the original cell which will be to the right

				% Get the node opposite the splitNode
				[oppositeNode, j] = obj.GetOppositeNode(i);

				% Get the elements either side
				J = j-1;
				if J==0; J = obj.numNodes; end
				elementOppositeLeft = obj.elementList(j);
				elementOppositeRight = obj.elementList(J);
				
				% oppositeNode is where the cells divide, so need to find
				% the position of the resulting nodes
				oPos = oppositeNode.position;

				newL = oPos - side * obj.newFreeCellSeparation / 2;
				newR = oPos + side * obj.newFreeCellSeparation / 2;

				% oppositeNode stays with the original cell which will be to the right
				oppositeNode.AdjustPosition(newR);

				% The left cell gets a new node
				newOppositeNodeLeft = Node(newL(1), newL(2), -1);


				% The loop is still intact, but we have the nodes staying with the
				% right cell in the correct position, and we've created new
				% nodes to go with the left cell. No links have changed yet.
				% We also have the nodes that will bridge the split for
				% both the left and right cells.
				

				%---------------------------------------
				% Assemble the parts for the new (left) cell
				%---------------------------------------

				% The constructor for making a new cell requires the nodes be in
				% anticlockwise order, as well as the elements.
				newNodesLeft = [newSplitNodeLeft, nodesLeft, newOppositeNodeLeft];

				% Make the new elements in anticlockwise order
				newElementsLeft = Element.empty();
				for j = 1:length(newNodesLeft)-1
					newElementsLeft(end + 1) = Element(newNodesLeft(j), newNodesLeft(j+1), -1);
				end


				% We now have the new elements for the left (new) cell. We need the 
				% original cell's nodes and elements that will go to the left cell

				% Get the nodes and elements between the split and opposite
				% in the anticlockwise direction
				oldNodesLeft = obj.GetNodesBetween(oppositeNode, splitNode, 1);
				oldElementsLeft = obj.GetElementsBetweenInclusive(elementOppositeLeft, elementSplitLeft, 1);

				% Now assemble all the stuff we need for the new cell
				newCellNodes = [newNodesLeft, oldNodesLeft];
				newCellElements = [newElementsLeft, oldElementsLeft];

				% Phew, now we have a list of nodes and elements to feed into the new cell

				%---------------------------------------
				% Assemble the parts for the right (old) cell
				%---------------------------------------

				% Need to put the new nodes in anticlockwise order
				newNodesRight = fliplr(nodesRight);

				% The nodes needed for the new elements
				nodesForNewElementsRight = [oppositeNode, newNodesRight, splitNode];

				% Make the elements in anticlockwise order
				newElementsRight = Element.empty();
				for j = 1:length(nodesForNewElementsRight)-1
					newElementsRight(end + 1) = Element(nodesForNewElementsRight(j), nodesForNewElementsRight(j+1), -1);
				end

				% Get the nodes and elements that are staying with this cell
				oldNodesRight 		= obj.GetNodesBetweenInclusive(splitNode, oppositeNode, 1);
				oldElementsRight 	= obj.GetElementsBetweenInclusive(elementSplitRight, elementOppositeRight, 1);


				% Finally, we need to adjust the links where the splitting
				% occurs to make sure nodes and elements only link to their own cell

				% The elements on the left cell that had their node replaced
				elementSplitLeft.ReplaceNode(splitNode, newSplitNodeLeft);
				elementOppositeLeft.ReplaceNode(oppositeNode, newOppositeNodeLeft);

				% Now assemble the nodes and elements that make up the right cell
				oldCellNodes 			= [newNodesRight, oldNodesRight];
				oldCellElements 		= [newElementsRight, oldElementsRight];
				% Need to rearrange the elements to match with the node indices
				oldCellElements 		= [oldCellElements(2:end), oldCellElements(1)];

				% Yay! Everything is done! Now for the odd case...


			else

				% From here on, a comment with an asterix means the line is modified from the
				% even case %*****
				%-----------------------------
				% Odd case
				%-----------------------------

				% Get the element opposite the splitNode
				[oppositeElement, j] = obj.GetOppositeElement(i); 									%*****
				
				% The division will happen at the at the midpoint of the element
				oPos = oppositeElement.GetMidPoint();												%*****

				newL = oPos - side * obj.newFreeCellSeparation / 2;
				newR = oPos + side * obj.newFreeCellSeparation / 2;

				% Make two new nodes at the split
				newOppositeNodeLeft = Node(newL(1), newL(2), -1);
				newOppositeNodeRight = Node(newR(1), newR(2), -1);									%*****


				elementOppositeRight = oppositeElement;												%*****

				elementOppositeLeft = Element(  newOppositeNodeLeft, oppositeElement.Node2, -1);  	%*****


				%---------------------------------------
				% Assemble the parts for the new (left) cell
				%---------------------------------------

				% The constructor for making a new cell requires the nodes be in
				% anticlockwise order, as well as the elements.
				newNodesLeft = [newSplitNodeLeft, nodesLeft, newOppositeNodeLeft];

				% Make the new elements in anticlockwise order
				newElementsLeft = Element.empty();
				for j = 1:length(newNodesLeft)-1
					newElementsLeft(end + 1) = Element(newNodesLeft(j), newNodesLeft(j+1), -1);
				end

				newElementsLeft = [, newElementsLeft];
				% We now have the new elements for the left (new) cell. We need the 
				% original cell's nodes and elements that will go to the left cell

				% Get the nodes and elements between the split and opposite
				% in the anticlockwise direction
				oldNodesLeft = obj.GetNodesBetween(oppositeElement.Node1, splitNode, 1); 			%*****
				oldElementsLeft = obj.GetElementsBetween(oppositeElement, elementSplitRight, 1);	%*****

				% Now assemble all the stuff we need for the new cell
				newCellNodes = [newNodesLeft, oldNodesLeft];
				newCellElements = [newElementsLeft, elementOppositeLeft, oldElementsLeft];

				% Phew, now we have a list of nodes and elements to feed into the new cell


				%---------------------------------------
				% Assemble the parts for the right (old) cell
				%---------------------------------------

				% Need to put the new nodes in anticlockwise order
				newNodesRight = [newOppositeNodeRight, fliplr(nodesRight)];									%*****

				% The nodes needed for the new elements
				nodesForNewElementsRight = [newNodesRight, splitNode];										%*****

				% Make the elements in anticlockwise order
				newElementsRight = Element.empty();
				for j = 1:length(nodesForNewElementsRight)-1
					newElementsRight(end + 1) = Element(nodesForNewElementsRight(j), nodesForNewElementsRight(j+1), -1);
				end

				% Get the nodes and elements that are staying with this cell
				oldNodesRight 		= obj.GetNodesBetweenInclusive(splitNode, oppositeElement.Node1, 1);	%*****
				oldElementsRight 	= obj.GetElementsBetweenInclusive(elementSplitRight, elementOppositeRight, 1);


				% The elements on the left cell that had their node replaced
				elementSplitLeft.ReplaceNode(splitNode, newSplitNodeLeft);									%*****
				% must be replaced. This should be done later so it doesn't ruin the 
				% element building, or looping
				oppositeElement.ReplaceNode(oppositeElement.Node2, newOppositeNodeRight);

				% Now assemble the nodes and elements that make up the right cell
				oldCellNodes 			= [newNodesRight, oldNodesRight];
				oldCellElements 		= [newElementsRight, oldElementsRight];
				% Need to rearrange the elements to match with the node indices

			end


			% Need to set the links to this cell
			for i = 1:length(oldCellNodes)
				oldCellNodes(i).ReplaceCellList(obj);
			end

			for i = 1:length(oldCellElements)
				oldCellElements(i).ReplaceCellList(obj);
			end

			obj.nodeList = oldCellNodes;
			obj.elementList = oldCellElements;

			% Duplicate the cell cycle model from the old cell
			newCCM = obj.CellCycleModel.Duplicate();

			% Now we have all the parts we need to build the new cell in its correct position
			% The new cell will have the correct links with its constituent elements and nodes
			newCell = CellFree(newCCM, newCellNodes, newCellElements , -1);			

			% Old cell should be completely remodelled by this point, adjust the age back to zero
			obj.CellCycleModel.SetAge(0);
			obj.age = 0;

			% Make a list of new nodes and elements
			newNodeList 	= [newNodesLeft, newNodesRight];
			newElementList	= [newElementsLeft, newElementsRight];

			% Update the sister cells
			newCell.sisterCell = obj;
			obj.sisterCell = newCell;
			% ...and ancestorId
			newCell.ancestorId = obj.id;
		
		end

		function inside = IsPointInsideCell(obj, point)

			% Assemble vertices in the correct order to produce a quadrilateral

			x = [obj.nodeList.x];
			y = [obj.nodeList.y];

			[inside, on] = inpolygon(point(1), point(2), x ,y);

			if inside && on
				inside = false;
			end

		end

		function next = GetNextNode(obj, n, direction)

			% Use the elements to find the next node around
			% the perimeter in direction 
			% direction = 1 anticlockwise
			% direction = -1 clockwise

			% Probably more bloated than necessary, but this way adds in error catching
			switch direction
				case 1
					% Heading anticlockwise
					switch n
						case n.elementList(1).Node1
							next = n.elementList(1).Node2;
						case n.elementList(1).Node2
							next = n.elementList(2).Node2;
						otherwise
							error('SCF:GetNextNode','Error with node-element linking');
					end
					
				case -1
					switch n
						case n.elementList(1).Node2
							next = n.elementList(1).Node1;
						case n.elementList(1).Node1
							next = n.elementList(2).Node1;
						otherwise
							error('SCF:GetNextNode','Error with node-element linking');
					end

				otherwise
					error('SCF:GetNextNode','Dirction must be 1, anticlockwise, or -1, clockwise');
			end

		end

		function next = GetNextElement(obj, e, direction)

			% Use the nodes to find the next element around
			% the perimeter in direction 
			% direction = 1 anticlockwise
			% direction = -1 clockwise

			% Probably more bloated than necessary, but this way adds in error catching
			switch direction
				case 1
					% Heading anticlockwise
					switch e
						case e.Node2.elementList(1)
							next = e.Node2.elementList(2);
						case e.Node2.elementList(2)
							next = e.Node2.elementList(1);
						otherwise
							error('SCF:GetNextElement','Error with node-element linking');
					end
					
				case -1
					switch e
						case e.Node1.elementList(1)
							next = e.Node1.elementList(2);
						case e.Node1.elementList(2)
							next = e.Node1.elementList(1);
						otherwise
							error('SCF:GetNextElement','Error with node-element linking');
					end

				otherwise
					error('SCF:GetNextElement','Dirction must be 1, anticlockwise, or -1, clockwise');
			end

		end

		function nodesBetween = GetNodesBetween(obj, startNode, endNode, direction)

			% This returns the nodes between start and end in direciton
			% EXCLUDING the end points
			nodesBetween = Node.empty();
			next = obj.GetNextNode(startNode, direction);
			while next ~=endNode
				nodesBetween(end + 1) = next;
				next = obj.GetNextNode(next, direction);
			end

		end

		function nodesBetween = GetNodesBetweenInclusive(obj, startNode, endNode, direction)

			% This returns the nodes between start and end in direciton
			% IINCLUDING the end points

			nodesBetween = [startNode,  GetNodesBetween(obj, startNode, endNode, direction), endNode];

		end

		function elementsBetween = GetElementsBetween(obj, startElement, endElement, direction)

			% This returns the Elements between start and end in direciton
			% EXCLUDING the end points
			elementsBetween = Element.empty();
			next = obj.GetNextElement(startElement, direction);
			while next ~=endElement
				elementsBetween(end + 1) = next;
				next = obj.GetNextElement(next, direction);
			end

		end

		function elementsBetween = GetElementsBetweenInclusive(obj, startElement, endElement, direction)

			% This returns the Elements between start and end in direciton
			% INCLUDING the end points

			elementsBetween = [startElement, GetElementsBetween(obj, startElement, endElement, direction), endElement];

		end

		function [splitNode, i] = GetSplitNode(obj)

			% Using something that defines the division axis,
			% chose a node to start the split from. The other side
			% will be on the opposite side of the cell and could be
			% an element or a node, depending on even or oddness of
			% the node count

			[splitNode, i] = obj.splitNodeFunction.GetSplitNode(obj);

		end

		function [oppositeNode, j] = GetOppositeNode(obj, i)

			% Gets the node opposite node given by index i in
			% nodeList. If matlab indexeed from 0 then mod would work
			% straight out of the box... 

			hN = obj.numNodes / 2;

			if  hN == floor(hN)
				j = mod(i + hN, obj.numNodes);
				if j==0; j=obj.numNodes; end
				oppositeNode = obj.nodeList(j);
			else
				error('CF:GetOppositeNode','Odd number of nodes, use GetOppositeElement');
			end

		end

		function [oppositeElement, j] = GetOppositeElement(obj, i)
			% Gets the node opposite element from node in index i in
			% nodeList. This is only used for odd numbers of nodes.
			% We use the same trick as with opposite node, but apply it to the
			% elementList. This requires the elementList to be 
			% assembled as in the constructor. If that changes, then this will break
			% When it comes to reassembling the lists after division, 
			% we will have to keep the order, or everything will fall over

			hN = obj.numNodes / 2;

			if  hN == floor(hN)
				error('CF:GetOppositeElement','Even number of nodes, use GetOppositeNode');
			else
				j = mod(i + floor(hN), obj.numNodes);
				if j==0; j=obj.numNodes; end
				oppositeElement = obj.elementList(j);
			end

		end

		function [nodesLeft, nodesRight, sTOo] = MakeIntermediateNodes(obj, s, i)

			% Get a vector along the split axis
			sTOo = obj.GetSplitVector(s, i);

			% We want to create the nodes that will appear in the
			% middle of the dividing cell, for now we ignore what
			% happens at the split node and it's opposite

			% In the even case, we will add obj.numNodes/2 - 1 new
			% nodes to keep the number constant, for the odd case
			% floor(obj.numNodes/2) - 1 works.
			
			% For example, 10 nodes cell -> split from Node1 to Node6
			% Node1 will be split, Node6 will be split, making for a total
			% of 6 nodes on each side, hence the remainder is 4

			% For a 9 node cell, split Node1 to Element5
			% Node1 will be split, Element5 will be split, making for a
			% total of 6 nodes each side, leaving 3 to be added

			splitPoints = [];
			nSplits = floor(obj.numNodes/2) - 1;

			for j = 1:nSplits
				splitPoints(j,:) = s.position + sTOo * j /(nSplits+1);
			end

			% Orient the new nodes by the line from s to o
			% If standing at s and looking at o side points right
			side = [sTOo(2), -sTOo(1)];
			side = side / norm(side);

			for j = 1:nSplits
				posL = splitPoints(j,:) - side * obj.newFreeCellSeparation / 2;
				posR = splitPoints(j,:) + side * obj.newFreeCellSeparation / 2;
				nodesLeft(j) = Node(posL(1), posL(2), -1);
				nodesRight(j) = Node(posR(1), posR(2), -1);
			end

		end

		function sTOo = GetSplitVector(obj, s, i)

			% Makes a vector from the split node to the opposite
			% side (whether that is an edge or a node), so the 
			% intermediate ndoes can be built
			% Uses the index i of the chosen node

			hN = obj.numNodes / 2;
			if  hN == floor(hN)
				o = obj.GetOppositeNode(i);
				oPos = o.position;
			else
				o = obj.GetOppositeElement(i);
				oPos = o.GetMidPoint();
			end

			sTOo = oPos - s.position;

		end

	end

end