classdef EdgeSpringForce < AbstractElementBasedForce
	% This class treats an edge like a spring

	% The specific acion rate of the spring can be determined by a 
	% user defined function, but at default it will be linear
	% It must take in two arguments, the natural length, and the actual length
	% Any stiffness parameter must be applied inside this function

	% The sign of the function must be positive if the spring is in compression
	% and negative if it is in tension


	properties

		springFunction = @(n, l) n - l;

	end

	methods


		function obj = EdgeSpringForce(varargin)

			if length(varargin) > 0
				obj.springFunction = varargin{1};
			end

		end

		function AddElementBasedForces(obj, elementList)

			for i = 1:length(elementList)
				e = elementList(i);
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