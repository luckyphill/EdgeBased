classdef (Abstract) AbstractCellSimulation < matlab.mixin.SetGet
	% A parent class that contains all the functions for running a simulation
	% The child/concrete class will only need a constructor that assembles the cells

	properties

		seed
        
		nodeList
		nextNodeId = 1

		elementList
		nextElementId = 1

		cellList
		nextCellId = 1

		stochasticJiggle = true
		epsilon = 0.0001; % The size of the jiggle force

		cellBasedForces AbstractCellBasedForce
		elementBasedForces AbstractElementBasedForce
		neighbourhoodBasedForces AbstractNeighbourhoodBasedForce
		tissueBasedForces AbstractTissueBasedForce

		stoppingConditions AbstractStoppingCondition

		stopped = false

		tissueLevelKillers AbstractTissueLevelCellKiller
		cellKillers AbstractCellKiller

		simulationModifiers AbstractSimulationModifier

		% A collection of objects that store data over multiple time steps
		% with also the potential to write to file
		dataStores AbstractDataStore

		dataWriters AbstractDataWriter

		% A collection objects for calculating data about the simulation
		% stored in a map container so each type of data can be given a
		% meaingful name
		simData = containers.Map;

		boxes SpacePartition;

		usingBoxes = true;

		writeToFile = true;
		
	end

	properties (Abstract)

		dt
		t
		step

	end

	methods

		function SetRNGSeed(obj, seed)

			obj.seed = seed;
			rng(seed);

		end

		function NextTimeStep(obj)
			% Updates all the forces and applies the movements

			obj.GenerateTissueBasedForces();
			obj.GenerateCellBasedForces();
			obj.GenerateElementBasedForces();

			if obj.usingBoxes
				obj.GenerateNeighbourhoodBasedForces();
			end

			obj.MakeNodesMove();

			% Division must occur after movement
			obj.MakeCellsDivide();

			obj.KillCells();

			obj.ModifySimulationState();

			obj.MakeCellsAge();

			obj.step = obj.step + 1;
			obj.t = obj.step * obj.dt;

			obj.StoreData();
			
			if obj.writeToFile
				obj.WriteData();
			end

			if obj.IsStoppingConditionMet()
				obj.stopped = true;
			end

		end

		function NTimeSteps(obj, n)
			% Advances a set number of time steps
			
			for i = 1:n
				% Do all the calculations
				obj.NextTimeStep();

				if mod(obj.step, 1000) == 0
					fprintf('Time = %3.3fhr\n',obj.t);
				end

				if obj.stopped
					fprintf('Stopping condition met at t=%3.3f\n', obj.t);
					break;
				end

			end
			
		end

		function RunToTime(obj, t)

			% Given a time, run the simulation until we reach said time
			if t > obj.t
				n = ceil((t-obj.t) / obj.dt);
				NTimeSteps(obj, n);
			end

		end

		function GenerateTissueBasedForces(obj)
			
			for i = 1:length(obj.tissueBasedForces)
				obj.tissueBasedForces(i).AddTissueBasedForces(obj);
			end

		end

		function GenerateCellBasedForces(obj)
			
			for i = 1:length(obj.cellBasedForces)
				obj.cellBasedForces(i).AddCellBasedForces(obj.cellList);
			end

		end

		function GenerateElementBasedForces(obj)

			for i = 1:length(obj.elementBasedForces)
				obj.elementBasedForces(i).AddElementBasedForces(obj.elementList);
			end

		end

		function GenerateNeighbourhoodBasedForces(obj)
			
			if isempty(obj.boxes)
				error('ACS:NoBoxes','Space partition required for NeighbourhoodForces, but none set');
			end

			for i = 1:length(obj.neighbourhoodBasedForces)
				obj.neighbourhoodBasedForces(i).AddNeighbourhoodBasedForces(obj.nodeList, obj.boxes);
			end

		end

		function MakeNodesMove(obj)

			for i = 1:length(obj.nodeList)
				
				n = obj.nodeList(i);

				eta = n.eta;
				force = n.force;
				if obj.stochasticJiggle
					% Add in a tiny amount of stochasticity to the force calculation
					% to nudge it out of unstable equilibria

					% Make a random direction vector
					v = [rand-0.5,rand-0.5];
					v = v/norm(v);

					% Add the random vector, and make sure it is orders of magnitude
					% smaller than the actual force
					% force = force + v * norm(force) / 10000;
					force = force + v * obj.epsilon;

				end

				newPosition = n.position + obj.dt/eta * force;

				n.MoveNode(newPosition);

				if obj.usingBoxes
					obj.boxes.UpdateBoxForNode(n);
				end
			end

		end

		function AdjustNodePosition(obj, n, newPos)

			% Only used by modifiers. Do not use to
			% progress the simulation

			% This will move a node to a given position regardless
			% of forces, but after all force movement has happened

			% Previous position and previous force are not modified

			% Make sure the node and elements are in the correct boxes
			n.AdjustPosition(newPos);
			if obj.usingBoxes
				obj.boxes.UpdateBoxForNodeAdjusted(n);
			end

		end

		function MakeCellsDivide(obj)

			% Call the divide process, and update the lists
			newCells 	= AbstractCell.empty();
			newElements = Element.empty();
			newNodes 	= Node.empty();
			for i = 1:length(obj.cellList)
				c = obj.cellList(i);
				if c.IsReadyToDivide()
					[newCellList, newNodeList, newElementList] = c.Divide();
					newCells = [newCells, newCellList];
					newElements = [newElements, newElementList];
					newNodes = [newNodes, newNodeList];
				end
			end

			obj.AddNewCells(newCells, newElements, newNodes);

		end

		function AddNewCells(obj, newCells, newElements, newNodes)
			% When a cell divides, need to make sure the new cell object
			% as well as the new elements and nodes are correctly added to
			% their respective lists and boxes if relevant

			for i = 1:length(newNodes)

				n = newNodes(i);
				n.id = obj.GetNextNodeId();
				if obj.usingBoxes
					obj.boxes.PutNodeInBox(n);
				end

			end

			for i = 1:length(newElements)

				e = newElements(i);
				e.id = obj.GetNextElementId();
				if obj.usingBoxes && ~e.internal
					obj.boxes.PutElementInBoxes(e);
				end

			end

			for i = 1:length(newCells)
				
				nc = newCells(i);
				nc.id = obj.GetNextCellId();

				if obj.usingBoxes

					% Not necessary, as external elements never become internal elements
					% even considering cell death. As long as the internal flag is set
					% correctly during division, there is no issue
					% % If the cell type is joined, then we need to make sure the
					% % internal element is labelled as such, and that the element
					% % is removed from the partition.

					% if strcmp(class(nc), 'SquareCellJoined')

					% 	if ~nc.elementRight.internal
					% 		nc.elementRight.internal = true;
					% 		obj.boxes.RemoveElementFromPartition(nc.elementRight);
					% 	end

					% end

					% When a division occurs, the nodes and elements of the sister cell
					% (which was also the parent cell before division), may
					% have been modified to have a different node. This screws
					% with the space partition, so we have to fix it
					oc = nc.sisterCell;

					% Repair modified elements goes first because that adjusts nodes
					% in the function
					for j = 1:length(oc.elementList)
						e = oc.elementList(j);
						
						if e.modifiedInDivision
							obj.boxes.RepairModifiedElement(e);
						end

					end

					for j = 1:length(oc.nodeList)
						n = oc.nodeList(j);

						if n.nodeAdjusted
							obj.boxes.UpdateBoxForNodeAdjusted(n);
						end

					end

				end

			end


			obj.cellList = [obj.cellList, newCells];

			obj.elementList = [obj.elementList, newElements];

			obj.nodeList = [obj.nodeList, newNodes];

		end

		function MakeCellsAge(obj)

			for i = 1:length(obj.cellList)
				obj.cellList(i).AgeCell(obj.dt);
			end

		end

		function AddCellBasedForce(obj, f)

			if isempty(obj.cellBasedForces)
				obj.cellBasedForces = f;
			else
				obj.cellBasedForces(end + 1) = f;
			end

		end

		function AddElementBasedForce(obj, f)

			if isempty(obj.elementBasedForces)
				obj.elementBasedForces = f;
			else
				obj.elementBasedForces(end + 1) = f;
			end

		end

		function AddNeighbourhoodBasedForce(obj, f)

			if isempty(obj.neighbourhoodBasedForces)
				obj.neighbourhoodBasedForces = f;
			else
				obj.neighbourhoodBasedForces(end + 1) = f;
			end

		end

		function AddTissueBasedForce(obj, f)

			if isempty(obj.tissueBasedForces)
				obj.tissueBasedForces = f;
			else
				obj.tissueBasedForces(end + 1) = f;
			end

		end

		function AddTissueLevelKiller(obj, k)

			if isempty(obj.tissueLevelKillers)
				obj.tissueLevelKillers = k;
			else
				obj.tissueLevelKillers(end + 1) = k;
			end

		end

		function AddCellKiller(obj, k)

			if isempty(obj.cellKillers)
				obj.cellKillers = k;
			else
				obj.cellKillers(end + 1) = k;
			end

		end

		function AddStoppingCondition(obj, s)

			if isempty(obj.stoppingConditions)
				obj.stoppingConditions = s;
			else
				obj.stoppingConditions(end + 1) = s;
			end

		end

		function AddSimulationModifier(obj, m)

			if isempty(obj.simulationModifiers)
				obj.simulationModifiers = m;
			else
				obj.simulationModifiers(end + 1) = m;
			end

		end

		function AddDataStore(obj, d)

			if isempty(obj.dataStores)
				obj.dataStores = d;
			else
				obj.dataStores(end + 1) = d;
			end

		end

		function AddDataWriter(obj, w)

			if isempty(obj.dataWriters)
				obj.dataWriters = w;
			else
				obj.dataWriters(end + 1) = w;
			end

		end

		function AddSimulationData(obj, d)

			% Add the simulation data calculator to the map
			% this will necessarily allow only one instance
			% of a given type of SimulationData, since the 
			% names are immutable

			% This is calculate-on-demand, so it does not have
			% an associated 'use' method here
			obj.simData(d.name) = d;

		end

		function StoreData(obj)

			for i = 1:length(obj.dataStores)
				obj.dataStores(i).StoreData(obj);
			end

		end

		function WriteData(obj)

			for i = 1:length(obj.dataWriters)
				obj.dataWriters(i).WriteData(obj);
			end

		end

		function ModifySimulationState(obj)

			for i = 1:length(obj.simulationModifiers)
				obj.simulationModifiers(i).ModifySimulation(obj);
			end

		end

		function KillCells(obj)

			% Loop through the cell killers

			for i = 1:length(obj.tissueLevelKillers)
				obj.tissueLevelKillers(i).KillCells(obj);
			end

			for i = 1:length(obj.cellKillers)
				obj.cellKillers(i).KillCells(obj.cellList);
			end

		end

		function stopped = IsStoppingConditionMet(obj)

			stopped = false;
			for i = 1:length(obj.stoppingConditions)
				if obj.stoppingConditions(i).CheckStoppingCondition(obj)
					stopped = true;
					break;
				end
			end

		end

		function numCells = GetNumCells(obj)

			numCells = length(obj.cellList);

		end

		function numElements = GetNumElements(obj)

			numElements = length(obj.elementList);

		end

		function numNodes = GetNumNodes(obj)

			numNodes = length(obj.nodeList);

		end

		function Visualise(obj, varargin)

			h = figure();
			hold on

			% Intitialise the vector
			fillObjects(length(obj.cellList)) = fill([1,1],[2,2],'r');

			for i = 1:length(obj.cellList)
				c = obj.cellList(i);

				x = [c.nodeList.x];
				y = [c.nodeList.y];	

				fillObjects(i) = fill(x,y,c.GetColour());
			end

			axis equal

			if ~isempty(varargin)
				cL = obj.simData('centreLine').GetData(obj);
				plot(cL(:,1), cL(:,2), 'k');
			end

		end

		function VisualiseArea(obj)

			h = figure();
			hold on
			% Makes the colour depend on the area
			% Intitialise the vector
			fillObjects(length(obj.cellList)) = fill([1,1],[2,2],'r');

			for i = 1:length(obj.cellList)
				c = obj.cellList(i);

				x = [c.nodeList.x];
				y = [c.nodeList.y];	

				A = polyarea(x,y);
				fillObjects(i) = fill(x,y,A);

			end

			axis equal

		end

		function VisualiseRods(obj, r)

			h = figure();
			hold on
			% r is rod "radius"
			% r = 0.08; % The width of the rods
			patchObjects(length(obj.cellList)) = patch([1,1],[2,2],1, 'LineWidth', 2);

			for i = 1:length(obj.cellList)

				c = obj.cellList(i);

				a = c.nodeList(1).position;
				b = c.nodeList(2).position;

				[pillX,pillY] = obj.DrawPill(a,b,r);
				patchObjects(i) = patch(pillX,pillY,c.GetColour(), 'LineWidth', 2);

			end

			axis equal

		end


		function VisualiseNodes(obj, r)
			% r is cell radius

			h = figure();
			hold on

			patchObjects(length(obj.cellList)) = patch([1,1],[2,2],1, 'LineWidth', 2);

			for i = 1:length(obj.cellList)

				c = obj.cellList(i);

				a = c.nodeList(1).position;

				[pillX,pillY] = obj.DrawPill(a,a,r);
				patchObjects(i) = patch(pillX,pillY,c.GetColour(), 'LineWidth', 2);

			end

			axis equal

		end


		function VisualiseWireFrame(obj, varargin)

			% plot a line for each element

			h = figure();
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

			if ~isempty(varargin)
				cL = obj.simData('centreLine').GetData(obj);
				plot(cL(:,1), cL(:,2), 'k');
			end

		end

		function VisualiseWireFramePrevious(obj, varargin)

			% plot a line for each element

			h = figure();
			hold on
			for i = 1:length(obj.elementList)

				if ~isempty(obj.elementList(i).Node1.previousPosition) && ~isempty(obj.elementList(i).Node2.previousPosition)
					x1 = obj.elementList(i).Node1.previousPosition(1);
					x2 = obj.elementList(i).Node2.previousPosition(1);
					x = [x1,x2];
					y1 = obj.elementList(i).Node1.previousPosition(2);
					y2 = obj.elementList(i).Node2.previousPosition(2);
					y = [y1,y2];

					line(x,y)
				else
					% There are three cases, where one or both nodes are new i.e. have no previous position
					if isempty(obj.elementList(i).Node1.previousPosition) && ~isempty(obj.elementList(i).Node2.previousPosition)
						x1 = obj.elementList(i).Node1.position(1);
						x2 = obj.elementList(i).Node2.previousPosition(1);
						x = [x1,x2];
						y1 = obj.elementList(i).Node1.position(2);
						y2 = obj.elementList(i).Node2.previousPosition(2);
						y = [y1,y2];

						line(x,y)
					end

					if ~isempty(obj.elementList(i).Node1.previousPosition) && isempty(obj.elementList(i).Node2.previousPosition)
						x1 = obj.elementList(i).Node1.previousPosition(1);
						x2 = obj.elementList(i).Node2.position(1);
						x = [x1,x2];
						y1 = obj.elementList(i).Node1.previousPosition(2);
						y2 = obj.elementList(i).Node2.position(2);
						y = [y1,y2];

						line(x,y)
					end

					if isempty(obj.elementList(i).Node1.previousPosition) && isempty(obj.elementList(i).Node2.previousPosition)
						x1 = obj.elementList(i).Node1.position(1);
						x2 = obj.elementList(i).Node2.position(1);
						x = [x1,x2];
						y1 = obj.elementList(i).Node1.position(2);
						y2 = obj.elementList(i).Node2.position(2);
						y = [y1,y2];
 
						line(x,y,'LineStyle',':')
					end

				end
			end

			axis equal

			if ~isempty(varargin)
				cL = obj.simData('centreLine').GetData(obj);
				plot(cL(:,1), cL(:,2), 'k');
			end

		end

		function Animate(obj, n, sm)
			% Since we aren't storing data at this point, the only way to animate is to
			% calculate then plot

			% Set up the line objects initially

			% Initialise an array of line objects
			h = figure();
			hold on
			axis equal

			fillObjects(length(obj.cellList)) = fill([1,1],[2,2],'r');

			for i = 1:length(obj.cellList)
				c = obj.cellList(i);

				x = [c.nodeList.x];
				y = [c.nodeList.y];

				fillObjects(i) = fill(x,y,c.GetColour());
			end

			totalSteps = 0;
			while totalSteps < n

				obj.NTimeSteps(sm);
				totalSteps = totalSteps + sm;

				for j = 1:length(obj.cellList)
					c = obj.cellList(j);

					x = [c.nodeList.x];
					y = [c.nodeList.y];

					if j > length(fillObjects)
						fillObjects(j) = fill(x,y,c.GetColour());
					else
						fillObjects(j).XData = x;
						fillObjects(j).YData = y;
						fillObjects(j).FaceColor = c.GetColour();
					end
				end

				% Delete the line objects when there are too many
				for j = length(fillObjects):-1:length(obj.cellList)+1
					fillObjects(j).delete;
					fillObjects(j) = [];
				end
				drawnow
				title(sprintf('t=%g',obj.t),'Interpreter', 'latex');

			end

		end

		function AnimateWireFrame(obj, n, sm)
			% Since we aren't storing data at this point, the only way to animate is to
			% calculate then plot

			% Set up the line objects initially

			% Initialise an array of line objects
			h = figure();
			hold on

			lineObjects(length(obj.elementList)) = line([1,1],[2,2]);

			for i = 1:length(obj.elementList)
				
				x1 = obj.elementList(i).Node1.x;
				x2 = obj.elementList(i).Node2.x;
				x = [x1,x2];
				y1 = obj.elementList(i).Node1.y;
				y2 = obj.elementList(i).Node2.y;
				y = [y1,y2];

				lineObjects(i) = line(x,y);
			end

			totalSteps = 0;
			while totalSteps < n

				obj.NTimeSteps(sm);
				totalSteps = totalSteps + sm;

				for j = 1:length(obj.elementList)
				
					x1 = obj.elementList(j).Node1.x;
					x2 = obj.elementList(j).Node2.x;
					x = [x1,x2];
					y1 = obj.elementList(j).Node1.y;
					y2 = obj.elementList(j).Node2.y;
					y = [y1,y2];

					if j > length(lineObjects)
						lineObjects(j) = line(x,y);
					else
						lineObjects(j).XData = x;
						lineObjects(j).YData = y;
					end
				end

				% Delete the line objects when there are too many
				for j = length(lineObjects):-1:length(obj.elementList)+1
					lineObjects(j).delete;
					lineObjects(j) = [];
				end
				drawnow
				title(sprintf('t=%g',obj.t));

			end

		end

		function AnimateRods(obj,n,sm,r)

			% Initialise an array of line objects
			h = figure();
			hold on
			axis equal

			% r is the rod "radius"


			% Initialise the array with anything
			patchObjects(length(obj.cellList)) = patch([1,1],[2,2],1, 'LineWidth', 1);

			for i = 1:length(obj.cellList)

				c = obj.cellList(i);

				a = c.nodeList(1).position;
				b = c.nodeList(2).position;

				[pillX,pillY] = obj.DrawPill(a,b,r);
				patchObjects(i) = patch(pillX,pillY,c.GetColour(), 'LineWidth', 1);

			end

			totalSteps = 0;
			while totalSteps < n

				obj.NTimeSteps(sm);
				totalSteps = totalSteps + sm;

				for j = 1:length(obj.cellList)

					c = obj.cellList(j);

					a = c.nodeList(1).position;
					b = c.nodeList(2).position;

					if j > length(patchObjects)
						[pillX,pillY] = obj.DrawPill(a,b,r);
						patchObjects(j) = patch(pillX,pillY,c.GetColour(), 'LineWidth', 1);
					else
						[pillX,pillY] = obj.DrawPill(a,b,r);
						patchObjects(j).XData = pillX;
						patchObjects(j).YData = pillY;
						patchObjects(j).FaceColor = c.GetColour();
					end

				end

				for k = length(patchObjects):-1:length(obj.cellList)+1
					patchObjects(k).delete;
					patchObjects(k) = [];
				end

				drawnow
				title(sprintf('t=%g',obj.t),'Interpreter', 'latex');

			end

		end

		function AnimateNodes(obj,n,sm,r)

			% Initialise an array of line objects
			h = figure();
			hold on
			axis equal

			% r is the rod "radius"


			% Initialise the array with anything
			patchObjects(length(obj.cellList)) = patch([1,1],[2,2],1, 'LineWidth', 2);

			for i = 1:length(obj.cellList)

				c = obj.cellList(i);

				a = c.nodeList(1).position;

				[pillX,pillY] = obj.DrawPill(a,a,r);
				patchObjects(i) = patch(pillX,pillY,c.GetColour(), 'LineWidth', 2);

			end

			totalSteps = 0;
			while totalSteps < n

				obj.NTimeSteps(sm);
				totalSteps = totalSteps + sm;

				for j = 1:length(obj.cellList)

					c = obj.cellList(j);

					a = c.nodeList(1).position;

					if j > length(patchObjects)
						[pillX,pillY] = obj.DrawPill(a,a,r);
						patchObjects(j) = patch(pillX,pillY,c.GetColour(), 'LineWidth', 2);
					else
						[pillX,pillY] = obj.DrawPill(a,a,r);
						patchObjects(j).XData = pillX;
						patchObjects(j).YData = pillY;
						patchObjects(j).FaceColor = c.GetColour();
					end

				end

				for k = length(patchObjects):-1:length(obj.cellList)+1
					patchObjects(k).delete;
					patchObjects(k) = [];
				end

				drawnow
				title(sprintf('t=%g',obj.t),'Interpreter', 'latex');

			end

		end

		function [pillX,pillY] = DrawPill(obj,a,b,r)

			% Draws a pill shape where the centre of the circles are at
			% a and b and the radius is r

			AtoB = b - a;
			 
			normAtoB = [-AtoB(2), AtoB(1)];
			 
			normAtoB = normAtoB / norm(normAtoB);
			if isnan(normAtoB)
				normAtoB = [1,0];
			end
			 
			R = r*normAtoB;
			% Make n equally spaced points around a circle starting from R
			
			n = 10;
			apoints = [];
			bpoints = [];
			
			rot = @(theta) [cos(theta), -sin(theta); sin(theta), cos(theta)];
			
			for i=1:n-1
				
				theta = i*pi/n;
				apoints(i,:) = rot(theta)*R' + a';
				bpoints(i,:) = -rot(theta)*R' + b';
				
			end
			pill = [ a + R; apoints; a - R; b - R; bpoints;  b + R];
			
			pillX = pill(:,1);
			pillY = pill(:,2);

		end

	end

	methods (Access = protected)
		
		function id = GetNextNodeId(obj)
			
			id = obj.nextNodeId;
			obj.nextNodeId = obj.nextNodeId + 1;

		end

		function id = GetNextElementId(obj)
			
			id = obj.nextElementId;
			obj.nextElementId = obj.nextElementId + 1;

		end

		function id = GetNextCellId(obj)
			
			id = obj.nextCellId;
			obj.nextCellId = obj.nextCellId + 1;

		end

		function AddNodesToList(obj, listOfNodes)
			
			for i = 1:length(listOfNodes)
				% If any of the nodes are already in the list, don't add them
				if sum(ismember(listOfNodes(i), obj.nodeList)) == 0
					obj.nodeList = [obj.nodeList, listOfNodes(i)];
				end

			end

		end

		function AddElementsToList(obj, listOfElements)
			
			for i = 1:length(listOfElements)
				% If any of the Elements are already in the list, don't add them
				if sum(ismember(listOfElements(i), obj.elementList)) == 0
					obj.elementList = [obj.elementList, listOfElements(i)];
				end

			end

		end

	end

end