classdef AbstractCell < handle & matlab.mixin.Heterogeneous
	% A class specifying the details about nodes

	properties
		% Essential properties of a node
		id

		age = 0

		nodeList 	= Node.empty()
		elementList = Element.empty()

		newCellTargetArea = 0.5
		grownCellTargetArea = 1

		CellCycleModel

		deformationEnergyParameter = 10
		surfaceEnergyParameter = 1

		% Determines if we are using a free or joined cell model
		freeCell = false
		newFreeCellSeparation = 0.1

		% A cell divides in 2, this will store the sister
		% cell after division
		sisterCell = AbstractCell.empty();

		% Stores the id of the cell that was in the 
		% initial configuration. Only can store the id
		% because the cell can be deleted from the simulation
		ancestorId


		% A collection objects for calculating data about the cell
		% stored in a map container so each type of data can be given a
		% meaingful name
		cellData

		% By default, the type is 1, matching a general epithelial cell
		cellType = 1
		
	end

	methods (Abstract)

		[newCell, newNodeList, newElementList] = Divide(obj)
		inside = IsPointInsideCell(obj, point)

	end

	methods

		function delete(obj)

			clear obj;

		end

		function set.CellCycleModel( obj, v )
			% This is to validate the object given to outputType in the constructor
			if isa(v, 'AbstractCellCycleModel')
            	validateattributes(v, {'AbstractCellCycleModel'}, {});
            	obj.CellCycleModel = v;
            	v.containingCell = obj;
            else
            	error('C:NotValidCCM','Not a valid cell cycle');
            end

        end

        function currentArea = GetCellArea(obj)
			% This and the following 3 functions could be replaced by accessing the cellData
			% but they're kept here for backwards compatibility, and because
			% these types of data are fundamental enough to designate a function

			currentArea = obj.cellData('cellArea').GetData(obj);

		end

		function targetArea = GetCellTargetArea(obj)
			% This is so the target area can be a function of cell age

			targetArea = obj.cellData('targetArea').GetData(obj);

		end

		function currentPerimeter = GetCellPerimeter(obj)

			currentPerimeter = obj.cellData('cellPerimeter').GetData(obj);

		end

		function centre = GetCellCentre(obj)

			centre = obj.cellData('cellCentre').GetData(obj);

		end

		function targetPerimeter = GetCellTargetPerimeter(obj)
			% This is so the target Perimeter can be a function of cell age
			targetPerimeter = obj.cellData('targetPerimeter').GetData(obj);

		end

		function ready = IsReadyToDivide(obj)

			ready = obj.CellCycleModel.IsReadyToDivide();

		end

		function AddCellData(obj, d)

			% Need to explicitly create a map object or matlab
			% will only point to one map object for the
			% entire list of Cells...
			if isempty(obj.cellData)
				cD = containers.Map;
				for i = 1:length(d)
					cD(d(i).name) = d(i);
				end
				obj.cellData = cD;
			else
				for i = 1:length(d)
					obj.cellData(d(i).name) = d(i);
				end
			end

		end

		function AgeCell(obj, dt)

			% This will be done at the end of the time step
			obj.age = obj.age + dt;
			obj.CellCycleModel.AgeCellCycle(dt);

		end

		function age = GetAge(obj)

			age = obj.CellCycleModel.GetAge();
			
		end

		function colour = GetColour(obj)
			% Used for animating/plotting only

			colour = obj.CellCycleModel.GetColour();
		
		end

		function crossing = DoElementsCross(obj, e1, e2)

			crossing = false;
			% An edge will only flip on the top or bottom
			% When that happens, the left and right edges will cross
			% The following algorithm decides if the edges cross

			if e1.Node1 == e2.Node1 || e1.Node1 == e2.Node2 || e1.Node2 == e2.Node1 || e1.Node2 == e2.Node2
				% These elements share a node, so there is no need to check if they cross
				crossing = false;
			else
				% But if the nodes are distinct, they could cause a problem

				X1 = e1.Node1.x;
				X2 = e1.Node2.x;

				Y1 = e1.Node1.y;
				Y2 = e1.Node2.y;

				X3 = e2.Node1.x;
				X4 = e2.Node2.x;

				Y3 = e2.Node1.y;
				Y4 = e2.Node2.y;

				% Basic run-down of algorithm:
				% The lines are parameterised so that
				% elementLeft  = (x1(t), y1(t)) = (A1t + a1, B1t + b1)
				% elementRight = (x2(s), y2(s)) = (A2s + a2, B2s + b2)
				% where 0 <= t,s <=1
				% If the lines cross, then there is a unique value of t,s such that
				% x1(t) == x2(s) and y1(t) == y2(s)
				% There will always be a value of t and s that satisfies these
				% conditions (except for when the lines are parallel), so to make
				% sure the actual segments cross, we MUST have 0 <= t,s <=1

				% Solving this, we have
				% t = ( B2(a1 - a2) - A2(b1 - b2) ) / (A2B1 - A1B2)
				% s = ( B1(a1 - a2) - A1(b1 - b2) ) / (A2B1 - A1B2)
				% Where 
				% A1 = X2 - X1, a1 = X1
				% B1 = Y2 - Y1, b1 = Y1
				% A2 = X4 - X3, a2 = X3
				% B2 = Y4 - Y3, b2 = Y3

				denom = (X4 - X3)*(Y2 - Y1) - (X2 - X1)*(Y4 - Y3);

				% denom == 0 means parallel

				if denom ~= 0
					% if the numerator for either t or s expression is larger than the
					% |denominator|, then |t| or |s| will be greater than 1, i.e. out of their range
					% so both must be less than
					tNum = (Y4 - Y3)*(X1 - X3) - (X4 - X3)*(Y1 - Y3);
					sNum = (Y2 - Y1)*(X1 - X3) - (X2 - X1)*(Y1 - Y3);
					
					% If they strictly less than, then crossing occurs
					% If they are equal, then the end points join
					if abs(tNum) < abs(denom) && abs(sNum) < abs(denom) && tNum~=0 && sNum~=0
						% magnitudes are correct, now check the signs
						if sign(tNum) == sign(denom) && sign(sNum) == sign(denom)
							% If the signs of the numerator and denominators are the same
							% Then s and t satisfy their range restrictions, hence the elements cross
							crossing = true;
						end
					end
				end
			end

		end

		function selfIntersecting = IsCellSelfIntersecting(obj)

			% This is the slowest possible algorithm to check self intersection
			% so it should only be used WHEN INITIALISING A CELL. It should NOT
			% be used regularly to detect intersections because it is
			% EXTREMELY SLOW
			
			selfIntersecting = false;

			for i = 1:length(obj.elementList)
				
				e1 = obj.elementList(i);
				for j = i+1:length(obj.elementList)
					
					e2 = obj.elementList(j);
					if obj.DoElementsCross(e1, e2)
						
						selfIntersecting = true;
						return;

					end

				end

			end

		end

		function inside = IsNodeInsideCell(obj, n)

			% Assemble vertices in the correct order to produce a quadrilateral

			x = [obj.nodeList.x];
			y = [obj.nodeList.y];

			[inside, on] = inpolygon(n.x, n.y, x ,y);

			if inside && on
				inside = false;
			end

		end

		function DrawCell(obj)

			% plot a line for each element

			% h = figure();
			hold on
			for i = 1:length(obj.elementList)

				x1 = obj.elementList(i).Node1.x;
				x2 = obj.elementList(i).Node2.x;
				x = [x1,x2];
				y1 = obj.elementList(i).Node1.y;
				y2 = obj.elementList(i).Node2.y;
				y = [y1,y2];

				line(x,y)
			end

			axis equal

		end

		function DrawCellPrevious(obj)

			% plot a line for each element

			h = figure();
			hold on
			
			for i = 1:length(obj.elementList)

				x1 = obj.elementList(i).Node1.previousPosition(1);
				x2 = obj.elementList(i).Node2.previousPosition(1);
				x = [x1,x2];
				y1 = obj.elementList(i).Node1.previousPosition(2);
				y2 = obj.elementList(i).Node2.previousPosition(2);
				y = [y1,y2];

				line(x,y)
			end

			axis equal

		end

	end

end