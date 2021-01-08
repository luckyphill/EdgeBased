classdef AbstractNeighbourhoodBasedForce < matlab.mixin.Heterogeneous
	% This class gives the details for how a force will be applied
	% to each cell (as opposed to each element, or the whole population)


	properties

	end

	methods (Abstract)

		AddNeighbourhoodBasedForces(obj, nodeList)

	end

	methods

		% This function applies the forces to make the element rotate
		% It is the pinnacle of the drag dominated equations of motion
		% I developed
		function ApplyForcesToNodeAndElement(obj,n,e,Fa,n1toA)

			% This takes a node, an element, a force and a point
			% and uses them to work out the forces applied to the node
			% and the element

			% Fa is the force pointing to the element

			% It uses the drag dominated equations of motion I developed
			% for a rigid body - see research diary

			% To solve the motion, we need to account for linear
			% movement and rotational movement. To do this, we solve
			% the angular velocity of the element in its body
			% system of coordinates. This requires a "moment of drag"
			% for the element, based on its length and the drag
			% coefficients of its nodes. We produce an angle that the
			% element rotates through during the time step
			% In addition to the rotation, we solve the linear motion
			% of the element at its "centre of drag", again, determined
			% by its length and the drag coefficients of its nodes. This
			% produces a vector that the centre of drag moves along in
			% the given time interval.
			% Once we have both the angle and vector, the rotation is aplied
			% first, moving the nodes to their rotated position assuming
			% no linear movement, then the linear movement is applied to each
			% node.

			% This process produces a final position after rotation and
			% translation, however, in order to apply this to the simulation
			% we need to convert this back into an equivalent force in
			% purely linear motion

			
			% Grab the components we need so the code is cleaner

			eta1 = e.Node1.eta;
			eta2 = e.Node2.eta;
			etaA = n.eta;

			
			r1 = e.Node1.position;
			r2 = e.Node2.position;
			rA = r1 + n1toA;
			
			
			% First, find the angle.
			% To do this, we need the force from the node, in the element's
			% body system of coordinates

			u = e.GetVector1to2();
			v = e.GetOutwardNormal();

			Fab = [dot(Fa, v), dot(Fa, u)];

			% Next, we determine the equivalent drag of the centre
			% and the position of the centre of drag
			etaD = eta1 + eta2;
			rD = (eta1 * r1 + eta2 * r2) / etaD;

			% We then need the vector from the centre of drag to
			% both nodes (note, these are relative the fixed system of
			% coordinates, not the body system of coordinates)
			rDto1 = r1 - rD;
			rDto2 = r2 - rD;
			rDtoA = rA - rD;

			% These give us the moment of drag about the centre of drag
			ID = eta1 * norm(rDto1)^2 + eta2 * norm(rDto2)^2;

			% The moment created by the node is then force times
			% perpendicular distance.  We must use the body system of
			% coordinates in order to get the correct direction.
			% (We could probably get away without the transform, 
			% since we only need the length, but we'd have to be
			% careful about choosing the sign correctly)
			
			rDtoAb = [dot(rDtoA, v),  dot(rDtoA, u)];

			% The moment is technically rDtoAby * Fabx - rDtoAbx * Faby
			% but by definition, the y-axis aligns with the element,
			% so all x components are 0
			M = -rDtoAb(2) * Fab(1);

			% Now we can find the change in angle in the given time step
			a = obj.dt * M / ID;

			% This angle can now be used in a rotation matrix to determine the new
			% position of the nodes. We can apply it directly to rDto1 and rDto2
			% since the angle is in the plane (a consequnce of 2D)

			Rot = [cos(a), -sin(a); sin(a), cos(a)];

			% Need to transpose the vector so we can apply the rotation
			rDto1_new = Rot * rDto1';
			rDto2_new = Rot * rDto2';

			% Finally, the new positions of the nodes in the fixed system
			% of coordinates found by summing the vectors

			% Now shift from element system of coordinates to global
			r1f = rD + rDto1_new';
			r2f = rD + rDto2_new';

			% Hooray, weve done it! All that is left to do it translate
			% the nodes with the linear motion
			r1f = r1f + (obj.dt * Fa) / etaD;
			r2f = r2f + (obj.dt * Fa) / etaD;

			% We now have the final position of the element after rotation
			
			% Ideally I would like to have the simulation set up
			% so elements can have a torque applied to them, however
			% this introduces complexity around how to handle two connected
			% elements that have different torques applied to them

			% The simulation represents elements as two nodes,
			% so all of the forces have to be realised there
			% this means that any movement has to be in terms
			% of a force on a node

			% The change in position
			dr1 = r1f - r1;
			dr2 = r2f - r2;

			% The force that would be applied to make a node move
			% to its new position
			Fequiv1 = eta1 * dr1 / obj.dt;
			Fequiv2 = eta2 * dr2 / obj.dt;

			e.Node1.AddForceContribution(Fequiv1);
			e.Node2.AddForceContribution(Fequiv2);
			n.AddForceContribution(-Fa);

		end

	end



end