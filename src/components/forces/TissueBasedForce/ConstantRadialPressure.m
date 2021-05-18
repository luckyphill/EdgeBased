classdef ConstantRadialPressure < AbstractTissueBasedForce
	% This adds a constant force to each NodeCell in the simulation
	% that points radially form a point.
	% force is a scalar magnitude - positive means it pushes away from
	% the centre, negative means it pushes towards the centre


	properties

		pressure
		membrane
		radius

		tooClose = false

	end

	methods


		function obj = ConstantRadialPressure(pressure, membrane, rad)

			% Pressure is the force per unit area
			% membrane is a pointer to the membrane object
			% rad is the radius of a NodeCell. In TumourInMembrane, this will be dSN/2
			obj.pressure = pressure;
			obj.membrane = membrane;
			obj.radius = rad;

		end

		function AddTissueBasedForces(obj, tissue)

			if ~obj.tooClose
				CalculateAndAddForce(obj, tissue);
			end

		end

		function CalculateAndAddForce(obj, tissue)

			nPos = reshape([obj.membrane.nodeList.position],2,[])';
			
			if tissue.step < 2
				centre = mean(nPos);
			else
				centre = tissue.simData('innerRadius').data(4:5);
			end



			% For each node, find its distance from the centre,
			% and angle from the horizontal that it covers assuming it is
			% uncompressed. A cell further out will cover a smaller angle.
			% Then we calculate the total angle where it is not covered by another
			% cell. We use this angle and its radius to calculate the force
			% applied due to internal pressure.


			% If we get too close to the centre point, then this breaks down
			% and we start getting imagniary numbers, and the whole
			% force calculation no longer makes sense. We turn it off once
			% the cells get within a diameter of the centre.

			loc = [];

			for i = 1:length(tissue.cellList)
				c = tissue.cellList(i);
				if isa(c, 'NodeCell')
					n = c.nodeList;
					r = n.position - centre;
					rmag = norm(r);
					loc(end + 1, :) = [i, r, rmag];

					if rmag < obj.radius
						obj.tooClose = true;
						% fprintf('Internal pressure turned off\n');
						break;
					end
				end

			end

			% A hack way of doing this to avoid duplicating efforts
			iR = InnerRadius();
			iR.SetData([nan,nan,nan,nan,nan]);
			
			if ~obj.tooClose

				% Sort the nodes in order of their distance from the centre
				loc = sortrows(loc,4);

				angLoc = []; % Store the angular location of the node, so we can order it

				% We now have each node in order of its distance from the centre
				% Starting from the closest node, calculate the angle it covers
				% Subtract away any portion of the angle that already exists in the tally
				% and use this to calculate the force due to internal pressure
				% Add the remaining angle to the tally.
				% Repeat until the tally covers the whole circle, or all nodes have been done

				i = 1;

				remAngles = AngleInterval();

				while i <= length(loc) && ~remAngles.IsCircleComplete()

					nid 		= loc(i,1);
					r 			= loc(i,2:3);
					rmag 		= loc(i,4);

					if nid > 0 % If this happens we've hit a cell that isn't a NodeCell

						theta 		= asin(r(2)/rmag);
						
						% Have to convert this to a full angle since asin doesn't have the full range
						theta 		= (r(1) < 0) * sign(r(2)) * pi  + sign(r(1)) * theta;

						dtheta 		= asin(  obj.radius / rmag  ); % Don't need to convert this because its in the range for asin
						angBottom 	= theta - dtheta;
						angTop		= theta + dtheta;

						if angTop > pi
							angTop = angTop - 2* pi;
						end

						if angBottom < -pi
							angBottom = angBottom + 2*pi;
						end

						angleCovered = remAngles.GetUnvistedAngle([angBottom, angTop]);

						arcLength = rmag * angleCovered;

						if angleCovered > 0
							angLoc(end + 1, :)		= [nid, theta, rmag, angleCovered, arcLength];
						end

						force = obj.pressure * arcLength * r / rmag;

						if ~isreal(force) || sum(isinf(force)) || sum(isnan(force))
							% Since we are using asin, if the argument doesn't fall within [-1,1] then it becomes imaginary
							% This error historically occurred because AngleInterval didn't store pi to sufficient decimal places
							error('CRP:NotReal','Somehow the force is not real: dtheta = %g + %g i = asin( %g / %g )', real(dtheta), imag(dtheta), obj.radius, rmag);
						end

						tissue.cellList(nid).nodeList.AddForceContribution(force);

					end

					i = i + 1;

				end

				% The values in angLoc are only those that make up the inner ring 
				angLoc = sortrows(angLoc,2);
				innerNodes = [tissue.cellList(angLoc(:,1)).nodeList];

				perimeter = 0;
				for i = 1:length(innerNodes)-1
					n1 = innerNodes(i);
					n2 = innerNodes(i+1);
					perimeter = perimeter + norm(n1.position - n2.position);
				end

				x = [innerNodes.x];
				y = [innerNodes.y];

				nPos = [x',y'];
				
				maxX = max(x);
				minX = min(x);
				maxY = max(y);
				minY = min(y);

				centre = [mean([minX,maxX]), mean([minY,maxY])];

				avgRadius = mean(sqrt(sum((nPos - centre).^2,2)));

				intArea = polyarea(x,y);

				iR.SetData([intArea, perimeter, avgRadius, centre]);

				tissue.AddSimulationData(iR);

			end

			


		end

	end

end