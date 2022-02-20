classdef EdgeForceSelected < AbstractElementBasedForce
	% Apply a spring force to specified edges


	properties

		springFunction = @(n, l) n - l;

		edgeList

	end

	methods


		function obj = EdgeForceSelected(edgeList)

			obj.edgeList = edgeList;

		end

		function AddElementBasedForces(obj, elementList)

			% Ignore the element list passed into the function, as we already have
			% the edges we care about

			for i = 1:length(obj.edgeList)
				e = obj.edgeList(i);
				obj.ApplySpringForce(e);
			end

		end


		function ApplySpringForce(obj, e)

			% If the spring is in compression, push the end points away from each
			% other. Since obj.springFunction will give +ve value in this case
			% the unitvector must be made negative on Node1 and positive on Node2
			l = e.GetLength();
			unitVector1to2 = (e.Node2.position - e.Node1.position) / l;

			n = e.GetNaturalLength();
			mag = obj.springFunction(n, l);

			force = mag * unitVector1to2;

			e.Node1.AddForceContribution(-force);
			e.Node2.AddForceContribution(force);

		end

	end

end