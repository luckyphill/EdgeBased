classdef CellCellInteractionForce < AbstractNodeElementForce

	% This force controls the interaction between cells
	% It encompasses node-node and node-edge interactions
	% It applies to both orientable edges (i.e. polygon cells
	% where the inside defines and orientation) and non-orientable cells
	% represented by a single edge i.e. rod/capsule cells like yeast etc.

	% The force law is designed to asymptote to infinite repulsion at certain distance
	% or overlap between a node and edge. It has a preferred separation,
	% and an interaction limit. The specific equations are

	%			/  srr * log(  ( dSep - dAsym ) / ( x - dAsym)  ),                    dAsym < x < dSep
	%	F(x) = |   sra * (  ( dSep - x ) / ( dSep - dAsym )  ) * exp(c*(dSep - x) ),  dSep < x < dLim 
	%			\  0																  dLim < x

	% The force law is parameterised so that:
	%  - Attraction and repulsion strength can be modulated separately
	%  - The asymptote point can be set to the inside of the cell, or exactly at
	%    the boundary to prevent overlap
	%  - The preferred separation distance and interaction limit are specified
	%    individually (i.e. the limit does not need to be a multiple of the separation)
	%  - The force is zero at x = dSep, and if srr = sra, then the derivative at x = dSep
	%    is smooth

	% Depending on the application, the force can be applied in slightly different ways.
	% If the cells are capsule cells represented by edges/rods, then we are only interested
	% in the absolute distance between a node and edge. If the cells are polygons, then
	% the orientation of the edge is important, so we consider a signed distance based
	% on the inside of the cell. A flag usingRodsOrPolygons specifies the case

	% The interactions between nodes can be turned on or off via the useNodeNodeInteractions
	% boolean variable, which is disabled by default. This must be set to true for
	% rod cells represented by a single edge, otherwise unphysical overlap and hence
	% numerical issues are much more likely

	% If a polygon cell is being used, then there is the risk that an edge will
	% invert, causing a non-simple polygon (i.e. a figure-8). This is mitigated to
	% a large extent by permitting nodes and edges of the same cell to have 
	% a repulsion interaction. This will cause the cell to expand by making the node and edge
	% push apart. This is controlled by useInternalRepulsion and is enabled by default

	% In order to function, this force calculator need to access a space partition
	% that efficiently stores the neighbouring nodes and edges. All that needs to be
	% accessed from the space partition is GetNeighbouringElements and GetNeighbouringNodes

	% Input variables:
	% sra: springRateAttraction, positive
	% srr: springRateRepulsion, positive
	% da:  dAsymptote, typical values [-0.1, 0]
	% ds:  dSeparation, typical value 0.1
	% dl:  dLimit, typical value 0.2
	% dt:  timestep size of the simulation
	% usingPolys: rods = false or polygons = true, setting this automatically sets other flags

	% Optional controls:
	% useNodeNodeInteractions: default false, automatically set to true for rods, can be manually
	%							set to true for polygons but is NOT RECOMMENDED as it needs smaller time step
	%							to be stable, and motion is much less smooth
	% useInternalRepulsion: default false, automatically set to true for polygons, can't be set true for rods 


	properties

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
		
		function obj = CellCellInteractionForce(sra, srr, da, ds, dl, dt, usingPolys)

			obj.springRateAttraction = sra;
			obj.springRateRepulsion = srr;
			obj.dAsymptote = da;
			obj.dSeparation = ds;
			obj.dLimit = dl;
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
				if da < 0
					error("CCIF:overlap", "The force asymptote position allows overlap, which is not supported for rod cells\n");
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

				if obj.useNodeNodeInteractions
					% The space partition efficiently finds the nodes and edges within
					% the interaction limit
					[eList, nList] = p.GetNeighbouringNodesAndElements(n, obj.dLimit);
				else
					eList = p.GetNeighbouringElements(n, obj.dLimit);
					nList = Node.empty();
				end

				for j = 1:length(eList)
					
					e = eList(j);

					% A unit vector tangent to the edge
					u = e.GetVector1to2();

					% We arbitrarily choose an end point on the edge to make a vector
					% going from edge to node...
					n1ton = n.position - e.Node1.position;
					% ... then project it onto the tangent vector to find the point of action
					n1toA = u * dot(n1ton, u);
					
					if obj.usingPolys
						% We use the outward pointing normal to orient the edge
						v = e.GetOutwardNormal();
						% ... and project the arbitrary vector onto the outward normal
						% to find the signed distance between edge and node
						x = dot(n1ton, v);
					

						% Need to check if node-edge interaction pair is between
						% a node and edge of the same cell
						internal = false;
						if sum(ismember(e.cellList, n.cellList)) ~= 0
							internal = true;
						end

						% The negative sign is necessary because v points away
						% from the edge and we need to to point towards the edge
						Fa = -obj.ForceLaw(x,internal) * v;

					else
						% We aren't using polygons, so we must be using rods
						% In this case we just take the vector going from the
						% node to the point of action and find its magnitude
						v = n1toA - n1ton;
						x = norm(v);

						% Convert v to a unit vector
						v = v/x;

						Fa = obj.ForceLaw(x,false) * v;

					end


					obj.ApplyForcesToNodeAndElement(n,e,Fa,n1toA);

				end

				if obj.useNodeNodeInteractions

					for j = 1:length(nList)

						n1 = nList(j);

						nton1 = n1.position - n.position;

						x = norm(nton1);
						v = nton1 / x;

						if obj.usingPolys
							% We need to be slightly tricky with polygons
							% because there can in rare cases be overlapping
							% nodes that interact directly with a node from
							% the inside of the cell

							% Check first if the 
							internal = false;
							if sum(ismember(n1.cellList, n.cellList)) ~= 0
								% if the nodes are part of the same cell
								% then the interaction is internal, so set the flag
								internal = true;
							end

							if ~internal
								% Check if the node needs to be pushed out of the cell
								% and if so, we know the signed distance between nodes is
								% negative 
								for k = 1:length(n1.cellList)
									if n1.cellList(k).IsNodeInsideCell(n);
										x = -x;
										v = -v;
										break;
									end
								end
							end

						else

							internal = false;

						end

						Fa = v * obj.ForceLaw(x,internal);

						% Fa has positive sense going from n to n1
						n.AddForceContribution(-Fa);
						n1.AddForceContribution(Fa);


					end

				end

			end

		end

		function Fa = ForceLaw(obj, x, internal)

			% This calculates the scalar force for the given separation
			% x and the controlling parameters as outline in the preamble


			Fa = 0;

			if ~internal

				% then the interaction is between separate cells
				
				if (obj.dAsymptote < x) && ( x < obj.dSeparation)

					Fa = obj.springRateRepulsion * log(  ( obj.dSeparation - obj.dAsymptote ) / ( x - obj.dAsymptote )  );
				end

				if (obj.dSeparation <= x ) && ( x < obj.dLimit )

					Fa = obj.springRateAttraction * (  ( obj.dSeparation - x ) / ( obj.dSeparation - obj.dAsymptote )  ) * exp(obj.c*(obj.dSeparation - x)/obj.dSeparation );

				end

			else
				% otherwise, it is internal, and we either do nothing or ...
				if obj.useInternalRepulsion
					% we apply the internal repulsion force to push the node and element apart
					% We need to make two small modifications
					% Firstly we need to flip the direction of the force; normally it would want to
					% push the node to the outside of the cell, but we wnat it to go inside
					% Secondly, we need it to aspymtote at the edge, not passed it
					srr = -obj.springRateRepulsion;
					dAsym = 0;
					if (obj.dAsymptote < x) && ( x < obj.dSeparation)

						Fa = srr * log(  ( obj.dSeparation - dAsymp ) / ( x - dAsymp )  );
					end
				end
			
			end


		end

	end

end