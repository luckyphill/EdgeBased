classdef ConstantRadialForce < AbstractTissueBasedForce
	% This adds a constant force to each NodeCell in the simulation
	% that points radially form a point.
	% force is a scalar magnitude - positive means it pushes away from
	% the centre, negative means it pushes towards the centre


	properties

		force
		membrane

	end

	methods


		function obj = ConstantRadialForce(force, membrane)

			obj.force = force;
			obj.membrane = membrane;


		end

		function AddTissueBasedForces(obj, tissue)

			for i = 1:length(tissue.cellList)
				c = tissue.cellList(i);
				if isa(c, 'NodeCell')
					obj.ApplyForce(c);
				end

			end

		end


		function ApplyForce(obj, c)

			n = c.nodeList;

			nPos = reshape([obj.membrane.nodeList.position],2,[])';
			centre = mean(nPos);


			centreToNode = n.position - centre;

			% Unit vector
			u = centreToNode / norm(centreToNode);

			n.AddForceContribution(obj.force * u);

		end

	end

end