classdef CellTypeInteractionForce < AbstractNodeElementForce

	% This force controls the interaction between cells
	% while accounting for different cell types 

	% It is otherwise identical to CellCellInteractionForce

	% NOTE
	% This cannot be used when nodes are shared with cells of different type
	% In this situation, it is not clear what type the node will be


	properties

		cellTypes % A vector containing the cell types in an order matching the
					% interaction matrices


		% Square matrices containing the interactions between cell types
		% If [i,j,k] are the cell types in cellTypes vector then the values
		% in the matrices must be
		%    i  j  k
		% i| .  .  .|
		% j| .  .  .|
		% k| .  .  .|
		% The matrix must be symetric

		springRateAttraction
		springRateRepulsion
		dAsymptote
		dSeparation
		dLimit

		% The shape parameter of the attraction force law, set here
		% so it can be modified, although it is not intended to be.
		c = 5;

		usingPolys


		useInternalRepulsion = false;
		useNodeNodeInteractions = false;


	end

	methods
		
		function obj = CellTypeInteractionForce(sra, srr, da, ds, dl, cellTypes, dt, usingPolys)

			% Make sure the inputs are square symetric matrices
			if ~isequal(sra,sra') || ~isequal(srr,srr') || ~isequal(da,da') || ~isequal(ds,ds') || ~isequal(dl,dl')
				error("CTIF:matrix","Make sure input matrices are symetric")
			end

			obj.springRateAttraction = sra;
			obj.springRateRepulsion = srr;
			obj.dAsymptote = da;
			obj.dSeparation = ds;
			obj.dLimit = dl;

			% A list of all the cell types in the simulation that this force law is applied to
			obj.cellTypes = cellTypes;

			obj.dt = dt;

			obj.usingPolys = usingPolys;

			if usingPolys
				% True means polygons, set flags as approriate
				obj.useInternalRepulsion = true;
				obj.useNodeNodeInteractions = false;
			else
				% False means rods
				obj.useInternalRepulsion = false;
				obj.useNodeNodeInteractions = true;
				asymp = da < 0;
				if sum(sum(asymp)) > 0
					error("CTIF:overlap", "The force asymptote position allows overlap, which is not supported for rod cells\n");
				end
			end

		end

		function AddNeighbourhoodBasedForces(obj, nodeList, p)

			% nodeList is a vector of nodes in the simulation
			% p is the space partition of nodes and edges in the simulation


			% Here we calculate the forces between nodes and edges, and
			% nodes and nodes. 

			% The force in ForceLaw assumes a positive scalar force is
			% a repulsion interaction.

			% For a node-edge interaction, we have to
			% use the semi-rigid body approach in ApplyForcesToNodeAndElement
			% which is supplied by the parent object.
			% To use the function, the force Fa is assumed to have positive sense towards
			% the edge. This means that Fa will be positive for repulsion applied
			% to an edge, or negative for repulsion applied to the node.

			% For a node-node interaction, the forces must be added in this method

			for i = 1:length(nodeList)
				n = nodeList(i);
				cT1 = find(obj.cellTypes == n.cellList(1).cellType);

				if obj.useNodeNodeInteractions
					% The space partition efficiently finds the nodes and edges within
					% the interaction limit (choose the maximum interaction limit)
					[eList, nList] = p.GetNeighbouringNodesAndElements(n, max(obj.dLimit(cT1,:)) );

				else
					eList = p.GetNeighbouringElements(n, max(obj.dLimit(cT1,:)));
					nList = Node.empty();
				end

				for j = 1:length(eList)
					
					e = eList(j);
					cT2 = find(obj.cellTypes == e.cellList(1).cellType);

					% A unit vector tangent to the edge
					u = e.GetVector1to2();

					% We arbitrarily choose an end point on the edge to make a vector
					% going from edge to node...
					n1ton = n.position - e.Node1.position;
					% ... then project it onto the tangent vector to find the point of action
					n1toA = u * dot(n1ton, u);


					% We need to determine the cell types interacting
					sra = obj.springRateAttraction(cT1,cT2);
					srr = obj.springRateRepulsion(cT1,cT2);
					da = obj.dAsymptote(cT1,cT2);
					ds = obj.dSeparation(cT1,cT2);
					dl = obj.dLimit(cT1,cT2);
					
					if obj.usingPolys
						% We use the outward pointing normal to orient the edge
						v = e.GetOutwardNormal();
						% ... and project the arbitrary vector onto the outward normal
						% to find the signed distance between edge and node
						x = dot(n1ton, v);
					

						% Need to check if node-edge interaction pair is between
						% a node and edge of the same cell

						% The negative sign is necessary because v points away
						% from the edge and we need to to point towards the edge

						if sum(ismember(e.cellList, n.cellList)) ~= 0
							Fa = -obj.InternalForceLaw(x, sra, srr, da, ds, dl) * v;
						else
							Fa = -obj.ExternalForceLaw(x, sra, srr, da, ds, dl) * v;
						end

					else
						% We aren't using polygons, so we must be using rods
						% In this case we just take the vector going from the
						% node to the point of action and find its magnitude
						v = n1toA - n1ton;
						x = norm(v);

						% Convert v to a unit vector
						v = v/x;

						% No negative because the direction is determined by v
						Fa = obj.ExternalForceLaw(x, sra, srr, da, ds, dl) * v;

					end


					obj.ApplyForcesToNodeAndElement(n,e,Fa,n1toA);

				end

				if obj.useNodeNodeInteractions

					for j = 1:length(nList)

						n1 = nList(j);

						nton1 = n1.position - n.position;

						x = norm(nton1);
						v = nton1 / x;

						% We need to determine the cell types interacting
						cT1 = find(obj.cellTypes == n.cellList(1).cellType);
						cT2 = find(obj.cellTypes == n1.cellList(1).cellType);

						sra = obj.springRateAttraction(cT1,cT2);
						srr = obj.springRateRepulsion(cT1,cT2);
						da = obj.dAsymptote(cT1,cT2);
						ds = obj.dSeparation(cT1,cT2);
						dl = obj.dLimit(cT1,cT2);

						if obj.usingPolys
							% We need to be slightly tricky with polygons
							% because there can in rare cases be overlapping
							% nodes that interact directly with a node from
							% the inside of the cell

							% Check first if the 
							if sum(ismember(n1.cellList, n.cellList)) ~= 0
								Fa = obj.InternalForceLaw(x, sra, srr, da, ds, dl) * v;
							else
								% Check if the node needs to be pushed out of the cell
								% and if so, we know the signed distance between nodes is
								% negative 
								for k = 1:length(n1.cellList)
									if n1.cellList(k).IsNodeInsideCell(n);
										x = -x;
										v = -v;
										Fa = obj.ExternalForceLaw(x, sra, srr, da, ds, dl) * v;
										break;
									end
								end
							end

						else

							Fa = obj.ExternalForceLaw(x, sra, srr, da, ds, dl) * v;

						end

						% Fa has positive sense going from n to n1
						n.AddForceContribution(-Fa);
						n1.AddForceContribution(Fa);


					end

				end

			end

		end

		function Fa = ExternalForceLaw(obj, x, sra, srr, da, ds, dl)

			% This calculates the scalar force for the given separation
			% x and the controlling parameters as outline in the preamble


			% It is used for interactions between cells

			Fa = 0;

				
			if (da < x) && ( x < ds)

				Fa = srr * log(  ( ds - da ) / ( x - da )  );
			end

			if (ds <= x ) && ( x < dl )

				Fa = sra * (  ( ds - x ) / ( ds - da )  ) * exp(obj.c*(ds - x)/ds );

			end


		end


		function Fa = InternalForceLaw(obj, x, sra, srr, da, ds, dl)

			% This calculates the scalar force for the given separation
			% x and the controlling parameters as outline in the preamble

			% It calculates the force when it is internal to a cell

			Fa = 0;
			% we apply the internal repulsion force to push the node and element apart
			% We need to make two small modifications
			% Firstly we need to flip the direction of the force; normally it would want to
			% push the node to the outside of the cell, but we wnat it to go inside
			% Secondly, we need it to aspymtote at the edge, not passed it
			srr = -srr;
			da = 0;
			if (da < x) && ( x < ds)

				Fa = srr * log(  ( ds - da ) / ( x - da )  );

			end

		end

	end

end