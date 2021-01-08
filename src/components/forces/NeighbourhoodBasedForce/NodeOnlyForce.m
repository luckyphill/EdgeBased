classdef NodeOnlyForce < AbstractNeighbourhoodBasedForce
	% A force calculator for node only simulations


	properties

		r % Distance that is close enough for a reaction
		s

	end

	methods


		function obj = NodeOnlyForce(r,s)

			obj.r = r;
			obj.s = s;

		end
		
		function AddNeighbourhoodBasedForces(obj, nodeList, p)


			doneList = Node.empty(); % A list of the interactions that have already been done

			for i = 1:length(nodeList)
				n1 = nodeList(i);
				neighbourList = p.GetNeighbouringNodes(n1, 3 * obj.r);

				for j = 1:length(neighbourList)
					n2 = neighbourList(j);

					if ~ismember(n2, doneList)

						n1ton2 = n2.position - n1.position;

						x = norm(n1ton2);

						v = n1ton2 / x;


						if (0 < x) && ( x < obj.r)

							Fa = obj.s * log(  obj.r / x   );
						end

						if (obj.r <= x ) && ( x < 3*obj.r )

							Fa = obj.s * (  ( obj.r - x ) / obj.r  ) * exp(5*(obj.r - x)/obj.r );

						end

						F1to2 = v * Fa;

						n1.AddForceContribution(-F1to2);
						n2.AddForceContribution(F1to2);

					end

				end

				doneList(end+1) = n1;

			end

		end

	end

end